import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/exercise_group_card.dart';

class WorkoutDayEditorScreen extends StatefulWidget {
  const WorkoutDayEditorScreen({super.key, required this.args});

  final WorkoutDayArgs args;

  @override
  State<WorkoutDayEditorScreen> createState() => _WorkoutDayEditorScreenState();
}

class _WorkoutDayEditorScreenState extends State<WorkoutDayEditorScreen> {
  late final TextEditingController _nameController;

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

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<WorkoutDayEditorBloc, WorkoutDayEditorState>(
      listenWhen: (previous, current) =>
          current is WorkoutDayEditorEditing &&
          previous is! WorkoutDayEditorEditing,
      listener: (context, state) {
        if (state is WorkoutDayEditorEditing) {
          _nameController.text = state.draft.name;
        }
      },
      builder: (context, state) {
        return switch (state) {
          WorkoutDayEditorInitial() => const _LoadingView(),
          WorkoutDayEditorLoading() => const _LoadingView(),
          WorkoutDayEditorNotFound(:final workoutDayId) => _NotFoundView(
            workoutDayId: workoutDayId,
          ),
          WorkoutDayEditorSaving(:final draft) => _EditingBody(
            nameController: _nameController,
            draft: draft,
            validation: WorkoutDayDraftValidation.of(draft),
            isSaving: true,
            groupValidationError: null,
          ),
          WorkoutDayEditorEditing(
            :final draft,
            :final validation,
            :final lastSaveError,
          ) =>
            _EditingBody(
              nameController: _nameController,
              draft: draft,
              validation: validation,
              isSaving: false,
              groupValidationError: null,
              lastSaveError: lastSaveError,
            ),
          WorkoutDayEditorGroupValidationError(
            :final draft,
            :final groupDraftId,
            :final invariant,
          ) =>
            _EditingBody(
              nameController: _nameController,
              draft: draft,
              validation: WorkoutDayDraftValidation.of(draft),
              isSaving: false,
              groupValidationError: (groupDraftId, invariant),
            ),
          WorkoutDayEditorSaved() => const _LoadingView(),
        };
      },
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
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
    const colors = AppColors.dark;
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
    required this.groupValidationError,
    this.lastSaveError,
  });

  final TextEditingController nameController;
  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;
  final bool isSaving;
  final (String groupDraftId, String invariant)? groupValidationError;
  final DomainError? lastSaveError;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
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
          IconButton(
            icon: Icon(Icons.add, color: colors.primary),
            tooltip: 'Add group',
            onPressed: () => bloc.add(const ExerciseGroupAdded()),
          ),
        ],
      ),
      body: Stack(
        children: [
          _GroupList(
            draft: draft,
            groupValidationError: groupValidationError,
            lastSaveError: lastSaveError,
          ),
          if (isSaving) const _SavingOverlay(),
        ],
      ),
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
    const colors = AppColors.dark;
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

class _GroupList extends StatelessWidget {
  const _GroupList({
    required this.draft,
    required this.groupValidationError,
    this.lastSaveError,
  });

  final WorkoutDayDraft draft;
  final (String groupDraftId, String invariant)? groupValidationError;
  final DomainError? lastSaveError;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
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
                'No exercise groups yet.\nTap + to add one.',
                style: TextStyle(color: colors.onSurfaceMuted, fontSize: 14),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        if (lastSaveError != null) _SaveErrorBanner(error: lastSaveError!),
        Expanded(
          child: ReorderableListView.builder(
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
              final error = groupValidationError?.$1 == group.draftId
                  ? groupValidationError?.$2
                  : null;

              return ExerciseGroupCard(
                key: ValueKey(group.draftId),
                group: group,
                validationError: error,
                reorderIndex: index,
                onDelete: () =>
                    bloc.add(ExerciseGroupDeleted(groupDraftId: group.draftId)),
                onSave: () =>
                    bloc.add(GroupSavePressed(groupDraftId: group.draftId)),
                onAddExercise: () =>
                    _showAddExerciseDialog(context, group.draftId),
                onDeleteExercise: (exerciseDraftId) => bloc.add(
                  ExerciseRemovedFromGroup(
                    groupDraftId: group.draftId,
                    exerciseDraftId: exerciseDraftId,
                  ),
                ),
                onReorderExercises: (orderedIds) => bloc.add(
                  ExerciseReorderedWithinGroup(
                    groupDraftId: group.draftId,
                    orderedExerciseDraftIds: orderedIds,
                  ),
                ),
                onTapExercise: (exerciseDraftId) {
                  final exercise = group.exercises
                      .where((e) => e.draftId == exerciseDraftId)
                      .firstOrNull;
                  if (exercise?.persistedId != null) {
                    Navigator.of(context).pushNamed(
                      ProgramManagementRoutes.exercise,
                      arguments: ExerciseArgs(
                        exerciseId: exercise!.persistedId!,
                      ),
                    );
                  }
                },
              );
            },
          ),
        ),
      ],
    );
  }

  void _showAddExerciseDialog(BuildContext context, String groupDraftId) {
    showDialog<void>(
      context: context,
      builder: (_) => _AddExerciseDialog(
        groupDraftId: groupDraftId,
        bloc: context.read<WorkoutDayEditorBloc>(),
      ),
    );
  }
}

class _SaveErrorBanner extends StatelessWidget {
  const _SaveErrorBanner({required this.error});

  final DomainError error;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
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

class _SavingOverlay extends StatelessWidget {
  const _SavingOverlay();

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
    return ColoredBox(
      color: colors.background.withValues(alpha: 0.6),
      child: Center(child: CircularProgressIndicator(color: colors.primary)),
    );
  }
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({required this.groupDraftId, required this.bloc});

  final String groupDraftId;
  final WorkoutDayEditorBloc bloc;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameController = TextEditingController();
  MeasurementType _measurementType = const MeasurementType.repBased();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text('Add exercise', style: TextStyle(color: colors.onSurface)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _nameController,
            autofocus: true,
            style: TextStyle(color: colors.onSurface),
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
          const SizedBox(height: AppSpacing.lg),
          Text(
            'Measurement type',
            style: TextStyle(color: colors.onSurfaceMuted, fontSize: 12),
          ),
          const SizedBox(height: AppSpacing.sm),
          _MeasurementTypeToggle(
            selected: _measurementType,
            onChanged: (type) => setState(() => _measurementType = type),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.onSurfaceMuted)),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty
              ? null
              : () {
                  widget.bloc.add(
                    ExerciseAddedToGroup(
                      groupDraftId: widget.groupDraftId,
                      exerciseName: _nameController.text.trim(),
                      measurementType: _measurementType,
                    ),
                  );
                  Navigator.of(context).pop();
                },
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

class _MeasurementTypeToggle extends StatelessWidget {
  const _MeasurementTypeToggle({
    required this.selected,
    required this.onChanged,
  });

  final MeasurementType selected;
  final void Function(MeasurementType) onChanged;

  @override
  Widget build(BuildContext context) {
    const colors = AppColors.dark;
    return Row(
      children: [
        _TypeChip(
          label: 'Rep-based',
          isSelected: selected is RepBasedMeasurement,
          onTap: () => onChanged(const MeasurementType.repBased()),
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        _TypeChip(
          label: 'Time-based',
          isSelected: selected is TimeBasedMeasurement,
          onTap: () => onChanged(const MeasurementType.timeBased()),
          colors: colors,
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: isSelected ? colors.primary : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colors.onPrimary : colors.onSurfaceMuted,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
