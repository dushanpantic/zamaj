import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';

import 'exercise_library_list_event.dart';
import 'exercise_library_list_state.dart';

class ExerciseLibraryListBloc
    extends Bloc<ExerciseLibraryListEvent, ExerciseLibraryListState> {
  ExerciseLibraryListBloc({
    required ExerciseLibraryRepository exerciseLibraryRepository,
  }) : _repo = exerciseLibraryRepository,
       super(const ExerciseLibraryListInitial()) {
    on<ExerciseLibraryListRequested>(_onRequested);
    on<ExerciseLibraryListRefreshed>(_onRefreshed);
    on<ExerciseLibraryListSearchChanged>(_onSearchChanged);
    on<ExerciseLibraryListIncludeArchivedToggled>(_onIncludeArchivedToggled);
    on<ExerciseLibraryListArchiveRequested>(_onArchiveRequested);
    on<ExerciseLibraryListUnarchiveRequested>(_onUnarchiveRequested);
    on<ExerciseLibraryListRetryRequested>(_onRetryRequested);
  }

  final ExerciseLibraryRepository _repo;

  Future<void> _onRequested(
    ExerciseLibraryListRequested event,
    Emitter<ExerciseLibraryListState> emit,
  ) async {
    emit(const ExerciseLibraryListLoading());
    await _load(emit, searchQuery: '', includeArchived: false);
  }

  Future<void> _onRefreshed(
    ExerciseLibraryListRefreshed event,
    Emitter<ExerciseLibraryListState> emit,
  ) async {
    final current = state;
    final searchQuery = current is ExerciseLibraryListLoaded
        ? current.searchQuery
        : '';
    final includeArchived = current is ExerciseLibraryListLoaded
        ? current.includeArchived
        : false;
    await _load(
      emit,
      searchQuery: searchQuery,
      includeArchived: includeArchived,
    );
  }

  Future<void> _onSearchChanged(
    ExerciseLibraryListSearchChanged event,
    Emitter<ExerciseLibraryListState> emit,
  ) async {
    final current = state;
    final includeArchived = current is ExerciseLibraryListLoaded
        ? current.includeArchived
        : false;
    await _load(
      emit,
      searchQuery: event.query,
      includeArchived: includeArchived,
    );
  }

  Future<void> _onIncludeArchivedToggled(
    ExerciseLibraryListIncludeArchivedToggled event,
    Emitter<ExerciseLibraryListState> emit,
  ) async {
    final current = state;
    final searchQuery = current is ExerciseLibraryListLoaded
        ? current.searchQuery
        : '';
    await _load(
      emit,
      searchQuery: searchQuery,
      includeArchived: event.includeArchived,
    );
  }

  Future<void> _onArchiveRequested(
    ExerciseLibraryListArchiveRequested event,
    Emitter<ExerciseLibraryListState> emit,
  ) async {
    await _mutate(
      emit,
      id: event.libraryExerciseId,
      action: () => _repo.archive(event.libraryExerciseId),
    );
  }

  Future<void> _onUnarchiveRequested(
    ExerciseLibraryListUnarchiveRequested event,
    Emitter<ExerciseLibraryListState> emit,
  ) async {
    await _mutate(
      emit,
      id: event.libraryExerciseId,
      action: () => _repo.unarchive(event.libraryExerciseId),
    );
  }

  Future<void> _onRetryRequested(
    ExerciseLibraryListRetryRequested event,
    Emitter<ExerciseLibraryListState> emit,
  ) async {
    emit(const ExerciseLibraryListLoading());
    await _load(emit, searchQuery: '', includeArchived: false);
  }

  Future<void> _load(
    Emitter<ExerciseLibraryListState> emit, {
    required String searchQuery,
    required bool includeArchived,
  }) async {
    try {
      final entries = await _repo.list(
        includeArchived: includeArchived,
        nameQuery: searchQuery.trim().isEmpty ? null : searchQuery,
      );
      emit(
        ExerciseLibraryListLoaded(
          entries: entries,
          searchQuery: searchQuery,
          includeArchived: includeArchived,
        ),
      );
    } on DomainError catch (e) {
      emit(ExerciseLibraryListFailure(error: e));
    }
  }

  Future<void> _mutate(
    Emitter<ExerciseLibraryListState> emit, {
    required String id,
    required Future<LibraryExercise> Function() action,
  }) async {
    final current = state;
    if (current is! ExerciseLibraryListLoaded) return;
    emit(current.copyWith(mutatingId: () => id, lastError: () => null));
    try {
      await action();
      await _load(
        emit,
        searchQuery: current.searchQuery,
        includeArchived: current.includeArchived,
      );
    } on DomainError catch (e) {
      emit(current.copyWith(mutatingId: () => null, lastError: () => e));
    }
  }
}
