import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_group_view_model.dart';
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

/// Every actionable exercise has terminated. The bloc keeps the latest
/// [sessionState] for context (e.g. so the "End session" affordance on
/// workout-overview still makes sense).
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
    required this.anchorSessionExerciseId,
    required this.groupViewModel,
    required this.drafts,
    required this.stopwatch,
    this.activeStopwatchExerciseId,
    this.restTimer,
    this.undoable,
    this.mutationInFlight = false,
    this.lastTransientError,
    this.userPinnedPanelId,
  });

  /// Authoritative engine-emitted session state.
  final SessionState sessionState;

  /// Identifies which group is focused — any exercise id within the visible
  /// group works; the assembler resolves it to the same panels regardless.
  final String anchorSessionExerciseId;

  /// Display projection of the focused group + its panels, built by
  /// [FocusModeAssembler.assemble].
  final FocusModeGroupViewModel groupViewModel;

  /// Editable actual values per panel, keyed by `sessionExerciseId`. Seeded
  /// on group switch and re-seeded for the just-completed exercise after a
  /// successful set log.
  final Map<String, ActualSetValues> drafts;

  /// Per-set stopwatch (time-based only). Always present; idle when not
  /// running. Tied to [activeStopwatchExerciseId] when running.
  final StopwatchViewModel stopwatch;

  /// Session-exercise id whose panel owns the running stopwatch. Null when
  /// [stopwatch.isRunning] is false.
  final String? activeStopwatchExerciseId;

  /// Rest timer state. Null between sets and after the rest is
  /// skipped/the next set is started. Global to the screen — the same
  /// timer is shared across panels in a superset.
  final RestTimerViewModel? restTimer;

  /// Reference to the most-recently logged set in this focused group for
  /// the undo affordance. Scoped to the group so a stale "Undo on X" never
  /// targets an exercise the user already navigated away from.
  final UndoableSet? undoable;

  /// True while an engine mutation is in flight. Used to suppress double
  /// taps.
  final bool mutationInFlight;

  final DomainError? lastTransientError;

  /// Session-exercise id the user has manually pinned as the active
  /// panel in a superset group. Overrides auto-rotation in the
  /// assembler. Cleared after the next set is logged on it, after a
  /// group switch, or when the pinned panel is no longer loggable.
  final String? userPinnedPanelId;

  ActualSetValues? draftFor(String sessionExerciseId) =>
      drafts[sessionExerciseId];

  FocusModeReady copyWith({
    SessionState? sessionState,
    String? anchorSessionExerciseId,
    FocusModeGroupViewModel? groupViewModel,
    Map<String, ActualSetValues>? drafts,
    StopwatchViewModel? stopwatch,
    String? Function()? activeStopwatchExerciseId,
    RestTimerViewModel? Function()? restTimer,
    UndoableSet? Function()? undoable,
    bool? mutationInFlight,
    DomainError? Function()? lastTransientError,
    String? Function()? userPinnedPanelId,
  }) {
    return FocusModeReady(
      sessionState: sessionState ?? this.sessionState,
      anchorSessionExerciseId:
          anchorSessionExerciseId ?? this.anchorSessionExerciseId,
      groupViewModel: groupViewModel ?? this.groupViewModel,
      drafts: drafts ?? this.drafts,
      stopwatch: stopwatch ?? this.stopwatch,
      activeStopwatchExerciseId: activeStopwatchExerciseId != null
          ? activeStopwatchExerciseId()
          : this.activeStopwatchExerciseId,
      restTimer: restTimer != null ? restTimer() : this.restTimer,
      undoable: undoable != null ? undoable() : this.undoable,
      mutationInFlight: mutationInFlight ?? this.mutationInFlight,
      lastTransientError: lastTransientError != null
          ? lastTransientError()
          : this.lastTransientError,
      userPinnedPanelId: userPinnedPanelId != null
          ? userPinnedPanelId()
          : this.userPinnedPanelId,
    );
  }

  @override
  List<Object?> get props => [
    sessionState,
    anchorSessionExerciseId,
    groupViewModel,
    drafts,
    stopwatch,
    activeStopwatchExerciseId,
    restTimer,
    undoable,
    mutationInFlight,
    lastTransientError,
    userPinnedPanelId,
  ];
}
