import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';

part 'workout_set.freezed.dart';
part 'workout_set.g.dart';

@freezed
abstract class WorkoutSet with _$WorkoutSet {
  WorkoutSet._() {
    switch ((measurementType, plannedValues)) {
      case (
        RepBasedMeasurement(),
        PlannedRepBased(:final weightKg, :final reps),
      ):
        if (weightKg < 0) {
          throw ValidationError(
            entityId: id,
            invariant: 'weightKg_non_negative',
            message: 'weightKg must be >= 0, got $weightKg',
          );
        }
        if ((weightKg * 2).roundToDouble() != weightKg * 2) {
          throw ValidationError(
            entityId: id,
            invariant: 'weightKg_half_kg_resolution',
            message: 'weightKg must be a multiple of 0.5, got $weightKg',
          );
        }
        if (reps < 0) {
          throw ValidationError(
            entityId: id,
            invariant: 'reps_non_negative',
            message: 'reps must be >= 0, got $reps',
          );
        }
      case (TimeBasedMeasurement(), PlannedTimeBased(:final durationSeconds)):
        if (durationSeconds < 0) {
          throw ValidationError(
            entityId: id,
            invariant: 'durationSeconds_non_negative',
            message: 'durationSeconds must be >= 0, got $durationSeconds',
          );
        }
      case (RepBasedMeasurement(), _):
        throw ValidationError(
          entityId: id,
          invariant: 'plannedValues_variant_mismatch',
          message:
              'measurementType is repBased but plannedValues is ${plannedValues.runtimeType}',
        );
      case (TimeBasedMeasurement(), _):
        throw ValidationError(
          entityId: id,
          invariant: 'plannedValues_variant_mismatch',
          message:
              'measurementType is timeBased but plannedValues is ${plannedValues.runtimeType}',
        );
    }
  }

  factory WorkoutSet({
    required String id,
    required String exerciseId,
    required int position,
    required MeasurementType measurementType,
    required PlannedSetValues plannedValues,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _WorkoutSet;

  factory WorkoutSet.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$WorkoutSetFromJson(json),
        json,
        'WorkoutSet',
      );
}
