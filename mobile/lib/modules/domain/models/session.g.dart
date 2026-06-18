// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Session _$SessionFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_Session', json, ($checkedConvert) {
  final val = _Session(
    id: $checkedConvert('id', (v) => v as String),
    workoutDayId: $checkedConvert('workoutDayId', (v) => v as String),
    snapshot: $checkedConvert(
      'snapshot',
      (v) => SessionSnapshot.fromJson(v as Map<String, dynamic>),
    ),
    sessionExercises: $checkedConvert(
      'sessionExercises',
      (v) => (v as List<dynamic>)
          .map((e) => SessionExercise.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    notes: $checkedConvert(
      'notes',
      (v) => (v as List<dynamic>)
          .map((e) => SessionNote.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    extraWork: $checkedConvert(
      'extraWork',
      (v) => (v as List<dynamic>)
          .map((e) => ExtraWork.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    startedAt: $checkedConvert('startedAt', (v) => DateTime.parse(v as String)),
    endedAt: $checkedConvert(
      'endedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
    isDeload: $checkedConvert('isDeload', (v) => v as bool? ?? false),
  );
  return val;
});

Map<String, dynamic> _$SessionToJson(_Session instance) => <String, dynamic>{
  'id': instance.id,
  'workoutDayId': instance.workoutDayId,
  'snapshot': instance.snapshot.toJson(),
  'sessionExercises': instance.sessionExercises.map((e) => e.toJson()).toList(),
  'notes': instance.notes.map((e) => e.toJson()).toList(),
  'extraWork': instance.extraWork.map((e) => e.toJson()).toList(),
  'startedAt': instance.startedAt.toIso8601String(),
  'endedAt': ?instance.endedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'schemaVersion': instance.schemaVersion,
  'isDeload': instance.isDeload,
};
