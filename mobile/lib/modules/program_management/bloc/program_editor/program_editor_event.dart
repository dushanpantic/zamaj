import 'package:equatable/equatable.dart';

sealed class ProgramEditorEvent extends Equatable {
  const ProgramEditorEvent();
}

final class ProgramEditorOpened extends ProgramEditorEvent {
  const ProgramEditorOpened({this.programId});

  final String? programId;

  @override
  List<Object?> get props => [programId];
}

final class ProgramEditorNameChanged extends ProgramEditorEvent {
  const ProgramEditorNameChanged({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

final class ProgramEditorWorkoutDayAdded extends ProgramEditorEvent {
  const ProgramEditorWorkoutDayAdded({required this.name});

  final String name;

  @override
  List<Object?> get props => [name];
}

final class ProgramEditorWorkoutDayRenamed extends ProgramEditorEvent {
  const ProgramEditorWorkoutDayRenamed({
    required this.draftId,
    required this.name,
  });

  final String draftId;
  final String name;

  @override
  List<Object?> get props => [draftId, name];
}

final class ProgramEditorWorkoutDayDeleteRequested extends ProgramEditorEvent {
  const ProgramEditorWorkoutDayDeleteRequested({required this.draftId});

  final String draftId;

  @override
  List<Object?> get props => [draftId];
}

final class ProgramEditorWorkoutDayDeleteConfirmed extends ProgramEditorEvent {
  const ProgramEditorWorkoutDayDeleteConfirmed({required this.draftId});

  final String draftId;

  @override
  List<Object?> get props => [draftId];
}

final class ProgramEditorWorkoutDayDeleteCancelled extends ProgramEditorEvent {
  const ProgramEditorWorkoutDayDeleteCancelled();

  @override
  List<Object?> get props => [];
}

final class ProgramEditorWorkoutDaysReordered extends ProgramEditorEvent {
  const ProgramEditorWorkoutDaysReordered({required this.orderedDraftIds});

  final List<String> orderedDraftIds;

  @override
  List<Object?> get props => [orderedDraftIds];
}
