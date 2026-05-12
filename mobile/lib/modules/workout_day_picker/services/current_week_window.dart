import 'package:freezed_annotation/freezed_annotation.dart';

part 'current_week_window.freezed.dart';

@freezed
abstract class CurrentWeekWindow with _$CurrentWeekWindow {
  const CurrentWeekWindow._();

  const factory CurrentWeekWindow({
    required DateTime start,
    required DateTime end,
  }) = _CurrentWeekWindow;

  factory CurrentWeekWindow.compute(DateTime now) {
    final local = now.isUtc ? now.toLocal() : now;
    final daysSinceMonday = (local.weekday - DateTime.monday + 7) % 7;
    final startDate = DateTime(
      local.year,
      local.month,
      local.day,
    ).subtract(Duration(days: daysSinceMonday));
    final start = DateTime(startDate.year, startDate.month, startDate.day);
    final end = DateTime(start.year, start.month, start.day + 7);
    return CurrentWeekWindow(start: start, end: end);
  }

  bool contains(DateTime instant) {
    return !instant.isBefore(start) && instant.isBefore(end);
  }
}
