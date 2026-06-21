import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';

/// The snapshot exercise ids that belong to a warmup group in [day].
///
/// Single source of truth for warmup-set exclusion across read surfaces (the
/// plain-text export, the session summary). Warmup ids come straight from the
/// snapshot; an added exercise (e.g. a replacement) carries a synthetic id that
/// is never in a warmup group, so it is simply not excluded here.
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

/// The non-warmup exercise and planned-set tallies for [day].
///
/// Both numbers come from one pass over the same non-warmup filter, so the
/// exercise count and set count can never range over different populations.
/// A superset group contributes each of its exercises. Warmup is group-level
/// today (there is no warmup-set axis), so a non-warmup exercise's sets all
/// count — extend here if a per-set warmup flag is ever added.
({int exercises, int sets}) nonWarmupCountsIn(WorkoutDay day) {
  var exercises = 0;
  var sets = 0;
  for (final group in day.exerciseGroups) {
    if (isWarmupGroup(group.role)) continue;
    for (final exercise in group.exercises) {
      exercises++;
      sets += exercise.sets.length;
    }
  }
  return (exercises: exercises, sets: sets);
}
