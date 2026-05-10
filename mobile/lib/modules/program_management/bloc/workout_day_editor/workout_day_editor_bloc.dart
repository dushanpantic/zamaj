import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/schema_versions.dart';
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
    on<WorkoutDayExercisePressed>(_onExercisePressed);
    on<WorkoutDaySavePressed>(_onDaySave);
  }

  final ProgramRepository _programRepository;
  static const _uuid = Uuid();

  WorkoutDay? _baseline;

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
      _baseline = workoutDay;
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
    if (!current.validation.isNameValid) return;

    final baseline = _baseline;
    final persistedId = current.draft.persistedId;
    if (baseline == null || persistedId == null) return;

    for (final group in current.draft.groups) {
      final invariant = _cardinalityInvariant(group);
      if (invariant != null) {
        emit(
          WorkoutDayEditorGroupValidationError(
            draft: current.draft,
            groupDraftId: group.draftId,
            invariant: invariant,
          ),
        );
        return;
      }
    }

    emit(WorkoutDayEditorSaving(draft: current.draft));

    try {
      if (baseline.name.trim() != current.draft.name.trim()) {
        await _programRepository.updateWorkoutDay(
          baseline.copyWith(name: current.draft.name.trim()),
        );
      }

      final baselineGroupsById = {
        for (final g in baseline.exerciseGroups) g.id: g,
      };
      final draftPersistedGroupIds = current.draft.groups
          .where((g) => g.persistedId != null)
          .map((g) => g.persistedId!)
          .toSet();

      for (final baselineGroupId in baselineGroupsById.keys) {
        if (!draftPersistedGroupIds.contains(baselineGroupId)) {
          await _programRepository.deleteExerciseGroup(baselineGroupId);
        }
      }

      for (var i = 0; i < current.draft.groups.length; i++) {
        final group = current.draft.groups[i];
        final persistedGroupId = group.persistedId;

        if (persistedGroupId == null) {
          await _programRepository.createExerciseGroup(
            workoutDayId: persistedId,
            kind: group.kind(),
            exercises: [
              for (var j = 0; j < group.exercises.length; j++)
                _draftExerciseToDomain(
                  group.exercises[j],
                  exerciseGroupId: '',
                  position: j,
                ),
            ],
          );
        } else {
          final baselineGroup = baselineGroupsById[persistedGroupId];
          if (baselineGroup == null) continue;

          final baselineExercisesById = {
            for (final e in baselineGroup.exercises) e.id: e,
          };
          final draftPersistedExerciseIds = group.exercises
              .where((e) => e.persistedId != null)
              .map((e) => e.persistedId!)
              .toSet();

          for (final baselineExerciseId in baselineExercisesById.keys) {
            if (!draftPersistedExerciseIds.contains(baselineExerciseId)) {
              await _programRepository.deleteExercise(baselineExerciseId);
            }
          }

          for (var j = 0; j < group.exercises.length; j++) {
            final exerciseDraft = group.exercises[j];
            final persistedExerciseId = exerciseDraft.persistedId;
            if (persistedExerciseId != null) {
              final baselineExercise =
                  baselineExercisesById[persistedExerciseId];
              if (baselineExercise == null) continue;
              final changed =
                  baselineExercise.name != exerciseDraft.name ||
                  baselineExercise.measurementType !=
                      exerciseDraft.measurementType ||
                  baselineExercise.metadata != exerciseDraft.metadata ||
                  baselineExercise.plannedRestSeconds !=
                      exerciseDraft.plannedRestSeconds;
              if (changed) {
                await _programRepository.updateExercise(
                  baselineExercise.copyWith(
                    name: exerciseDraft.name,
                    measurementType: exerciseDraft.measurementType,
                    metadata: exerciseDraft.metadata,
                    plannedRestSeconds: exerciseDraft.plannedRestSeconds,
                  ),
                );
              }
            }
          }

          for (var j = 0; j < group.exercises.length; j++) {
            final exerciseDraft = group.exercises[j];
            if (exerciseDraft.persistedId == null) {
              await _programRepository.createExercise(
                exerciseGroupId: persistedGroupId,
                name: exerciseDraft.name,
                measurementType: exerciseDraft.measurementType,
                metadata: exerciseDraft.metadata,
                plannedRestSeconds: exerciseDraft.plannedRestSeconds,
              );
            }
          }

          final desiredExerciseOrder = group.exercises
              .where((e) => e.persistedId != null)
              .map((e) => e.persistedId!)
              .toList();
          final baselineExerciseOrder = baselineGroup.exercises
              .map((e) => e.id)
              .where(draftPersistedExerciseIds.contains)
              .toList();
          if (desiredExerciseOrder.isNotEmpty &&
              !_listEquals(desiredExerciseOrder, baselineExerciseOrder)) {
            await _programRepository.reorderExercises(
              persistedGroupId,
              desiredExerciseOrder,
            );
          }

          if (baselineGroup.kind != group.kind()) {
            await _programRepository.updateExerciseGroup(
              ExerciseGroup(
                id: persistedGroupId,
                workoutDayId: baselineGroup.workoutDayId,
                position: baselineGroup.position,
                kind: group.kind(),
                exercises: [
                  for (var j = 0; j < group.exercises.length; j++)
                    _draftExerciseToDomain(
                      group.exercises[j],
                      exerciseGroupId: persistedGroupId,
                      position: j,
                    ),
                ],
                createdAt: baselineGroup.createdAt,
                updatedAt: baselineGroup.updatedAt,
                schemaVersion: baselineGroup.schemaVersion,
              ),
            );
          }
        }
      }

      final reloaded = await _programRepository.getWorkoutDay(persistedId);
      if (reloaded == null) {
        emit(WorkoutDayEditorNotFound(workoutDayId: persistedId));
        return;
      }

      final desiredGroupOrder = _liveGroupIdOrder(current.draft, reloaded);
      final currentGroupOrder = reloaded.exerciseGroups
          .map((g) => g.id)
          .toList();
      if (desiredGroupOrder.isNotEmpty &&
          !_listEquals(desiredGroupOrder, currentGroupOrder)) {
        await _programRepository.reorderExerciseGroups(
          persistedId,
          desiredGroupOrder,
        );
      }

      final finalDay = await _programRepository.getWorkoutDay(persistedId);
      if (finalDay == null) {
        emit(WorkoutDayEditorNotFound(workoutDayId: persistedId));
        return;
      }
      _baseline = finalDay;
      final newDraft = _draftFromWorkoutDay(finalDay);
      emit(
        WorkoutDayEditorEditing(
          draft: newDraft,
          validation: WorkoutDayDraftValidation.of(newDraft),
        ),
      );
    } on ValidationError catch (e) {
      if (e.invariant == 'single_requires_exactly_one_exercise' ||
          e.invariant == 'superset_requires_at_least_two_exercises') {
        emit(
          WorkoutDayEditorGroupValidationError(
            draft: current.draft,
            groupDraftId: current.draft.groups.first.draftId,
            invariant: e.invariant,
          ),
        );
      } else {
        emit(
          WorkoutDayEditorEditing(
            draft: current.draft,
            validation: WorkoutDayDraftValidation.of(current.draft),
            lastSaveError: e,
          ),
        );
      }
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

  String? _cardinalityInvariant(ExerciseGroupDraft group) {
    if (group.exercises.isEmpty) return 'empty_group';
    return null;
  }

  Exercise _draftExerciseToDomain(
    ExerciseDraft draft, {
    required String exerciseGroupId,
    required int position,
  }) {
    final now = DateTime.now().toUtc();
    return Exercise(
      id: draft.persistedId ?? _uuid.v4(),
      exerciseGroupId: exerciseGroupId,
      position: position,
      name: draft.name,
      measurementType: draft.measurementType,
      metadata: draft.metadata,
      plannedRestSeconds: draft.plannedRestSeconds,
      sets: const [],
      createdAt: now,
      updatedAt: now,
      schemaVersion: SchemaVersions.domain,
    );
  }

  List<String> _liveGroupIdOrder(WorkoutDayDraft draft, WorkoutDay reloaded) {
    final reloadedIds = reloaded.exerciseGroups.map((g) => g.id).toSet();
    final ordered = <String>[];
    for (final group in draft.groups) {
      final id = group.persistedId;
      if (id != null && reloadedIds.contains(id)) {
        ordered.add(id);
      }
    }
    if (ordered.length != reloadedIds.length) {
      for (final id in reloadedIds) {
        if (!ordered.contains(id)) ordered.add(id);
      }
    }
    return ordered;
  }

  bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  static WorkoutDayDraft _draftFromWorkoutDay(WorkoutDay workoutDay) {
    return WorkoutDayDraft(
      draftId: workoutDay.id,
      persistedId: workoutDay.id,
      name: workoutDay.name,
      groups: workoutDay.exerciseGroups.map((group) {
        return ExerciseGroupDraft(
          draftId: group.id,
          persistedId: group.id,
          exercises: group.exercises.map((exercise) {
            return ExerciseDraft(
              draftId: exercise.id,
              persistedId: exercise.id,
              name: exercise.name,
              measurementType: exercise.measurementType,
              metadata: exercise.metadata,
              plannedRestSeconds: exercise.plannedRestSeconds,
              sets: exercise.sets.map((set) {
                return PlannedSetDraft(
                  draftId: set.id,
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
