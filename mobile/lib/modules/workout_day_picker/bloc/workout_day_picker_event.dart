import 'package:equatable/equatable.dart';

sealed class WorkoutDayPickerEvent extends Equatable {
  const WorkoutDayPickerEvent();

  @override
  List<Object?> get props => const [];
}

final class WorkoutDayPickerOpened extends WorkoutDayPickerEvent {
  const WorkoutDayPickerOpened(this.programId);

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class WorkoutDayPickerRefreshRequested extends WorkoutDayPickerEvent {
  const WorkoutDayPickerRefreshRequested();
}

final class WorkoutDayPickerReturnedFromSession extends WorkoutDayPickerEvent {
  const WorkoutDayPickerReturnedFromSession();
}

final class WorkoutDayPickerScreenRetryRequested
    extends WorkoutDayPickerEvent {
  const WorkoutDayPickerScreenRetryRequested();
}

final class WorkoutDayPickerTileRetryRequested extends WorkoutDayPickerEvent {
  const WorkoutDayPickerTileRetryRequested(this.workoutDayId);

  final String workoutDayId;

  @override
  List<Object?> get props => [workoutDayId];
}

final class WorkoutDayPickerStartPressed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerStartPressed(this.workoutDayId);

  final String workoutDayId;

  @override
  List<Object?> get props => [workoutDayId];
}

final class WorkoutDayPickerResumePressed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerResumePressed({
    required this.workoutDayId,
    required this.activeSessionId,
  });

  final String workoutDayId;
  final String activeSessionId;

  @override
  List<Object?> get props => [workoutDayId, activeSessionId];
}

final class WorkoutDayPickerErrorDismissed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerErrorDismissed();
}
