import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';

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
        _encode(ExerciseState.replaced(substitute: substitute).toJson()),
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
}
