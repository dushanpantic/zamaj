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

  /// The kind implied by a group's member [count]: exactly one member is a
  /// single group, two or more form a superset. This is the one place the
  /// group-kind rule is stated — derivation ([ExerciseGroupDraft.kind]) and
  /// validation (ExerciseGroupInvariants) both go through it.
  static ExerciseGroupKind forMemberCount(int count) => count == 1
      ? const ExerciseGroupKind.single()
      : const ExerciseGroupKind.superset();
}
