import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/program_validation.dart';

/// Working draft for the library editor. Mirrors [LibraryExercise] but holds
/// raw text inputs so we can validate before serialising into the domain
/// model.
final class LibraryExerciseDraft extends Equatable {
  const LibraryExerciseDraft({
    required this.name,
    required this.measurementType,
    required this.videoUrl,
    required this.cues,
  });

  final String name;
  final MeasurementType measurementType;
  final String videoUrl;
  final String cues;

  LibraryExerciseDraft copyWith({
    String? name,
    MeasurementType? measurementType,
    String? videoUrl,
    String? cues,
  }) {
    return LibraryExerciseDraft(
      name: name ?? this.name,
      measurementType: measurementType ?? this.measurementType,
      videoUrl: videoUrl ?? this.videoUrl,
      cues: cues ?? this.cues,
    );
  }

  @override
  List<Object?> get props => [name, measurementType, videoUrl, cues];
}

final class LibraryExerciseDraftValidation extends Equatable {
  const LibraryExerciseDraftValidation({
    required this.isNameValid,
    required this.isVideoUrlValid,
    required this.areCuesValid,
  });

  final bool isNameValid;
  final bool isVideoUrlValid;
  final bool areCuesValid;

  bool get canSave => isNameValid && isVideoUrlValid && areCuesValid;

  static LibraryExerciseDraftValidation compute(LibraryExerciseDraft draft) {
    final isNameValid =
        ProgramValidation.validateExerciseName(draft.name) is Valid<String>;
    final videoTrimmed = draft.videoUrl.trim();
    final isVideoUrlValid = videoTrimmed.isEmpty
        ? true
        : ProgramValidation.validateVideoUrl(draft.videoUrl) is Valid<Uri?>;
    final cuesTrimmed = draft.cues.trim();
    final areCuesValid = cuesTrimmed.isEmpty
        ? true
        : cuesTrimmed.length <= 2000;
    return LibraryExerciseDraftValidation(
      isNameValid: isNameValid,
      isVideoUrlValid: isVideoUrlValid,
      areCuesValid: areCuesValid,
    );
  }

  @override
  List<Object?> get props => [isNameValid, isVideoUrlValid, areCuesValid];
}

sealed class ExerciseLibraryEditorState extends Equatable {
  const ExerciseLibraryEditorState();
}

final class ExerciseLibraryEditorInitial extends ExerciseLibraryEditorState {
  const ExerciseLibraryEditorInitial();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryEditorLoading extends ExerciseLibraryEditorState {
  const ExerciseLibraryEditorLoading();

  @override
  List<Object?> get props => [];
}

final class ExerciseLibraryEditorNotFound extends ExerciseLibraryEditorState {
  const ExerciseLibraryEditorNotFound({required this.libraryExerciseId});

  final String libraryExerciseId;

  @override
  List<Object?> get props => [libraryExerciseId];
}

/// Either an in-progress create (when [persisted] is null) or an edit of an
/// existing entry. `measurementType` is locked to the persisted value once
/// the entry exists.
final class ExerciseLibraryEditorEditing extends ExerciseLibraryEditorState {
  const ExerciseLibraryEditorEditing({
    required this.draft,
    required this.validation,
    required this.persisted,
    this.lastError,
  });

  final LibraryExerciseDraft draft;
  final LibraryExerciseDraftValidation validation;
  final LibraryExercise? persisted;
  final DomainError? lastError;

  bool get isCreate => persisted == null;
  bool get isArchived => persisted?.archivedAt != null;
  bool get isMeasurementTypeLocked => persisted != null;

  ExerciseLibraryEditorEditing copyWith({
    LibraryExerciseDraft? draft,
    LibraryExerciseDraftValidation? validation,
    LibraryExercise? Function()? persisted,
    DomainError? Function()? lastError,
  }) {
    return ExerciseLibraryEditorEditing(
      draft: draft ?? this.draft,
      validation: validation ?? this.validation,
      persisted: persisted != null ? persisted() : this.persisted,
      lastError: lastError != null ? lastError() : this.lastError,
    );
  }

  @override
  List<Object?> get props => [draft, validation, persisted, lastError];
}

final class ExerciseLibraryEditorSaving extends ExerciseLibraryEditorState {
  const ExerciseLibraryEditorSaving({required this.draft});

  final LibraryExerciseDraft draft;

  @override
  List<Object?> get props => [draft];
}

final class ExerciseLibraryEditorSaved extends ExerciseLibraryEditorState {
  const ExerciseLibraryEditorSaved({required this.entry});

  final LibraryExercise entry;

  @override
  List<Object?> get props => [entry];
}
