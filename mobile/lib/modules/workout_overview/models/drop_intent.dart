import 'package:freezed_annotation/freezed_annotation.dart';

part 'drop_intent.freezed.dart';

@Freezed(unionKey: 'type')
sealed class DropTarget with _$DropTarget {
  const factory DropTarget.beforeIndex(int unfinishedIndex) = DropTargetGap;

  const factory DropTarget.ontoExercise(String sessionExerciseId) =
      DropTargetExercise;

  const factory DropTarget.outside() = DropTargetOutside;
}

@Freezed(unionKey: 'type')
sealed class DropIntent with _$DropIntent {
  const factory DropIntent.reorder({
    required String sessionId,
    required List<String> orderedUnfinishedIds,
  }) = ReorderIntent;

  const factory DropIntent.createSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) = CreateSupersetIntent;

  const factory DropIntent.appendToSuperset({
    required String sessionId,
    required String supersetTag,
    required String sessionExerciseId,
  }) = AppendToSupersetIntent;

  const factory DropIntent.noop() = NoopIntent;
}
