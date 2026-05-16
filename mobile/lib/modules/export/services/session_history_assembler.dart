import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/models/session_history_item.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';

/// Builds the recent-sessions list from a flat list of [Session]s.
///
/// Filters out in-progress sessions (no `endedAt`), sorts the rest by
/// `endedAt` descending (newest first), and tags each row with whether its
/// `endedAt` falls inside the supplied [CurrentWeekWindow] so the UI can
/// bucket the list.
abstract final class SessionHistoryAssembler {
  static List<SessionHistoryItem> assemble({
    required List<Session> sessions,
    required CurrentWeekWindow window,
  }) {
    final completed = sessions.where((s) => s.endedAt != null).toList()
      ..sort((a, b) {
        final byEnded = b.endedAt!.compareTo(a.endedAt!);
        if (byEnded != 0) return byEnded;
        return b.id.compareTo(a.id);
      });

    return [for (final s in completed) _toItem(s, window)];
  }

  static SessionHistoryItem _toItem(Session s, CurrentWeekWindow window) {
    var completed = 0;
    for (final ex in s.sessionExercises) {
      if (ex.state is CompletedState) completed++;
    }
    return SessionHistoryItem(
      sessionId: s.id,
      workoutDayName: s.snapshot.workoutDay.name,
      endedAt: s.endedAt,
      completedExerciseCount: completed,
      totalExerciseCount: s.sessionExercises.length,
      isInThisWeek: window.contains(s.endedAt!),
    );
  }
}
