import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/models/workout_day_summary.dart';

import 'program_editor_event.dart';
import 'program_editor_state.dart';

/// Processes events one at a time, in arrival order — each handler runs to
/// completion before the next starts. Applied to the persisting mutations so a
/// burst of rapid edits (e.g. fast typing in the name field) can never overlap
/// into interleaved writes with an inconsistent baseline.
EventTransformer<E> _sequential<E>() =>
    (events, mapper) => events.asyncExpand(mapper);

class ProgramEditorBloc extends Bloc<ProgramEditorEvent, ProgramEditorState> {
  ProgramEditorBloc({required ProgramRepository programRepository})
    : _programRepository = programRepository,
      super(const ProgramEditorInitial()) {
    on<ProgramEditorOpened>(_onOpened);
    on<ProgramEditorNameChanged>(_onNameChanged, transformer: _sequential());
    on<ProgramEditorWorkoutDayAdded>(
      _onWorkoutDayAdded,
      transformer: _sequential(),
    );
    on<ProgramEditorWorkoutDayRenamed>(
      _onWorkoutDayRenamed,
      transformer: _sequential(),
    );
    on<ProgramEditorWorkoutDayDeleteRequested>(_onWorkoutDayDeleteRequested);
    on<ProgramEditorWorkoutDayDeleteConfirmed>(
      _onWorkoutDayDeleteConfirmed,
      transformer: _sequential(),
    );
    on<ProgramEditorWorkoutDayDeleteCancelled>(_onWorkoutDayDeleteCancelled);
    on<ProgramEditorWorkoutDayDeleteOptimistic>(_onWorkoutDayDeleteOptimistic);
    on<ProgramEditorWorkoutDayDeleteUndone>(_onWorkoutDayDeleteUndone);
    on<ProgramEditorWorkoutDayDeleteFinalized>(
      _onWorkoutDayDeleteFinalized,
      transformer: _sequential(),
    );
    on<ProgramEditorWorkoutDaysReordered>(
      _onWorkoutDaysReordered,
      transformer: _sequential(),
    );
    on<ProgramEditorWorkoutDayDuplicated>(
      _onWorkoutDayDuplicated,
      transformer: _sequential(),
    );
  }

  /// First N exercise names surfaced in the inline-expand peek.
  static const int _exercisePreviewLimit = 5;

  final ProgramRepository _programRepository;
  final _uuid = const Uuid();

  List<WorkoutDay> _baselineWorkoutDays = [];

  Map<String, WorkoutDaySummary> _summariesFor(List<WorkoutDay> days) {
    return {
      for (final day in days) day.id: WorkoutDaySummary.fromWorkoutDay(day),
    };
  }

  Map<String, List<String>> _previewsFor(List<WorkoutDay> days) {
    return {for (final day in days) day.id: _previewExerciseNames(day)};
  }

  List<String> _previewExerciseNames(WorkoutDay day) {
    final mainNames = <String>[];
    final warmupNames = <String>[];
    for (final group in day.exerciseGroups) {
      for (final exercise in group.exercises) {
        if (group.role == ExerciseGroupRole.warmup) {
          warmupNames.add(exercise.name);
        } else {
          mainNames.add(exercise.name);
        }
      }
    }
    final ordered = [...mainNames, ...warmupNames];
    if (ordered.length <= _exercisePreviewLimit) return ordered;
    return ordered.sublist(0, _exercisePreviewLimit);
  }

