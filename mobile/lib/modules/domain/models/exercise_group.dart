import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';

part 'exercise_group.freezed.dart';
part 'exercise_group.g.dart';

@freezed
abstract class ExerciseGroup with _$ExerciseGroup {
  ExerciseGroup._() {
    ExerciseGroupInvariants.validate(id: id, kind: kind, exercises: exercises);
  }

  factory ExerciseGroup({
    required String id,
    required String workoutDayId,
    required int position,
    required ExerciseGroupKind kind,
    required List<Exercise> exercises,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
    @Default(ExerciseGroupRole.main) ExerciseGroupRole role,
  }) = _ExerciseGroup;

  factory ExerciseGroup.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ExerciseGroupFromJson(json),
        json,
        'ExerciseGroup',
      );
}

abstract final class ExerciseGroupInvariants {
  static void validate({
    required String id,
    required ExerciseGroupKind kind,
    required List<Exercise> exercises,
  }) {
    switch (kind) {
      case SingleKind():
        if (exercises.length != 1) {
          throw ValidationError(
            entityId: id,
            invariant: 'single_requires_exactly_one_exercise',
            message:
                'ExerciseGroup with kind=single must have exactly 1 exercise, '
                'got ${exercises.length}',
          );
        }
      case SupersetKind():
        if (exercises.length < 2) {
          throw ValidationError(
            entityId: id,
            invariant: 'superset_requires_at_least_two_exercises',
            message:
                'ExerciseGroup with kind=superset must have at least 2 exercises, '
                'got ${exercises.length}',
          );
        }
    }
  }
}
