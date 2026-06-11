import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class FocusModeEvent extends Equatable {
  const FocusModeEvent();

  @override
  List<Object?> get props => const [];
}

final class FocusModeOpened extends FocusModeEvent {
  const FocusModeOpened({
    required this.sessionId,
    required this.anchorSessionExerciseId,
  });

  final String sessionId;
  final String anchorSessionExerciseId;

  @override
  List<Object?> get props => [sessionId, anchorSessionExerciseId];
}

final class FocusModeRetried extends FocusModeEvent {
  const FocusModeRetried();
}

/// Switches the focused group to the one containing
/// [anchorSessionExerciseId]. Drafts for the new panels seed from the
/// engine's last-set suggestion.
final class FocusModeGroupSwitched extends FocusModeEvent {
  const FocusModeGroupSwitched(this.anchorSessionExerciseId);

  final String anchorSessionExerciseId;

  @override
  List<Object?> get props => [anchorSessionExerciseId];
}

/// User tapped a partner card in a superset to make it the active panel.
/// Overrides auto-rotation until the next set is logged on it or the
/// user switches groups.
final class FocusModeFocusedPanelSelected extends FocusModeEvent {
  const FocusModeFocusedPanelSelected(this.sessionExerciseId);

  final String sessionExerciseId;

  @override
  List<Object?> get props => [sessionExerciseId];
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
  const FocusModeWeightBumped({
    required this.sessionExerciseId,
    required this.delta,
  });
  final String sessionExerciseId;
  final double delta;
  @override
  List<Object?> get props => [sessionExerciseId, delta];
}

final class FocusModeRepsBumped extends FocusModeEvent {
  const FocusModeRepsBumped({
    required this.sessionExerciseId,
    required this.delta,
  });
  final String sessionExerciseId;
  final int delta;
  @override
  List<Object?> get props => [sessionExerciseId, delta];
}

final class FocusModeDurationBumped extends FocusModeEvent {
  const FocusModeDurationBumped({
    required this.sessionExerciseId,
    required this.delta,
  });
  final String sessionExerciseId;
  final int delta;
  @override
  List<Object?> get props => [sessionExerciseId, delta];
}

final class FocusModeWeightEdited extends FocusModeEvent {
  const FocusModeWeightEdited({
    required this.sessionExerciseId,
    required this.weightKg,
  });

  final String sessionExerciseId;

  /// `null` clears the weight on a time-based draft. On a rep-based draft
  /// `null` is treated as `0`.
  final double? weightKg;
  @override
  List<Object?> get props => [sessionExerciseId, weightKg];
}

final class FocusModeRepsEdited extends FocusModeEvent {
  const FocusModeRepsEdited({
    required this.sessionExerciseId,
    required this.reps,
  });
  final String sessionExerciseId;
  final int reps;
  @override
  List<Object?> get props => [sessionExerciseId, reps];
}

final class FocusModeDurationEdited extends FocusModeEvent {
  const FocusModeDurationEdited({
    required this.sessionExerciseId,
    required this.seconds,
  });
  final String sessionExerciseId;
  final int seconds;
  @override
  List<Object?> get props => [sessionExerciseId, seconds];
}

// Stopwatch (time-based current set) ---------------------------------------

final class FocusModeStopwatchStarted extends FocusModeEvent {
  const FocusModeStopwatchStarted(this.sessionExerciseId);
  final String sessionExerciseId;
  @override
  List<Object?> get props => [sessionExerciseId];
}

final class FocusModeStopwatchStopped extends FocusModeEvent {
  const FocusModeStopwatchStopped();
}

final class FocusModeStopwatchTicked extends FocusModeEvent {
  const FocusModeStopwatchTicked();
}

/// Fired after the brief 00:00 hold once a countdown finishes, clearing the
/// `finished` flash and returning the panel to its idle target value.
final class FocusModeStopwatchReset extends FocusModeEvent {
  const FocusModeStopwatchReset();
}

// Set completion + undo -----------------------------------------------------

final class FocusModeSetCompleted extends FocusModeEvent {
  const FocusModeSetCompleted(this.sessionExerciseId);
  final String sessionExerciseId;
  @override
  List<Object?> get props => [sessionExerciseId];
}

final class FocusModeUndoRequested extends FocusModeEvent {
  const FocusModeUndoRequested();
}

// Per-exercise actions accessible from the focus AppBar / panel menu -------

final class FocusModeExerciseSkipped extends FocusModeEvent {
  const FocusModeExerciseSkipped(this.sessionExerciseId);
  final String sessionExerciseId;
  @override
  List<Object?> get props => [sessionExerciseId];
}

final class FocusModeExerciseMarkedDone extends FocusModeEvent {
  const FocusModeExerciseMarkedDone(this.sessionExerciseId);
  final String sessionExerciseId;
  @override
  List<Object?> get props => [sessionExerciseId];
}

// Rest timer ----------------------------------------------------------------

final class FocusModeRestTicked extends FocusModeEvent {
  const FocusModeRestTicked();
}

final class FocusModeRestSkipped extends FocusModeEvent {
  const FocusModeRestSkipped();
}
