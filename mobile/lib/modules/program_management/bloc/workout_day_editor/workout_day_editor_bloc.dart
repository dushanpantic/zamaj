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
    on<WorkoutDayEditorRefreshed>(_onRefreshed);
    on<WorkoutDayNameChanged>(_onNameChanged);
    on<QuickExerciseAdded>(_onQuickExerciseAdded);
    on<ExerciseGroupDeleted>(_onGroupDeleted);
    on<ExerciseGroupsReordered>(_onGroupsReordered);
    on<ExerciseAddedToGroup>(_onExerciseAddedToGroup);
    on<ExerciseRemovedFromGroup>(_onExerciseRemoved);
    on<ExerciseReorderedWithinGroup>(_onExerciseReordered);
    on<ExerciseDraggedOntoExercise>(_onExerciseDraggedOnto);
    on<SupersetUngrouped>(_onSupersetUngrouped);
  }

  final ProgramRepository _programRepository;
  static const _uuid = Uuid();

  WorkoutDay? _baseline;
  String? _persistedDayId;

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
      _persistedDayId = workoutDay.id;
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

  Future<void> _onRefreshed(
    WorkoutDayEditorRefreshed event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final dayId = _persistedDayId;
    if (dayId == null) return;
    final workoutDay = await _programRepository.getWorkoutDay(dayId);
    if (workoutDay == null) {
      emit(WorkoutDayEditorNotFound(workoutDayId: dayId));
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
    await _persist(emit);
  }

  Future<void> _onQuickExerciseAdded(
    QuickExerciseAdded event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final newExercise = ExerciseDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      name: event.exerciseName,
      measurementType: const MeasurementType.repBased(),
      metadata: ExerciseMetadata.empty,
      plannedRestSeconds: null,
      sets: const [],
    );
    final newGroup = ExerciseGroupDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      exercises: [newExercise],
    );
    final updated = current.draft.copyWith(
      groups: [...current.draft.groups, newGroup],
    );
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
    await _persist(emit, navigateToNewExercise: true);
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
    await _persist(emit);
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
    await _persist(emit);
  }

  Future<void> _onExerciseAddedToGroup(
    ExerciseAddedToGroup event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    final newExercise = ExerciseDraft(
      draftId: _uuid.v4(),
      persistedId: null,
      name: event.exerciseName,
      measurementType: const MeasurementType.repBased(),
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
    await _persist(emit, navigateToNewExercise: true);
  }

  Future<void> _onExerciseRemoved(
    ExerciseRemovedFromGroup event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    var groups = current.draft.groups.map((g) {
      if (g.draftId != event.groupDraftId) return g;
      return g.copyWith(
        exercises: g.exercises
            .where((e) => e.draftId != event.exerciseDraftId)
            .toList(),
      );
    }).toList();
    groups = groups.where((g) => g.exercises.isNotEmpty).toList();
    final updated = current.draft.copyWith(groups: groups);
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
    await _persist(emit);
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
    await _persist(emit);
  }

  Future<void> _onExerciseDraggedOnto(
    ExerciseDraggedOntoExercise event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;
    if (event.sourceGroupDraftId == event.targetGroupDraftId) return;

    ExerciseDraft? sourceExercise;
    var groups = current.draft.groups.map((g) {
      if (g.draftId != event.sourceGroupDraftId) return g;
      sourceExercise = g.exercises
          .where((e) => e.draftId == event.sourceExerciseDraftId)
          .firstOrNull;
      return g.copyWith(
        exercises: g.exercises
            .where((e) => e.draftId != event.sourceExerciseDraftId)
            .toList(),
      );
    }).toList();

    if (sourceExercise == null) return;

    groups = groups.map((g) {
      if (g.draftId != event.targetGroupDraftId) return g;
      final targetIndex = g.exercises.indexWhere(
        (e) => e.draftId == event.targetExerciseDraftId,
      );
      final insertAt = targetIndex >= 0 ? targetIndex + 1 : g.exercises.length;
      final newExercises = List<ExerciseDraft>.from(g.exercises)
        ..insert(insertAt, sourceExercise!);
      return g.copyWith(exercises: newExercises);
    }).toList();

    groups = groups.where((g) => g.exercises.isNotEmpty).toList();

    final updated = current.draft.copyWith(groups: groups);
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
    await _persist(emit);
  }

  Future<void> _onSupersetUngrouped(
    SupersetUngrouped event,
    Emitter<WorkoutDayEditorState> emit,
  ) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;

    final groupIndex = current.draft.groups.indexWhere(
      (g) => g.draftId == event.groupDraftId,
    );
    if (groupIndex < 0) return;
    final group = current.draft.groups[groupIndex];
    if (group.exercises.length < 2) return;

    final newGroups = List<ExerciseGroupDraft>.from(current.draft.groups);
    newGroups.removeAt(groupIndex);

    for (var i = 0; i < group.exercises.length; i++) {
      final exercise = group.exercises[i];
      newGroups.insert(
        groupIndex + i,
        ExerciseGroupDraft(
          draftId: _uuid.v4(),
          persistedId: null,
          exercises: [exercise],
        ),
      );
    }

    final updated = current.draft.copyWith(groups: newGroups);
    emit(current.copyWith(draft: updated, lastSaveError: () => null));
    await _persist(emit);
  }

  Future<void> _persist(
    Emitter<WorkoutDayEditorState> emit, {
    bool navigateToNewExercise = false,
  }) async {
    final current = state;
    if (current is! WorkoutDayEditorEditing) return;

    final baseline = _baseline;
    final persistedId = _persistedDayId;
    if (baseline == null || persistedId == null) return;
    if (!current.validation.isNameValid) return;

    emit(current.copyWith(isSaving: true));

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

      final baselineExerciseGroupOwnership = <String, String>{};
      for (final g in baseline.exerciseGroups) {
        for (final e in g.exercises) {
          baselineExerciseGroupOwnership[e.id] = g.id;
        }
      }

      final draftExerciseGroupOwnership = <String, String>{};
      for (final g in current.draft.groups) {
        if (g.persistedId == null) continue;
        for (final e in g.exercises) {
          if (e.persistedId != null) {
            draftExerciseGroupOwnership[e.persistedId!] = g.persistedId!;
          }
        }
      }

      final movedExerciseIds = <String>{};
      for (final entry in draftExerciseGroupOwnership.entries) {
        final exerciseId = entry.key;
        final newGroupId = entry.value;
        final oldGroupId = baselineExerciseGroupOwnership[exerciseId];
        if (oldGroupId != null && oldGroupId != newGroupId) {
          movedExerciseIds.add(exerciseId);
        }
      }

      for (final baselineGroupId in baselineGroupsById.keys) {
        if (!draftPersistedGroupIds.contains(baselineGroupId)) {
          await _programRepository.deleteExerciseGroup(baselineGroupId);
        }
      }

      final survivingGroupIds = current.draft.groups
          .where((g) => g.persistedId != null)
          .map((g) => g.persistedId!)
          .toList();
      if (survivingGroupIds.isNotEmpty) {
        await _programRepository.reorderExerciseGroups(
          persistedId,
          survivingGroupIds,
        );
      }

      for (final exerciseId in movedExerciseIds) {
        await _programRepository.deleteExercise(exerciseId);
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
            if (!draftPersistedExerciseIds.contains(baselineExerciseId) &&
                !movedExerciseIds.contains(baselineExerciseId)) {
              await _programRepository.deleteExercise(baselineExerciseId);
            }
          }

          for (var j = 0; j < group.exercises.length; j++) {
            final exerciseDraft = group.exercises[j];
            final persistedExerciseId = exerciseDraft.persistedId;
            if (persistedExerciseId != null &&
                !movedExerciseIds.contains(persistedExerciseId)) {
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
            if (exerciseDraft.persistedId == null ||
                movedExerciseIds.contains(exerciseDraft.persistedId)) {
              final created = await _programRepository.createExercise(
                exerciseGroupId: persistedGroupId,
                name: exerciseDraft.name,
                measurementType: exerciseDraft.measurementType,
                metadata: exerciseDraft.metadata,
                plannedRestSeconds: exerciseDraft.plannedRestSeconds,
              );
              for (final setDraft in exerciseDraft.sets) {
                await _programRepository.createSet(
                  exerciseId: created.id,
                  plannedValues: _draftValuesToPlanned(setDraft.values),
                );
              }
            }
          }

          final desiredExerciseOrder = group.exercises
              .where(
                (e) =>
                    e.persistedId != null &&
                    !movedExerciseIds.contains(e.persistedId),
              )
              .map((e) => e.persistedId!)
              .toList();
          final baselineExerciseOrder = baselineGroup.exercises
              .map((e) => e.id)
              .where(
                (id) =>
                    draftPersistedExerciseIds.contains(id) &&
                    !movedExerciseIds.contains(id),
              )
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

      if (navigateToNewExercise) {
        final newExerciseId = _findNewExerciseId(finalDay);
        if (newExerciseId != null) {
          emit(
            WorkoutDayEditorExerciseCreated(
              draft: newDraft,
              validation: WorkoutDayDraftValidation.of(newDraft),
              exerciseId: newExerciseId,
            ),
          );
        }
      }

      emit(
        WorkoutDayEditorEditing(
          draft: newDraft,
          validation: WorkoutDayDraftValidation.of(newDraft),
        ),
      );
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

  String? _findNewExerciseId(WorkoutDay day) {
    final baselineExerciseIds = <String>{};
    if (_baseline != null) {
      for (final g in _baseline!.exerciseGroups) {
        for (final e in g.exercises) {
          baselineExerciseIds.add(e.id);
        }
      }
    }
    for (final g in day.exerciseGroups) {
      for (final e in g.exercises) {
        if (!baselineExerciseIds.contains(e.id)) {
          return e.id;
        }
      }
    }
    if (day.exerciseGroups.isNotEmpty) {
      final lastGroup = day.exerciseGroups.last;
      if (lastGroup.exercises.isNotEmpty) {
        return lastGroup.exercises.last.id;
      }
    }
    return null;
  }

  Exercise _draftExerciseToDomain(
    ExerciseDraft draft, {
    required String exerciseGroupId,
    required int position,
  }) {
    final now = DateTime.now().toUtc();
    final exerciseId = draft.persistedId ?? _uuid.v4();
    return Exercise(
      id: exerciseId,
      exerciseGroupId: exerciseGroupId,
      position: position,
      name: draft.name,
      measurementType: draft.measurementType,
      metadata: draft.metadata,
      plannedRestSeconds: draft.plannedRestSeconds,
      sets: [
        for (var i = 0; i < draft.sets.length; i++)
          WorkoutSet(
            id: draft.sets[i].persistedId ?? _uuid.v4(),
            exerciseId: exerciseId,
            position: i,
            measurementType: draft.measurementType,
            plannedValues: _draftValuesToPlanned(draft.sets[i].values),
            createdAt: now,
            updatedAt: now,
            schemaVersion: SchemaVersions.domain,
          ),
      ],
      createdAt: now,
      updatedAt: now,
      schemaVersion: SchemaVersions.domain,
    );
  }

  static double? _parseOptionalWeight(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    return double.tryParse(trimmed);
  }

  static PlannedSetValues _draftValuesToPlanned(PlannedSetDraftValues values) {
    return switch (values) {
      PlannedSetDraftRepBased(:final weightInput, :final repsInput) =>
        PlannedSetValues.repBased(
          weightKg: double.tryParse(weightInput) ?? 0.0,
          reps: int.tryParse(repsInput) ?? 0,
        ),
      PlannedSetDraftTimeBased(:final durationInput, :final weightInput) =>
        PlannedSetValues.timeBased(
          durationSeconds: int.tryParse(durationInput) ?? 0,
          weightKg: _parseOptionalWeight(weightInput),
        ),
    };
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
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        PlannedSetDraftValues.timeBased(
          durationInput: durationSeconds.toString(),
          weightInput: weightKg == null ? '' : weightKg.toString(),
        ),
    };
  }
}
