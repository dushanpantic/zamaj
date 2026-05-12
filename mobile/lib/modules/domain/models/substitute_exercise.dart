import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

part 'substitute_exercise.freezed.dart';
part 'substitute_exercise.g.dart';

@freezed
abstract class SubstituteExercise with _$SubstituteExercise {
  const factory SubstituteExercise({
    required String name,
    required MeasurementType measurementType,
    ExerciseMetadata? metadata,
  }) = _SubstituteExercise;

  factory SubstituteExercise.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$SubstituteExerciseFromJson(json),
        json,
        'SubstituteExercise',
      );
}
