import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';

void main() {
  group('SubstituteExercise.libraryExerciseId serialization', () {
    test('round-trips with libraryExerciseId set', () {
      final original = SubstituteExercise(
        name: 'Cable Fly',
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 12.5,
          repTarget: RepTarget.fixed(reps: 12),
        ),
        setCount: 4,
        libraryExerciseId: '11111111-1111-4111-8111-111111111111',
      );

      final json = original.toJson();
      expect(
        json['libraryExerciseId'],
        equals('11111111-1111-4111-8111-111111111111'),
      );

      final restored = SubstituteExercise.fromJson(json);
      expect(restored, equals(original));
      expect(
        restored.libraryExerciseId,
        equals('11111111-1111-4111-8111-111111111111'),
      );
    });

    test('round-trips with libraryExerciseId null', () {
      final original = SubstituteExercise(
        name: 'Cable Fly',
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 12.5,
          repTarget: RepTarget.fixed(reps: 12),
        ),
        setCount: 4,
      );

      final restored = SubstituteExercise.fromJson(original.toJson());
      expect(restored, equals(original));
      expect(restored.libraryExerciseId, isNull);
    });

    test('pre-v8 payload (no libraryExerciseId key) decodes to null', () {
      // A SubstituteExercise payload as written before the libraryExerciseId
      // field existed. The decoder must default missing keys to null so old
      // session_exercises rows continue to load.
      final preV8 = <String, dynamic>{
        'name': 'Cable Fly',
        'measurementType': {'type': 'repBased'},
        'plannedValues': {
          'type': 'repBased',
          'weightKg': 12.5,
          'repTarget': {'type': 'fixed', 'reps': 12},
        },
        'setCount': 4,
        // No 'metadata', no 'libraryExerciseId'.
      };

      final restored = SubstituteExercise.fromJson(preV8);
      expect(restored.libraryExerciseId, isNull);
      expect(restored.name, equals('Cable Fly'));
      expect(restored.setCount, equals(4));
    });

    test('non-UUID libraryExerciseId rejected by domain validation', () {
      expect(
        () => SubstituteExercise(
          name: 'Cable Fly',
          measurementType: const MeasurementType.repBased(),
          plannedValues: PlannedSetValues.repBased(
            weightKg: 12.5,
            repTarget: RepTarget.fixed(reps: 12),
          ),
          setCount: 4,
          libraryExerciseId: 'not-a-uuid',
        ),
        throwsA(isA<Exception>()),
      );
    });
  });
}
