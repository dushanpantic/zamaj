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
    prominence: $checkedConvert(
      'prominence',
      (v) => $enumDecodeNullable(_$ProminenceEnumMap, v) ?? Prominence.common,
    ),
    primaryMuscles: $checkedConvert(
      'primaryMuscles',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
              .toList() ??
          const <MuscleGroup>[],
    ),
    secondaryMuscles: $checkedConvert(
      'secondaryMuscles',
      (v) =>
          (v as List<dynamic>?)
              ?.map((e) => $enumDecode(_$MuscleGroupEnumMap, e))
              .toList() ??
          const <MuscleGroup>[],
    ),
    source: $checkedConvert(
      'source',
      (v) =>
          $enumDecodeNullable(_$LibrarySourceEnumMap, v) ?? LibrarySource.user,
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

Map<String, dynamic> _$LibraryExerciseToJson(
  _LibraryExercise instance,
) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'measurementType': instance.measurementType.toJson(),
  'prominence': instance.prominence.toJson(),
  'primaryMuscles': instance.primaryMuscles.map((e) => e.toJson()).toList(),
  'secondaryMuscles': instance.secondaryMuscles.map((e) => e.toJson()).toList(),
  'source': instance.source.toJson(),
  'videoUrl': ?instance.videoUrl,
  'cues': ?instance.cues,
  'archivedAt': ?instance.archivedAt?.toIso8601String(),
  'createdAt': instance.createdAt.toIso8601String(),
  'updatedAt': instance.updatedAt.toIso8601String(),
  'schemaVersion': instance.schemaVersion,
};

const _$ProminenceEnumMap = {
  Prominence.common: 'common',
  Prominence.specialized: 'specialized',
};

const _$MuscleGroupEnumMap = {
  MuscleGroup.chest: 'chest',
  MuscleGroup.upperBack: 'upperBack',
  MuscleGroup.lats: 'lats',
  MuscleGroup.lowerBack: 'lowerBack',
  MuscleGroup.traps: 'traps',
  MuscleGroup.shoulders: 'shoulders',
  MuscleGroup.biceps: 'biceps',
  MuscleGroup.triceps: 'triceps',
  MuscleGroup.forearms: 'forearms',
  MuscleGroup.abs: 'abs',
  MuscleGroup.obliques: 'obliques',
  MuscleGroup.quadriceps: 'quadriceps',
  MuscleGroup.hamstrings: 'hamstrings',
  MuscleGroup.glutes: 'glutes',
  MuscleGroup.calves: 'calves',
  MuscleGroup.adductors: 'adductors',
  MuscleGroup.abductors: 'abductors',
  MuscleGroup.hipFlexors: 'hipFlexors',
  MuscleGroup.neck: 'neck',
};

const _$LibrarySourceEnumMap = {
  LibrarySource.user: 'user',
  LibrarySource.canonicalSeed: 'canonicalSeed',
};
