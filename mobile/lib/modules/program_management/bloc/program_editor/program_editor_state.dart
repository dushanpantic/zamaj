import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

final class ProgramDraftValidation extends Equatable {
  const ProgramDraftValidation({required this.isNameValid});

  final bool isNameValid;

  bool get canSave => isNameValid;

  static ProgramDraftValidation compute({
    required String name,
    required bool isCreateMode,
  }) {
    final trimmed = name.trim();
    final maxLength = isCreateMode ? 120 : 100;
    final isNameValid = trimmed.isNotEmpty && trimmed.length <= maxLength;
    return ProgramDraftValidation(isNameValid: isNameValid);
  }

  @override
  List<Object?> get props => [isNameValid];
}

sealed class ProgramEditorState extends Equatable {
  const ProgramEditorState();
}

final class ProgramEditorInitial extends ProgramEditorState {
  const ProgramEditorInitial();

  @override
  List<Object?> get props => [];
}

final class ProgramEditorLoading extends ProgramEditorState {
  const ProgramEditorLoading();

  @override
  List<Object?> get props => [];
}

final class ProgramEditorNotFound extends ProgramEditorState {
  const ProgramEditorNotFound({required this.programId});

  final String programId;

  @override
  List<Object?> get props => [programId];
}

final class ProgramEditorEditing extends ProgramEditorState {
  const ProgramEditorEditing({
    required this.draft,
    required this.isCreateMode,
    required this.validation,
    this.deletionCandidateDraftId,
    this.lastSaveError,
  });

  final ProgramDraft draft;
  final bool isCreateMode;
  final String? deletionCandidateDraftId;
  final ProgramDraftValidation validation;
  final DomainError? lastSaveError;

  ProgramEditorEditing copyWith({
    ProgramDraft? draft,
    bool? isCreateMode,
    ProgramDraftValidation? validation,
    String? Function()? deletionCandidateDraftId,
    DomainError? Function()? lastSaveError,
  }) {
    return ProgramEditorEditing(
      draft: draft ?? this.draft,
      isCreateMode: isCreateMode ?? this.isCreateMode,
      validation: validation ?? this.validation,
      deletionCandidateDraftId: deletionCandidateDraftId != null
          ? deletionCandidateDraftId()
          : this.deletionCandidateDraftId,
      lastSaveError: lastSaveError != null
          ? lastSaveError()
          : this.lastSaveError,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    isCreateMode,
    deletionCandidateDraftId,
    validation,
    lastSaveError,
  ];
}

final class ProgramEditorSaving extends ProgramEditorState {
  const ProgramEditorSaving({required this.draft});

  final ProgramDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class ProgramEditorSaved extends ProgramEditorState {
  const ProgramEditorSaved({required this.programId});

  final String programId;

  @override
  List<Object?> get props => [programId];
}
