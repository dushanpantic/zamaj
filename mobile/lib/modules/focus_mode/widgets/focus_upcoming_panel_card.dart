import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_panel_actions_menu.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_planned_and_last.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_set_progress.dart';

/// Medium card variant — used for panels whose position is *after* the
/// active. Two-line content: name on top, current set's planned values
/// alongside the set-progress pips. Same tap-to-pin and 3-dot menu
/// affordances as the previous card.
class FocusUpcomingPanelCard extends StatelessWidget {
  const FocusUpcomingPanelCard({
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
    final plannedLabel = focusFormatPlanned(
      panel.currentPlannedValues,
      panel.plannedSummary,
    );
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          key: ValueKey('upcoming-panel-${panel.sessionExerciseId}'),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: AppOpacity.recede3),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(
              color: colors.outline.withValues(alpha: AppOpacity.borderTint),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      panel.displayExerciseName,
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  FocusPanelActionsMenu(state: state, panel: panel),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      plannedLabel,
                      style: typography.caption.copyWith(color: colors.planned),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (isCompleted)
                    AppIcon(
                      Icons.check_circle,
                      color: colors.exerciseCompleted,
                      size: AppIconSize.status,
                    )
                  else
                    FocusSetProgress(
                      completed: panel.completedSetsCount,
                      total: panel.totalPlannedSets,
                      currentIndex: panel.currentSetIndex,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
