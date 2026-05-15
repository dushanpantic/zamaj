// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'substitute_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubstituteExercise _$SubstituteExerciseFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SubstituteExercise', json, ($checkedConvert) {
      final val = _SubstituteExercise(
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
      );
      return val;
    });

Map<String, dynamic> _$SubstituteExerciseToJson(_SubstituteExercise instance) =>
    <String, dynamic>{
      'name': instance.name,
      'measurementType': instance.measurementType.toJson(),
      'plannedValues': instance.plannedValues.toJson(),
      'setCount': instance.setCount,
      'metadata': ?instance.metadata?.toJson(),
    };
