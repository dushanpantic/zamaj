import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

part 'executed_set.freezed.dart';
part 'executed_set.g.dart';

/// A set the user actually performed for a session exercise.
///
/// [position] is a dense chronological index within the owning
/// [SessionExercise]: the first logged set has position 0, the second 1, and
/// so on. The repository keeps positions packed (0..N-1) by renumbering on
/// delete, so `executedSets[i]` is always the i-th set the user performed.
/// This is distinct from [WorkoutSet.position], which is a LexoRank-style
/// ordering value on the *template* side.
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
      case (
        TimeBasedMeasurement(),
        ActualTimeBased(:final durationSeconds, :final weightKg),
      ):
        if (durationSeconds < 0) {
          throw ValidationError(
            entityId: id,
            invariant: 'durationSeconds_non_negative',
            message: 'durationSeconds must be >= 0, got $durationSeconds',
          );
        }
        if (weightKg != null) {
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
        }
      case (BodyweightMeasurement(), ActualBodyweight(:final reps)):
        if (reps < 0) {
          throw ValidationError(
            entityId: id,
            invariant: 'reps_non_negative',
            message: 'reps must be >= 0, got $reps',
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
      case (BodyweightMeasurement(), _):
        throw ValidationError(
          entityId: id,
          invariant: 'actualValues_variant_mismatch',
          message:
              'measurementType is bodyweight but actualValues is ${actualValues.runtimeType}',
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
