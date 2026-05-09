import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';

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

    test('ActualSetValues round-trips through JSON', () {
      for (var i = 0; i < iterations; i++) {
        final v = anyActualSetValues(rng);
        expect(ActualSetValues.fromJson(v.toJson()), equals(v));
      }
    });
  });
}
