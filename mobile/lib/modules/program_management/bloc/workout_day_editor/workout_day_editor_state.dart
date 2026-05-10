import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

final class WorkoutDayDraftValidation extends Equatable {
  const WorkoutDayDraftValidation({required this.isNameValid});

  final bool isNameValid;

  static WorkoutDayDraftValidation of(WorkoutDayDraft draft) {
    final trimmed = draft.name.trim();
    return WorkoutDayDraftValidation(
      isNameValid: trimmed.isNotEmpty && trimmed.length <= 100,
    );
  }

  @override
  List<Object?> get props => [isNameValid];
}

sealed class WorkoutDayEditorState extends Equatable {
  const WorkoutDayEditorState();
}

final class WorkoutDayEditorInitial extends WorkoutDayEditorState {
  const WorkoutDayEditorInitial();

  @override
  List<Object?> get props => [];
}

final class WorkoutDayEditorLoading extends WorkoutDayEditorState {
  const WorkoutDayEditorLoading();

  @override
  List<Object?> get props => [];
}

final class WorkoutDayEditorNotFound extends WorkoutDayEditorState {
  const WorkoutDayEditorNotFound({required this.workoutDayId});

  final String workoutDayId;

  @override
  List<Object?> get props => [workoutDayId];
}

final class WorkoutDayEditorEditing extends WorkoutDayEditorState {
  const WorkoutDayEditorEditing({
    required this.draft,
    required this.validation,
    this.lastSaveError,
  });

  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;
  final DomainError? lastSaveError;

  WorkoutDayEditorEditing copyWith({
    WorkoutDayDraft? draft,
    WorkoutDayDraftValidation? validation,
    DomainError? Function()? lastSaveError,
  }) {
    return WorkoutDayEditorEditing(
      draft: draft ?? this.draft,
      validation: validation ?? this.validation,
      lastSaveError: lastSaveError != null
          ? lastSaveError()
          : this.lastSaveError,
    );
  }

  @override
  List<Object?> get props => [draft, validation, lastSaveError];
}

final class WorkoutDayEditorGroupValidationError extends WorkoutDayEditorState {
  const WorkoutDayEditorGroupValidationError({
    required this.draft,
    required this.groupDraftId,
    required this.invariant,
  });

  final WorkoutDayDraft draft;
  final String groupDraftId;
  final String invariant;

  @override
  List<Object?> get props => [draft, groupDraftId, invariant];
}

final class WorkoutDayEditorSaving extends WorkoutDayEditorState {
  const WorkoutDayEditorSaving({required this.draft});

  final WorkoutDayDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class WorkoutDayEditorSaved extends WorkoutDayEditorState {
  const WorkoutDayEditorSaved({required this.workoutDayId});

  final String workoutDayId;

  @override
  List<Object?> get props => [workoutDayId];
}
