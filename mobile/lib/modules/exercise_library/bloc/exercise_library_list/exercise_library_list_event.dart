import 'package:equatable/equatable.dart';

sealed class ExerciseLibraryListEvent extends Equatable {
  const ExerciseLibraryListEvent();
}

final class ExerciseLibraryListRequested extends ExerciseLibraryListEvent {
  const ExerciseLibraryListRequested();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryListRefreshed extends ExerciseLibraryListEvent {
  const ExerciseLibraryListRefreshed();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryListSearchChanged extends ExerciseLibraryListEvent {
  const ExerciseLibraryListSearchChanged({required this.query});

  final String query;

  @override
  List<Object?> get props => [query];
}

final class ExerciseLibraryListIncludeArchivedToggled
    extends ExerciseLibraryListEvent {
  const ExerciseLibraryListIncludeArchivedToggled({
    required this.includeArchived,
  });

  final bool includeArchived;

  @override
  List<Object?> get props => [includeArchived];
}

final class ExerciseLibraryListArchiveRequested
    extends ExerciseLibraryListEvent {
  const ExerciseLibraryListArchiveRequested({required this.libraryExerciseId});

  final String libraryExerciseId;

  @override
  List<Object?> get props => [libraryExerciseId];
}

final class ExerciseLibraryListUnarchiveRequested
    extends ExerciseLibraryListEvent {
  const ExerciseLibraryListUnarchiveRequested({
    required this.libraryExerciseId,
  });

  final String libraryExerciseId;

  @override
  List<Object?> get props => [libraryExerciseId];
}

final class ExerciseLibraryListRetryRequested extends ExerciseLibraryListEvent {
  const ExerciseLibraryListRetryRequested();

  @override
  List<Object?> get props => [];
}
