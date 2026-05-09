// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_snapshot.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SessionSnapshot _$SessionSnapshotFromJson(Map<String, dynamic> json) =>
    $checkedCreate('_SessionSnapshot', json, ($checkedConvert) {
      final val = _SessionSnapshot(
        workoutDay: $checkedConvert(
          'workoutDay',
          (v) => WorkoutDay.fromJson(v as Map<String, dynamic>),
        ),
        canonicalJson: $checkedConvert('canonicalJson', (v) => v as String),
        sha256Hash: $checkedConvert('sha256Hash', (v) => v as String),
        capturedAt: $checkedConvert(
          'capturedAt',
          (v) => DateTime.parse(v as String),
        ),
        schemaVersion: $checkedConvert(
          'schemaVersion',
          (v) => (v as num).toInt(),
        ),
      );
      return val;
    });

Map<String, dynamic> _$SessionSnapshotToJson(_SessionSnapshot instance) =>
    <String, dynamic>{
      'workoutDay': instance.workoutDay.toJson(),
      'canonicalJson': instance.canonicalJson,
      'sha256Hash': instance.sha256Hash,
      'capturedAt': instance.capturedAt.toIso8601String(),
      'schemaVersion': instance.schemaVersion,
    };
