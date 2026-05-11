import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/workout_day_list_tile.dart';

class ProgramEditorScreen extends StatefulWidget {
  const ProgramEditorScreen({super.key, required this.args});

  final ProgramEditorArgs args;

  @override
  State<ProgramEditorScreen> createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends State<ProgramEditorScreen> {
  late final TextEditingController _nameController;
  bool _nameControllerSynced = false;
  String? _shownDeletionCandidate;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    context.read<ProgramEditorBloc>().add(
      ProgramEditorOpened(programId: widget.args.programId),
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

  Future<void> _showAddWorkoutDayDialog() async {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final nameController = TextEditingController();
    String? errorText;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: colors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            side: BorderSide(color: colors.outline),
          ),
          title: Text(
            'Add Workout Day',
            style: typography.titleSmall.copyWith(color: colors.onSurface),
          ),
          content: TextField(
            controller: nameController,
            autofocus: true,
            style: typography.body.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              hintText: 'Day name',
              errorText: errorText,
            ),
            onSubmitted: (_) => _submitAddDay(
              dialogContext,
              nameController,
              setDialogState,
              (e) => errorText = e,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(
                'Cancel',
                style: typography.label.copyWith(color: colors.onSurfaceMuted),
              ),
            ),
            TextButton(
              onPressed: () => _submitAddDay(
                dialogContext,
                nameController,
                setDialogState,
                (e) => errorText = e,
              ),
              child: Text(
                'Add',
                style: typography.label.copyWith(color: colors.primary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _submitAddDay(
    BuildContext dialogContext,
    TextEditingController controller,
    StateSetter setDialogState,
    void Function(String?) setError,
  ) {
    final trimmed = controller.text.trim();
    if (trimmed.isEmpty) {
      setDialogState(() => setError('Name cannot be empty'));
      return;
    }
    context.read<ProgramEditorBloc>().add(
      ProgramEditorWorkoutDayAdded(name: trimmed),
    );
    Navigator.of(dialogContext).pop();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ProgramEditorBloc, ProgramEditorState>(
      listener: (context, state) {
        if (state is ProgramEditorEditing) {
          if (!_nameControllerSynced) {
            _syncNameController(state.draft.name);
            _nameControllerSynced = true;
          }
          final candidate = state.deletionCandidateDraftId;
          if (candidate != null && candidate != _shownDeletionCandidate) {
            _shownDeletionCandidate = candidate;
            final day = state.draft.workoutDays
                .where((d) => d.draftId == candidate)
                .firstOrNull;
            if (day != null) {
              _showDeleteConfirmationDialog(candidate, day.name);
            }
          } else if (candidate == null) {
            _shownDeletionCandidate = null;
          }
        }
      },
      builder: (context, state) => _buildScaffold(context, state),
    );
  }

  Future<void> _showDeleteConfirmationDialog(
    String draftId,
    String dayName,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Workout Day',
      body: 'Delete "$dayName"? This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
    );

    if (!mounted) return;

    if (confirmed == true) {
      context.read<ProgramEditorBloc>().add(
        ProgramEditorWorkoutDayDeleteConfirmed(draftId: draftId),
      );
    } else {
      context.read<ProgramEditorBloc>().add(
        const ProgramEditorWorkoutDayDeleteCancelled(),
      );
    }
  }

  Widget _buildScaffold(BuildContext context, ProgramEditorState state) {
    final colors = Theme.of(context).appColors;

    return switch (state) {
      ProgramEditorInitial() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      ProgramEditorLoading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      ProgramEditorNotFound(:final programId) => Scaffold(
        appBar: AppBar(),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Program not found',
                style: TextStyle(color: colors.onSurface, fontSize: 18),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                programId,
                style: TextStyle(color: colors.onSurfaceMuted, fontSize: 12),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Go back'),
              ),
            ],
          ),
        ),
      ),
      ProgramEditorEditing(
        :final draft,
        :final isCreateMode,
        :final isSaving,
        :final lastSaveError,
        :final deletionCandidateDraftId,
      ) =>
        Scaffold(
          appBar: _buildAppBar(
            context,
            name: draft.name,
            isSaving: isSaving,
            isCreateMode: isCreateMode,
          ),
          floatingActionButton: FloatingActionButton(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            onPressed: _showAddWorkoutDayDialog,
            tooltip: 'Add workout day',
            child: const Icon(Icons.add),
          ),
          body: Column(
            children: [
              if (lastSaveError != null)
                DomainErrorBanner(error: lastSaveError),
              Expanded(
                child: _buildWorkoutDayList(
                  context,
                  draft.workoutDays,
                  deletionCandidateDraftId,
                ),
              ),
            ],
          ),
        ),
    };
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required String name,
    required bool isSaving,
    required bool isCreateMode,
  }) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return AppBar(
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: TextField(
          controller: _nameController,
          style: typography.title.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Program name',
            hintStyle: typography.title.copyWith(color: colors.onSurfaceMuted),
            border: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
          ),
          onChanged: (value) {
            context.read<ProgramEditorBloc>().add(
              ProgramEditorNameChanged(name: value),
            );
          },
        ),
      ),
      actions: [
        if (isSaving)
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildWorkoutDayList(
    BuildContext context,
    List<WorkoutDayDraft> workoutDays,
    String? deletionCandidateDraftId,
  ) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    if (workoutDays.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_outlined,
              size: 48,
              color: colors.onSurfaceMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No workout days yet',
              style: typography.body.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Tap + to add a workout day',
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ),
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.xxxl + AppSpacing.xl),
      itemCount: workoutDays.length,
      onReorder: (oldIndex, newIndex) {
        final days = List.of(workoutDays);
        if (newIndex > oldIndex) newIndex -= 1;
        final moved = days.removeAt(oldIndex);
        days.insert(newIndex, moved);
        context.read<ProgramEditorBloc>().add(
          ProgramEditorWorkoutDaysReordered(
            orderedDraftIds: days.map((d) => d.draftId).toList(),
          ),
        );
      },
      itemBuilder: (context, index) {
        final day = workoutDays[index];

        return WorkoutDayListTile(
          key: ValueKey(day.draftId),
          name: day.name,
          onTap: day.persistedId != null
              ? () => Navigator.of(context).pushNamed(
                  ProgramManagementRoutes.workoutDay,
                  arguments: WorkoutDayArgs(workoutDayId: day.persistedId!),
                )
              : null,
          onDelete: () => context.read<ProgramEditorBloc>().add(
            ProgramEditorWorkoutDayDeleteRequested(draftId: day.draftId),
          ),
        );
      },
    );
  }
}
