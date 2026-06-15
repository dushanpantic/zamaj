import 'package:equatable/equatable.dart';

sealed class ExerciseProgressEvent extends Equatable {
  const ExerciseProgressEvent();

  @override
  List<Object?> get props => const [];
}

/// Load (or reload) the progress series for the screen's exercise. Dispatched
/// on open and re-dispatched by the error state's retry action; reloading also
/// recomputes from live data, so a since-deleted session drops out.
final class ExerciseProgressLoadRequested extends ExerciseProgressEvent {
  const ExerciseProgressLoadRequested();
}
