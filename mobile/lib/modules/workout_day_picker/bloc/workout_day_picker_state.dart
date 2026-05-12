import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_view_model.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';

sealed class WorkoutDayPickerState extends Equatable {
  const WorkoutDayPickerState();

  @override
  List<Object?> get props => const [];
}

final class WorkoutDayPickerInitial extends WorkoutDayPickerState {
  const WorkoutDayPickerInitial();
}

final class WorkoutDayPickerLoading extends WorkoutDayPickerState {
  const WorkoutDayPickerLoading(this.programId);

  final String programId;

  @override
  List<Object?> get props => [programId];
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
    required this.error,
  });

  final String programId;
  final DomainError error;

  @override
  List<Object?> get props => [programId, error];
}

final class WorkoutDayPickerLoaded extends WorkoutDayPickerState {
  const WorkoutDayPickerLoaded({
    required this.program,
    required this.dayViewModels,
    required this.referenceNow,
    required this.window,
    this.launchInFlightWorkoutDayId,
    this.lastTransientError,
  });

  final Program program;
  final List<DayViewModel> dayViewModels;
  final DateTime referenceNow;
  final CurrentWeekWindow window;
  final String? launchInFlightWorkoutDayId;
  final DomainError? lastTransientError;

  WorkoutDayPickerLoaded copyWith({
    Program? program,
    List<DayViewModel>? dayViewModels,
    DateTime? referenceNow,
    CurrentWeekWindow? window,
    String? Function()? launchInFlightWorkoutDayId,
    DomainError? Function()? lastTransientError,
  }) {
    return WorkoutDayPickerLoaded(
      program: program ?? this.program,
      dayViewModels: dayViewModels ?? this.dayViewModels,
      referenceNow: referenceNow ?? this.referenceNow,
      window: window ?? this.window,
      launchInFlightWorkoutDayId: launchInFlightWorkoutDayId != null
          ? launchInFlightWorkoutDayId()
          : this.launchInFlightWorkoutDayId,
      lastTransientError: lastTransientError != null
          ? lastTransientError()
          : this.lastTransientError,
    );
  }

  @override
  List<Object?> get props => [
    program,
    dayViewModels,
    referenceNow,
    window,
    launchInFlightWorkoutDayId,
    lastTransientError,
  ];
}
