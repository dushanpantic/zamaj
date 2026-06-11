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

    return switch (first) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${sets.length}×${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${sets.length}×${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '${sets.length}×${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '${sets.length}×${RepTargetFormatter.format(repTarget)}',
    };
  }
}
