import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

void main() {
  group('Exercise plannedRestSeconds invariant', () {
    test('accepts null plannedRestSeconds', () {
      final exercise = _buildExercise(plannedRestSeconds: null);
      expect(exercise.plannedRestSeconds, isNull);
    });

    test('accepts 0 plannedRestSeconds', () {
      final exercise = _buildExercise(plannedRestSeconds: 0);
      expect(exercise.plannedRestSeconds, equals(0));
    });

    test('accepts 3600 plannedRestSeconds', () {
      final exercise = _buildExercise(plannedRestSeconds: 3600);
      expect(exercise.plannedRestSeconds, equals(3600));
    });

    test('rejects -1 with plannedRestSeconds_out_of_range invariant', () {
      final error = _expectValidationError(
        () => _buildExercise(plannedRestSeconds: -1),
      );
      expect(error.invariant, equals('plannedRestSeconds_out_of_range'));
    });

    test('rejects 3601 with plannedRestSeconds_out_of_range invariant', () {
      final error = _expectValidationError(
        () => _buildExercise(plannedRestSeconds: 3601),
      );
      expect(error.invariant, equals('plannedRestSeconds_out_of_range'));
    });
  });
}

Exercise _buildExercise({int? plannedRestSeconds}) {
  const id = '00000000-0000-4000-8000-000000000001';
  const groupId = '00000000-0000-4000-8000-000000000002';
  final now = DateTime.utc(2024);
  return Exercise(
    id: id,
    exerciseGroupId: groupId,
    position: 0,
    name: 'Squat',
    measurementType: const MeasurementType.repBased(),
    metadata: const ExerciseMetadata(notes: null, videoUrl: null),
    plannedRestSeconds: plannedRestSeconds,
    sets: const [],
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}

ValidationError _expectValidationError(void Function() fn) {
  try {
    fn();
    fail('Expected ValidationError but no exception was thrown');
  } on ValidationError catch (e) {
    return e;
  }
}
