import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/errors.dart';

part 'progress_point.freezed.dart';

/// A single point on an exercise's top-set progress series: the heaviest set
/// logged for the exercise in one completed session.
///
/// [date] is the session's `startedAt`. [topSetWeightKg] / [reps] describe that
/// session's heaviest `repBased` set (ties broken by higher reps upstream).
/// [programId] identifies the program the source workout day belonged to and is
/// retained for the deferred v2 per-program filter. [sourceWorkoutDayName] is
/// the snapshot workout-day name, surfaced in the v1 per-point tooltip.
@freezed
abstract class ProgressPoint with _$ProgressPoint {
  ProgressPoint._() {
    if (topSetWeightKg < 0) {
      throw ValidationError(
        entityId: 'ProgressPoint',
        invariant: 'topSetWeightKg_non_negative',
        message: 'topSetWeightKg must be >= 0, got $topSetWeightKg',
      );
    }
    if ((topSetWeightKg * 2).roundToDouble() != topSetWeightKg * 2) {
      throw ValidationError(
        entityId: 'ProgressPoint',
        invariant: 'topSetWeightKg_half_kg_resolution',
        message:
            'topSetWeightKg must be a multiple of 0.5, got $topSetWeightKg',
      );
    }
    if (reps < 0) {
      throw ValidationError(
        entityId: 'ProgressPoint',
        invariant: 'reps_non_negative',
        message: 'reps must be >= 0, got $reps',
      );
    }
  }

  factory ProgressPoint({
    required DateTime date,
    required double topSetWeightKg,
    required int reps,
    required String programId,
    required String sourceWorkoutDayName,
  }) = _ProgressPoint;
}
