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

  group('nonWarmupCountsIn', () {
    test('sums exercises and sets across non-warmup groups only', () {
      final day = _groupedDay(const [
        (role: ExerciseGroupRole.warmup, setsPerExercise: [2]),
        (role: ExerciseGroupRole.main, setsPerExercise: [3, 4]),
      ]);

      expect(nonWarmupCountsIn(day), (exercises: 2, sets: 7));
    });

    test('counts each exercise of a superset group and its sets', () {
      final day = _groupedDay(const [
        (role: ExerciseGroupRole.main, setsPerExercise: [3, 3]),
      ]);

      expect(nonWarmupCountsIn(day), (exercises: 2, sets: 6));
    });

    test('returns zero for a day whose only group is a warmup', () {
      final day = _groupedDay(const [
        (role: ExerciseGroupRole.warmup, setsPerExercise: [2]),
      ]);

      expect(nonWarmupCountsIn(day), (exercises: 0, sets: 0));
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

// -----------------------------------------------------------------------------
// Richer fixture: each group spec carries a role and one entry per exercise
// giving that exercise's set count. Group kind is derived from member count
// (1 → single, ≥2 → superset), so a multi-entry list builds a valid superset.

WorkoutDay _groupedDay(
  List<({ExerciseGroupRole role, List<int> setsPerExercise})> specs,
) {
  final t = DateTime.utc(2026, 5, 12);
  return WorkoutDay(
    id: 'wd-1',
    programId: 'p-1',
    name: 'Day',
    exerciseGroups: [
      for (var gi = 0; gi < specs.length; gi++)
        ExerciseGroup(
          id: 'g-$gi',
          workoutDayId: 'wd-1',
          position: gi,
          kind: ExerciseGroupKind.forMemberCount(
            specs[gi].setsPerExercise.length,
          ),
          role: specs[gi].role,
          exercises: [
            for (var ei = 0; ei < specs[gi].setsPerExercise.length; ei++)
              Exercise(
                id: 'g-$gi-e-$ei',
                exerciseGroupId: 'g-$gi',
                position: ei,
                name: 'Ex $gi-$ei',
                measurementType: const MeasurementType.repBased(),
                metadata: const ExerciseMetadata(),
                sets: [
                  for (var si = 0; si < specs[gi].setsPerExercise[ei]; si++)
                    _set(id: 'g-$gi-e-$ei-s-$si', position: si, t: t),
                ],
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

WorkoutSet _set({
  required String id,
  required int position,
  required DateTime t,
}) => WorkoutSet(
  id: id,
  exerciseId: 'unused',
  position: position,
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 20,
    repTarget: RepTarget.fixed(reps: 8),
  ),
  createdAt: t,
  updatedAt: t,
  schemaVersion: 1,
);
