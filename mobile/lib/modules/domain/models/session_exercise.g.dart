// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionExercise _$SessionExerciseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_SessionExercise', json, ($checkedConvert) {
  final val = _SessionExercise(
    id: $checkedConvert('id', (v) => v as String),
    sessionId: $checkedConvert('sessionId', (v) => v as String),
    position: $checkedConvert('position', (v) => (v as num).toInt()),
    plannedExerciseIdInSnapshot: $checkedConvert(
      'plannedExerciseIdInSnapshot',
      (v) => v as String,
    ),
    state: $checkedConvert(
      'state',
      (v) => ExerciseState.fromJson(v as Map<String, dynamic>),
    ),
    executedSets: $checkedConvert(
      'executedSets',
      (v) => (v as List<dynamic>)
          .map((e) => ExecutedSet.fromJson(e as Map<String, dynamic>))
          .toList(),
    ),
    supersetTag: $checkedConvert('supersetTag', (v) => v as String?),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$SessionExerciseToJson(_SessionExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'sessionId': instance.sessionId,
      'position': instance.position,
      'plannedExerciseIdInSnapshot': instance.plannedExerciseIdInSnapshot,
      'state': instance.state.toJson(),
      'executedSets': instance.executedSets.map((e) => e.toJson()).toList(),
      'supersetTag': ?instance.supersetTag,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
