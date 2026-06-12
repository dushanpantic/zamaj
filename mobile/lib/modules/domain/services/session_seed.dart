import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';

/// One seeded session-exercise: the snapshot id of the planned exercise it
/// tracks, plus the superset tag it belongs to (the group id for a superset
/// group, null for a single group).
typedef SessionSeedEntry = ({
  String plannedExerciseIdInSnapshot,
  String? supersetTag,
});

/// Flattens a planned [WorkoutDay] into the ordered session-exercise seed the
/// Drift session repository materialises when a session starts.
///
/// Exercises appear in group-then-member order, mirroring the planned day; each
/// superset member carries the group id as its `supersetTag` and single-group
/// exercises carry none. Position assignment (the gap constant) stays a repo
/// detail — this service owns only what gets seeded and in what order.
abstract final class SessionSeed {
  static List<SessionSeedEntry> fromWorkoutDay(WorkoutDay workoutDay) {
    final entries = <SessionSeedEntry>[];
    for (final group in workoutDay.exerciseGroups) {
      final supersetTag = group.kind is SupersetKind ? group.id : null;
      for (final exercise in group.exercises) {
        entries.add((
          plannedExerciseIdInSnapshot: exercise.id,
          supersetTag: supersetTag,
        ));
      }
    }
    return entries;
  }
}