  Future<void> _onOpened(
    ProgramEditorOpened event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final programId = event.programId;

    // The editor is edit-only: programs are created name-first from the list,
    // so the editor always opens an existing program. A null id is a defensive
    // dead-end (a deleted/never-created program), never a create draft.
    if (programId == null) {
      emit(const ProgramEditorNotFound(programId: ''));
      return;
    }

    emit(const ProgramEditorLoading());

    try {
      final program = await _programRepository.getProgram(programId);
      if (program == null) {
        emit(ProgramEditorNotFound(programId: programId));
        return;
      }

      final workoutDays = await _programRepository.listWorkoutDaysForProgram(
        programId,
      );
      _baselineWorkoutDays = List.unmodifiable(workoutDays);

      final draft = ProgramDraft(
        programId: program.id,
        name: program.name,
        workoutDays: workoutDays
            .map(
              (day) => WorkoutDayDraft(
                draftId: day.id,
                persistedId: day.id,
                name: day.name,
                groups: [],
              ),
            )
            .toList(),
        schemaVersion: program.schemaVersion,
      );

      emit(
        ProgramEditorEditing(
          draft: draft,
          isCreateMode: false,
          validation: ProgramDraftValidation.compute(
            name: draft.name,
            isCreateMode: false,
          ),
          daySummaries: _summariesFor(workoutDays),
          dayExercisePreviews: _previewsFor(workoutDays),
          programUpdatedAt: program.updatedAt,
        ),
      );
    } on DomainError catch (e) {
      emit(
        ProgramEditorEditing(
          draft: const ProgramDraft(
            programId: null,
            name: '',
            workoutDays: [],
            schemaVersion: null,
          ),
          isCreateMode: false,
          lastSaveError: e,
          validation: ProgramDraftValidation.compute(
            name: '',
            isCreateMode: false,
          ),
        ),
      );
    }
  }

  Future<void> _onNameChanged(
    ProgramEditorNameChanged event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final updatedDraft = current.draft.copyWith(name: event.name);
    final validation = ProgramDraftValidation.compute(
      name: event.name,
      isCreateMode: current.isCreateMode,
    );

    emit(
      current.copyWith(
        draft: updatedDraft,
        validation: validation,
        lastSaveError: () => null,
      ),
    );

    if (validation.canSave) {
      await _persist(emit);
    }
  }

  Future<void> _onWorkoutDayAdded(
    ProgramEditorWorkoutDayAdded event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final newDay = WorkoutDayDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      name: event.name,
      groups: [],
    );

    final updatedDraft = current.draft.copyWith(
      workoutDays: [...current.draft.workoutDays, newDay],
    );
    emit(current.copyWith(draft: updatedDraft, lastSaveError: () => null));

