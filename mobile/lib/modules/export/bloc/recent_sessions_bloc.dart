import 'package:clock/clock.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/recent_sessions_event.dart';
import 'package:zamaj/modules/export/bloc/recent_sessions_state.dart';
import 'package:zamaj/modules/export/services/session_history_assembler.dart';

class RecentSessionsBloc
    extends Bloc<RecentSessionsEvent, RecentSessionsState> {
  RecentSessionsBloc({
    required ProgramRepository programRepository,
    required SessionRepository sessionRepository,
    required Clock clock,
  }) : _programRepository = programRepository,
       _sessionRepository = sessionRepository,
       _clock = clock,
       super(const RecentSessionsInitial()) {
    on<RecentSessionsOpened>(_onOpened);
    on<RecentSessionsRetried>(_onRetried);
    on<RecentSessionsRefreshed>(_onRefreshed);
    on<RecentSessionsDeleteRequested>(_onDeleteRequested);
  }

  final ProgramRepository _programRepository;
  final SessionRepository _sessionRepository;
  final Clock _clock;

  Future<void> _onOpened(
    RecentSessionsOpened event,
    Emitter<RecentSessionsState> emit,
  ) async {
    await _load(programId: event.programId, emit: emit);
  }

  Future<void> _onRetried(
    RecentSessionsRetried event,
    Emitter<RecentSessionsState> emit,
  ) async {
    final programId = _currentProgramId();
    if (programId == null) return;
    await _load(programId: programId, emit: emit);
  }

  Future<void> _onRefreshed(
    RecentSessionsRefreshed event,
    Emitter<RecentSessionsState> emit,
  ) async {
    final current = state;
    if (current is! RecentSessionsLoaded) return;
    await _load(programId: current.programId, emit: emit);
  }

  Future<void> _onDeleteRequested(
    RecentSessionsDeleteRequested event,
    Emitter<RecentSessionsState> emit,
  ) async {
    final current = state;
    if (current is! RecentSessionsLoaded) return;

    // Optimistic in-place removal so the list doesn't flash a spinner;
    // the Dismissible animation has already hidden the tile.
    emit(
      RecentSessionsLoaded(
        programId: current.programId,
        programName: current.programName,
        items: [
          for (final i in current.items)
            if (i.sessionId != event.sessionId) i,
        ],
        sessionsById: {
          for (final entry in current.sessionsById.entries)
            if (entry.key != event.sessionId) entry.key: entry.value,
        },
        weekSessions: [
          for (final s in current.weekSessions)
            if (s.id != event.sessionId) s,
        ],
        window: current.window,
        referenceNow: current.referenceNow,
      ),
    );

    try {
      await _sessionRepository.deleteSession(event.sessionId);
    } on DomainError catch (e) {
      // Restore prior state and surface the failure.
      emit(current);
      emit(RecentSessionsFailure(programId: current.programId, error: e));
    }
  }

  Future<void> _load({
    required String programId,
    required Emitter<RecentSessionsState> emit,
  }) async {
    emit(RecentSessionsLoading(programId));

    final Program? program;
    final List<WorkoutDay> workoutDays;
    try {
      program = await _programRepository.getProgram(programId);
      if (program == null) {
        emit(RecentSessionsProgramNotFound(programId));
        return;
      }
      workoutDays = await _programRepository.listWorkoutDaysForProgram(
        programId,
      );
    } on DomainError catch (e) {
      emit(RecentSessionsFailure(programId: programId, error: e));
      return;
    }

    final List<Session> allSessions;
    try {
      final perDay = await Future.wait(
        workoutDays.map(
          (d) => _sessionRepository.listSessionsForWorkoutDay(d.id),
        ),
      );
      allSessions = [for (final list in perDay) ...list];
    } on DomainError catch (e) {
      emit(RecentSessionsFailure(programId: programId, error: e));
      return;
    }

    final now = _clock.now();
    final window = TrainingWeek.compute(now);
    final items = SessionHistoryAssembler.assemble(
      sessions: allSessions,
      window: window,
    );
    final completed = allSessions.where((s) => s.endedAt != null);
    final sessionsById = {for (final s in completed) s.id: s};
    final weekSessions =
        completed.where((s) => window.contains(s.endedAt!)).toList()
          ..sort((a, b) => a.endedAt!.compareTo(b.endedAt!));

    emit(
      RecentSessionsLoaded(
        programId: programId,
        programName: program.name,
        items: items,
        sessionsById: sessionsById,
        weekSessions: weekSessions,
        window: window,
        referenceNow: now,
      ),
    );
  }

  String? _currentProgramId() {
    return switch (state) {
      RecentSessionsLoaded(:final programId) => programId,
      RecentSessionsLoading(:final programId) => programId,
      RecentSessionsFailure(:final programId) => programId,
      RecentSessionsProgramNotFound(:final programId) => programId,
      RecentSessionsInitial() => null,
    };
  }
}
