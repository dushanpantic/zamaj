import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';

import '../support/generators.dart';

Map<String, dynamic> _corruptDiscriminator(
  Map<String, dynamic> json,
  Random rng,
) {
  final corrupted = Map<String, dynamic>.from(json);
  corrupted['type'] = 'unknown_${anyUuidV4(rng).replaceAll('-', '')}';
  return corrupted;
}

Map<String, dynamic> _dropField(Map<String, dynamic> json, String field) {
  final corrupted = Map<String, dynamic>.from(json);
  corrupted.remove(field);
  return corrupted;
}

void _assertDeserializationError(void Function() fn, String expectedField) {
  try {
    fn();
    fail('Expected DeserializationError but no exception was thrown');
  } on DeserializationError catch (e) {
    expect(
      e.field,
      equals(expectedField),
      reason: 'DeserializationError.field should name the offending field',
    );
  }
}

void main() {
  const iterations = 100;
  final rng = Random(99);

  group('P10 – Typed deserialization error naming', () {
    group('MeasurementType', () {
      test('unknown discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyMeasurementType(rng);
          final corrupted = _corruptDiscriminator(v.toJson(), rng);
          _assertDeserializationError(
            () => MeasurementType.fromJson(corrupted),
            'type',
          );
        }
      });

      test('missing discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyMeasurementType(rng);
          final corrupted = _dropField(v.toJson(), 'type');
          _assertDeserializationError(
            () => MeasurementType.fromJson(corrupted),
            'type',
          );
        }
      });
    });

    group('ExerciseGroupKind', () {
      test('unknown discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExerciseGroupKind(rng);
          final corrupted = _corruptDiscriminator(v.toJson(), rng);
          _assertDeserializationError(
            () => ExerciseGroupKind.fromJson(corrupted),
            'type',
          );
        }
      });

      test('missing discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExerciseGroupKind(rng);
          final corrupted = _dropField(v.toJson(), 'type');
          _assertDeserializationError(
            () => ExerciseGroupKind.fromJson(corrupted),
            'type',
          );
        }
      });
    });

    group('ExerciseState', () {
      test('unknown discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExerciseState(rng);
          final corrupted = _corruptDiscriminator(v.toJson(), rng);
          _assertDeserializationError(
            () => ExerciseState.fromJson(corrupted),
            'type',
          );
        }
      });

      test('missing discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyExerciseState(rng);
          final corrupted = _dropField(v.toJson(), 'type');
          _assertDeserializationError(
            () => ExerciseState.fromJson(corrupted),
            'type',
          );
        }
      });

      test('replaced variant with missing substitute names the field', () {
        for (var i = 0; i < iterations; i++) {
          final json = <String, dynamic>{'type': 'replaced'};
          _assertDeserializationError(
            () => ExerciseState.fromJson(json),
            'substitute',
          );
        }
      });
    });

    group('PlannedSetValues', () {
      test('unknown discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyPlannedSetValues(rng);
          final corrupted = _corruptDiscriminator(v.toJson(), rng);
          _assertDeserializationError(
            () => PlannedSetValues.fromJson(corrupted),
            'type',
          );
        }
      });

      test('missing discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyPlannedSetValues(rng);
          final corrupted = _dropField(v.toJson(), 'type');
          _assertDeserializationError(
            () => PlannedSetValues.fromJson(corrupted),
            'type',
          );
        }
      });
    });

    group('ActualSetValues', () {
      test('unknown discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyActualSetValues(rng);
          final corrupted = _corruptDiscriminator(v.toJson(), rng);
          _assertDeserializationError(
            () => ActualSetValues.fromJson(corrupted),
            'type',
          );
        }
      });

      test('missing discriminator names the type field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anyActualSetValues(rng);
          final corrupted = _dropField(v.toJson(), 'type');
          _assertDeserializationError(
            () => ActualSetValues.fromJson(corrupted),
            'type',
          );
        }
      });
    });

    group('SubstituteExercise', () {
      test('missing required name field names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySubstituteExercise(rng);
          final corrupted = _dropField(v.toJson(), 'name');
          _assertDeserializationError(
            () => SubstituteExercise.fromJson(corrupted),
            'name',
          );
        }
      });

      test('missing required measurementType field names the field', () {
        for (var i = 0; i < iterations; i++) {
          final v = anySubstituteExercise(rng);
          final corrupted = _dropField(v.toJson(), 'measurementType');
          _assertDeserializationError(
            () => SubstituteExercise.fromJson(corrupted),
            'measurementType',
          );
        }
      });
    });
  });
}
