import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/training_week.dart';
import 'package:zamaj/modules/domain/services/effective_exercises.dart';
import 'package:zamaj/modules/domain/services/exercise_outcome.dart';

/// Pure derivations over a flat list of [Session]s for the session-history
/// surfaces (the day-picker summary and the recent-sessions list).
///
/// "Completed" here means an *ended* session (its `endedAt` is set); in-progress
/// sessions are excluded from every count and from the ordered list. Ordering is
/// newest-first by `endedAt`, ties broken by `id` descending so the result is
/// deterministic regardless of input order.
abstract final class SessionHistory {
  /// Ended sessions only, newest first, ties broken by `id` descending.
  static List<Session> completedNewestFirst(List<Session> sessions) {
    return sessions.where((s) => s.endedAt != null).toList()..sort((a, b) {
      final byEnded = b.endedAt!.compareTo(a.endedAt!);
      if (byEnded != 0) return byEnded;
      return b.id.compareTo(a.id);
    });
  }

  /// Number of exercises in [session] whose logged sets meet the planned quota,
  /// derived via [ExerciseOutcomes.of] rather than the stored discriminator.
  ///
  /// A legacy marked-done-early row (stored `completed` but short of its quota)
  /// and a skipped-with-sets row both read as partial and are excluded; a
  /// replaced exercise reads as replaced and is excluded, matching prior
  /// behavior.
  static int completedExerciseCount(Session session) {
    final effective = EffectiveExercises.of(session);
    var count = 0;
    for (final ex in session.sessionExercises) {
      final outcome = ExerciseOutcomes.of(
        state: ex.state,
        executedSetCount: ex.executedSets.length,
        plannedSetCount: effective.forSessionExercise(ex).plannedSetCount,
      );
      if (outcome == ExerciseOutcome.completed) count++;
    }
    return count;
  }

  /// Total number of ended sessions.
  static int completedCount(List<Session> sessions) {
    return sessions.where((s) => s.endedAt != null).length;
  }

  /// Number of ended sessions whose `endedAt` falls inside [week].
  static int completedCountInWeek(List<Session> sessions, TrainingWeek week) {
    var count = 0;
    for (final s in sessions) {
      final endedAt = s.endedAt;
      if (endedAt != null && week.contains(endedAt)) count++;
    }
    return count;
  }

  /// The latest `endedAt` among ended sessions, or `null` when there are none.
  static DateTime? lastCompletedAt(List<Session> sessions) {
    DateTime? latest;
    for (final s in sessions) {
      final endedAt = s.endedAt;
      if (endedAt == null) continue;
      if (latest == null || endedAt.isAfter(latest)) latest = endedAt;
    }
    return latest;
  }
}
