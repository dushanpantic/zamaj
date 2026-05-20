import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/rest_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';

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
                style: AppTypography.standard.titleSmall.copyWith(
                  color: colors.onBackground,
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
          Expanded(child: _ExerciseList(draft: draft)),
        ],
      ),
    );
  }

  void _showAddExerciseDialog(BuildContext context, WorkoutDayEditorBloc bloc) {
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
      style: AppTypography.standard.body.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: 'Day name',
        hintStyle: AppTypography.standard.body.copyWith(
          color: colors.onSurfaceMuted,
        ),
        border: InputBorder.none,
        errorText: isValid || controller.text.isEmpty
            ? null
            : 'Name must be 1–100 characters',
        errorStyle: AppTypography.standard.caption.copyWith(
          color: colors.error,
        ),
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
                Icons.fitness_center_outlined,
                color: colors.onSurfaceMuted,
                size: 48,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No exercises yet.\nTap + to add one.',
                style: AppTypography.standard.bodySmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
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
          return Padding(
            key: ValueKey(group.draftId),
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FlatExerciseRow(
              group: group,
              exercise: group.exercises.first,
              reorderIndex: index,
              bloc: bloc,
              onNavigateToExercise: (id) {
                final screenState = context
                    .findAncestorStateOfType<_WorkoutDayEditorScreenState>();
                screenState?._navigateToExercise(id);
              },
            ),
          );
        }
        return _SupersetCard(
          key: ValueKey(group.draftId),
          group: group,
          reorderIndex: index,
          bloc: bloc,
          onNavigateToExercise: (id) {
            final screenState = context
                .findAncestorStateOfType<_WorkoutDayEditorScreenState>();
            screenState?._navigateToExercise(id);
          },
        );
      },
    );
  }
}

class _WarmupBadge extends StatelessWidget {
  const _WarmupBadge({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.warmup.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.warmup.withValues(alpha: 0.5)),
      ),
      child: Text(
        'WARMUP',
        style: AppTypography.standard.caption.copyWith(color: colors.warmup),
      ),
    );
  }
}

