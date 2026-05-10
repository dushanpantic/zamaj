import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/widgets/exercise_tile.dart';

class ExerciseGroupCard extends StatelessWidget {
  const ExerciseGroupCard({
    super.key,
    required this.group,
    required this.onDelete,
    required this.onAddExercise,
    required this.onDeleteExercise,
    required this.onReorderExercises,
    required this.onTapExercise,
    this.validationError,
    this.reorderIndex,
  });

  final ExerciseGroupDraft group;
  final VoidCallback onDelete;
  final VoidCallback onAddExercise;
  final void Function(String exerciseDraftId) onDeleteExercise;
  final void Function(List<String> orderedIds) onReorderExercises;
  final void Function(String exerciseDraftId) onTapExercise;
  final String? validationError;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final kind = group.kind();

    return Card(
      color: colors.surface,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _GroupHeader(
              kind: kind,
              onDelete: onDelete,
              reorderIndex: reorderIndex,
            ),
            if (validationError != null) ...[
              const SizedBox(height: AppSpacing.sm),
              _CardinalityErrorBanner(invariant: validationError!),
            ],
            if (group.exercises.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.sm),
              _ExerciseList(
                group: group,
                onDeleteExercise: onDeleteExercise,
                onReorderExercises: onReorderExercises,
                onTapExercise: onTapExercise,
              ),
            ],
            const SizedBox(height: AppSpacing.sm),
            _AddExerciseButton(onAddExercise: onAddExercise),
          ],
        ),
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  const _GroupHeader({
    required this.kind,
    required this.onDelete,
    this.reorderIndex,
  });

  final ExerciseGroupKind kind;
  final VoidCallback onDelete;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final label = switch (kind) {
      SingleKind() => 'Single',
      SupersetKind() => 'Superset',
    };

    return Row(
      children: [
        if (reorderIndex != null)
          ReorderableDragStartListener(
            index: reorderIndex!,
            child: Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Icon(Icons.drag_handle, color: colors.onSurfaceMuted),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.sm),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceMuted,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const Spacer(),
        IconButton(
          icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
          onPressed: onDelete,
          tooltip: 'Delete group',
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(
            minWidth: AppSpacing.touchMin,
            minHeight: AppSpacing.touchMin,
          ),
        ),
      ],
    );
  }
}

class _CardinalityErrorBanner extends StatelessWidget {
  const _CardinalityErrorBanner({required this.invariant});

  final String invariant;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final message = switch (invariant) {
      'single_requires_exactly_one_exercise' =>
        'A Single group must have exactly 1 exercise.',
      'superset_requires_at_least_two_exercises' =>
        'A Superset group must have at least 2 exercises.',
      'empty_group' => 'A group must have at least 1 exercise.',
      _ => 'Invalid group configuration.',
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({
    required this.group,
    required this.onDeleteExercise,
    required this.onReorderExercises,
    required this.onTapExercise,
  });

  final ExerciseGroupDraft group;
  final void Function(String exerciseDraftId) onDeleteExercise;
  final void Function(List<String> orderedIds) onReorderExercises;
  final void Function(String exerciseDraftId) onTapExercise;

  @override
  Widget build(BuildContext context) {
    return ReorderableListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: group.exercises.length,
      onReorder: (oldIndex, newIndex) {
        final ids = group.exercises.map((e) => e.draftId).toList();
        if (newIndex > oldIndex) newIndex -= 1;
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        onReorderExercises(ids);
      },
      itemBuilder: (context, index) {
        final exercise = group.exercises[index];
        return Padding(
          key: ValueKey(exercise.draftId),
          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
          child: ExerciseTile(
            exercise: exercise,
            onTap: () => onTapExercise(exercise.draftId),
            onDelete: () => onDeleteExercise(exercise.draftId),
            reorderIndex: index,
          ),
        );
      },
    );
  }
}

class _AddExerciseButton extends StatelessWidget {
  const _AddExerciseButton({required this.onAddExercise});

  final VoidCallback onAddExercise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return TextButton.icon(
      onPressed: onAddExercise,
      icon: Icon(Icons.add, color: colors.primary, size: 18),
      label: Text(
        'Add exercise',
        style: TextStyle(color: colors.primary, fontSize: 13),
      ),
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        minimumSize: const Size(0, AppSpacing.touchMin),
      ),
    );
  }
}
