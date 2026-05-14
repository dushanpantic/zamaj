import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/rest_timer_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/undoable_set.dart';

sealed class FocusModeState extends Equatable {
  const FocusModeState();

  @override
  List<Object?> get props => const [];
}

final class FocusModeInitial extends FocusModeState {
  const FocusModeInitial();
}

final class FocusModeLoading extends FocusModeState {
  const FocusModeLoading(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class FocusModeNotFound extends FocusModeState {
  const FocusModeNotFound(this.sessionId);

  final String sessionId;

  @override
  List<Object?> get props => [sessionId];
}

final class FocusModeLoadFailure extends FocusModeState {
  const FocusModeLoadFailure({required this.sessionId, required this.error});

  final String sessionId;
  final DomainError error;

  @override
  List<Object?> get props => [sessionId, error];
}

/// All planned-and-actionable exercises have terminated. The cursor is
/// completed; the bloc keeps the latest [sessionState] for context (and so
/// the "End session" affordance on workout-overview still makes sense).
final class FocusModeWorkoutComplete extends FocusModeState {
  const FocusModeWorkoutComplete({
    required this.sessionState,
    this.lastTransientError,
  });

  final SessionState sessionState;
  final DomainError? lastTransientError;

  @override
  List<Object?> get props => [sessionState, lastTransientError];
}

final class FocusModeReady extends FocusModeState {
  const FocusModeReady({
    required this.sessionState,
    required this.viewModel,
    required this.draft,
    required this.stopwatch,
    this.restTimer,
    this.undoable,
    this.mutationInFlight = false,
    this.lastTransientError,
  });

  /// Authoritative engine-emitted session state. Every other field is
  /// derived from this or held as pure UI state.
  final SessionState sessionState;

  /// Display projection of the cursor target, built by
  /// [FocusModeAssembler.assemble].
  final FocusModeViewModel viewModel;

  /// Current editable actual values. Initially seeded from
  /// [SessionState.suggestedValues] and re-seeded on cursor advance, then
  /// mutated locally as the user bumps/edits.
  final ActualSetValues draft;

  /// Per-set stopwatch (time-based only). Always present; idle when not
  /// running. Rep-based screens simply ignore it.
  final StopwatchViewModel stopwatch;

  /// Rest timer state. Null between sets (before the first completion and
  /// after the rest is skipped/the next set is started).
  final RestTimerViewModel? restTimer;

  /// Reference to the most-recently logged set in this focus session for
  /// the UI's undo snackbar. Cleared on dismissal / new mutation / undo.
  final UndoableSet? undoable;

  /// True while an engine mutation is in flight. Used to suppress double
  /// taps.
  final bool mutationInFlight;

  final DomainError? lastTransientError;

  FocusModeReady copyWith({
    SessionState? sessionState,
    FocusModeViewModel? viewModel,
    ActualSetValues? draft,
    StopwatchViewModel? stopwatch,
    RestTimerViewModel? Function()? restTimer,
    UndoableSet? Function()? undoable,
    bool? mutationInFlight,
    DomainError? Function()? lastTransientError,
  }) {
    return FocusModeReady(
      sessionState: sessionState ?? this.sessionState,
      viewModel: viewModel ?? this.viewModel,
      draft: draft ?? this.draft,
      stopwatch: stopwatch ?? this.stopwatch,
      restTimer: restTimer != null ? restTimer() : this.restTimer,
      undoable: undoable != null ? undoable() : this.undoable,
      mutationInFlight: mutationInFlight ?? this.mutationInFlight,
      lastTransientError: lastTransientError != null
          ? lastTransientError()
          : this.lastTransientError,
    );
  }

  @override
  List<Object?> get props => [
    sessionState,
    viewModel,
    draft,
    stopwatch,
    restTimer,
    undoable,
    mutationInFlight,
    lastTransientError,
  ];
}
