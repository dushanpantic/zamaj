import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/services/warmup_exercises.dart';

/// Headline read-only stats for a finished [Session]: how long it took, how
/// many working sets were completed against the plan, and the total weighted
/// volume moved.
///
/// Pure derivation — reads the persisted session, writes nothing, never
/// touches the frozen snapshot. Warmup-group sets are excluded from every
/// figure (they are not working sets). Volume sums weighted (rep-based) work
/// only; bodyweight and time-based sets still count as completed sets but
/// contribute nothing to volume.
class SessionSummary {
  const SessionSummary({
    required this.duration,
    required this.completedWorkingSets,
    required this.plannedWorkingSets,
    required this.weightedVolumeKg,
  });

  /// Wall-clock time from start to end. Zero while the session is in progress.
  final Duration duration;

  /// Working (non-warmup) sets the lifter actually logged. May exceed
  /// [plannedWorkingSets] when extra sets were logged beyond the prescription.
  final int completedWorkingSets;

  /// Working (non-warmup) sets prescribed by the frozen snapshot.
  final int plannedWorkingSets;

  /// Σ(weightKg × reps) over weighted working sets.
  final double weightedVolumeKg;

  /// Whether any weighted volume was moved. Gates whether a surface shows a
  /// volume figure at all — an all-bodyweight session reports `false`, so the
  /// surface omits volume rather than rendering a misleading `0 kg`.
  bool get hasWeightedVolume => weightedVolumeKg > 0;

  static SessionSummary fromSession(Session session) {
    final end = session.endedAt ?? session.startedAt;
    final elapsed = end.difference(session.startedAt);

    final warmupIds = warmupExerciseIdsIn(session.snapshot.workoutDay);

    var plannedWorkingSets = 0;
    for (final group in session.snapshot.workoutDay.exerciseGroups) {
      if (isWarmupGroup(group.role)) continue;
      for (final exercise in group.exercises) {
        plannedWorkingSets += exercise.sets.length;
      }
    }

    var completedWorkingSets = 0;
    var weightedVolumeKg = 0.0;
    for (final sessionExercise in session.sessionExercises) {
      if (warmupIds.contains(sessionExercise.plannedExerciseIdInSnapshot)) {
        continue;
      }
      completedWorkingSets += sessionExercise.executedSets.length;
      for (final set in sessionExercise.executedSets) {
        final values = set.actualValues;
        if (values is ActualRepBased) {
          weightedVolumeKg += values.weightKg * values.reps;
        }
      }
    }

    return SessionSummary(
      duration: elapsed.isNegative ? Duration.zero : elapsed,
      completedWorkingSets: completedWorkingSets,
      plannedWorkingSets: plannedWorkingSets,
      weightedVolumeKg: weightedVolumeKg,
    );
  }
}
