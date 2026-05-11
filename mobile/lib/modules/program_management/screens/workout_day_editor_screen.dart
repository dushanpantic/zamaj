import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';

class WorkoutDayEditorScreen extends StatefulWidget {
  const WorkoutDayEditorScreen({super.key, required this.args});

  final WorkoutDayArgs args;

  @override
  State<WorkoutDayEditorScreen> createState() => _WorkoutDayEditorScreenState();
}

class _WorkoutDayEditorScreenState extends State<WorkoutDayEditorScreen> {
  late final TextEditingController _nameController;
  bool _initialLoadDispatched = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    context.read<WorkoutDayEditorBloc>().add(
      WorkoutDayEditorOpened(workoutDayId: widget.args.workoutDayId),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _syncNameController(String name) {
    if (_nameController.text != name) {
      _nameController.value = _nameController.value.copyWith(
        text: name,
        selection: TextSelection.collapsed(offset: name.length),
      );
    }
  }

  void _navigateToExercise(String exerciseId) {
    Navigator.of(context)
        .pushNamed(
          ProgramManagementRoutes.exercise,
          arguments: ExerciseArgs(exerciseId: exerciseId),
        )
        .then((_) {
          if (mounted) {
            context.read<WorkoutDayEditorBloc>().add(
              const WorkoutDayEditorRefreshed(),
            );
          }
        });
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutDayEditorBloc, WorkoutDayEditorState>(
      listenWhen: (previous, current) {
        if (current is WorkoutDayEditorExerciseCreated) return true;
        if (current is WorkoutDayEditorEditing && !_initialLoadDispatched) {
          return true;
        }
        return false;
      },
      listener: (context, state) {
        if (state is WorkoutDayEditorExerciseCreated) {
          _navigateToExercise(state.exerciseId);
          return;
        }
        if (state is WorkoutDayEditorEditing) {
          if (!_initialLoadDispatched) {
            _initialLoadDispatched = true;
            _syncNameController(state.draft.name);
          }
        }
      },
      builder: (context, state) {
        return switch (state) {
          WorkoutDayEditorInitial() => const _LoadingView(),
          WorkoutDayEditorLoading() => const _LoadingView(),
          WorkoutDayEditorNotFound(:final workoutDayId) => _NotFoundView(
            workoutDayId: workoutDayId,
          ),
          WorkoutDayEditorExerciseCreated(:final draft, :final validation) =>
            _EditingBody(
              nameController: _nameController,
              draft: draft,
              validation: validation,
              isSaving: false,
              lastSaveError: null,
            ),
          WorkoutDayEditorEditing(
            :final draft,
            :final validation,
            :final isSaving,
            :final lastSaveError,
          ) =>
            _EditingBody(
              nameController: _nameController,
              draft: draft,
              validation: validation,
              isSaving: isSaving,
              lastSaveError: lastSaveError,
            ),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(child: CircularProgressIndicator(color: colors.primary)),
    );
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView({required this.workoutDayId});

  final String workoutDayId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: colors.error, size: 48),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Workout day not found.',
                style: TextStyle(
                  color: colors.onBackground,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                ),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditingBody extends StatelessWidget {
  const _EditingBody({
    required this.nameController,
    required this.draft,
    required this.validation,
    required this.isSaving,
    required this.lastSaveError,
  });

  final TextEditingController nameController;
  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;
  final bool isSaving;
  final DomainError? lastSaveError;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bloc = context.read<WorkoutDayEditorBloc>();

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        title: _NameField(
          controller: nameController,
          isValid: validation.isNameValid,
          onChanged: (name) => bloc.add(WorkoutDayNameChanged(name: name)),
        ),
        actions: [
          if (isSaving)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.md),
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
          IconButton(
            icon: Icon(Icons.add, color: colors.primary),
            tooltip: 'Add exercise',
            onPressed: isSaving
                ? null
                : () => _showAddExerciseDialog(context, bloc),
          ),
        ],
      ),
      body: Column(
        children: [
          if (lastSaveError != null) _SaveErrorBanner(error: lastSaveError!),
          Expanded(
            child: _ExerciseList(draft: draft),
          ),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(
    BuildContext context,
    WorkoutDayEditorBloc bloc,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddExerciseDialog(bloc: bloc),
    );
  }
}

class _NameField extends StatelessWidget {
  const _NameField({
    required this.controller,
    required this.isValid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isValid;
  final void Function(String) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(color: colors.onSurface, fontSize: 16),
      decoration: InputDecoration(
        hintText: 'Day name',
        hintStyle: TextStyle(color: colors.onSurfaceMuted),
        border: InputBorder.none,
        errorText: isValid || controller.text.isEmpty
            ? null
            : 'Name must be 1–100 characters',
        errorStyle: TextStyle(color: colors.error, fontSize: 11),
      ),
      maxLength: 100,
      buildCounter:
          (_, {required currentLength, required isFocused, maxLength}) => null,
    );
  }
}

class _ExerciseList extends StatelessWidget {
  const _ExerciseList({required this.draft});

  final WorkoutDayDraft draft;

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
                Icons.fitness_center,
                color: colors.onSurfaceMuted,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No exercises yet.\nTap + to add one.',
                style: TextStyle(color: colors.onSurfaceMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.all(AppSpacing.lg),
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
          return _FlatExerciseRow(
            key: ValueKey(group.draftId),
            group: group,
            exercise: group.exercises.first,
            reorderIndex: index,
            bloc: bloc,
            onNavigateToExercise: (id) {
              final screenState = context.findAncestorStateOfType<
                  _WorkoutDayEditorScreenState>();
              screenState?._navigateToExercise(id);
            },
          );
        }
        return _SupersetCard(
          key: ValueKey(group.draftId),
          group: group,
          reorderIndex: index,
          bloc: bloc,
          onNavigateToExercise: (id) {
            final screenState = context.findAncestorStateOfType<
                _WorkoutDayEditorScreenState>();
            screenState?._navigateToExercise(id);
          },
        );
      },
    );
  }
}

