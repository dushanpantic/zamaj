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

final class WorkoutDayPickerLoaded extends WorkoutDayPickerState {
  const WorkoutDayPickerLoaded({
    required this.program,
    required this.dayViewModels,
    required this.referenceNow,
    required this.window,
    this.activeSession,
    this.launchInFlightWorkoutDayId,
    this.lastTransientError,
    this.deloadSelected = false,
  });

  final Program program;
  final List<DayViewModel> dayViewModels;
  final DateTime referenceNow;
  final TrainingWeek window;

  /// Whether the "Deload week" toggle is on. A plain per-load selection that
  /// defaults to off on every full load — no week-derived inference — and is
  /// forwarded to the engine when a day is started.
  final bool deloadSelected;

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
    bool? deloadSelected,
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
      deloadSelected: deloadSelected ?? this.deloadSelected,
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
    deloadSelected,
  ];
}
