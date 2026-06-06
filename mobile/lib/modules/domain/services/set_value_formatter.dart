import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';

/// Single source of truth for "one set's planned / actual values → compact
/// display string", shared by the in-session set row and the post-session
/// review screen.
///
/// Pure Dart, no Flutter. The two sides are intentionally asymmetric, matching
/// the long-standing in-session rendering: planned values carry a `kg` suffix
/// on the weight (`100kg × 8`) while actual values omit it (`100 × 8`), since
/// actuals sit beside their planned twin in the same row.
abstract final class SetValueFormatter {
  /// Compact planned summary for one set, or `—` when no planned values exist
  /// (e.g. an extra set logged beyond the plan).
  ///
  /// [measurementType] is accepted for call-site symmetry with the planned
  /// metadata; the rendering is fully determined by [planned]'s variant.
  static String formatPlanned(
    PlannedSetValues? planned,
    MeasurementType measurementType,
  ) {
    if (planned == null) return '—';
    return switch (planned) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg × ${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '× ${RepTargetFormatter.format(repTarget)}',
    };
  }

  /// Compact actual summary for one logged set. Weight has no `kg` suffix so it
  /// reads as the actual twin of the planned value beside it.
  static String formatActual(ActualSetValues values) => switch (values) {
    ActualRepBased(:final weightKg, :final reps) =>
      '${WeightFormatter.formatKg(weightKg)} × $reps',
    ActualTimeBased(:final durationSeconds, :final weightKg) =>
      weightKg == null
          ? '${durationSeconds}s'
          : '${WeightFormatter.formatKg(weightKg)} × ${durationSeconds}s',
    ActualBodyweight(:final reps) => '× $reps',
  };
}
