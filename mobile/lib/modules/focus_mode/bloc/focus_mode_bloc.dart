import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/bloc/focus_mode_event.dart';
import 'package:zamaj/modules/focus_mode/bloc/focus_mode_state.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_group_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/rest_timer_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/undoable_set.dart';
import 'package:zamaj/modules/focus_mode/services/focus_mode_assembler.dart';
import 'package:zamaj/modules/focus_mode/services/increment_rules.dart';

/// Owns the execution screen's runtime state.
///
/// Responsibilities:
///   - Hydrate from the engine on open / refresh and on group switch
///   - Maintain a per-panel editable [drafts] map; reseed on group switch
///     and after the matching panel's set is logged
///   - Run the rest timer and per-set stopwatch as Timer.periodic streams
///     (an internal-only signal — tests can drive the same ticks by
///     adding `FocusModeRestTicked` / `FocusModeStopwatchTicked` directly)
///   - Dispatch engine mutations (completeSet / deleteExecutedSet / skip /
///     markDone / replace) targeted at a specific panel
class FocusModeBloc extends Bloc<FocusModeEvent, FocusModeState> {
  FocusModeBloc({required SessionFlowEngine sessionFlowEngine})
    : _engine = sessionFlowEngine,
      super(const FocusModeInitial()) {
    on<FocusModeOpened>(_onOpened);
    on<FocusModeRetried>(_onRetried);
    on<FocusModeGroupSwitched>(_onGroupSwitched);
    on<FocusModeFocusedPanelSelected>(_onFocusedPanelSelected);
    on<InternalFocusSessionPushed>(_onSessionPushed);
    on<InternalFocusSessionMissing>(_onSessionMissing);
    on<InternalFocusSessionFailed>(_onSessionFailed);
    on<FocusModeErrorDismissed>(_onErrorDismissed);

    on<FocusModeWeightBumped>(_onWeightBumped);
    on<FocusModeRepsBumped>(_onRepsBumped);
    on<FocusModeDurationBumped>(_onDurationBumped);
    on<FocusModeWeightEdited>(_onWeightEdited);
    on<FocusModeRepsEdited>(_onRepsEdited);
    on<FocusModeDurationEdited>(_onDurationEdited);

    on<FocusModeStopwatchStarted>(_onStopwatchStarted);
    on<FocusModeStopwatchStopped>(_onStopwatchStopped);
    on<FocusModeStopwatchTicked>(_onStopwatchTicked);

    on<FocusModeSetCompleted>(_onSetCompleted);
    on<FocusModeUndoRequested>(_onUndoRequested);

    on<FocusModeExerciseSkipped>(_onExerciseSkipped);
    on<FocusModeExerciseMarkedDone>(_onExerciseMarkedDone);
    on<FocusModeExerciseReplaced>(_onExerciseReplaced);

    on<FocusModeRestTicked>(_onRestTicked);
    on<FocusModeRestPaused>(_onRestPaused);
    on<FocusModeRestResumed>(_onRestResumed);
    on<FocusModeRestExtended>(_onRestExtended);
    on<FocusModeRestSkipped>(_onRestSkipped);
  }

  final SessionFlowEngine _engine;

  Timer? _restTicker;
  Timer? _stopwatchTicker;
  StreamSubscription<SessionState?>? _streamSub;
  String? _watchedSessionId;
  String? _pendingAnchorId;

  @override
  Future<void> close() async {
    _restTicker?.cancel();
    _stopwatchTicker?.cancel();
    await _streamSub?.cancel();
    return super.close();
  }

  // ---------------- Lifecycle ----------------

  Future<void> _onOpened(
    FocusModeOpened event,
    Emitter<FocusModeState> emit,
  ) async {
    emit(FocusModeLoading(event.sessionId));
    _pendingAnchorId = event.anchorSessionExerciseId;
    await _subscribe(event.sessionId);
  }

  Future<void> _onRetried(
    FocusModeRetried event,
    Emitter<FocusModeState> emit,
  ) async {
    final sessionId = _sessionIdOrNull();
    final anchor = _currentAnchorOrNull() ?? _pendingAnchorId;
    if (sessionId == null || anchor == null) return;
    add(FocusModeOpened(sessionId: sessionId, anchorSessionExerciseId: anchor));
  }

