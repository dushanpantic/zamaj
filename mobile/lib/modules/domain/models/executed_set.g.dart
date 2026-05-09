// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'executed_set.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExecutedSet _$ExecutedSetFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_ExecutedSet', json, ($checkedConvert) {
  final val = _ExecutedSet(
    id: $checkedConvert('id', (v) => v as String),
    sessionExerciseId: $checkedConvert('sessionExerciseId', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    measurementType: $checkedConvert(
      'measurementType',
      (v) => MeasurementType.fromJson(v as Map<String, dynamic>),
    ),
    actualValues: $checkedConvert(
      'actualValues',
      (v) => ActualSetValues.fromJson(v as Map<String, dynamic>),
    ),
    plannedSetIdInSnapshot: $checkedConvert(
      'plannedSetIdInSnapshot',
      (v) => v as String?,
    ),
    completedAt: $checkedConvert(
      'completedAt',
      (v) => DateTime.parse(v as String),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ExecutedSetToJson(_ExecutedSet instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionExerciseId': instance.sessionExerciseId,
      'position': instance.position,
      'measurementType': instance.measurementType.toJson(),
      'actualValues': instance.actualValues.toJson(),
      'plannedSetIdInSnapshot': ?instance.plannedSetIdInSnapshot,
      'completedAt': instance.completedAt.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
