// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseGroup _$ExerciseGroupFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_ExerciseGroup', json, ($checkedConvert) {
  final val = _ExerciseGroup(
    id: $checkedConvert('id', (v) => v as String),
    workoutDayId: $checkedConvert('workoutDayId', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    kind: $checkedConvert(
      'kind',
      (v) => ExerciseGroupKind.fromJson(v as Map<String, dynamic>),
    ),
    exercises: $checkedConvert(
      'exercises',
      (v) => (v as List<dynamic>)
          .map((e) => Exercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ExerciseGroupToJson(_ExerciseGroup instance) =>
    <String, dynamic>{
      'id': instance.id,
      'workoutDayId': instance.workoutDayId,
      'position': instance.position,
      'kind': instance.kind.toJson(),
      'exercises': instance.exercises.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
