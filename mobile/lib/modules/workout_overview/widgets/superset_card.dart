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
    this.lastTouchedSessionExerciseId,
    this.showDragHandle = false,
    this.isDropTarget = false,
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
  final String? lastTouchedSessionExerciseId;
  final bool showDragHandle;
  final bool isDropTarget;

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
                if (showDragHandle && anyUnfinished)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xs),
                    child: Icon(
                      Icons.drag_indicator,
                      color: colors.onSurfaceMuted,
                      size: 20,
                    ),
                  ),
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
          for (var i = 0; i < exercises.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.sm),
            ExerciseCard(
              viewModel: exercises[i],
              isExpanded: expandedExerciseIds.contains(
                exercises[i].sessionExercise.id,
              ),
              canMutate: canMutate,
              isLastTouched:
                  lastTouchedSessionExerciseId ==
                  exercises[i].sessionExercise.id,
              onToggleExpansion: () =>
                  onToggleExpansion(exercises[i].sessionExercise.id),
              onLogSet: (values, plannedId) =>
                  onLogSet(exercises[i].sessionExercise.id, values, plannedId),
              onEditSet: onEditSet,
              onSkipPressed: () =>
                  onSkipPressed(exercises[i].sessionExercise.id),
              onMarkDonePressed: () =>
                  onMarkDonePressed(exercises[i].sessionExercise.id),
              onReplacePressed: () =>
                  onReplacePressed(exercises[i].sessionExercise.id),
              onOpenVideo: onOpenVideo,
            ),
          ],
        ],
      ),
    );
  }
}
