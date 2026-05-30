import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/add_exercise_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/workout_day_exercise_list.dart';
import 'package:zamaj/modules/program_management/widgets/workout_day_name_field.dart';
import 'package:zamaj/modules/program_management/widgets/workout_day_save_chip.dart';
import 'package:zamaj/modules/program_management/widgets/workout_day_save_error_banner.dart';

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
          WorkoutDayEditorNotFound() => const _NotFoundView(),
          WorkoutDayEditorExerciseCreated(:final draft, :final validation) =>
            _EditingBody(
              nameController: _nameController,
              draft: draft,
              validation: validation,
              isSaving: false,
              lastSaveError: null,
              onNavigateToExercise: _navigateToExercise,
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
              onNavigateToExercise: _navigateToExercise,
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
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Scaffold(
      backgroundColor: colors.background,
      body: AppStateView(
        icon: Icons.error_outline,
        tone: AppStateTone.error,
        title: 'Workout day not found.',
        primaryAction: AppStateAction(
          label: 'Go back',
          onPressed: () => Navigator.of(context).pop(),
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
    required this.onNavigateToExercise,
  });

  final TextEditingController nameController;
  final WorkoutDayDraft draft;
  final WorkoutDayDraftValidation validation;
  final bool isSaving;
  final DomainError? lastSaveError;
  final void Function(String exerciseId) onNavigateToExercise;

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
        title: WorkoutDayNameField(
          controller: widget.nameController,
          isValid: widget.validation.isNameValid,
          onChanged: (name) => bloc.add(WorkoutDayNameChanged(name: name)),
        ),
        actions: [
          WorkoutDaySaveChip(
            isSaving: widget.isSaving,
            hasError: widget.lastSaveError != null,
            onRetry: () => bloc.add(const WorkoutDaySaveRetryRequested()),
          ),
          IconButton(
            icon: Icon(Icons.add, color: colors.primary),
            tooltip: 'Add exercise',
            onPressed: widget.isSaving
                ? null
                : () => startAddExercise(context, bloc),
          ),
        ],
      ),
      body: Column(
        children: [
          if (showErrorBanner)
            WorkoutDaySaveErrorBanner(
              error: widget.lastSaveError!,
              onDismiss: () => setState(() => _saveErrorDismissed = true),
            ),
          Expanded(
            child: WorkoutDayExerciseList(
              draft: widget.draft,
              validation: widget.validation,
              onNavigateToExercise: widget.onNavigateToExercise,
            ),
          ),
        ],
      ),
    );
  }
}
