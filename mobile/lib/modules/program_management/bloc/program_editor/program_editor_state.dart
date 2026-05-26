import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/models/workout_day_summary.dart';

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

class PendingDeletion extends Equatable {
  const PendingDeletion({
    required this.draftId,
    required this.restoreIndex,
    required this.day,
    required this.summary,
  });

  final String draftId;
  final int restoreIndex;
  final WorkoutDayDraft day;
  final WorkoutDaySummary summary;

  @override
  List<Object?> get props => [draftId, restoreIndex, day, summary];
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
    this.isSaving = false,
    this.deletionCandidateDraftId,
    this.lastSaveError,
    this.daySummaries = const {},
    this.pendingDeletion,
  });

  final ProgramDraft draft;
  final bool isCreateMode;
  final bool isSaving;
  final String? deletionCandidateDraftId;
  final ProgramDraftValidation validation;
  final DomainError? lastSaveError;

  /// Per-day exercise counts keyed by `persistedId`. Days without a
  /// `persistedId` (newly-added, not yet saved) won't appear here and
  /// should fall back to [WorkoutDaySummary.empty].
  final Map<String, WorkoutDaySummary> daySummaries;

  /// Set when the user triggers an optimistic delete that hasn't yet been
  /// finalised. The UI filters this day from the visible list and shows a
  /// snackbar; the deletion is only persisted when finalised.
  final PendingDeletion? pendingDeletion;

  WorkoutDaySummary summaryFor(WorkoutDayDraft day) {
    final id = day.persistedId;
    if (id == null) return WorkoutDaySummary.empty;
    return daySummaries[id] ?? WorkoutDaySummary.empty;
  }

  ProgramEditorEditing copyWith({
    ProgramDraft? draft,
    bool? isCreateMode,
    bool? isSaving,
    ProgramDraftValidation? validation,
    String? Function()? deletionCandidateDraftId,
    DomainError? Function()? lastSaveError,
    Map<String, WorkoutDaySummary>? daySummaries,
    PendingDeletion? Function()? pendingDeletion,
  }) {
    return ProgramEditorEditing(
      draft: draft ?? this.draft,
      isCreateMode: isCreateMode ?? this.isCreateMode,
      isSaving: isSaving ?? this.isSaving,
      validation: validation ?? this.validation,
      deletionCandidateDraftId: deletionCandidateDraftId != null
          ? deletionCandidateDraftId()
          : this.deletionCandidateDraftId,
      lastSaveError: lastSaveError != null
          ? lastSaveError()
          : this.lastSaveError,
      daySummaries: daySummaries ?? this.daySummaries,
      pendingDeletion: pendingDeletion != null
          ? pendingDeletion()
          : this.pendingDeletion,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    isCreateMode,
    isSaving,
    deletionCandidateDraftId,
    validation,
    lastSaveError,
    daySummaries,
    pendingDeletion,
  ];
}
