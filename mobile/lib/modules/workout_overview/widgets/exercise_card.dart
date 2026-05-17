import 'package:flutter/material.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/rest_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/set_row.dart';

/// Drag payload that travels with a LongPressDraggable started on this
/// card's handle. Lives at the screen level too: the screen's DragTarget
/// regions resolve drops via [DropResolver].
class ExerciseDragPayload {
  const ExerciseDragPayload(this.sessionExerciseId);
  final String sessionExerciseId;
}

/// Vertical card showing a single session exercise with its set rows, notes,
/// and contextual actions. The card itself never mutates state — it emits
/// intent through the callback fields, all of which the screen plumbs back
/// into [WorkoutOverviewBloc].
class ExerciseCard extends StatelessWidget {
  const ExerciseCard({
    super.key,
    required this.viewModel,
    required this.isExpanded,
    required this.canMutate,
    required this.onToggleExpansion,
    required this.onLogSet,
    required this.onEditSet,
    required this.onSkipPressed,
    required this.onMarkDonePressed,
    required this.onReplacePressed,
    required this.onOpenVideo,
    this.isLastTouched = false,
    this.showDragHandle = false,
    this.isDropTarget = false,
  });

  final ExerciseViewModel viewModel;
  final bool isExpanded;
  final bool canMutate;
  final VoidCallback onToggleExpansion;
  final void Function(ActualSetValues values, String? plannedSetIdInSnapshot)
  onLogSet;
  final void Function(String executedSetId, ActualSetValues values) onEditSet;
  final VoidCallback onSkipPressed;
  final VoidCallback onMarkDonePressed;
  final VoidCallback onReplacePressed;
  final void Function(String videoUrl) onOpenVideo;

