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

final class WorkoutDayNameChanged extends WorkoutDayEditorEvent {
  const WorkoutDayNameChanged({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

final class ExerciseGroupAdded extends WorkoutDayEditorEvent {
  const ExerciseGroupAdded();

  @override
  List<Object?> get props => [];
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
    required this.measurementType,
  });

  final String groupDraftId;
  final String exerciseName;
  final MeasurementType measurementType;

  @override
  List<Object?> get props => [groupDraftId, exerciseName, measurementType];
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

final class GroupSavePressed extends WorkoutDayEditorEvent {
  const GroupSavePressed({required this.groupDraftId});

  final String groupDraftId;

  @override
  List<Object?> get props => [groupDraftId];
}

final class WorkoutDayExercisePressed extends WorkoutDayEditorEvent {
  const WorkoutDayExercisePressed({required this.exerciseDraftId});

  final String exerciseDraftId;

  @override
  List<Object?> get props => [exerciseDraftId];
}

final class WorkoutDaySavePressed extends WorkoutDayEditorEvent {
  const WorkoutDaySavePressed();

  @override
  List<Object?> get props => [];
}
