import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'measurement_type.freezed.dart';
part 'measurement_type.g.dart';

@Freezed(unionKey: 'type')
sealed class MeasurementType with _$MeasurementType {
  const factory MeasurementType.repBased() = RepBasedMeasurement;
  const factory MeasurementType.timeBased() = TimeBasedMeasurement;
  const factory MeasurementType.bodyweight() = BodyweightMeasurement;

  factory MeasurementType.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$MeasurementTypeFromJson(json),
        json,
        'MeasurementType',
      );
}
