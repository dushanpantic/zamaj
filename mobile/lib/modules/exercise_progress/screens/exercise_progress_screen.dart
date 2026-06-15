import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/exercise_progress/bloc/exercise_progress/bloc.dart';
import 'package:zamaj/modules/exercise_progress/widgets/progress_status_view.dart';
import 'package:zamaj/modules/exercise_progress/widgets/top_set_trend_chart.dart';

/// The exercise-progress screen: a top-set trend line for a linked, weighted
/// exercise aggregated across every program, or a guidance state when there's
/// nothing (yet) to plot.
///
/// Switches on [ExerciseProgressBloc]'s state — the trend draws the chart, every
/// other state routes to [ProgressStatusView] (including the retry-able error).
class ExerciseProgressScreen extends StatelessWidget {
  const ExerciseProgressScreen({super.key, required this.displayName});

  /// Exercise name shown in the app bar and the chart's spoken summary.
  final String displayName;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: Text(displayName)),
      body: BlocBuilder<ExerciseProgressBloc, ExerciseProgressState>(
        builder: (context, state) {
          return switch (state) {
            ExerciseProgressTrend(:final series) => ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.lg,
                AppSpacing.xxxl,
              ),
              children: [
                TopSetTrendChart(series: series, displayName: displayName),
                const SizedBox(height: AppSpacing.md),
                // A sighted-only affordance hint: the chart's tap interaction is
                // unavailable to screen readers (the canvas is ExcludeSemantics),
                // which already get the chart's spoken summary instead.
                ExcludeSemantics(
                  child: Text(
                    'Tap a point to see its workout day.',
                    style: AppTypography.standard.caption.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            _ => ProgressStatusView(
              state: state,
              onRetry: () => context.read<ExerciseProgressBloc>().add(
                const ExerciseProgressLoadRequested(),
              ),
            ),
          };
        },
      ),
    );
  }
}
