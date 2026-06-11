import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/rest_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/set_row.dart';

/// Width reserved in the card-header leading slot for the drag handle — and
/// for the matching [_LeadingStateTile] on non-draggable (finished) cards.
/// Pinning both to one value keeps the title's left edge from shifting across
/// the unfinished→done transition or the LOG-SET in-flight window. Sized to
/// the sweaty-hands [AppInSessionSize.stepButton] (64 dp) grab target.
const double kExerciseLeadingSlotWidth = AppInSessionSize.stepButton;

/// Drag payload that travels with a LongPressDraggable started on this
/// card's handle. Lives at the screen level too: the screen's DragTarget
/// regions resolve drops via [DropResolver].
///
/// [supersetTag] is the dragged exercise's current `supersetTag`. Drop
/// targets gate on it: main-list reorder gaps and onto-card targets accept
/// only payloads with `supersetTag == null`, while reorder gaps inside a
/// superset accept only payloads whose `supersetTag` matches the group.
/// This keeps within-superset reordering contiguous and prevents accidental
/// breakage of an existing group.
class ExerciseDragPayload {
  const ExerciseDragPayload({
    required this.sessionExerciseId,
    required this.supersetTag,
  });
  final String sessionExerciseId;
  final String? supersetTag;
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
    required this.onOpenVideo,
    this.onGroupIntoPressed,
    this.onMoveUp,
    this.onMoveDown,
    this.isCurrent = false,
    this.isLastTouched = false,
    this.dragHandle,
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
  final void Function(String videoUrl) onOpenVideo;

  /// When non-null, the per-card ⋮ menu surfaces a "Group into superset…"
  /// entry that opens the picker dialog. Null hides the entry — used inside
  /// already-grouped supersets and whenever no eligible partner exists.
  final VoidCallback? onGroupIntoPressed;

  /// Tap-only reorder fallback: dispatched from the ⋮ menu's "Move up" /
  /// "Move down" entries and the matching screen-reader custom actions, so
  /// reordering never *requires* a drag. Null disables that direction — it's
  /// a no-op end (top-most / bottom-most in the exercise's reorder scope) or
  /// the card isn't reorderable (finished, or the session has ended).
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  /// True when this card represents the "current" exercise — the one Focus
  /// mode and the bottom Focus button will open. Drives the accent border,
  /// which is the sole "current" signal on the card.
  final bool isCurrent;

  /// True when this exercise was the target of the most recent log/edit
  /// action. The loggable row inside receives a subtle accent so the eye
  /// returns to where the user left off after a rest.
  final bool isLastTouched;

  /// Optional widget rendered in the leading 48dp slot of the card header.
  /// The screen passes a [LongPressDraggable]-wrapped icon here so the
  /// drag-to-reorder gesture is scoped to the handle only and doesn't fight
  /// taps on LOG SET / kebab / etc. elsewhere on the card.
  final Widget? dragHandle;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final sessionExercise = viewModel.sessionExercise;
    final state = sessionExercise.state;
    final hasExecutedSet = sessionExercise.executedSets.isNotEmpty;

    // The accent border is the card's sole "current exercise" signal.
    final borderColor = isCurrent ? colors.primary : colors.outline;
    final borderWidth = isCurrent ? AppStroke.emphasis : AppStroke.hairline;
    // Screen-reader equivalents of the ⋮ Move up/down entries: AT users get a
    // reorder path that never depends on a precise drag gesture.
    final moveActions = <CustomSemanticsAction, VoidCallback>{
      const CustomSemanticsAction(label: 'Move up'): ?onMoveUp,
      const CustomSemanticsAction(label: 'Move down'): ?onMoveDown,
    };
    return Semantics(
      container: true,
      customSemanticsActions: moveActions.isEmpty ? null : moveActions,
      child: AnimatedContainer(
        duration: resolveDuration(context, AppDuration.base),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: borderColor, width: borderWidth),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Header(
              viewModel: viewModel,
              isExpanded: isExpanded,
              canMutate: canMutate,
              canMarkDone: state is UnfinishedState && hasExecutedSet,
              dragHandle: state is UnfinishedState ? dragHandle : null,
              onTap: onToggleExpansion,
              onSkip: onSkipPressed,
              onMarkDone: onMarkDonePressed,
              onOpenVideo: onOpenVideo,
              onGroupInto: onGroupIntoPressed,
              onMoveUp: onMoveUp,
              onMoveDown: onMoveDown,
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
    required this.dragHandle,
    required this.onTap,
    required this.onSkip,
    required this.onMarkDone,
    required this.onOpenVideo,
    required this.onGroupInto,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.typography,
    required this.colors,
  });

