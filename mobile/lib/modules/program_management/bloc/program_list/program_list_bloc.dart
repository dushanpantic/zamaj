import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';

import 'program_list_event.dart';
import 'program_list_state.dart';

class ProgramListBloc extends Bloc<ProgramListEvent, ProgramListState> {
  ProgramListBloc({required ProgramRepository programRepository})
    : _programRepository = programRepository,
      super(const ProgramListInitial()) {
    on<ProgramListRequested>(_onRequested);
    on<ProgramListDeleteRequested>(_onDeleteRequested);
    on<ProgramListDeleteConfirmed>(_onDeleteConfirmed);
    on<ProgramListDeleteCancelled>(_onDeleteCancelled);
    on<ProgramListRetryRequested>(_onRetryRequested);
  }

  final ProgramRepository _programRepository;

  Future<void> _onRequested(
    ProgramListRequested event,
    Emitter<ProgramListState> emit,
  ) async {
    emit(const ProgramListLoading());
    await _loadPrograms(emit);
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

  Future<void> _loadPrograms(Emitter<ProgramListState> emit) async {
    try {
      final programs = await _programRepository.listPrograms();
      programs.sort((a, b) {
        final cmp = b.updatedAt.compareTo(a.updatedAt);
        if (cmp != 0) return cmp;
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      emit(ProgramListLoaded(programs: programs));
    } on DomainError catch (e) {
      emit(ProgramListFailure(error: e));
    }
  }
}
