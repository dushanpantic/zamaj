import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
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

  /// Width reserved for the trailing start/resume action across every tile
  /// state, so the loading placeholder and the resolved button occupy the same
  /// slot and the tile body doesn't reflow when history loads.
  static const double _trailingActionWidth = 120;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final day = viewModel.workoutDay;
    final exerciseCount = day.exerciseGroups
        .where((g) => g.role == ExerciseGroupRole.main)
        .fold<int>(0, (sum, g) => sum + g.exercises.length);
    final exerciseLabel = exerciseCount == 1
        ? '1 exercise'
        : '$exerciseCount exercises';

    final activeSessionId = switch (viewModel.status) {
      DayTileLoaded(:final summary) => summary.activeSessionId,
      _ => null,
    };
    final hasActiveSession = activeSessionId != null;

    final body = Container(
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
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        day.name,
                        style: typography.titleSmall.copyWith(
                          color: colors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasActiveSession) ...[
                      const SizedBox(width: AppSpacing.sm),
                      StatusBadge.pill(
                        label: 'IN PROGRESS',
                        color: colors.primary,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  exerciseLabel,
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

    final content = hasActiveSession
        ? Stack(
            children: [
              body,
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Container(
                    width: 4,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.md),
                        bottomLeft: Radius.circular(AppRadius.md),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          )
        : body;

    final tapHandler = _resolveTapHandler(activeSessionId);

    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.md),
        onTap: tapHandler,
        child: content,
      ),
    );
  }

  VoidCallback? _resolveTapHandler(String? activeSessionId) {
    if (viewModel.status is! DayTileLoaded) return null;
    final anyInFlight = launchInFlightWorkoutDayId != null;
    if (anyInFlight) return null;
    final workoutDayId = viewModel.workoutDay.id;
    if (activeSessionId != null) {
      return () => onResumePressed(workoutDayId, activeSessionId);
    }
    return () => onStartPressed(workoutDayId);
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
      DayTileLoading() => const SizedBox(
        width: _trailingActionWidth,
        height: AppSpacing.touchMin,
      ),
      DayTileFailure() => SizedBox(
        height: AppSpacing.touchMin,
        child: TextButton.icon(
          onPressed: () => onRetryPressed(viewModel.workoutDay.id),
          icon: const AppIcon(Icons.refresh, size: AppIconSize.md),
          label: const Text('Retry'),
        ),
      ),
      DayTileLoaded(:final summary) => SizedBox(
        width: _trailingActionWidth,
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
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppSkeletonBar(width: 160),
        SizedBox(height: AppSpacing.xs),
        AppSkeletonBar(width: 120),
      ],
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
