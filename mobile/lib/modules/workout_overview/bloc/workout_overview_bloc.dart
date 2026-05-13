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
    on<WorkoutOverviewRefreshed>(_onRefreshed);
    on<WorkoutOverviewErrorDismissed>(_onErrorDismissed);
    on<WorkoutOverviewExpansionToggled>(_onExpansionToggled);
    on<WorkoutOverviewSetLogged>(_onSetLogged);
    on<WorkoutOverviewSetEdited>(_onSetEdited);
    on<WorkoutOverviewExerciseSkipped>(_onExerciseSkipped);
    on<WorkoutOverviewExerciseReplaced>(_onExerciseReplaced);
    on<WorkoutOverviewDropResolved>(_onDropResolved);
    on<WorkoutOverviewSupersetUngrouped>(_onSupersetUngrouped);
    on<WorkoutOverviewSessionNoteAdded>(_onSessionNoteAdded);
    on<WorkoutOverviewExtraWorkAdded>(_onExtraWorkAdded);
    on<WorkoutOverviewSessionEnded>(_onSessionEnded);
  }

  final SessionFlowEngine _engine;

  Future<void> _onOpened(
    WorkoutOverviewOpened event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    emit(WorkoutOverviewLoading(event.sessionId));
    try {
      final sessionState = await _engine.resumeSession(
        sessionId: event.sessionId,
      );
      emit(_assemble(sessionState, _initialExpansionFor(sessionState)));
    } on NotFoundError {
      emit(WorkoutOverviewNotFound(event.sessionId));
    } on DomainError catch (e) {
      emit(WorkoutOverviewLoadFailure(sessionId: event.sessionId, error: e));
    }
  }

  Future<void> _onRetried(
    WorkoutOverviewRetried event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final sessionId = _sessionIdOrNull();
    if (sessionId == null) return;
    add(WorkoutOverviewOpened(sessionId));
  }

  Future<void> _onRefreshed(
    WorkoutOverviewRefreshed event,
    Emitter<WorkoutOverviewState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    try {
      final sessionState = await _engine.resumeSession(
        sessionId: current.sessionState.session.id,
      );
      emit(
        _assemble(
          sessionState,
          current.expandedExerciseIds,
          mutationInFlight: current.mutationInFlight,
        ),
      );
    } on DomainError catch (e) {
      emit(current.copyWith(lastTransientError: () => e));
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

  Future<void> _onExerciseReplaced(
    WorkoutOverviewExerciseReplaced event,
    Emitter<WorkoutOverviewState> emit,
  ) => _runMutation(
    emit,
    () => _engine.replaceExercise(
      sessionExerciseId: event.sessionExerciseId,
      substituteName: event.substituteName,
      substituteMeasurementType: event.substituteMeasurementType,
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

  /// Runs an engine mutation, surfaces success by replacing the assembled
  /// state and clearing any prior transient error, and surfaces failure by
  /// keeping the prior state and attaching the error.
  ///
  /// Refuses to start while another mutation is already in-flight; this
  /// prevents the UI from sending two competing reorders or two completes
  /// for the same set.
  Future<void> _runMutation(
    Emitter<WorkoutOverviewState> emit,
    Future<SessionState> Function() action,
  ) async {
    final current = state;
    if (current is! WorkoutOverviewLoaded) return;
    if (current.mutationInFlight) return;

    emit(current.copyWith(mutationInFlight: true));
    try {
      final next = await action();
      final latest = state;
      if (latest is! WorkoutOverviewLoaded) return;
      emit(
        _assemble(next, _expansionWithCursor(latest.expandedExerciseIds, next)),
      );
    } on DomainError catch (e) {
      final latest = state;
      if (latest is! WorkoutOverviewLoaded) return;
      emit(
        latest.copyWith(mutationInFlight: false, lastTransientError: () => e),
      );
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

  Set<String> _initialExpansionFor(SessionState sessionState) {
    final cursor = sessionState.cursor;
    if (cursor is ActiveCursor) return {cursor.sessionExerciseId};
    return <String>{};
  }

  /// Keeps user-driven expansions and additionally ensures the new cursor
  /// target is open after a mutation. Skipped/replaced/completed exercises
  /// keep their explicit expansion state — the user decides when to fold
  /// them away.
  Set<String> _expansionWithCursor(
    Set<String> current,
    SessionState sessionState,
  ) {
    final cursor = sessionState.cursor;
    if (cursor is! ActiveCursor) return current;
    if (current.contains(cursor.sessionExerciseId)) return current;
    return {...current, cursor.sessionExerciseId};
  }

  String? _sessionIdOrNull() => switch (state) {
    WorkoutOverviewLoaded(:final sessionState) => sessionState.session.id,
    WorkoutOverviewLoading(:final sessionId) => sessionId,
    WorkoutOverviewNotFound(:final sessionId) => sessionId,
    WorkoutOverviewLoadFailure(:final sessionId) => sessionId,
    WorkoutOverviewInitial() => null,
  };
}
