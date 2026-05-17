import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/workout_overview_event.dart';
import 'package:zamaj/modules/workout_overview/bloc/workout_overview_state.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/drop_resolver.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

class WorkoutOverviewBloc
    extends Bloc<WorkoutOverviewEvent, WorkoutOverviewState> {
  WorkoutOverviewBloc({required SessionFlowEngine sessionFlowEngine})
    : _engine = sessionFlowEngine,
      super(const WorkoutOverviewInitial()) {
    on<WorkoutOverviewOpened>(_onOpened);
    on<WorkoutOverviewRetried>(_onRetried);
    on<WorkoutOverviewErrorDismissed>(_onErrorDismissed);
    on<WorkoutOverviewExpansionToggled>(_onExpansionToggled);
    on<WorkoutOverviewSetLogged>(_onSetLogged);
    on<WorkoutOverviewSetEdited>(_onSetEdited);
    on<WorkoutOverviewExerciseSkipped>(_onExerciseSkipped);
    on<WorkoutOverviewExerciseMarkedDone>(_onExerciseMarkedDone);
    on<WorkoutOverviewExerciseReplaced>(_onExerciseReplaced);
    on<WorkoutOverviewDropResolved>(_onDropResolved);
    on<WorkoutOverviewSupersetUngrouped>(_onSupersetUngrouped);
    on<WorkoutOverviewSessionNoteAdded>(_onSessionNoteAdded);
    on<WorkoutOverviewExtraWorkAdded>(_onExtraWorkAdded);
    on<WorkoutOverviewSessionEnded>(_onSessionEnded);
    on<InternalSessionPushed>(_onSessionPushed);
    on<InternalSessionMissing>(_onSessionMissing);
    on<InternalSessionFailed>(_onSessionFailed);
  }

  final SessionFlowEngine _engine;
  StreamSubscription<SessionState?>? _streamSub;
  String? _watchedSessionId;

  @override
  Future<void> close() async {
    await _streamSub?.cancel();
    return super.close();
  }

  // ---------- Stream subscription lifecycle ----------

  Future<void> _onOpened(
    WorkoutOverviewOpened event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    emit(WorkoutOverviewLoading(event.sessionId));
    await _subscribe(event.sessionId);
  }

  Future<void> _onRetried(
    WorkoutOverviewRetried event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final sessionId = _sessionIdOrNull();
    if (sessionId == null) return;
    add(WorkoutOverviewOpened(sessionId));
  }

  Future<void> _subscribe(String sessionId) async {
    await _streamSub?.cancel();
    _watchedSessionId = sessionId;
    _streamSub = _engine
        .watchSession(sessionId: sessionId)
        .listen(
          (sessionState) {
            if (sessionState == null) {
              add(InternalSessionMissing(sessionId));
            } else {
              add(InternalSessionPushed(sessionState));
            }
          },
          onError: (Object error) {
            if (error is DomainError) {
              add(InternalSessionFailed(error, sessionId));
            }
          },
        );
  }

  // ---------- Internal stream-driven handlers ----------

  Future<void> _onSessionPushed(
    InternalSessionPushed event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    final next = event.sessionState;
    if (current is WorkoutOverviewLoaded) {
      emit(
        current.copyWith(
          sessionState: next,
          groups: ExerciseViewModelAssembler.assemble(next),
          expandedExerciseIds: _expansionForOpenTargets(
            current.expandedExerciseIds,
            next,
          ),
        ),
      );
    } else {
      emit(_assemble(next, _initialExpansionFor(next)));
    }
  }

  Future<void> _onSessionMissing(
    InternalSessionMissing event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    emit(WorkoutOverviewNotFound(event.sessionId));
  }

  Future<void> _onSessionFailed(
    InternalSessionFailed event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is WorkoutOverviewLoaded) {
      emit(current.copyWith(lastTransientError: () => event.error));
    } else {
      emit(
        WorkoutOverviewLoadFailure(
          sessionId: event.sessionId,
          error: event.error,
        ),
      );
    }
  }

  Future<void> _onErrorDismissed(
    WorkoutOverviewErrorDismissed event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    if (current.lastTransientError == null) return;
    emit(current.copyWith(lastTransientError: () => null));
  }

  Future<void> _onExpansionToggled(
    WorkoutOverviewExpansionToggled event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    final next = Set<String>.of(current.expandedExerciseIds);
    if (!next.remove(event.sessionExerciseId)) {
      next.add(event.sessionExerciseId);
    }
    emit(current.copyWith(expandedExerciseIds: next));
  }

  Future<void> _onSetLogged(
    WorkoutOverviewSetLogged event,
    Emitter<WorkoutOverviewState> emit,
  ) => _runMutation(
    emit,
    () => _engine.completeSet(
      sessionExerciseId: event.sessionExerciseId,
      actualValues: event.actualValues,
      plannedSetIdInSnapshot: event.plannedSetIdInSnapshot,
    ),
    touchedSessionExerciseId: event.sessionExerciseId,
  );

  Future<void> _onSetEdited(
    WorkoutOverviewSetEdited event,
    Emitter<WorkoutOverviewState> emit,
  ) => _runMutation(
    emit,
    () => _engine.updateExecutedSet(
      executedSetId: event.executedSetId,
      actualValues: event.actualValues,
    ),
  );

  Future<void> _onExerciseSkipped(
    WorkoutOverviewExerciseSkipped event,
    Emitter<WorkoutOverviewState> emit,
  ) => _runMutation(
    emit,
    () => _engine.skipExercise(sessionExerciseId: event.sessionExerciseId),
  );

  Future<void> _onExerciseMarkedDone(
    WorkoutOverviewExerciseMarkedDone event,
    Emitter<WorkoutOverviewState> emit,
  ) => _runMutation(
    emit,
    () => _engine.markExerciseDone(sessionExerciseId: event.sessionExerciseId),
  );

  Future<void> _onExerciseReplaced(
    WorkoutOverviewExerciseReplaced event,
    Emitter<WorkoutOverviewState> emit,
  ) => _runMutation(
    emit,
    () => _engine.replaceExercise(
      sessionExerciseId: event.sessionExerciseId,
      substituteName: event.substituteName,
      substituteMeasurementType: event.substituteMeasurementType,
      substitutePlannedValues: event.substitutePlannedValues,
      substituteSetCount: event.substituteSetCount,
      substituteMetadata: event.substituteMetadata,
    ),
  );

  Future<void> _onDropResolved(
    WorkoutOverviewDropResolved event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    final intent = DropResolver.resolve(
      sessionId: current.sessionState.session.id,
      groups: current.groups,
      draggedSessionExerciseId: event.draggedSessionExerciseId,
      target: event.target,
    );
    switch (intent) {
      case NoopIntent():
        return;
      case ReorderIntent(:final sessionId, :final orderedUnfinishedIds):
        await _runMutation(
          emit,
          () => _engine.reorderUnfinished(
            sessionId: sessionId,
            orderedUnfinishedIds: orderedUnfinishedIds,
          ),
        );
      case CreateSupersetIntent(:final sessionId, :final sessionExerciseIds):
        await _runMutation(
          emit,
          () => _engine.createSuperset(
            sessionId: sessionId,
            sessionExerciseIds: sessionExerciseIds,
          ),
        );
    }
  }

  Future<void> _onSupersetUngrouped(
    WorkoutOverviewSupersetUngrouped event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    final ids = current.sessionState.session.sessionExercises
        .where((e) => e.supersetTag == event.supersetTag)
        .map((e) => e.id)
        .toList();
    if (ids.isEmpty) return;
    await _runMutation(
      emit,
      () => _engine.removeSuperset(
        sessionId: current.sessionState.session.id,
        sessionExerciseIds: ids,
      ),
    );
  }

  Future<void> _onSessionNoteAdded(
    WorkoutOverviewSessionNoteAdded event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    await _runMutation(
      emit,
      () => _engine.addSessionNote(
        sessionId: current.sessionState.session.id,
        body: event.body,
      ),
    );
  }

  Future<void> _onExtraWorkAdded(
    WorkoutOverviewExtraWorkAdded event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    await _runMutation(
      emit,
      () => _engine.addExtraWork(
        sessionId: current.sessionState.session.id,
        body: event.body,
      ),
    );
  }

  Future<void> _onSessionEnded(
    WorkoutOverviewSessionEnded event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    if (current.isEnded) return;
    await _runMutation(
      emit,
      () => _engine.endSession(sessionId: current.sessionState.session.id),
    );
  }

  /// Runs an engine mutation. On success, applies the returned session state
  /// directly and clears the in-flight flag — the watch-stream will push the
  /// same value moments later but bloc-level equality dedupes it. On failure,
  /// keeps the prior session state and attaches the error.
  ///
  /// [touchedSessionExerciseId], when provided, is recorded as the last-
  /// touched exercise so the UI can apply a subtle accent on its loggable
  /// row.
  Future<void> _runMutation(
    Emitter<WorkoutOverviewState> emit,
    Future<SessionState> Function() action, {
    String? touchedSessionExerciseId,
  }) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    if (current.mutationInFlight) return;

    emit(current.copyWith(mutationInFlight: true));
    try {
      final next = await action();
      final latest = state;
      if (latest is WorkoutOverviewLoaded) {
        emit(
          latest.copyWith(
            sessionState: next,
            groups: ExerciseViewModelAssembler.assemble(next),
            expandedExerciseIds: _expansionForOpenTargets(
              latest.expandedExerciseIds,
              next,
            ),
            mutationInFlight: false,
            lastTouchedSessionExerciseId: touchedSessionExerciseId != null
                ? () => touchedSessionExerciseId
                : null,
          ),
        );
      }
    } on DomainError catch (e) {
      final latest = state;
      if (latest is WorkoutOverviewLoaded) {
        emit(
          latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
        );
      }
    }
  }

  WorkoutOverviewLoaded _assemble(
    SessionState sessionState,
    Set<String> expansion, {
    bool mutationInFlight = false,
  }) {
    final groups = ExerciseViewModelAssembler.assemble(sessionState);
    return WorkoutOverviewLoaded(
      sessionState: sessionState,
      groups: groups,
      expandedExerciseIds: expansion,
      mutationInFlight: mutationInFlight,
    );
  }

  /// Initial expansion: every currently-loggable exercise is auto-expanded
  /// so the user sees the next-set editor for each in-progress exercise
  /// (including all members of a superset) the moment the screen opens.
  Set<String> _initialExpansionFor(SessionState sessionState) {
    return <String>{
      for (final t in sessionState.openTargets) t.sessionExerciseId,
    };
  }

  /// On each refresh: keep manually-expanded cards open as long as their
  /// exercise still exists, drop those that hit a terminal state with all
  /// sets done, and force-expand every loggable exercise so the user can
  /// always tap a loggable row without an extra expand step.
  Set<String> _expansionForOpenTargets(
    Set<String> current,
    SessionState sessionState,
  ) {
    final kept = <String>{
      for (final ex in sessionState.session.sessionExercises)
        if (current.contains(ex.id) &&
            switch (ex.state) {
              UnfinishedState() => true,
              ReplacedState(:final substitute) =>
                ex.executedSets.length < substitute.setCount,
              CompletedState() || SkippedState() => false,
            })
          ex.id,
    };
    for (final t in sessionState.openTargets) {
      kept.add(t.sessionExerciseId);
    }
    return kept;
  }

  String? _sessionIdOrNull() => switch (state) {
    WorkoutOverviewLoaded(:final sessionState) => sessionState.session.id,
    WorkoutOverviewLoading(:final sessionId) => sessionId,
    WorkoutOverviewNotFound(:final sessionId) => sessionId,
    WorkoutOverviewLoadFailure(:final sessionId) => sessionId,
    WorkoutOverviewInitial() => _watchedSessionId,
  };
}
