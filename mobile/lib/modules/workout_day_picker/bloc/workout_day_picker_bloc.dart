import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/workout_day_picker_event.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/workout_day_picker_state.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_view_model.dart';
import 'package:zamaj/modules/workout_day_picker/services/session_history_summarizer.dart';

class WorkoutDayPickerBloc
    extends Bloc<WorkoutDayPickerEvent, WorkoutDayPickerState> {
  WorkoutDayPickerBloc({
    required ProgramRepository programRepository,
    required SessionRepository sessionRepository,
    required SessionFlowEngine sessionFlowEngine,
    required Clock clock,
    required String initialProgramName,
  }) : _programRepository = programRepository,
       _sessionRepository = sessionRepository,
       _sessionFlowEngine = sessionFlowEngine,
       _clock = clock,
       super(WorkoutDayPickerInitial(initialProgramName)) {
    on<WorkoutDayPickerOpened>(_onOpened);
    on<WorkoutDayPickerScreenRetryRequested>(_onScreenRetryRequested);
    on<WorkoutDayPickerTileRetryRequested>(_onTileRetryRequested);
    on<WorkoutDayPickerRefreshRequested>(_onRefreshRequested);
    on<WorkoutDayPickerReturnedFromSession>(_onReturnedFromSession);
    on<WorkoutDayPickerStartPressed>(_onStartPressed);
    on<WorkoutDayPickerResumePressed>(_onResumePressed);
    on<WorkoutDayPickerErrorDismissed>(_onErrorDismissed);
    // TEMP: snapshot link repair — remove after one-time run.
    on<WorkoutDayPickerRepairPreviewRequested>(_onRepairPreviewRequested);
    on<WorkoutDayPickerRepairConfirmed>(_onRepairConfirmed);
    on<WorkoutDayPickerRepairDismissed>(_onRepairDismissed);
  }

  final ProgramRepository _programRepository;
  final SessionRepository _sessionRepository;
  final SessionFlowEngine _sessionFlowEngine;
  final Clock _clock;

  // TEMP: snapshot link repair — remove after one-time run. The plan computed
  // by the last preview, held so apply can persist its rewrites without
  // recomputing.
  SnapshotLinkBackfillPlan? _pendingRepairPlan;
  final StreamController<String> _navigationIntents =
      StreamController<String>.broadcast();

  Stream<String> get navigationIntents => _navigationIntents.stream;

  @override
  Future<void> close() async {
    await _navigationIntents.close();
    return super.close();
  }

  Future<void> _onOpened(
    WorkoutDayPickerOpened event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    await _runFullLoad(
      programId: event.programId,
      programName: event.programName,
      emit: emit,
    );
  }

  Future<void> _onScreenRetryRequested(
    WorkoutDayPickerScreenRetryRequested event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final identity = _currentProgramIdentity();
    if (identity == null) return;
    await _runFullLoad(
      programId: identity.id,
      programName: identity.name,
      emit: emit,
    );
  }

  Future<void> _onRefreshRequested(
    WorkoutDayPickerRefreshRequested event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    await _runFullLoad(
      programId: current.program.id,
      programName: current.program.name,
      emit: emit,
    );
  }

  Future<void> _onReturnedFromSession(
    WorkoutDayPickerReturnedFromSession event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    await _runFullLoad(
      programId: current.program.id,
      programName: current.program.name,
      emit: emit,
    );
  }

  Future<void> _onTileRetryRequested(
    WorkoutDayPickerTileRetryRequested event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;

    final targetIndex = current.dayViewModels.indexWhere(
      (vm) => vm.workoutDay.id == event.workoutDayId,
    );
    if (targetIndex < 0) return;

    emit(
      current.copyWith(
        dayViewModels: _withTileStatus(
          current.dayViewModels,
          targetIndex,
          const DayTileStatus.loading(),
        ),
      ),
    );

    final reloaded = await _loadTileStatus(
      workoutDayId: event.workoutDayId,
      window: current.window,
    );

    final latest = state;
    if (latest is! WorkoutDayPickerLoaded) return;
    final stillThere = latest.dayViewModels.indexWhere(
      (vm) => vm.workoutDay.id == event.workoutDayId,
    );
    if (stillThere < 0) return;

    emit(
      latest.copyWith(
        dayViewModels: _withTileStatus(
          latest.dayViewModels,
          stillThere,
          reloaded,
        ),
      ),
    );
  }

  Future<void> _onStartPressed(
    WorkoutDayPickerStartPressed event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    if (current.launchInFlightWorkoutDayId != null) return;
    // A session is already in progress (this program or another). Only one
    // session may run at a time, so refuse to start a new one — the UI keeps
    // the START affordance disabled, this guards the race where state went
    // stale between render and tap.
    if (current.activeSession != null) return;

    emit(
      current.copyWith(
        launchInFlightWorkoutDayId: () => event.workoutDayId,
        lastTransientError: () => null,
      ),
    );

    try {
      final sessionState = await _sessionFlowEngine.startSession(
        workoutDayId: event.workoutDayId,
      );
      _navigationIntents.add(sessionState.session.id);
      final latest = state;
      if (latest is WorkoutDayPickerLoaded) {
        emit(latest.copyWith(launchInFlightWorkoutDayId: () => null));
      }
    } on DomainError catch (e) {
      final latest = state;
      if (latest is WorkoutDayPickerLoaded) {
        emit(
          latest.copyWith(
            launchInFlightWorkoutDayId: () => null,
            lastTransientError: () => e,
          ),
        );
      }
    }
  }

  Future<void> _onResumePressed(
    WorkoutDayPickerResumePressed event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    if (current.launchInFlightWorkoutDayId != null) return;

    emit(
      current.copyWith(
        launchInFlightWorkoutDayId: () => event.workoutDayId,
        lastTransientError: () => null,
      ),
    );

    try {
      final sessionState = await _sessionFlowEngine.resumeSession(
        sessionId: event.activeSessionId,
      );
      _navigationIntents.add(sessionState.session.id);
      final latest = state;
      if (latest is WorkoutDayPickerLoaded) {
        emit(latest.copyWith(launchInFlightWorkoutDayId: () => null));
      }
    } on NotFoundError {
      final latest = state;
      if (latest is! WorkoutDayPickerLoaded) return;

      final targetIndex = latest.dayViewModels.indexWhere(
        (vm) => vm.workoutDay.id == event.workoutDayId,
      );
      if (targetIndex < 0) {
        emit(latest.copyWith(launchInFlightWorkoutDayId: () => null));
        return;
      }

      emit(
        latest.copyWith(
          launchInFlightWorkoutDayId: () => null,
          dayViewModels: _withTileStatus(
            latest.dayViewModels,
            targetIndex,
            const DayTileStatus.loading(),
          ),
        ),
      );

      final reloaded = await _loadTileStatus(
        workoutDayId: event.workoutDayId,
        window: latest.window,
      );

      final afterReload = state;
      if (afterReload is! WorkoutDayPickerLoaded) return;
      final stillThere = afterReload.dayViewModels.indexWhere(
        (vm) => vm.workoutDay.id == event.workoutDayId,
      );
      if (stillThere < 0) return;

      emit(
        afterReload.copyWith(
          dayViewModels: _withTileStatus(
            afterReload.dayViewModels,
            stillThere,
            reloaded,
          ),
        ),
      );
    } on DomainError catch (e) {
      final latest = state;
      if (latest is WorkoutDayPickerLoaded) {
        emit(
          latest.copyWith(
            launchInFlightWorkoutDayId: () => null,
            lastTransientError: () => e,
          ),
        );
      }
    }
  }

  Future<void> _onErrorDismissed(
    WorkoutDayPickerErrorDismissed event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    if (current.lastTransientError == null) return;
    emit(current.copyWith(lastTransientError: () => null));
  }

  // TEMP: snapshot link repair — remove after one-time run.
  //
  // Computes the repair plan for the open program — its ended sessions
  // (`listCompletedSessions` already excludes in-flight ones) filtered to this
  // program by their snapshot's `programId`, matched against the current
  // templates — and exposes the counts without writing anything. The plan is
  // cached for a subsequent apply.
  Future<void> _onRepairPreviewRequested(
    WorkoutDayPickerRepairPreviewRequested event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    final programId = current.program.id;

    final List<WorkoutDay> currentDays;
    final List<Session> programSessions;
    try {
      currentDays = await _programRepository.listWorkoutDaysForProgram(
        programId,
      );
      final completed = await _sessionRepository.listCompletedSessions();
      programSessions = [
        for (final session in completed)
          if (session.snapshot.workoutDay.programId == programId) session,
      ];
    } on DomainError catch (e) {
      emit(current.copyWith(lastTransientError: () => e));
      return;
    }

    final plan = SnapshotLinkBackfill.plan(
      currentDays: currentDays,
      sessions: programSessions,
    );
    _pendingRepairPlan = plan;

    emit(
      current.copyWith(
        repairPreview: () => WorkoutDayPickerRepairPreview(
          sessionsScanned: plan.sessionsScanned,
          sessionsToChange: plan.sessionsChanged,
          exercisesToReLink: plan.exercisesReLinked,
          unmatched: plan.unmatched,
          currentUnlinked: plan.currentUnlinked,
          daysMissing: plan.dayMissing,
        ),
        // A fresh preview supersedes any prior result summary.
        repairResult: () => null,
      ),
    );
  }

  // TEMP: snapshot link repair — remove after one-time run.
  //
  // Persists each cached rewrite via [SessionRepository.overwriteSnapshotWorkoutDay]
  // and surfaces a result summary. Day-missing sessions never appear in the
  // plan's rewrites (they are counted but not rewritten), so a deleted day is
  // skipped while siblings are repaired. No full reload is needed: rewriting a
  // snapshot's library links does not change the day-tile history summaries.
  Future<void> _onRepairConfirmed(
    WorkoutDayPickerRepairConfirmed event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    final plan = _pendingRepairPlan;
    if (plan == null) return;

    try {
      for (final rewrite in plan.rewrites) {
        await _sessionRepository.overwriteSnapshotWorkoutDay(
          sessionId: rewrite.sessionId,
          workoutDay: rewrite.workoutDay,
        );
      }
    } on DomainError catch (e) {
      emit(current.copyWith(lastTransientError: () => e));
      return;
    }

    _pendingRepairPlan = null;
    emit(
      current.copyWith(
        repairPreview: () => null,
        repairResult: () => WorkoutDayPickerRepairResult(
          sessionsChanged: plan.sessionsChanged,
          exercisesReLinked: plan.exercisesReLinked,
          unmatched: plan.unmatched,
          currentUnlinked: plan.currentUnlinked,
          daysMissing: plan.dayMissing,
        ),
      ),
    );
  }

  // TEMP: snapshot link repair — remove after one-time run.
  Future<void> _onRepairDismissed(
    WorkoutDayPickerRepairDismissed event,
    Emitter<WorkoutDayPickerState> emit,
  ) async {
    _pendingRepairPlan = null;
    final current = state;
    if (current is! WorkoutDayPickerLoaded) return;
    if (current.repairPreview == null && current.repairResult == null) return;
    emit(current.copyWith(repairPreview: () => null, repairResult: () => null));
  }

  Future<void> _runFullLoad({
    required String programId,
    required String programName,
    required Emitter<WorkoutDayPickerState> emit,
  }) async {
    emit(
      WorkoutDayPickerLoading(programId: programId, programName: programName),
    );

    final Program? program;
    final List<WorkoutDay> workoutDays;
    final Session? activeSession;
    try {
      program = await _programRepository.getProgram(programId);
      if (program == null) {
        emit(WorkoutDayPickerProgramNotFound(programId));
        return;
      }
      workoutDays = await _programRepository.listWorkoutDaysForProgram(
        programId,
      );
      activeSession = await _sessionRepository.getActiveSession();
    } on DomainError catch (e) {
      emit(
        WorkoutDayPickerScreenFailure(
          programId: programId,
          programName: programName,
          error: e,
        ),
      );
      return;
    }

    final now = _clock.now();
    final window = TrainingWeek.compute(now);

    final tileStatuses = await Future.wait(
      workoutDays.map(
        (day) => _loadTileStatus(workoutDayId: day.id, window: window),
      ),
    );

    final viewModels = <DayViewModel>[
      for (var i = 0; i < workoutDays.length; i++)
        DayViewModel(workoutDay: workoutDays[i], status: tileStatuses[i]),
    ];

    emit(
      WorkoutDayPickerLoaded(
        program: program,
        dayViewModels: viewModels,
        referenceNow: now,
        window: window,
        activeSession: activeSession,
      ),
    );
  }

  Future<DayTileStatus> _loadTileStatus({
    required String workoutDayId,
    required TrainingWeek window,
  }) async {
    try {
      final sessions = await _sessionRepository.listSessionsForWorkoutDay(
        workoutDayId,
      );
      final DayHistorySummary summary = SessionHistorySummarizer.summarize(
        sessions,
        window,
      );
      return DayTileStatus.loaded(summary);
    } on DomainError catch (e) {
      return DayTileStatus.failure(e);
    }
  }

  ({String id, String name})? _currentProgramIdentity() {
    final current = state;
    return switch (current) {
      WorkoutDayPickerLoaded(:final program) => (
        id: program.id,
        name: program.name,
      ),
      WorkoutDayPickerLoading(:final programId, :final programName) => (
        id: programId,
        name: programName,
      ),
      WorkoutDayPickerScreenFailure(:final programId, :final programName) => (
        id: programId,
        name: programName,
      ),
      WorkoutDayPickerProgramNotFound() => null,
      WorkoutDayPickerInitial() => null,
    };
  }

  List<DayViewModel> _withTileStatus(
    List<DayViewModel> source,
    int index,
    DayTileStatus status,
  ) {
    return [
      for (var i = 0; i < source.length; i++)
        if (i == index) source[i].copyWith(status: status) else source[i],
    ];
  }
}