  /// True when this exercise was the target of the most recent log/edit
  /// action. The loggable row inside receives a subtle accent so the eye
  /// returns to where the user left off after a rest.
  final bool isLastTouched;
  final bool showDragHandle;
  final bool isDropTarget;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final sessionExercise = viewModel.sessionExercise;
    final state = sessionExercise.state;
    final hasExecutedSet = sessionExercise.executedSets.isNotEmpty;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: isDropTarget ? colors.primary : colors.outline,
          width: isDropTarget ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(
            viewModel: viewModel,
            isExpanded: isExpanded,
            canMutate: canMutate,
            canMarkDone: state is UnfinishedState && hasExecutedSet,
            showDragHandle: showDragHandle && state is UnfinishedState,
            onTap: onToggleExpansion,
            onSkip: onSkipPressed,
            onMarkDone: onMarkDonePressed,
            onReplace: onReplacePressed,
            onOpenVideo: onOpenVideo,
            typography: typography,
            colors: colors,
          ),
          if (isExpanded)
            _ExpandedBody(
              viewModel: viewModel,
              canMutate: canMutate,
              isLastTouched: isLastTouched,
              onLogSet: onLogSet,
              onEditSet: onEditSet,
              onOpenVideo: onOpenVideo,
              typography: typography,
              colors: colors,
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.viewModel,
    required this.isExpanded,
    required this.canMutate,
    required this.canMarkDone,
    required this.showDragHandle,
    required this.onTap,
    required this.onSkip,
    required this.onMarkDone,
    required this.onReplace,
    required this.onOpenVideo,
    required this.typography,
    required this.colors,
  });

  final ExerciseViewModel viewModel;
  final bool isExpanded;
  final bool canMutate;
  final bool canMarkDone;
  final bool showDragHandle;
  final VoidCallback onTap;
  final VoidCallback onSkip;
  final VoidCallback onMarkDone;
  final VoidCallback onReplace;
  final void Function(String videoUrl) onOpenVideo;
  final AppTypography typography;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final state = viewModel.sessionExercise.state;
    final isUnfinished = state is UnfinishedState;
    final displayName = switch (state) {
      ReplacedState(:final substitute) => substitute.name,
      _ => viewModel.plannedExerciseName,
    };
    final completedCount = viewModel.setRows
        .where((r) => r.executedSet != null)
        .length;
    final totalPlanned = viewModel.setRows
        .where((r) => r.plannedValues != null)
        .length;
    final videoUrl = switch (state) {
      ReplacedState(:final substitute) => substitute.metadata?.videoUrl,
      _ => viewModel.plannedMetadata.videoUrl,
    };

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.md,
            AppSpacing.xs,
            AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (showDragHandle)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: Icon(
                    Icons.drag_indicator,
                    color: colors.onSurfaceMuted,
                    size: 20,
                  ),
                )
              else
                const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            displayName,
                            style: typography.titleSmall.copyWith(
                              color: colors.onSurface,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.sm),
                        _StateBadge(state: state, colors: colors),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  viewModel.plannedSummary,
                                  style: typography.caption.copyWith(
                                    color: colors.onSurfaceMuted,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (viewModel.plannedRestSeconds != null) ...[
                                const SizedBox(width: AppSpacing.sm),
                                _RestIndicator(
                                  seconds: viewModel.plannedRestSeconds!,
                                  typography: typography,
                                  colors: colors,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (totalPlanned > 0)
                          Text(
                            '$completedCount / $totalPlanned',
                            style: typography.numericSm.copyWith(
                              color: colors.onSurfaceMuted,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              _Actions(
                isUnfinished: isUnfinished,
                canMutate: canMutate,
                canMarkDone: canMutate && canMarkDone,
                videoUrl: videoUrl,
                isExpanded: isExpanded,
                onSkip: onSkip,
                onMarkDone: onMarkDone,
                onReplace: onReplace,
                onOpenVideo: onOpenVideo,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RestIndicator extends StatelessWidget {
  const _RestIndicator({
    required this.seconds,
    required this.typography,
    required this.colors,
  });

  final int seconds;
  final AppTypography typography;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.timer_outlined, size: 12, color: colors.onSurfaceMuted),
        const SizedBox(width: 2),
        Text(
          RestFormatter.format(seconds),
          style: typography.numericXs.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _StateBadge extends StatelessWidget {
  const _StateBadge({required this.state, required this.colors});

  final ExerciseState state;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (state) {
      UnfinishedState() => (null, colors.onSurfaceMuted),
      CompletedState() => ('Done', colors.exerciseCompleted),
      SkippedState() => ('Skipped', colors.exerciseSkipped),
      ReplacedState() => ('Replaced', colors.exerciseReplaced),
    };
    if (label == null) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: AppTypography.standard.caption.copyWith(color: color),
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isUnfinished,
    required this.canMutate,
    required this.canMarkDone,
    required this.videoUrl,
    required this.isExpanded,
    required this.onSkip,
    required this.onMarkDone,
    required this.onReplace,
    required this.onOpenVideo,
    required this.colors,
  });

  final bool isUnfinished;
  final bool canMutate;
  final bool canMarkDone;
  final String? videoUrl;
  final bool isExpanded;
  final VoidCallback onSkip;
  final VoidCallback onMarkDone;
  final VoidCallback onReplace;
  final void Function(String videoUrl) onOpenVideo;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final hasMenu =
        (canMutate && isUnfinished) ||
        (videoUrl != null && videoUrl!.isNotEmpty);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: colors.onSurfaceMuted,
          size: 20,
        ),
        if (hasMenu)
          PopupMenuButton<_MenuAction>(
            tooltip: 'Exercise actions',
            icon: Icon(Icons.more_vert, color: colors.onSurfaceMuted, size: 20),
            padding: EdgeInsets.zero,
            onSelected: (action) {
              switch (action) {
                case _MenuAction.skip:
                  onSkip();
                case _MenuAction.markDone:
                  onMarkDone();
                case _MenuAction.replace:
                  onReplace();
                case _MenuAction.openVideo:
                  final url = videoUrl;
                  if (url != null && url.isNotEmpty) onOpenVideo(url);
              }
            },
            itemBuilder: (context) => [
              if (canMutate && isUnfinished)
                const PopupMenuItem(
                  value: _MenuAction.replace,
                  child: ListTile(
                    leading: Icon(Icons.swap_horiz),
                    title: Text('Replace'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              if (canMarkDone)
                const PopupMenuItem(
                  value: _MenuAction.markDone,
                  child: ListTile(
                    leading: Icon(Icons.check_circle_outline),
                    title: Text('Mark done'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              if (canMutate && isUnfinished)
                const PopupMenuItem(
                  value: _MenuAction.skip,
                  child: ListTile(
                    leading: Icon(Icons.skip_next),
                    title: Text('Skip'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              if (videoUrl != null && videoUrl!.isNotEmpty)
                const PopupMenuItem(
                  value: _MenuAction.openVideo,
                  child: ListTile(
                    leading: Icon(Icons.play_circle_outline),
                    title: Text('Open video'),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
            ],
          )
        else
          const SizedBox(width: AppSpacing.lg),
      ],
    );
  }
}

enum _MenuAction { skip, markDone, replace, openVideo }

class _ExpandedBody extends StatelessWidget {
  const _ExpandedBody({
    required this.viewModel,
    required this.canMutate,
    required this.isLastTouched,
    required this.onLogSet,
    required this.onEditSet,
    required this.onOpenVideo,
    required this.typography,
    required this.colors,
  });

  final ExerciseViewModel viewModel;
  final bool canMutate;
  final bool isLastTouched;
  final void Function(ActualSetValues values, String? plannedSetIdInSnapshot)
  onLogSet;
  final void Function(String executedSetId, ActualSetValues values) onEditSet;
  final void Function(String videoUrl) onOpenVideo;
  final AppTypography typography;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final state = viewModel.sessionExercise.state;
    final notes = switch (state) {
      ReplacedState(:final substitute) => substitute.metadata?.notes,
      _ => viewModel.plannedMetadata.notes,
    };
    final videoUrl = switch (state) {
      ReplacedState(:final substitute) => substitute.metadata?.videoUrl,
      _ => viewModel.plannedMetadata.videoUrl,
    };
    final replacementBanner = state is ReplacedState
        ? Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.sm,
            ),
            child: Text(
              'Replaced from "${viewModel.plannedExerciseName}"',
              style: typography.caption.copyWith(
                color: colors.exerciseReplaced,
              ),
            ),
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Divider(color: colors.outline, height: 1, thickness: 1),
        if (replacementBanner != null) ...[
          const SizedBox(height: AppSpacing.sm),
          replacementBanner,
        ],
        ...viewModel.setRows.map(
          (row) => SetRow(
            key: ValueKey(
              '${viewModel.sessionExercise.id}_set_${row.position}',
            ),
            viewModel: row,
            sessionExerciseId: viewModel.sessionExercise.id,
            measurementType: viewModel.effectiveMeasurementType,
            canMutate: canMutate && _exerciseAllowsMutation(state),
            highlightLoggable: isLastTouched,
            onLogSet: onLogSet,
            onEditSet: onEditSet,
          ),
        ),
        if ((notes != null && notes.isNotEmpty) ||
            (videoUrl != null && videoUrl.isNotEmpty)) ...[
          const SizedBox(height: AppSpacing.sm),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              0,
              AppSpacing.md,
              AppSpacing.md,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (notes != null && notes.isNotEmpty)
                  Text(
                    notes,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                if (videoUrl != null && videoUrl.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  TextButton.icon(
                    onPressed: () => onOpenVideo(videoUrl),
                    icon: const Icon(Icons.play_circle_outline, size: 18),
                    label: const Text('Open video'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, 32),
                      alignment: Alignment.centerLeft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ] else
          const SizedBox(height: AppSpacing.xs),
      ],
    );
  }

  bool _exerciseAllowsMutation(ExerciseState state) {
    return state is UnfinishedState ||
        state is ReplacedState ||
        state is CompletedState;
  }
}
