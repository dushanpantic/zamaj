import 'package:flutter/material.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';

class FocusPanelHeader extends StatelessWidget {
  const FocusPanelHeader({super.key, required this.panel});

  final FocusModeViewModel panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isWarmup = panel.plannedGroupRole == ExerciseGroupRole.warmup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWarmup) ...[
          _WarmupPill(colors: colors),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          panel.displayExerciseName,
          style: typography.title.copyWith(color: colors.onBackground),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (panel.isReplaced) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Replaced from "${panel.plannedExerciseName}"',
            style: typography.caption.copyWith(color: colors.exerciseReplaced),
          ),
        ],
      ],
    );
  }
}

class _WarmupPill extends StatelessWidget {
  const _WarmupPill({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.warmup.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: colors.warmup.withValues(alpha: AppOpacity.borderTint),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AppIcon(
            Icons.local_fire_department,
            size: AppIconSize.xs,
            color: colors.warmup,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            'WARMUP',
            style: AppTypography.standard.caption.copyWith(
              color: colors.warmup,
            ),
          ),
        ],
      ),
    );
  }
}
