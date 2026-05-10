import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

part 'exercise.freezed.dart';
part 'exercise.g.dart';

@freezed
abstract class Exercise with _$Exercise {
  Exercise._() {
    if (plannedRestSeconds != null &&
        (plannedRestSeconds! < 0 || plannedRestSeconds! > 3600)) {
      throw ValidationError(
        entityId: id,
        invariant: 'plannedRestSeconds_out_of_range',
        message:
            'plannedRestSeconds must be in [0, 3600], got $plannedRestSeconds',
      );
    }
    for (final s in sets) {
      if (s.measurementType != measurementType) {
        throw ValidationError(
          entityId: id,
          invariant: 'set_measurement_type_mismatch',
          message:
              'WorkoutSet ${s.id} has measurementType ${s.measurementType} '
              'but exercise measurementType is $measurementType',
        );
      }
    }
  }

  factory Exercise({
    required String id,
    required String exerciseGroupId,
    required int position,
    required String name,
    required MeasurementType measurementType,
    required ExerciseMetadata metadata,
    int? plannedRestSeconds,
    required List<WorkoutSet> sets,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _Exercise;

  factory Exercise.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ExerciseFromJson(json),
        json,
        'Exercise',
      );
}
