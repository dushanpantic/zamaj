import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

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
