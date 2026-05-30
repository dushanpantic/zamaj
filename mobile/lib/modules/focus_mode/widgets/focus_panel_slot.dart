import 'package:flutter/material.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_group_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_current_panel_card.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_previous_panel_card.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_upcoming_panel_card.dart';

/// Position-relative role of a panel within its group. Derived from the
/// panel's index versus the group's `activeSessionExerciseId` so the UI
/// can render three visual sizes (previous → current → upcoming) without
/// reordering panels as the active rotates.
enum FocusPanelRole { previous, current, upcoming }

FocusPanelRole focusPanelRoleFor(
  FocusModeGroupViewModel group,
  int panelIndex,
) {
  final activeId = group.activeSessionExerciseId;
  if (activeId == null) return FocusPanelRole.previous;
  final activeIndex = group.panels.indexWhere(
    (p) => p.sessionExerciseId == activeId,
  );
  if (activeIndex < 0) return FocusPanelRole.upcoming;
  if (panelIndex == activeIndex) return FocusPanelRole.current;
  return panelIndex < activeIndex
      ? FocusPanelRole.previous
      : FocusPanelRole.upcoming;
}

/// Dispatches a panel to the right card variant for its role and wraps
/// the result in `AnimatedSize` so a role change (e.g. when the active
/// rotates after a logged set) animates as an in-place resize instead of
/// a translation.
class FocusPanelSlot extends StatelessWidget {
  const FocusPanelSlot({
    super.key,
    required this.state,
    required this.panel,
    required this.role,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel panel;
  final FocusPanelRole role;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppDuration.slow,
      curve: AppCurve.emphasized,
      alignment: Alignment.topCenter,
      child: switch (role) {
        FocusPanelRole.previous => FocusPreviousPanelCard(
          state: state,
          panel: panel,
          canMutate: canMutate,
        ),
        FocusPanelRole.current => FocusCurrentPanelCard(
          state: state,
          panel: panel,
          canMutate: canMutate,
        ),
        FocusPanelRole.upcoming => FocusUpcomingPanelCard(
          state: state,
          panel: panel,
          canMutate: canMutate,
        ),
      },
    );
  }
}
