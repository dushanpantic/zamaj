import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class FocusModeEvent extends Equatable {
  const FocusModeEvent();

  @override
  List<Object?> get props => const [];
}

final class FocusModeOpened extends FocusModeEvent {
  const FocusModeOpened(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class FocusModeRetried extends FocusModeEvent {
  const FocusModeRetried();
}

/// Internal events ingest emissions from the engine's session watch-stream.
/// They live inside the sealed hierarchy because Dart will not let outside
/// classes extend a sealed type.
final class InternalFocusSessionPushed extends FocusModeEvent {
  const InternalFocusSessionPushed(this.sessionState);
  final SessionState sessionState;
  @override
  List<Object?> get props => [sessionState];
}

final class InternalFocusSessionMissing extends FocusModeEvent {
  const InternalFocusSessionMissing(this.sessionId);
  final String sessionId;
  @override
  List<Object?> get props => [sessionId];
}

final class InternalFocusSessionFailed extends FocusModeEvent {
  const InternalFocusSessionFailed(this.error, this.sessionId);
  final DomainError error;
  final String sessionId;
  @override
  List<Object?> get props => [error, sessionId];
}

final class FocusModeErrorDismissed extends FocusModeEvent {
  const FocusModeErrorDismissed();
}

// Editing the current draft -------------------------------------------------

final class FocusModeWeightBumped extends FocusModeEvent {
  const FocusModeWeightBumped(this.delta);
  final double delta;
  @override
  List<Object?> get props => [delta];
}

final class FocusModeRepsBumped extends FocusModeEvent {
  const FocusModeRepsBumped(this.delta);
  final int delta;
  @override
  List<Object?> get props => [delta];
}

final class FocusModeDurationBumped extends FocusModeEvent {
  const FocusModeDurationBumped(this.delta);
  final int delta;
  @override
  List<Object?> get props => [delta];
}

final class FocusModeWeightEdited extends FocusModeEvent {
  const FocusModeWeightEdited(this.weightKg);

  /// `null` clears the weight on a time-based draft. On a rep-based draft
  /// `null` is treated as `0`.
  final double? weightKg;
  @override
  List<Object?> get props => [weightKg];
}

final class FocusModeRepsEdited extends FocusModeEvent {
  const FocusModeRepsEdited(this.reps);
  final int reps;
  @override
  List<Object?> get props => [reps];
}

final class FocusModeDurationEdited extends FocusModeEvent {
  const FocusModeDurationEdited(this.seconds);
  final int seconds;
  @override
  List<Object?> get props => [seconds];
}

// Stopwatch (time-based current set) ---------------------------------------

final class FocusModeStopwatchStarted extends FocusModeEvent {
  const FocusModeStopwatchStarted();
}

final class FocusModeStopwatchStopped extends FocusModeEvent {
  const FocusModeStopwatchStopped();
}

final class FocusModeStopwatchTicked extends FocusModeEvent {
  const FocusModeStopwatchTicked();
}

// Set completion + undo -----------------------------------------------------

final class FocusModeSetCompleted extends FocusModeEvent {
  const FocusModeSetCompleted();
}

final class FocusModeUndoRequested extends FocusModeEvent {
  const FocusModeUndoRequested();
}

// Per-exercise actions accessible from the focus AppBar menu ---------------

final class FocusModeExerciseSkipped extends FocusModeEvent {
  const FocusModeExerciseSkipped();
}

final class FocusModeExerciseReplaced extends FocusModeEvent {
  const FocusModeExerciseReplaced({
    required this.substituteName,
    required this.substituteMeasurementType,
    required this.substitutePlannedValues,
    required this.substituteSetCount,
    this.substituteMetadata,
  });

  final String substituteName;
  final MeasurementType substituteMeasurementType;
  final PlannedSetValues substitutePlannedValues;
  final int substituteSetCount;
  final ExerciseMetadata? substituteMetadata;

  @override
  List<Object?> get props => [
    substituteName,
    substituteMeasurementType,
    substitutePlannedValues,
    substituteSetCount,
    substituteMetadata,
  ];
}

// Rest timer ----------------------------------------------------------------

final class FocusModeRestTicked extends FocusModeEvent {
  const FocusModeRestTicked();
}

final class FocusModeRestPaused extends FocusModeEvent {
  const FocusModeRestPaused();
}

final class FocusModeRestResumed extends FocusModeEvent {
  const FocusModeRestResumed();
}

final class FocusModeRestExtended extends FocusModeEvent {
  const FocusModeRestExtended({this.deltaSeconds = 15});
  final int deltaSeconds;
  @override
  List<Object?> get props => [deltaSeconds];
}

final class FocusModeRestSkipped extends FocusModeEvent {
  const FocusModeRestSkipped();
}
