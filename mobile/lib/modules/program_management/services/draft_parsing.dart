import 'package:zamaj/modules/domain/models/rep_target.dart';

/// Shared best-effort parsers for draft input strings used during program
/// editing. Used by both the save path (drafts → aggregates) and the
/// display path (drafts → human-readable subtitle) so the two never drift.
abstract final class DraftParsing {
  /// Parses a rep-target input string for save / display. Accepts a single
  /// integer (`"8"`) or a hyphen / en-dash separated range (`"5-8"`,
  /// `"5 – 8"`). Invalid or empty input becomes `RepTarget.fixed(reps: 0)` —
  /// validation lives in `ProgramValidation.parseRepTarget`; this is the
  /// lossy variant the editor uses while the user is mid-typing.
  static RepTarget parseRepTargetOrZero(String input) {
    final trimmed = input.trim();
    final rangeMatch = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(trimmed);
    if (rangeMatch != null) {
      final min = int.tryParse(rangeMatch.group(1)!) ?? 0;
      final max = int.tryParse(rangeMatch.group(2)!) ?? 0;
      if (max > min) return RepTarget.range(minReps: min, maxReps: max);
      return RepTarget.fixed(reps: min);
    }
    return RepTarget.fixed(reps: int.tryParse(trimmed) ?? 0);
  }

  static double? parseOptionalWeight(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }
}
