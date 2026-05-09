// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'exercise_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ExerciseMetadata _$ExerciseMetadataFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_ExerciseMetadata', json, ($checkedConvert) {
      final val = _ExerciseMetadata(
        notes: $checkedConvert('notes', (v) => v as String?),
        videoUrl: $checkedConvert('videoUrl', (v) => v as String?),
      );
      return val;
    });

Map<String, dynamic> _$ExerciseMetadataToJson(_ExerciseMetadata instance) =>
    <String, dynamic>{'notes': ?instance.notes, 'videoUrl': ?instance.videoUrl};
