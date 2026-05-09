// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutSet _$WorkoutSetFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_WorkoutSet', json, ($checkedConvert) {
  final val = _WorkoutSet(
    id: $checkedConvert('id', (v) => v as String),
    exerciseId: $checkedConvert('exerciseId', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    measurementType: $checkedConvert(
      'measurementType',
      (v) => MeasurementType.fromJson(v as Map<String, dynamic>),
    ),
    plannedValues: $checkedConvert(
      'plannedValues',
      (v) => PlannedSetValues.fromJson(v as Map<String, dynamic>),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$WorkoutSetToJson(_WorkoutSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'exerciseId': instance.exerciseId,
      'position': instance.position,
      'measurementType': instance.measurementType.toJson(),
      'plannedValues': instance.plannedValues.toJson(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
