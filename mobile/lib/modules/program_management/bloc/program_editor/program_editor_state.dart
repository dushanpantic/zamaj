import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/models/workout_day_summary.dart';
import 'package:zamaj/modules/program_management/services/program_name_rules.dart';

final class ProgramDraftValidation extends Equatable {
  const ProgramDraftValidation({required this.isNameValid});

  final bool isNameValid;

  bool get canSave => isNameValid;

  /// Name validity for saving a program. Delegates to the single create/save
  /// rule in [ProgramNameRules] (non-empty after trim, within the uniform
  /// 100-char bound) so the create dialog and the editor never diverge.
  static ProgramDraftValidation compute({required String name}) {
    return ProgramDraftValidation(
      isNameValid: ProgramNameRules.canCreate(name),
    );
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
    required this.validation,
    this.isSaving = false,
    this.deletionCandidateDraftId,
    this.lastSaveError,
    this.hadUnexpectedSaveError = false,
    this.daySummaries = const {},
    this.dayExercisePreviews = const {},
    this.pendingDeletion,
    this.programUpdatedAt,
  });

  final ProgramDraft draft;
  final bool isSaving;
  final String? deletionCandidateDraftId;
  final ProgramDraftValidation validation;
  final DomainError? lastSaveError;

  /// True when the last save failed with a non-[DomainError] (e.g. a bug or an
  /// unexpected storage error). Surfaced as a generic non-fatal notice so a
  /// failed save never crashes the editor.
  final bool hadUnexpectedSaveError;

  /// Per-day exercise counts keyed by `persistedId`. Days without a
  /// `persistedId` (newly-added, not yet saved) won't appear here and
  /// should fall back to [WorkoutDaySummary.empty].
  final Map<String, WorkoutDaySummary> daySummaries;

  /// Per-day ordered list of exercise names (main groups, then warmups)
  /// keyed by `persistedId`. Used by the inline-expand peek.
  final Map<String, List<String>> dayExercisePreviews;

  /// Set when the user triggers an optimistic delete that hasn't yet been
  /// finalised. The UI filters this day from the visible list and shows a
  /// snackbar; the deletion is only persisted when finalised.
  final PendingDeletion? pendingDeletion;

  /// Last time the program (or any of its children) was saved. Used by the
  /// header strip's "last edited" label. `null` until the first load/save
  /// resolves.
  final DateTime? programUpdatedAt;

  WorkoutDaySummary summaryFor(WorkoutDayDraft day) {
    final id = day.persistedId;
    if (id == null) return WorkoutDaySummary.empty;
    return daySummaries[id] ?? WorkoutDaySummary.empty;
  }

  List<String> exercisePreviewFor(WorkoutDayDraft day) {
    final id = day.persistedId;
    if (id == null) return const [];
    return dayExercisePreviews[id] ?? const [];
  }

  int get totalExerciseCount {
    var total = 0;
    for (final summary in daySummaries.values) {
      total += summary.exerciseCount + summary.warmupExerciseCount;
    }
    return total;
  }

  ProgramEditorEditing copyWith({
    ProgramDraft? draft,
    bool? isSaving,
    ProgramDraftValidation? validation,
    String? Function()? deletionCandidateDraftId,
    DomainError? Function()? lastSaveError,
    bool? hadUnexpectedSaveError,
    Map<String, WorkoutDaySummary>? daySummaries,
    Map<String, List<String>>? dayExercisePreviews,
    PendingDeletion? Function()? pendingDeletion,
    DateTime? Function()? programUpdatedAt,
  }) {
    return ProgramEditorEditing(
      draft: draft ?? this.draft,
      isSaving: isSaving ?? this.isSaving,
      validation: validation ?? this.validation,
      deletionCandidateDraftId: deletionCandidateDraftId != null
          ? deletionCandidateDraftId()
          : this.deletionCandidateDraftId,
      lastSaveError: lastSaveError != null
          ? lastSaveError()
          : this.lastSaveError,
      hadUnexpectedSaveError:
          hadUnexpectedSaveError ?? this.hadUnexpectedSaveError,
      daySummaries: daySummaries ?? this.daySummaries,
      dayExercisePreviews: dayExercisePreviews ?? this.dayExercisePreviews,
      pendingDeletion: pendingDeletion != null
          ? pendingDeletion()
          : this.pendingDeletion,
      programUpdatedAt: programUpdatedAt != null
          ? programUpdatedAt()
          : this.programUpdatedAt,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    isSaving,
    deletionCandidateDraftId,
    validation,
    lastSaveError,
    hadUnexpectedSaveError,
    daySummaries,
    dayExercisePreviews,
    pendingDeletion,
    programUpdatedAt,
  ];
}
