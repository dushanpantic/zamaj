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
}
