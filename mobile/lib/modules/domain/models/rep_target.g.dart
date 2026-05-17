// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rep_target.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepTargetFixed _$RepTargetFixedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RepTargetFixed', json, ($checkedConvert) {
      final val = RepTargetFixed(
        reps: $checkedConvert('reps', (v) => (v as num).toInt()),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$RepTargetFixedToJson(RepTargetFixed instance) =>
    <String, dynamic>{'reps': instance.reps, 'type': instance.$type};

RepTargetRange _$RepTargetRangeFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RepTargetRange', json, ($checkedConvert) {
      final val = RepTargetRange(
        minReps: $checkedConvert('minReps', (v) => (v as num).toInt()),
        maxReps: $checkedConvert('maxReps', (v) => (v as num).toInt()),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$RepTargetRangeToJson(RepTargetRange instance) =>
    <String, dynamic>{
      'minReps': instance.minReps,
      'maxReps': instance.maxReps,
      'type': instance.$type,
    };
