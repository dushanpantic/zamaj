import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_panel_actions_menu.dart';

/// Smallest card variant — used for panels whose position is *before*
/// the active. Single line: name + completion count or check. The whole
/// row is a tap target (≥ 48 dp hitbox) that pins this panel as active
/// when it's still loggable; the 3-dot menu remains available for
/// completed panels too so replace / skip / mark-done work without
/// re-focusing first.
class FocusPreviousPanelCard extends StatelessWidget {
  const FocusPreviousPanelCard({
    super.key,
    required this.state,
    required this.panel,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel panel;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isCompleted = !panel.isLoggable;
    final onTap = (isCompleted || !canMutate)
        ? null
        : () {
            Haptics.tap();
            context.read<FocusModeBloc>().add(
              FocusModeFocusedPanelSelected(panel.sessionExerciseId),
            );
          };
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          key: ValueKey('previous-panel-${panel.sessionExerciseId}'),
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMin),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.18),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  panel.displayExerciseName,
                  style: typography.labelSmall.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              if (isCompleted)
                Icon(
                  Icons.check_circle,
                  color: colors.exerciseCompleted,
                  size: 18,
                )
              else
                Text(
                  '${panel.completedSetsCount}/${panel.totalPlannedSets}',
                  style: typography.caption.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              FocusPanelActionsMenu(state: state, panel: panel),
            ],
          ),
        ),
      ),
    );
  }
}
