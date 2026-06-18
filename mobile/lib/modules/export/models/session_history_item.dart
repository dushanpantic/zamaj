/// Display projection for one row in the recent-sessions list.
///
/// Pure data — no Flutter types — so it can be assembled in pure Dart and
/// snapshot-tested. The bloc converts each [Session] into one of these.
class SessionHistoryItem {
  const SessionHistoryItem({
    required this.sessionId,
    required this.workoutDayName,
    required this.endedAt,
    required this.completedExerciseCount,
    required this.totalExerciseCount,
    required this.isInThisWeek,
    required this.isDeload,
  });

  final String sessionId;
  final String workoutDayName;

  /// Local DateTime when the session ended. Null when the session is still
  /// in progress; the recent-sessions bloc filters those out today, so
  /// historically every item has a non-null `endedAt`, but the field is
  /// kept nullable to leave room for "in progress" rendering later.
  final DateTime? endedAt;

  /// Count of exercises whose state is `completed`. Used to render a
  /// "5/8 exercises" subtitle.
  final int completedExerciseCount;
  final int totalExerciseCount;

  /// True when [endedAt] falls inside the same Mon-Sun window as the
  /// reference clock — used to bucket the list into "This week" vs "Earlier".
  final bool isInThisWeek;

  /// True when this session was logged as a deload — drives the DELOAD badge
  /// on the recent-sessions tile.
  final bool isDeload;
}
