import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

/// Pinned bottom action bar for a loaded session: two secondary icon
/// buttons (note / extra work) and a primary `Focus: <name>` button.
class WorkoutOverviewBottomBar extends StatelessWidget {
  const WorkoutOverviewBottomBar({
    super.key,
    required this.state,
    required this.currentExerciseName,
    required this.onAddNote,
    required this.onAddExtraWork,
    required this.onFocusMode,
  });

  final WorkoutOverviewLoaded state;

  /// Display name of the exercise the Focus button will open, or null when
  /// there's no open target. Shown as `Focus: <name>` so the user can
  /// confirm the target before tapping.
  final String? currentExerciseName;
  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;
  final VoidCallback onFocusMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final hasOpenTarget = state.sessionState.openTargets.isNotEmpty;
    final canMutate = !state.isEnded && !state.mutationInFlight;
    final label = currentExerciseName == null
        ? 'Focus'
        : 'Focus: $currentExerciseName';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        child: Row(
          children: [
            _SecondaryActionButton(
              icon: Icons.sticky_note_2_outlined,
              tooltip: 'Add note',
              onPressed: canMutate ? onAddNote : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            _SecondaryActionButton(
              icon: Icons.add_task,
              tooltip: 'Add extra work',
              onPressed: canMutate ? onAddExtraWork : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: hasOpenTarget && !state.isEnded ? onFocusMode : null,
                icon: const AppIcon(
                  Icons.center_focus_strong,
                  size: AppIconSize.md,
                ),
                label: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square 48dp icon button used in the bottom action bar for secondary
/// actions (Note, Extra). Outlined to read as a peer of the primary
/// FilledButton next to it, sized to satisfy [AppSpacing.touchMin].
class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.touchMin,
      height: AppSpacing.touchMin,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(AppSpacing.touchMin),
          ),
          child: AppIcon(icon, size: AppIconSize.lg, semanticLabel: tooltip),
        ),
      ),
    );
  }
}