  Future<void> _onGroupSwitched(
    FocusModeGroupSwitched event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    _stopStopwatchTicker();
    _stopRestTicker();
    emit(
      _assembleFromSessionState(
        current.sessionState,
        anchor: event.anchorSessionExerciseId,
        priorDrafts: const {},
        userPinnedPanelId: null,
      ),
    );
  }

  Future<void> _onFocusedPanelSelected(
    FocusModeFocusedPanelSelected event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    // Only honor pins that name a loggable panel in the current group.
    final panel = _findPanel(current, event.sessionExerciseId);
    if (panel == null || !panel.isLoggable) return;
    if (current.userPinnedPanelId == event.sessionExerciseId) return;
    final group = FocusModeAssembler.assemble(
      current.sessionState,
      anchorSessionExerciseId: current.anchorSessionExerciseId,
      userPinnedPanelId: event.sessionExerciseId,
    );
    if (group == null) return;
    emit(
      current.copyWith(
        groupViewModel: group,
        userPinnedPanelId: () => event.sessionExerciseId,
      ),
    );
  }

  Future<void> _subscribe(String sessionId) async {
    await _streamSub?.cancel();
    _watchedSessionId = sessionId;
    _streamSub = _engine
        .watchSession(sessionId: sessionId)
        .listen(
          (sessionState) {
            if (sessionState == null) {
              add(InternalFocusSessionMissing(sessionId));
            } else {
              add(InternalFocusSessionPushed(sessionState));
            }
          },
          onError: (Object error) {
            if (error is DomainError) {
              add(InternalFocusSessionFailed(error, sessionId));
            }
          },
        );
  }

  Future<void> _onSessionPushed(
    InternalFocusSessionPushed event,
    Emitter<FocusModeState> emit,
  ) async {
    emit(_reassembleAfterRefresh(event.sessionState));
  }

  Future<void> _onSessionMissing(
    InternalFocusSessionMissing event,
    Emitter<FocusModeState> emit,
  ) async {
    emit(FocusModeNotFound(event.sessionId));
  }

