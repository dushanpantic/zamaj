import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/widgets/add_exercise_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/editor_flat_exercise_row.dart';
import 'package:zamaj/modules/program_management/widgets/editor_superset_card.dart';

class WorkoutDayExerciseList extends StatelessWidget {
  const WorkoutDayExerciseList({
    super.key,
    required this.draft,
    required this.validation,
    required this.onNavigateToExercise,
  });

  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;
  final void Function(String exerciseId) onNavigateToExercise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bloc = context.read<WorkoutDayEditorBloc>();

    if (draft.groups.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                color: colors.onSurfaceMuted,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No exercises yet.',
                style: AppTypography.standard.bodySmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: () => startAddExercise(context, bloc),
                icon: const Icon(Icons.add),
                label: const Text('Add exercise'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size(0, AppSpacing.touchMin),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
      ),
      itemCount: draft.groups.length,
      onReorder: (oldIndex, newIndex) {
        final ids = draft.groups.map((g) => g.draftId).toList();
        if (newIndex > oldIndex) newIndex -= 1;
        final moved = ids.removeAt(oldIndex);
        ids.insert(newIndex, moved);
        bloc.add(ExerciseGroupsReordered(orderedGroupDraftIds: ids));
      },
      itemBuilder: (context, index) {
        final group = draft.groups[index];
        if (group.exercises.length == 1) {
          final exercise = group.exercises.first;
          return Padding(
            key: ValueKey(group.draftId),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: EditorFlatExerciseRow(
              group: group,
              exercise: exercise,
              reorderIndex: index,
              bloc: bloc,
              isInvalid: validation.invalidExerciseDraftIds.contains(
                exercise.draftId,
              ),
              otherGroups: draft.groups
                  .where((g) => g.draftId != group.draftId)
                  .toList(),
              onNavigateToExercise: onNavigateToExercise,
            ),
          );
        }
        return EditorSupersetCard(
          key: ValueKey(group.draftId),
          group: group,
          reorderIndex: index,
          bloc: bloc,
          validation: validation,
          onNavigateToExercise: onNavigateToExercise,
        );
      },
    );
  }
}
