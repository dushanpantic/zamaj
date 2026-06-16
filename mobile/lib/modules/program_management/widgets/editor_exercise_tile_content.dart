import 'package:flutter/material.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/rest_formatter.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/planned_draft_summary_formatter.dart';

class EditorExerciseTileContent extends StatelessWidget {
  const EditorExerciseTileContent({
    super.key,
    required this.exercise,
    required this.colors,
    this.isWarmup = false,
    this.isInvalid = false,
    this.isBadged = false,
    this.supersetPositionLabel,
  });

  final ExerciseDraft exercise;
  final AppColors colors;
  final bool isWarmup;
  final bool isInvalid;

  /// Whether this exercise capped its current prescription and has not been
  /// advanced — flags the descriptive "needs attention" badge. Never shown for
  /// warmup-group exercises.
  final bool isBadged;
  final String? supersetPositionLabel;

  @override
  Widget build(BuildContext context) {
    final subtitle = PlannedDraftSummaryFormatter.summarize(exercise);
    final hasNoSets = PlannedDraftSummaryFormatter.isNoSetsPlanned(exercise);
    final rest = exercise.plannedRestSeconds;
    final showWarning = isInvalid && !hasNoSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (supersetPositionLabel != null) ...[
              _SupersetPositionBadge(
                label: supersetPositionLabel!,
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
            Flexible(
              child: Text(
                exercise.name.isEmpty ? 'Unnamed exercise' : exercise.name,
                style: AppTypography.standard.label.copyWith(
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWarmup) ...[
              const SizedBox(width: AppSpacing.sm),
              EditorWarmupBadge(colors: colors),
            ],
            if (isBadged && !isWarmup) ...[
              const SizedBox(width: AppSpacing.sm),
              _AttentionBadge(colors: colors),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xxs),
        Row(
          children: [
            Flexible(
              child: Text(
                subtitle,
                style: AppTypography.standard.caption.copyWith(
                  color: hasNoSets ? colors.error : colors.onSurfaceMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showWarning) ...[
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: 'Incomplete sets',
                child: AppIcon(
                  Icons.warning_amber_rounded,
                  color: colors.error,
                  size: AppIconSize.sm,
                  semanticLabel: 'Incomplete sets',
                ),
              ),
            ],
            if (rest != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _RestChip(seconds: rest, colors: colors),
            ],
          ],
        ),
      ],
    );
  }
}

class EditorWarmupBadge extends StatelessWidget {
  const EditorWarmupBadge({super.key, required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.warmup.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: colors.warmup.withValues(alpha: AppOpacity.borderTint),
        ),
      ),
      child: Text(
        'WARMUP',
        style: AppTypography.standard.caption.copyWith(color: colors.warmup),
      ),
    );
  }
}

/// The descriptive "capped" badge: the lift met or exceeded its current
/// prescription on its most recent matching session and has not been advanced.
/// Non-interactive — the enclosing exercise row carries the ≥48 dp tap target.
class _AttentionBadge extends StatelessWidget {
  const _AttentionBadge({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Capped at current prescription',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: 2,
        ),
        decoration: BoxDecoration(
          color: colors.exerciseCompleted.withValues(
            alpha: AppOpacity.tintFill,
          ),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(
            color: colors.exerciseCompleted.withValues(
              alpha: AppOpacity.borderTint,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              Icons.arrow_drop_up,
              color: colors.exerciseCompleted,
              size: AppIconSize.sm,
            ),
            Text(
              'CAPPED',
              style: AppTypography.standard.caption.copyWith(
                color: colors.exerciseCompleted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SupersetPositionBadge extends StatelessWidget {
  const _SupersetPositionBadge({required this.label, required this.colors});

  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.standard.badge.copyWith(
          color: colors.onSurfaceMuted,
        ),
      ),
    );
  }
}

class _RestChip extends StatelessWidget {
  const _RestChip({required this.seconds, required this.colors});

  final int seconds;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          Icons.timer_outlined,
          size: AppIconSize.xs,
          color: colors.onSurfaceMuted,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          RestFormatter.format(seconds),
          style: AppTypography.standard.numericXs.copyWith(
            color: colors.onSurfaceMuted,
          ),
        ),
      ],
    );
  }
}
