// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'added_exercise_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AddedExercisePlan _$AddedExercisePlanFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_AddedExercisePlan', json, ($checkedConvert) {
      final val = _AddedExercisePlan(
        name: $checkedConvert('name', (v) => v as String),
        measurementType: $checkedConvert(
          'measurementType',
          (v) => MeasurementType.fromJson(v as Map<String, dynamic>),
        ),
        plannedValues: $checkedConvert(
          'plannedValues',
          (v) => PlannedSetValues.fromJson(v as Map<String, dynamic>),
        ),
        setCount: $checkedConvert('setCount', (v) => (v as num).toInt()),
        metadata: $checkedConvert(
          'metadata',
          (v) => v == null
              ? null
              : ExerciseMetadata.fromJson(v as Map<String, dynamic>),
        ),
        libraryExerciseId: $checkedConvert(
          'libraryExerciseId',
          (v) => v as String?,
        ),
      );
      return val;
    });

Map<String, dynamic> _$AddedExercisePlanToJson(_AddedExercisePlan instance) =>
    <String, dynamic>{
      'name': instance.name,
      'measurementType': instance.measurementType.toJson(),
      'plannedValues': instance.plannedValues.toJson(),
      'setCount': instance.setCount,
      'metadata': ?instance.metadata?.toJson(),
      'libraryExerciseId': ?instance.libraryExerciseId,
    };
