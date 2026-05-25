import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/rest_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/widgets/library_picker_sheet.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/services/planned_draft_summary_formatter.dart';
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

class _EditingBody extends StatefulWidget {
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
  State<_EditingBody> createState() => _EditingBodyState();
}

class _EditingBodyState extends State<_EditingBody> {
  static bool _coachMarkShownThisSession = false;
  bool _saveErrorDismissed = false;
  DomainError? _lastSeenError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_coachMarkShownThisSession && widget.draft.groups.isNotEmpty) {
      _coachMarkShownThisSession = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final colors = Theme.of(context).appColors;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 6),
            backgroundColor: colors.surface,
            content: Text(
              'Swipe left to delete · Long-press to reorder · '
              'Use the ⋮ menu for more',
              style: AppTypography.standard.bodySmall.copyWith(
                color: colors.onSurface,
              ),
            ),
            action: SnackBarAction(
              label: 'Got it',
              textColor: colors.primary,
              onPressed: () {},
            ),
          ),
        );
      });
    }
  }

  @override
  void didUpdateWidget(covariant _EditingBody old) {
    super.didUpdateWidget(old);
    if (widget.lastSaveError != _lastSeenError) {
      _lastSeenError = widget.lastSaveError;
      _saveErrorDismissed = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bloc = context.read<WorkoutDayEditorBloc>();
    final showErrorBanner =
        widget.lastSaveError != null && !_saveErrorDismissed;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: _NameField(
          controller: widget.nameController,
          isValid: widget.validation.isNameValid,
          onChanged: (name) => bloc.add(WorkoutDayNameChanged(name: name)),
        ),
        actions: [
          _SaveChip(
            isSaving: widget.isSaving,
            hasError: widget.lastSaveError != null,
            onRetry: () => bloc.add(const WorkoutDaySaveRetryRequested()),
          ),
          IconButton(
            icon: Icon(Icons.add, color: colors.primary),
            tooltip: 'Add exercise',
            onPressed: widget.isSaving
                ? null
                : () => _startAddExercise(context, bloc),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showErrorBanner)
            _SaveErrorBanner(
              error: widget.lastSaveError!,
              onDismiss: () => setState(() => _saveErrorDismissed = true),
            ),
          Expanded(
            child: _ExerciseList(
              draft: widget.draft,
              validation: widget.validation,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _startAddExercise(
  BuildContext context,
  WorkoutDayEditorBloc bloc,
) async {
  final result = await LibraryPickerSheet.show(context);
  if (!context.mounted) return;
  switch (result) {
    case LibraryPickerSelected(:final entry):
      bloc.add(LibraryExerciseAddedAsNew(entry: entry));
    case LibraryPickerCreateOneOff():
      await showDialog<void>(
        context: context,
        builder: (_) => _AddExerciseDialog(bloc: bloc),
      );
    case null:
      return;
  }
}

class _NameField extends StatefulWidget {
  const _NameField({
    required this.controller,
    required this.isValid,
    required this.onChanged,
  });

  final TextEditingController controller;
  final bool isValid;
  final void Function(String) onChanged;

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final showEditAffordance = !_focusNode.hasFocus;
    return TextField(
      controller: widget.controller,
      focusNode: _focusNode,
      onChanged: widget.onChanged,
      style: AppTypography.standard.body.copyWith(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: 'Day name',
        hintStyle: AppTypography.standard.body.copyWith(
          color: colors.onSurfaceMuted,
        ),
        border: InputBorder.none,
        suffixIcon: showEditAffordance
            ? Icon(Icons.edit, size: 14, color: colors.onSurfaceMuted)
            : null,
        suffixIconConstraints: const BoxConstraints(
          minWidth: 24,
          minHeight: 24,
        ),
        errorText: widget.isValid || widget.controller.text.isEmpty
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
  const _ExerciseList({required this.draft, required this.validation});

  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;

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
                onPressed: () => _startAddExercise(context, bloc),
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
            child: _FlatExerciseRow(
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
          validation: validation,
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

enum _GroupMenuAction { toggleWarmup, group, ungroup, delete }

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
              backgroundColor: colors.surface,
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
                color: isDropTarget
                    ? colors.primary.withValues(alpha: 0.10)
                    : null,
                borderRadius: BorderRadius.circular(AppRadius.sm),
                border: isDropTarget
                    ? Border.all(color: colors.primary, width: 2)
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
                            isInvalid: isInvalid,
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
                              case _GroupMenuAction.group:
                                _promptGroupInto(context);
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
                            if (otherGroups.isNotEmpty)
                              const PopupMenuItem(
                                value: _GroupMenuAction.group,
                                child: ListTile(
                                  leading: Icon(Icons.merge_type),
                                  title: Text('Group into superset'),
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
    this.isInvalid = false,
    this.supersetPositionLabel,
  });

  final ExerciseDraft exercise;
  final AppColors colors;
  final bool isWarmup;
  final bool isInvalid;
  final String? supersetPositionLabel;

  @override
  Widget build(BuildContext context) {
    final subtitle = PlannedDraftSummaryFormatter.summarize(exercise);
    final hasNoSets = PlannedDraftSummaryFormatter.isNoSetsPlanned(exercise);
    final rest = exercise.plannedRestSeconds;
    final showWarning = isInvalid && !hasNoSets;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            if (supersetPositionLabel != null) ...[
              _SupersetPositionBadge(
                label: supersetPositionLabel!,
                colors: colors,
              ),
              const SizedBox(width: AppSpacing.sm),
            ],
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
                  color: hasNoSets ? colors.error : colors.onSurfaceMuted,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (showWarning) ...[
              const SizedBox(width: AppSpacing.sm),
              Tooltip(
                message: 'Incomplete sets',
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: colors.error,
                  size: 14,
                  semanticLabel: 'Incomplete sets',
                ),
              ),
            ],
            if (rest != null) ...[
              const SizedBox(width: AppSpacing.sm),
              _RestChip(seconds: rest, colors: colors),
            ],
          ],
        ),
      ],
    );
  }
}

class _SupersetPositionBadge extends StatelessWidget {
  const _SupersetPositionBadge({required this.label, required this.colors});

  final String label;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 1,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Text(
        label,
        style: AppTypography.standard.badge.copyWith(
          color: colors.onSurfaceMuted,
        ),
      ),
    );
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
                      case _GroupMenuAction.group:
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
                    final positionLabel = _positionLabel(index);
                    final isInvalid = validation.invalidExerciseDraftIds
                        .contains(exercise.draftId);
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
                            isInvalid: isInvalid,
                            supersetPositionLabel: positionLabel,
                          ),
                        ),
                      ),
                      childWhenDragging: Opacity(
                        opacity: 0.3,
                        child: _ExerciseTileContent(
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
                              ? colors.primary.withValues(alpha: 0.10)
                              : null,
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

class _SaveErrorBanner extends StatelessWidget {
  const _SaveErrorBanner({required this.error, required this.onDismiss});

  final DomainError error;
  final VoidCallback onDismiss;

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
          IconButton(
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Dismiss',
            icon: Icon(Icons.close, color: colors.error),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}

class _SaveChip extends StatelessWidget {
  const _SaveChip({
    required this.isSaving,
    required this.hasError,
    required this.onRetry,
  });

  final bool isSaving;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isError = hasError && !isSaving;
    final label = isError
        ? 'Save failed — tap to retry'
        : isSaving
        ? 'Saving…'
        : 'Saved';
    final color = isError ? colors.error : colors.onSurfaceMuted;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: isError ? onRetry : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSaving)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: color,
                    ),
                  ),
                ),
              Text(
                label,
                style: AppTypography.standard.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
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
