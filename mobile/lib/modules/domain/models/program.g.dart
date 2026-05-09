// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'program.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Program _$ProgramFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_Program', json, ($checkedConvert) {
  final val = _Program(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    workoutDayIds: $checkedConvert(
      'workoutDayIds',
      (v) => (v as List<dynamic>).map((e) => e as String).toList(),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ProgramToJson(_Program instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'workoutDayIds': instance.workoutDayIds,
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'schemaVersion': instance.schemaVersion,
};
