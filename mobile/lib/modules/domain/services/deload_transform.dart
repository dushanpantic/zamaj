import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';

/// Pure transform that turns a planned [WorkoutDay] into its deload form by
/// halving the working-set count of every `main`-role exercise.
///
/// The set count is reduced to `ceil(n/2)` (a floor of one), keeping each
/// exercise's first sets in order. `warmup`-role groups are returned untouched.
/// The input tree is never mutated — a fresh [WorkoutDay] is returned.
abstract final class DeloadTransform {
  static WorkoutDay halveWorkingSets(WorkoutDay day) {
    return day.copyWith(
      exerciseGroups: [
        for (final group in day.exerciseGroups)
          if (group.role == ExerciseGroupRole.main)
            group.copyWith(
              exercises: group.exercises.map(_halveExercise).toList(),
            )
          else
            group,
      ],
    );
  }

  static Exercise _halveExercise(Exercise exercise) {
    // Sort by position so "keep the first sets" is self-contained rather than
    // trusting hydration order — mirrors ExerciseCapHistoryAggregator's
    // defensive position sort over the same set lists.
    final ordered = [...exercise.sets]
      ..sort((a, b) => a.position.compareTo(b.position));
    final keep = (ordered.length + 1) ~/ 2;
    return exercise.copyWith(sets: ordered.take(keep).toList());
  }
}
