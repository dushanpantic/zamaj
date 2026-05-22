// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'library_exercise.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LibraryExercise _$LibraryExerciseFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('_LibraryExercise', json, ($checkedConvert) {
  final val = _LibraryExercise(
    id: $checkedConvert('id', (v) => v as String),
    name: $checkedConvert('name', (v) => v as String),
    measurementType: $checkedConvert(
      'measurementType',
      (v) => MeasurementType.fromJson(v as Map<String, dynamic>),
    ),
    videoUrl: $checkedConvert('videoUrl', (v) => v as String?),
    cues: $checkedConvert('cues', (v) => v as String?),
    archivedAt: $checkedConvert(
      'archivedAt',
      (v) => v == null ? null : DateTime.parse(v as String),
    ),
    createdAt: $checkedConvert('createdAt', (v) => DateTime.parse(v as String)),
    updatedAt: $checkedConvert('updatedAt', (v) => DateTime.parse(v as String)),
    schemaVersion: $checkedConvert('schemaVersion', (v) => (v as num).toInt()),
  );
  return val;
});

Map<String, dynamic> _$LibraryExerciseToJson(_LibraryExercise instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'measurementType': instance.measurementType.toJson(),
      'videoUrl': ?instance.videoUrl,
      'cues': ?instance.cues,
      'archivedAt': ?instance.archivedAt?.toIso8601String(),
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
