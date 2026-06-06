import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/workout_overview.dart';

/// Read-only card for one overview group on the post-session review screen:
/// a single exercise, or a superset of two-or-more exercises rendered together.
///
/// Reuses the [SupersetGroupViewModel] the in-session assembler already
/// produces (via [ExerciseViewModelAssembler.assembleReadOnly]); it never
/// mutates state, so unlike the in-session card it has no callbacks.
class SessionDetailGroupCard extends StatelessWidget {
  const SessionDetailGroupCard({super.key, required this.group});

  final SupersetGroupViewModel group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline, width: AppStroke.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      child: switch (group) {
        SingleGroupViewModel(:final exercise) => _Exercise(viewModel: exercise),
        SupersetGroup(:final exercises) => _Superset(exercises: exercises),
      },
    );
  }
}

class _Superset extends StatelessWidget {
  const _Superset({required this.exercises});

  final List<ExerciseViewModel> exercises;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            AppIcon(
              Icons.link,
              size: AppIconSize.sm,
              color: colors.onSurfaceMuted,
            ),
            const SizedBox(width: AppSpacing.xs),
            Text(
              'Superset'.toUpperCase(),
              style: AppTypography.standard.overline.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        for (var i = 0; i < exercises.length; i++) ...[
          if (i > 0) const Divider(height: AppSpacing.lg),
          _Exercise(viewModel: exercises[i]),
        ],
      ],
    );
  }
}

class _Exercise extends StatelessWidget {
  const _Exercise({required this.viewModel});

  final ExerciseViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final state = viewModel.sessionExercise.state;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                viewModel.displayName,
                style: typography.titleSmall.copyWith(color: colors.onSurface),
              ),
            ),
            if (viewModel.plannedGroupRole == ExerciseGroupRole.warmup) ...[
              const SizedBox(width: AppSpacing.sm),
              StatusBadge.icon(
                icon: Icons.local_fire_department,
                color: colors.warmup,
                label: 'Warmup',
              ),
            ],
            const SizedBox(width: AppSpacing.sm),
            _StateBadge(state: state, colors: colors),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          viewModel.plannedSummary,
          style: typography.caption.copyWith(color: colors.onSurfaceMuted),
        ),
        if (state is ReplacedState) ...[
          const SizedBox(height: AppSpacing.xxs),
          Text(
            'Replaced from "${viewModel.plannedExerciseName}"',
            style: typography.caption.copyWith(color: colors.exerciseReplaced),
          ),
        ],
        const Divider(height: AppSpacing.lg),
        for (final row in viewModel.setRows)
          _SetLine(
            row: row,
            measurementType: viewModel.effectiveMeasurementType,
            colors: colors,
            typography: typography,
          ),
      ],
    );
  }
}

/// One "Set N — planned ↔ actual" line. The planned column reads from the
/// frozen snapshot (muted accent), the actual column from what was logged
/// (bright accent), with a check when the set was completed and a hollow dot
/// when it was not (e.g. a skipped exercise or an unfinished planned set).
class _SetLine extends StatelessWidget {
  const _SetLine({
    required this.row,
    required this.measurementType,
    required this.colors,
    required this.typography,
  });

  final SetRowViewModel row;
  final MeasurementType measurementType;
  final AppColors colors;
  final AppTypography typography;

  /// Matches the in-session set row's leading label column so single- and
  /// double-digit set numbers share one width.
  static const double _setLabelWidth = AppSpacing.xl + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final executed = row.executedSet;
    final actualText = executed == null
        ? '—'
        : SetValueFormatter.formatActual(executed.actualValues);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          SizedBox(
            width: _setLabelWidth,
            child: Text(
              'Set ${row.position + 1}',
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              SetValueFormatter.formatPlanned(
                row.plannedValues,
                measurementType,
              ),
              style: typography.numericSm.copyWith(color: colors.planned),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            child: AppIcon(
              Icons.arrow_forward,
              size: AppIconSize.sm,
              color: colors.onSurfaceMuted,
            ),
          ),
          Expanded(
            child: Text(
              actualText,
              style: typography.numericSm.copyWith(
                color: executed != null ? colors.actual : colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          AppIcon(
            executed != null ? Icons.check_circle : Icons.circle_outlined,
            size: AppIconSize.status,
            color: executed != null
                ? colors.exerciseCompleted
                : colors.onSurfaceMuted,
          ),
        ],
      ),
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, required this.colors});

  final ExerciseState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      CompletedState() => StatusBadge.icon(
        icon: Icons.check_circle,
        color: colors.exerciseCompleted,
        label: 'Done',
      ),
      SkippedState() => StatusBadge.pill(
        label: 'Skipped',
        color: colors.exerciseSkipped,
      ),
      ReplacedState() => StatusBadge.pill(
        label: 'Replaced',
        color: colors.exerciseReplaced,
      ),
      UnfinishedState() => const SizedBox.shrink(),
    };
  }
}
