import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/workout_overview_event.dart';
import 'package:zamaj/modules/workout_overview/bloc/workout_overview_state.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/drop_resolver.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';
import 'package:zamaj/modules/workout_overview/services/superset_reorder_resolver.dart';

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
    on<WorkoutOverviewDropResolved>(_onDropResolved);
    on<WorkoutOverviewSupersetReordered>(_onSupersetReordered);
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
    try {
      if (current is WorkoutOverviewLoaded) {
        emit(
          current.copyWith(
            sessionState: next,
            groups: ExerciseViewModelAssembler.assemble(next),
            expandedExerciseIds: _expansionForOpenTargets(
              current.expandedExerciseIds,
              current.sessionState,
              next,
            ),
          ),
        );
      } else {
        emit(_assemble(next, _initialExpansionFor(next)));
      }
    } on DomainError catch (e) {
      // A corrupt snapshot (a planned exercise missing from the immutable
      // snapshot) makes the synchronous assemble throw. The watch stream's
      // engine projection only resolves unfinished/replaced exercises, so a
      // terminal corrupt exercise slips through to here. Route it through the
      // existing failure path rather than letting it escape and crash.
      add(InternalSessionFailed(e, next.session.id));
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
      case AppendToSupersetIntent(
        :final sessionId,
        :final supersetTag,
        :final sessionExerciseId,
      ):
        await _runMutation(
          emit,
          () => _engine.addToSuperset(
            sessionId: sessionId,
            supersetTag: supersetTag,
            sessionExerciseId: sessionExerciseId,
          ),
        );
    }
  }

  Future<void> _onSupersetReordered(
    WorkoutOverviewSupersetReordered event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    final intent = SupersetReorderResolver.resolve(
      sessionId: current.sessionState.session.id,
      groups: current.groups,
      supersetTag: event.supersetTag,
      targetUnfinishedIndex: event.targetUnfinishedIndex,
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
      // The resolver only ever yields a reorder or a no-op; the other DropIntent
      // variants (create/append) are unreachable for a whole-superset move.
      case CreateSupersetIntent():
      case AppendToSupersetIntent():
        return;
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
              latest.sessionState,
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

  /// Initial expansion: open the active group so logging is one tap away. For
  /// a standalone first exercise that's just the lone open target; for a
  /// superset it's every loggable member, so the whole round opens at once.
  /// Everything else stays collapsed.
  Set<String> _initialExpansionFor(SessionState sessionState) =>
      _activeGroupLoggableIds(sessionState);

  /// On each refresh: keep the user's manual choice, but drive the active
  /// group's expansion automatically.
  ///
  /// - Cards the user opened stay open while their exercise is still loggable
  ///   (has a remaining planned set). A card whose planned sets are all logged,
  ///   or that hit a terminal state, drops out and collapses — so superset
  ///   members fold away one by one as the user finishes them.
  /// - When the active group (the group owning the first open target) changes —
  ///   because the prior one was finished, skipped, or marked done — every
  ///   loggable member of the new group auto-expands. For a superset that opens
  ///   the whole round; once all its members are finished the next group opens.
  Set<String> _expansionForOpenTargets(
    Set<String> current,
    SessionState previous,
    SessionState next,
  ) {
    final loggableIds = <String>{
      for (final t in next.openTargets) t.sessionExerciseId,
    };
    final retained = <String>{
      for (final id in current)
        if (loggableIds.contains(id)) id,
    };
    if (_activeGroupKey(next) != _activeGroupKey(previous)) {
      retained.addAll(_activeGroupLoggableIds(next));
    }
    return retained;
  }

  /// Identity of the "active group" — the group owning the first open target.
  /// A superset is keyed by its shared tag, a standalone exercise by its own
  /// id, so the key changes only when logging advances past the whole group,
  /// not when the first open target rotates between superset members. Null
  /// when nothing is loggable.
  String? _activeGroupKey(SessionState state) {
    if (state.openTargets.isEmpty) return null;
    final anchorId = state.openTargets.first.sessionExerciseId;
    final anchor = state.session.sessionExercises
        .where((e) => e.id == anchorId)
        .firstOrNull;
    return anchor?.supersetTag ?? anchorId;
  }

  /// Loggable members of the active group. For a standalone exercise that's the
  /// lone open target; for a superset it's every member of the same contiguous
  /// run that still has a remaining planned set, so the whole round expands
  /// together. Uses the shared [groupBySupersetRun] so the bloc, the overview
  /// assembler, and the focus assembler all agree on what "the group" is.
  Set<String> _activeGroupLoggableIds(SessionState state) {
    if (state.openTargets.isEmpty) return <String>{};
    final loggableIds = <String>{
      for (final t in state.openTargets) t.sessionExerciseId,
    };
    final anchorId = state.openTargets.first.sessionExerciseId;
    final group = groupBySupersetRun(state.session.sessionExercises).firstWhere(
      (run) => run.any((e) => e.id == anchorId),
      orElse: () => const <SessionExercise>[],
    );
    return <String>{
      for (final e in group)
        if (loggableIds.contains(e.id)) e.id,
    };
  }

  String? _sessionIdOrNull() => switch (state) {
    WorkoutOverviewLoaded(:final sessionState) => sessionState.session.id,
    WorkoutOverviewLoading(:final sessionId) => sessionId,
    WorkoutOverviewNotFound(:final sessionId) => sessionId,
    WorkoutOverviewLoadFailure(:final sessionId) => sessionId,
    WorkoutOverviewInitial() => _watchedSessionId,
  };
}
