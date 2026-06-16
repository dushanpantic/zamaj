import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/program_validation.dart';
import 'package:zamaj/modules/program_management/services/set_input_adjustment.dart';

import 'exercise_editor_event.dart';
import 'exercise_editor_state.dart';

class ExerciseEditorBloc
    extends Bloc<ExerciseEditorEvent, ExerciseEditorState> {
  ExerciseEditorBloc({
    required ProgramRepository programRepository,
    required SessionRepository sessionRepository,
    required ExternalLinkLauncher externalLinkLauncher,
  }) : _programRepository = programRepository,
       _sessionRepository = sessionRepository,
       _externalLinkLauncher = externalLinkLauncher,
       super(const ExerciseEditorInitial()) {
    on<ExerciseEditorOpened>(_onOpened);
    on<ExerciseNameChanged>(_onNameChanged);
    on<ExerciseMeasurementTypeChanged>(_onMeasurementTypeChanged);
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
    on<AllSetsWeightChanged>(_onAllSetsWeightChanged);
    on<AllSetsRepsChanged>(_onAllSetsRepsChanged);
    on<AllSetsDurationChanged>(_onAllSetsDurationChanged);
    on<AllSetsWeightBumped>(_onAllSetsWeightBumped);
    on<AllSetsRepsBumped>(_onAllSetsRepsBumped);
    on<AllSetsDurationBumped>(_onAllSetsDurationBumped);
    on<PlannedSetCountChanged>(_onPlannedSetCountChanged);
    on<AllSetsFlattenedToFirst>(_onAllSetsFlattenedToFirst);
    on<ExerciseSavePressed>(_onSavePressed);
    on<ExerciseLibraryLinked>(_onLibraryLinked);
    on<ExerciseLibraryUnlinked>(_onLibraryUnlinked);
  }

  final ProgramRepository _programRepository;
  final SessionRepository _sessionRepository;
  final ExternalLinkLauncher _externalLinkLauncher;
  final _uuid = const Uuid();

  Exercise? _baselineExercise;
  ExerciseDraft? _baselineDraft;
  String? _baselinePlannedRestInput;
  String? _plannedRestInput;

  /// True when the in-memory draft differs from the loaded baseline. Drives
  /// the back-press "discard changes?" guard on [ExerciseEditorScreen].
  ///
  /// Returns false while the editor is loading, in not-found state, or while
  /// a save is in flight (the save itself will pop the route on completion).
  bool get isDirty {
    final current = state;
    if (current is! ExerciseEditorEditing) return false;
    final baselineDraft = _baselineDraft;
    if (baselineDraft == null) return false;
    if (current.draft != baselineDraft) return true;
    return _plannedRestInput != _baselinePlannedRestInput;
  }

  Future<void> _onOpened(
    ExerciseEditorOpened event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    emit(const ExerciseEditorLoading());
    final exercise = await _programRepository.getExercise(event.exerciseId);
    if (exercise == null) {
      emit(ExerciseEditorNotFound(exerciseId: event.exerciseId));
      return;
    }
    _baselineExercise = exercise;
    var draft = _exerciseToDraft(exercise);
    if (draft.plannedRestSeconds == null) {
      draft = draft.copyWith(plannedRestSeconds: 180);
    }
    if (draft.sets.isEmpty) {
      draft = draft.copyWith(
        sets: [
          PlannedSetDraft(
            draftId: _uuid.v4(),
            persistedId: null,
            values: _emptySet(draft.measurementType),
          ),
        ],
      );
    }
    _plannedRestInput = draft.plannedRestSeconds?.toString() ?? '180';
    _baselineDraft = draft;
    _baselinePlannedRestInput = _plannedRestInput;
    final validation = _computeValidation(draft);
    final recentHistory = await _loadRecentHistory(exercise.libraryExerciseId);
    emit(
      ExerciseEditorEditing(
        draft: draft,
        validation: validation,
        recentHistory: recentHistory,
      ),
    );
  }

  /// Resolves the recent set-history view for the exercise. An unlinked
  /// exercise has no movement identity to aggregate by, so it gets the link
  /// nudge; a linked one gets its [CapHistory] derived from completed sessions.
  Future<RecentHistoryView> _loadRecentHistory(
    String? libraryExerciseId,
  ) async {
    if (libraryExerciseId == null) return const RecentHistoryUnlinked();
    final sessions = await _sessionRepository.listCompletedSessions();
    return RecentHistoryAvailable(
      ExerciseCapHistoryAggregator.computeHistory(
        libraryExerciseId: libraryExerciseId,
        sessions: sessions,
      ),
    );
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

  Future<void> _onMeasurementTypeChanged(
    ExerciseMeasurementTypeChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    if (event.next == current.draft.measurementType) return;
    final reinitializedSets = current.draft.sets
        .map((s) => s.copyWith(values: _emptySet(event.next)))
        .toList();
    final updated = current.draft.copyWith(
      measurementType: event.next,
      sets: reinitializedSets,
    );
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
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
    final values = current.draft.sets.isEmpty
        ? _emptySet(current.draft.measurementType)
        : current.draft.sets.last.values;
    final newSet = PlannedSetDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      values: values,
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
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
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
        final next = switch (s.values) {
          final PlannedSetDraftRepBased rep => rep.copyWith(
            weightInput: event.rawInput,
          ),
          final PlannedSetDraftTimeBased tb => tb.copyWith(
            weightInput: event.rawInput,
          ),
          PlannedSetDraftBodyweight() => s.values,
        };
        return s.copyWith(values: next);
      }).toList(),
    );
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
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
        final next = switch (s.values) {
          final PlannedSetDraftRepBased rep => rep.copyWith(
            repsInput: event.rawInput,
          ),
          final PlannedSetDraftBodyweight bw => bw.copyWith(
            repsInput: event.rawInput,
          ),
          PlannedSetDraftTimeBased() => s.values,
        };
        return s.copyWith(values: next);
      }).toList(),
    );
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
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
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  /// Maps [transform] over every set's values, recomputes validation, and
  /// emits — the shared fan-out path for all uniform "all sets" edits.
  void _mapAllSets(
    Emitter<ExerciseEditorState> emit,
    PlannedSetDraftValues Function(PlannedSetDraftValues values) transform,
  ) {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final updated = current.draft.copyWith(
      sets: current.draft.sets
          .map((s) => s.copyWith(values: transform(s.values)))
          .toList(),
    );
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  Future<void> _onAllSetsWeightChanged(
    AllSetsWeightChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    _mapAllSets(
      emit,
      (values) => switch (values) {
        final PlannedSetDraftRepBased rep => rep.copyWith(
          weightInput: event.rawInput,
        ),
        final PlannedSetDraftTimeBased tb => tb.copyWith(
          weightInput: event.rawInput,
        ),
        PlannedSetDraftBodyweight() => values,
      },
    );
  }

  Future<void> _onAllSetsRepsChanged(
    AllSetsRepsChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    _mapAllSets(
      emit,
      (values) => switch (values) {
        final PlannedSetDraftRepBased rep => rep.copyWith(
          repsInput: event.rawInput,
        ),
        final PlannedSetDraftBodyweight bw => bw.copyWith(
          repsInput: event.rawInput,
        ),
        PlannedSetDraftTimeBased() => values,
      },
    );
  }

  Future<void> _onAllSetsDurationChanged(
    AllSetsDurationChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    _mapAllSets(
      emit,
      (values) => switch (values) {
        final PlannedSetDraftTimeBased tb => tb.copyWith(
          durationInput: event.rawInput,
        ),
        _ => values,
      },
    );
  }

  Future<void> _onAllSetsWeightBumped(
    AllSetsWeightBumped event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    _mapAllSets(
      emit,
      (values) => switch (values) {
        final PlannedSetDraftRepBased rep => rep.copyWith(
          weightInput: SetInputAdjustment.bumpWeight(
            rep.weightInput,
            event.delta,
          ),
        ),
        final PlannedSetDraftTimeBased tb => tb.copyWith(
          weightInput: SetInputAdjustment.bumpWeight(
            tb.weightInput,
            event.delta,
          ),
        ),
        PlannedSetDraftBodyweight() => values,
      },
    );
  }

  Future<void> _onAllSetsRepsBumped(
    AllSetsRepsBumped event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    _mapAllSets(
      emit,
      (values) => switch (values) {
        final PlannedSetDraftRepBased rep => rep.copyWith(
          repsInput: SetInputAdjustment.bumpReps(rep.repsInput, event.delta),
        ),
        final PlannedSetDraftBodyweight bw => bw.copyWith(
          repsInput: SetInputAdjustment.bumpReps(bw.repsInput, event.delta),
        ),
        PlannedSetDraftTimeBased() => values,
      },
    );
  }

  Future<void> _onAllSetsDurationBumped(
    AllSetsDurationBumped event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    _mapAllSets(
      emit,
      (values) => switch (values) {
        final PlannedSetDraftTimeBased tb => tb.copyWith(
          durationInput: SetInputAdjustment.bumpDuration(
            tb.durationInput,
            event.delta,
          ),
        ),
        _ => values,
      },
    );
  }

  Future<void> _onPlannedSetCountChanged(
    PlannedSetCountChanged event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final sets = current.draft.sets;
    final target = event.count.clamp(1, 20);
    if (target == sets.length) return;
    final List<PlannedSetDraft> updatedSets;
    if (target < sets.length) {
      updatedSets = sets.sublist(0, target);
    } else {
      final template = sets.isEmpty
          ? _emptySet(current.draft.measurementType)
          : sets.last.values;
      updatedSets = [
        ...sets,
        for (var i = sets.length; i < target; i++)
          PlannedSetDraft(
            draftId: _uuid.v4(),
            persistedId: null,
            values: template,
          ),
      ];
    }
    final updated = current.draft.copyWith(sets: updatedSets);
    final validation = _computeValidation(updated);
    emit(current.copyWith(draft: updated, validation: validation));
  }

  Future<void> _onAllSetsFlattenedToFirst(
    AllSetsFlattenedToFirst event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    if (current.draft.sets.isEmpty) return;
    final first = current.draft.sets.first.values;
    _mapAllSets(emit, (_) => first);
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
    final baseline = _baselineExercise;
    if (baseline == null) return;

    final restResult = ProgramValidation.validatePlannedRest(_plannedRestInput);
    final plannedRestSeconds = restResult is Valid<int?>
        ? restResult.value
        : null;

    emit(ExerciseEditorSaving(draft: current.draft));
    try {
      final measurementType = current.draft.measurementType;
      final baselineSetsById = {for (final s in baseline.sets) s.id: s};
      final setDrafts = current.draft.sets.where((s) => !s.isBlank).toList();
      final sets = <WorkoutSet>[];
      for (var i = 0; i < setDrafts.length; i++) {
        final setDraft = setDrafts[i];
        final plannedValues = _draftToPlannedValues(
          setDraft.values,
          measurementType,
        );
        final persistedSetId = setDraft.persistedId;
        final baselineSet = persistedSetId != null
            ? baselineSetsById[persistedSetId]
            : null;
        sets.add(
          WorkoutSet(
            id: baselineSet?.id ?? _uuid.v4(),
            exerciseId: baseline.id,
            position: i,
            measurementType: measurementType,
            plannedValues: plannedValues,
            createdAt: baselineSet?.createdAt ?? baseline.createdAt,
            updatedAt: baselineSet?.updatedAt ?? baseline.updatedAt,
            schemaVersion: baselineSet?.schemaVersion ?? baseline.schemaVersion,
          ),
        );
      }

      final updatedExercise = Exercise(
        id: baseline.id,
        exerciseGroupId: baseline.exerciseGroupId,
        position: baseline.position,
        name: current.draft.name.trim(),
        measurementType: measurementType,
        metadata: ExerciseMetadata(
          notes: _nullIfBlank(current.draft.metadata.notes),
          videoUrl: _nullIfBlank(current.draft.metadata.videoUrl),
        ),
        plannedRestSeconds: plannedRestSeconds,
        libraryExerciseId: current.draft.libraryExerciseId,
        sets: sets,
        createdAt: baseline.createdAt,
        updatedAt: baseline.updatedAt,
        schemaVersion: baseline.schemaVersion,
      );
      await _programRepository.updateExercise(updatedExercise);
      emit(ExerciseEditorSaved(exerciseId: persistedId));
    } on DomainError catch (e) {
      emit(
        ExerciseEditorEditing(
          draft: current.draft,
          validation: validation,
          lastSaveError: e,
          controllerSyncRevision: current.controllerSyncRevision,
          recentHistory: current.recentHistory,
        ),
      );
    }
  }

  Future<void> _onLibraryLinked(
    ExerciseLibraryLinked event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    var draft = current.draft.copyWith(
      libraryExerciseId: event.libraryExerciseId,
    );
    if (event.overwriteNameAndVideo) {
      draft = draft.copyWith(
        name: event.libraryName,
        metadata: draft.metadata.copyWith(videoUrl: event.libraryVideoUrl),
      );
    }
    final validation = _computeValidation(draft);
    emit(
      current.copyWith(
        draft: draft,
        validation: validation,
        controllerSyncRevision: event.overwriteNameAndVideo
            ? current.controllerSyncRevision + 1
            : null,
      ),
    );
  }

  Future<void> _onLibraryUnlinked(
    ExerciseLibraryUnlinked event,
    Emitter<ExerciseEditorState> emit,
  ) async {
    final current = state;
    if (current is! ExerciseEditorEditing) return;
    final draft = current.draft.copyWith(libraryExerciseId: null);
    final validation = _computeValidation(draft);
    emit(current.copyWith(draft: draft, validation: validation));
  }

  ExerciseDraft _exerciseToDraft(Exercise exercise) {
    return ExerciseDraft(
      draftId: _uuid.v4(),
      persistedId: exercise.id,
      name: exercise.name,
      measurementType: exercise.measurementType,
      metadata: exercise.metadata,
      plannedRestSeconds: exercise.plannedRestSeconds,
      libraryExerciseId: exercise.libraryExerciseId,
      sets: exercise.sets.map(_setToDraft).toList(),
    );
  }

  PlannedSetDraft _setToDraft(WorkoutSet set) {
    final values = switch (set.plannedValues) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        PlannedSetDraftValues.repBased(
          weightInput: weightKg.toString(),
          repsInput: switch (repTarget) {
            RepTargetFixed(:final reps) => reps.toString(),
            RepTargetRange(:final minReps, :final maxReps) =>
              '$minReps-$maxReps',
          },
        ),
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        PlannedSetDraftValues.timeBased(
          durationInput: durationSeconds.toString(),
          weightInput: weightKg == null ? '' : weightKg.toString(),
        ),
      PlannedBodyweight(:final repTarget) => PlannedSetDraftValues.bodyweight(
        repsInput: switch (repTarget) {
          RepTargetFixed(:final reps) => reps.toString(),
          RepTargetRange(:final minReps, :final maxReps) => '$minReps-$maxReps',
        },
      ),
    };
    return PlannedSetDraft(
      draftId: _uuid.v4(),
      persistedId: set.id,
      values: values,
    );
  }

  PlannedSetDraftValues _emptySet(MeasurementType type) {
    return switch (type) {
      RepBasedMeasurement() => const PlannedSetDraftValues.repBased(
        weightInput: '',
        repsInput: '',
      ),
      TimeBasedMeasurement() => const PlannedSetDraftValues.timeBased(
        durationInput: '',
        weightInput: '',
      ),
      BodyweightMeasurement() => const PlannedSetDraftValues.bodyweight(
        repsInput: '',
      ),
    };
  }

  PlannedSetValues _draftToPlannedValues(
    PlannedSetDraftValues values,
    MeasurementType measurementType,
  ) {
    return switch ((values, measurementType)) {
      (
        PlannedSetDraftRepBased(:final weightInput, :final repsInput),
        RepBasedMeasurement(),
      ) =>
        () {
          final result = ProgramValidation.validateRepBasedSet(
            weightInput: weightInput,
            repsInput: repsInput,
          );
          return switch (result) {
            Valid(:final value) => PlannedSetValues.repBased(
              weightKg: value.weightKg,
              repTarget: value.repTarget,
            ),
            Invalid() => PlannedSetValues.repBased(
              weightKg: 0,
              repTarget: RepTarget.fixed(reps: 0),
            ),
          };
        }(),
      (
        PlannedSetDraftTimeBased(:final durationInput, :final weightInput),
        TimeBasedMeasurement(),
      ) =>
        () {
          final durationResult = ProgramValidation.validateTimeBasedSet(
            durationInput,
          );
          final weightResult = ProgramValidation.validateTimeBasedSetWeight(
            weightInput,
          );
          final durationSeconds = switch (durationResult) {
            Valid(:final value) => value,
            Invalid() => 0,
          };
          final weightKg = switch (weightResult) {
            Valid(:final value) => value,
            Invalid() => null,
          };
          return PlannedSetValues.timeBased(
            durationSeconds: durationSeconds,
            weightKg: weightKg,
          );
        }(),
      (PlannedSetDraftBodyweight(:final repsInput), BodyweightMeasurement()) =>
        () {
          final result = ProgramValidation.validateBodyweightSet(
            repsInput: repsInput,
          );
          return switch (result) {
            Valid(:final value) => PlannedSetValues.bodyweight(
              repTarget: value,
            ),
            Invalid() => PlannedSetValues.bodyweight(
              repTarget: RepTarget.fixed(reps: 0),
            ),
          };
        }(),
      (PlannedSetDraftRepBased(), TimeBasedMeasurement()) =>
        const PlannedSetValues.timeBased(durationSeconds: 0),
      (PlannedSetDraftTimeBased(), RepBasedMeasurement()) =>
        PlannedSetValues.repBased(
          weightKg: 0,
          repTarget: RepTarget.fixed(reps: 0),
        ),
      (PlannedSetDraftRepBased(), BodyweightMeasurement()) =>
        PlannedSetValues.bodyweight(repTarget: RepTarget.fixed(reps: 0)),
      (PlannedSetDraftTimeBased(), BodyweightMeasurement()) =>
        PlannedSetValues.bodyweight(repTarget: RepTarget.fixed(reps: 0)),
      (PlannedSetDraftBodyweight(), RepBasedMeasurement()) =>
        PlannedSetValues.repBased(
          weightKg: 0,
          repTarget: RepTarget.fixed(reps: 0),
        ),
      (PlannedSetDraftBodyweight(), TimeBasedMeasurement()) =>
        const PlannedSetValues.timeBased(durationSeconds: 0),
    };
  }

  ExerciseDraftValidation _computeValidation(ExerciseDraft draft) {
    return ExerciseDraftValidation.compute(
      name: draft.name,
      plannedRestInput: _plannedRestInput,
      videoUrl: draft.metadata.videoUrl,
      notes: draft.metadata.notes,
      measurementType: draft.measurementType,
      sets: draft.sets,
    );
  }

  String? _nullIfBlank(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    return value;
  }
}
