import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/draft_parsing.dart';

/// Subtitle formatter for `ExerciseDraft` rows in the workout-day editor.
///
/// Mirrors `PlannedSummaryFormatter` (which works on persisted `Exercise`)
/// but operates on the editor's draft model, where reps and weights are
/// still raw user-typed strings. Parses through [DraftParsing] so the
/// equality used here matches what the save path will write — e.g. `"5-8"`
/// and `"5 – 8"` are treated as equal.
///
/// Degrades gracefully rather than bailing to a generic "N sets" subtitle.
abstract final class PlannedDraftSummaryFormatter {
  /// Soft limit for the rendered subtitle; longer outputs are ellipsized
  /// so the row always stays on one line.
  static const int _maxLength = 32;
  static const String _noSetsPlanned = 'No sets planned';

  /// Render a one-line subtitle for [exercise]. The result is sized to
  /// fit within ~32 characters; longer outputs are truncated with `…`.
  static String summarize(ExerciseDraft exercise) {
    final sets = exercise.sets;
    if (sets.isEmpty) return _noSetsPlanned;

    final raw = switch (exercise.measurementType) {
      RepBasedMeasurement() => _repBased(sets),
      BodyweightMeasurement() => _bodyweight(sets),
      TimeBasedMeasurement() => _timeBased(sets),
    };
    return _ellipsize(raw);
  }

  /// True when [exercise] has no planned sets — callers may surface this
  /// with a subtle warning style.
  static bool isNoSetsPlanned(ExerciseDraft exercise) => exercise.sets.isEmpty;

  // ---- rep-based --------------------------------------------------------

  static String _repBased(List<PlannedSetDraft> sets) {
    final weights = <double>[];
    final reps = <RepTarget>[];
    for (final s in sets) {
      final v = s.values;
      if (v is! PlannedSetDraftRepBased) {
        return '${sets.length} sets';
      }
      weights.add(double.tryParse(v.weightInput) ?? 0.0);
      reps.add(DraftParsing.parseRepTargetOrZero(v.repsInput));
    }

    final weightUniform = weights.every((w) => w == weights.first);
    final repsUniform = reps.every((r) => r == reps.first);
    final n = sets.length;

    if (weightUniform && repsUniform) {
      return '${WeightFormatter.formatKg(weights.first)}kg '
          '$n×${RepTargetFormatter.format(reps.first)}';
    }
    if (weightUniform && !repsUniform) {
      if (n <= 6) {
        final list = reps.map(RepTargetFormatter.format).join('/');
        return '${WeightFormatter.formatKg(weights.first)}kg · $list';
      }
      return '${WeightFormatter.formatKg(weights.first)}kg · $n sets';
    }
    if (!weightUniform && repsUniform) {
      final lo = weights.reduce((a, b) => a < b ? a : b);
      final hi = weights.reduce((a, b) => a > b ? a : b);
      return '${WeightFormatter.formatKg(lo)}-${WeightFormatter.formatKg(hi)}kg '
          '$n×${RepTargetFormatter.format(reps.first)}';
    }
    final lo = weights.reduce((a, b) => a < b ? a : b);
    final hi = weights.reduce((a, b) => a > b ? a : b);
    return '$n sets · '
        '${WeightFormatter.formatKg(lo)}-${WeightFormatter.formatKg(hi)}kg';
  }

  // ---- bodyweight -------------------------------------------------------

  static String _bodyweight(List<PlannedSetDraft> sets) {
    final reps = <RepTarget>[];
    for (final s in sets) {
      final v = s.values;
      if (v is! PlannedSetDraftBodyweight) return '${sets.length} sets';
      reps.add(DraftParsing.parseRepTargetOrZero(v.repsInput));
    }
    final n = sets.length;
    if (reps.every((r) => r == reps.first)) {
      return 'BW · $n×${RepTargetFormatter.format(reps.first)}';
    }
    if (n <= 6) {
      return 'BW · ${reps.map(RepTargetFormatter.format).join('/')}';
    }
    return 'BW · $n sets';
  }

  // ---- time-based -------------------------------------------------------

  static String _timeBased(List<PlannedSetDraft> sets) {
    final durations = <int>[];
    final weights = <double?>[];
    for (final s in sets) {
      final v = s.values;
      if (v is! PlannedSetDraftTimeBased) return '${sets.length} sets';
      durations.add(int.tryParse(v.durationInput) ?? 0);
      weights.add(DraftParsing.parseOptionalWeight(v.weightInput));
    }
    final n = sets.length;
    final durationsUniform = durations.every((d) => d == durations.first);
    final weightsUniform = weights.every((w) => w == weights.first);
    final firstWeight = weights.first;

    if (durationsUniform && weightsUniform) {
      if (firstWeight == null) return '$n×${durations.first}s';
      return '${WeightFormatter.formatKg(firstWeight)}kg '
          '$n×${durations.first}s';
    }
    if (weightsUniform && !durationsUniform) {
      final list = durations.map((d) => '${d}s').join('/');
      if (n <= 6) {
        return firstWeight == null
            ? list
            : '${WeightFormatter.formatKg(firstWeight)}kg · $list';
      }
      return firstWeight == null
          ? '$n sets'
          : '${WeightFormatter.formatKg(firstWeight)}kg · $n sets';
    }
    if (durationsUniform && !weightsUniform) {
      final nonNull = weights.whereType<double>().toList();
      if (nonNull.isNotEmpty) {
        final lo = nonNull.reduce((a, b) => a < b ? a : b);
        final hi = nonNull.reduce((a, b) => a > b ? a : b);
        return '${WeightFormatter.formatKg(lo)}-${WeightFormatter.formatKg(hi)}kg '
            '$n×${durations.first}s';
      }
    }
    return '$n sets · ${durations.first}s';
  }

  static String _ellipsize(String input) {
    if (input.length <= _maxLength) return input;
    return '${input.substring(0, _maxLength - 1)}…';
  }
}
