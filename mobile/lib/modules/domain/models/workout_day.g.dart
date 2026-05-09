// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'workout_day.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WorkoutDay _$WorkoutDayFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_WorkoutDay', json, ($checkedConvert) {
  final val = _WorkoutDay(
    id: $checkedConvert('id', (v) => v as String),
    programId: $checkedConvert('programId', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    exerciseGroups: $checkedConvert(
      'exerciseGroups',
      (v) => (v as List<dynamic>)
          .map((e) => ExerciseGroup.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$WorkoutDayToJson(_WorkoutDay instance) =>
    <String, dynamic>{
      'id': instance.id,
      'programId': instance.programId,
      'name': instance.name,
      'exerciseGroups': instance.exerciseGroups.map((e) => e.toJson()).toList(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
