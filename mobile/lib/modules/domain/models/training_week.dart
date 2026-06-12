import 'package:freezed_annotation/freezed_annotation.dart';

part 'training_week.freezed.dart';

/// The Monday-to-Monday training week containing a given instant, in local time.
///
/// `start` is the most recent Monday at local midnight; `end` is the following
/// Monday at local midnight. The window is half-open `[start, end)` — the start
/// is included, the end is excluded — so a single instant belongs to exactly one
/// week. This is the canonical "this week" boundary used for session-history
/// bucketing and the end-of-week correction deadline.
@freezed
abstract class TrainingWeek with _$TrainingWeek {
  const TrainingWeek._();

  const factory TrainingWeek({required DateTime start, required DateTime end}) =
      _TrainingWeek;

  factory TrainingWeek.compute(DateTime now) {
    final local = now.isUtc ? now.toLocal() : now;
    final daysSinceMonday = (local.weekday - DateTime.monday + 7) % 7;
    final startDate = DateTime(
      local.year,
      local.month,
      local.day,
    ).subtract(Duration(days: daysSinceMonday));
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(start.year, start.month, start.day + 7);
    return TrainingWeek(start: start, end: end);
  }

  bool contains(DateTime instant) {
    return !instant.isBefore(start) && instant.isBefore(end);
  }
}
