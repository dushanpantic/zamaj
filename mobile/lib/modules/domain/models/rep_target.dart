import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';

part 'rep_target.freezed.dart';
part 'rep_target.g.dart';

@Freezed(unionKey: 'type')
sealed class RepTarget with _$RepTarget {
  RepTarget._() {
    switch (this) {
      case RepTargetFixed(:final reps):
        if (reps < 0) {
          throw ValidationError(
            entityId: 'RepTarget',
            invariant: 'reps_non_negative',
            message: 'reps must be >= 0, got $reps',
          );
        }
      case RepTargetRange(:final minReps, :final maxReps):
        if (minReps < 0) {
          throw ValidationError(
            entityId: 'RepTarget',
            invariant: 'reps_non_negative',
            message: 'minReps must be >= 0, got $minReps',
          );
        }
        if (maxReps < minReps) {
          throw ValidationError(
            entityId: 'RepTarget',
            invariant: 'range_min_le_max',
            message: 'maxReps ($maxReps) must be >= minReps ($minReps)',
          );
        }
        if (minReps == maxReps) {
          throw ValidationError(
            entityId: 'RepTarget',
            invariant: 'range_distinct',
            message:
                'range bounds must differ; use RepTarget.fixed($minReps) instead',
          );
        }
    }
  }

  factory RepTarget.fixed({required int reps}) = RepTargetFixed;
  factory RepTarget.range({required int minReps, required int maxReps}) =
      RepTargetRange;

  factory RepTarget.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$RepTargetFromJson(json),
        json,
        'RepTarget',
      );

  /// Parses a rep-target input string into a [RepTarget].
  ///
  /// Accepts a single integer (`"8"`) or a hyphen / en-dash separated range
  /// (`"6-8"`, `"6 - 8"`, `"6–8"`); equal bounds collapse to a fixed target.
  /// Throws a [ValidationError] whose `invariant` carries a stable error code
  /// (`reps_invalid`, `reps_not_whole`, `reps_out_of_range`, `range_invalid`)
  /// that the program-authoring UI maps to its own messages.
  static RepTarget parse(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) {
      throw const ValidationError(
        entityId: 'RepTarget',
        invariant: 'reps_invalid',
        message: 'reps input must not be empty',
      );
    }

    final rangeMatch = RegExp(r'^(\d+)\s*[-–]\s*(\d+)$').firstMatch(trimmed);
    if (rangeMatch != null) {
      final min = int.tryParse(rangeMatch.group(1)!);
      final max = int.tryParse(rangeMatch.group(2)!);
      if (min == null || max == null) {
        throw const ValidationError(
          entityId: 'RepTarget',
          invariant: 'range_invalid',
          message: 'range bounds must be integers',
        );
      }
      if (min < 0 || max < 0 || min > 999 || max > 999) {
        throw const ValidationError(
          entityId: 'RepTarget',
          invariant: 'reps_out_of_range',
          message: 'reps must be in [0, 999]',
        );
      }
      if (max < min) {
        throw const ValidationError(
          entityId: 'RepTarget',
          invariant: 'range_invalid',
          message: 'range bounds must not be reversed',
        );
      }
      if (min == max) return RepTarget.fixed(reps: min);
      return RepTarget.range(minReps: min, maxReps: max);
    }

    final repsParsed = int.tryParse(trimmed);
    if (repsParsed == null) {
      if (double.tryParse(trimmed) == null) {
        throw const ValidationError(
          entityId: 'RepTarget',
          invariant: 'reps_invalid',
          message: 'reps must be a number',
        );
      }
      throw const ValidationError(
        entityId: 'RepTarget',
        invariant: 'reps_not_whole',
        message: 'reps must be a whole number',
      );
    }
    if (repsParsed < 0 || repsParsed > 999) {
      throw const ValidationError(
        entityId: 'RepTarget',
        invariant: 'reps_out_of_range',
        message: 'reps must be in [0, 999]',
      );
    }
    return RepTarget.fixed(reps: repsParsed);
  }
}
