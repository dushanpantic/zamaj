import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session.dart' as domain;
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/domain/repositories/program_repository.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';
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
  Future<domain.Session> startSession({required String workoutDayId}) async {
    return _db.transaction(() async {
      final workoutDay = await _programRepository.getWorkoutDay(workoutDayId);
      if (workoutDay == null) {
        throw NotFoundError(entityType: 'WorkoutDay', id: workoutDayId);
      }

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
            ),
          );

      var position = 0;
      for (final group in workoutDay.exerciseGroups) {
        for (final exercise in group.exercises) {
          final exerciseId = _uuid.v4();
          await _db
              .into(_db.sessionExercises)
              .insert(
                SessionExercisesCompanion.insert(
                  id: exerciseId,
                  sessionId: sessionId,
                  position: position * _gap,
                  plannedExerciseIdInSnapshot: exercise.id,
                  stateDiscriminator: 'unfinished',
                  substitutePayloadJson: const Value(null),
                  createdAtMs: nowMs,
                  updatedAtMs: nowMs,
                  schemaVersion: SchemaVersions.domain,
                ),
              );
          position++;
        }
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
  Future<domain.Session> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  }) async {
    return _db.transaction(() async {
      final exerciseRow = await _requireSessionExerciseRow(sessionExerciseId);
      final sessionRow = await _requireSessionRow(exerciseRow.sessionId);

      final measurementType = _measurementTypeForExercise(
        exerciseRow,
        sessionRow,
      );
      _validateActualValues(
        actualValues: actualValues,
        measurementType: measurementType,
        entityId: sessionExerciseId,
      );

      final existingSets =
          await (_db.select(_db.executedSets)
                ..where((t) => t.sessionExerciseId.equals(sessionExerciseId))
                ..orderBy([(t) => OrderingTerm.desc(t.position)]))
              .get();

      final maxExistingPos = existingSets.isEmpty
          ? 0
          : existingSets.first.position;
      final newSetPosition = existingSets.isEmpty
          ? _gap
          : maxExistingPos + _gap;

      final setId = _uuid.v4();
      final now = _clock.now().toUtc();
      final nowMs = utcToMs(now);
      final actualJson = actualValues.toJson();
      final actualDiscriminator = actualJson['type'] as String;
      final measurementDiscriminator = switch (measurementType) {
        RepBasedMeasurement() => 'repBased',
        TimeBasedMeasurement() => 'timeBased',
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

      final plannedSetCount = _plannedSetCountForExercise(
        exerciseRow,
        sessionRow,
      );
      final completedSetCount = existingSets.length + 1;

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      if (completedSetCount >= plannedSetCount &&
          exerciseRow.stateDiscriminator == 'unfinished') {
        final lockedPos = await _maxLockedPositionExcluding(
          exerciseRow.sessionId,
          excludeId: sessionExerciseId,
        );
        final newExercisePosition = lockedPos + 1;

        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(sessionExerciseId))).write(
          SessionExercisesCompanion(
            stateDiscriminator: const Value('completed'),
            position: Value(newExercisePosition),
            updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
          ),
        );

        await _renumberUnfinishedAfterLock(
          sessionId: exerciseRow.sessionId,
          lockedPosition: newExercisePosition,
          excludeId: sessionExerciseId,
        );
      } else {
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(sessionExerciseId))).write(
          SessionExercisesCompanion(
            updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
          ),
        );
      }

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

      final measurementType = _measurementTypeForExercise(
        exerciseRow,
        sessionRow,
      );
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

      final remaining = await (_db.select(
        _db.executedSets,
      )..where((t) => t.sessionExerciseId.equals(exerciseRow.id))).get();
      final plannedSetCount = _plannedSetCountForExercise(
        exerciseRow,
        sessionRow,
      );

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      if (exerciseRow.stateDiscriminator == 'completed' &&
          remaining.length < plannedSetCount) {
        final lockedPos = await _maxLockedPositionExcluding(
          exerciseRow.sessionId,
          excludeId: exerciseRow.id,
        );
        final newPosition = lockedPos + 1;

        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(exerciseRow.id))).write(
          SessionExercisesCompanion(
            stateDiscriminator: const Value('unfinished'),
            position: Value(newPosition),
            updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
          ),
        );

        await _renumberUnfinishedAfterLock(
          sessionId: exerciseRow.sessionId,
          lockedPosition: newPosition,
          excludeId: exerciseRow.id,
        );
      } else {
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(exerciseRow.id))).write(
          SessionExercisesCompanion(
            updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
          ),
        );
      }

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

      final lockedPos = await _maxLockedPositionExcluding(
        exerciseRow.sessionId,
        excludeId: sessionExerciseId,
      );
      final newPosition = lockedPos + 1;

      final exerciseUpdatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(exerciseRow.updatedAtMs),
        createdAt: msToUtc(exerciseRow.createdAtMs),
      );

      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(sessionExerciseId))).write(
        SessionExercisesCompanion(
          stateDiscriminator: const Value('skipped'),
          position: Value(newPosition),
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      await _renumberUnfinishedAfterLock(
        sessionId: exerciseRow.sessionId,
        lockedPosition: newPosition,
        excludeId: sessionExerciseId,
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
  Future<domain.Session> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    ExerciseMetadata? substituteMetadata,
  }) async {
    return _db.transaction(() async {
      final exerciseRow = await _requireSessionExerciseRow(sessionExerciseId);
      _requireUnfinished(exerciseRow);

      final substitute = SubstituteExercise(
        name: substituteName,
        measurementType: substituteMeasurementType,
        metadata: substituteMetadata,
      );
      final substituteJson = CanonicalJson.encode(substitute.toJson());

      final lockedPos = await _maxLockedPositionExcluding(
        exerciseRow.sessionId,
        excludeId: sessionExerciseId,
      );
      final newPosition = lockedPos + 1;

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
          position: Value(newPosition),
          updatedAtMs: Value(utcToMs(exerciseUpdatedAt)),
        ),
      );

      await _renumberUnfinishedAfterLock(
        sessionId: exerciseRow.sessionId,
        lockedPosition: newPosition,
        excludeId: sessionExerciseId,
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
      final lockedPos = await _maxLockedPosition(sessionId);

      for (var i = 0; i < orderedUnfinishedIds.length; i++) {
        final id = orderedUnfinishedIds[i];
        final exercise = exerciseById[id]!;
        final newPosition = lockedPos + (i + 1) * _gap;
        final updatedAt = _timestamps.nextUpdatedAt(
          previousUpdatedAt: msToUtc(exercise.updatedAtMs),
          createdAt: msToUtc(exercise.createdAtMs),
        );
        await (_db.update(
          _db.sessionExercises,
        )..where((t) => t.id.equals(id))).write(
          SessionExercisesCompanion(
            position: Value(newPosition),
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

  Future<int> _maxLockedPosition(String sessionId) async {
    final lockedExercises =
        await (_db.select(_db.sessionExercises)
              ..where(
                (t) =>
                    t.sessionId.equals(sessionId) &
                    t.stateDiscriminator.isNotIn(['unfinished']),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.position)]))
            .get();
    return lockedExercises.isEmpty ? 0 : lockedExercises.first.position;
  }

  Future<int> _maxLockedPositionExcluding(
    String sessionId, {
    required String excludeId,
  }) async {
    final lockedExercises =
        await (_db.select(_db.sessionExercises)
              ..where(
                (t) =>
                    t.sessionId.equals(sessionId) &
                    t.stateDiscriminator.isNotIn(['unfinished']) &
                    t.id.isNotValue(excludeId),
              )
              ..orderBy([(t) => OrderingTerm.desc(t.position)]))
            .get();
    return lockedExercises.isEmpty ? 0 : lockedExercises.first.position;
  }

  Future<void> _renumberUnfinishedAfterLock({
    required String sessionId,
    required int lockedPosition,
    required String excludeId,
  }) async {
    final unfinished =
        await (_db.select(_db.sessionExercises)
              ..where(
                (t) =>
                    t.sessionId.equals(sessionId) &
                    t.stateDiscriminator.equals('unfinished') &
                    t.id.isNotValue(excludeId),
              )
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

    for (var j = 0; j < unfinished.length; j++) {
      final row = unfinished[j];
      final newPos = lockedPosition + (j + 1) * _gap;
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(row.updatedAtMs),
        createdAt: msToUtc(row.createdAtMs),
      );
      await (_db.update(
        _db.sessionExercises,
      )..where((t) => t.id.equals(row.id))).write(
        SessionExercisesCompanion(
          position: Value(newPos),
          updatedAtMs: Value(utcToMs(updatedAt)),
        ),
      );
    }
  }

  domain.WorkoutDay _parseSnapshotWorkoutDay(Session sessionRow) {
    return domain.WorkoutDay.fromJson(
      jsonDecode(sessionRow.snapshotJson) as Map<String, dynamic>,
    );
  }

  MeasurementType _measurementTypeForExercise(
    SessionExercise exerciseRow,
    Session sessionRow,
  ) {
    final workoutDay = _parseSnapshotWorkoutDay(sessionRow);
    for (final group in workoutDay.exerciseGroups) {
      for (final exercise in group.exercises) {
        if (exercise.id == exerciseRow.plannedExerciseIdInSnapshot) {
          return exercise.measurementType;
        }
      }
    }
    throw NotFoundError(
      entityType: 'Exercise in snapshot',
      id: exerciseRow.plannedExerciseIdInSnapshot,
    );
  }

  int _plannedSetCountForExercise(
    SessionExercise exerciseRow,
    Session sessionRow,
  ) {
    final workoutDay = _parseSnapshotWorkoutDay(sessionRow);
    for (final group in workoutDay.exerciseGroups) {
      for (final exercise in group.exercises) {
        if (exercise.id == exerciseRow.plannedExerciseIdInSnapshot) {
          return exercise.sets.length;
        }
      }
    }
    return 0;
  }

  void _validateActualValues({
    required ActualSetValues actualValues,
    required MeasurementType measurementType,
    required String entityId,
  }) {
    final isValid = switch ((measurementType, actualValues)) {
      (RepBasedMeasurement(), ActualRepBased()) => true,
      (TimeBasedMeasurement(), ActualTimeBased()) => true,
      _ => false,
    };
    if (!isValid) {
      throw ValidationError(
        entityId: entityId,
        invariant: 'measurementType_actualValues_mismatch',
        message:
            'ActualSetValues variant does not match measurementType for $entityId',
      );
    }
  }
}
