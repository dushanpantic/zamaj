// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'actual_set_values.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ActualRepBased _$ActualRepBasedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActualRepBased', json, ($checkedConvert) {
      final val = ActualRepBased(
        weightKg: $checkedConvert('weightKg', (v) => (v as num).toDouble()),
        reps: $checkedConvert('reps', (v) => (v as num).toInt()),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$ActualRepBasedToJson(ActualRepBased instance) =>
    <String, dynamic>{
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'type': instance.$type,
    };

ActualTimeBased _$ActualTimeBasedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('ActualTimeBased', json, ($checkedConvert) {
      final val = ActualTimeBased(
        durationSeconds: $checkedConvert(
          'durationSeconds',
          (v) => (v as num).toInt(),
        ),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$ActualTimeBasedToJson(ActualTimeBased instance) =>
    <String, dynamic>{
      'durationSeconds': instance.durationSeconds,
      'type': instance.$type,
    };
