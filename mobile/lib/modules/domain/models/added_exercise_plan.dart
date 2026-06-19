import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';

part 'added_exercise_plan.freezed.dart';
part 'added_exercise_plan.g.dart';

/// Inline plan carried by an exercise added to a live session that is not part
/// of the frozen day snapshot.
///
/// A [SessionExercise] whose `addedPlan` is non-null resolves its name,
/// measurement type, planned values, and set count from here rather than from
/// the snapshot — so added exercises (library-linked or one-off) record their
/// own intended work alongside the immutable plan without ever mutating it.
///
/// Mirrors [SubstituteExercise]'s shape and validation; the generalized
/// carrier supersedes it (the replaced/substitute machinery is retired once
/// composed replace ships).
@freezed
abstract class AddedExercisePlan with _$AddedExercisePlan {
  AddedExercisePlan._() {
    if (setCount < 1) {
      throw ValidationError(
        entityId: name,
        invariant: 'setCount_positive',
        message: 'setCount must be >= 1, got $setCount',
      );
    }
    if (libraryExerciseId != null && libraryExerciseId!.length != 36) {
      throw ValidationError(
        entityId: name,
        invariant: 'libraryExerciseId_not_uuid_v4',
        message:
            'libraryExerciseId must be canonical UUIDv4 (36 chars), '
            'got ${libraryExerciseId!.length}',
      );
    }
    final mismatch = switch ((measurementType, plannedValues)) {
      (RepBasedMeasurement(), PlannedRepBased()) => false,
      (TimeBasedMeasurement(), PlannedTimeBased()) => false,
      (BodyweightMeasurement(), PlannedBodyweight()) => false,
      _ => true,
    };
    if (mismatch) {
      throw ValidationError(
        entityId: name,
        invariant: 'measurementType_plannedValues_mismatch',
        message: 'measurementType does not match plannedValues variant',
      );
    }
  }

  factory AddedExercisePlan({
    required String name,
    required MeasurementType measurementType,
    required PlannedSetValues plannedValues,
    required int setCount,
    ExerciseMetadata? metadata,
    String? libraryExerciseId,
  }) = _AddedExercisePlan;

  factory AddedExercisePlan.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$AddedExercisePlanFromJson(json),
        json,
        'AddedExercisePlan',
      );
}
