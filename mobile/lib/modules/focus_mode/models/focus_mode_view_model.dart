import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/domain.dart';

part 'focus_mode_view_model.freezed.dart';

/// Display-ready projection of one panel inside a focused group.
///
/// One [FocusModeViewModel] per visible session exercise. Built by
/// [FocusModeAssembler.assemble] alongside the parent [FocusModeGroupViewModel].
@freezed
abstract class FocusModeViewModel with _$FocusModeViewModel {
  const factory FocusModeViewModel({
    required String sessionExerciseId,
    required String displayExerciseName,
    required ExerciseMetadata? displayMetadata,
    required MeasurementType effectiveMeasurementType,

    /// 0-based index of the set the user is about to log on this exercise.
    /// Equals `executedSets.length` for loggable panels; equals
    /// `plannedSetCount` for completed panels (past the last planned slot).
    required int currentSetIndex,

    /// Number of planned sets for this exercise. May be 0 for snapshot-only
    /// planned exercises that were stripped of sets.
    required int totalPlannedSets,

    /// Always equals `executedSets.length` for the panel exercise.
    required int completedSetsCount,

    /// Planned values for the current set index, or null when the panel is
    /// past the planned set list (e.g. completed, or extra sets on a
    /// replaced exercise).
    required PlannedSetValues? currentPlannedValues,

    /// Pre-formatted "100kg 4 × 8" summary of all planned sets.
    required String plannedSummary,

    /// Identity of the planned set being targeted; copied onto the logged
    /// [ExecutedSet] when known.
    required String? currentPlannedSetIdInSnapshot,

    /// Actual values from the last completed set on this exercise.
    required ActualSetValues? lastExecutedValues,

    /// Coach-defined rest, propagated from the planned exercise. Drives the
    /// shared rest-timer's planned/remaining display.
    required int? plannedRestSeconds,

    /// True if the panel exercise is currently in `replaced` state.
    required bool isReplaced,

    /// Original planned exercise name; relevant when [isReplaced] is true
    /// so the UI can show "Replaced from <plannedName>".
    required String plannedExerciseName,

    /// True when the user can still log a working set on this exercise —
    /// i.e. state is `unfinished` or `replaced` and `executedSets.length <
    /// plannedSetCount`. False for completed/skipped panels.
    required bool isLoggable,
    @Default(ExerciseGroupRole.main) ExerciseGroupRole plannedGroupRole,
  }) = _FocusModeViewModel;
}
