import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// The three text-field values backing a set-value editor, independent of
/// measurement type. Fields unused by a given type are empty strings.
typedef SetValueInputFields = ({String weight, String reps, String duration});

/// Pure text ↔ [ActualSetValues] mapping for set-value editors, shared by the
/// in-session `SetRow` inline editor and the post-session `SetValueEditorSheet`.
///
/// Centralizes the parse/round semantics — half-kg rounding on weight,
/// non-negative integers on reps/seconds — so the two editors can never drift
/// apart. Pure Dart, fully unit-tested.
abstract final class SetValueInputMapper {
  /// Seeds an editor's text controllers from [values] for [measurementType].
  /// A null [values] yields zero defaults for the type (matching an empty
  /// editor): `'0'` for the type's required numbers, `''` for optional/unused
  /// fields.
  static SetValueInputFields seed(
    ActualSetValues? values,
    MeasurementType measurementType,
  ) {
    switch (measurementType) {
      case RepBasedMeasurement():
        final rb = values is ActualRepBased ? values : null;
        return (
          weight: WeightFormatter.formatKg(rb?.weightKg ?? 0),
          reps: (rb?.reps ?? 0).toString(),
          duration: '',
        );
      case TimeBasedMeasurement():
        final tb = values is ActualTimeBased ? values : null;
        return (
          weight: tb?.weightKg != null
              ? WeightFormatter.formatKg(tb!.weightKg!)
              : '',
          reps: '',
          duration: (tb?.durationSeconds ?? 0).toString(),
        );
      case BodyweightMeasurement():
        final bw = values is ActualBodyweight ? values : null;
        return (weight: '', reps: (bw?.reps ?? 0).toString(), duration: '');
    }
  }

  /// Parses controller text into [ActualSetValues] for [measurementType], or
  /// `null` when the input is incomplete or invalid (unparseable or negative).
  /// Weight is rounded to the nearest half-kg.
  static ActualSetValues? parse({
    required MeasurementType measurementType,
    required String weightText,
    required String repsText,
    required String durationText,
  }) {
    switch (measurementType) {
      case RepBasedMeasurement():
        final weight = double.tryParse(weightText.trim());
        final reps = int.tryParse(repsText.trim());
        if (weight == null || reps == null) return null;
        if (weight < 0 || reps < 0) return null;
        return ActualSetValues.repBased(
          weightKg: _roundHalfKg(weight),
          reps: reps,
        );
      case TimeBasedMeasurement():
        final seconds = int.tryParse(durationText.trim());
        if (seconds == null || seconds < 0) return null;
        final raw = weightText.trim();
        double? weightKg;
        if (raw.isNotEmpty) {
          final parsed = double.tryParse(raw);
          if (parsed == null || parsed < 0) return null;
          weightKg = _roundHalfKg(parsed);
        }
        return ActualSetValues.timeBased(
          durationSeconds: seconds,
          weightKg: weightKg,
        );
      case BodyweightMeasurement():
        final reps = int.tryParse(repsText.trim());
        if (reps == null || reps < 0) return null;
        return ActualSetValues.bodyweight(reps: reps);
    }
  }

  static double _roundHalfKg(double kg) => (kg * 2).round() / 2;
}
