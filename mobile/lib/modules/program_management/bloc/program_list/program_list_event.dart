import 'package:equatable/equatable.dart';

sealed class ProgramListEvent extends Equatable {
  const ProgramListEvent();
}

final class ProgramListRequested extends ProgramListEvent {
  const ProgramListRequested();

  @override
  List<Object?> get props => [];
}

/// Creates a new, empty program named [name] (single write). Ignored when the
/// trimmed name is invalid — the name-first dialog gates this, the bloc guards
/// it again as defense-in-depth.
final class ProgramCreateRequested extends ProgramListEvent {
  const ProgramCreateRequested({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

/// Clears the one-shot [ProgramListLoaded.lastCreatedProgramId] after the UI has
/// consumed it to navigate, so a rebuild doesn't re-trigger navigation.
final class ProgramCreateNavigationHandled extends ProgramListEvent {
  const ProgramCreateNavigationHandled();

  @override
  List<Object?> get props => [];
}

final class ProgramListDeleteRequested extends ProgramListEvent {
  const ProgramListDeleteRequested({required this.programId});

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class ProgramListDeleteConfirmed extends ProgramListEvent {
  const ProgramListDeleteConfirmed({required this.programId});

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class ProgramListDeleteCancelled extends ProgramListEvent {
  const ProgramListDeleteCancelled({required this.programId});

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class ProgramListRetryRequested extends ProgramListEvent {
  const ProgramListRetryRequested();

  @override
  List<Object?> get props => [];
}

final class ProgramListRefreshed extends ProgramListEvent {
  const ProgramListRefreshed();

  @override
  List<Object?> get props => [];
}
