import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';

/// The snapshot exercise ids that belong to a warmup group in [day].
///
/// Single source of truth for warmup-set exclusion across read surfaces (the
/// plain-text export, the session summary). A replaced exercise inherits its
/// slot, so a substituted warmup is still excluded by id.
Set<String> warmupExerciseIdsIn(WorkoutDay day) {
  final out = <String>{};
  for (final group in day.exerciseGroups) {
    if (!isWarmupGroup(group.role)) continue;
    for (final exercise in group.exercises) {
      out.add(exercise.id);
    }
  }
  return out;
}
