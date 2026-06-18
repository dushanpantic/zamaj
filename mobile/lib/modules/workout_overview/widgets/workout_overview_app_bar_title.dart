import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/session_elapsed_label.dart';

/// AppBar title for the loaded state. Stacks the workout-day name above a
/// `done of total · mm:ss` status line so the user always knows their
/// position and pace at a glance.
class WorkoutOverviewAppBarTitle extends StatelessWidget {
  const WorkoutOverviewAppBarTitle({super.key, required this.state});

  final WorkoutOverviewLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final counts = _exerciseCounts(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                state.sessionState.session.snapshot.workoutDay.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (state.isDeload) ...[
              const SizedBox(width: AppSpacing.sm),
              const DeloadBadge(),
            ],
          ],
        ),
        Row(
          children: [
            Text(
              '${counts.done} of ${counts.total}',
              style: typography.numericSm.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            Text(
              '  ·  ',
              style: typography.labelSmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            SessionElapsedLabel(
              startedAt: state.sessionState.session.startedAt,
              endedAt: state.sessionState.session.endedAt,
            ),
          ],
        ),
      ],
    );
  }

  static ({int done, int total}) _exerciseCounts(WorkoutOverviewLoaded state) {
    var done = 0;
    var total = 0;
    for (final group in state.groups) {
      for (final ex in group.allExercises) {
        total++;
        if (ex.sessionExercise.state is! UnfinishedState) done++;
      }
    }
    return (done: done, total: total);
  }
}
