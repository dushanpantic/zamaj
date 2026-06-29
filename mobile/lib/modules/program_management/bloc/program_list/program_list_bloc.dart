import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/program_name_rules.dart';

import 'program_list_event.dart';
import 'program_list_state.dart';

class ProgramListBloc extends Bloc<ProgramListEvent, ProgramListState> {
  ProgramListBloc({required ProgramRepository programRepository})
    : _programRepository = programRepository,
      super(const ProgramListInitial()) {
    on<ProgramListRequested>(_onRequested);
    on<ProgramCreateRequested>(_onCreateRequested);
    on<ProgramCreateNavigationHandled>(_onCreateNavigationHandled);
    on<ProgramListDeleteRequested>(_onDeleteRequested);
    on<ProgramListDeleteConfirmed>(_onDeleteConfirmed);
    on<ProgramListDeleteCancelled>(_onDeleteCancelled);
    on<ProgramListRetryRequested>(_onRetryRequested);
    on<ProgramListRefreshed>(_onRefreshed);
  }

  final ProgramRepository _programRepository;

  Future<void> _onRequested(
    ProgramListRequested event,
    Emitter<ProgramListState> emit,
  ) async {
    emit(const ProgramListLoading());
    await _loadPrograms(emit);
  }

  Future<void> _onCreateRequested(
    ProgramCreateRequested event,
    Emitter<ProgramListState> emit,
  ) async {
    final name = event.name.trim();
    // Defense-in-depth: the name-first dialog already blocks invalid names.
    if (!ProgramNameRules.canCreate(name)) return;

    try {
      final created = await _programRepository.createProgram(name: name);
      final programs = await _sortedPrograms();
      emit(
        ProgramListLoaded(
          programs: programs,
          lastCreatedProgramId: created.id,
        ),
      );
    } on DomainError catch (e) {
      // Surface as a non-fatal notice (the same channel as a failed delete).
      final current = state;
      if (current is ProgramListLoaded) {
        emit(current.copyWith(lastDeleteError: () => e));
      } else {
        emit(ProgramListFailure(error: e));
      }
    }
  }

  Future<void> _onCreateNavigationHandled(
    ProgramCreateNavigationHandled event,
    Emitter<ProgramListState> emit,
  ) async {
    final current = state;
    if (current is! ProgramListLoaded) return;
    if (current.lastCreatedProgramId == null) return;
    emit(current.copyWith(lastCreatedProgramId: () => null));
  }

  Future<void> _onDeleteRequested(
    ProgramListDeleteRequested event,
    Emitter<ProgramListState> emit,
  ) async {
    final current = state;
    if (current is! ProgramListLoaded) return;
    emit(current.copyWith(deletionCandidateId: () => event.programId));
  }

  Future<void> _onDeleteConfirmed(
    ProgramListDeleteConfirmed event,
    Emitter<ProgramListState> emit,
  ) async {
    final current = state;
    if (current is! ProgramListLoaded) return;

    try {
      await _programRepository.deleteProgram(event.programId);
      emit(const ProgramListLoading());
      await _loadPrograms(emit);
    } on DomainError catch (e) {
      emit(
        current.copyWith(
          deletionCandidateId: () => null,
          lastDeleteError: () => e,
        ),
      );
    }
  }

  Future<void> _onDeleteCancelled(
    ProgramListDeleteCancelled event,
    Emitter<ProgramListState> emit,
  ) async {
    final current = state;
    if (current is! ProgramListLoaded) return;
    emit(current.copyWith(deletionCandidateId: () => null));
  }

  Future<void> _onRetryRequested(
    ProgramListRetryRequested event,
    Emitter<ProgramListState> emit,
  ) async {
    emit(const ProgramListLoading());
    await _loadPrograms(emit);
  }

  Future<void> _onRefreshed(
    ProgramListRefreshed event,
    Emitter<ProgramListState> emit,
  ) async {
    await _loadPrograms(emit);
  }

  Future<void> _loadPrograms(Emitter<ProgramListState> emit) async {
    try {
      emit(ProgramListLoaded(programs: await _sortedPrograms()));
    } on DomainError catch (e) {
      emit(ProgramListFailure(error: e));
    }
  }

  /// Programs newest-edited first, ties broken case-insensitively by name.
  Future<List<Program>> _sortedPrograms() async {
    final programs = await _programRepository.listPrograms();
    programs.sort((a, b) {
      final cmp = b.updatedAt.compareTo(a.updatedAt);
      if (cmp != 0) return cmp;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    return programs;
  }
}
