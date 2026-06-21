import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// Formats a planned [Exercise]'s sets into a compact one-line summary shared by
/// the workout-overview cards and the focus panels (e.g. `100kg 3×8`,
/// `3×30s`, `4 sets` when the sets vary). The single planned-summary source so
/// the two surfaces can never drift on wording.
abstract final class PlannedSummaryFormatter {
  static String summarize(Exercise plannedExercise) {
    final sets = List<WorkoutSet>.of(plannedExercise.sets)
      ..sort((a, b) => a.position.compareTo(b.position));
    if (sets.isEmpty) return '0 sets';

    final first = sets.first.plannedValues;
    final allSame = sets.every((s) => s.plannedValues == first);

    if (!allSame) return '${sets.length} sets';

    return summarizeValues(first, sets.length);
  }

  /// Formats [setCount] identical planned [values] into the same one-line
  /// summary [summarize] produces for an equivalent uniform exercise. Useful
  /// when the planned values are uniform by construction (every set shares one
  /// value) and only the count varies.
  static String summarizeValues(PlannedSetValues values, int setCount) {
    if (setCount == 0) return '0 sets';

    return switch (values) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg $setCount×${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '$setCount×${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '$setCount×${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '$setCount×${RepTargetFormatter.format(repTarget)}',
    };
  }
}
