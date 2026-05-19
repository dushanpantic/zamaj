import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/program_validation.dart';

final class ExerciseDraftValidation extends Equatable {
  const ExerciseDraftValidation({
    required this.isNameValid,
    required this.isPlannedRestValid,
    required this.isVideoUrlValid,
    required this.isNotesValid,
    required this.isSetCountValid,
    required this.areSetsValid,
  });

  final bool isNameValid;
  final bool isPlannedRestValid;
  final bool isVideoUrlValid;
  final bool isNotesValid;
  final bool isSetCountValid;
  final bool areSetsValid;

  bool get canSave =>
      isNameValid &&
      isPlannedRestValid &&
      isVideoUrlValid &&
      isNotesValid &&
      isSetCountValid &&
      areSetsValid;

  static ExerciseDraftValidation compute({
    required String name,
    required String? plannedRestInput,
    required String? videoUrl,
    required String? notes,
    required MeasurementType measurementType,
    required List<PlannedSetDraft> sets,
  }) {
    final isNameValid =
        ProgramValidation.validateExerciseName(name) is Valid<String>;
    final isPlannedRestValid =
        ProgramValidation.validatePlannedRest(plannedRestInput) is Valid<int?>;
    final isVideoUrlValid =
        ProgramValidation.validateVideoUrl(videoUrl) is Valid<Uri?>;
    final isNotesValid =
        ProgramValidation.validateNotes(notes) is Valid<String?>;
    final isSetCountValid =
        ProgramValidation.validateSetCount(sets.length) is Valid<int>;
    final areSetsValid = sets.every((s) => _isSetValid(s, measurementType));
    return ExerciseDraftValidation(
      isNameValid: isNameValid,
      isPlannedRestValid: isPlannedRestValid,
      isVideoUrlValid: isVideoUrlValid,
      isNotesValid: isNotesValid,
      isSetCountValid: isSetCountValid,
      areSetsValid: areSetsValid,
    );
  }

  static bool _isSetValid(PlannedSetDraft set, MeasurementType type) {
    return switch ((set.values, type)) {
      (
        PlannedSetDraftRepBased(:final weightInput, :final repsInput),
        RepBasedMeasurement(),
      ) =>
        ProgramValidation.validateRepBasedSet(
              weightInput: weightInput,
              repsInput: repsInput,
            )
            is Valid,
      (
        PlannedSetDraftTimeBased(:final durationInput, :final weightInput),
        TimeBasedMeasurement(),
      ) =>
        ProgramValidation.validateTimeBasedSet(durationInput) is Valid<int> &&
            ProgramValidation.validateTimeBasedSetWeight(weightInput)
                is Valid<double?>,
      (PlannedSetDraftBodyweight(:final repsInput), BodyweightMeasurement()) =>
        ProgramValidation.validateBodyweightSet(repsInput: repsInput)
            is Valid<RepTarget>,
      _ => false,
    };
  }

  @override
  List<Object?> get props => [
    isNameValid,
    isPlannedRestValid,
    isVideoUrlValid,
    isNotesValid,
    isSetCountValid,
    areSetsValid,
  ];
}

sealed class ExerciseEditorState extends Equatable {
  const ExerciseEditorState();
}

final class ExerciseEditorInitial extends ExerciseEditorState {
  const ExerciseEditorInitial();

  @override
  List<Object?> get props => [];
}

final class ExerciseEditorLoading extends ExerciseEditorState {
  const ExerciseEditorLoading();

  @override
  List<Object?> get props => [];
}

final class ExerciseEditorNotFound extends ExerciseEditorState {
  const ExerciseEditorNotFound({required this.exerciseId});

  final String exerciseId;

  @override
  List<Object?> get props => [exerciseId];
}

final class ExerciseEditorEditing extends ExerciseEditorState {
  const ExerciseEditorEditing({
    required this.draft,
    required this.groupRole,
    required this.validation,
    this.lastSaveError,
  });

  final ExerciseDraft draft;
  final ExerciseGroupRole groupRole;
  final ExerciseDraftValidation validation;
  final DomainError? lastSaveError;

  ExerciseEditorEditing copyWith({
    ExerciseDraft? draft,
    ExerciseGroupRole? groupRole,
    ExerciseDraftValidation? validation,
    DomainError? Function()? lastSaveError,
  }) {
    return ExerciseEditorEditing(
      draft: draft ?? this.draft,
      groupRole: groupRole ?? this.groupRole,
      validation: validation ?? this.validation,
      lastSaveError: lastSaveError != null
          ? lastSaveError()
          : this.lastSaveError,
    );
  }

  @override
  List<Object?> get props => [draft, groupRole, validation, lastSaveError];
}

final class ExerciseEditorSaving extends ExerciseEditorState {
  const ExerciseEditorSaving({required this.draft, required this.groupRole});

  final ExerciseDraft draft;
  final ExerciseGroupRole groupRole;

  @override
  List<Object?> get props => [draft, groupRole];
}

final class ExerciseEditorSaved extends ExerciseEditorState {
  const ExerciseEditorSaved({required this.exerciseId});

  final String exerciseId;

  @override
  List<Object?> get props => [exerciseId];
}

final class ExerciseEditorVideoLinkError extends ExerciseEditorState {
  const ExerciseEditorVideoLinkError({
    required this.draft,
    required this.groupRole,
    required this.validation,
    required this.reason,
  });

  final ExerciseDraft draft;
  final ExerciseGroupRole groupRole;
  final ExerciseDraftValidation validation;
  final String reason;

  @override
  List<Object?> get props => [draft, groupRole, validation, reason];
}
