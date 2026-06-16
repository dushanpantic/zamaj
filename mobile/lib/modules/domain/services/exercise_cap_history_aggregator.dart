import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';

/// Pure-Dart derivations behind the progression hints: whether a logged session
/// "capped" its planned prescription, plus (later steps) the recent set-history
/// table and the needs-attention badge.
///
/// A session caps a movement iff **every** planned working set was executed and
/// each met (or exceeded) its own ceiling — the top of a rep target or a
/// time-based hold's planned seconds. Vary-by-set plans are judged per set
/// against each set's own ceiling; there is no special-casing.
abstract final class ExerciseCapHistoryAggregator {
  /// Whether [actualSets] caps the [plannedSets] prescription.
  ///
  /// Capped iff at least every planned working set was executed (`actualSets`
  /// has an entry for each planned index) and each of those sets met its own
  /// ceiling. Extra logged sets beyond the plan do not affect the result.
  static bool isCapped({
    required List<PlannedSetValues> plannedSets,
    required List<ActualSetValues> actualSets,
  }) {
    if (plannedSets.isEmpty) return false;
    if (actualSets.length < plannedSets.length) return false;
    for (var i = 0; i < plannedSets.length; i++) {
      if (!_setMeetsCeiling(plannedSets[i], actualSets[i])) return false;
    }
    return true;
  }

  /// Whether a single [actual] set meets the ceiling of its [planned] set.
  static bool _setMeetsCeiling(
    PlannedSetValues planned,
    ActualSetValues actual,
  ) {
    final ceiling = _ceilingFor(planned);
    if (ceiling == null) return false;
    return switch ((planned, actual)) {
      (PlannedRepBased(), ActualRepBased(:final reps)) => reps >= ceiling,
      (PlannedBodyweight(), ActualBodyweight(:final reps)) => reps >= ceiling,
      _ => false,
    };
  }
}

/// The per-set ceiling [planned] is judged against: the top of a rep target
/// (fixed reps or a range's `maxReps`) for rep-based and bodyweight sets.
///
/// Null when the planned variant has no ceiling rule wired in yet (time-based
/// is added in the next step).
int? _ceilingFor(PlannedSetValues planned) => switch (planned) {
  PlannedRepBased(:final repTarget) => _repCeiling(repTarget),
  PlannedBodyweight(:final repTarget) => _repCeiling(repTarget),
  PlannedTimeBased() => null,
};

/// The top of a [RepTarget]: a fixed target's reps or a range's `maxReps`.
int _repCeiling(RepTarget target) => switch (target) {
  RepTargetFixed(:final reps) => reps,
  RepTargetRange(:final maxReps) => maxReps,
};
