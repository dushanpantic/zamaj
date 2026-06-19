import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

/// Wraps a contiguous run of exercises that share a `supersetTag` in a labeled
/// container. The header is the only superset-specific part: a leading
/// whole-group drag handle (when eligible), the "Superset" label, and a single
/// trailing overflow kebab holding Move up / Move down / Ungroup. The exercise
/// cards inside are unchanged from the standalone single-exercise display.
class SupersetCard extends StatelessWidget {
  const SupersetCard({
    super.key,
    required this.tag,
    required this.exercises,
    required this.expandedExerciseIds,
    required this.canMutate,
    required this.onUngroupPressed,
    this.onMoveUp,
    this.onMoveDown,
    required this.onToggleExpansion,
    required this.onLogSet,
    required this.onEditSet,
    required this.onEndOrSkipPressed,
    required this.onOpenVideo,
    this.onAddSetPressed,
    this.onResumePressed,
    this.currentSessionExerciseIds = const <String>{},
    this.lastTouchedSessionExerciseId,
    this.groupDragHandle,
    this.memberDragHandleBuilder,
    this.memberMoveBuilder,
    this.gapBuilder,
  });

  final String tag;
  final List<ExerciseViewModel> exercises;
  final Set<String> expandedExerciseIds;
  final bool canMutate;
  final VoidCallback onUngroupPressed;

  /// Tap-only whole-superset reorder, surfaced as the header kebab's Move up /
  /// Move down entries. A null direction is a disabled end; both null when the
  /// group isn't whole-move eligible (a finished member, or the session ended),
  /// in which case the Move entries are omitted and only Ungroup remains.
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final void Function(String sessionExerciseId) onToggleExpansion;
  final void Function(
    String sessionExerciseId,
    ActualSetValues values,
    String? plannedSetIdInSnapshot,
  )
  onLogSet;
  final void Function(String executedSetId, ActualSetValues values) onEditSet;

  /// The single adaptive terminal action (Skip exercise / End exercise) for a
  /// member, keyed by its session-exercise id.
  final void Function(String sessionExerciseId) onEndOrSkipPressed;
  final void Function(String videoUrl) onOpenVideo;

  /// Logs an extra set beyond plan on a completed member, keyed by its
  /// session-exercise id. Null leaves the "Add set" kebab item hidden.
  final void Function(String sessionExerciseId)? onAddSetPressed;

  /// Resumes a skipped/ended-early member back to in-progress. Threaded to each
  /// member card's "Resume" kebab item; null hides it.
  final void Function(String sessionExerciseId)? onResumePressed;

  /// Members that should render the CURRENT chip + accent border. Includes
  /// every unfinished member of the active superset; the screen computes
  /// the set from `openTargets.first` and the assembled groups.
  final Set<String> currentSessionExerciseIds;
  final String? lastTouchedSessionExerciseId;

  /// Optional drag handle for moving the whole superset as one block, rendered
  /// in the header's leading slot. Non-null only when the group is whole-drag
  /// eligible (session live and every member unfinished); the screen passes a
  /// [LongPressDraggable]-wrapped handle carrying a `SupersetDragPayload`.
  final Widget? groupDragHandle;

  /// Optional per-member drag-handle builder. When non-null and the returned
  /// widget is non-null, the handle is rendered in the member card's leading
  /// 48 dp slot. The workout-overview screen returns a [LongPressDraggable]-
  /// wrapped icon so the drag-to-reorder gesture lives on the handle only
  /// and doesn't fight taps elsewhere on the card.
  final Widget? Function(ExerciseViewModel member)? memberDragHandleBuilder;

  /// Optional per-member tap-only reorder handlers, surfaced as the member
  /// card's ⋮ Move up/down entries. A null direction (or null builder) leaves
  /// that direction disabled. Scoped to within-group moves by the caller.
  final ({VoidCallback? up, VoidCallback? down}) Function(
    ExerciseViewModel member,
  )?
  memberMoveBuilder;

