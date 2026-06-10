import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/undoable_set.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_rest_timer_bar.dart';

/// Pinned bottom region. Contains the LOG SET button (when an active
/// panel is loggable), the rest timer (when active), and the undo
/// affordance (when a set was just logged). Single primary action per
/// screen — the LOG SET button always targets the active panel.
class FocusPinnedBottomBar extends StatelessWidget {
  const FocusPinnedBottomBar({
    super.key,
    required this.state,
    required this.activePanel,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel? activePanel;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bloc = context.read<FocusModeBloc>();
    final isResting = state.restTimer != null;
    final hasLogButton = activePanel != null;
    if (!hasLogButton && !isResting && state.undoable == null) {
      return const SizedBox.shrink();
    }

    // The undo / rest-timer strip above LOG SET is deliberately compact; pull
    // the top inset in with it so the whole post-log region stays short.
    final hasCompactStrip = state.undoable != null || isResting;
    final topPadding = hasCompactStrip ? AppSpacing.xs : AppSpacing.md;

    // Clamp text scaling on this in-session control bar so the LOG SET button,
    // rest-timer readout, and undo label stay laid out at large font sizes.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        decoration: BoxDecoration(
          color: colors.background,
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          topPadding,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.undoable != null) ...[
              _UndoLastSetButton(undoable: state.undoable!, enabled: canMutate),
              const SizedBox(height: AppSpacing.xxs),
            ],
            if (isResting) ...[
              FocusRestTimerBar(
                timer: state.restTimer!,
                onSkip: () => bloc.add(const FocusModeRestSkipped()),
              ),
              if (activePanel != null) const SizedBox(height: AppSpacing.sm),
            ],
            if (activePanel != null)
              PrimaryActionButton(
                onPressed: () => bloc.add(
                  FocusModeSetCompleted(activePanel!.sessionExerciseId),
                ),
                label: 'LOG SET',
                subLabel: activePanel!.totalPlannedSets > 0
                    ? 'Set ${activePanel!.currentSetIndex + 1} of ${activePanel!.totalPlannedSets}'
                    : null,
                enabled: canMutate,
              ),
          ],
        ),
      ),
    );
  }
}

class _UndoLastSetButton extends StatelessWidget {
  const _UndoLastSetButton({required this.undoable, required this.enabled});

  final UndoableSet undoable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    // Deliberately sub-touchMin, like the rest-timer SKIP (see CLAUDE.md
    // exception): undo is a rarely-used corrective affordance, and keeping it
    // at compactAction height stops the post-log region from growing tall.
    // Do not "fix" it back up to the in-session floor.
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled
            ? () => context.read<FocusModeBloc>().add(
                const FocusModeUndoRequested(),
              )
            : null,
        icon: const AppIcon(Icons.undo, size: AppIconSize.sm),
        label: Text('Undo last set on ${undoable.exerciseDisplayName}'),
        style: TextButton.styleFrom(
          foregroundColor: colors.onSurfaceMuted,
          minimumSize: const Size(0, AppSpacing.compactAction),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
      ),
    );
  }
}