  Future<void> _onSessionFailed(
    InternalFocusSessionFailed event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is FocusModeReady) {
      emit(current.copyWith(lastTransientError: () => event.error));
    } else if (current is FocusModeWorkoutComplete) {
      emit(
        FocusModeWorkoutComplete(
          sessionState: current.sessionState,
          lastTransientError: event.error,
        ),
      );
    } else {
      emit(
        FocusModeLoadFailure(sessionId: event.sessionId, error: event.error),
      );
    }
  }

  Future<void> _onErrorDismissed(
    FocusModeErrorDismissed event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is FocusModeReady && current.lastTransientError != null) {
      emit(current.copyWith(lastTransientError: () => null));
    } else if (current is FocusModeWorkoutComplete &&
        current.lastTransientError != null) {
      emit(FocusModeWorkoutComplete(sessionState: current.sessionState));
    }
  }

  // ---------------- Draft edits ----------------

  Future<void> _onWeightBumped(
    FocusModeWeightBumped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draftFor(event.sessionExerciseId);
    if (draft == null) return;
    final next = switch (draft) {
      ActualRepBased() => ActualSetValues.repBased(
        weightKg: IncrementRules.bumpWeight(draft.weightKg, event.delta),
        reps: draft.reps,
      ),
      ActualTimeBased() => ActualSetValues.timeBased(
        durationSeconds: draft.durationSeconds,
        weightKg: IncrementRules.bumpWeight(draft.weightKg ?? 0, event.delta),
      ),
      ActualBodyweight() => draft,
    };
    emit(
      current.copyWith(
        drafts: _replaceDraft(current.drafts, event.sessionExerciseId, next),
      ),
    );
  }

  Future<void> _onRepsBumped(
    FocusModeRepsBumped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draftFor(event.sessionExerciseId);
    final next = switch (draft) {
      ActualRepBased() => ActualSetValues.repBased(
        weightKg: draft.weightKg,
        reps: IncrementRules.bumpReps(draft.reps, event.delta),
      ),
      ActualBodyweight() => ActualSetValues.bodyweight(
        reps: IncrementRules.bumpReps(draft.reps, event.delta),
      ),
      _ => null,
    };
    if (next == null) return;
    emit(
      current.copyWith(
        drafts: _replaceDraft(current.drafts, event.sessionExerciseId, next),
      ),
    );
  }

  Future<void> _onDurationBumped(
    FocusModeDurationBumped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draftFor(event.sessionExerciseId);
    if (draft is! ActualTimeBased) return;
    emit(
      current.copyWith(
        drafts: _replaceDraft(
          current.drafts,
          event.sessionExerciseId,
          ActualSetValues.timeBased(
            durationSeconds: IncrementRules.bumpDuration(
              draft.durationSeconds,
              event.delta,
            ),
            weightKg: draft.weightKg,
          ),
        ),
      ),
    );
  }

  Future<void> _onWeightEdited(
    FocusModeWeightEdited event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draftFor(event.sessionExerciseId);
    if (draft == null) return;
    final raw = event.weightKg;
    final rounded = raw == null ? null : (raw * 2).round() / 2;
    final clamped = rounded == null ? null : (rounded < 0 ? 0.0 : rounded);
    final next = switch (draft) {
      ActualRepBased() => ActualSetValues.repBased(
        weightKg: clamped ?? 0,
        reps: draft.reps,
      ),
      ActualTimeBased() => ActualSetValues.timeBased(
        durationSeconds: draft.durationSeconds,
        weightKg: clamped,
      ),
      ActualBodyweight() => draft,
    };
    emit(
      current.copyWith(
        drafts: _replaceDraft(current.drafts, event.sessionExerciseId, next),
      ),
    );
  }

  Future<void> _onRepsEdited(
    FocusModeRepsEdited event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draftFor(event.sessionExerciseId);
    if (draft is! ActualRepBased) return;
    final clamped = event.reps < 0 ? 0 : event.reps;
    emit(
      current.copyWith(
        drafts: _replaceDraft(
          current.drafts,
          event.sessionExerciseId,
          ActualSetValues.repBased(weightKg: draft.weightKg, reps: clamped),
        ),
      ),
    );
  }

  Future<void> _onDurationEdited(
    FocusModeDurationEdited event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draftFor(event.sessionExerciseId);
    if (draft is! ActualTimeBased) return;
    final clamped = event.seconds < 0 ? 0 : event.seconds;
    emit(
      current.copyWith(
        drafts: _replaceDraft(
          current.drafts,
          event.sessionExerciseId,
          ActualSetValues.timeBased(
            durationSeconds: clamped,
            weightKg: draft.weightKg,
          ),
        ),
      ),
    );
  }

  // ---------------- Stopwatch ----------------

  Future<void> _onStopwatchStarted(
    FocusModeStopwatchStarted event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final panel = _findPanel(current, event.sessionExerciseId);
    if (panel == null) return;
    if (panel.effectiveMeasurementType is! TimeBasedMeasurement) return;
    _stopRestTicker();
    _startStopwatchTicker();
    emit(
      current.copyWith(
        stopwatch: const StopwatchViewModel(isRunning: true, elapsedSeconds: 0),
        activeStopwatchExerciseId: () => event.sessionExerciseId,
        restTimer: () => null,
      ),
    );
  }

  Future<void> _onStopwatchTicked(
    FocusModeStopwatchTicked event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    if (!current.stopwatch.isRunning) return;
    final exerciseId = current.activeStopwatchExerciseId;
    if (exerciseId == null) return;
    final next = current.stopwatch.elapsedSeconds + 1;
    final draft = current.draftFor(exerciseId);
    final newDraft = draft is ActualTimeBased
        ? ActualSetValues.timeBased(
            durationSeconds: next,
            weightKg: draft.weightKg,
          )
        : draft;
    emit(
      current.copyWith(
        stopwatch: StopwatchViewModel(isRunning: true, elapsedSeconds: next),
        drafts: newDraft == null
            ? current.drafts
            : _replaceDraft(current.drafts, exerciseId, newDraft),
      ),
    );
  }

  Future<void> _onStopwatchStopped(
    FocusModeStopwatchStopped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    _stopStopwatchTicker();
    if (!current.stopwatch.isRunning) return;
    emit(
      current.copyWith(
        stopwatch: StopwatchViewModel(
          isRunning: false,
          elapsedSeconds: current.stopwatch.elapsedSeconds,
        ),
        activeStopwatchExerciseId: () => null,
      ),
    );
  }

  // ---------------- Set completion / undo ----------------

  Future<void> _onSetCompleted(
    FocusModeSetCompleted event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    if (current.mutationInFlight) return;
    final panel = _findPanel(current, event.sessionExerciseId);
    if (panel == null || !panel.isLoggable) return;
    final draft = current.draftFor(event.sessionExerciseId);
    if (draft == null) return;
    if (current.activeStopwatchExerciseId == event.sessionExerciseId) {
      _stopStopwatchTicker();
    }

    emit(current.copyWith(mutationInFlight: true));
    try {
      final next = await _engine.completeSet(
        sessionExerciseId: event.sessionExerciseId,
        actualValues: draft,
        plannedSetIdInSnapshot: panel.currentPlannedSetIdInSnapshot,
      );
      final justLoggedSetId = _newestExecutedSetId(
        sessionState: next,
        sessionExerciseId: event.sessionExerciseId,
      );
      final undoable = justLoggedSetId == null
          ? null
          : UndoableSet(
              executedSetId: justLoggedSetId,
              sessionExerciseId: event.sessionExerciseId,
              exerciseDisplayName: panel.displayExerciseName,
            );
      final reassembled = _assembleAfterMutation(
        next,
        priorDrafts: current.drafts,
        completedExerciseId: event.sessionExerciseId,
        undoable: undoable,
        restTimer: _restTimerFromPanel(panel),
      );
      emit(reassembled);
      if (reassembled is FocusModeReady && reassembled.restTimer != null) {
        _startRestTicker();
      }
    } on DomainError catch (e) {
      final latest = state;
      if (latest is FocusModeReady) {
        emit(
          latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
        );
      }
    }
  }

  Future<void> _onUndoRequested(
    FocusModeUndoRequested event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    final undoable = switch (current) {
      FocusModeReady() => current.undoable,
      _ => null,
    };
    if (undoable == null) return;
    if (current is FocusModeReady && current.mutationInFlight) return;

    if (current is FocusModeReady) {
      emit(current.copyWith(mutationInFlight: true, undoable: () => null));
    }
    try {
      final next = await _engine.deleteExecutedSet(
        executedSetId: undoable.executedSetId,
      );
      _stopRestTicker();
      emit(
        _assembleAfterMutation(
          next,
          priorDrafts: current is FocusModeReady ? current.drafts : const {},
          completedExerciseId: undoable.sessionExerciseId,
          undoable: null,
          restTimer: null,
        ),
      );
    } on DomainError catch (e) {
      final latest = state;
      if (latest is FocusModeReady) {
        emit(
          latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
        );
      }
    }
  }

  // ---------------- Exercise actions ----------------

  Future<void> _onExerciseSkipped(
    FocusModeExerciseSkipped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    if (current.mutationInFlight) return;
    emit(current.copyWith(mutationInFlight: true, undoable: () => null));
    try {
      final next = await _engine.skipExercise(
        sessionExerciseId: event.sessionExerciseId,
      );
      _stopRestTicker();
      emit(
        _assembleAfterMutation(
          next,
          priorDrafts: current.drafts,
          completedExerciseId: event.sessionExerciseId,
          undoable: null,
          restTimer: null,
        ),
      );
    } on DomainError catch (e) {
      final latest = state;
      if (latest is FocusModeReady) {
        emit(
          latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
        );
      }
    }
  }

  Future<void> _onExerciseMarkedDone(
    FocusModeExerciseMarkedDone event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    if (current.mutationInFlight) return;
    emit(current.copyWith(mutationInFlight: true, undoable: () => null));
    try {
      final next = await _engine.markExerciseDone(
        sessionExerciseId: event.sessionExerciseId,
      );
      _stopRestTicker();
      emit(
        _assembleAfterMutation(
          next,
          priorDrafts: current.drafts,
          completedExerciseId: event.sessionExerciseId,
          undoable: null,
          restTimer: null,
        ),
      );
    } on DomainError catch (e) {
      final latest = state;
      if (latest is FocusModeReady) {
        emit(
          latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
        );
      }
    }
  }

  Future<void> _onExerciseReplaced(
    FocusModeExerciseReplaced event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    if (current.mutationInFlight) return;
    emit(current.copyWith(mutationInFlight: true, undoable: () => null));
    try {
      final next = await _engine.replaceExercise(
        sessionExerciseId: event.sessionExerciseId,
        substituteName: event.substituteName,
        substituteMeasurementType: event.substituteMeasurementType,
        substitutePlannedValues: event.substitutePlannedValues,
        substituteSetCount: event.substituteSetCount,
        substituteMetadata: event.substituteMetadata,
        substituteLibraryExerciseId: event.substituteLibraryExerciseId,
      );
      _stopRestTicker();
      // Drop the prior draft for the replaced exercise — its measurement
      // type may have flipped, so the seed needs to come from the engine
      // suggestion.
      final priorDrafts = Map<String, ActualSetValues>.of(current.drafts)
        ..remove(event.sessionExerciseId);
      emit(
        _assembleAfterMutation(
          next,
          priorDrafts: priorDrafts,
          completedExerciseId: event.sessionExerciseId,
          undoable: null,
          restTimer: null,
        ),
      );
    } on DomainError catch (e) {
      final latest = state;
      if (latest is FocusModeReady) {
        emit(
          latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
        );
      }
    }
  }

  // ---------------- Rest timer ----------------

  Future<void> _onRestTicked(
    FocusModeRestTicked event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final timer = current.restTimer;
    if (timer == null || timer.isPaused) return;
    emit(
      current.copyWith(
        restTimer: () => RestTimerViewModel(
          plannedSeconds: timer.plannedSeconds,
          elapsedSeconds: timer.elapsedSeconds + 1,
          extensionSeconds: timer.extensionSeconds,
          isPaused: false,
        ),
      ),
    );
  }

  Future<void> _onRestPaused(
    FocusModeRestPaused event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final timer = current.restTimer;
    if (timer == null || timer.isPaused) return;
    _stopRestTicker();
    emit(
      current.copyWith(
        restTimer: () => RestTimerViewModel(
          plannedSeconds: timer.plannedSeconds,
          elapsedSeconds: timer.elapsedSeconds,
          extensionSeconds: timer.extensionSeconds,
          isPaused: true,
        ),
      ),
    );
  }

  Future<void> _onRestResumed(
    FocusModeRestResumed event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final timer = current.restTimer;
    if (timer == null || !timer.isPaused) return;
    _startRestTicker();
    emit(
      current.copyWith(
        restTimer: () => RestTimerViewModel(
          plannedSeconds: timer.plannedSeconds,
          elapsedSeconds: timer.elapsedSeconds,
          extensionSeconds: timer.extensionSeconds,
          isPaused: false,
        ),
      ),
    );
  }

  Future<void> _onRestExtended(
    FocusModeRestExtended event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final timer = current.restTimer;
    if (timer == null) return;
    emit(
      current.copyWith(
        restTimer: () => RestTimerViewModel(
          plannedSeconds: timer.plannedSeconds ?? timer.elapsedSeconds,
          elapsedSeconds: timer.elapsedSeconds,
          extensionSeconds: timer.extensionSeconds + event.deltaSeconds,
          isPaused: timer.isPaused,
        ),
      ),
    );
  }

  Future<void> _onRestSkipped(
    FocusModeRestSkipped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    if (current.restTimer == null) return;
    _stopRestTicker();
    emit(current.copyWith(restTimer: () => null));
  }

  // ---------------- Helpers ----------------

  FocusModeState _assembleFromSessionState(
    SessionState sessionState, {
    required String anchor,
    required Map<String, ActualSetValues> priorDrafts,
    String? userPinnedPanelId,
  }) {
    if (sessionState.isComplete) {
      return FocusModeWorkoutComplete(sessionState: sessionState);
    }
    final group = FocusModeAssembler.assemble(
      sessionState,
      anchorSessionExerciseId: anchor,
      userPinnedPanelId: userPinnedPanelId,
    );
    if (group == null) {
      final fallback = FocusModeAssembler.findNextAnchorAfter(
        sessionState,
        completedAnchorId: anchor,
      );
      if (fallback == null) {
        return FocusModeWorkoutComplete(sessionState: sessionState);
      }
      return _assembleFromSessionState(
        sessionState,
        anchor: fallback,
        priorDrafts: priorDrafts,
      );
    }
    final drafts = _seedDrafts(
      sessionState,
      group: group,
      priorDrafts: priorDrafts,
    );
    return FocusModeReady(
      sessionState: sessionState,
      anchorSessionExerciseId: anchor,
      groupViewModel: group,
      drafts: drafts,
      stopwatch: StopwatchViewModel.idle(),
      userPinnedPanelId: group.activeIsUserPinned ? userPinnedPanelId : null,
    );
  }

  FocusModeState _reassembleAfterRefresh(SessionState sessionState) {
    final current = state;
    final anchor = _currentAnchorOrNull() ?? _pendingAnchorId;
    if (anchor == null) {
      return FocusModeWorkoutComplete(sessionState: sessionState);
    }
    if (current is FocusModeReady) {
      // Preserve drafts on a passive refresh. The group view model may
      // shift (e.g. another panel finished elsewhere); the assembler picks
      // the same anchor's group.
      final group = FocusModeAssembler.assemble(
        sessionState,
        anchorSessionExerciseId: anchor,
        userPinnedPanelId: current.userPinnedPanelId,
      );
      if (group == null) {
        // Anchor's group disappeared (everything skipped).
        return _assembleFromSessionState(
          sessionState,
          anchor: anchor,
          priorDrafts: current.drafts,
        );
      }
      final drafts = _seedDrafts(
        sessionState,
        group: group,
        priorDrafts: current.drafts,
      );
      // If the pin no longer resolves to a loggable panel, drop it.
      final effectivePin = group.activeIsUserPinned
          ? current.userPinnedPanelId
          : null;
      return current.copyWith(
        sessionState: sessionState,
        groupViewModel: group,
        drafts: drafts,
        userPinnedPanelId: () => effectivePin,
      );
    }
    return _assembleFromSessionState(
      sessionState,
      anchor: anchor,
      priorDrafts: const {},
    );
  }

  /// Builds the new state after a mutation targeted at [completedExerciseId].
  ///
  /// If the current anchor's group is fully terminal after the mutation, the
  /// bloc auto-advances to the next group with open targets; if none remain,
  /// it transitions to [FocusModeWorkoutComplete].
  FocusModeState _assembleAfterMutation(
    SessionState sessionState, {
    required Map<String, ActualSetValues> priorDrafts,
    required String completedExerciseId,
    required UndoableSet? undoable,
    required RestTimerViewModel? restTimer,
  }) {
    if (sessionState.isComplete) {
      return FocusModeWorkoutComplete(sessionState: sessionState);
    }
    final anchor = _currentAnchorOrNull() ?? completedExerciseId;
    // Clear the pin if the mutation targeted the pinned panel — the user
    // logged on it, so auto-rotation resumes.
    final priorPin = switch (state) {
      FocusModeReady(:final userPinnedPanelId) => userPinnedPanelId,
      _ => null,
    };
    final carriedPin = priorPin == completedExerciseId ? null : priorPin;
    final group = FocusModeAssembler.assemble(
      sessionState,
      anchorSessionExerciseId: anchor,
      userPinnedPanelId: carriedPin,
    );
    final hasLoggableInGroup = group?.panels.any((p) => p.isLoggable) ?? false;

    String? effectiveAnchor = anchor;
    FocusModeGroupViewModel? effectiveGroup = group;
    String? effectivePin = carriedPin;
    if (group == null || !hasLoggableInGroup) {
      final next = FocusModeAssembler.findNextAnchorAfter(
        sessionState,
        completedAnchorId: anchor,
      );
      if (next == null) {
        return FocusModeWorkoutComplete(sessionState: sessionState);
      }
      effectiveAnchor = next;
      effectivePin = null;
      effectiveGroup = FocusModeAssembler.assemble(
        sessionState,
        anchorSessionExerciseId: next,
      );
    }
    if (effectiveGroup == null) {
      return FocusModeWorkoutComplete(sessionState: sessionState);
    }
    // If the pin no longer resolves to a loggable panel in the resolved
    // group, drop it.
    if (effectivePin != null && !effectiveGroup.activeIsUserPinned) {
      effectivePin = null;
    }

    // Drop the just-completed exercise's draft from `priorDrafts` so that
    // it re-seeds from the engine suggestion (last set's actuals).
    final cleared = Map<String, ActualSetValues>.of(priorDrafts)
      ..remove(completedExerciseId);
    final drafts = _seedDrafts(
      sessionState,
      group: effectiveGroup,
      priorDrafts: cleared,
    );
    return FocusModeReady(
      sessionState: sessionState,
      anchorSessionExerciseId: effectiveAnchor,
      groupViewModel: effectiveGroup,
      drafts: drafts,
      stopwatch: StopwatchViewModel.idle(),
      restTimer: restTimer,
      undoable: undoable,
      userPinnedPanelId: effectivePin,
    );
  }

  Map<String, ActualSetValues> _seedDrafts(
    SessionState sessionState, {
    required FocusModeGroupViewModel group,
    required Map<String, ActualSetValues> priorDrafts,
  }) {
    final next = <String, ActualSetValues>{};
    for (final panel in group.panels) {
      if (!panel.isLoggable) continue;
      final prior = priorDrafts[panel.sessionExerciseId];
      if (prior != null && _matches(prior, panel.effectiveMeasurementType)) {
        next[panel.sessionExerciseId] = prior;
        continue;
      }
      next[panel.sessionExerciseId] = _seedFromEngine(
        sessionState,
        panel: panel,
      );
    }
    return next;
  }

  ActualSetValues _seedFromEngine(
    SessionState sessionState, {
    required FocusModeViewModel panel,
  }) {
    try {
      final suggested = _engine.suggestValuesFor(
        session: sessionState.session,
        sessionExerciseId: panel.sessionExerciseId,
      );
      if (_matches(suggested, panel.effectiveMeasurementType)) {
        return suggested;
      }
    } on NotFoundError {
      // fall through to zero seed
    }
    return switch (panel.effectiveMeasurementType) {
      RepBasedMeasurement() => const ActualSetValues.repBased(
        weightKg: 0,
        reps: 0,
      ),
      TimeBasedMeasurement() => const ActualSetValues.timeBased(
        durationSeconds: 0,
      ),
      BodyweightMeasurement() => const ActualSetValues.bodyweight(reps: 0),
    };
  }

  bool _matches(ActualSetValues values, MeasurementType measurementType) {
    return switch ((measurementType, values)) {
      (RepBasedMeasurement(), ActualRepBased()) => true,
      (TimeBasedMeasurement(), ActualTimeBased()) => true,
      (BodyweightMeasurement(), ActualBodyweight()) => true,
      _ => false,
    };
  }

  RestTimerViewModel? _restTimerFromPanel(FocusModeViewModel panel) {
    return RestTimerViewModel(
      plannedSeconds: panel.plannedRestSeconds,
      elapsedSeconds: 0,
      extensionSeconds: 0,
      isPaused: false,
    );
  }

  FocusModeViewModel? _findPanel(
    FocusModeReady ready,
    String sessionExerciseId,
  ) {
    for (final panel in ready.groupViewModel.panels) {
      if (panel.sessionExerciseId == sessionExerciseId) return panel;
    }
    return null;
  }

  Map<String, ActualSetValues> _replaceDraft(
    Map<String, ActualSetValues> drafts,
    String sessionExerciseId,
    ActualSetValues next,
  ) {
    return Map<String, ActualSetValues>.of(drafts)..[sessionExerciseId] = next;
  }

  String? _newestExecutedSetId({
    required SessionState sessionState,
    required String sessionExerciseId,
  }) {
    final exercise = sessionState.session.sessionExercises
        .where((e) => e.id == sessionExerciseId)
        .firstOrNull;
    if (exercise == null || exercise.executedSets.isEmpty) return null;
    final sorted = List<ExecutedSet>.of(exercise.executedSets)
      ..sort((a, b) => a.position.compareTo(b.position));
    return sorted.last.id;
  }

  void _startRestTicker() {
    _restTicker?.cancel();
    _restTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const FocusModeRestTicked()),
    );
  }

  void _stopRestTicker() {
    _restTicker?.cancel();
    _restTicker = null;
  }

  void _startStopwatchTicker() {
    _stopwatchTicker?.cancel();
    _stopwatchTicker = Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const FocusModeStopwatchTicked()),
    );
  }

  void _stopStopwatchTicker() {
    _stopwatchTicker?.cancel();
    _stopwatchTicker = null;
  }

  String? _sessionIdOrNull() => switch (state) {
    FocusModeReady(:final sessionState) => sessionState.session.id,
    FocusModeWorkoutComplete(:final sessionState) => sessionState.session.id,
    FocusModeLoading(:final sessionId) => sessionId,
    FocusModeNotFound(:final sessionId) => sessionId,
    FocusModeLoadFailure(:final sessionId) => sessionId,
    FocusModeInitial() => _watchedSessionId,
  };

  String? _currentAnchorOrNull() => switch (state) {
    FocusModeReady(:final anchorSessionExerciseId) => anchorSessionExerciseId,
    _ => null,
  };
}
