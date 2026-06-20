import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

part 'exercise_state.freezed.dart';
part 'exercise_state.g.dart';

@Freezed(unionKey: 'type')
sealed class ExerciseState with _$ExerciseState {
  const factory ExerciseState.unfinished() = UnfinishedState;
  const factory ExerciseState.completed() = CompletedState;
  const factory ExerciseState.skipped() = SkippedState;

  factory ExerciseState.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$ExerciseStateFromJson(json),
        json,
        'ExerciseState',
      );
}

extension ExerciseStateDiscriminator on ExerciseState {
  /// Stable, persistence-compatible discriminator. Matches the JSON union key
  /// and the `stateDiscriminator` column used by the Drift session schema.
  String get discriminator => switch (this) {
    UnfinishedState() => 'unfinished',
    CompletedState() => 'completed',
    SkippedState() => 'skipped',
  };
}
