import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';

abstract final class SessionHistorySummarizer {
  static DayHistorySummary summarize(
    List<Session> sessions,
    CurrentWeekWindow window,
  ) {
    DateTime? lastCompleted;
    var totalCompletedCount = 0;
    var thisWeekCount = 0;

    for (final s in sessions) {
      final endedAt = s.endedAt;
      if (endedAt == null) continue;
      totalCompletedCount += 1;
      if (lastCompleted == null || endedAt.isAfter(lastCompleted)) {
        lastCompleted = endedAt;
      }
      if (window.contains(endedAt)) {
        thisWeekCount += 1;
      }
    }

    return DayHistorySummary(
      lastCompleted: lastCompleted,
      totalCompletedCount: totalCompletedCount,
      thisWeekCount: thisWeekCount,
      activeSessionId: ActiveSessionPolicy.select(sessions)?.id,
    );
  }
}
