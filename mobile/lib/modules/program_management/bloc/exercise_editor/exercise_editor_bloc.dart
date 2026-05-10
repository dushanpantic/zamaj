import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';
import 'package:zamaj/modules/program_management/services/program_validation.dart';

import 'exercise_editor_event.dart';
import 'exercise_editor_state.dart';

class ExerciseEditorBloc
    extends Bloc<ExerciseEditorEvent, ExerciseEditorState> {
  ExerciseEditorBloc({
    required ProgramRepository programRepository,
    required ExternalLinkLauncher externalLinkLauncher,
  }) : _programRepository = programRepository,
       _externalLinkLauncher = externalLinkLauncher,
       super(const ExerciseEditorInitial()) {
    on<ExerciseEditorOpened>(_onOpened);
    on<ExerciseNameChanged>(_onNameChanged);
    on<ExerciseMeasurementTypeRequested>(_onMeasurementTypeRequested);
    on<ExerciseMeasurementTypeConfirmed>(_onMeasurementTypeConfirmed);
    on<ExerciseMeasurementTypeCancelled>(_onMeasurementTypeCancelled);
    on<ExerciseNotesChanged>(_onNotesChanged);
    on<ExerciseVideoUrlChanged>(_onVideoUrlChanged);
    on<ExerciseVideoUrlActivated>(_onVideoUrlActivated);
    on<ExercisePlannedRestChanged>(_onPlannedRestChanged);
    on<PlannedSetAdded>(_onPlannedSetAdded);
    on<PlannedSetDeleted>(_onPlannedSetDeleted);
    on<PlannedSetReordered>(_onPlannedSetReordered);
    on<PlannedSetWeightChanged>(_onPlannedSetWeightChanged);
    on<PlannedSetRepsChanged>(_onPlannedSetRepsChanged);
    on<PlannedSetDurationChanged>(_onPlannedSetDurationChanged);
    on<ExerciseSavePressed>(_onSavePressed);
  }

  final ProgramRepository _programRepository;
  final ExternalLinkLauncher _externalLinkLauncher;
  final _uuid = const Uuid();

  String? _plannedRestInput;

  Future<void> _onOpened(
    ExerciseEditorOpened event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    emit(const ExerciseEditorLoading());
    final exercise = await _findExercise(event.exerciseId);
    if (exercise == null) {
      emit(ExerciseEditorNotFound(exerciseId: event.exerciseId));
      return;
    }
    final draft = _exerciseToDraft(exercise);
    _plannedRestInput = exercise.plannedRestSeconds?.toString();
    final validation = _computeValidation(draft);
    emit(ExerciseEditorEditing(draft: draft, validation: validation));
  }

  Future<void> _onNameChanged(
    ExerciseNameChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final updated = current.draft.copyWith(name: event.name);
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  Future<void> _onMeasurementTypeRequested(
    ExerciseMeasurementTypeRequested event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    if (event.next == current.draft.measurementType) return;
    emit(current.copyWith(pendingMeasurementChange: () => event.next));
  }

  Future<void> _onMeasurementTypeConfirmed(
    ExerciseMeasurementTypeConfirmed event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final pending = current.pendingMeasurementChange;
    if (pending == null) return;
    final reinitializedSets = current.draft.sets
        .map((s) => s.copyWith(values: _zeroValuedSet(pending)))
        .toList();
    final updated = current.draft.copyWith(
      measurementType: pending,
      sets: reinitializedSets,
    );
    final validation = _computeValidation(updated);
    emit(
      ExerciseEditorEditing(
        draft: updated,
        validation: validation,
        pendingMeasurementChange: null,
        lastSaveError: current.lastSaveError,
      ),
    );
  }

  Future<void> _onMeasurementTypeCancelled(
    ExerciseMeasurementTypeCancelled event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    emit(current.copyWith(pendingMeasurementChange: () => null));
  }

  Future<void> _onNotesChanged(
    ExerciseNotesChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final updatedMetadata = current.draft.metadata.copyWith(notes: event.notes);
    final updated = current.draft.copyWith(metadata: updatedMetadata);
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  Future<void> _onVideoUrlChanged(
    ExerciseVideoUrlChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final updatedMetadata = current.draft.metadata.copyWith(
      videoUrl: event.videoUrl,
    );
    final updated = current.draft.copyWith(metadata: updatedMetadata);
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  Future<void> _onVideoUrlActivated(
    ExerciseVideoUrlActivated event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final rawUrl = current.draft.metadata.videoUrl;
    final urlResult = ProgramValidation.validateVideoUrl(rawUrl);
    if (urlResult is! Valid<Uri?> || urlResult.value == null) return;
    final result = await _externalLinkLauncher.launch(urlResult.value!);
    if (result is ExternalLinkFailure) {
      emit(
        ExerciseEditorVideoLinkError(
          draft: current.draft,
          validation: current.validation,
          reason: result.reason,
        ),
      );
    }
  }

  Future<void> _onPlannedRestChanged(
    ExercisePlannedRestChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    _plannedRestInput = event.rawInput;
    final validation = _computeValidation(current.draft);
    emit(current.copyWith(validation: validation));
  }

  Future<void> _onPlannedSetAdded(
    PlannedSetAdded event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    if (current.draft.sets.length >= 20) return;
    final newSet = PlannedSetDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      values: _zeroValuedSet(current.draft.measurementType),
    );
    final updated = current.draft.copyWith(
      sets: [...current.draft.sets, newSet],
    );
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  Future<void> _onPlannedSetDeleted(
    PlannedSetDeleted event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    if (current.draft.sets.length <= 1) return;
    final updated = current.draft.copyWith(
      sets: current.draft.sets
          .where((s) => s.draftId != event.setDraftId)
          .toList(),
    );
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  Future<void> _onPlannedSetReordered(
    PlannedSetReordered event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final setMap = {for (final s in current.draft.sets) s.draftId: s};
    final reordered = event.orderedSetDraftIds
        .map((id) => setMap[id])
        .whereType<PlannedSetDraft>()
        .toList();
    final updated = current.draft.copyWith(sets: reordered);
    emit(current.copyWith(draft: updated));
  }

  Future<void> _onPlannedSetWeightChanged(
    PlannedSetWeightChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final updated = current.draft.copyWith(
      sets: current.draft.sets.map((s) {
        if (s.draftId != event.setDraftId) return s;
        final values = s.values;
        if (values is! PlannedSetDraftRepBased) return s;
        return s.copyWith(values: values.copyWith(weightInput: event.rawInput));
      }).toList(),
    );
    emit(current.copyWith(draft: updated));
  }

  Future<void> _onPlannedSetRepsChanged(
    PlannedSetRepsChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final updated = current.draft.copyWith(
      sets: current.draft.sets.map((s) {
        if (s.draftId != event.setDraftId) return s;
        final values = s.values;
        if (values is! PlannedSetDraftRepBased) return s;
        return s.copyWith(values: values.copyWith(repsInput: event.rawInput));
      }).toList(),
    );
    emit(current.copyWith(draft: updated));
  }

  Future<void> _onPlannedSetDurationChanged(
    PlannedSetDurationChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final updated = current.draft.copyWith(
      sets: current.draft.sets.map((s) {
        if (s.draftId != event.setDraftId) return s;
        final values = s.values;
        if (values is! PlannedSetDraftTimeBased) return s;
        return s.copyWith(
          values: values.copyWith(durationInput: event.rawInput),
        );
      }).toList(),
    );
    emit(current.copyWith(draft: updated));
  }

  Future<void> _onSavePressed(
    ExerciseSavePressed event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final validation = _computeValidation(current.draft);
    if (!validation.canSave) {
      emit(current.copyWith(validation: validation));
      return;
    }
    final persistedId = current.draft.persistedId;
    if (persistedId == null) return;

    final restResult = ProgramValidation.validatePlannedRest(_plannedRestInput);
    final plannedRestSeconds = restResult is Valid<int?>
        ? restResult.value
        : null;

    emit(ExerciseEditorSaving(draft: current.draft));
    try {
      final exercise = await _findExercise(persistedId);
      if (exercise == null) {
        emit(ExerciseEditorNotFound(exerciseId: persistedId));
        return;
      }
      final updatedExercise = Exercise(
        id: exercise.id,
        exerciseGroupId: exercise.exerciseGroupId,
        position: exercise.position,
        name: current.draft.name.trim(),
        measurementType: current.draft.measurementType,
        metadata: ExerciseMetadata(
          notes: _nullIfBlank(current.draft.metadata.notes),
          videoUrl: _nullIfBlank(current.draft.metadata.videoUrl),
        ),
        plannedRestSeconds: plannedRestSeconds,
        sets: exercise.sets,
        createdAt: exercise.createdAt,
        updatedAt: exercise.updatedAt,
        schemaVersion: exercise.schemaVersion,
      );
      await _programRepository.updateExercise(updatedExercise);
      emit(ExerciseEditorSaved(exerciseId: persistedId));
    } on DomainError catch (e) {
      emit(
        ExerciseEditorEditing(
          draft: current.draft,
          validation: validation,
          lastSaveError: e,
        ),
      );
    }
  }

  Future<Exercise?> _findExercise(String exerciseId) async {
    final programs = await _programRepository.listPrograms();
    for (final program in programs) {
      final days = await _programRepository.listWorkoutDaysForProgram(
        program.id,
      );
      for (final day in days) {
        for (final group in day.exerciseGroups) {
          for (final exercise in group.exercises) {
            if (exercise.id == exerciseId) return exercise;
          }
        }
      }
    }
    return null;
  }

  ExerciseDraft _exerciseToDraft(Exercise exercise) {
    return ExerciseDraft(
      draftId: _uuid.v4(),
      persistedId: exercise.id,
      name: exercise.name,
      measurementType: exercise.measurementType,
      metadata: exercise.metadata,
      plannedRestSeconds: exercise.plannedRestSeconds,
      sets: exercise.sets.map(_setToDraft).toList(),
    );
  }

  PlannedSetDraft _setToDraft(WorkoutSet set) {
    final values = switch (set.plannedValues) {
      PlannedRepBased(:final weightKg, :final reps) =>
        PlannedSetDraftValues.repBased(
          weightInput: weightKg.toString(),
          repsInput: reps.toString(),
        ),
      PlannedTimeBased(:final durationSeconds) =>
        PlannedSetDraftValues.timeBased(
          durationInput: durationSeconds.toString(),
        ),
    };
    return PlannedSetDraft(
      draftId: _uuid.v4(),
      persistedId: set.id,
      values: values,
    );
  }

  PlannedSetDraftValues _zeroValuedSet(MeasurementType type) {
    return switch (type) {
      RepBasedMeasurement() => const PlannedSetDraftValues.repBased(
        weightInput: '0',
        repsInput: '0',
      ),
      TimeBasedMeasurement() => const PlannedSetDraftValues.timeBased(
        durationInput: '0',
      ),
    };
  }

  ExerciseDraftValidation _computeValidation(ExerciseDraft draft) {
    return ExerciseDraftValidation.compute(
      name: draft.name,
      plannedRestInput: _plannedRestInput,
      videoUrl: draft.metadata.videoUrl,
      notes: draft.metadata.notes,
    );
  }

  String? _nullIfBlank(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}
