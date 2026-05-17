// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'planned_set_values.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PlannedRepBased _$PlannedRepBasedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlannedRepBased', json, ($checkedConvert) {
      final val = PlannedRepBased(
        weightKg: $checkedConvert('weightKg', (v) => (v as num).toDouble()),
        repTarget: $checkedConvert(
          'repTarget',
          (v) => RepTarget.fromJson(v as Map<String, dynamic>),
        ),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$PlannedRepBasedToJson(PlannedRepBased instance) =>
    <String, dynamic>{
      'weightKg': instance.weightKg,
      'repTarget': instance.repTarget.toJson(),
      'type': instance.$type,
    };

PlannedTimeBased _$PlannedTimeBasedFromJson(Map<String, dynamic> json) =>
    $checkedCreate('PlannedTimeBased', json, ($checkedConvert) {
      final val = PlannedTimeBased(
        durationSeconds: $checkedConvert(
          'durationSeconds',
          (v) => (v as num).toInt(),
        ),
        weightKg: $checkedConvert('weightKg', (v) => (v as num?)?.toDouble()),
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$PlannedTimeBasedToJson(PlannedTimeBased instance) =>
    <String, dynamic>{
      'durationSeconds': instance.durationSeconds,
      'weightKg': ?instance.weightKg,
      'type': instance.$type,
    };
