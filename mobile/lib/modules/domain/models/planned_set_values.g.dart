// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_set_values.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlannedRepBased _$PlannedRepBasedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlannedRepBased', json, ($checkedConvert) {
      final val = PlannedRepBased(
        weightKg: $checkedConvert('weightKg', (v) => (v as num).toDouble()),
        reps: $checkedConvert('reps', (v) => (v as num).toInt()),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$PlannedRepBasedToJson(PlannedRepBased instance) =>
    <String, dynamic>{
      'weightKg': instance.weightKg,
      'reps': instance.reps,
      'type': instance.$type,
    };

PlannedTimeBased _$PlannedTimeBasedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlannedTimeBased', json, ($checkedConvert) {
      final val = PlannedTimeBased(
        durationSeconds: $checkedConvert(
          'durationSeconds',
          (v) => (v as num).toInt(),
        ),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$PlannedTimeBasedToJson(PlannedTimeBased instance) =>
    <String, dynamic>{
      'durationSeconds': instance.durationSeconds,
      'type': instance.$type,
    };
