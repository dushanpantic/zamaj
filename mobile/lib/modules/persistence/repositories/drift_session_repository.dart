import 'dart:async';
import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart' as domain;
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart' as domain;
import 'package:zamaj/modules/domain/models/session_exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/domain/repositories/program_repository.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';
import 'package:zamaj/modules/domain/services/deload_transform.dart';
import 'package:zamaj/modules/domain/services/effective_exercises.dart'
    as domain;
import 'package:zamaj/modules/domain/services/exercise_state_transitions.dart'
    as domain;
import 'package:zamaj/modules/domain/services/session_seed.dart' as domain;
import 'package:zamaj/modules/domain/services/superset_ordering.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/database/datetime_utils.dart';
import 'package:zamaj/modules/persistence/database/timestamp_oracle.dart';
import 'package:zamaj/modules/persistence/mappers/session_mapper.dart';

class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository({
    required AppDatabase db,
    required ProgramRepository programRepository,
    Clock clock = const Clock(),
  }) : _db = db,
       _programRepository = programRepository,
       _clock = clock,
       _timestamps = TimestampOracle(clock);

  final AppDatabase _db;
  final ProgramRepository _programRepository;
  final Clock _clock;
  final TimestampOracle _timestamps;
  final _uuid = const Uuid();
  final _mapper = SessionMapper();

  static const _gap = 1024;

  @override
  Future<domain.Session> startSession({
    required String workoutDayId,
    bool isDeload = false,
  }) async {
    return _db.transaction(() async {
      final storedDay = await _programRepository.getWorkoutDay(workoutDayId);
      if (storedDay == null) {
        throw NotFoundError(entityType: 'WorkoutDay', id: workoutDayId);
      }

      // A deload freezes a halved snapshot; the stored template is untouched.
      final workoutDay = isDeload
          ? DeloadTransform.halveWorkingSets(storedDay)
          : storedDay;

      final snapshotJson = CanonicalJson.encode(workoutDay.toJson());
      final snapshotHash = CanonicalJson.sha256Hex(snapshotJson);

      final sessionId = _uuid.v4();
      final now = _clock.now().toUtc();
      final nowMs = utcToMs(now);

      await _db
          .into(_db.sessions)
          .insert(
            SessionsCompanion.insert(
              id: sessionId,
              workoutDayId: workoutDayId,
              snapshotJson: snapshotJson,
              snapshotHash: snapshotHash,
              startedAtMs: nowMs,
              createdAtMs: nowMs,
              updatedAtMs: nowMs,
              schemaVersion: SchemaVersions.domain,
              isDeload: Value(isDeload),
            ),
          );

      final seed = domain.SessionSeed.fromWorkoutDay(workoutDay);
      for (var position = 0; position < seed.length; position++) {
        final entry = seed[position];
        await _db
            .into(_db.sessionExercises)
            .insert(
              SessionExercisesCompanion.insert(
                id: _uuid.v4(),
                sessionId: sessionId,
                position: position * _gap,
                plannedExerciseIdInSnapshot: entry.plannedExerciseIdInSnapshot,
                stateDiscriminator: 'unfinished',
                substitutePayloadJson: const Value(null),
                supersetTag: Value(entry.supersetTag),
                createdAtMs: nowMs,
                updatedAtMs: nowMs,
                schemaVersion: SchemaVersions.domain,
              ),
            );
      }

      return _loadSession(sessionId);
    });
  }

  @override
  Future<domain.Session?> getSession(String sessionId) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (row == null) return null;
    return _buildSession(row);
  }

  @override
  Stream<domain.Session?> watchSession(String sessionId) {
    // Re-fetch the full session whenever any of the related tables change.
    // tableUpdates is sync-broadcast: subscribers receive the event in the
    // same microtask the transaction commits in, so by the time a mutation
    // future resolves the dependent stream has already emitted.
    final triggers = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.sessions,
        _db.sessionExercises,
        _db.executedSets,
        _db.sessionNotes,
        _db.extraWorkItems,
      ]),
    );
    final controller = StreamController<domain.Session?>();
    StreamSubscription<void>? sub;
    var lastInFlight = false;

    Future<void> push() async {
      if (lastInFlight) return;
      lastInFlight = true;
      try {
        final value = await getSession(sessionId);
        if (!controller.isClosed) controller.add(value);
      } finally {
        lastInFlight = false;
      }
    }

    controller.onListen = () {
      push();
      sub = triggers.listen((_) => push());
    };
    controller.onCancel = () async {
      await sub?.cancel();
      sub = null;
      await controller.close();
    };
    return controller.stream;
  }

  @override
  Future<domain.Session?> getActiveSession() async {
    final row =
        await (_db.select(_db.sessions)
              ..where((t) => t.endedAtMs.isNull())
              // Mirrors domain ActiveSessionPolicy: most recently worked-on
              // wins (updatedAt desc), then startedAt desc, then id desc as a
              // deterministic tie-break.
              ..orderBy([
                (t) => OrderingTerm.desc(t.updatedAtMs),
                (t) => OrderingTerm.desc(t.startedAtMs),
                (t) => OrderingTerm.desc(t.id),
              ])
              ..limit(1))
            .getSingleOrNull();
    if (row == null) return null;
    return _buildSession(row);
  }

  @override
  Stream<domain.Session?> watchActiveSession() {
    final triggers = _db.tableUpdates(
      TableUpdateQuery.onAllTables([
        _db.sessions,
        _db.sessionExercises,
        _db.executedSets,
        _db.sessionNotes,
        _db.extraWorkItems,
      ]),
    );
    final controller = StreamController<domain.Session?>();
    StreamSubscription<void>? sub;
    var lastInFlight = false;

    Future<void> push() async {
      if (lastInFlight) return;
      lastInFlight = true;
      try {
        final value = await getActiveSession();
        if (!controller.isClosed) controller.add(value);
      } finally {
        lastInFlight = false;
      }
    }

    controller.onListen = () {
      push();
      sub = triggers.listen((_) => push());
    };
    controller.onCancel = () async {
      await sub?.cancel();
      sub = null;
      await controller.close();
    };
    return controller.stream;
  }

  @override
  Future<domain.Session> getSessionByExerciseId(
    String sessionExerciseId,
  ) async {
    final exerciseRow = await _requireSessionExerciseRow(sessionExerciseId);
    return _loadSession(exerciseRow.sessionId);
  }

  @override
  Future<domain.Session> getSessionByExecutedSetId(String executedSetId) async {
    final setRow = await (_db.select(
      _db.executedSets,
    )..where((t) => t.id.equals(executedSetId))).getSingleOrNull();
    if (setRow == null) {
      throw NotFoundError(entityType: 'ExecutedSet', id: executedSetId);
    }
    final exerciseRow = await _requireSessionExerciseRow(
      setRow.sessionExerciseId,
    );
    return _loadSession(exerciseRow.sessionId);
  }

  @override
  Future<List<domain.Session>> listSessionsForWorkoutDay(
    String workoutDayId,
  ) async {
    final sessionRows = await (_db.select(
      _db.sessions,
    )..where((t) => t.workoutDayId.equals(workoutDayId))).get();
    return _hydrateSessions(sessionRows);
  }

  @override
  Future<List<domain.Session>> listCompletedSessions() async {
    final sessionRows = await (_db.select(
      _db.sessions,
    )..where((t) => t.endedAtMs.isNotNull())).get();
    return _hydrateSessions(sessionRows);
  }

  /// Batched row→domain hydration for a set of session rows: one query per
  /// related table (exercises, executed sets, notes, extra work), grouped in
  /// memory. Shared by every multi-session read so none of them N+1.
  Future<List<domain.Session>> _hydrateSessions(
    List<Session> sessionRows,
  ) async {
    if (sessionRows.isEmpty) return const [];

    final sessionIds = sessionRows.map((r) => r.id).toList();

    final exerciseRows =
        await (_db.select(_db.sessionExercises)
              ..where((t) => t.sessionId.isIn(sessionIds))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final exerciseIds = exerciseRows.map((e) => e.id).toList();

    final setRows = exerciseIds.isEmpty
        ? <ExecutedSet>[]
        : await (_db.select(_db.executedSets)
                ..where((t) => t.sessionExerciseId.isIn(exerciseIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

    final noteRows = await (_db.select(
      _db.sessionNotes,
    )..where((t) => t.sessionId.isIn(sessionIds))).get();

    final extraWorkRows =
        await (_db.select(_db.extraWorkItems)
              ..where((t) => t.sessionId.isIn(sessionIds))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

    final exercisesBySession = <String, List<SessionExercise>>{};
    for (final e in exerciseRows) {
      (exercisesBySession[e.sessionId] ??= []).add(e);
    }
    final setsByExercise = <String, List<ExecutedSet>>{};
    for (final s in setRows) {
      (setsByExercise[s.sessionExerciseId] ??= []).add(s);
    }
    final notesBySession = <String, List<SessionNote>>{};
    for (final n in noteRows) {
      (notesBySession[n.sessionId] ??= []).add(n);
    }
    final extrasBySession = <String, List<ExtraWorkItem>>{};
    for (final x in extraWorkRows) {
      (extrasBySession[x.sessionId] ??= []).add(x);
    }

    return [
      for (final row in sessionRows)
        () {
          final exercises =
              exercisesBySession[row.id] ?? const <SessionExercise>[];
          return _mapper.toDomain(
            row,
            exercises,
            [for (final e in exercises) ...?setsByExercise[e.id]],
            notesBySession[row.id] ?? const <SessionNote>[],
            extrasBySession[row.id] ?? const <ExtraWorkItem>[],
          );
        }(),
    ];
  }

  @override
  Future<domain.Session> endSession(String sessionId) async {
    return _db.transaction(() async {
      final row = await _requireSessionRow(sessionId);
      if (row.endedAtMs != null) {
        throw ImmutabilityError(
          sessionId: sessionId,
          message: 'Session $sessionId is already ended',
        );
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(row.updatedAtMs),
        createdAt: msToUtc(row.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(
          endedAtMs: Value(utcToMs(updatedAt)),
          updatedAtMs: Value(utcToMs(updatedAt)),
        ),
      );
      return _loadSession(sessionId);
    });
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    await _db.transaction(() async {
      await _requireSessionRow(sessionId);
      await (_db.delete(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).go();
    });
  }

  @override
  Future<domain.Session> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  }) async {
    return _db.transaction(() async {
      final exerciseRow = await _requireSessionExerciseRow(sessionExerciseId);
      final sessionRow = await _requireSessionRow(exerciseRow.sessionId);

      final effective = _effectiveForRow(exerciseRow, sessionRow);
      final measurementType = effective.effectiveMeasurementType;
      _validateActualValues(
        actualValues: actualValues,
        measurementType: measurementType,
        entityId: sessionExerciseId,
      );

      final existingSets = await (_db.select(
        _db.executedSets,
      )..where((t) => t.sessionExerciseId.equals(sessionExerciseId))).get();

      // ExecutedSet.position is a dense chronological index, so the next set
      // appends at the current count.
      final newSetPosition = existingSets.length;

      final setId = _uuid.v4();
      final now = _clock.now().toUtc();
      final nowMs = utcToMs(now);
      final actualJson = actualValues.toJson();
      final actualDiscriminator = actualJson['type'] as String;
      final measurementDiscriminator = switch (measurementType) {
        RepBasedMeasurement() => 'repBased',
        TimeBasedMeasurement() => 'timeBased',
        BodyweightMeasurement() => 'bodyweight',
      };

      await _db
          .into(_db.executedSets)
          .insert(
            ExecutedSetsCompanion.insert(
              id: setId,
              sessionExerciseId: sessionExerciseId,
              position: newSetPosition,
              measurementTypeDiscriminator: measurementDiscriminator,
              actualValuesDiscriminator: actualDiscriminator,
              actualValuesPayloadJson: CanonicalJson.encode(actualJson),
              plannedSetIdInSnapshot: Value(plannedSetIdInSnapshot),
              completedAtMs: nowMs,
              createdAtMs: nowMs,
              updatedAtMs: nowMs,
              schemaVersion: SchemaVersions.domain,
            ),
          );

      final completedSetCount = existingSets.length + 1;

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      final nextState = domain.ExerciseStateTransitions.afterSetLogged(
        effective.sessionExercise.state,
        executedSetCount: completedSetCount,
        plannedSetCount: effective.plannedSetCount,
      );

      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).write(
        SessionExercisesCompanion(
          stateDiscriminator: _stateWriteFor(nextState, exerciseRow),
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(exerciseRow.sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(exerciseRow.sessionId);
    });
  }

  @override
  Future<domain.Session> updateExecutedSet({
    required String executedSetId,
    required ActualSetValues actualValues,
  }) async {
    return _db.transaction(() async {
      final setRow = await (_db.select(
        _db.executedSets,
      )..where((t) => t.id.equals(executedSetId))).getSingleOrNull();
      if (setRow == null) {
        throw NotFoundError(entityType: 'ExecutedSet', id: executedSetId);
      }

      final exerciseRow = await _requireSessionExerciseRow(
        setRow.sessionExerciseId,
      );
      final sessionRow = await _requireSessionRow(exerciseRow.sessionId);

      final measurementType = _effectiveForRow(
        exerciseRow,
        sessionRow,
      ).effectiveMeasurementType;
      _validateActualValues(
        actualValues: actualValues,
        measurementType: measurementType,
        entityId: executedSetId,
      );

      final actualJson = actualValues.toJson();
      final actualDiscriminator = actualJson['type'] as String;

      final setUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(setRow.updatedAtMs),
        createdAt: msToUtc(setRow.createdAtMs),
      );

      await (_db.update(
        _db.executedSets,
      )..where((t) => t.id.equals(executedSetId))).write(
        ExecutedSetsCompanion(
          actualValuesDiscriminator: Value(actualDiscriminator),
          actualValuesPayloadJson: Value(CanonicalJson.encode(actualJson)),
          updatedAtMs: Value(utcToMs(setUpdatedAt)),
        ),
      );

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );
      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(exerciseRow.id))).write(
        SessionExercisesCompanion(
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(exerciseRow.sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(exerciseRow.sessionId);
    });
  }

  @override
  Future<domain.Session> deleteExecutedSet({
    required String executedSetId,
  }) async {
    return _db.transaction(() async {
      final setRow = await (_db.select(
        _db.executedSets,
      )..where((t) => t.id.equals(executedSetId))).getSingleOrNull();
      if (setRow == null) {
        throw NotFoundError(entityType: 'ExecutedSet', id: executedSetId);
      }

      final exerciseRow = await _requireSessionExerciseRow(
        setRow.sessionExerciseId,
      );
      final sessionRow = await _requireSessionRow(exerciseRow.sessionId);

      if (sessionRow.endedAtMs != null) {
        throw ImmutabilityError(
          sessionId: sessionRow.id,
          message:
              'Cannot delete executed set on ended session ${sessionRow.id}',
        );
      }

      await (_db.delete(
        _db.executedSets,
      )..where((t) => t.id.equals(executedSetId))).go();

      // Renumber to keep positions dense 0..N-1 in chronological order.
      final remaining =
          await (_db.select(_db.executedSets)
                ..where((t) => t.sessionExerciseId.equals(exerciseRow.id))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      for (var i = 0; i < remaining.length; i++) {
        if (remaining[i].position == i) continue;
        await (_db.update(_db.executedSets)
              ..where((t) => t.id.equals(remaining[i].id)))
            .write(ExecutedSetsCompanion(position: Value(i)));
      }
      final effective = _effectiveForRow(exerciseRow, sessionRow);

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      final nextState = domain.ExerciseStateTransitions.afterSetDeleted(
        effective.sessionExercise.state,
        executedSetCount: remaining.length,
        plannedSetCount: effective.plannedSetCount,
      );

      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(exerciseRow.id))).write(
        SessionExercisesCompanion(
          stateDiscriminator: _stateWriteFor(nextState, exerciseRow),
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionRow.id))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionRow.id);
    });
  }

  @override
  Future<domain.Session> skipExercise(String sessionExerciseId) async {
    return _db.transaction(() async {
      final exerciseRow = await _requireSessionExerciseRow(sessionExerciseId);
      _requireUnfinished(exerciseRow);

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).write(
        SessionExercisesCompanion(
          stateDiscriminator: const Value('skipped'),
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      final sessionRow = await _requireSessionRow(exerciseRow.sessionId);
      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(exerciseRow.sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(exerciseRow.sessionId);
    });
  }

  @override
  Future<domain.Session> resumeExercise(String sessionExerciseId) async {
    return _db.transaction(() async {
      final exerciseRow = await _requireSessionExerciseRow(sessionExerciseId);

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      // Single-row state flip back to unfinished; sets, position, and
      // superset_tag are left untouched. The engine guards that the current
      // state is skipped.
      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).write(
        SessionExercisesCompanion(
          stateDiscriminator: const Value('unfinished'),
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      final sessionRow = await _requireSessionRow(exerciseRow.sessionId);
      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(exerciseRow.sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(exerciseRow.sessionId);
    });
  }

  @override
  Future<domain.Session> addExercise({
    required String sessionId,
    required AddedExercisePlan plan,
  }) async {
    return _db.transaction(() async {
      final sessionRow = await _requireSessionRow(sessionId);

      // Append after the current last exercise (maxPosition + gap).
      final existing = await (_db.select(
        _db.sessionExercises,
      )..where((t) => t.sessionId.equals(sessionId))).get();
      final maxPosition = existing.isEmpty
          ? -_gap
          : existing.map((e) => e.position).reduce((a, b) => a > b ? a : b);

      final now = _clock.now().toUtc();
      final nowMs = utcToMs(now);

      await _db
          .into(_db.sessionExercises)
          .insert(
            SessionExercisesCompanion.insert(
              id: _uuid.v4(),
              sessionId: sessionId,
              position: maxPosition + _gap,
              // Synthetic 36-char id; never resolved against the snapshot
              // because EffectiveExercises branches on addedPlan first.
              plannedExerciseIdInSnapshot: _uuid.v4(),
              stateDiscriminator: 'unfinished',
              substitutePayloadJson: const Value(null),
              addedPlanJson: Value(CanonicalJson.encode(plan.toJson())),
              supersetTag: const Value(null),
              createdAtMs: nowMs,
              updatedAtMs: nowMs,
              schemaVersion: SchemaVersions.domain,
            ),
          );

      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionId);
    });
  }

  @override
  Future<domain.Session> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    required PlannedSetValues substitutePlannedValues,
    required int substituteSetCount,
    ExerciseMetadata? substituteMetadata,
    String? substituteLibraryExerciseId,
  }) async {
    return _db.transaction(() async {
      final exerciseRow = await _requireSessionExerciseRow(sessionExerciseId);
      _requireUnfinished(exerciseRow);

      final substitute = SubstituteExercise(
        name: substituteName,
        measurementType: substituteMeasurementType,
        plannedValues: substitutePlannedValues,
        setCount: substituteSetCount,
        metadata: substituteMetadata,
        libraryExerciseId: substituteLibraryExerciseId,
      );
      final substituteJson = CanonicalJson.encode(substitute.toJson());

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).write(
        SessionExercisesCompanion(
          stateDiscriminator: const Value('replaced'),
          substitutePayloadJson: Value(substituteJson),
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      final sessionRow = await _requireSessionRow(exerciseRow.sessionId);
      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(exerciseRow.sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(exerciseRow.sessionId);
    });
  }

  @override
  Future<domain.Session> reorderUnfinished({
    required String sessionId,
    required List<String> orderedUnfinishedIds,
  }) async {
    final allExercises = await (_db.select(
      _db.sessionExercises,
    )..where((t) => t.sessionId.equals(sessionId))).get();

    final exerciseById = {for (final e in allExercises) e.id: e};

    for (final id in orderedUnfinishedIds) {
      final exercise = exerciseById[id];
      if (exercise == null) {
        throw NotFoundError(entityType: 'SessionExercise', id: id);
      }
      if (exercise.stateDiscriminator != 'unfinished') {
        throw OrderingError(
          sessionExerciseId: id,
          currentState: exercise.stateDiscriminator,
          message:
              'SessionExercise $id is in state ${exercise.stateDiscriminator}, not unfinished',
        );
      }
    }

    return _db.transaction(() async {
      // Permute positions among the provided unfinished ids: the slots they
      // currently occupy (sorted ascending) get re-assigned in the new order.
      // Locked exercises and any unfinished exercise not in the input keep
      // their current positions.
      final slots =
          orderedUnfinishedIds.map((id) => exerciseById[id]!.position).toList()
            ..sort();

      // Two-phase write to dodge the (session_id, position) UNIQUE constraint:
      // SQLite checks UNIQUE per-statement (no deferred constraints), so a
      // direct row-by-row update collides whenever two rows swap slots.
      // Phase 1 parks every moving row in a disjoint negative range; phase 2
      // writes the final positions.
      final movers = <({String id, int newPosition, SessionExercise row})>[];
      for (var i = 0; i < orderedUnfinishedIds.length; i++) {
        final id = orderedUnfinishedIds[i];
        final exercise = exerciseById[id]!;
        final newPosition = slots[i];
        if (newPosition == exercise.position) continue;
        movers.add((id: id, newPosition: newPosition, row: exercise));
      }

      for (final mover in movers) {
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(mover.id))).write(
          SessionExercisesCompanion(position: Value(-1 - mover.row.position)),
        );
      }
      for (final mover in movers) {
        final updatedAt = _timestamps.nextUpdatedAt(
          previousUpdatedAt: msToUtc(mover.row.updatedAtMs),
          createdAt: msToUtc(mover.row.createdAtMs),
        );
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(mover.id))).write(
          SessionExercisesCompanion(
            position: Value(mover.newPosition),
            updatedAtMs: Value(utcToMs(updatedAt)),
          ),
        );
      }

      final sessionRow = await _requireSessionRow(sessionId);
      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionId);
    });
  }

  @override
  Future<domain.Session> addSessionNote({
    required String sessionId,
    required String body,
  }) async {
    return _db.transaction(() async {
      final sessionRow = await _requireSessionRow(sessionId);

      final noteId = _uuid.v4();
      final now = _clock.now().toUtc();
      final nowMs = utcToMs(now);

      await _db
          .into(_db.sessionNotes)
          .insert(
            SessionNotesCompanion.insert(
              id: noteId,
              sessionId: sessionId,
              body: body,
              createdAtMs: nowMs,
              updatedAtMs: nowMs,
              schemaVersion: SchemaVersions.domain,
            ),
          );

      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionId);
    });
  }

  @override
  Future<domain.Session> createSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) async {
    return _db.transaction(() async {
      final tag = _uuid.v4();

      final allExercises =
          await (_db.select(_db.sessionExercises)
                ..where((t) => t.sessionId.equals(sessionId))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
      final exerciseById = {for (final e in allExercises) e.id: e};

      for (final id in sessionExerciseIds) {
        final row = exerciseById[id];
        if (row == null) {
          throw NotFoundError(entityType: 'SessionExercise', id: id);
        }
        if (row.stateDiscriminator != 'unfinished') {
          throw OrderingError(
            sessionExerciseId: id,
            currentState: row.stateDiscriminator,
            message:
                'Cannot add exercise $id to superset: state is '
                '${row.stateDiscriminator}',
          );
        }
      }

      // Pull the chosen members into one contiguous block, anchored at the
      // drop target's slot and ordered as provided; every other exercise keeps
      // its relative order. The resolver and picker place the drop target last
      // in [sessionExerciseIds], so the block lands where the lifter dropped it.
      // The assembler renders a superset only from a contiguous run of same-tag
      // rows, so without this a group whose members weren't already adjacent
      // (e.g. dropped onto a non-neighbouring card, or split by an intervening
      // locked exercise) would render as orphaned singles — undraggable, with
      // no ungroup affordance. Positions are permuted across the full ordering
      // via the same two-phase write reorderUnfinished uses, since SQLite has
      // no deferred UNIQUE constraints.
      final newOrder = domain.SupersetOrdering.blockedOrderForCreate(
        allIds: allExercises.map((e) => e.id).toList(),
        chosenIds: sessionExerciseIds,
        anchorId: sessionExerciseIds.last,
      );

      final slots = allExercises.map((e) => e.position).toList()..sort();
      final movers = <({String id, int newPosition, SessionExercise row})>[];
      for (var i = 0; i < newOrder.length; i++) {
        final row = exerciseById[newOrder[i]]!;
        final newPosition = slots[i];
        if (newPosition == row.position) continue;
        movers.add((id: newOrder[i], newPosition: newPosition, row: row));
      }

      for (final mover in movers) {
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(mover.id))).write(
          SessionExercisesCompanion(position: Value(-1 - mover.row.position)),
        );
      }
      for (final mover in movers) {
        final updatedAt = _timestamps.nextUpdatedAt(
          previousUpdatedAt: msToUtc(mover.row.updatedAtMs),
          createdAt: msToUtc(mover.row.createdAtMs),
        );
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(mover.id))).write(
          SessionExercisesCompanion(
            position: Value(mover.newPosition),
            updatedAtMs: Value(utcToMs(updatedAt)),
          ),
        );
      }

      for (final id in sessionExerciseIds) {
        final row = exerciseById[id]!;
        final updatedAt = _timestamps.nextUpdatedAt(
          previousUpdatedAt: msToUtc(row.updatedAtMs),
          createdAt: msToUtc(row.createdAtMs),
        );
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(id))).write(
          SessionExercisesCompanion(
            supersetTag: Value(tag),
            updatedAtMs: Value(utcToMs(updatedAt)),
          ),
        );
      }

      final sessionRow = await _requireSessionRow(sessionId);
      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionId);
    });
  }

  @override
  Future<domain.Session> addToSuperset({
    required String sessionId,
    required String supersetTag,
    required String sessionExerciseId,
  }) async {
    return _db.transaction(() async {
      await _requireSessionRow(sessionId);

      final allExercises =
          await (_db.select(_db.sessionExercises)
                ..where((t) => t.sessionId.equals(sessionId))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

      final members = allExercises
          .where((e) => e.supersetTag == supersetTag)
          .toList();
      if (members.isEmpty) {
        throw NotFoundError(entityType: 'Superset', id: supersetTag);
      }
      for (final m in members) {
        if (m.stateDiscriminator != 'unfinished') {
          throw OrderingError(
            sessionExerciseId: m.id,
            currentState: m.stateDiscriminator,
            message:
                'Cannot append to superset $supersetTag: member ${m.id} is '
                '${m.stateDiscriminator}, not unfinished',
          );
        }
      }
      final dragged = allExercises.firstWhere(
        (e) => e.id == sessionExerciseId,
        orElse: () => throw NotFoundError(
          entityType: 'SessionExercise',
          id: sessionExerciseId,
        ),
      );
      if (dragged.stateDiscriminator != 'unfinished') {
        throw OrderingError(
          sessionExerciseId: sessionExerciseId,
          currentState: dragged.stateDiscriminator,
          message:
              'Cannot append exercise $sessionExerciseId to superset: state '
              'is ${dragged.stateDiscriminator}',
        );
      }
      if (dragged.supersetTag != null) {
        throw ValidationError(
          entityId: sessionExerciseId,
          invariant: 'append_to_superset_dragged_already_grouped',
          message:
              'Exercise $sessionExerciseId is already in superset '
              '${dragged.supersetTag}',
        );
      }

      // Compute the new unfinished order: keep the current unfinished slots
      // exactly as they are, but extract the dragged and reinsert it
      // immediately after the last existing group member. Locked exercises
      // keep their positions — only the unfinished slots get permuted, same
      // approach `reorderUnfinished` uses.
      final unfinished = allExercises
          .where((e) => e.stateDiscriminator == 'unfinished')
          .toList();
      final unfinishedIds = domain.SupersetOrdering.orderForAppend(
        unfinishedIds: unfinished.map((e) => e.id).toList(),
        memberIds: members.map((e) => e.id).toList(),
        draggedId: sessionExerciseId,
      );

      final unfinishedById = {for (final e in unfinished) e.id: e};
      final slots = unfinished.map((e) => e.position).toList()..sort();

      // Two-phase write to dodge the (session_id, position) UNIQUE
      // constraint, mirroring `reorderUnfinished`.
      final movers = <({String id, int newPosition, SessionExercise row})>[];
      for (var i = 0; i < unfinishedIds.length; i++) {
        final id = unfinishedIds[i];
        final row = unfinishedById[id]!;
        final newPosition = slots[i];
        if (newPosition == row.position) continue;
        movers.add((id: id, newPosition: newPosition, row: row));
      }

      for (final mover in movers) {
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(mover.id))).write(
          SessionExercisesCompanion(position: Value(-1 - mover.row.position)),
        );
      }
      for (final mover in movers) {
        final updatedAt = _timestamps.nextUpdatedAt(
          previousUpdatedAt: msToUtc(mover.row.updatedAtMs),
          createdAt: msToUtc(mover.row.createdAtMs),
        );
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(mover.id))).write(
          SessionExercisesCompanion(
            position: Value(mover.newPosition),
            updatedAtMs: Value(utcToMs(updatedAt)),
          ),
        );
      }

      final draggedUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(dragged.updatedAtMs),
        createdAt: msToUtc(dragged.createdAtMs),
      );
      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).write(
        SessionExercisesCompanion(
          supersetTag: Value(supersetTag),
          updatedAtMs: Value(utcToMs(draggedUpdatedAt)),
        ),
      );

      final sessionRow = await _requireSessionRow(sessionId);
      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionId);
    });
  }

  @override
  Future<domain.Session> removeSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) async {
    return _db.transaction(() async {
      for (final id in sessionExerciseIds) {
        final exerciseRow = await _requireSessionExerciseRow(id);
        final updatedAt = _timestamps.nextUpdatedAt(
          previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
          createdAt: msToUtc(exerciseRow.createdAtMs),
        );
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(id))).write(
          SessionExercisesCompanion(
            supersetTag: const Value(null),
            updatedAtMs: Value(utcToMs(updatedAt)),
          ),
        );
      }

      final sessionRow = await _requireSessionRow(sessionId);
      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionId);
    });
  }

  @override
  Future<domain.Session> addExtraWork({
    required String sessionId,
    required String body,
  }) async {
    return _db.transaction(() async {
      final sessionRow = await _requireSessionRow(sessionId);

      final existingItems =
          await (_db.select(_db.extraWorkItems)
                ..where((t) => t.sessionId.equals(sessionId))
                ..orderBy([(t) => OrderingTerm.desc(t.position)]))
              .get();

      final maxPos = existingItems.isEmpty ? 0 : existingItems.first.position;
      final newPosition = existingItems.isEmpty ? _gap : maxPos + _gap;

      final itemId = _uuid.v4();
      final now = _clock.now().toUtc();
      final nowMs = utcToMs(now);

      await _db
          .into(_db.extraWorkItems)
          .insert(
            ExtraWorkItemsCompanion.insert(
              id: itemId,
              sessionId: sessionId,
              position: newPosition,
              body: body,
              createdAtMs: nowMs,
              updatedAtMs: nowMs,
              schemaVersion: SchemaVersions.domain,
            ),
          );

      final sessionUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(sessionRow.updatedAtMs),
        createdAt: msToUtc(sessionRow.createdAtMs),
      );
      await (_db.update(
        _db.sessions,
      )..where((t) => t.id.equals(sessionId))).write(
        SessionsCompanion(updatedAtMs: Value(utcToMs(sessionUpdatedAt))),
      );

      return _loadSession(sessionId);
    });
  }

  Future<domain.Session> _loadSession(String sessionId) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(sessionId))).getSingle();
    return _buildSession(row);
  }

  Future<domain.Session> _buildSession(Session row) async {
    final exerciseRows =
        await (_db.select(_db.sessionExercises)
              ..where((t) => t.sessionId.equals(row.id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

    final exerciseIds = exerciseRows.map((e) => e.id).toList();
    final setRows = exerciseIds.isEmpty
        ? <ExecutedSet>[]
        : await (_db.select(_db.executedSets)
                ..where((t) => t.sessionExerciseId.isIn(exerciseIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

    final noteRows = await (_db.select(
      _db.sessionNotes,
    )..where((t) => t.sessionId.equals(row.id))).get();

    final extraWorkRows =
        await (_db.select(_db.extraWorkItems)
              ..where((t) => t.sessionId.equals(row.id))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

    return _mapper.toDomain(
      row,
      exerciseRows,
      setRows,
      noteRows,
      extraWorkRows,
    );
  }

  Future<Session> _requireSessionRow(String sessionId) async {
    final row = await (_db.select(
      _db.sessions,
    )..where((t) => t.id.equals(sessionId))).getSingleOrNull();
    if (row == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }
    return row;
  }

  Future<SessionExercise> _requireSessionExerciseRow(
    String sessionExerciseId,
  ) async {
    final row = await (_db.select(
      _db.sessionExercises,
    )..where((t) => t.id.equals(sessionExerciseId))).getSingleOrNull();
    if (row == null) {
      throw NotFoundError(entityType: 'SessionExercise', id: sessionExerciseId);
    }
    return row;
  }

  void _requireUnfinished(SessionExercise row) {
    if (row.stateDiscriminator != 'unfinished') {
      throw OrderingError(
        sessionExerciseId: row.id,
        currentState: row.stateDiscriminator,
        message:
            'SessionExercise ${row.id} is already locked in state ${row.stateDiscriminator}',
      );
    }
  }

  domain.WorkoutDay _parseSnapshotWorkoutDay(Session sessionRow) {
    return domain.WorkoutDay.fromJson(
      jsonDecode(sessionRow.snapshotJson) as Map<String, dynamic>,
    );
  }

  /// Resolves a session-exercise row against its session's snapshot via the
  /// shared domain projection. A planned exercise absent from the snapshot
  /// raises [NotFoundError] — there is no silent set-count-0 degradation.
  domain.EffectiveExercise _effectiveForRow(
    SessionExercise exerciseRow,
    Session sessionRow,
  ) {
    final workoutDay = _parseSnapshotWorkoutDay(sessionRow);
    // Reconstruct the inline plan so an added (snapshot-less) row resolves via
    // its plan instead of throwing NotFoundError on its synthetic snapshot id.
    final addedPlan = exerciseRow.addedPlanJson != null
        ? AddedExercisePlan.fromJson(
            jsonDecode(exerciseRow.addedPlanJson!) as Map<String, dynamic>,
          )
        : null;
    final sessionExercise = domain.SessionExercise(
      id: exerciseRow.id,
      sessionId: exerciseRow.sessionId,
      position: exerciseRow.position,
      plannedExerciseIdInSnapshot: exerciseRow.plannedExerciseIdInSnapshot,
      state: _stateForRow(exerciseRow),
      executedSets: const [],
      supersetTag: exerciseRow.supersetTag,
      addedPlan: addedPlan,
      createdAt: msToUtc(exerciseRow.createdAtMs),
      updatedAt: msToUtc(exerciseRow.updatedAtMs),
      schemaVersion: exerciseRow.schemaVersion,
    );
    return domain.EffectiveExercises.fromWorkoutDay(
      workoutDay,
    ).forSessionExercise(sessionExercise);
  }

  /// Maps a domain transition result onto a column write. Leaves the
  /// `stateDiscriminator` column untouched ([Value.absent]) when the next state
  /// equals the row's current state, preserving the previous "only write on a
  /// real transition" behaviour.
  Value<String> _stateWriteFor(
    domain.ExerciseState nextState,
    SessionExercise exerciseRow,
  ) {
    final next = nextState.discriminator;
    return next == exerciseRow.stateDiscriminator
        ? const Value.absent()
        : Value(next);
  }

  domain.ExerciseState _stateForRow(SessionExercise exerciseRow) {
    return switch (exerciseRow.stateDiscriminator) {
      'unfinished' => const domain.ExerciseState.unfinished(),
      'completed' => const domain.ExerciseState.completed(),
      'skipped' => const domain.ExerciseState.skipped(),
      'replaced' => domain.ExerciseState.replaced(
        substitute: SubstituteExercise.fromJson(
          jsonDecode(exerciseRow.substitutePayloadJson!)
              as Map<String, dynamic>,
        ),
      ),
      final d => throw DeserializationError(
        field: 'stateDiscriminator',
        discriminator: d,
        message: 'Unknown stateDiscriminator: $d',
      ),
    };
  }

  void _validateActualValues({
    required ActualSetValues actualValues,
    required MeasurementType measurementType,
    required String entityId,
  }) {
    if (!actualValues.matches(measurementType)) {
      throw ValidationError(
        entityId: entityId,
        invariant: 'measurementType_actualValues_mismatch',
        message:
            'ActualSetValues variant does not match measurementType for $entityId',
      );
    }
  }
}
