import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/models/session_history_item.dart';

/// Builds the recent-sessions list from a flat list of [Session]s.
///
/// Filters out in-progress sessions (no `endedAt`), sorts the rest by
/// `endedAt` descending (newest first), and tags each row with whether its
/// `endedAt` falls inside the supplied [TrainingWeek] so the UI can
/// bucket the list.
abstract final class SessionHistoryAssembler {
  static List<SessionHistoryItem> assemble({
    required List<Session> sessions,
    required TrainingWeek window,
  }) {
    return [
      for (final s in SessionHistory.completedNewestFirst(sessions))
        _toItem(s, window),
    ];
  }

  static SessionHistoryItem _toItem(Session s, TrainingWeek window) {
    return SessionHistoryItem(
      sessionId: s.id,
      workoutDayName: s.snapshot.workoutDay.name,
      endedAt: s.endedAt,
      completedExerciseCount: SessionHistory.completedExerciseCount(s),
      totalExerciseCount: s.sessionExercises.length,
      isInThisWeek: window.contains(s.endedAt!),
    );
  }
}
