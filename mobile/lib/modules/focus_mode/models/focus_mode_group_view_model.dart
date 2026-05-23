import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';

part 'focus_mode_group_view_model.freezed.dart';

/// Display-ready projection of the focused group on the focus screen.
///
/// A group is either a single non-superset exercise (`supersetTag == null`,
/// `panels.length == 1`) or a contiguous run of session exercises sharing
/// the same `supersetTag`. Built by [FocusModeAssembler.assemble].
@freezed
abstract class FocusModeGroupViewModel with _$FocusModeGroupViewModel {
  const factory FocusModeGroupViewModel({
    required String sessionId,
    required String workoutDayName,

    /// Shared superset tag, or null when the group is a single exercise.
    required String? supersetTag,

    /// Panels in this group, in position order. Includes only exercises
    /// that are still loggable or completed — skipped exercises are hidden
    /// from focus mode.
    required List<FocusModeViewModel> panels,

    /// Display name of the next group past this one — either a single
    /// exercise name or a "Superset (A + B)" label. Null when this is the
    /// last group with any open or completed panels.
    required String? upNextGroupLabel,

    /// Session-exercise id of the first loggable exercise in the next
    /// group, used as the anchor when the user taps "switch to next".
    /// Null when no next group has open targets.
    required String? upNextGroupAnchorId,

    /// Session-exercise id of the panel that should render as ACTIVE
    /// (full editor + target of the pinned LOG SET button). Equals the
    /// only loggable panel for singles; chosen by auto-rotation or by a
    /// user pin in supersets. Null when no panel in the group is
    /// loggable (terminal group; bloc transitions away).
    required String? activeSessionExerciseId,

    /// True when [activeSessionExerciseId] was chosen by the user via a
    /// manual pin, false when chosen by auto-rotation. Used for
    /// analytics/diagnostics only; UI doesn't need to differentiate.
    @Default(false) bool activeIsUserPinned,
  }) = _FocusModeGroupViewModel;
}

/// One entry in the "switch exercise" picker — a target the user can jump
/// to without leaving focus mode. Built by [FocusModeAssembler.listSwitchOptions].
class FocusModeSwitchOption {
  const FocusModeSwitchOption({
    required this.anchorSessionExerciseId,
    required this.label,
    required this.isSuperset,
    required this.isCurrent,
  });

  /// Pass this id back into [FocusModeGroupSwitched] to refocus on the
  /// group. Always points at the first member of the target group.
  final String anchorSessionExerciseId;

  /// Display label — exercise name for singles, "A + B" for supersets.
  final String label;

  final bool isSuperset;

  /// True when this option represents the currently-focused group.
  final bool isCurrent;
}
