import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';

void main() {
  group('SubstituteExercise construction invariants', () {
    test('setCount must be >= 1', () {
      expect(
        () => SubstituteExercise(
          name: 'Bench',
          measurementType: const MeasurementType.repBased(),
          plannedValues: const PlannedSetValues.repBased(weightKg: 20, reps: 5),
          setCount: 0,
        ),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'setCount_positive',
          ),
        ),
      );
      expect(
        () => SubstituteExercise(
          name: 'Bench',
          measurementType: const MeasurementType.repBased(),
          plannedValues: const PlannedSetValues.repBased(weightKg: 20, reps: 5),
          setCount: -1,
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('plannedValues variant must match measurementType (repBased)', () {
      expect(
        () => SubstituteExercise(
          name: 'Bench',
          measurementType: const MeasurementType.repBased(),
          plannedValues: const PlannedSetValues.timeBased(durationSeconds: 30),
          setCount: 3,
        ),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'measurementType_plannedValues_mismatch',
          ),
        ),
      );
    });

    test('plannedValues variant must match measurementType (timeBased)', () {
      expect(
        () => SubstituteExercise(
          name: 'Plank',
          measurementType: const MeasurementType.timeBased(),
          plannedValues: const PlannedSetValues.repBased(weightKg: 0, reps: 5),
          setCount: 2,
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('accepts a valid repBased substitute', () {
      final sub = SubstituteExercise(
        name: 'Cable Fly',
        measurementType: const MeasurementType.repBased(),
        plannedValues: const PlannedSetValues.repBased(
          weightKg: 12.5,
          reps: 12,
        ),
        setCount: 4,
      );
      expect(sub.name, 'Cable Fly');
      expect(sub.setCount, 4);
    });

    test('accepts a valid timeBased substitute', () {
      final sub = SubstituteExercise(
        name: 'Wall Sit',
        measurementType: const MeasurementType.timeBased(),
        plannedValues: const PlannedSetValues.timeBased(durationSeconds: 45),
        setCount: 3,
      );
      expect(sub.plannedValues, isA<PlannedTimeBased>());
    });

    test('round-trips through JSON preserving plannedValues and setCount', () {
      final original = SubstituteExercise(
        name: 'Goblet Squat',
        measurementType: const MeasurementType.repBased(),
        plannedValues: const PlannedSetValues.repBased(weightKg: 16, reps: 10),
        setCount: 5,
      );
      final json = original.toJson();
      expect(json['plannedValues'], isNotNull);
      expect(json['setCount'], 5);
      final restored = SubstituteExercise.fromJson(json);
      expect(restored, equals(original));
    });
  });
}
