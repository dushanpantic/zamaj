// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'extra_work.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExtraWork _$ExtraWorkFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_ExtraWork', json, ($checkedConvert) {
  final val = _ExtraWork(
    id: $checkedConvert('id', (v) => v as String),
    sessionId: $checkedConvert('sessionId', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    body: $checkedConvert('body', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$ExtraWorkToJson(_ExtraWork instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'position': instance.position,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
