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
  });

  final bool isNameValid;
  final bool isPlannedRestValid;
  final bool isVideoUrlValid;
  final bool isNotesValid;

  bool get canSave =>
      isNameValid && isPlannedRestValid && isVideoUrlValid && isNotesValid;

  static ExerciseDraftValidation compute({
    required String name,
    required String? plannedRestInput,
    required String? videoUrl,
    required String? notes,
  }) {
    final isNameValid =
        ProgramValidation.validateExerciseName(name) is Valid<String>;
    final isPlannedRestValid =
        ProgramValidation.validatePlannedRest(plannedRestInput) is Valid<int?>;
    final isVideoUrlValid =
        ProgramValidation.validateVideoUrl(videoUrl) is Valid<Uri?>;
    final isNotesValid =
        ProgramValidation.validateNotes(notes) is Valid<String?>;
    return ExerciseDraftValidation(
      isNameValid: isNameValid,
      isPlannedRestValid: isPlannedRestValid,
      isVideoUrlValid: isVideoUrlValid,
      isNotesValid: isNotesValid,
    );
  }

  @override
  List<Object?> get props => [
    isNameValid,
    isPlannedRestValid,
    isVideoUrlValid,
    isNotesValid,
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
    required this.validation,
    this.pendingMeasurementChange,
    this.lastSaveError,
  });

  final ExerciseDraft draft;
  final ExerciseDraftValidation validation;
  final MeasurementType? pendingMeasurementChange;
  final DomainError? lastSaveError;

  ExerciseEditorEditing copyWith({
    ExerciseDraft? draft,
    ExerciseDraftValidation? validation,
    MeasurementType? Function()? pendingMeasurementChange,
    DomainError? Function()? lastSaveError,
  }) {
    return ExerciseEditorEditing(
      draft: draft ?? this.draft,
      validation: validation ?? this.validation,
      pendingMeasurementChange: pendingMeasurementChange != null
          ? pendingMeasurementChange()
          : this.pendingMeasurementChange,
      lastSaveError: lastSaveError != null
          ? lastSaveError()
          : this.lastSaveError,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    validation,
    pendingMeasurementChange,
    lastSaveError,
  ];
}

final class ExerciseEditorSaving extends ExerciseEditorState {
  const ExerciseEditorSaving({required this.draft});

  final ExerciseDraft draft;

  @override
  List<Object?> get props => [draft];
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
    required this.validation,
    required this.reason,
  });

  final ExerciseDraft draft;
  final ExerciseDraftValidation validation;
  final String reason;

  @override
  List<Object?> get props => [draft, validation, reason];
}