enum _GroupMenuAction { toggleWarmup, ungroup, delete }

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

  Future<void> _confirmAndDelete(BuildContext context) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Exercise',
      body:
          'Delete "${exercise.name.isEmpty ? 'Unnamed exercise' : exercise.name}"? This cannot be undone.',
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
                isWarmup: isWarmup,
              ),
            ),
          ),
          childWhenDragging: Opacity(
            opacity: 0.3,
            child: _ExerciseTileContent(
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
                            isWarmup: isWarmup,
                          ),
                        ),
                        PopupMenuButton<_GroupMenuAction>(
                          tooltip: 'Exercise actions',
                          icon: Icon(
                            Icons.more_vert,
                            color: colors.onSurfaceMuted,
                            size: 20,
                          ),
                          padding: EdgeInsets.zero,
                          onSelected: (action) {
                            switch (action) {
                              case _GroupMenuAction.toggleWarmup:
                                bloc.add(
                                  ExerciseGroupRoleToggled(
                                    groupDraftId: group.draftId,
                                    role: isWarmup
                                        ? ExerciseGroupRole.main
                                        : ExerciseGroupRole.warmup,
                                  ),
                                );
                              case _GroupMenuAction.delete:
                                _confirmAndDelete(context);
                              case _GroupMenuAction.ungroup:
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: _GroupMenuAction.toggleWarmup,
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
                              value: _GroupMenuAction.delete,
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

class _ExerciseTileContent extends StatelessWidget {
  const _ExerciseTileContent({
    required this.exercise,
    required this.colors,
    this.isWarmup = false,
  });

  final ExerciseDraft exercise;
  final AppColors colors;
  final bool isWarmup;

  @override
  Widget build(BuildContext context) {
    final subtitle = _subtitleFor(exercise);
    final rest = exercise.plannedRestSeconds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                exercise.name.isEmpty ? 'Unnamed exercise' : exercise.name,
                style: AppTypography.standard.label.copyWith(
                  color: colors.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isWarmup) ...[
              const SizedBox(width: AppSpacing.sm),
              _WarmupBadge(colors: colors),
            ],
          ],
        ),
        const SizedBox(height: 2),
        Row(
          children: [
            Flexible(
              child: Text(
                subtitle,
                style: AppTypography.standard.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (rest != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _RestChip(seconds: rest, colors: colors),
            ],
          ],
        ),
      ],
    );
  }

  static String _subtitleFor(ExerciseDraft exercise) {
    final sets = exercise.sets;
    final typeLabel = switch (exercise.measurementType) {
      RepBasedMeasurement() => 'Rep-based',
      TimeBasedMeasurement() => 'Time-based',
      BodyweightMeasurement() => 'Bodyweight',
    };
    if (sets.isEmpty) return typeLabel;

    final summary = _uniformSummary(sets);
    if (summary != null) return summary;
    return '${sets.length} sets · $typeLabel';
  }

  static String? _uniformSummary(List<PlannedSetDraft> sets) {
    final first = sets.first.values;
    switch (first) {
      case PlannedSetDraftRepBased():
        double? weight;
        int? reps;
        for (final set in sets) {
          final values = set.values;
          if (values is! PlannedSetDraftRepBased) return null;
          final w = double.tryParse(values.weightInput);
          final r = int.tryParse(values.repsInput);
          if (w == null || r == null) return null;
          weight ??= w;
          reps ??= r;
          if (w != weight || r != reps) return null;
        }
        return '${WeightFormatter.formatKg(weight!)}kg ${sets.length}×$reps';
      case PlannedSetDraftTimeBased():
        int? duration;
        double? weight;
        var weightSeen = false;
        for (final set in sets) {
          final values = set.values;
          if (values is! PlannedSetDraftTimeBased) return null;
          final d = int.tryParse(values.durationInput);
          if (d == null) return null;
          duration ??= d;
          if (d != duration) return null;

          final wInput = values.weightInput.trim();
          if (wInput.isEmpty) {
            if (weightSeen && weight != null) return null;
            weightSeen = true;
          } else {
            final w = double.tryParse(wInput);
            if (w == null) return null;
            if (weightSeen && weight != w) return null;
            weight = w;
            weightSeen = true;
          }
        }
        if (weight == null) return '${sets.length}×${duration}s';
        return '${WeightFormatter.formatKg(weight)}kg '
            '${sets.length}×${duration}s';
      case PlannedSetDraftBodyweight():
        String? reps;
        for (final set in sets) {
          final values = set.values;
          if (values is! PlannedSetDraftBodyweight) return null;
          reps ??= values.repsInput;
          if (values.repsInput != reps) return null;
        }
        return '${sets.length}×$reps';
    }
  }
}

class _RestChip extends StatelessWidget {
  const _RestChip({required this.seconds, required this.colors});

  final int seconds;
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
          style: AppTypography.standard.numericXs.copyWith(
            color: colors.onSurfaceMuted,
          ),
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
                  _WarmupBadge(colors: colors),
                ],
                const Spacer(),
                PopupMenuButton<_GroupMenuAction>(
                  tooltip: 'Superset actions',
                  icon: Icon(
                    Icons.more_vert,
                    color: colors.onSurfaceMuted,
                    size: 20,
                  ),
                  padding: EdgeInsets.zero,
                  onSelected: (action) {
                    switch (action) {
                      case _GroupMenuAction.toggleWarmup:
                        bloc.add(
                          ExerciseGroupRoleToggled(
                            groupDraftId: group.draftId,
                            role: isWarmup
                                ? ExerciseGroupRole.main
                                : ExerciseGroupRole.warmup,
                          ),
                        );
                      case _GroupMenuAction.ungroup:
                        bloc.add(
                          SupersetUngrouped(groupDraftId: group.draftId),
                        );
                      case _GroupMenuAction.delete:
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: _GroupMenuAction.toggleWarmup,
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
                      value: _GroupMenuAction.ungroup,
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
                          width:
                              MediaQuery.of(context).size.width -
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
                            final confirmed = await ConfirmationDialog.show(
                              context: context,
                              title: 'Delete Exercise',
                              body:
                                  'Delete "${exercise.name.isEmpty ? 'Unnamed exercise' : exercise.name}"? This cannot be undone.',
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
          ],
        ),
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
              style: AppTypography.standard.labelSmall.copyWith(
                color: colors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({required this.bloc});

  final WorkoutDayEditorBloc bloc;

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
    widget.bloc.add(QuickExerciseAdded(exerciseName: trimmed));
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
