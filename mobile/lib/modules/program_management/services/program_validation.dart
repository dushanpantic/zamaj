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

  static ValidationResult<({double weightKg, int reps})> validateRepBasedSet({
    required String weightInput,
    required String repsInput,
  }) {
    final weightParsed = double.tryParse(weightInput);
    if (weightParsed == null) return const Invalid('weight_invalid');
    if (weightParsed < 0) return const Invalid('weight_out_of_range');
    if (weightParsed > 1000) return const Invalid('weight_out_of_range');
    final remainder = (weightParsed * 2).round() - (weightParsed * 2);
    if (remainder.abs() > 1e-9) return const Invalid('weight_not_half_kg');

    final repsParsed = int.tryParse(repsInput);
    if (repsParsed == null) {
      final repsDouble = double.tryParse(repsInput);
      if (repsDouble == null) return const Invalid('reps_invalid');
      return const Invalid('reps_not_whole');
    }
    if (repsParsed < 0) return const Invalid('reps_out_of_range');
    if (repsParsed > 999) return const Invalid('reps_out_of_range');

    return Valid((weightKg: weightParsed, reps: repsParsed));
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
