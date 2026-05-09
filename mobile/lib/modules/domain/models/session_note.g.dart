// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_note.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionNote _$SessionNoteFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_SessionNote', json, ($checkedConvert) {
  final val = _SessionNote(
    id: $checkedConvert('id', (v) => v as String),
    sessionId: $checkedConvert('sessionId', (v) => v as String),
    body: $checkedConvert('body', (v) => v as String),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$SessionNoteToJson(_SessionNote instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'body': instance.body,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
