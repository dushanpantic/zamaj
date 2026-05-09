import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

import '../support/generators.dart';

void main() {
  group('Property 1: WorkoutSet value consistency', () {
    test('valid repBased sets construct without error', () {
      final rng = Random(42);
      for (var i = 0; i < 100; i++) {
        final mt = const MeasurementType.repBased();
        final set = anyWorkoutSet(rng, mt);
        expect(set.measurementType, equals(mt));
        expect(set.plannedValues, isA<PlannedRepBased>());
      }
    });

    test('valid timeBased sets construct without error', () {
      final rng = Random(43);
      for (var i = 0; i < 100; i++) {
        final mt = const MeasurementType.timeBased();
        final set = anyWorkoutSet(rng, mt);
        expect(set.measurementType, equals(mt));
        expect(set.plannedValues, isA<PlannedTimeBased>());
      }
    });

    test(
      'variant mismatch throws ValidationError with correct entityId and invariant',
      () {
        final rng = Random(44);
        for (var i = 0; i < 100; i++) {
          final id = anyUuidV4(rng);
          final now = anyUtcDateTime(rng);

          final error = _expectValidationError(
            () => WorkoutSet(
              id: id,
              exerciseId: anyUuidV4(rng),
              position: 0,
              measurementType: const MeasurementType.repBased(),
              plannedValues: PlannedSetValues.timeBased(durationSeconds: 30),
              createdAt: now,
              updatedAt: now,
              schemaVersion: 1,
            ),
          );
          expect(error.entityId, equals(id));
          expect(error.invariant, equals('plannedValues_variant_mismatch'));
        }
      },
    );

    test('timeBased with repBased values throws ValidationError', () {
      final rng = Random(45);
      for (var i = 0; i < 100; i++) {
        final id = anyUuidV4(rng);
        final now = anyUtcDateTime(rng);

        final error = _expectValidationError(
          () => WorkoutSet(
            id: id,
            exerciseId: anyUuidV4(rng),
            position: 0,
            measurementType: const MeasurementType.timeBased(),
            plannedValues: PlannedSetValues.repBased(weightKg: 60.0, reps: 10),
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
        );
        expect(error.entityId, equals(id));
        expect(error.invariant, equals('plannedValues_variant_mismatch'));
      }
    });

    test('negative weightKg throws ValidationError with correct invariant', () {
      final rng = Random(46);
      for (var i = 0; i < 100; i++) {
        final id = anyUuidV4(rng);
        final now = anyUtcDateTime(rng);
        final negativeWeight = -(0.5 + rng.nextInt(200) * 0.5);

        final error = _expectValidationError(
          () => WorkoutSet(
            id: id,
            exerciseId: anyUuidV4(rng),
            position: 0,
            measurementType: const MeasurementType.repBased(),
            plannedValues: PlannedSetValues.repBased(
              weightKg: negativeWeight,
              reps: 5,
            ),
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
        );
        expect(error.entityId, equals(id));
        expect(error.invariant, equals('weightKg_non_negative'));
      }
    });

    test('weightKg not a multiple of 0.5 throws ValidationError', () {
      final rng = Random(47);
      final invalidWeights = [0.1, 0.3, 1.1, 2.7, 10.25, 100.1];
      for (var i = 0; i < 100; i++) {
        final id = anyUuidV4(rng);
        final now = anyUtcDateTime(rng);
        final weight = invalidWeights[rng.nextInt(invalidWeights.length)];

        final error = _expectValidationError(
          () => WorkoutSet(
            id: id,
            exerciseId: anyUuidV4(rng),
            position: 0,
            measurementType: const MeasurementType.repBased(),
            plannedValues: PlannedSetValues.repBased(weightKg: weight, reps: 5),
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
        );
        expect(error.entityId, equals(id));
        expect(error.invariant, equals('weightKg_half_kg_resolution'));
      }
    });

    test('negative reps throws ValidationError', () {
      final rng = Random(48);
      for (var i = 0; i < 100; i++) {
        final id = anyUuidV4(rng);
        final now = anyUtcDateTime(rng);
        final negativeReps = -(1 + rng.nextInt(50));

        final error = _expectValidationError(
          () => WorkoutSet(
            id: id,
            exerciseId: anyUuidV4(rng),
            position: 0,
            measurementType: const MeasurementType.repBased(),
            plannedValues: PlannedSetValues.repBased(
              weightKg: 60.0,
              reps: negativeReps,
            ),
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
        );
        expect(error.entityId, equals(id));
        expect(error.invariant, equals('reps_non_negative'));
      }
    });

    test('negative durationSeconds throws ValidationError', () {
      final rng = Random(49);
      for (var i = 0; i < 100; i++) {
        final id = anyUuidV4(rng);
        final now = anyUtcDateTime(rng);
        final negativeDuration = -(1 + rng.nextInt(300));

        final error = _expectValidationError(
          () => WorkoutSet(
            id: id,
            exerciseId: anyUuidV4(rng),
            position: 0,
            measurementType: const MeasurementType.timeBased(),
            plannedValues: PlannedSetValues.timeBased(
              durationSeconds: negativeDuration,
            ),
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
        );
        expect(error.entityId, equals(id));
        expect(error.invariant, equals('durationSeconds_non_negative'));
      }
    });

    test('zero weightKg and zero reps are valid (boundary)', () {
      final rng = Random(50);
      final now = anyUtcDateTime(rng);
      final set = WorkoutSet(
        id: anyUuidV4(rng),
        exerciseId: anyUuidV4(rng),
        position: 0,
        measurementType: const MeasurementType.repBased(),
        plannedValues: const PlannedSetValues.repBased(weightKg: 0.0, reps: 0),
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );
      expect(set.plannedValues, isA<PlannedRepBased>());
    });

    test('zero durationSeconds is valid (boundary)', () {
      final rng = Random(51);
      final now = anyUtcDateTime(rng);
      final set = WorkoutSet(
        id: anyUuidV4(rng),
        exerciseId: anyUuidV4(rng),
        position: 0,
        measurementType: const MeasurementType.timeBased(),
        plannedValues: const PlannedSetValues.timeBased(durationSeconds: 0),
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );
      expect(set.plannedValues, isA<PlannedTimeBased>());
    });
  });
}

ValidationError _expectValidationError(void Function() fn) {
  try {
    fn();
    fail('Expected ValidationError but no exception was thrown');
  } on ValidationError catch (e) {
    return e;
  }
}
