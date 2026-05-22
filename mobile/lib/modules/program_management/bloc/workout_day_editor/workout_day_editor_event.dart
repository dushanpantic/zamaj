import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class WorkoutDayEditorEvent extends Equatable {
  const WorkoutDayEditorEvent();
}

final class WorkoutDayEditorOpened extends WorkoutDayEditorEvent {
  const WorkoutDayEditorOpened({required this.workoutDayId});

  final String workoutDayId;

  @override
  List<Object?> get props => [workoutDayId];
}

final class WorkoutDayEditorRefreshed extends WorkoutDayEditorEvent {
  const WorkoutDayEditorRefreshed();

  @override
  List<Object?> get props => [];
}

final class WorkoutDayNameChanged extends WorkoutDayEditorEvent {
  const WorkoutDayNameChanged({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

final class QuickExerciseAdded extends WorkoutDayEditorEvent {
  const QuickExerciseAdded({required this.exerciseName});

  final String exerciseName;

  @override
  List<Object?> get props => [exerciseName];
}

final class LibraryExerciseAddedAsNew extends WorkoutDayEditorEvent {
  const LibraryExerciseAddedAsNew({required this.entry});

  final LibraryExercise entry;

  @override
  List<Object?> get props => [entry];
}

final class ExerciseGroupDeleted extends WorkoutDayEditorEvent {
  const ExerciseGroupDeleted({required this.groupDraftId});

  final String groupDraftId;

  @override
  List<Object?> get props => [groupDraftId];
}

final class ExerciseGroupsReordered extends WorkoutDayEditorEvent {
  const ExerciseGroupsReordered({required this.orderedGroupDraftIds});

  final List<String> orderedGroupDraftIds;

  @override
  List<Object?> get props => [orderedGroupDraftIds];
}

final class ExerciseAddedToGroup extends WorkoutDayEditorEvent {
  const ExerciseAddedToGroup({
    required this.groupDraftId,
    required this.exerciseName,
  });

  final String groupDraftId;
  final String exerciseName;

  @override
  List<Object?> get props => [groupDraftId, exerciseName];
}

final class ExerciseRemovedFromGroup extends WorkoutDayEditorEvent {
  const ExerciseRemovedFromGroup({
    required this.groupDraftId,
    required this.exerciseDraftId,
  });

  final String groupDraftId;
  final String exerciseDraftId;

  @override
  List<Object?> get props => [groupDraftId, exerciseDraftId];
}

final class ExerciseReorderedWithinGroup extends WorkoutDayEditorEvent {
  const ExerciseReorderedWithinGroup({
    required this.groupDraftId,
    required this.orderedExerciseDraftIds,
  });

  final String groupDraftId;
  final List<String> orderedExerciseDraftIds;

  @override
  List<Object?> get props => [groupDraftId, orderedExerciseDraftIds];
}

final class ExerciseDraggedOntoExercise extends WorkoutDayEditorEvent {
  const ExerciseDraggedOntoExercise({
    required this.sourceGroupDraftId,
    required this.sourceExerciseDraftId,
    required this.targetGroupDraftId,
    required this.targetExerciseDraftId,
  });

  final String sourceGroupDraftId;
  final String sourceExerciseDraftId;
  final String targetGroupDraftId;
  final String targetExerciseDraftId;

  @override
  List<Object?> get props => [
    sourceGroupDraftId,
    sourceExerciseDraftId,
    targetGroupDraftId,
    targetExerciseDraftId,
  ];
}

final class SupersetUngrouped extends WorkoutDayEditorEvent {
  const SupersetUngrouped({required this.groupDraftId});

  final String groupDraftId;

  @override
  List<Object?> get props => [groupDraftId];
}

final class ExerciseGroupRoleToggled extends WorkoutDayEditorEvent {
  const ExerciseGroupRoleToggled({
    required this.groupDraftId,
    required this.role,
  });

  final String groupDraftId;
  final ExerciseGroupRole role;

  @override
  List<Object?> get props => [groupDraftId, role];
}