  /// Optional builder for the gap widgets surrounding each member.
  /// `position` ranges over `0..exercises.length` inclusive:
  ///
  /// - `0` is the gap above the first member,
  /// - `k` for `0 < k < exercises.length` is the gap between
  ///   `exercises[k - 1]` and `exercises[k]`,
  /// - `exercises.length` is the gap below the last member.
  ///
  /// Return [SizedBox.shrink] for positions that should render nothing.
  /// When this builder is null, a plain [AppSpacing.sm] spacer is rendered
  /// only between consecutive members (no top/bottom gaps).
  final Widget Function(int position)? gapBuilder;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final anyUnfinished = exercises.any(
      (e) => e.sessionExercise.state is UnfinishedState,
    );

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline, width: AppStroke.hairline),
      ),
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              AppSpacing.xs,
              AppSpacing.xs,
              AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (groupDragHandle != null) ...[
                  groupDragHandle!,
                  const SizedBox(width: AppSpacing.xs),
                ],
                AppIcon(
                  Icons.link,
                  color: colors.primary,
                  size: AppIconSize.sm,
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Superset',
                  style: typography.label.copyWith(color: colors.primary),
                ),
                const Spacer(),
                if (canMutate && anyUnfinished)
                  _SupersetHeaderMenu(
                    onMoveUp: onMoveUp,
                    onMoveDown: onMoveDown,
                    onUngroup: onUngroupPressed,
                  ),
              ],
            ),
          ),
          for (var i = 0; i <= exercises.length; i++) ...[
            if (gapBuilder != null)
              gapBuilder!(i)
            else if (i > 0 && i < exercises.length)
              const SizedBox(height: AppSpacing.sm),
            if (i < exercises.length)
              Builder(
                builder: (context) {
                  final memberId = exercises[i].sessionExercise.id;
                  final move = memberMoveBuilder?.call(exercises[i]);
                  return ExerciseCard(
                    viewModel: exercises[i],
                    isExpanded: expandedExerciseIds.contains(memberId),
                    canMutate: canMutate,
                    isCurrent: currentSessionExerciseIds.contains(memberId),
                    isLastTouched: lastTouchedSessionExerciseId == memberId,
                    onToggleExpansion: () => onToggleExpansion(memberId),
                    onLogSet: (values, plannedId) =>
                        onLogSet(memberId, values, plannedId),
                    onEditSet: onEditSet,
                    onEndOrSkipPressed: () => onEndOrSkipPressed(memberId),
                    onOpenVideo: onOpenVideo,
                    onAddSetPressed: onAddSetPressed == null
                        ? null
                        : () => onAddSetPressed!(memberId),
                    onResumePressed: onResumePressed == null
                        ? null
                        : () => onResumePressed!(memberId),
                    onMoveUp: move?.up,
                    onMoveDown: move?.down,
                    dragHandle: memberDragHandleBuilder?.call(exercises[i]),
                  );
                },
              ),
          ],
        ],
      ),
    );
  }
}

/// The superset header's single trailing overflow kebab. Holds Move up / Move
/// down (the whole-group reorder fallback) and Ungroup, so the header never
/// carries two competing trailing affordances. Move entries appear only when
/// the group is whole-move eligible (at least one direction available); a no-op
/// end is rendered disabled so the menu layout stays stable, mirroring the
/// per-exercise card kebab.
class _SupersetHeaderMenu extends StatelessWidget {
  const _SupersetHeaderMenu({
    required this.onMoveUp,
    required this.onMoveDown,
    required this.onUngroup,
  });

  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;
  final VoidCallback onUngroup;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final canReorder = onMoveUp != null || onMoveDown != null;
    return PopupMenuButton<_SupersetMenuAction>(
      tooltip: 'Superset actions',
      icon: AppIcon(
        Icons.more_vert,
        color: colors.onSurfaceMuted,
        size: AppIconSize.lg,
      ),
      padding: EdgeInsets.zero,
      onSelected: (action) {
        switch (action) {
          case _SupersetMenuAction.moveUp:
            onMoveUp?.call();
          case _SupersetMenuAction.moveDown:
            onMoveDown?.call();
          case _SupersetMenuAction.ungroup:
            onUngroup();
        }
      },
      itemBuilder: (context) => [
        if (canReorder) ...[
          PopupMenuItem(
            value: _SupersetMenuAction.moveUp,
            enabled: onMoveUp != null,
            child: AppMenuRow(
              icon: Icons.arrow_upward,
              label: 'Move superset up',
              enabled: onMoveUp != null,
            ),
          ),
          PopupMenuItem(
            value: _SupersetMenuAction.moveDown,
            enabled: onMoveDown != null,
            child: AppMenuRow(
              icon: Icons.arrow_downward,
              label: 'Move superset down',
              enabled: onMoveDown != null,
            ),
          ),
        ],
        const PopupMenuItem(
          value: _SupersetMenuAction.ungroup,
          child: AppMenuRow(icon: Icons.call_split, label: 'Ungroup'),
        ),
      ],
    );
  }
}

enum _SupersetMenuAction { moveUp, moveDown, ungroup }
