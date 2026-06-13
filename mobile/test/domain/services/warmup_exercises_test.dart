import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('warmupExerciseIdsIn', () {
    test('returns exercise ids from warmup-role groups only', () {
      final day = _day(const [
        (role: ExerciseGroupRole.warmup, exerciseId: 'warm-1'),
        (role: ExerciseGroupRole.main, exerciseId: 'work-1'),
        (role: ExerciseGroupRole.warmup, exerciseId: 'warm-2'),
      ]);

      expect(warmupExerciseIdsIn(day), {'warm-1', 'warm-2'});
    });

    test('returns empty when no warmup groups exist', () {
      final day = _day(const [
        (role: ExerciseGroupRole.main, exerciseId: 'work-1'),
        (role: ExerciseGroupRole.main, exerciseId: 'work-2'),
      ]);

      expect(warmupExerciseIdsIn(day), isEmpty);
    });
  });
}

// -----------------------------------------------------------------------------
// Fixture builder: a workout day of single-exercise groups, each tagged with a
// role and carrying one identifiable exercise (no sets needed for this helper).

WorkoutDay _day(List<({ExerciseGroupRole role, String exerciseId})> specs) {
  final t = DateTime.utc(2026, 5, 12);
  return WorkoutDay(
    id: 'wd-1',
    programId: 'p-1',
    name: 'Day',
    exerciseGroups: [
      for (var i = 0; i < specs.length; i++)
        ExerciseGroup(
          id: 'g-$i',
          workoutDayId: 'wd-1',
          position: i,
          kind: const ExerciseGroupKind.single(),
          role: specs[i].role,
          exercises: [
            Exercise(
              id: specs[i].exerciseId,
              exerciseGroupId: 'g-$i',
              position: 0,
              name: 'Ex $i',
              measurementType: const MeasurementType.repBased(),
              metadata: const ExerciseMetadata(),
              sets: const [],
              createdAt: t,
              updatedAt: t,
              schemaVersion: 1,
            ),
          ],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
    ],
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}
