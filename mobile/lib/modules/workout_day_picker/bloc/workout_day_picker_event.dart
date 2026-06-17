import 'package:equatable/equatable.dart';

sealed class WorkoutDayPickerEvent extends Equatable {
  const WorkoutDayPickerEvent();

  @override
  List<Object?> get props => const [];
}

final class WorkoutDayPickerOpened extends WorkoutDayPickerEvent {
  const WorkoutDayPickerOpened({
    required this.programId,
    required this.programName,
  });

  final String programId;
  final String programName;

  @override
  List<Object?> get props => [programId, programName];
}

final class WorkoutDayPickerRefreshRequested extends WorkoutDayPickerEvent {
  const WorkoutDayPickerRefreshRequested();
}

final class WorkoutDayPickerReturnedFromSession extends WorkoutDayPickerEvent {
  const WorkoutDayPickerReturnedFromSession();
}

final class WorkoutDayPickerScreenRetryRequested extends WorkoutDayPickerEvent {
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

// TEMP: snapshot link repair — remove after one-time run.
/// Requests the no-write repair preview for the loaded program.
final class WorkoutDayPickerRepairPreviewRequested
    extends WorkoutDayPickerEvent {
  const WorkoutDayPickerRepairPreviewRequested();
}

// TEMP: snapshot link repair — remove after one-time run.
/// Confirms and applies the previewed repair.
final class WorkoutDayPickerRepairConfirmed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerRepairConfirmed();
}

// TEMP: snapshot link repair — remove after one-time run.
/// Dismisses the repair preview / result without applying anything.
final class WorkoutDayPickerRepairDismissed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerRepairDismissed();
}
