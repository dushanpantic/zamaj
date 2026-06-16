import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';

part 'cap_history.freezed.dart';

/// One completed session's record for a movement, as shown in the exercise
/// editor's recent set-history table.
///
/// [plannedSets] and [actualSets] are parallel, position-ordered lists — the
/// i-th planned set pairs with the i-th logged set. The planned side carries the
/// working weight and target the UI renders; the actual side carries the per-set
/// reps/holds. [isCapped] is the derived marker: every planned working set was
/// executed and met its own ceiling.
@freezed
abstract class CapHistoryEntry with _$CapHistoryEntry {
  const factory CapHistoryEntry({
    required DateTime date,
    required String programId,
    required String sourceWorkoutDayName,
    required List<PlannedSetValues> plannedSets,
    required List<ActualSetValues> actualSets,
    required bool isCapped,
  }) = _CapHistoryEntry;
}

/// A movement's recent set-history: newest-first [CapHistoryEntry]s aggregated
/// across every program the movement appears in, capped at the aggregator's
/// `limit`.
@freezed
abstract class CapHistory with _$CapHistory {
  const CapHistory._();

  const factory CapHistory({required List<CapHistoryEntry> entries}) =
      _CapHistory;

  /// No entries — the movement has no completed-session history.
  bool get isEmpty => entries.isEmpty;
}
