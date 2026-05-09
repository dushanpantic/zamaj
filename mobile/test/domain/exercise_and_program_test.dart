import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

import '../support/generators.dart';

void main() {
  final rng = Random(200);

  WorkoutSet _makeSet({
    required String exerciseId,
    required MeasurementType measurementType,
    required PlannedSetValues plannedValues,
  }) {
    final now = anyUtcDateTime(rng);
    return WorkoutSet(
      id: anyUuidV4(rng),
      exerciseId: exerciseId,
      position: 0,
      measurementType: measurementType,
      plannedValues: plannedValues,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );
  }

  group('Exercise.measurementType ↔ set consistency', () {
    test('exercise with all matching sets constructs successfully', () {
      final exerciseId = anyUuidV4(rng);
      final now = anyUtcDateTime(rng);
      final exercise = Exercise(
        id: exerciseId,
        exerciseGroupId: anyUuidV4(rng),
        position: 0,
        name: 'Bench Press',
        measurementType: const MeasurementType.repBased(),
        metadata: ExerciseMetadata.empty,
        sets: [
          _makeSet(
            exerciseId: exerciseId,
            measurementType: const MeasurementType.repBased(),
            plannedValues: const PlannedSetValues.repBased(
              weightKg: 80.0,
              reps: 8,
            ),
          ),
          _makeSet(
            exerciseId: exerciseId,
            measurementType: const MeasurementType.repBased(),
            plannedValues: const PlannedSetValues.repBased(
              weightKg: 80.0,
              reps: 8,
            ),
          ),
        ],
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );
      expect(exercise.sets.length, equals(2));
      expect(exercise.measurementType, isA<RepBasedMeasurement>());
    });

    test('exercise with empty sets constructs successfully', () {
      final now = anyUtcDateTime(rng);
      final exercise = Exercise(
        id: anyUuidV4(rng),
        exerciseGroupId: anyUuidV4(rng),
        position: 0,
        name: 'Plank',
        measurementType: const MeasurementType.timeBased(),
        metadata: ExerciseMetadata.empty,
        sets: [],
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );
      expect(exercise.sets, isEmpty);
    });

    test(
      'exercise with mismatched set measurementType throws ValidationError',
      () {
        final exerciseId = anyUuidV4(rng);
        final now = anyUtcDateTime(rng);
        final mismatchedSet = _makeSet(
          exerciseId: exerciseId,
          measurementType: const MeasurementType.timeBased(),
          plannedValues: const PlannedSetValues.timeBased(durationSeconds: 60),
        );

        try {
          Exercise(
            id: exerciseId,
            exerciseGroupId: anyUuidV4(rng),
            position: 0,
            name: 'Bench Press',
            measurementType: const MeasurementType.repBased(),
            metadata: ExerciseMetadata.empty,
            sets: [mismatchedSet],
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          );
          fail('Expected ValidationError');
        } on ValidationError catch (e) {
          expect(e.entityId, equals(exerciseId));
          expect(e.invariant, equals('set_measurement_type_mismatch'));
        }
      },
    );

    test('only the first mismatched set triggers the error', () {
      final exerciseId = anyUuidV4(rng);
      final now = anyUtcDateTime(rng);
      final goodSet = _makeSet(
        exerciseId: exerciseId,
        measurementType: const MeasurementType.repBased(),
        plannedValues: const PlannedSetValues.repBased(
          weightKg: 60.0,
          reps: 10,
        ),
      );
      final badSet = _makeSet(
        exerciseId: exerciseId,
        measurementType: const MeasurementType.timeBased(),
        plannedValues: const PlannedSetValues.timeBased(durationSeconds: 30),
      );

      try {
        Exercise(
          id: exerciseId,
          exerciseGroupId: anyUuidV4(rng),
          position: 0,
          name: 'Mixed',
          measurementType: const MeasurementType.repBased(),
          metadata: ExerciseMetadata.empty,
          sets: [goodSet, badSet],
          createdAt: now,
          updatedAt: now,
          schemaVersion: 1,
        );
        fail('Expected ValidationError');
      } on ValidationError catch (e) {
        expect(e.entityId, equals(exerciseId));
        expect(e.invariant, equals('set_measurement_type_mismatch'));
      }
    });

    test('anyInconsistentExercise inputs always trigger ValidationError', () {
      final rng2 = Random(201);
      for (var i = 0; i < 100; i++) {
        final params = anyInconsistentExercise(rng2);
        final now = anyUtcDateTime(rng2);
        try {
          Exercise(
            id: params.id,
            exerciseGroupId: params.exerciseGroupId,
            position: 0,
            name: 'test',
            measurementType: params.measurementType,
            metadata: ExerciseMetadata.empty,
            sets: params.sets,
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          );
          fail('Expected ValidationError for inconsistent exercise');
        } on ValidationError catch (e) {
          expect(e.entityId, equals(params.id));
          expect(e.invariant, equals('set_measurement_type_mismatch'));
        }
      }
    });
  });

  group('Program UUID length assertion', () {
    test('program with valid 36-char UUID constructs successfully', () {
      final now = anyUtcDateTime(rng);
      final id = anyUuidV4(rng);
      expect(id.length, equals(36));
      final program = Program(
        id: id,
        name: 'Push Pull Legs',
        workoutDayIds: [],
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );
      expect(program.id.length, equals(36));
    });

    test(
      'program with too-short id fails assert in debug mode',
      () {
        final now = anyUtcDateTime(rng);
        expect(
          () => Program(
            id: 'too-short',
            name: 'Bad Program',
            workoutDayIds: [],
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
      skip: !_assertionsEnabled(),
    );

    test(
      'program with too-long id fails assert in debug mode',
      () {
        final now = anyUtcDateTime(rng);
        expect(
          () => Program(
            id: 'a' * 37,
            name: 'Bad Program',
            workoutDayIds: [],
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
          throwsA(isA<AssertionError>()),
        );
      },
      skip: !_assertionsEnabled(),
    );

    test('anyProgram generator always produces programs with 36-char ids', () {
      final rng2 = Random(202);
      for (var i = 0; i < 100; i++) {
        final program = anyProgram(rng2);
        expect(program.id.length, equals(36));
      }
    });
  });
}

bool _assertionsEnabled() {
  var enabled = false;
  assert(() {
    enabled = true;
    return true;
  }());
  return enabled;
}
