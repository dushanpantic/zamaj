import 'package:zamaj/modules/domain/models/rep_target.dart';

sealed class ValidationResult<T> {
  const ValidationResult();
}

final class Valid<T> extends ValidationResult<T> {
  const Valid(this.value);
  final T value;
}

final class Invalid<T> extends ValidationResult<T> {
  const Invalid(this.reason);
  final String reason;
}

abstract final class ProgramValidation {
  static ValidationResult<String> validateProgramName(
    String name, {
    required bool isCreate,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Invalid('name_too_short');
    final maxLength = isCreate ? 120 : 100;
    if (trimmed.length > maxLength) return const Invalid('name_too_long');
    return Valid(trimmed);
  }

  static ValidationResult<String> validateExerciseName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Invalid('name_too_short');
    if (trimmed.length > 80) return const Invalid('name_too_long');
    return Valid(trimmed);
  }

  static ValidationResult<String> validateWorkoutDayName(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return const Invalid('name_too_short');
    if (trimmed.length > 100) return const Invalid('name_too_long');
    return Valid(trimmed);
  }

  static ValidationResult<({double weightKg, RepTarget repTarget})>
  validateRepBasedSet({
    required String weightInput,
    required String repsInput,
  }) {
    final weightParsed = double.tryParse(weightInput);
    if (weightParsed == null) return const Invalid('weight_invalid');
    if (weightParsed < 0) return const Invalid('weight_out_of_range');
    if (weightParsed > 1000) return const Invalid('weight_out_of_range');
    final remainder = (weightParsed * 2).round() - (weightParsed * 2);
    if (remainder.abs() > 1e-9) return const Invalid('weight_not_half_kg');

    final repTargetResult = parseRepTarget(repsInput);
    return switch (repTargetResult) {
      Valid(:final value) => Valid((weightKg: weightParsed, repTarget: value)),
      Invalid(:final reason) => Invalid(reason),
    };
  }

  /// Parses a rep-target input string into a [RepTarget].
  ///
  /// Accepts a single integer (`"8"`) or a hyphen / en-dash separated
  /// range (`"6-8"`, `"6 - 8"`, `"6–8"`). The range form requires
  /// `min < max`; equal bounds are rejected (callers can express a fixed
  /// value with a single integer instead).
  static ValidationResult<RepTarget> parseRepTarget(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const Invalid('reps_invalid');

    final rangeMatch = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(trimmed);
    if (rangeMatch != null) {
      final min = int.tryParse(rangeMatch.group(1)!);
      final max = int.tryParse(rangeMatch.group(2)!);
      if (min == null || max == null) return const Invalid('range_invalid');
      if (min < 0 || max < 0) return const Invalid('reps_out_of_range');
      if (min > 999 || max > 999) return const Invalid('reps_out_of_range');
      if (max < min) return const Invalid('range_invalid');
      if (min == max) return Valid(RepTarget.fixed(reps: min));
      return Valid(RepTarget.range(minReps: min, maxReps: max));
    }

    final repsParsed = int.tryParse(trimmed);
    if (repsParsed == null) {
      final repsDouble = double.tryParse(trimmed);
      if (repsDouble == null) return const Invalid('reps_invalid');
      return const Invalid('reps_not_whole');
    }
    if (repsParsed < 0) return const Invalid('reps_out_of_range');
    if (repsParsed > 999) return const Invalid('reps_out_of_range');
    return Valid(RepTarget.fixed(reps: repsParsed));
  }

  static ValidationResult<RepTarget> validateBodyweightSet({
    required String repsInput,
  }) {
    return parseRepTarget(repsInput);
  }

  static ValidationResult<int> validateTimeBasedSet(String durationInput) {
    final parsed = int.tryParse(durationInput);
    if (parsed == null) {
      final asDouble = double.tryParse(durationInput);
      if (asDouble == null) return const Invalid('duration_invalid');
      return const Invalid('duration_not_whole');
    }
    if (parsed < 0) return const Invalid('duration_out_of_range');
    if (parsed > 3600) return const Invalid('duration_out_of_range');
    return Valid(parsed);
  }

  /// Validates the optional weight on a time-based set.
  /// Empty / whitespace input is treated as "no weight" and yields
  /// `Valid(null)`. Non-empty input must parse, be in `[0, 1000]`, and
  /// resolve to a multiple of 0.5 kg.
  static ValidationResult<double?> validateTimeBasedSetWeight(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const Valid(null);
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return const Invalid('weight_invalid');
    if (parsed < 0) return const Invalid('weight_out_of_range');
    if (parsed > 1000) return const Invalid('weight_out_of_range');
    final remainder = (parsed * 2).round() - (parsed * 2);
    if (remainder.abs() > 1e-9) return const Invalid('weight_not_half_kg');
    return Valid(parsed);
  }

  static ValidationResult<int?> validatePlannedRest(String? input) {
    if (input == null || input.trim().isEmpty) return const Valid(null);
    final parsed = int.tryParse(input.trim());
    if (parsed == null) {
      final asDouble = double.tryParse(input.trim());
      if (asDouble == null) return const Invalid('rest_invalid');
      return const Invalid('rest_not_whole');
    }
    if (parsed < 0) return const Invalid('rest_out_of_range');
    if (parsed > 3600) return const Invalid('rest_out_of_range');
    return Valid(parsed);
  }

  static ValidationResult<Uri?> validateVideoUrl(String? input) {
    if (input == null || input.trim().isEmpty) return const Valid(null);
    final trimmed = input.trim();
    if (trimmed.length > 2048) return const Invalid('url_too_long');
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.isAbsolute) {
      return const Invalid('url_not_absolute');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      return const Invalid('url_scheme_not_http_https');
    }
    return Valid(uri);
  }

  static ValidationResult<String?> validateNotes(String? input) {
    if (input == null || input.isEmpty) return const Valid(null);
    if (input.length > 2000) return const Invalid('notes_too_long');
    return Valid(input);
  }

  static ValidationResult<int> validateSetCount(int count) {
    if (count < 1) return const Invalid('set_count_too_low');
    if (count > 20) return const Invalid('set_count_too_high');
    return Valid(count);
  }
}