  final ExerciseViewModel viewModel;
  final bool isExpanded;
  final bool canMutate;
  final bool canMarkDone;
  final Widget? dragHandle;
  final VoidCallback onTap;
  final VoidCallback onSkip;
  final VoidCallback onMarkDone;
  final void Function(String videoUrl) onOpenVideo;
  final VoidCallback? onGroupInto;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
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
              AnimatedSwitcher(
                duration: resolveDuration(context, AppDuration.base),
                child: dragHandle ?? _LeadingStateTile(state: state),
              ),
              // Breathing room between the (now tinted) leading slot and the
              // title. Outside the handle/placeholder branch so the title's
              // left edge stays put across the unfinished→done transition.
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Row(
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
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Badges and the set counter share one trailing block with a
              // flush right edge. With a badge above (warmup flame, Done…)
              // the counter keeps its stacked two-line look; without one —
              // the common unfinished case — the lone counter centers
              // vertically against the title/summary lines instead of
              // dangling at the second line under empty space.
              _TrailingMeta(
                isWarmup:
                    viewModel.plannedGroupRole == ExerciseGroupRole.warmup,
                state: state,
                completedCount: completedCount,
                totalPlanned: totalPlanned,
                typography: typography,
                colors: colors,
              ),
              _Actions(
                isUnfinished: isUnfinished,
                canMutate: canMutate,
                canMarkDone: canMutate && canMarkDone,
                videoUrl: videoUrl,
                isExpanded: isExpanded,
                onSkip: onSkip,
                onMarkDone: onMarkDone,
                onOpenVideo: onOpenVideo,
                onGroupInto: onGroupInto,
                onMoveUp: onMoveUp,
                onMoveDown: onMoveDown,
                colors: colors,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fills the header's leading slot whenever the drag handle is absent —
/// finished exercises, and every card once the session has ended. Mirrors the
/// handle's exact geometry (64dp rounded square with a drawn fill) so the slot
/// reads as the handle resolving into a status, never as a hole in the card.
///
/// Finished states get their semantic color as a tint fill + glyph; an
/// unfinished exercise in an ended session keeps the handle's neutral fill
/// with a muted hollow circle — an unchecked checkbox, "never completed".
class _LeadingStateTile extends StatelessWidget {
  const _LeadingStateTile({required this.state});

  final ExerciseState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    // Skipped / Replaced pass a null label: their trailing pill already
    // announces the state, and a second identical announcement from the tile
    // would just be screen-reader noise. Done and Not-completed have no other
    // announcer, so the tile carries their label.
    final (Color accent, IconData icon, String? label) = switch (state) {
      CompletedState() => (colors.exerciseCompleted, Icons.check, 'Done'),
      SkippedState() => (colors.exerciseSkipped, Icons.skip_next, null),
      ReplacedState() => (colors.exerciseReplaced, Icons.swap_horiz, null),
      UnfinishedState() => (
        colors.onSurfaceMuted,
        Icons.radio_button_unchecked,
        'Not completed',
      ),
    };
    return Container(
      width: kExerciseLeadingSlotWidth,
      height: kExerciseLeadingSlotWidth,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: state is UnfinishedState
            ? colors.surfaceVariant
            : accent.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: AppIcon(
        icon,
        color: accent,
        size: AppIconSize.lg,
        semanticLabel: label,
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
        AppIcon(
          Icons.timer_outlined,
          size: AppIconSize.xs,
          color: colors.onSurfaceMuted,
        ),
        const SizedBox(width: AppSpacing.xxs),
        Text(
          RestFormatter.format(seconds),
          style: typography.numericXs.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

/// Right-edge meta block of the card header: status badges (warmup flame,
/// Skipped / Replaced pills) on the first line, the `completed / planned`
/// set counter below them. Keeping them in one column guarantees a shared
/// flush right edge, and when no badge renders the lone counter is centered
/// vertically by the header row instead of sitting on the second text line
/// with nothing above it.
class _TrailingMeta extends StatelessWidget {
  const _TrailingMeta({
    required this.isWarmup,
    required this.state,
    required this.completedCount,
    required this.totalPlanned,
    required this.typography,
    required this.colors,
  });

  final bool isWarmup;
  final ExerciseState state;
  final int completedCount;
  final int totalPlanned;
  final AppTypography typography;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    // Done lives in the leading state tile now; only the rarer exception
    // states (Skipped / Replaced) keep a labelled pill on the right.
    final showStatePill = state is SkippedState || state is ReplacedState;
    final hasBadges = isWarmup || showStatePill;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (hasBadges)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isWarmup)
                StatusBadge.icon(
                  icon: Icons.local_fire_department,
                  color: colors.warmup,
                  label: 'Warmup',
                ),
              if (isWarmup && showStatePill)
                const SizedBox(width: AppSpacing.sm),
              if (showStatePill) _StateBadge(state: state, colors: colors),
            ],
          ),
        if (hasBadges && totalPlanned > 0)
          const SizedBox(height: AppSpacing.xs),
        if (totalPlanned > 0)
          Semantics(
            label: '$completedCount of $totalPlanned sets done',
            excludeSemantics: true,
            child: Text(
              '$completedCount / $totalPlanned',
              style: typography.numericSm.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
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
    // Only the exception states render here: Done is signalled by the leading
    // [_LeadingStateTile], and the active exercise carries no badge — the
    // card's 2dp primary border is the "current" signal on its own.
    return switch (state) {
      CompletedState() => const SizedBox.shrink(),
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

class _Actions extends StatelessWidget {
  const _Actions({
    required this.isUnfinished,
    required this.canMutate,
    required this.canMarkDone,
    required this.videoUrl,
    required this.isExpanded,
    required this.onSkip,
    required this.onMarkDone,
    required this.onOpenVideo,
    required this.onGroupInto,
    required this.onMoveUp,
    required this.onMoveDown,
    required this.colors,
  });

  final bool isUnfinished;
  final bool canMutate;
  final bool canMarkDone;
  final String? videoUrl;
  final bool isExpanded;
  final VoidCallback onSkip;
  final VoidCallback onMarkDone;
  final void Function(String videoUrl) onOpenVideo;
  final VoidCallback? onGroupInto;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final canGroupInto = canMutate && isUnfinished && onGroupInto != null;
    // Tap-only reorder fallback. Shown whenever at least one direction can
    // actually move the exercise; the no-op direction at a sequence end is
    // rendered disabled so the menu layout stays stable.
    final canReorder = onMoveUp != null || onMoveDown != null;
    // Every secondary action lives in the kebab: Move up/down /
    // Group into / Mark done / Skip / Open video. The card surface stays
    // reserved for the one direct control that matters in the gym, LOG SET.
    final hasMenu =
        canReorder ||
        canGroupInto ||
        (videoUrl != null && videoUrl!.isNotEmpty);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppIcon(
          isExpanded ? Icons.expand_less : Icons.expand_more,
          color: colors.onSurfaceMuted,
          size: AppIconSize.lg,
        ),
        if (hasMenu)
          PopupMenuButton<_MenuAction>(
            tooltip: 'Exercise actions',
            icon: AppIcon(
              Icons.more_vert,
              color: colors.onSurfaceMuted,
              size: AppIconSize.lg,
            ),
            padding: EdgeInsets.zero,
            onSelected: (action) {
              switch (action) {
                case _MenuAction.moveUp:
                  onMoveUp?.call();
                case _MenuAction.moveDown:
                  onMoveDown?.call();
                case _MenuAction.groupInto:
                  onGroupInto?.call();
                case _MenuAction.skip:
                  onSkip();
                case _MenuAction.markDone:
                  onMarkDone();
                case _MenuAction.openVideo:
                  final url = videoUrl;
                  if (url != null && url.isNotEmpty) onOpenVideo(url);
              }
            },
            itemBuilder: (context) => [
              if (canReorder) ...[
                PopupMenuItem(
                  value: _MenuAction.moveUp,
                  enabled: onMoveUp != null,
                  child: AppMenuRow(
                    icon: Icons.arrow_upward,
                    label: 'Move up',
                    enabled: onMoveUp != null,
                  ),
                ),
                PopupMenuItem(
                  value: _MenuAction.moveDown,
                  enabled: onMoveDown != null,
                  child: AppMenuRow(
                    icon: Icons.arrow_downward,
                    label: 'Move down',
                    enabled: onMoveDown != null,
                  ),
                ),
              ],
              if (canGroupInto)
                const PopupMenuItem(
                  value: _MenuAction.groupInto,
                  child: AppMenuRow(
                    icon: Icons.link,
                    label: 'Group into superset…',
                  ),
                ),
              if (canMarkDone)
                const PopupMenuItem(
                  value: _MenuAction.markDone,
                  child: AppMenuRow(
                    icon: Icons.check_circle_outline,
                    label: 'Mark done',
                  ),
                ),
              if (canMutate && isUnfinished)
                const PopupMenuItem(
                  value: _MenuAction.skip,
                  child: AppMenuRow(icon: Icons.skip_next, label: 'Skip'),
                ),
              if (videoUrl != null && videoUrl!.isNotEmpty)
                const PopupMenuItem(
                  value: _MenuAction.openVideo,
                  child: AppMenuRow(
                    icon: Icons.play_circle_outline,
                    label: 'Open video',
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

enum _MenuAction { moveUp, moveDown, groupInto, skip, markDone, openVideo }

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
        const Divider(),
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
            // Logging a new set needs a live session (canMutate) AND an
            // exercise state that still accepts logs. Editing an already-logged
            // set only needs the latter, so completed sets stay correctable
            // after the session ends.
            canLog: canMutate && _exerciseAllowsMutation(state),
            canEditExecuted: _exerciseAllowsMutation(state),
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
                    icon: const AppIcon(
                      Icons.play_circle_outline,
                      size: AppIconSize.md,
                    ),
                    label: const Text('Open video'),
                    style: TextButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: const Size(0, AppSpacing.compactAction),
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
