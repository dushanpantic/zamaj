import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

/// Pinned bottom action bar for a loaded session: two secondary icon
/// buttons (note / extra work) and a primary `Focus` button. The on-screen
/// accent border marks which exercise(s) Focus will open, so the button
/// stays a plain verb rather than naming a (possibly truncated, and for
/// supersets incomplete) target.
class WorkoutOverviewBottomBar extends StatelessWidget {
  const WorkoutOverviewBottomBar({
    super.key,
    required this.state,
    required this.onAddNote,
    required this.onAddExtraWork,
    required this.onFocusMode,
  });

  final WorkoutOverviewLoaded state;

  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;
  final VoidCallback onFocusMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final hasOpenTarget = state.sessionState.openTargets.isNotEmpty;
    final canMutate = !state.isEnded && !state.mutationInFlight;

    // Clamp text scaling on this in-session control bar so the Focus label and
    // Note/Extra icons stay laid out at large accessibility font sizes.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: SafeArea(
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
                  onPressed: hasOpenTarget && !state.isEnded
                      ? onFocusMode
                      : null,
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(0, AppInSessionSize.controlMin),
                    textStyle: AppTypography.standard.actionLabel,
                  ),
                  icon: const AppIcon(
                    Icons.center_focus_strong,
                    size: AppIconSize.lg,
                  ),
                  label: const Text('Focus'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Square 56dp icon button used in the bottom action bar for secondary
/// actions (Note, Extra). Outlined to read as a peer of the primary
/// FilledButton next to it, sized to the live-session
/// [AppInSessionSize.controlMin] floor (this bar is on the sweaty-hands
/// surface, so 56 dp, not the ambient 48 dp [AppSpacing.touchMin]).
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
      width: AppInSessionSize.controlMin,
      height: AppInSessionSize.controlMin,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(AppInSessionSize.controlMin),
          ),
          child: AppIcon(icon, size: AppIconSize.lg, semanticLabel: tooltip),
        ),
      ),
    );
  }
}
