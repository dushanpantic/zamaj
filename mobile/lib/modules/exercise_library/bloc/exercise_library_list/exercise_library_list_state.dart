import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class ExerciseLibraryListState extends Equatable {
  const ExerciseLibraryListState();
}

final class ExerciseLibraryListInitial extends ExerciseLibraryListState {
  const ExerciseLibraryListInitial();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryListLoading extends ExerciseLibraryListState {
  const ExerciseLibraryListLoading();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryListLoaded extends ExerciseLibraryListState {
  const ExerciseLibraryListLoaded({
    required this.entries,
    required this.searchQuery,
    required this.includeArchived,
    this.lastError,
    this.mutatingId,
  });

  final List<LibraryExercise> entries;
  final String searchQuery;
  final bool includeArchived;
  final DomainError? lastError;

  /// Id of the entry currently being archived/unarchived, if any. Used to show
  /// an inline spinner on the tile.
  final String? mutatingId;

  ExerciseLibraryListLoaded copyWith({
    List<LibraryExercise>? entries,
    String? searchQuery,
    bool? includeArchived,
    DomainError? Function()? lastError,
    String? Function()? mutatingId,
  }) {
    return ExerciseLibraryListLoaded(
      entries: entries ?? this.entries,
      searchQuery: searchQuery ?? this.searchQuery,
      includeArchived: includeArchived ?? this.includeArchived,
      lastError: lastError != null ? lastError() : this.lastError,
      mutatingId: mutatingId != null ? mutatingId() : this.mutatingId,
    );
  }

  @override
  List<Object?> get props => [
    entries,
    searchQuery,
    includeArchived,
    lastError,
    mutatingId,
  ];
}

final class ExerciseLibraryListFailure extends ExerciseLibraryListState {
  const ExerciseLibraryListFailure({required this.error});

  final DomainError error;

  @override
  List<Object?> get props => [error];
}
