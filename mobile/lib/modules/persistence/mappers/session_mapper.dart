import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart' as domain;
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session.dart' as domain;
import 'package:zamaj/modules/domain/models/session_exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/session_note.dart' as domain;
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart';

class SessionMapper {
  domain.Session toDomain(
    Session row,
    List<SessionExercise> exerciseRows,
    List<ExecutedSet> setRows,
    List<SessionNote> noteRows,
    List<ExtraWorkItem> extraWorkRows,
  ) {
    final snapshot = _reconstructSnapshot(row);

    final sortedExercises = exerciseRows.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final sessionExercises = sortedExercises
        .map((e) => _exerciseToDomain(e, setRows))
        .toList();

    final notes = noteRows
        .map(
          (n) => domain.SessionNote(
            id: n.id,
            sessionId: n.sessionId,
            body: n.body,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              n.createdAtMs,
              isUtc: true,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              n.updatedAtMs,
              isUtc: true,
            ),
            schemaVersion: n.schemaVersion,
          ),
        )
        .toList();

    final sortedExtraWork = extraWorkRows.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final extraWork = sortedExtraWork
        .map(
          (e) => domain.ExtraWork(
            id: e.id,
            sessionId: e.sessionId,
            position: e.position,
            body: e.body,
            createdAt: DateTime.fromMillisecondsSinceEpoch(
              e.createdAtMs,
              isUtc: true,
            ),
            updatedAt: DateTime.fromMillisecondsSinceEpoch(
              e.updatedAtMs,
              isUtc: true,
            ),
            schemaVersion: e.schemaVersion,
          ),
        )
        .toList();

