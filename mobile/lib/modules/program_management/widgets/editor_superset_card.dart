import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_elevation.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/widgets/editor_drag_payload.dart';
import 'package:zamaj/modules/program_management/widgets/editor_exercise_tile_content.dart';

class EditorSupersetCard extends StatelessWidget {
  const EditorSupersetCard({
    super.key,
    required this.group,
    required this.reorderIndex,
    required this.bloc,
    required this.validation,
    required this.onNavigateToExercise,
  });

  final ExerciseGroupDraft group;
  final int reorderIndex;
  final WorkoutDayEditorBloc bloc;
  final WorkoutDayDraftValidation validation;
  final void Function(String exerciseId) onNavigateToExercise;

  static String _positionLabel(int index) {
    return 'A${index + 1}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isWarmup = group.role == ExerciseGroupRole.warmup;

    return Card(
      color: colors.surface,
      margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        side: BorderSide(color: colors.outline),
      ),
      child: Padding(
        padding: const EdgeInsets.only(
          left: AppSpacing.md,
          right: AppSpacing.sm,
          top: AppSpacing.md,
          bottom: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                ReorderableDragStartListener(
                  index: reorderIndex,
                  child: Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.sm),
                    child: Icon(
                      Icons.drag_handle,
                      color: colors.onSurfaceMuted,
                    ),
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
                    'Superset',
                    style: AppTypography.standard.badge.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ),
                if (isWarmup) ...[
                  const SizedBox(width: AppSpacing.sm),
                  EditorWarmupBadge(colors: colors),
                ],
                const Spacer(),
                PopupMenuButton<GroupMenuAction>(
                  tooltip: 'Superset actions',
                  icon: AppIcon(
                    Icons.more_vert,
                    color: colors.onSurfaceMuted,
                    size: AppIconSize.lg,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (action) {
                    switch (action) {
                      case GroupMenuAction.toggleWarmup:
                        bloc.add(
                          ExerciseGroupRoleToggled(
                            groupDraftId: group.draftId,
                            role: isWarmup
                                ? ExerciseGroupRole.main
                                : ExerciseGroupRole.warmup,
                          ),
                        );
                      case GroupMenuAction.ungroup:
                        bloc.add(
                          SupersetUngrouped(groupDraftId: group.draftId),
                        );
                      case GroupMenuAction.group:
                      case GroupMenuAction.delete:
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: GroupMenuAction.toggleWarmup,
                      child: ListTile(
                        leading: Icon(
                          isWarmup
                              ? Icons.fitness_center
                              : Icons.local_fire_department,
                        ),
                        title: Text(
                          isWarmup ? 'Mark as main' : 'Mark as warmup',
                        ),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: GroupMenuAction.ungroup,
                      child: ListTile(
                        leading: Icon(Icons.call_split),
                        title: Text('Ungroup superset'),
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: group.exercises.length,
              onReorder: (oldIndex, newIndex) {
                final ids = group.exercises.map((e) => e.draftId).toList();
                if (newIndex > oldIndex) newIndex -= 1;
                final moved = ids.removeAt(oldIndex);
                ids.insert(newIndex, moved);
                bloc.add(
                  ExerciseReorderedWithinGroup(
                    groupDraftId: group.draftId,
                    orderedExerciseDraftIds: ids,
                  ),
                );
              },
              itemBuilder: (context, index) {
                final exercise = group.exercises[index];
                final payload = ExerciseDragPayload(
                  groupDraftId: group.draftId,
                  exerciseDraftId: exercise.draftId,
                );

                return DragTarget<ExerciseDragPayload>(
                  key: ValueKey(exercise.draftId),
                  onWillAcceptWithDetails: (details) =>
                      details.data.exerciseDraftId != exercise.draftId,
                  onAcceptWithDetails: (details) {
                    bloc.add(
                      ExerciseDraggedOntoExercise(
                        sourceGroupDraftId: details.data.groupDraftId,
                        sourceExerciseDraftId: details.data.exerciseDraftId,
                        targetGroupDraftId: group.draftId,
                        targetExerciseDraftId: exercise.draftId,
                      ),
                    );
                  },
                  builder: (context, candidateData, rejectedData) {
                    final isDropTarget = candidateData.isNotEmpty;
                    final positionLabel = _positionLabel(index);
                    final isInvalid = validation.invalidExerciseDraftIds
                        .contains(exercise.draftId);
                    return LongPressDraggable<ExerciseDragPayload>(
                      data: payload,
                      feedback: Material(
                        elevation: AppElevation.drag,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: SizedBox(
                          width:
                              MediaQuery.of(context).size.width -
                              AppSpacing.lg * 4,
                          child: EditorExerciseTileContent(
                            exercise: exercise,
                            colors: colors,
                            isInvalid: isInvalid,
                            supersetPositionLabel: positionLabel,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: EditorExerciseTileContent(
                          exercise: exercise,
                          colors: colors,
                          isInvalid: isInvalid,
                          supersetPositionLabel: positionLabel,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        decoration: BoxDecoration(
                          color: isDropTarget
                              ? colors.primary.withValues(
                                  alpha: AppOpacity.tintFill,
                                )
                              : null,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: isDropTarget
                              ? Border.all(
                                  color: colors.primary,
                                  width: AppStroke.emphasis,
                                )
                              : null,
                        ),
                        child: Dismissible(
                          key: ValueKey('dismiss_superset_${exercise.draftId}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            final confirmed = await AppConfirmDialog.show(
                              context: context,
                              title: 'Delete exercise?',
                              body:
                                  'Removes "${exercise.name.isEmpty ? 'Unnamed exercise' : exercise.name}". Can\'t be undone.',
                              confirmLabel: 'Delete',
                              isDestructive: true,
                            );
                            if (confirmed == true) {
                              bloc.add(
                                ExerciseRemovedFromGroup(
                                  groupDraftId: group.draftId,
                                  exerciseDraftId: exercise.draftId,
                                ),
                              );
                            }
                            return false;
                          },
                          background: Container(
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(
                              right: AppSpacing.lg,
                            ),
                            decoration: BoxDecoration(
                              color: colors.error,
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                            ),
                            child: AppIcon(
                              Icons.delete_outline,
                              color: colors.onPrimary,
                              size: AppIconSize.lg,
                            ),
                          ),
                          child: Material(
                            color: isDropTarget
                                ? Colors.transparent
                                : colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                            child: InkWell(
                              onTap: () {
                                if (exercise.persistedId != null) {
                                  onNavigateToExercise(exercise.persistedId!);
                                }
                              },
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                child: Row(
                                  children: [
                                    ReorderableDragStartListener(
                                      index: index,
                                      child: Padding(
                                        padding: const EdgeInsets.only(
                                          right: AppSpacing.sm,
                                        ),
                                        child: AppIcon(
                                          Icons.drag_handle,
                                          color: colors.onSurfaceMuted,
                                          size: AppIconSize.lg,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: EditorExerciseTileContent(
                                        exercise: exercise,
                                        colors: colors,
                                        isInvalid: isInvalid,
                                        supersetPositionLabel: positionLabel,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