class _ExerciseDragPayload {
  const _ExerciseDragPayload({
    required this.groupDraftId,
    required this.exerciseDraftId,
  });

  final String groupDraftId;
  final String exerciseDraftId;
}

class _FlatExerciseRow extends StatelessWidget {
  const _FlatExerciseRow({
    super.key,
    required this.group,
    required this.exercise,
    required this.reorderIndex,
    required this.bloc,
    required this.onNavigateToExercise,
  });

  final ExerciseGroupDraft group;
  final ExerciseDraft exercise;
  final int reorderIndex;
  final WorkoutDayEditorBloc bloc;
  final void Function(String exerciseId) onNavigateToExercise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    final payload = _ExerciseDragPayload(
      groupDraftId: group.draftId,
      exerciseDraftId: exercise.draftId,
    );

    return DragTarget<_ExerciseDragPayload>(
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
        return LongPressDraggable<_ExerciseDragPayload>(
          data: payload,
          feedback: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            child: SizedBox(
              width: MediaQuery.of(context).size.width - AppSpacing.lg * 2,
              child: _ExerciseTileContent(
                exercise: exercise,
                colors: colors,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _ExerciseTileContent(
              exercise: exercise,
              colors: colors,
            ),
          ),
          child: Dismissible(
            key: ValueKey('dismiss_${exercise.draftId}'),
            direction: DismissDirection.endToStart,
            confirmDismiss: (_) async {
              bloc.add(
                ExerciseRemovedFromGroup(
                  groupDraftId: group.draftId,
                  exerciseDraftId: exercise.draftId,
                ),
              );
              return false;
            },
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: AppSpacing.lg),
              decoration: BoxDecoration(
                color: colors.error,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(
                Icons.delete_outline,
                color: colors.onPrimary,
                size: 20,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: isDropTarget
                    ? Border.all(color: colors.primary, width: 2)
                    : null,
              ),
              child: Material(
                color: colors.surfaceVariant,
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
                          index: reorderIndex,
                          child: Padding(
                            padding: const EdgeInsets.only(
                              right: AppSpacing.sm,
                            ),
                            child: Icon(
                              Icons.drag_handle,
                              color: colors.onSurfaceMuted,
                              size: 20,
                            ),
                          ),
                        ),
                        Expanded(
                          child: _ExerciseTileContent(
                            exercise: exercise,
                            colors: colors,
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
  }
}

class _ExerciseTileContent extends StatelessWidget {
  const _ExerciseTileContent({
    required this.exercise,
    required this.colors,
  });

  final ExerciseDraft exercise;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final setCount = exercise.sets.length;
    final typeLabel = switch (exercise.measurementType) {
      RepBasedMeasurement() => 'Rep-based',
      TimeBasedMeasurement() => 'Time-based',
    };
    final subtitle = setCount > 0 ? '$setCount sets · $typeLabel' : typeLabel;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          exercise.name.isEmpty ? 'Unnamed exercise' : exercise.name,
          style: TextStyle(
            color: colors.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle,
          style: TextStyle(color: colors.onSurfaceMuted, fontSize: 12),
        ),
      ],
    );
  }
}

class _SupersetCard extends StatelessWidget {
  const _SupersetCard({
    super.key,
    required this.group,
    required this.reorderIndex,
    required this.bloc,
    required this.onNavigateToExercise,
  });

  final ExerciseGroupDraft group;
  final int reorderIndex;
  final WorkoutDayEditorBloc bloc;
  final void Function(String exerciseId) onNavigateToExercise;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

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
                    style: TextStyle(
                      color: colors.onSurfaceMuted,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: Icon(
                    Icons.call_split,
                    color: colors.onSurfaceMuted,
                    size: 20,
                  ),
                  onPressed: () => bloc.add(
                    SupersetUngrouped(groupDraftId: group.draftId),
                  ),
                  tooltip: 'Ungroup superset',
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: AppSpacing.touchMin,
                    minHeight: AppSpacing.touchMin,
                  ),
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
                final payload = _ExerciseDragPayload(
                  groupDraftId: group.draftId,
                  exerciseDraftId: exercise.draftId,
                );

                return DragTarget<_ExerciseDragPayload>(
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
                    return LongPressDraggable<_ExerciseDragPayload>(
                      data: payload,
                      feedback: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                        child: SizedBox(
                          width: MediaQuery.of(context).size.width -
                              AppSpacing.lg * 4,
                          child: _ExerciseTileContent(
                            exercise: exercise,
                            colors: colors,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _ExerciseTileContent(
                          exercise: exercise,
                          colors: colors,
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.only(bottom: AppSpacing.xs),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                          border: isDropTarget
                              ? Border.all(color: colors.primary, width: 2)
                              : null,
                        ),
                        child: Dismissible(
                          key: ValueKey('dismiss_superset_${exercise.draftId}'),
                          direction: DismissDirection.endToStart,
                          confirmDismiss: (_) async {
                            bloc.add(
                              ExerciseRemovedFromGroup(
                                groupDraftId: group.draftId,
                                exerciseDraftId: exercise.draftId,
                              ),
                            );
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
                            child: Icon(
                              Icons.delete_outline,
                              color: colors.onPrimary,
                              size: 20,
                            ),
                          ),
                          child: Material(
                            color: colors.surfaceVariant,
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
                                        child: Icon(
                                          Icons.drag_handle,
                                          color: colors.onSurfaceMuted,
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: _ExerciseTileContent(
                                        exercise: exercise,
                                        colors: colors,
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
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => _showAddToSupersetDialog(context, bloc),
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
            ),
          ],
        ),
      ),
    );
  }

  void _showAddToSupersetDialog(
    BuildContext context,
    WorkoutDayEditorBloc bloc,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddExerciseDialog(
        bloc: bloc,
        groupDraftId: group.draftId,
      ),
    );
  }
}

class _SaveErrorBanner extends StatelessWidget {
  const _SaveErrorBanner({required this.error});

  final DomainError error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: colors.error.withValues(alpha: 0.12),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 16),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Failed to save. Please try again.',
              style: TextStyle(color: colors.error, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({required this.bloc, this.groupDraftId});

  final WorkoutDayEditorBloc bloc;
  final String? groupDraftId;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;
    if (widget.groupDraftId != null) {
      widget.bloc.add(
        ExerciseAddedToGroup(
          groupDraftId: widget.groupDraftId!,
          exerciseName: trimmed,
        ),
      );
    } else {
      widget.bloc.add(QuickExerciseAdded(exerciseName: trimmed));
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text('Add exercise', style: TextStyle(color: colors.onSurface)),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        style: TextStyle(color: colors.onSurface),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Exercise name',
          labelStyle: TextStyle(color: colors.onSurfaceMuted),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.outline),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.onSurfaceMuted)),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
