import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/domain.dart';

part 'set_row_view_model.freezed.dart';

/// One row in the inline set list for an exercise card.
///
/// [position] is the canonical set position (matches
/// [PlannedSet.position] / [ExecutedSet.position]), not a list index — so
/// gaps or extra trailing actual sets remain disambiguated.
@freezed
abstract class SetRowViewModel with _$SetRowViewModel {
  const factory SetRowViewModel({
    required int position,
    required PlannedSetValues? plannedValues,
    required String? plannedSetIdInSnapshot,
    required ExecutedSet? executedSet,

    /// True when this row is the next chronological slot to log on a
    /// loggable exercise — equivalent to `position == executedSets.length`
    /// for an exercise present in [SessionState.openTargets]. UI renders
    /// loggable rows pre-expanded with an inline editor; all other unlogged
    /// rows render as inert "future" rows.
    required bool isLoggable,
    ActualSetValues? suggestedActualValues,
  }) = _SetRowViewModel;
}
