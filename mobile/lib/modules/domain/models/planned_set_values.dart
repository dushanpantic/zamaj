import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'planned_set_values.freezed.dart';
part 'planned_set_values.g.dart';

@Freezed(unionKey: 'type')
sealed class PlannedSetValues with _$PlannedSetValues {
  const factory PlannedSetValues.repBased({
    required double weightKg,
    required int reps,
  }) = PlannedRepBased;

  const factory PlannedSetValues.timeBased({required int durationSeconds}) =
      PlannedTimeBased;

  factory PlannedSetValues.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$PlannedSetValuesFromJson(json),
        json,
        'PlannedSetValues',
      );
}
