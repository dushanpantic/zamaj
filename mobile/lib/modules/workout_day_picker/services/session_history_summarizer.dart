import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';

abstract final class SessionHistorySummarizer {
  static DayHistorySummary summarize(
    List<Session> sessions,
    TrainingWeek window,
  ) {
    return DayHistorySummary(
      lastCompleted: SessionHistory.lastCompletedAt(sessions),
      totalCompletedCount: SessionHistory.completedCount(sessions),
      thisWeekCount: SessionHistory.completedCountInWeek(sessions, window),
      activeSessionId: ActiveSessionPolicy.select(sessions)?.id,
    );
  }
}
