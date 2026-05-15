import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';

part 'substitute_exercise.freezed.dart';
part 'substitute_exercise.g.dart';

@freezed
abstract class SubstituteExercise with _$SubstituteExercise {
  SubstituteExercise._() {
    if (setCount < 1) {
      throw ValidationError(
        entityId: name,
        invariant: 'setCount_positive',
        message: 'setCount must be >= 1, got $setCount',
      );
    }
    final mismatch = switch ((measurementType, plannedValues)) {
      (RepBasedMeasurement(), PlannedRepBased()) => false,
      (TimeBasedMeasurement(), PlannedTimeBased()) => false,
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

  factory SubstituteExercise({
    required String name,
    required MeasurementType measurementType,
    required PlannedSetValues plannedValues,
    required int setCount,
    ExerciseMetadata? metadata,
  }) = _SubstituteExercise;

  factory SubstituteExercise.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$SubstituteExerciseFromJson(json),
        json,
        'SubstituteExercise',
      );
}
