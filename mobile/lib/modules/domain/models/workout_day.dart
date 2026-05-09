import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';

part 'workout_day.freezed.dart';
part 'workout_day.g.dart';

@freezed
abstract class WorkoutDay with _$WorkoutDay {
  const WorkoutDay._();

  const factory WorkoutDay({
    required String id,
    required String programId,
    required String name,
    required List<ExerciseGroup> exerciseGroups,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _WorkoutDay;

  factory WorkoutDay.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$WorkoutDayFromJson(json),
        json,
        'WorkoutDay',
      );
}
