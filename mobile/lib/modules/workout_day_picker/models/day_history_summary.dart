import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_history_summary.freezed.dart';

@freezed
abstract class DayHistorySummary with _$DayHistorySummary {
  const factory DayHistorySummary({
    required DateTime? lastCompleted,
    required int totalCompletedCount,
    required int thisWeekCount,
    required String? activeSessionId,
  }) = _DayHistorySummary;
}
