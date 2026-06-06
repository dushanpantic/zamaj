import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';

/// Decides whether a completed session's logged set values may still be
/// corrected from the read-only review screen.
///
/// Correction is the deliberate, narrow softening of session immutability: an
/// ended session's *actual* values stay editable only while it falls inside the
/// current Mon–Sun week (the same window the recent-sessions list buckets as
/// "This week"), which maps to the end-of-week coach-report deadline. Sessions
/// outside that window — and sessions still in progress — are never editable
/// here. The frozen plan snapshot is never affected by this decision.
abstract final class SessionEditability {
  /// Returns `true` only when [session] has ended and its `endedAt` falls
  /// inside [window].
  static bool canEditValues(Session session, CurrentWeekWindow window) {
    final endedAt = session.endedAt;
    if (endedAt == null) return false;
    return window.contains(endedAt);
  }
}
