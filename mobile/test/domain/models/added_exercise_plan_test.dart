import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';

void main() {
  group('AddedExercisePlan construction invariants', () {
    test('setCount must be >= 1', () {
      expect(
        () => AddedExercisePlan(
          name: 'Bench',
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: 20,
            repTarget: RepTarget.fixed(reps: 5),
          ),
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
    });

    test('plannedValues variant must match measurementType', () {
      expect(
        () => AddedExercisePlan(
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

    test('libraryExerciseId must be a 36-char UUID when present', () {
      expect(
        () => AddedExercisePlan(
          name: 'Bench',
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: 20,
            repTarget: RepTarget.fixed(reps: 5),
          ),
          setCount: 3,
          libraryExerciseId: 'too-short',
        ),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'libraryExerciseId_not_uuid_v4',
          ),
        ),
      );
    });

    test('accepts a valid one-off (unlinked) plan', () {
      final plan = AddedExercisePlan(
        name: 'Cable Fly',
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 12.5,
          repTarget: RepTarget.fixed(reps: 12),
        ),
        setCount: 4,
      );
      expect(plan.name, 'Cable Fly');
      expect(plan.setCount, 4);
      expect(plan.libraryExerciseId, isNull);
    });

    test('accepts a valid library-linked plan with metadata', () {
      const libraryId = '11111111-1111-4111-8111-111111111111';
      final plan = AddedExercisePlan(
        name: 'Goblet Squat',
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 16,
          repTarget: RepTarget.fixed(reps: 10),
        ),
        setCount: 5,
        libraryExerciseId: libraryId,
        metadata: const ExerciseMetadata(videoUrl: 'https://example.com/v'),
      );
      expect(plan.libraryExerciseId, libraryId);
      expect(plan.metadata?.videoUrl, 'https://example.com/v');
    });

    test('round-trips through JSON preserving plannedValues and setCount', () {
      final original = AddedExercisePlan(
        name: 'Goblet Squat',
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 16,
          repTarget: RepTarget.fixed(reps: 10),
        ),
        setCount: 5,
      );
      final json = original.toJson();
      expect(json['setCount'], 5);
      final restored = AddedExercisePlan.fromJson(json);
      expect(restored, equals(original));
    });
  });
}