    await _persist(emit);
  }

  Future<void> _onWorkoutDayRenamed(
    ProgramEditorWorkoutDayRenamed event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final updatedDays = current.draft.workoutDays.map((day) {
      if (day.draftId == event.draftId) {
        return day.copyWith(name: event.name);
      }
      return day;
    }).toList();

    final updatedDraft = current.draft.copyWith(workoutDays: updatedDays);
    emit(current.copyWith(draft: updatedDraft, lastSaveError: () => null));

    await _persist(emit);
  }

  void _onWorkoutDayDeleteRequested(
    ProgramEditorWorkoutDayDeleteRequested event,
    Emitter<ProgramEditorState> emit,
  ) {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    emit(current.copyWith(deletionCandidateDraftId: () => event.draftId));
  }

  Future<void> _onWorkoutDayDeleteConfirmed(
    ProgramEditorWorkoutDayDeleteConfirmed event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final updatedDays = current.draft.workoutDays
        .where((day) => day.draftId != event.draftId)
        .toList();

    final updatedDraft = current.draft.copyWith(workoutDays: updatedDays);
    emit(
      current.copyWith(
        draft: updatedDraft,
        deletionCandidateDraftId: () => null,
        lastSaveError: () => null,
      ),
    );

    await _persist(emit);
  }

  void _onWorkoutDayDeleteCancelled(
    ProgramEditorWorkoutDayDeleteCancelled event,
    Emitter<ProgramEditorState> emit,
  ) {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    emit(current.copyWith(deletionCandidateDraftId: () => null));
  }

  Future<void> _onWorkoutDayDeleteOptimistic(
    ProgramEditorWorkoutDayDeleteOptimistic event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final existingPending = current.pendingDeletion;

    // If another deletion is already pending, finalise it first so a single
    // optimistic slot is never overloaded.
    var working = current;
    if (existingPending != null) {
      final after = await _finalisePendingDeletion(working, emit);
      if (after == null) return;
      working = after;
    }

    final days = working.draft.workoutDays;
    final index = days.indexWhere((d) => d.draftId == event.draftId);
    if (index < 0) return;
    final day = days[index];

    final updatedDays = [...days]..removeAt(index);
    final updatedDraft = working.draft.copyWith(workoutDays: updatedDays);

    emit(
      working.copyWith(
        draft: updatedDraft,
        pendingDeletion: () => PendingDeletion(
          draftId: day.draftId,
          restoreIndex: index,
          day: day,
          summary: working.summaryFor(day),
        ),
        deletionCandidateDraftId: () => null,
        lastSaveError: () => null,
      ),
    );
  }

  void _onWorkoutDayDeleteUndone(
    ProgramEditorWorkoutDayDeleteUndone event,
    Emitter<ProgramEditorState> emit,
  ) {
    final current = state;
    if (current is! ProgramEditorEditing) return;
    final pending = current.pendingDeletion;
    if (pending == null) return;

    final restored = [...current.draft.workoutDays];
    final insertAt = pending.restoreIndex.clamp(0, restored.length);
    restored.insert(insertAt, pending.day);

    emit(
      current.copyWith(
        draft: current.draft.copyWith(workoutDays: restored),
        pendingDeletion: () => null,
      ),
    );
  }

  Future<void> _onWorkoutDayDeleteFinalized(
    ProgramEditorWorkoutDayDeleteFinalized event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;
    if (current.pendingDeletion == null) return;
    await _finalisePendingDeletion(current, emit);
  }

  Future<ProgramEditorEditing?> _finalisePendingDeletion(
    ProgramEditorEditing current,
    Emitter<ProgramEditorState> emit,
  ) async {
    emit(current.copyWith(pendingDeletion: () => null));
    await _persist(emit);
    final latest = state;
    return latest is ProgramEditorEditing ? latest : null;
  }

  Future<void> _onWorkoutDaysReordered(
    ProgramEditorWorkoutDaysReordered event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final daysByDraftId = {
      for (final day in current.draft.workoutDays) day.draftId: day,
    };

    final reordered = event.orderedDraftIds
        .map((id) => daysByDraftId[id])
        .whereType<WorkoutDayDraft>()
        .toList();

    final updatedDraft = current.draft.copyWith(workoutDays: reordered);
    emit(current.copyWith(draft: updatedDraft, lastSaveError: () => null));

    await _persist(emit);
  }

  Future<void> _persist(Emitter<ProgramEditorState> emit) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;
    if (!current.validation.canSave) return;

    emit(current.copyWith(isSaving: true, hadUnexpectedSaveError: false));

    try {
      await _persistEdit(emit);
    } on DomainError catch (e) {
      final latest = state;
      if (latest is ProgramEditorEditing) {
        emit(latest.copyWith(isSaving: false, lastSaveError: () => e));
      }
    } catch (_) {
      // Defense-in-depth: an unexpected (non-domain) failure must surface as a
      // non-fatal notice, never an uncaught exception that crashes the editor.
      final latest = state;
      if (latest is ProgramEditorEditing) {
        emit(latest.copyWith(isSaving: false, hadUnexpectedSaveError: true));
      }
    }
  }

  Future<void> _persistEdit(Emitter<ProgramEditorState> emit) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final draft = current.draft;
    final programId = draft.programId;
    if (programId == null) return;

    final baselineIds = _baselineWorkoutDays.map((d) => d.id).toSet();
    final draftPersistedIds = draft.workoutDays
        .where((d) => d.persistedId != null)
        .map((d) => d.persistedId!)
        .toSet();

    final baselineProgram = await _programRepository.getProgram(programId);
    if (baselineProgram != null &&
        baselineProgram.name.trim() != draft.name.trim()) {
      await _programRepository.updateProgram(
        baselineProgram.copyWith(name: draft.name.trim()),
      );
    }

    for (final day in draft.workoutDays) {
      if (day.persistedId == null) {
        await _programRepository.createWorkoutDay(
          programId: programId,
          name: day.name,
        );
      } else {
        final baseline = _baselineWorkoutDays.firstWhere(
          (b) => b.id == day.persistedId,
          orElse: () => throw StateError('Baseline not found'),
        );
        if (baseline.name != day.name) {
          await _programRepository.updateWorkoutDay(
            baseline.copyWith(name: day.name),
          );
        }
      }
    }

    final deletedIds = baselineIds.difference(draftPersistedIds);
    for (final deletedId in deletedIds) {
      await _programRepository.deleteWorkoutDay(deletedId);
    }

    final orderedPersistedIds = draft.workoutDays
        .where((d) => d.persistedId != null)
        .map((d) => d.persistedId!)
        .toList();

    final baselineOrder = _baselineWorkoutDays.map((d) => d.id).toList();
    final reorderedPersistedIds = orderedPersistedIds
        .where(baselineIds.contains)
        .toList();

    final orderChanged =
        reorderedPersistedIds.length != baselineOrder.length ||
        Iterable<int>.generate(
          reorderedPersistedIds.length,
        ).any((i) => reorderedPersistedIds[i] != baselineOrder[i]);

    if (reorderedPersistedIds.isNotEmpty && orderChanged) {
      await _programRepository.reorderWorkoutDays(
        programId,
        reorderedPersistedIds,
      );
    }

    final reloadedProgram = await _programRepository.getProgram(programId);
    if (reloadedProgram == null) {
      emit(ProgramEditorNotFound(programId: programId));
      return;
    }
    final reloadedDays = await _programRepository.listWorkoutDaysForProgram(
      programId,
    );
    _baselineWorkoutDays = List.unmodifiable(reloadedDays);

    final reloadedDraft = ProgramDraft(
      programId: reloadedProgram.id,
      name: reloadedProgram.name,
      workoutDays: reloadedDays
          .map(
            (day) => WorkoutDayDraft(
              draftId: day.id,
              persistedId: day.id,
              name: day.name,
              groups: const [],
            ),
          )
          .toList(),
      schemaVersion: reloadedProgram.schemaVersion,
    );

    emit(
      ProgramEditorEditing(
        draft: reloadedDraft,
        isCreateMode: false,
        validation: ProgramDraftValidation.compute(
          name: reloadedDraft.name,
          isCreateMode: false,
        ),
        daySummaries: _summariesFor(reloadedDays),
        dayExercisePreviews: _previewsFor(reloadedDays),
        programUpdatedAt: reloadedProgram.updatedAt,
      ),
    );
  }

  Future<void> _onWorkoutDayDuplicated(
    ProgramEditorWorkoutDayDuplicated event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final source = current.draft.workoutDays
        .where((d) => d.draftId == event.draftId)
        .firstOrNull;
    final sourcePersistedId = source?.persistedId;
    if (sourcePersistedId == null) return;

    try {
      await _programRepository.duplicateWorkoutDay(sourcePersistedId);
    } on DomainError catch (e) {
      final latest = state;
      if (latest is ProgramEditorEditing) {
        emit(latest.copyWith(lastSaveError: () => e));
      }
      return;
    }

    final programId = current.draft.programId;
    if (programId == null) return;

    final reloadedProgram = await _programRepository.getProgram(programId);
    if (reloadedProgram == null) {
      emit(ProgramEditorNotFound(programId: programId));
      return;
    }
    final reloadedDays = await _programRepository.listWorkoutDaysForProgram(
      programId,
    );
    _baselineWorkoutDays = List.unmodifiable(reloadedDays);

    final reloadedDraft = ProgramDraft(
      programId: reloadedProgram.id,
      name: reloadedProgram.name,
      workoutDays: reloadedDays
          .map(
            (day) => WorkoutDayDraft(
              draftId: day.id,
              persistedId: day.id,
              name: day.name,
              groups: const [],
            ),
          )
          .toList(),
      schemaVersion: reloadedProgram.schemaVersion,
    );

    emit(
      current.copyWith(
        draft: reloadedDraft,
        daySummaries: _summariesFor(reloadedDays),
        dayExercisePreviews: _previewsFor(reloadedDays),
        programUpdatedAt: () => reloadedProgram.updatedAt,
        lastSaveError: () => null,
      ),
    );
  }
}
