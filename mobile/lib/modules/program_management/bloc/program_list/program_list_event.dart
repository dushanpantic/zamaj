import 'package:equatable/equatable.dart';

sealed class ProgramListEvent extends Equatable {
  const ProgramListEvent();
}

final class ProgramListRequested extends ProgramListEvent {
  const ProgramListRequested();

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
