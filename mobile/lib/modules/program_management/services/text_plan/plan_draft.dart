import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

part 'plan_draft.freezed.dart';

@freezed
abstract class PlanDraft with _$PlanDraft {
  const factory PlanDraft({
    required String programName,
    required List<PlanDraftWorkoutDay> workoutDays,
  }) = _PlanDraft;
}

@freezed
abstract class PlanDraftWorkoutDay with _$PlanDraftWorkoutDay {
  const factory PlanDraftWorkoutDay({
    required String name,
    required List<PlanDraftGroup> groups,
  }) = _PlanDraftWorkoutDay;
}

@freezed
abstract class PlanDraftGroup with _$PlanDraftGroup {
  const factory PlanDraftGroup({required List<PlanDraftExercise> exercises}) =
      _PlanDraftGroup;
}

@freezed
abstract class PlanDraftExercise with _$PlanDraftExercise {
  const factory PlanDraftExercise({
    required String draftId,
    required String name,
    required int? plannedRestSeconds,
    required String? notes,
    required String? videoUrl,
    required List<PlanDraftSet> sets,
    required List<PlanParseWarning> warnings,
  }) = _PlanDraftExercise;
}

@Freezed(unionKey: 'type')
sealed class PlanDraftSet with _$PlanDraftSet {
  const factory PlanDraftSet.repBased({
    required int count,
    required int reps,
    required double weightKg,
  }) = PlanDraftSetRepBased;

  const factory PlanDraftSet.timeBased({
    required int count,
    required int durationSeconds,
    double? weightKg,
  }) = PlanDraftSetTimeBased;
}
