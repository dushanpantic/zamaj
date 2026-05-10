import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_note.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

String _golden(String name) {
  final file = File('test/serialization/golden/$name.json');
  return file.readAsStringSync().trim();
}

String _encode(Map<String, dynamic> json) => jsonEncode(json);

void main() {
  group('Golden JSON fixtures – wire format lock', () {
    test('MeasurementType.repBased', () {
      expect(
        _encode(const MeasurementType.repBased().toJson()),
        equals(_golden('measurement_type_rep_based')),
      );
    });

    test('MeasurementType.timeBased', () {
      expect(
        _encode(const MeasurementType.timeBased().toJson()),
        equals(_golden('measurement_type_time_based')),
      );
    });

    test('ExerciseGroupKind.single', () {
      expect(
        _encode(const ExerciseGroupKind.single().toJson()),
        equals(_golden('exercise_group_kind_single')),
      );
    });

    test('ExerciseGroupKind.superset', () {
      expect(
        _encode(const ExerciseGroupKind.superset().toJson()),
        equals(_golden('exercise_group_kind_superset')),
      );
    });

    test('ExerciseState.unfinished', () {
      expect(
        _encode(const ExerciseState.unfinished().toJson()),
        equals(_golden('exercise_state_unfinished')),
      );
    });

    test('ExerciseState.completed', () {
      expect(
        _encode(const ExerciseState.completed().toJson()),
        equals(_golden('exercise_state_completed')),
      );
    });

    test('ExerciseState.skipped', () {
      expect(
        _encode(const ExerciseState.skipped().toJson()),
        equals(_golden('exercise_state_skipped')),
      );
    });

    test('ExerciseState.replaced', () {
      const substitute = SubstituteExercise(
        name: 'Dumbbell Press',
        measurementType: MeasurementType.repBased(),
        metadata: null,
      );
      expect(
        _encode(const ExerciseState.replaced(substitute: substitute).toJson()),
        equals(_golden('exercise_state_replaced')),
      );
    });

    test('PlannedSetValues.repBased', () {
      expect(
        _encode(
          const PlannedSetValues.repBased(weightKg: 60.0, reps: 10).toJson(),
        ),
        equals(_golden('planned_set_values_rep_based')),
      );
    });

    test('PlannedSetValues.timeBased', () {
      expect(
        _encode(const PlannedSetValues.timeBased(durationSeconds: 30).toJson()),
        equals(_golden('planned_set_values_time_based')),
      );
    });

    test('ActualSetValues.repBased', () {
      expect(
        _encode(
          const ActualSetValues.repBased(weightKg: 62.5, reps: 8).toJson(),
        ),
        equals(_golden('actual_set_values_rep_based')),
      );
    });

    test('ActualSetValues.timeBased', () {
      expect(
        _encode(const ActualSetValues.timeBased(durationSeconds: 45).toJson()),
        equals(_golden('actual_set_values_time_based')),
      );
    });
  });

  group('Golden JSON fixtures – aggregate wire format lock', () {
    final t0 = DateTime.utc(2024, 1, 15, 10, 0, 0);
    final t1 = DateTime.utc(2024, 1, 15, 10, 30, 0);
    final t2 = DateTime.utc(2024, 1, 15, 11, 0, 0);

    const programId = '11111111-1111-4111-8111-111111111111';
    const workoutDayId = '22222222-2222-4222-8222-222222222222';
    const exerciseGroupId = '33333333-3333-4333-8333-333333333333';
    const exerciseId = '44444444-4444-4444-8444-444444444444';
    const setId = '55555555-5555-4555-8555-555555555555';
    const sessionId = '66666666-6666-4666-8666-666666666666';
    const sessionExerciseId = '77777777-7777-4777-8777-777777777777';
    const executedSetId = '88888888-8888-4888-8888-888888888888';
    const sessionNoteId = '99999999-9999-4999-8999-999999999999';
    const extraWorkId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

    const metadata = ExerciseMetadata(
      notes: 'Squeeze at the top',
      videoUrl: 'https://example.com/bench-press',
    );

    late WorkoutSet workoutSet;
    late Exercise exercise;
    late ExerciseGroup exerciseGroup;
    late WorkoutDay workoutDay;

    setUp(() {
      workoutSet = WorkoutSet(
        id: setId,
        exerciseId: exerciseId,
        position: 0,
        measurementType: const MeasurementType.repBased(),
        plannedValues: const PlannedSetValues.repBased(weightKg: 80.0, reps: 8),
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );

      exercise = Exercise(
        id: exerciseId,
        exerciseGroupId: exerciseGroupId,
        position: 0,
        name: 'Bench Press',
        measurementType: const MeasurementType.repBased(),
        metadata: metadata,
        sets: [workoutSet],
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );

      exerciseGroup = ExerciseGroup(
        id: exerciseGroupId,
        workoutDayId: workoutDayId,
        position: 0,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercise],
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );

      workoutDay = WorkoutDay(
        id: workoutDayId,
        programId: programId,
        name: 'Upper A',
        exerciseGroups: [exerciseGroup],
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );
    });

    test('ExerciseMetadata', () {
      expect(_encode(metadata.toJson()), equals(_golden('exercise_metadata')));
    });

    test('WorkoutSet', () {
      expect(_encode(workoutSet.toJson()), equals(_golden('workout_set')));
    });

    test('Exercise', () {
      expect(_encode(exercise.toJson()), equals(_golden('exercise')));
    });

    test('Exercise with plannedRestSeconds', () {
      final exerciseWithRest = Exercise(
        id: exerciseId,
        exerciseGroupId: exerciseGroupId,
        position: 0,
        name: 'Bench Press',
        measurementType: const MeasurementType.repBased(),
        metadata: metadata,
        plannedRestSeconds: 90,
        sets: [workoutSet],
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );
      expect(
        _encode(exerciseWithRest.toJson()),
        equals(_golden('exercise_with_rest')),
      );
    });

    test('ExerciseGroup', () {
      expect(
        _encode(exerciseGroup.toJson()),
        equals(_golden('exercise_group')),
      );
    });

    test('WorkoutDay', () {
      expect(_encode(workoutDay.toJson()), equals(_golden('workout_day')));
    });

    test('Program', () {
      final program = Program(
        id: programId,
        name: 'Hypertrophy Block',
        workoutDayIds: [workoutDayId],
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );
      expect(_encode(program.toJson()), equals(_golden('program')));
    });

    test('SubstituteExercise', () {
      const substitute = SubstituteExercise(
        name: 'Dumbbell Press',
        measurementType: MeasurementType.repBased(),
        metadata: ExerciseMetadata(notes: 'Use 30kg dumbbells'),
      );
      expect(
        _encode(substitute.toJson()),
        equals(_golden('substitute_exercise')),
      );
    });

    test('ExecutedSet', () {
      final executedSet = ExecutedSet(
        id: executedSetId,
        sessionExerciseId: sessionExerciseId,
        position: 0,
        measurementType: const MeasurementType.repBased(),
        actualValues: const ActualSetValues.repBased(weightKg: 82.5, reps: 7),
        plannedSetIdInSnapshot: setId,
        completedAt: t1,
        createdAt: t1,
        updatedAt: t1,
        schemaVersion: 1,
      );
      expect(_encode(executedSet.toJson()), equals(_golden('executed_set')));
    });

    test('SessionExercise', () {
      final executedSet = ExecutedSet(
        id: executedSetId,
        sessionExerciseId: sessionExerciseId,
        position: 0,
        measurementType: const MeasurementType.repBased(),
        actualValues: const ActualSetValues.repBased(weightKg: 82.5, reps: 7),
        plannedSetIdInSnapshot: setId,
        completedAt: t1,
        createdAt: t1,
        updatedAt: t1,
        schemaVersion: 1,
      );
      final sessionExercise = SessionExercise(
        id: sessionExerciseId,
        sessionId: sessionId,
        position: 0,
        plannedExerciseIdInSnapshot: exerciseId,
        state: const ExerciseState.completed(),
        executedSets: [executedSet],
        createdAt: t1,
        updatedAt: t1,
        schemaVersion: 1,
      );
      expect(
        _encode(sessionExercise.toJson()),
        equals(_golden('session_exercise')),
      );
    });

    test('SessionNote', () {
      final sessionNote = SessionNote(
        id: sessionNoteId,
        sessionId: sessionId,
        body: 'Felt strong today',
        createdAt: t1,
        updatedAt: t1,
        schemaVersion: 1,
      );
      expect(_encode(sessionNote.toJson()), equals(_golden('session_note')));
    });

    test('ExtraWork', () {
      final extraWork = ExtraWork(
        id: extraWorkId,
        sessionId: sessionId,
        position: 0,
        body: '10 min treadmill cooldown',
        createdAt: t2,
        updatedAt: t2,
        schemaVersion: 1,
      );
      expect(_encode(extraWork.toJson()), equals(_golden('extra_work')));
    });

    test('SessionSnapshot', () {
      final snapshotJson = CanonicalJson.encode(workoutDay.toJson());
      final snapshotHash = CanonicalJson.sha256Hex(snapshotJson);
      final snapshot = SessionSnapshot(
        workoutDay: workoutDay,
        canonicalJson: snapshotJson,
        sha256Hash: snapshotHash,
        capturedAt: t0,
        schemaVersion: 1,
      );
      expect(_encode(snapshot.toJson()), equals(_golden('session_snapshot')));
    });

    test('Session', () {
      final executedSet = ExecutedSet(
        id: executedSetId,
        sessionExerciseId: sessionExerciseId,
        position: 0,
        measurementType: const MeasurementType.repBased(),
        actualValues: const ActualSetValues.repBased(weightKg: 82.5, reps: 7),
        plannedSetIdInSnapshot: setId,
        completedAt: t1,
        createdAt: t1,
        updatedAt: t1,
        schemaVersion: 1,
      );
      final sessionExercise = SessionExercise(
        id: sessionExerciseId,
        sessionId: sessionId,
        position: 0,
        plannedExerciseIdInSnapshot: exerciseId,
        state: const ExerciseState.completed(),
        executedSets: [executedSet],
        createdAt: t1,
        updatedAt: t1,
        schemaVersion: 1,
      );
      final sessionNote = SessionNote(
        id: sessionNoteId,
        sessionId: sessionId,
        body: 'Felt strong today',
        createdAt: t1,
        updatedAt: t1,
        schemaVersion: 1,
      );
      final extraWork = ExtraWork(
        id: extraWorkId,
        sessionId: sessionId,
        position: 0,
        body: '10 min treadmill cooldown',
        createdAt: t2,
        updatedAt: t2,
        schemaVersion: 1,
      );
      final snapshotJson = CanonicalJson.encode(workoutDay.toJson());
      final snapshotHash = CanonicalJson.sha256Hex(snapshotJson);
      final snapshot = SessionSnapshot(
        workoutDay: workoutDay,
        canonicalJson: snapshotJson,
        sha256Hash: snapshotHash,
        capturedAt: t0,
        schemaVersion: 1,
      );
      final session = Session(
        id: sessionId,
        workoutDayId: workoutDayId,
        snapshot: snapshot,
        sessionExercises: [sessionExercise],
        notes: [sessionNote],
        extraWork: [extraWork],
        startedAt: t0,
        endedAt: t2,
        createdAt: t0,
        updatedAt: t2,
        schemaVersion: 1,
      );
      expect(_encode(session.toJson()), equals(_golden('session')));
    });
  });
}
