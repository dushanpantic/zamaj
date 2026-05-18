import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

import '../support/generators.dart';

void main() {
  const iterations = 100;
  final rng = Random(42);

  group('P9 – JSON round-trip', () {
    test('MeasurementType round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyMeasurementType(rng);
        expect(MeasurementType.fromJson(v.toJson()), equals(v));
      }
    });

    test('ExerciseGroupKind round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyExerciseGroupKind(rng);
        expect(ExerciseGroupKind.fromJson(v.toJson()), equals(v));
      }
    });

    test('ExerciseMetadata round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyExerciseMetadata(rng);
        expect(ExerciseMetadata.fromJson(v.toJson()), equals(v));
      }
    });

    test('SubstituteExercise round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anySubstituteExercise(rng);
        expect(SubstituteExercise.fromJson(v.toJson()), equals(v));
      }
    });

    test('ExerciseState round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyExerciseState(rng);
        expect(ExerciseState.fromJson(v.toJson()), equals(v));
      }
    });

    test('PlannedSetValues round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyPlannedSetValues(rng);
        expect(PlannedSetValues.fromJson(v.toJson()), equals(v));
      }
    });

    test('PlannedBodyweight serializes with "bodyweight" discriminator', () {
      // ignore: prefer_const_constructors
      final v = PlannedSetValues.bodyweight(
        repTarget: RepTarget.fixed(reps: 8),
      );
      final json = v.toJson();
      expect(json['type'], equals('bodyweight'));
      expect(PlannedSetValues.fromJson(json), equals(v));
    });

    test('ActualBodyweight serializes with "bodyweight" discriminator', () {
      const v = ActualSetValues.bodyweight(reps: 12);
      final json = v.toJson();
      expect(json['type'], equals('bodyweight'));
      expect(ActualSetValues.fromJson(json), equals(v));
    });

    test('ActualSetValues round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyActualSetValues(rng);
        expect(ActualSetValues.fromJson(v.toJson()), equals(v));
      }
    });

    test('Exercise with null plannedRestSeconds round-trips through JSON', () {
      final t0 = DateTime.utc(2024, 1, 15, 10, 0, 0);
      const mt = MeasurementType.repBased();
      final set = WorkoutSet(
        id: '55555555-5555-4555-8555-555555555555',
        exerciseId: '44444444-4444-4444-8444-444444444444',
        position: 0,
        measurementType: mt,
        plannedValues: PlannedSetValues.repBased(
          weightKg: 80.0,
          repTarget: RepTarget.fixed(reps: 8),
        ),
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );
      final exercise = Exercise(
        id: '44444444-4444-4444-8444-444444444444',
        exerciseGroupId: '33333333-3333-4333-8333-333333333333',
        position: 0,
        name: 'Bench Press',
        measurementType: mt,
        metadata: const ExerciseMetadata(
          notes: 'Squeeze at the top',
          videoUrl: 'https://example.com/bench-press',
        ),
        sets: [set],
        createdAt: t0,
        updatedAt: t0,
        schemaVersion: 1,
      );
      expect(Exercise.fromJson(exercise.toJson()), equals(exercise));
      expect(exercise.plannedRestSeconds, isNull);
    });

    test(
      'Exercise with non-null plannedRestSeconds round-trips through JSON',
      () {
        final t0 = DateTime.utc(2024, 1, 15, 10, 0, 0);
        const mt = MeasurementType.repBased();
        final set = WorkoutSet(
          id: '55555555-5555-4555-8555-555555555555',
          exerciseId: '44444444-4444-4444-8444-444444444444',
          position: 0,
          measurementType: mt,
          plannedValues: PlannedSetValues.repBased(
            weightKg: 80.0,
            repTarget: RepTarget.fixed(reps: 8),
          ),
          createdAt: t0,
          updatedAt: t0,
          schemaVersion: 1,
        );
        final exercise = Exercise(
          id: '44444444-4444-4444-8444-444444444444',
          exerciseGroupId: '33333333-3333-4333-8333-333333333333',
          position: 0,
          name: 'Bench Press',
          measurementType: mt,
          metadata: const ExerciseMetadata(
            notes: 'Squeeze at the top',
            videoUrl: 'https://example.com/bench-press',
          ),
          plannedRestSeconds: 90,
          sets: [set],
          createdAt: t0,
          updatedAt: t0,
          schemaVersion: 1,
        );
        expect(Exercise.fromJson(exercise.toJson()), equals(exercise));
        expect(exercise.plannedRestSeconds, equals(90));
      },
    );
  });
}
