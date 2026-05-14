import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/bloc/focus_mode_event.dart';
import 'package:zamaj/modules/focus_mode/bloc/focus_mode_state.dart';
import 'package:zamaj/modules/focus_mode/models/rest_timer_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/undoable_set.dart';
import 'package:zamaj/modules/focus_mode/services/focus_mode_assembler.dart';
import 'package:zamaj/modules/focus_mode/services/increment_rules.dart';

/// Owns the execution screen's runtime state.
///
/// Responsibilities:
///   - Hydrate from the engine on open / refresh
///   - Maintain a local editable [draft] of actual values for the current
///     set; reseed whenever the cursor advances
///   - Run the rest timer and per-set stopwatch as Timer.periodic streams
///     (an internal-only signal — tests can drive the same ticks by
///     adding `FocusModeRestTicked` / `FocusModeStopwatchTicked` directly)
///   - Dispatch engine mutations (completeSet / deleteExecutedSet / skip /
///     replace) and surface their results
class FocusModeBloc extends Bloc<FocusModeEvent, FocusModeState> {
  FocusModeBloc({required SessionFlowEngine sessionFlowEngine})
    : _engine = sessionFlowEngine,
      super(const FocusModeInitial()) {
    on<FocusModeOpened>(_onOpened);
    on<FocusModeRetried>(_onRetried);
    on<FocusModeRefreshed>(_onRefreshed);
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
    on<FocusModeUndoExpired>(_onUndoExpired);

    on<FocusModeExerciseSkipped>(_onExerciseSkipped);
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

  @override
  Future<void> close() {
    _restTicker?.cancel();
    _stopwatchTicker?.cancel();
    return super.close();
  }

  // ---------------- Lifecycle ----------------

  Future<void> _onOpened(
    FocusModeOpened event,
    Emitter<FocusModeState> emit,
  ) async {
    emit(FocusModeLoading(event.sessionId));
    try {
      final sessionState = await _engine.resumeSession(
        sessionId: event.sessionId,
      );
      emit(_assemble(sessionState));
    } on NotFoundError {
      emit(FocusModeNotFound(event.sessionId));
    } on DomainError catch (e) {
      emit(FocusModeLoadFailure(sessionId: event.sessionId, error: e));
    }
  }

  Future<void> _onRetried(
    FocusModeRetried event,
    Emitter<FocusModeState> emit,
  ) async {
    final sessionId = _sessionIdOrNull();
    if (sessionId == null) return;
    add(FocusModeOpened(sessionId));
  }

  Future<void> _onRefreshed(
    FocusModeRefreshed event,
    Emitter<FocusModeState> emit,
  ) async {
    final sessionId = _sessionIdOrNull();
    if (sessionId == null) return;
    try {
      final sessionState = await _engine.resumeSession(sessionId: sessionId);
      emit(_reassembleAfterRefresh(sessionState));
    } on DomainError catch (e) {
      final current = state;
      if (current is FocusModeReady) {
        emit(current.copyWith(lastTransientError: () => e));
      } else if (current is FocusModeWorkoutComplete) {
        emit(
          FocusModeWorkoutComplete(
            sessionState: current.sessionState,
            lastTransientError: e,
          ),
        );
      }
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
    final draft = current.draft;
    if (draft is! ActualRepBased) return;
    emit(
      current.copyWith(
        draft: ActualSetValues.repBased(
          weightKg: IncrementRules.bumpWeight(draft.weightKg, event.delta),
          reps: draft.reps,
        ),
      ),
    );
  }

  Future<void> _onRepsBumped(
    FocusModeRepsBumped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draft;
    if (draft is! ActualRepBased) return;
    emit(
      current.copyWith(
        draft: ActualSetValues.repBased(
          weightKg: draft.weightKg,
          reps: IncrementRules.bumpReps(draft.reps, event.delta),
        ),
      ),
    );
  }

  Future<void> _onDurationBumped(
    FocusModeDurationBumped event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draft;
    if (draft is! ActualTimeBased) return;
    emit(
      current.copyWith(
        draft: ActualSetValues.timeBased(
          durationSeconds: IncrementRules.bumpDuration(
            draft.durationSeconds,
            event.delta,
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
    final draft = current.draft;
    if (draft is! ActualRepBased) return;
    final rounded = (event.weightKg * 2).round() / 2;
    final clamped = rounded < 0 ? 0.0 : rounded;
    emit(
      current.copyWith(
        draft: ActualSetValues.repBased(weightKg: clamped, reps: draft.reps),
      ),
    );
  }

  Future<void> _onRepsEdited(
    FocusModeRepsEdited event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    final draft = current.draft;
    if (draft is! ActualRepBased) return;
    final clamped = event.reps < 0 ? 0 : event.reps;
    emit(
      current.copyWith(
        draft: ActualSetValues.repBased(
          weightKg: draft.weightKg,
          reps: clamped,
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
    final draft = current.draft;
    if (draft is! ActualTimeBased) return;
    final clamped = event.seconds < 0 ? 0 : event.seconds;
    emit(
      current.copyWith(
        draft: ActualSetValues.timeBased(durationSeconds: clamped),
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
    if (current.viewModel.effectiveMeasurementType is! TimeBasedMeasurement) {
      return;
    }
    _stopRestTicker();
    _startStopwatchTicker();
    emit(
      current.copyWith(
        stopwatch: const StopwatchViewModel(isRunning: true, elapsedSeconds: 0),
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
    final next = current.stopwatch.elapsedSeconds + 1;
    final draft = current.draft;
    final newDraft = draft is ActualTimeBased
        ? ActualSetValues.timeBased(durationSeconds: next)
        : draft;
    emit(
      current.copyWith(
        stopwatch: StopwatchViewModel(isRunning: true, elapsedSeconds: next),
        draft: newDraft,
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
    _stopStopwatchTicker();

    emit(current.copyWith(mutationInFlight: true));
    try {
      final next = await _engine.completeSet(
        sessionExerciseId: current.viewModel.sessionExerciseId,
        actualValues: current.draft,
        plannedSetIdInSnapshot: current.viewModel.currentPlannedSetIdInSnapshot,
      );
      final justLoggedSetId = _newestExecutedSetId(
        sessionState: next,
        sessionExerciseId: current.viewModel.sessionExerciseId,
      );
      final undoable = justLoggedSetId == null
          ? null
          : UndoableSet(
              executedSetId: justLoggedSetId,
              sessionExerciseId: current.viewModel.sessionExerciseId,
              exerciseDisplayName: current.viewModel.displayExerciseName,
            );
      emit(
        _assembleAfterMutation(
          next,
          undoable: undoable,
          restTimer: _restTimerForNewSet(next),
        ),
      );
      if (state is FocusModeReady &&
          (state as FocusModeReady).restTimer != null) {
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
      emit(_assembleAfterMutation(next, undoable: null, restTimer: null));
    } on DomainError catch (e) {
      final latest = state;
      if (latest is FocusModeReady) {
        emit(
          latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
        );
      }
    }
  }

  Future<void> _onUndoExpired(
    FocusModeUndoExpired event,
    Emitter<FocusModeState> emit,
  ) async {
    final current = state;
    if (current is! FocusModeReady) return;
    if (current.undoable?.executedSetId == event.executedSetId) {
      emit(current.copyWith(undoable: () => null));
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
        sessionExerciseId: current.viewModel.sessionExerciseId,
      );
      _stopRestTicker();
      emit(_assembleAfterMutation(next, undoable: null, restTimer: null));
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
        sessionExerciseId: current.viewModel.sessionExerciseId,
        substituteName: event.substituteName,
        substituteMeasurementType: event.substituteMeasurementType,
        substituteMetadata: event.substituteMetadata,
      );
      _stopRestTicker();
      emit(_assembleAfterMutation(next, undoable: null, restTimer: null));
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

  FocusModeState _assemble(SessionState sessionState) {
    final vm = FocusModeAssembler.assemble(sessionState);
    if (vm == null) {
      return FocusModeWorkoutComplete(sessionState: sessionState);
    }
    final draft = _seedDraft(sessionState, vm.effectiveMeasurementType);
    return FocusModeReady(
      sessionState: sessionState,
      viewModel: vm,
      draft: draft,
      stopwatch: StopwatchViewModel.idle(),
    );
  }

  FocusModeState _reassembleAfterRefresh(SessionState sessionState) {
    final current = state;
    final vm = FocusModeAssembler.assemble(sessionState);
    if (vm == null) {
      return FocusModeWorkoutComplete(sessionState: sessionState);
    }
    if (current is! FocusModeReady) {
      return _assemble(sessionState);
    }
    final cursorChanged =
        current.viewModel.sessionExerciseId != vm.sessionExerciseId ||
        current.viewModel.currentSetIndex != vm.currentSetIndex;
    final draft = cursorChanged
        ? _seedDraft(sessionState, vm.effectiveMeasurementType)
        : current.draft;
    return current.copyWith(
      sessionState: sessionState,
      viewModel: vm,
      draft: draft,
    );
  }

  /// Builds the new ready state after a mutation. If the cursor advanced,
  /// the draft is re-seeded; otherwise the prior draft is preserved.
  FocusModeState _assembleAfterMutation(
    SessionState sessionState, {
    required UndoableSet? undoable,
    required RestTimerViewModel? restTimer,
  }) {
    final vm = FocusModeAssembler.assemble(sessionState);
    if (vm == null) {
      return FocusModeWorkoutComplete(sessionState: sessionState);
    }
    final current = state;
    final priorDraft = current is FocusModeReady ? current.draft : null;
    final priorVm = current is FocusModeReady ? current.viewModel : null;
    final cursorChanged =
        priorVm == null ||
        priorVm.sessionExerciseId != vm.sessionExerciseId ||
        priorVm.currentSetIndex != vm.currentSetIndex;
    final draft = cursorChanged || priorDraft == null
        ? _seedDraft(sessionState, vm.effectiveMeasurementType)
        : priorDraft;
    return FocusModeReady(
      sessionState: sessionState,
      viewModel: vm,
      draft: draft,
      stopwatch: StopwatchViewModel.idle(),
      restTimer: restTimer,
      undoable: undoable,
    );
  }

  ActualSetValues _seedDraft(
    SessionState sessionState,
    MeasurementType measurementType,
  ) {
    final suggested = sessionState.suggestedValues;
    if (suggested != null) {
      final matches = switch ((measurementType, suggested)) {
        (RepBasedMeasurement(), ActualRepBased()) => true,
        (TimeBasedMeasurement(), ActualTimeBased()) => true,
        _ => false,
      };
      if (matches) return suggested;
    }
    return switch (measurementType) {
      RepBasedMeasurement() => const ActualSetValues.repBased(
        weightKg: 0,
        reps: 0,
      ),
      TimeBasedMeasurement() => const ActualSetValues.timeBased(
        durationSeconds: 0,
      ),
    };
  }

  RestTimerViewModel? _restTimerForNewSet(SessionState sessionState) {
    final vm = FocusModeAssembler.assemble(sessionState);
    final priorVm = state is FocusModeReady
        ? (state as FocusModeReady).viewModel
        : null;
    // If the cursor is completed (whole workout done) or hasn't advanced
    // (e.g. extra sets on a replaced exercise), still surface a rest timer
    // using the planned rest from the just-completed exercise.
    final planned = priorVm?.plannedRestSeconds ?? vm?.plannedRestSeconds;
    if (vm == null && planned == null) {
      return null;
    }
    return RestTimerViewModel(
      plannedSeconds: planned,
      elapsedSeconds: 0,
      extensionSeconds: 0,
      isPaused: false,
    );
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
    FocusModeInitial() => null,
  };
}
