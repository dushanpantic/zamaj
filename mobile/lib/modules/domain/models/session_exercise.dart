import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';

part 'session_exercise.freezed.dart';
part 'session_exercise.g.dart';

@freezed
abstract class SessionExercise with _$SessionExercise {
  const SessionExercise._();

  const factory SessionExercise({
    required String id,
    required String sessionId,
    required int position,
    required String plannedExerciseIdInSnapshot,
    required ExerciseState state,
    required List<ExecutedSet> executedSets,
    String? supersetTag,

    /// Inline plan for an exercise added to the session after start — work not
    /// present in the frozen day snapshot. When non-null, the session-exercise
    /// resolves its planned data from here via [EffectiveExercises] rather than
    /// the snapshot (its [plannedExerciseIdInSnapshot] is a synthetic id that is
    /// never looked up). Null for every snapshot-backed exercise.
    AddedExercisePlan? addedPlan,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
  }) = _SessionExercise;

  factory SessionExercise.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$SessionExerciseFromJson(json),
        json,
        'SessionExercise',
      );
}
