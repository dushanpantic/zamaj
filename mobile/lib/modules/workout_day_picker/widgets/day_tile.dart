import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_view_model.dart';
import 'package:zamaj/modules/workout_day_picker/widgets/day_tile_history_labels.dart';
import 'package:zamaj/modules/workout_day_picker/widgets/start_resume_action_button.dart';

class DayTile extends StatelessWidget {
  const DayTile({
    super.key,
    required this.viewModel,
    required this.referenceNow,
    required this.launchInFlightWorkoutDayId,
    required this.onStartPressed,
    required this.onResumePressed,
    required this.onRetryPressed,
  });

  final DayViewModel viewModel;
  final DateTime referenceNow;
  final String? launchInFlightWorkoutDayId;
  final void Function(String workoutDayId) onStartPressed;
  final void Function(String workoutDayId, String activeSessionId)
  onResumePressed;
  final void Function(String workoutDayId) onRetryPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final day = viewModel.workoutDay;
    final groupCount = day.exerciseGroups.length;
    final groupLabel = groupCount == 1
        ? '1 exercise group'
        : '$groupCount exercise groups';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  day.name,
                  style: typography.titleSmall.copyWith(
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  groupLabel,
                  style: typography.caption.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                _statusBody(context),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _trailing(),
        ],
      ),
    );
  }

  Widget _statusBody(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return switch (viewModel.status) {
      DayTileLoading() => _Skeleton(),
      DayTileFailure(:final error) => _TileError(
        message: DomainErrorPresenter.present(error).body,
        textStyle: typography.bodySmall.copyWith(color: colors.error),
      ),
      DayTileLoaded(:final summary) => DayTileHistoryLabels(
        summary: summary,
        referenceNow: referenceNow,
      ),
    };
  }

  Widget _trailing() {
    return switch (viewModel.status) {
      DayTileLoading() => const SizedBox(width: 96, height: AppSpacing.touchMin),
      DayTileFailure() => SizedBox(
        height: AppSpacing.touchMin,
        child: TextButton.icon(
          onPressed: () => onRetryPressed(viewModel.workoutDay.id),
          icon: const Icon(Icons.refresh, size: 18),
          label: const Text('Retry'),
        ),
      ),
      DayTileLoaded(:final summary) => SizedBox(
        width: 120,
        child: _LoadedTrailing(
          workoutDayId: viewModel.workoutDay.id,
          activeSessionId: summary.activeSessionId,
          launchInFlightWorkoutDayId: launchInFlightWorkoutDayId,
          onStartPressed: onStartPressed,
          onResumePressed: onResumePressed,
        ),
      ),
    };
  }
}

class _LoadedTrailing extends StatelessWidget {
  const _LoadedTrailing({
    required this.workoutDayId,
    required this.activeSessionId,
    required this.launchInFlightWorkoutDayId,
    required this.onStartPressed,
    required this.onResumePressed,
  });

  final String workoutDayId;
  final String? activeSessionId;
  final String? launchInFlightWorkoutDayId;
  final void Function(String workoutDayId) onStartPressed;
  final void Function(String workoutDayId, String activeSessionId)
  onResumePressed;

  @override
  Widget build(BuildContext context) {
    final isResume = activeSessionId != null;
    final anyInFlight = launchInFlightWorkoutDayId != null;
    final thisBusy = launchInFlightWorkoutDayId == workoutDayId;
    final enabled = !anyInFlight || thisBusy;

    return StartResumeActionButton(
      isResume: isResume,
      busy: thisBusy,
      enabled: enabled,
      onPressed: () {
        if (isResume) {
          onResumePressed(workoutDayId, activeSessionId!);
        } else {
          onStartPressed(workoutDayId);
        }
      },
    );
  }
}

class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBar(width: 160, color: colors.surfaceVariant),
        const SizedBox(height: AppSpacing.xs),
        _SkeletonBar(width: 120, color: colors.surfaceVariant),
      ],
    );
  }
}

class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({required this.width, required this.color});

  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: AppSpacing.md,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
  }
}

class _TileError extends StatelessWidget {
  const _TileError({required this.message, required this.textStyle});

  final String message;
  final TextStyle textStyle;

  @override
  Widget build(BuildContext context) {
    return Text(
      'Failed to load history: $message',
      style: textStyle,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
