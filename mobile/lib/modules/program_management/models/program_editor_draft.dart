import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/draft_parsing.dart';

part 'program_editor_draft.freezed.dart';
part 'program_editor_draft.g.dart';

@freezed
abstract class ProgramDraft with _$ProgramDraft {
  const ProgramDraft._();

  const factory ProgramDraft({
    required String? programId,
    required String name,
    required List<WorkoutDayDraft> workoutDays,
    required int? schemaVersion,
  }) = _ProgramDraft;

  factory ProgramDraft.fromJson(Map<String, dynamic> json) =>
      _$ProgramDraftFromJson(json);

  ProgramAggregate toAggregate() {
    const uuid = Uuid();
    final now = DateTime.now().toUtc();
    final resolvedProgramId = programId ?? uuid.v4();

    return ProgramAggregate(
      id: resolvedProgramId,
      name: name,
      createdAt: now,
      updatedAt: now,
      schemaVersion: schemaVersion ?? SchemaVersions.domain,
      workoutDays: [
        for (var dayIndex = 0; dayIndex < workoutDays.length; dayIndex++)
          _convertDay(workoutDays[dayIndex], dayIndex, resolvedProgramId, uuid),
      ],
    );
  }

  static WorkoutDayAggregate _convertDay(
    WorkoutDayDraft day,
    int position,
    String programId,
    Uuid uuid,
  ) {
    final dayId = day.persistedId ?? uuid.v4();
    return WorkoutDayAggregate(
      id: dayId,
      programId: programId,
      name: day.name,
      position: position,
      groups: [
        for (var i = 0; i < day.groups.length; i++)
          _convertGroup(day.groups[i], i, dayId, uuid),
      ],
    );
  }

  static ExerciseGroupAggregate _convertGroup(
    ExerciseGroupDraft group,
    int position,
    String workoutDayId,
    Uuid uuid,
  ) {
    final groupId = group.persistedId ?? uuid.v4();
    return ExerciseGroupAggregate(
      id: groupId,
      workoutDayId: workoutDayId,
      kind: group.kind(),
      role: group.role,
      position: position,
      exercises: [
        for (var i = 0; i < group.exercises.length; i++)
          _convertExercise(group.exercises[i], i, groupId, uuid),
      ],
    );
  }

  static ExerciseAggregate _convertExercise(
    ExerciseDraft exercise,
    int position,
    String groupId,
    Uuid uuid,
  ) {
    final exerciseId = exercise.persistedId ?? uuid.v4();
    return ExerciseAggregate(
      id: exerciseId,
      groupId: groupId,
      name: exercise.name,
      measurementType: exercise.measurementType,
      metadata: exercise.metadata,
      plannedRestSeconds: exercise.plannedRestSeconds,
      libraryExerciseId: exercise.libraryExerciseId,
      position: position,
      sets: [
        for (var i = 0; i < exercise.sets.length; i++)
          _convertSet(exercise.sets[i], i, exerciseId, uuid),
      ],
    );
  }

  static WorkoutSetAggregate _convertSet(
    PlannedSetDraft set,
    int position,
    String exerciseId,
    Uuid uuid,
  ) {
    return WorkoutSetAggregate(
      id: set.persistedId ?? uuid.v4(),
      exerciseId: exerciseId,
      values: _toPlannedSetValues(set.values),
      position: position,
    );
  }

  static PlannedSetValues _toPlannedSetValues(PlannedSetDraftValues values) {
    return switch (values) {
      PlannedSetDraftRepBased(:final weightInput, :final repsInput) =>
        PlannedSetValues.repBased(
          weightKg: double.tryParse(weightInput) ?? 0.0,
          repTarget: DraftParsing.parseRepTargetOrZero(repsInput),
        ),
      PlannedSetDraftTimeBased(:final durationInput, :final weightInput) =>
        PlannedSetValues.timeBased(
          durationSeconds: int.tryParse(durationInput) ?? 0,
          weightKg: DraftParsing.parseOptionalWeight(weightInput),
        ),
      PlannedSetDraftBodyweight(:final repsInput) =>
        PlannedSetValues.bodyweight(
          repTarget: DraftParsing.parseRepTargetOrZero(repsInput),
        ),
    };
  }
}

@freezed
abstract class WorkoutDayDraft with _$WorkoutDayDraft {
  const factory WorkoutDayDraft({
    required String draftId,
    required String? persistedId,
    required String name,
    required List<ExerciseGroupDraft> groups,
  }) = _WorkoutDayDraft;

  factory WorkoutDayDraft.fromJson(Map<String, dynamic> json) =>
      _$WorkoutDayDraftFromJson(json);
}

@freezed
abstract class ExerciseGroupDraft with _$ExerciseGroupDraft {
  const ExerciseGroupDraft._();

  const factory ExerciseGroupDraft({
    required String draftId,
    required String? persistedId,
    required List<ExerciseDraft> exercises,
    @Default(ExerciseGroupRole.main) ExerciseGroupRole role,
  }) = _ExerciseGroupDraft;

  factory ExerciseGroupDraft.fromJson(Map<String, dynamic> json) =>
      _$ExerciseGroupDraftFromJson(json);

  ExerciseGroupKind kind() => exercises.length == 1
      ? const ExerciseGroupKind.single()
      : const ExerciseGroupKind.superset();
}

@freezed
abstract class ExerciseDraft with _$ExerciseDraft {
  const factory ExerciseDraft({
    required String draftId,
    required String? persistedId,
    required String name,
    required MeasurementType measurementType,
    required ExerciseMetadata metadata,
    required int? plannedRestSeconds,
    required List<PlannedSetDraft> sets,
    String? libraryExerciseId,
  }) = _ExerciseDraft;

  factory ExerciseDraft.fromJson(Map<String, dynamic> json) =>
      _$ExerciseDraftFromJson(json);
}

@freezed
abstract class PlannedSetDraft with _$PlannedSetDraft {
  const factory PlannedSetDraft({
    required String draftId,
    required String? persistedId,
    required PlannedSetDraftValues values,
  }) = _PlannedSetDraft;

  factory PlannedSetDraft.fromJson(Map<String, dynamic> json) =>
      _$PlannedSetDraftFromJson(json);
}

@Freezed(unionKey: 'type')
sealed class PlannedSetDraftValues with _$PlannedSetDraftValues {
  const factory PlannedSetDraftValues.repBased({
    required String weightInput,
    required String repsInput,
  }) = PlannedSetDraftRepBased;

  const factory PlannedSetDraftValues.timeBased({
    required String durationInput,
    @Default('') String weightInput,
  }) = PlannedSetDraftTimeBased;

  const factory PlannedSetDraftValues.bodyweight({required String repsInput}) =
      PlannedSetDraftBodyweight;

  factory PlannedSetDraftValues.fromJson(Map<String, dynamic> json) =>
      _$PlannedSetDraftValuesFromJson(json);
}

extension PlannedSetDraftBlankness on PlannedSetDraft {
  /// True when every input field is empty — an untouched placeholder row.
  /// Blank rows don't count toward validation and are stripped on save, so
  /// an exercise can be saved with zero sets (e.g. to persist a library link
  /// before planning the sets).
  bool get isBlank => switch (values) {
    PlannedSetDraftRepBased(:final weightInput, :final repsInput) =>
      weightInput.trim().isEmpty && repsInput.trim().isEmpty,
    PlannedSetDraftTimeBased(:final durationInput, :final weightInput) =>
      durationInput.trim().isEmpty && weightInput.trim().isEmpty,
    PlannedSetDraftBodyweight(:final repsInput) => repsInput.trim().isEmpty,
  };
}
