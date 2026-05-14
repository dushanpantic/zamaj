import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/domain.dart';

part 'focus_mode_view_model.freezed.dart';

/// Display-ready projection of the cursor target for the focus screen.
///
/// Built from a [SessionState] by [FocusModeAssembler]. Only populated when
/// the cursor is active; an exhausted cursor is represented at the bloc
/// state level by a dedicated workout-complete state instead.
@freezed
abstract class FocusModeViewModel with _$FocusModeViewModel {
  const factory FocusModeViewModel({
    required String sessionId,
    required String workoutDayName,
    required String sessionExerciseId,
    required String displayExerciseName,
    required ExerciseMetadata? displayMetadata,
    required MeasurementType effectiveMeasurementType,

    /// 0-based index of the set the user is about to log. Matches
    /// `Cursor.active.setIndex`.
    required int currentSetIndex,

    /// Number of planned sets on the planned exercise. May be 0 for
    /// snapshot-only planned exercises that were stripped of sets.
    required int totalPlannedSets,

    /// Always equals `executedSets.length` for the cursor exercise.
    required int completedSetsCount,

    /// Planned values for the current set index, or null if the cursor is
    /// past the planned set list (extra sets being logged on a replaced
    /// exercise).
    required PlannedSetValues? currentPlannedValues,

    /// Pre-formatted "100kg 4 × 8" summary of all planned sets.
    required String plannedSummary,

    /// Identity of the planned set being targeted; copied onto the logged
    /// [ExecutedSet] when known.
    required String? currentPlannedSetIdInSnapshot,

    /// Actual values from the last completed set, used to show "Last: …"
    /// and to seed the editor. Null when [currentSetIndex] == 0.
    required ActualSetValues? lastExecutedValues,

    /// Display name of the next exercise after the cursor (skipping
    /// non-actionable states), or null if none remain.
    required String? upNextExerciseName,

    /// Coach-defined rest, propagated from the planned exercise. Drives the
    /// inline rest-timer planned/remaining display.
    required int? plannedRestSeconds,

    /// True if the cursor exercise is currently in `replaced` state. Drives
    /// the "Replaced from …" annotation.
    required bool isReplaced,

    /// Original planned exercise name; relevant when [isReplaced] is true
    /// so the UI can show "Replaced from <plannedName>".
    required String plannedExerciseName,
  }) = _FocusModeViewModel;
}
