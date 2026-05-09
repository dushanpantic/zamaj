import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

part 'executed_set.freezed.dart';
part 'executed_set.g.dart';

@freezed
abstract class ExecutedSet with _$ExecutedSet {
  ExecutedSet._() {
    switch ((measurementType, actualValues)) {
      case (
        RepBasedMeasurement(),
        ActualRepBased(:final weightKg, :final reps),
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
      case (TimeBasedMeasurement(), ActualTimeBased(:final durationSeconds)):
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
          invariant: 'actualValues_variant_mismatch',
          message:
              'measurementType is repBased but actualValues is ${actualValues.runtimeType}',
        );
      case (TimeBasedMeasurement(), _):
        throw ValidationError(
          entityId: id,
          invariant: 'actualValues_variant_mismatch',
          message:
              'measurementType is timeBased but actualValues is ${actualValues.runtimeType}',
        );
    }
  }

  factory ExecutedSet({
    required String id,
    required String sessionExerciseId,
    required int position,
    required MeasurementType measurementType,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
    required DateTime completedAt,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _ExecutedSet;

  factory ExecutedSet.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ExecutedSetFromJson(json),
        json,
        'ExecutedSet',
      );
}
