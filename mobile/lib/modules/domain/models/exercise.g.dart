// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Exercise _$ExerciseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_Exercise', json, ($checkedConvert) {
  final val = _Exercise(
    id: $checkedConvert('id', (v) => v as String),
    exerciseGroupId: $checkedConvert('exerciseGroupId', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    name: $checkedConvert('name', (v) => v as String),
    measurementType: $checkedConvert(
      'measurementType',
      (v) => MeasurementType.fromJson(v as Map<String, dynamic>),
    ),
    metadata: $checkedConvert(
      'metadata',
      (v) => ExerciseMetadata.fromJson(v as Map<String, dynamic>),
    ),
    plannedRestSeconds: $checkedConvert(
      'plannedRestSeconds',
      (v) => (v as num?)?.toInt(),
    ),
    libraryExerciseId: $checkedConvert(
      'libraryExerciseId',
      (v) => v as String?,
    ),
    sets: $checkedConvert(
      'sets',
      (v) => (v as List<dynamic>)
          .map((e) => WorkoutSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ExerciseToJson(_Exercise instance) => <String, dynamic>{
  'id': instance.id,
  'exerciseGroupId': instance.exerciseGroupId,
  'position': instance.position,
  'name': instance.name,
  'measurementType': instance.measurementType.toJson(),
  'metadata': instance.metadata.toJson(),
  'plannedRestSeconds': ?instance.plannedRestSeconds,
  'libraryExerciseId': ?instance.libraryExerciseId,
  'sets': instance.sets.map((e) => e.toJson()).toList(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'schemaVersion': instance.schemaVersion,
};