    return domain.Session(
      id: row.id,
      workoutDayId: row.workoutDayId,
      snapshot: snapshot,
      sessionExercises: sessionExercises,
      notes: notes,
      extraWork: extraWork,
      startedAt: DateTime.fromMillisecondsSinceEpoch(
        row.startedAtMs,
        isUtc: true,
      ),
      endedAt: row.endedAtMs != null
          ? DateTime.fromMillisecondsSinceEpoch(row.endedAtMs!, isUtc: true)
          : null,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  SessionSnapshot _reconstructSnapshot(Session row) {
    final recomputedHash = CanonicalJson.sha256Hex(row.snapshotJson);
    if (recomputedHash != row.snapshotHash) {
      throw DeserializationError(
        field: 'sessionSnapshot',
        discriminator: 'sha256Hash',
        message:
            'Snapshot hash mismatch: stored ${row.snapshotHash}, recomputed $recomputedHash',
      );
    }

    final workoutDay = domain.WorkoutDay.fromJson(
      jsonDecode(row.snapshotJson) as Map<String, dynamic>,
    );

    return SessionSnapshot(
      workoutDay: workoutDay,
      canonicalJson: row.snapshotJson,
      sha256Hash: row.snapshotHash,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  domain.SessionExercise _exerciseToDomain(
    SessionExercise row,
    List<ExecutedSet> setRows,
  ) {
    final state = _reconstructState(row);

    final sortedSets =
        setRows.where((s) => s.sessionExerciseId == row.id).toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    final executedSets = sortedSets.map(_executedSetToDomain).toList();

    return domain.SessionExercise(
      id: row.id,
      sessionId: row.sessionId,
      position: row.position,
      plannedExerciseIdInSnapshot: row.plannedExerciseIdInSnapshot,
      state: state,
      executedSets: executedSets,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  ExerciseState _reconstructState(SessionExercise row) {
    return switch (row.stateDiscriminator) {
      'unfinished' => const ExerciseState.unfinished(),
      'completed' => const ExerciseState.completed(),
      'skipped' => const ExerciseState.skipped(),
      'replaced' => ExerciseState.replaced(
        substitute: SubstituteExercise.fromJson(
          jsonDecode(row.substitutePayloadJson!) as Map<String, dynamic>,
        ),
      ),
      final d => throw DeserializationError(
        field: 'stateDiscriminator',
        discriminator: d,
        message: 'Unknown stateDiscriminator: $d',
      ),
    };
  }

  domain.ExecutedSet _executedSetToDomain(ExecutedSet row) {
    final actualValues = ActualSetValues.fromJson(
      jsonDecode(row.actualValuesPayloadJson) as Map<String, dynamic>,
    );

    final measurementType = switch (actualValues) {
      ActualRepBased() => const MeasurementType.repBased(),
      ActualTimeBased() => const MeasurementType.timeBased(),
    };

    return domain.ExecutedSet(
      id: row.id,
      sessionExerciseId: row.sessionExerciseId,
      position: row.position,
      measurementType: measurementType,
      actualValues: actualValues,
      plannedSetIdInSnapshot: row.plannedSetIdInSnapshot,
      completedAt: DateTime.fromMillisecondsSinceEpoch(
        row.completedAtMs,
        isUtc: true,
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  SessionsCompanion sessionToRow(domain.Session session) {
    return SessionsCompanion(
      id: Value(session.id),
      workoutDayId: Value(session.workoutDayId),
      snapshotJson: Value(session.snapshot.canonicalJson),
      snapshotHash: Value(session.snapshot.sha256Hash),
      startedAtMs: Value(session.startedAt.millisecondsSinceEpoch),
      endedAtMs: Value(session.endedAt?.millisecondsSinceEpoch),
      createdAtMs: Value(session.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(session.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(session.schemaVersion),
    );
  }

  SessionExercisesCompanion sessionExerciseToRow(
    domain.SessionExercise exercise,
  ) {
    final (discriminator, substituteJson) = switch (exercise.state) {
      UnfinishedState() => ('unfinished', null),
      CompletedState() => ('completed', null),
      SkippedState() => ('skipped', null),
      ReplacedState(:final substitute) => (
        'replaced',
        CanonicalJson.encode(substitute.toJson()),
      ),
    };

    return SessionExercisesCompanion(
      id: Value(exercise.id),
      sessionId: Value(exercise.sessionId),
      position: Value(exercise.position),
      plannedExerciseIdInSnapshot: Value(exercise.plannedExerciseIdInSnapshot),
      stateDiscriminator: Value(discriminator),
      substitutePayloadJson: Value(substituteJson),
      createdAtMs: Value(exercise.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(exercise.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(exercise.schemaVersion),
    );
  }

  ExecutedSetsCompanion executedSetToRow(domain.ExecutedSet set) {
    final actualJson = set.actualValues.toJson();
    final actualDiscriminator = actualJson['type'] as String;

    final measurementDiscriminator = switch (set.measurementType) {
      RepBasedMeasurement() => 'repBased',
      TimeBasedMeasurement() => 'timeBased',
    };

    return ExecutedSetsCompanion(
      id: Value(set.id),
      sessionExerciseId: Value(set.sessionExerciseId),
      position: Value(set.position),
      measurementTypeDiscriminator: Value(measurementDiscriminator),
      actualValuesDiscriminator: Value(actualDiscriminator),
      actualValuesPayloadJson: Value(CanonicalJson.encode(actualJson)),
      plannedSetIdInSnapshot: Value(set.plannedSetIdInSnapshot),
      completedAtMs: Value(set.completedAt.millisecondsSinceEpoch),
      createdAtMs: Value(set.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(set.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(set.schemaVersion),
    );
  }

  SessionNotesCompanion sessionNoteToRow(domain.SessionNote note) {
    return SessionNotesCompanion(
      id: Value(note.id),
      sessionId: Value(note.sessionId),
      body: Value(note.body),
      createdAtMs: Value(note.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(note.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(note.schemaVersion),
    );
  }

  ExtraWorkItemsCompanion extraWorkToRow(domain.ExtraWork extraWork) {
    return ExtraWorkItemsCompanion(
      id: Value(extraWork.id),
      sessionId: Value(extraWork.sessionId),
      position: Value(extraWork.position),
      body: Value(extraWork.body),
      createdAtMs: Value(extraWork.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(extraWork.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(extraWork.schemaVersion),
    );
  }
}
