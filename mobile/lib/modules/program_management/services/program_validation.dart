import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/services/program_rules.dart';

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

/// Input parsing + error-code mapping for the program-authoring UI.
///
/// Parsing of user strings lives here; the numeric/text **bounds** are owned by
/// domain [ProgramRules]. Each validator parses, then delegates the bound check
/// to `ProgramRules`, mapping a thrown [ValidationError] back onto this layer's
/// `Invalid(code)` envelope via [_guard].
abstract final class ProgramValidation {
  /// Runs [check]; returns `Valid(value)` when it passes, or `Invalid(code)`
  /// carrying the thrown [ValidationError]'s `invariant` code.
  static ValidationResult<T> _guard<T>(T value, void Function() check) {
    try {
      check();
      return Valid(value);
    } on ValidationError catch (e) {
      return Invalid(e.invariant);
    }
  }

  static ValidationResult<String> validateProgramName(
    String name, {
    required bool isCreate,
  }) {
    final trimmed = name.trim();
    return _guard(trimmed, () => ProgramRules.checkProgramName(trimmed));
  }

  static ValidationResult<String> validateExerciseName(String name) {
    final trimmed = name.trim();
    return _guard(trimmed, () => ProgramRules.checkExerciseName(trimmed));
  }

  static ValidationResult<String> validateWorkoutDayName(String name) {
    final trimmed = name.trim();
    return _guard(trimmed, () => ProgramRules.checkWorkoutDayName(trimmed));
  }

  static ValidationResult<({double weightKg, RepTarget repTarget})>
  validateRepBasedSet({
    required String weightInput,
    required String repsInput,
  }) {
    final weightParsed = double.tryParse(weightInput);
    if (weightParsed == null) return const Invalid('weight_invalid');
    final weightResult = _guard(
      weightParsed,
      () => ProgramRules.checkWeightKg(weightParsed),
    );
    if (weightResult is Invalid) {
      return Invalid((weightResult as Invalid).reason);
    }

    final repTargetResult = parseRepTarget(repsInput);
    return switch (repTargetResult) {
      Valid(:final value) => Valid((weightKg: weightParsed, repTarget: value)),
      Invalid(:final reason) => Invalid(reason),
    };
  }

  /// Parses a rep-target input string into a [RepTarget], delegating to the
  /// domain [RepTarget.parse] and mapping its [ValidationError] code onto the
  /// `Invalid(code)` envelope.
  static ValidationResult<RepTarget> parseRepTarget(String input) {
    try {
      return Valid(RepTarget.parse(input));
    } on ValidationError catch (e) {
      return Invalid(e.invariant);
    }
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
    return _guard(parsed, () => ProgramRules.checkDurationSeconds(parsed));
  }

  /// Validates the optional weight on a time-based set.
  /// Empty / whitespace input is treated as "no weight" and yields
  /// `Valid(null)`. Non-empty input must parse and pass [ProgramRules].
  static ValidationResult<double?> validateTimeBasedSetWeight(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return const Valid(null);
    final parsed = double.tryParse(trimmed);
    if (parsed == null) return const Invalid('weight_invalid');
    return _guard(parsed, () => ProgramRules.checkWeightKg(parsed));
  }

  static ValidationResult<int?> validatePlannedRest(String? input) {
    if (input == null || input.trim().isEmpty) return const Valid(null);
    final parsed = int.tryParse(input.trim());
    if (parsed == null) {
      final asDouble = double.tryParse(input.trim());
      if (asDouble == null) return const Invalid('rest_invalid');
      return const Invalid('rest_not_whole');
    }
    return _guard(parsed, () => ProgramRules.checkRestSeconds(parsed));
  }

  static ValidationResult<Uri?> validateVideoUrl(String? input) {
    if (input == null || input.trim().isEmpty) return const Valid(null);
    final trimmed = input.trim();
    final result = _guard(trimmed, () => ProgramRules.checkVideoUrl(trimmed));
    if (result is Invalid) return Invalid((result as Invalid).reason);
    // ProgramRules guarantees an absolute http(s) URI at this point.
    return Valid(Uri.parse(trimmed));
  }

  static ValidationResult<String?> validateNotes(String? input) {
    if (input == null || input.isEmpty) return const Valid(null);
    return _guard(input, () => ProgramRules.checkNotes(input));
  }

  static ValidationResult<int> validateSetCount(int count) {
    return _guard(count, () => ProgramRules.checkSetCount(count));
  }
}
