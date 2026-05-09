import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'exercise_group_kind.freezed.dart';
part 'exercise_group_kind.g.dart';

@Freezed(unionKey: 'type')
sealed class ExerciseGroupKind with _$ExerciseGroupKind {
  const factory ExerciseGroupKind.single() = SingleKind;
  const factory ExerciseGroupKind.superset() = SupersetKind;

  factory ExerciseGroupKind.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ExerciseGroupKindFromJson(json),
        json,
        'ExerciseGroupKind',
      );
}
