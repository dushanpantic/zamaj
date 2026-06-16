import 'package:equatable/equatable.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/program_validation.dart';

final class WorkoutDayDraftValidation extends Equatable {
  const WorkoutDayDraftValidation({
    required this.isNameValid,
    this.invalidExerciseDraftIds = const {},
  });

  final bool isNameValid;

  /// Draft IDs of exercises that are incomplete or have invalid set values.
  /// Surface this on the per-tile UI so the user can see *which* exercise
  /// is blocking save without having to drill in.
  final Set<String> invalidExerciseDraftIds;

  static WorkoutDayDraftValidation of(WorkoutDayDraft draft) {
    final trimmed = draft.name.trim();
    final invalid = <String>{};
    for (final group in draft.groups) {
      for (final exercise in group.exercises) {
        if (_isExerciseInvalid(exercise)) {
          invalid.add(exercise.draftId);
        }
      }
    }
    return WorkoutDayDraftValidation(
      isNameValid: trimmed.isNotEmpty && trimmed.length <= 100,
      invalidExerciseDraftIds: invalid,
    );
  }

  static bool _isExerciseInvalid(ExerciseDraft exercise) {
    if (exercise.sets.isEmpty) return true;
    final type = exercise.measurementType;
    for (final set in exercise.sets) {
      if (!_isSetValid(set, type)) return true;
    }
    return false;
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
  List<Object?> get props => [isNameValid, invalidExerciseDraftIds];
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
    this.isSaving = false,
    this.lastSaveError,
    this.badgedExerciseIds = const {},
  });

  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;
  final bool isSaving;
  final DomainError? lastSaveError;

  /// Persisted ids of exercises flagged "needs attention" — capped at their
  /// current prescription and not yet advanced. Excludes warmup-group and
  /// unlinked exercises. Resolved on load/refresh from completed sessions.
  final Set<String> badgedExerciseIds;

  WorkoutDayEditorEditing copyWith({
    WorkoutDayDraft? draft,
    WorkoutDayDraftValidation? validation,
    bool? isSaving,
    DomainError? Function()? lastSaveError,
    Set<String>? badgedExerciseIds,
  }) {
    return WorkoutDayEditorEditing(
      draft: draft ?? this.draft,
      validation: validation ?? this.validation,
      isSaving: isSaving ?? this.isSaving,
      lastSaveError: lastSaveError != null
          ? lastSaveError()
          : this.lastSaveError,
      badgedExerciseIds: badgedExerciseIds ?? this.badgedExerciseIds,
    );
  }

  @override
  List<Object?> get props => [
    draft,
    validation,
    isSaving,
    lastSaveError,
    badgedExerciseIds,
  ];
}

final class WorkoutDayEditorExerciseCreated extends WorkoutDayEditorState {
  const WorkoutDayEditorExerciseCreated({
    required this.draft,
    required this.validation,
    required this.exerciseId,
  });

  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;
  final String exerciseId;

  @override
  List<Object?> get props => [draft, validation, exerciseId];
}
