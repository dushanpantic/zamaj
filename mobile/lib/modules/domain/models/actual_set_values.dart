import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';

part 'actual_set_values.freezed.dart';
part 'actual_set_values.g.dart';

@Freezed(unionKey: 'type')
sealed class ActualSetValues with _$ActualSetValues {
  const factory ActualSetValues.repBased({
    required double weightKg,
    required int reps,
  }) = ActualRepBased;

  const factory ActualSetValues.timeBased({
    required int durationSeconds,
    double? weightKg,
  }) = ActualTimeBased;

  const factory ActualSetValues.bodyweight({required int reps}) =
      ActualBodyweight;

  factory ActualSetValues.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ActualSetValuesFromJson(json),
        json,
        'ActualSetValues',
      );
}

extension ActualSetValuesMatching on ActualSetValues {
  /// Whether these actual values are of the kind described by [type].
  ///
  /// The single source of truth for the `measurementType` ↔ `actualValues`
  /// variant pairing — previously re-implemented in the engine, the Drift
  /// repo, and the focus bloc.
  bool matches(MeasurementType type) => switch ((type, this)) {
    (RepBasedMeasurement(), ActualRepBased()) => true,
    (TimeBasedMeasurement(), ActualTimeBased()) => true,
    (BodyweightMeasurement(), ActualBodyweight()) => true,
    _ => false,
  };
}
