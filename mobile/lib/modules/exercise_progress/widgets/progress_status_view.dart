import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_progress/bloc/exercise_progress/bloc.dart';

/// Renders every non-trend [ExerciseProgressState]: the loading spinner, the
/// single-session top-set stat, and the guidance/empty/error states.
///
/// The trend state is drawn by `TopSetTrendChart`, not here — for it this view
/// renders nothing.
class ProgressStatusView extends StatelessWidget {
  const ProgressStatusView({
    super.key,
    required this.state,
    required this.onRetry,
  });

  final ExerciseProgressState state;

  /// Re-dispatches the load; wired to the error state's retry action.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ExerciseProgressLoading() => const AppLoadingView(
        semanticsLabel: 'Loading progress',
      ),
      ExerciseProgressSingle(:final point) => _SingleStat(point: point),
      ExerciseProgressEmptyNoSessions() => const AppStateView(
        icon: Icons.timeline_outlined,
        title: 'No sessions logged yet',
        message: 'Log a workout with this exercise to start your trend.',
      ),
      ExerciseProgressUnsupportedType() => const AppStateView(
        icon: Icons.fitness_center_outlined,
        title: 'Weighted exercises only',
        message: 'Progress tracking supports weight × reps exercises for now.',
      ),
      ExerciseProgressUnlinked() => const AppStateView(
        icon: Icons.link_off_outlined,
        title: "Not linked — can't track across sessions",
        message:
            'Link this exercise to a Library entry to track its top set '
            'across every program.',
      ),
      ExerciseProgressError() => AppStateView(
        icon: Icons.error_outline,
        tone: AppStateTone.error,
        title: "Couldn't load progress",
        message: 'Something went wrong reading your sessions.',
        primaryAction: AppStateAction(
          label: 'Retry',
          icon: Icons.refresh,
          onPressed: onRetry,
        ),
      ),
      // The trend state owns its own chart surface.
      ExerciseProgressTrend() => const SizedBox.shrink(),
    };
  }
}

/// The exactly-one-session layout: a labelled top-set readout in numeric type
/// with the session date and a keep-training nudge.
class _SingleStat extends StatelessWidget {
  const _SingleStat({required this.point});

  final ProgressPoint point;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final stat =
        '${WeightFormatter.formatKg(point.topSetWeightKg)} kg × ${point.reps}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Top set',
              style: typography.overline.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              stat,
              style: typography.numericLarge.copyWith(color: colors.actual),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              DateFormatter.isoDate(point.date),
              style: typography.numeric.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Keep training to build your trend.',
              style: typography.body.copyWith(color: colors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
