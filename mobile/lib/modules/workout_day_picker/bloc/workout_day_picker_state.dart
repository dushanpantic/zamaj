import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_view_model.dart';

sealed class WorkoutDayPickerState extends Equatable {
  const WorkoutDayPickerState();

  @override
  List<Object?> get props => const [];
}

final class WorkoutDayPickerInitial extends WorkoutDayPickerState {
  const WorkoutDayPickerInitial(this.programName);

  final String programName;

  @override
  List<Object?> get props => [programName];
}

final class WorkoutDayPickerLoading extends WorkoutDayPickerState {
  const WorkoutDayPickerLoading({
    required this.programId,
    required this.programName,
  });

  final String programId;
  final String programName;

  @override
  List<Object?> get props => [programId, programName];
}

final class WorkoutDayPickerProgramNotFound extends WorkoutDayPickerState {
  const WorkoutDayPickerProgramNotFound(this.programId);

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class WorkoutDayPickerScreenFailure extends WorkoutDayPickerState {
  const WorkoutDayPickerScreenFailure({
    required this.programId,
    required this.programName,
    required this.error,
  });

  final String programId;
  final String programName;
  final DomainError error;

  @override
  List<Object?> get props => [programId, programName, error];
}

// TEMP: snapshot link repair — remove after one-time run.
/// Counts surfaced by the repair preview / result dialog. Non-null on a loaded
/// state means the maintainer is mid-repair (preview or result shown).
final class WorkoutDayPickerRepairPreview extends Equatable {
  const WorkoutDayPickerRepairPreview({
    required this.sessionsScanned,
    required this.sessionsToChange,
    required this.exercisesToReLink,
    required this.unmatched,
    required this.currentUnlinked,
    required this.daysMissing,
  });

  final int sessionsScanned;
  final int sessionsToChange;
  final int exercisesToReLink;
  final int unmatched;
  final int currentUnlinked;
  final int daysMissing;

  @override
  List<Object?> get props => [
    sessionsScanned,
    sessionsToChange,
    exercisesToReLink,
    unmatched,
    currentUnlinked,
    daysMissing,
  ];
}

// TEMP: snapshot link repair — remove after one-time run.
/// Counts surfaced by the repair result summary after the rewrites are applied.
final class WorkoutDayPickerRepairResult extends Equatable {
  const WorkoutDayPickerRepairResult({
    required this.sessionsChanged,
    required this.exercisesReLinked,
    required this.unmatched,
    required this.currentUnlinked,
    required this.daysMissing,
  });

  final int sessionsChanged;
  final int exercisesReLinked;
  final int unmatched;
  final int currentUnlinked;
  final int daysMissing;

  @override
  List<Object?> get props => [
    sessionsChanged,
    exercisesReLinked,
    unmatched,
    currentUnlinked,
    daysMissing,
  ];
}

final class WorkoutDayPickerLoaded extends WorkoutDayPickerState {
  const WorkoutDayPickerLoaded({
    required this.program,
    required this.dayViewModels,
    required this.referenceNow,
    required this.window,
    this.activeSession,
    this.launchInFlightWorkoutDayId,
    this.lastTransientError,
    this.repairPreview,
    this.repairResult,
  });

  final Program program;
  final List<DayViewModel> dayViewModels;
  final DateTime referenceNow;
  final TrainingWeek window;

  /// TEMP: snapshot link repair — remove after one-time run. Non-null while the
  /// repair preview is shown.
  final WorkoutDayPickerRepairPreview? repairPreview;

  /// TEMP: snapshot link repair — remove after one-time run. Non-null once the
  /// repair has been applied and its result summary should be shown.
  final WorkoutDayPickerRepairResult? repairResult;

  /// The single in-flight session anywhere in the app (its `endedAt` is null),
  /// or null when nothing is in progress. While this is non-null, starting a
  /// *new* session is disallowed app-wide — only resuming the one already in
  /// progress is offered (Req: at most one session runs at a time).
  final Session? activeSession;

  final String? launchInFlightWorkoutDayId;
  final DomainError? lastTransientError;

  WorkoutDayPickerLoaded copyWith({
    Program? program,
    List<DayViewModel>? dayViewModels,
    DateTime? referenceNow,
    TrainingWeek? window,
    Session? Function()? activeSession,
    String? Function()? launchInFlightWorkoutDayId,
    DomainError? Function()? lastTransientError,
    WorkoutDayPickerRepairPreview? Function()? repairPreview,
    WorkoutDayPickerRepairResult? Function()? repairResult,
  }) {
    return WorkoutDayPickerLoaded(
      program: program ?? this.program,
      dayViewModels: dayViewModels ?? this.dayViewModels,
      referenceNow: referenceNow ?? this.referenceNow,
      window: window ?? this.window,
      activeSession: activeSession != null
          ? activeSession()
          : this.activeSession,
      launchInFlightWorkoutDayId: launchInFlightWorkoutDayId != null
          ? launchInFlightWorkoutDayId()
          : this.launchInFlightWorkoutDayId,
      lastTransientError: lastTransientError != null
          ? lastTransientError()
          : this.lastTransientError,
      repairPreview: repairPreview != null
          ? repairPreview()
          : this.repairPreview,
      repairResult: repairResult != null ? repairResult() : this.repairResult,
    );
  }

  @override
  List<Object?> get props => [
    program,
    dayViewModels,
    referenceNow,
    window,
    activeSession,
    launchInFlightWorkoutDayId,
    lastTransientError,
    repairPreview,
    repairResult,
  ];
}
