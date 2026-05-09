// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'measurement_type.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

RepBasedMeasurement _$RepBasedMeasurementFromJson(Map<String, dynamic> json) =>
    $checkedCreate('RepBasedMeasurement', json, ($checkedConvert) {
      final val = RepBasedMeasurement(
        $type: $checkedConvert('type', (v) => v as String?),
      );
      return val;
    }, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$RepBasedMeasurementToJson(
  RepBasedMeasurement instance,
) => <String, dynamic>{'type': instance.$type};

TimeBasedMeasurement _$TimeBasedMeasurementFromJson(
  Map<String, dynamic> json,
) => $checkedCreate('TimeBasedMeasurement', json, ($checkedConvert) {
  final val = TimeBasedMeasurement(
    $type: $checkedConvert('type', (v) => v as String?),
  );
  return val;
}, fieldKeyMap: const {r'$type': 'type'});

Map<String, dynamic> _$TimeBasedMeasurementToJson(
  TimeBasedMeasurement instance,
) => <String, dynamic>{'type': instance.$type};
