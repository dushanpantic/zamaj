import 'package:uuid/uuid.dart';
import 'package:zamaj/core/clock.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';

abstract final class PlanDraftToAggregate {
  static ProgramDraft convert(
    PlanDraft draft, {
    required Uuid idGenerator,
    required AppClock clock,
  }) {
    return ProgramDraft(
      programId: null,
      schemaVersion: null,
      name: draft.programName,
      workoutDays: draft.workoutDays
          .map((day) => _convertDay(day, idGenerator))
          .toList(),
    );
  }

  static WorkoutDayDraft _convertDay(
    PlanDraftWorkoutDay day,
    Uuid idGenerator,
  ) {
    return WorkoutDayDraft(
      draftId: idGenerator.v4(),
      persistedId: null,
      name: day.name,
      groups: day.groups
          .map((group) => _convertGroup(group, idGenerator))
          .toList(),
    );
  }

  static ExerciseGroupDraft _convertGroup(
    PlanDraftGroup group,
    Uuid idGenerator,
  ) {
    return ExerciseGroupDraft(
      draftId: idGenerator.v4(),
      persistedId: null,
      exercises: group.exercises
          .map((exercise) => _convertExercise(exercise, idGenerator))
          .toList(),
    );
  }

  static ExerciseDraft _convertExercise(
    PlanDraftExercise exercise,
    Uuid idGenerator,
  ) {
    final sets = exercise.sets;
    final measurementType = sets.isEmpty
        ? const MeasurementType.repBased()
        : switch (sets.first) {
            PlanDraftSetRepBased() => const MeasurementType.repBased(),
            PlanDraftSetTimeBased() => const MeasurementType.timeBased(),
            PlanDraftSetBodyweight() => const MeasurementType.bodyweight(),
          };

    return ExerciseDraft(
      draftId: idGenerator.v4(),
      persistedId: null,
      name: exercise.name,
      measurementType: measurementType,
      metadata: ExerciseMetadata(
        notes: exercise.notes,
        videoUrl: exercise.videoUrl,
      ),
      plannedRestSeconds: exercise.plannedRestSeconds,
      sets: sets.expand((set) => _convertSet(set, idGenerator)).toList(),
    );
  }

  static Iterable<PlannedSetDraft> _convertSet(
    PlanDraftSet set,
    Uuid idGenerator,
  ) {
    return switch (set) {
      PlanDraftSetRepBased(:final count, :final repTarget, :final weightKg) =>
        List.generate(
          count,
          (_) => PlannedSetDraft(
            draftId: idGenerator.v4(),
            persistedId: null,
            values: PlannedSetDraftValues.repBased(
              weightInput: WeightFormatter.formatKg(weightKg),
              repsInput: switch (repTarget) {
                RepTargetFixed(:final reps) => reps.toString(),
                RepTargetRange(:final minReps, :final maxReps) =>
                  '$minReps-$maxReps',
              },
            ),
          ),
        ),
      PlanDraftSetTimeBased(
        :final count,
        :final durationSeconds,
        :final weightKg,
      ) =>
        List.generate(
          count,
          (_) => PlannedSetDraft(
            draftId: idGenerator.v4(),
            persistedId: null,
            values: PlannedSetDraftValues.timeBased(
              durationInput: durationSeconds.toString(),
              weightInput: weightKg == null
                  ? ''
                  : WeightFormatter.formatKg(weightKg),
            ),
          ),
        ),
      PlanDraftSetBodyweight(:final count, :final repTarget) => List.generate(
        count,
        (_) => PlannedSetDraft(
          draftId: idGenerator.v4(),
          persistedId: null,
          values: PlannedSetDraftValues.bodyweight(
            repsInput: switch (repTarget) {
              RepTargetFixed(:final reps) => reps.toString(),
              RepTargetRange(:final minReps, :final maxReps) =>
                '$minReps-$maxReps',
            },
          ),
        ),
      ),
    };
  }
}
