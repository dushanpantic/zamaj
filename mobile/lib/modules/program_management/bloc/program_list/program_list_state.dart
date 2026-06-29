import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';

sealed class ProgramListState extends Equatable {
  const ProgramListState();
}

final class ProgramListInitial extends ProgramListState {
  const ProgramListInitial();

  @override
  List<Object?> get props => [];
}

final class ProgramListLoading extends ProgramListState {
  const ProgramListLoading();

  @override
  List<Object?> get props => [];
}

final class ProgramListLoaded extends ProgramListState {
  const ProgramListLoaded({
    required this.programs,
    this.deletionCandidateId,
    this.lastDeleteError,
    this.lastCreatedProgramId,
  });

  final List<Program> programs;
  final String? deletionCandidateId;
  final DomainError? lastDeleteError;

  /// One-shot id of a program just created via [ProgramCreateRequested]. The
  /// list screen consumes it to push the editor for the new program, then
  /// dispatches [ProgramCreateNavigationHandled] to clear it.
  final String? lastCreatedProgramId;

  ProgramListLoaded copyWith({
    List<Program>? programs,
    String? Function()? deletionCandidateId,
    DomainError? Function()? lastDeleteError,
    String? Function()? lastCreatedProgramId,
  }) {
    return ProgramListLoaded(
      programs: programs ?? this.programs,
      deletionCandidateId: deletionCandidateId != null
          ? deletionCandidateId()
          : this.deletionCandidateId,
      lastDeleteError: lastDeleteError != null
          ? lastDeleteError()
          : this.lastDeleteError,
      lastCreatedProgramId: lastCreatedProgramId != null
          ? lastCreatedProgramId()
          : this.lastCreatedProgramId,
    );
  }

  @override
  List<Object?> get props => [
    programs,
    deletionCandidateId,
    lastDeleteError,
    lastCreatedProgramId,
  ];
}

final class ProgramListFailure extends ProgramListState {
  const ProgramListFailure({required this.error});

  final DomainError error;

  @override
  List<Object?> get props => [error];
}
