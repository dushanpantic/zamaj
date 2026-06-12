import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/workout_overview.dart';

/// Opens the post-session set-value editor for one logged set, seeded with its
/// current values. Wired by the screen (which holds the bloc) and threaded down
/// to the editable set line; `null` keeps the card purely read-only.
typedef SessionDetailEditSet =
    void Function({
      required String executedSetId,
      required ActualSetValues currentValues,
      required MeasurementType measurementType,
      required String title,
    });

/// Card for one overview group on the post-session review screen: a single
/// exercise, or a superset of two-or-more exercises rendered together.
///
/// Reuses the [SupersetGroupViewModel] the in-session assembler already
/// produces (via [ExerciseViewModelAssembler.assembleReadOnly]). Read-only by
/// default; when [onEditSet] is non-null (an in-week session), each logged set
/// line's actual-value cell becomes tappable to correct its values.
class SessionDetailGroupCard extends StatelessWidget {
  const SessionDetailGroupCard({
    super.key,
    required this.group,
    this.onEditSet,
  });

  final SupersetGroupViewModel group;
  final SessionDetailEditSet? onEditSet;

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
        SingleGroupViewModel(:final exercise) => _Exercise(
          viewModel: exercise,
          onEditSet: onEditSet,
        ),
        SupersetGroup(:final exercises) => _Superset(
          exercises: exercises,
          onEditSet: onEditSet,
        ),
      },
    );
  }
}

class _Superset extends StatelessWidget {
  const _Superset({required this.exercises, this.onEditSet});

  final List<ExerciseViewModel> exercises;
  final SessionDetailEditSet? onEditSet;

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
          _Exercise(viewModel: exercises[i], onEditSet: onEditSet),
        ],
      ],
    );
  }
}

class _Exercise extends StatelessWidget {
  const _Exercise({required this.viewModel, this.onEditSet});

  final ExerciseViewModel viewModel;
  final SessionDetailEditSet? onEditSet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final state = viewModel.sessionExercise.state;
    // The badge derives from the logged-set record, not the stored
    // discriminator: an exercise ended early (or a legacy marked-done-early
    // row) reads as the honest "n/m sets" partial, a zero-set record reads as
    // skipped, and a fully logged one as Done.
    final executedCount = viewModel.setRows
        .where((r) => r.executedSet != null)
        .length;
    final plannedCount = viewModel.setRows
        .where((r) => r.plannedValues != null)
        .length;
    final outcome = ExerciseOutcomes.of(
      state: state,
      executedSetCount: executedCount,
      plannedSetCount: plannedCount,
    );

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
            _StateBadge(
              outcome: outcome,
              completedCount: executedCount,
              totalPlanned: plannedCount,
              colors: colors,
            ),
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
            exerciseName: viewModel.displayName,
            colors: colors,
            typography: typography,
            onEditSet: onEditSet,
          ),
      ],
    );
  }
}

/// One "Set N — planned ↔ actual" line. The planned column reads from the
/// frozen snapshot (muted accent), the actual column from what was logged
/// (bright accent), with a check when the set was completed and a hollow dot
/// when it was not (e.g. a skipped exercise or an unfinished planned set).
///
/// On an in-week session ([onEditSet] non-null) a *logged* set's actual cell
/// becomes a tappable affordance — a 48 dp hit target with a subtle edit cue —
/// that opens the value editor. Rows with no logged set stay inert even then.
class _SetLine extends StatelessWidget {
  const _SetLine({
    required this.row,
    required this.measurementType,
    required this.exerciseName,
    required this.colors,
    required this.typography,
    this.onEditSet,
  });

  final SetRowViewModel row;
  final MeasurementType measurementType;
  final String exerciseName;
  final AppColors colors;
  final AppTypography typography;
  final SessionDetailEditSet? onEditSet;

  /// Matches the in-session set row's leading label column so single- and
  /// double-digit set numbers share one width.
  static const double _setLabelWidth = AppSpacing.xl + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    final executed = row.executedSet;
    final actualText = executed == null
        ? '—'
        : SetValueFormatter.formatActual(executed.actualValues);
    final canEdit = onEditSet != null && executed != null;

    final actualStyle = typography.numericSm.copyWith(
      color: executed != null ? colors.actual : colors.onSurfaceMuted,
    );

    final Widget actualCell;
    if (canEdit) {
      actualCell = Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: () => onEditSet!(
            executedSetId: executed.id,
            currentValues: executed.actualValues,
            measurementType: measurementType,
            title: '$exerciseName · Set ${row.position + 1}',
          ),
          borderRadius: BorderRadius.circular(AppRadius.sm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AppSpacing.touchMin),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: Text(
                    actualText,
                    style: actualStyle,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                AppIcon(
                  Icons.edit_outlined,
                  size: AppIconSize.xs,
                  color: colors.onSurfaceMuted,
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      actualCell = Text(
        actualText,
        style: actualStyle,
        textAlign: TextAlign.end,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      );
    }

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
          Expanded(child: actualCell),
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
  const _StateBadge({
    required this.outcome,
    required this.completedCount,
    required this.totalPlanned,
    required this.colors,
  });

  final ExerciseOutcome outcome;
  final int completedCount;
  final int totalPlanned;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return switch (outcome) {
      ExerciseOutcome.completed => StatusBadge.icon(
        icon: Icons.check_circle,
        color: colors.exerciseCompleted,
        label: 'Done',
      ),
      ExerciseOutcome.partial => StatusBadge.pill(
        label: '$completedCount/$totalPlanned sets',
        color: colors.exercisePartial,
      ),
      ExerciseOutcome.skipped => StatusBadge.pill(
        label: 'Skipped',
        color: colors.exerciseSkipped,
      ),
      ExerciseOutcome.replaced => StatusBadge.pill(
        label: 'Replaced',
        color: colors.exerciseReplaced,
      ),
    };
  }
}
