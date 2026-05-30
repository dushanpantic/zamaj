import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_elevation.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/widgets/editor_drag_payload.dart';
import 'package:zamaj/modules/program_management/widgets/editor_exercise_tile_content.dart';

class EditorFlatExerciseRow extends StatelessWidget {
  const EditorFlatExerciseRow({
    super.key,
    required this.group,
    required this.exercise,
    required this.reorderIndex,
    required this.bloc,
    required this.isInvalid,
    required this.otherGroups,
    required this.onNavigateToExercise,
  });

  final ExerciseGroupDraft group;
  final ExerciseDraft exercise;
  final int reorderIndex;
  final WorkoutDayEditorBloc bloc;
  final bool isInvalid;
  final List<ExerciseGroupDraft> otherGroups;
  final void Function(String exerciseId) onNavigateToExercise;

  Future<void> _promptGroupInto(BuildContext context) async {
    if (otherGroups.isEmpty) return;
    final candidates = <({String groupDraftId, ExerciseDraft exercise})>[
      for (final g in otherGroups)
        for (final e in g.exercises) (groupDraftId: g.draftId, exercise: e),
    ];
    if (candidates.isEmpty) return;
    final picked =
        await showDialog<({String groupDraftId, String exerciseDraftId})>(
          context: context,
          builder: (ctx) {
            final colors = Theme.of(ctx).appColors;
            return AlertDialog(
              backgroundColor: colors.surfaceElevated,
              title: Text(
                'Group with…',
                style: TextStyle(color: colors.onSurface),
              ),
              contentPadding: const EdgeInsets.symmetric(
                vertical: AppSpacing.sm,
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    for (final c in candidates)
                      ListTile(
                        title: Text(
                          c.exercise.name.isEmpty
                              ? 'Unnamed exercise'
                              : c.exercise.name,
                          style: TextStyle(color: colors.onSurface),
                        ),
                        onTap: () => Navigator.of(ctx).pop((
                          groupDraftId: c.groupDraftId,
                          exerciseDraftId: c.exercise.draftId,
                        )),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colors.onSurfaceMuted),
                  ),
                ),
              ],
            );
          },
        );
    if (picked == null) return;
    bloc.add(
      ExerciseDraggedOntoExercise(
        sourceGroupDraftId: group.draftId,
        sourceExerciseDraftId: exercise.draftId,
        targetGroupDraftId: picked.groupDraftId,
        targetExerciseDraftId: picked.exerciseDraftId,
      ),
    );
  }

  Future<void> _confirmAndDelete(BuildContext context) async {
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
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isWarmup = group.role == ExerciseGroupRole.warmup;

    final payload = ExerciseDragPayload(
      groupDraftId: group.draftId,
      exerciseDraftId: exercise.draftId,
    );

    return DragTarget<ExerciseDragPayload>(
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
        return LongPressDraggable<ExerciseDragPayload>(
          data: payload,
          feedback: Material(
            elevation: AppElevation.drag,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - AppSpacing.lg * 2,
              child: EditorExerciseTileContent(
                exercise: exercise,
                colors: colors,
                isWarmup: isWarmup,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: EditorExerciseTileContent(
              exercise: exercise,
              colors: colors,
              isWarmup: isWarmup,
            ),
          ),
          child: Dismissible(
            key: ValueKey('dismiss_${exercise.draftId}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              await _confirmAndDelete(context);
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
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
            child: Container(
              decoration: BoxDecoration(
                color: isDropTarget
                    ? colors.primary.withValues(alpha: AppOpacity.tintFill)
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: isDropTarget
                    ? Border.all(
                        color: colors.primary,
                        width: AppStroke.emphasis,
                      )
                    : null,
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
                    padding: const EdgeInsets.only(
                      left: AppSpacing.md,
                      top: AppSpacing.sm,
                      bottom: AppSpacing.sm,
                    ),
                    child: Row(
                      children: [
                        ReorderableDragStartListener(
                          index: reorderIndex,
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
                            isWarmup: isWarmup,
                            isInvalid: isInvalid,
                          ),
                        ),
                        PopupMenuButton<GroupMenuAction>(
                          tooltip: 'Exercise actions',
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
                              case GroupMenuAction.group:
                                _promptGroupInto(context);
                              case GroupMenuAction.delete:
                                _confirmAndDelete(context);
                              case GroupMenuAction.ungroup:
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
                            if (otherGroups.isNotEmpty)
                              const PopupMenuItem(
                                value: GroupMenuAction.group,
                                child: ListTile(
                                  leading: Icon(Icons.merge_type),
                                  title: Text('Group into superset'),
                                  contentPadding: EdgeInsets.zero,
                                  dense: true,
                                ),
                              ),
                            const PopupMenuItem(
                              value: GroupMenuAction.delete,
                              child: ListTile(
                                leading: Icon(Icons.delete_outline),
                                title: Text('Delete'),
                                contentPadding: EdgeInsets.zero,
                                dense: true,
                              ),
                            ),
                          ],
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
  }
}
