import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/aggregate_saver.dart';

import 'program_editor_event.dart';
import 'program_editor_state.dart';

class ProgramEditorBloc extends Bloc<ProgramEditorEvent, ProgramEditorState> {
  ProgramEditorBloc({
    required ProgramRepository programRepository,
    required AggregateSaver aggregateSaver,
  }) : _programRepository = programRepository,
       _aggregateSaver = aggregateSaver,
       super(const ProgramEditorInitial()) {
    on<ProgramEditorOpened>(_onOpened);
    on<ProgramEditorNameChanged>(_onNameChanged);
    on<ProgramEditorWorkoutDayAdded>(_onWorkoutDayAdded);
    on<ProgramEditorWorkoutDayRenamed>(_onWorkoutDayRenamed);
    on<ProgramEditorWorkoutDayDeleteRequested>(_onWorkoutDayDeleteRequested);
    on<ProgramEditorWorkoutDayDeleteConfirmed>(_onWorkoutDayDeleteConfirmed);
    on<ProgramEditorWorkoutDayDeleteCancelled>(_onWorkoutDayDeleteCancelled);
    on<ProgramEditorWorkoutDaysReordered>(_onWorkoutDaysReordered);
    on<ProgramEditorSavePressed>(_onSavePressed);
  }

  final ProgramRepository _programRepository;
  final AggregateSaver _aggregateSaver;
  final _uuid = const Uuid();

  List<WorkoutDay> _baselineWorkoutDays = [];

  Future<void> _onOpened(
    ProgramEditorOpened event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final programId = event.programId;

    if (programId == null) {
      const draft = ProgramDraft(
        programId: null,
        name: '',
        workoutDays: [],
        schemaVersion: null,
      );
      emit(
        ProgramEditorEditing(
          draft: draft,
          isCreateMode: true,
          validation: ProgramDraftValidation.compute(
            name: draft.name,
            isCreateMode: true,
          ),
        ),
      );
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

  void _onNameChanged(
    ProgramEditorNameChanged event,
    Emitter<ProgramEditorState> emit,
  ) {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final updatedDraft = current.draft.copyWith(name: event.name);
    emit(
      current.copyWith(
        draft: updatedDraft,
        validation: ProgramDraftValidation.compute(
          name: event.name,
          isCreateMode: current.isCreateMode,
        ),
      ),
    );
  }

  void _onWorkoutDayAdded(
    ProgramEditorWorkoutDayAdded event,
    Emitter<ProgramEditorState> emit,
  ) {
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
    emit(current.copyWith(draft: updatedDraft));
  }

  void _onWorkoutDayRenamed(
    ProgramEditorWorkoutDayRenamed event,
    Emitter<ProgramEditorState> emit,
  ) {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    final updatedDays = current.draft.workoutDays.map((day) {
      if (day.draftId == event.draftId) {
        return day.copyWith(name: event.name);
      }
      return day;
    }).toList();

    final updatedDraft = current.draft.copyWith(workoutDays: updatedDays);
    emit(current.copyWith(draft: updatedDraft));
  }

  void _onWorkoutDayDeleteRequested(
    ProgramEditorWorkoutDayDeleteRequested event,
    Emitter<ProgramEditorState> emit,
  ) {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    emit(current.copyWith(deletionCandidateDraftId: () => event.draftId));
  }

  void _onWorkoutDayDeleteConfirmed(
    ProgramEditorWorkoutDayDeleteConfirmed event,
    Emitter<ProgramEditorState> emit,
  ) {
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
      ),
    );
  }

  void _onWorkoutDayDeleteCancelled(
    ProgramEditorWorkoutDayDeleteCancelled event,
    Emitter<ProgramEditorState> emit,
  ) {
    final current = state;
    if (current is! ProgramEditorEditing) return;

    emit(current.copyWith(deletionCandidateDraftId: () => null));
  }

  void _onWorkoutDaysReordered(
    ProgramEditorWorkoutDaysReordered event,
    Emitter<ProgramEditorState> emit,
  ) {
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
    emit(current.copyWith(draft: updatedDraft));
  }

  Future<void> _onSavePressed(
    ProgramEditorSavePressed event,
    Emitter<ProgramEditorState> emit,
  ) async {
    final current = state;
    if (current is! ProgramEditorEditing) return;
    if (!current.validation.canSave) return;

    emit(ProgramEditorSaving(draft: current.draft));

    if (current.isCreateMode) {
      await _saveCreate(current, emit);
    } else {
      await _saveEdit(current, emit);
    }
  }

  Future<void> _saveCreate(
    ProgramEditorEditing editing,
    Emitter<ProgramEditorState> emit,
  ) async {
    try {
      final saved = await _aggregateSaver.save(editing.draft);
      emit(ProgramEditorSaved(programId: saved.id));
    } on DomainError catch (e) {
      emit(editing.copyWith(lastSaveError: () => e));
    }
  }

  Future<void> _saveEdit(
    ProgramEditorEditing editing,
    Emitter<ProgramEditorState> emit,
  ) async {
    final draft = editing.draft;
    final programId = draft.programId;
    if (programId == null) return;

    try {
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
        ),
      );
    } on DomainError catch (e) {
      emit(editing.copyWith(lastSaveError: () => e));
    }
  }
}
