import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/workout_day_picker_event.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/workout_day_picker_state.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_view_model.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';
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
  }

  final ProgramRepository _programRepository;
  final SessionRepository _sessionRepository;
  final SessionFlowEngine _sessionFlowEngine;
  final Clock _clock;
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
    try {
      program = await _programRepository.getProgram(programId);
      if (program == null) {
        emit(WorkoutDayPickerProgramNotFound(programId));
        return;
      }
      workoutDays = await _programRepository.listWorkoutDaysForProgram(
        programId,
      );
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
    final window = CurrentWeekWindow.compute(now);

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
      ),
    );
  }

  Future<DayTileStatus> _loadTileStatus({
    required String workoutDayId,
    required CurrentWeekWindow window,
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
