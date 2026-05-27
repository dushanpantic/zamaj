import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

/// Wraps a contiguous run of exercises that share a `supersetTag` in a
/// labeled container with an "ungroup" action. The header is the only
/// part that's superset-specific; the individual exercise cards inside
/// are unchanged from the standalone single-exercise display.
class SupersetCard extends StatelessWidget {
  const SupersetCard({
    super.key,
    required this.tag,
    required this.exercises,
    required this.expandedExerciseIds,
    required this.canMutate,
    required this.onUngroupPressed,
    required this.onToggleExpansion,
    required this.onLogSet,
    required this.onEditSet,
    required this.onSkipPressed,
    required this.onMarkDonePressed,
    required this.onReplacePressed,
    required this.onOpenVideo,
    this.currentSessionExerciseIds = const <String>{},
    this.lastTouchedSessionExerciseId,
    this.isDropTarget = false,
    this.memberDragHandleBuilder,
    this.gapBuilder,
  });

  final String tag;
  final List<ExerciseViewModel> exercises;
  final Set<String> expandedExerciseIds;
  final bool canMutate;
  final VoidCallback onUngroupPressed;
  final void Function(String sessionExerciseId) onToggleExpansion;
  final void Function(
    String sessionExerciseId,
    ActualSetValues values,
    String? plannedSetIdInSnapshot,
  )
  onLogSet;
  final void Function(String executedSetId, ActualSetValues values) onEditSet;
  final void Function(String sessionExerciseId) onSkipPressed;
  final void Function(String sessionExerciseId) onMarkDonePressed;
  final void Function(String sessionExerciseId) onReplacePressed;
  final void Function(String videoUrl) onOpenVideo;

  /// Members that should render the CURRENT chip + accent border. Includes
  /// every unfinished member of the active superset; the screen computes
  /// the set from `openTargets.first` and the assembled groups.
  final Set<String> currentSessionExerciseIds;
  final String? lastTouchedSessionExerciseId;
  final bool isDropTarget;

  /// Optional per-member drag-handle builder. When non-null and the returned
  /// widget is non-null, the handle is rendered in the member card's leading
  /// 48 dp slot. The workout-overview screen returns a [LongPressDraggable]-
  /// wrapped icon so the drag-to-reorder gesture lives on the handle only
  /// and doesn't fight taps elsewhere on the card.
  final Widget? Function(ExerciseViewModel member)? memberDragHandleBuilder;

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
        border: Border.all(
          color: isDropTarget ? colors.primary : colors.outline,
          width: isDropTarget ? 2 : 1,
        ),
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
                Icon(Icons.link, color: colors.primary, size: 16),
                const SizedBox(width: AppSpacing.xs),
                Text(
                  'Superset',
                  style: typography.label.copyWith(color: colors.primary),
                ),
                const Spacer(),
                if (canMutate && anyUnfinished)
                  TextButton.icon(
                    onPressed: onUngroupPressed,
                    icon: const Icon(Icons.call_split, size: 16),
                    label: const Text('Ungroup'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      minimumSize: const Size(0, 32),
                    ),
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
                    onSkipPressed: () => onSkipPressed(memberId),
                    onMarkDonePressed: () => onMarkDonePressed(memberId),
                    onReplacePressed: () => onReplacePressed(memberId),
                    onOpenVideo: onOpenVideo,
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
