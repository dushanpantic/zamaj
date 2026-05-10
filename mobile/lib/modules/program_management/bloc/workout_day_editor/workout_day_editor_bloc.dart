import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

import 'workout_day_editor_event.dart';
import 'workout_day_editor_state.dart';

class WorkoutDayEditorBloc
    extends Bloc<WorkoutDayEditorEvent, WorkoutDayEditorState> {
  WorkoutDayEditorBloc({required ProgramRepository programRepository})
    : _programRepository = programRepository,
      super(const WorkoutDayEditorInitial()) {
    on<WorkoutDayEditorOpened>(_onOpened);
    on<WorkoutDayNameChanged>(_onNameChanged);
    on<ExerciseGroupAdded>(_onGroupAdded);
    on<ExerciseGroupDeleted>(_onGroupDeleted);
    on<ExerciseGroupsReordered>(_onGroupsReordered);
    on<ExerciseAddedToGroup>(_onExerciseAdded);
    on<ExerciseRemovedFromGroup>(_onExerciseRemoved);
    on<ExerciseReorderedWithinGroup>(_onExerciseReordered);
    on<GroupSavePressed>(_onGroupSave);
    on<WorkoutDayExercisePressed>(_onExercisePressed);
    on<WorkoutDaySavePressed>(_onDaySave);
  }

  final ProgramRepository _programRepository;
  static const _uuid = Uuid();

  Future<void> _onOpened(
    WorkoutDayEditorOpened event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    emit(const WorkoutDayEditorLoading());
    try {
      final workoutDay = await _programRepository.getWorkoutDay(
        event.workoutDayId,
      );
      if (workoutDay == null) {
        emit(WorkoutDayEditorNotFound(workoutDayId: event.workoutDayId));
        return;
      }
      final draft = _draftFromWorkoutDay(workoutDay);
      emit(
        WorkoutDayEditorEditing(
          draft: draft,
          validation: WorkoutDayDraftValidation.of(draft),
        ),
      );
    } on DomainError catch (e) {
      emit(
        WorkoutDayEditorEditing(
          draft: WorkoutDayDraft(
            draftId: _uuid.v4(),
            persistedId: event.workoutDayId,
            name: '',
            groups: const [],
          ),
          validation: const WorkoutDayDraftValidation(isNameValid: false),
          lastSaveError: e,
        ),
      );
    }
  }

  Future<void> _onNameChanged(
    WorkoutDayNameChanged event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final updated = current.draft.copyWith(name: event.name);
    emit(
      current.copyWith(
        draft: updated,
        validation: WorkoutDayDraftValidation.of(updated),
        lastSaveError: () => null,
      ),
    );
  }

  Future<void> _onGroupAdded(
    ExerciseGroupAdded event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final newGroup = ExerciseGroupDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      exercises: const [],
    );
    final updated = current.draft.copyWith(
      groups: [...current.draft.groups, newGroup],
    );
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
  }

  Future<void> _onGroupDeleted(
    ExerciseGroupDeleted event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final updated = current.draft.copyWith(
      groups: current.draft.groups
          .where((g) => g.draftId != event.groupDraftId)
          .toList(),
    );
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
  }

  Future<void> _onGroupsReordered(
    ExerciseGroupsReordered event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final groupMap = {for (final g in current.draft.groups) g.draftId: g};
    final reordered = event.orderedGroupDraftIds
        .map((id) => groupMap[id])
        .whereType<ExerciseGroupDraft>()
        .toList();
    final updated = current.draft.copyWith(groups: reordered);
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
  }

  Future<void> _onExerciseAdded(
    ExerciseAddedToGroup event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final newExercise = ExerciseDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      name: event.exerciseName,
      measurementType: event.measurementType,
      metadata: ExerciseMetadata.empty,
      plannedRestSeconds: null,
      sets: const [],
    );
    final updated = current.draft.copyWith(
      groups: current.draft.groups.map((g) {
        if (g.draftId != event.groupDraftId) return g;
        return g.copyWith(exercises: [...g.exercises, newExercise]);
      }).toList(),
    );
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
  }

  Future<void> _onExerciseRemoved(
    ExerciseRemovedFromGroup event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final updated = current.draft.copyWith(
      groups: current.draft.groups.map((g) {
        if (g.draftId != event.groupDraftId) return g;
        return g.copyWith(
          exercises: g.exercises
              .where((e) => e.draftId != event.exerciseDraftId)
              .toList(),
        );
      }).toList(),
    );
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
  }

  Future<void> _onExerciseReordered(
    ExerciseReorderedWithinGroup event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final updated = current.draft.copyWith(
      groups: current.draft.groups.map((g) {
        if (g.draftId != event.groupDraftId) return g;
        final exerciseMap = {for (final e in g.exercises) e.draftId: e};
        final reordered = event.orderedExerciseDraftIds
            .map((id) => exerciseMap[id])
            .whereType<ExerciseDraft>()
            .toList();
        return g.copyWith(exercises: reordered);
      }).toList(),
    );
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
  }

  Future<void> _onGroupSave(
    GroupSavePressed event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;

    final group = current.draft.groups
        .where((g) => g.draftId == event.groupDraftId)
        .firstOrNull;
    if (group == null) return;

    if (group.exercises.isEmpty) {
      emit(
        WorkoutDayEditorGroupValidationError(
          draft: current.draft,
          groupDraftId: event.groupDraftId,
          invariant: 'empty_group',
        ),
      );
      return;
    }

    final kind = group.kind();
    final workoutDayId = current.draft.persistedId;
    if (workoutDayId == null) return;

    try {
      final exercises = group.exercises.map((e) {
        final persistedId = e.persistedId;
        if (persistedId == null) {
          return Exercise(
            id: _uuid.v4(),
            exerciseGroupId: group.persistedId ?? _uuid.v4(),
            position: group.exercises.indexOf(e),
            name: e.name,
            measurementType: e.measurementType,
            metadata: e.metadata,
            plannedRestSeconds: e.plannedRestSeconds,
            sets: const [],
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            schemaVersion: 1,
          );
        }
        return Exercise(
          id: persistedId,
          exerciseGroupId: group.persistedId ?? _uuid.v4(),
          position: group.exercises.indexOf(e),
          name: e.name,
          measurementType: e.measurementType,
          metadata: e.metadata,
          plannedRestSeconds: e.plannedRestSeconds,
          sets: const [],
          createdAt: DateTime.now().toUtc(),
          updatedAt: DateTime.now().toUtc(),
          schemaVersion: 1,
        );
      }).toList();

      final ExerciseGroup savedGroup;
      final persistedGroupId = group.persistedId;
      if (persistedGroupId == null) {
        savedGroup = await _programRepository.createExerciseGroup(
          workoutDayId: workoutDayId,
          kind: kind,
          exercises: exercises,
        );
      } else {
        savedGroup = await _programRepository.updateExerciseGroup(
          ExerciseGroup(
            id: persistedGroupId,
            workoutDayId: workoutDayId,
            position: current.draft.groups.indexWhere(
              (g) => g.draftId == event.groupDraftId,
            ),
            kind: kind,
            exercises: exercises,
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
            schemaVersion: 1,
          ),
        );
      }

      final updatedGroups = current.draft.groups.map((g) {
        if (g.draftId != event.groupDraftId) return g;
        return g.copyWith(
          persistedId: savedGroup.id,
          exercises: [
            for (var i = 0; i < g.exercises.length; i++)
              g.exercises[i].copyWith(
                persistedId: i < savedGroup.exercises.length
                    ? savedGroup.exercises[i].id
                    : g.exercises[i].persistedId,
              ),
          ],
        );
      }).toList();

      final updatedDraft = current.draft.copyWith(groups: updatedGroups);
      emit(
        WorkoutDayEditorEditing(
          draft: updatedDraft,
          validation: WorkoutDayDraftValidation.of(updatedDraft),
        ),
      );
    } on ValidationError catch (e) {
      if (e.invariant == 'single_requires_exactly_one_exercise' ||
          e.invariant == 'superset_requires_at_least_two_exercises') {
        emit(
          WorkoutDayEditorGroupValidationError(
            draft: current.draft,
            groupDraftId: event.groupDraftId,
            invariant: e.invariant,
          ),
        );
      } else {
        emit(current.copyWith(lastSaveError: () => e));
      }
    } on DomainError catch (e) {
      emit(current.copyWith(lastSaveError: () => e));
    }
  }

  Future<void> _onExercisePressed(
    WorkoutDayExercisePressed event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {}

  Future<void> _onDaySave(
    WorkoutDaySavePressed event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;

    final persistedId = current.draft.persistedId;
    if (persistedId == null) return;

    emit(WorkoutDayEditorSaving(draft: current.draft));

    try {
      final workoutDay = await _programRepository.getWorkoutDay(persistedId);
      if (workoutDay == null) {
        emit(WorkoutDayEditorNotFound(workoutDayId: persistedId));
        return;
      }
      await _programRepository.updateWorkoutDay(
        workoutDay.copyWith(name: current.draft.name),
      );
      emit(WorkoutDayEditorSaved(workoutDayId: persistedId));
    } on DomainError catch (e) {
      emit(
        WorkoutDayEditorEditing(
          draft: current.draft,
          validation: WorkoutDayDraftValidation.of(current.draft),
          lastSaveError: e,
        ),
      );
    }
  }

  static WorkoutDayDraft _draftFromWorkoutDay(WorkoutDay workoutDay) {
    return WorkoutDayDraft(
      draftId: _uuid.v4(),
      persistedId: workoutDay.id,
      name: workoutDay.name,
      groups: workoutDay.exerciseGroups.map((group) {
        return ExerciseGroupDraft(
          draftId: _uuid.v4(),
          persistedId: group.id,
          exercises: group.exercises.map((exercise) {
            return ExerciseDraft(
              draftId: _uuid.v4(),
              persistedId: exercise.id,
              name: exercise.name,
              measurementType: exercise.measurementType,
              metadata: exercise.metadata,
              plannedRestSeconds: exercise.plannedRestSeconds,
              sets: exercise.sets.map((set) {
                return PlannedSetDraft(
                  draftId: _uuid.v4(),
                  persistedId: set.id,
                  values: _toSetDraftValues(set.plannedValues),
                );
              }).toList(),
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  static PlannedSetDraftValues _toSetDraftValues(PlannedSetValues values) {
    return switch (values) {
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
  }
}
