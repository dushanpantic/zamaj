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
  });

  final List<Program> programs;
  final String? deletionCandidateId;
  final DomainError? lastDeleteError;

  ProgramListLoaded copyWith({
    List<Program>? programs,
    String? Function()? deletionCandidateId,
    DomainError? Function()? lastDeleteError,
  }) {
    return ProgramListLoaded(
      programs: programs ?? this.programs,
      deletionCandidateId: deletionCandidateId != null
          ? deletionCandidateId()
          : this.deletionCandidateId,
      lastDeleteError: lastDeleteError != null
          ? lastDeleteError()
          : this.lastDeleteError,
    );
  }

  @override
  List<Object?> get props => [programs, deletionCandidateId, lastDeleteError];
}

final class ProgramListFailure extends ProgramListState {
  const ProgramListFailure({required this.error});

  final DomainError error;

  @override
  List<Object?> get props => [error];
}
