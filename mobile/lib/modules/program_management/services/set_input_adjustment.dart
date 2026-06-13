import 'package:zamaj/core/increment_rules.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

/// Adjustments applied uniformly across an exercise's planned sets while
/// editing. Operates on the *raw input strings* the editor holds (so the
/// `"6-8"` range shape and its separator survive a bump) and on lists of
/// [PlannedSetDraft] for uniformity detection. Step magnitudes come from
/// [IncrementRules] — the single source of truth shared with focus mode — so
/// the uniform editor and the in-session steppers can never drift apart.
abstract final class SetInputAdjustment {
  /// Bumps every numeric run in a reps input by [delta], preserving the
  /// surrounding shape (separators, whitespace). A blank or non-numeric input
  /// is returned unchanged; counts clamp at zero.
  static String bumpReps(String input, int delta) {
    if (input.trim().isEmpty) return input;
    return input.replaceAllMapped(RegExp(r'\d+'), (match) {
      final current = int.parse(match.group(0)!);
      return IncrementRules.bumpReps(current, delta).toString();
    });
  }

  /// Bumps a weight input by [delta] (half-kg snapped, clamped ≥0 via
  /// [IncrementRules.bumpWeight]) and re-renders it via [formatWeight]. A blank
  /// or non-numeric input is returned unchanged.
  static String bumpWeight(String input, double delta) {
    final current = double.tryParse(input.trim());
    if (current == null) return input;
    return formatWeight(IncrementRules.bumpWeight(current, delta));
  }

  /// Bumps a duration input (seconds) by [delta], clamped ≥0 via
  /// [IncrementRules.bumpDuration]. A blank or non-numeric input is returned
  /// unchanged.
  static String bumpDuration(String input, int delta) {
    final current = int.tryParse(input.trim());
    if (current == null) return input;
    return IncrementRules.bumpDuration(current, delta).toString();
  }

  /// Renders a weight value for an input field: whole values drop the trailing
  /// decimal (`100.0` → `"100"`), half-kg values keep it (`102.5` → `"102.5"`).
  static String formatWeight(double value) {
    if (value == value.roundToDouble()) return value.toInt().toString();
    return value.toString();
  }

  /// True when every set holds equal planned values — the signal the editor
  /// uses to present a single uniform editor instead of a per-set list. An
  /// empty or single-set list is uniform; blank-but-equal sets are uniform.
  static bool areUniform(List<PlannedSetDraft> sets) {
    if (sets.length <= 1) return true;
    final first = sets.first.values;
    return sets.every((set) => set.values == first);
  }
}
