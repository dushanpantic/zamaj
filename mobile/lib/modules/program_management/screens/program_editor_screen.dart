import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/models/workout_day_summary.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';
import 'package:zamaj/modules/program_management/widgets/workout_day_list_tile.dart';

/// Days with more exercises than this trigger the heavy-confirm dialog
/// instead of the optimistic snackbar-undo delete.
const int _heavyDeleteThreshold = 3;

class ProgramEditorScreen extends StatefulWidget {
  const ProgramEditorScreen({super.key, required this.args});

  final ProgramEditorArgs args;

  @override
  State<ProgramEditorScreen> createState() => _ProgramEditorScreenState();
}

class _ProgramEditorScreenState extends State<ProgramEditorScreen> {
  late final TextEditingController _nameController;
  late final FocusNode _nameFocus;
  bool _nameControllerSynced = false;
  String? _shownDeletionCandidate;
  String? _shownPendingDeletion;
  String? _editingDayDraftId;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _nameFocus = FocusNode()..addListener(_handleNameFocusChanged);
    context.read<ProgramEditorBloc>().add(
      ProgramEditorOpened(programId: widget.args.programId),
    );
  }

  void _handleNameFocusChanged() => setState(() {});

  @override
  void dispose() {
    _nameController.dispose();
    _nameFocus.removeListener(_handleNameFocusChanged);
    _nameFocus.dispose();
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
              _showHeavyDeleteConfirmation(
                draftId: candidate,
                dayName: day.name,
                summary: state.summaryFor(day),
              );
            }
          } else if (candidate == null) {
            _shownDeletionCandidate = null;
          }

          final pending = state.pendingDeletion;
          if (pending != null && pending.draftId != _shownPendingDeletion) {
            _shownPendingDeletion = pending.draftId;
            _showUndoSnackbar(pending.draftId, pending.day.name);
          } else if (pending == null && _shownPendingDeletion != null) {
            _shownPendingDeletion = null;
            ScaffoldMessenger.of(context).clearSnackBars();
          }

          if (_editingDayDraftId != null) {
            final stillExists = state.draft.workoutDays.any(
              (d) => d.draftId == _editingDayDraftId,
            );
            if (!stillExists) {
              setState(() => _editingDayDraftId = null);
            }
          }
        }
      },
      builder: (context, state) => _buildScaffold(context, state),
    );
  }

  Future<void> _showHeavyDeleteConfirmation({
    required String draftId,
    required String dayName,
    required WorkoutDaySummary summary,
  }) async {
    final cost = WorkoutDaySummaryFormatter.deletionCost(summary);
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete Workout Day',
      body: 'Delete "$dayName"? This removes $cost.',
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

  void _showUndoSnackbar(String draftId, String dayName) {
    final messenger = ScaffoldMessenger.of(context);
    final bloc = context.read<ProgramEditorBloc>();
    final colors = Theme.of(context).appColors;
    var undoTapped = false;
    messenger.clearSnackBars();
    messenger
        .showSnackBar(
          SnackBar(
            duration: const Duration(seconds: 5),
            content: Text('Deleted "$dayName"'),
            action: SnackBarAction(
              label: 'UNDO',
              textColor: colors.primary,
              onPressed: () {
                undoTapped = true;
                bloc.add(const ProgramEditorWorkoutDayDeleteUndone());
              },
            ),
          ),
        )
        .closed
        .then((_) {
          if (bloc.isClosed) return;
          if (!undoTapped) {
            bloc.add(const ProgramEditorWorkoutDayDeleteFinalized());
          }
        });
  }

  void _onDeletePressed({
    required String draftId,
    required WorkoutDaySummary summary,
  }) {
    final bloc = context.read<ProgramEditorBloc>();
    if (summary.exerciseCount > _heavyDeleteThreshold ||
        summary.warmupExerciseCount > _heavyDeleteThreshold) {
      bloc.add(ProgramEditorWorkoutDayDeleteRequested(draftId: draftId));
    } else {
      bloc.add(ProgramEditorWorkoutDayDeleteOptimistic(draftId: draftId));
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
                style: AppTypography.standard.titleSmall.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                programId,
                style: AppTypography.standard.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
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
        :final pendingDeletion,
      ) =>
        () {
          final visibleDays = pendingDeletion == null
              ? draft.workoutDays
              : draft.workoutDays
                    .where((d) => d.draftId != pendingDeletion.draftId)
                    .toList();
          return Scaffold(
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
                  child: _buildWorkoutDayList(context, state, visibleDays),
                ),
              ],
            ),
          );
        }(),
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
    final showEditAffordance = !_nameFocus.hasFocus;

    return AppBar(
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.sm),
        child: TextField(
          controller: _nameController,
          focusNode: _nameFocus,
          style: typography.title.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            hintText: 'Program name',
            hintStyle: typography.title.copyWith(color: colors.onSurfaceMuted),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            filled: false,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
            ),
            suffixIcon: showEditAffordance
                ? Icon(Icons.edit, size: 14, color: colors.onSurfaceMuted)
                : null,
            suffixIconConstraints: const BoxConstraints(
              minWidth: 24,
              minHeight: 24,
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
    ProgramEditorEditing state,
    List<WorkoutDayDraft> workoutDays,
  ) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    if (workoutDays.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.fitness_center_outlined,
                size: 48,
                color: colors.onSurfaceMuted,
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'No workout days yet',
                style: typography.titleSmall.copyWith(color: colors.onSurface),
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Build out your week one day at a time.',
                style: typography.bodySmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              FilledButton.icon(
                onPressed: _showAddWorkoutDayDialog,
                icon: const Icon(Icons.add),
                label: const Text('Add workout day'),
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  minimumSize: const Size(0, AppSpacing.touchMin),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              TextButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pushNamed(ProgramManagementRoutes.planImport),
                icon: Icon(Icons.content_paste, color: colors.primary),
                label: Text(
                  'Paste a plan',
                  style: typography.label.copyWith(color: colors.primary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ReorderableListView.builder(
      buildDefaultDragHandles: false,
      padding: EdgeInsets.only(
        top: AppSpacing.sm,
        bottom:
            AppSpacing.xxxl +
            AppSpacing.xl +
            MediaQuery.viewPaddingOf(context).bottom,
      ),
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
        final summary = state.summaryFor(day);

        return WorkoutDayListTile(
          key: ValueKey(day.draftId),
          index: index,
          name: day.name,
          summary: summary,
          isPersisted: day.persistedId != null,
          onTap: day.persistedId != null
              ? () => Navigator.of(context).pushNamed(
                  ProgramManagementRoutes.workoutDay,
                  arguments: WorkoutDayArgs(workoutDayId: day.persistedId!),
                )
              : null,
          onRename: (newName) {
            context.read<ProgramEditorBloc>().add(
              ProgramEditorWorkoutDayRenamed(
                draftId: day.draftId,
                name: newName,
              ),
            );
          },
          onDuplicate: null,
          onDelete: () =>
              _onDeletePressed(draftId: day.draftId, summary: summary),
          isEditing: _editingDayDraftId == day.draftId,
          onEnterRename: () => setState(() => _editingDayDraftId = day.draftId),
          onExitRename: () {
            if (_editingDayDraftId == day.draftId) {
              setState(() => _editingDayDraftId = null);
            }
          },
        );
      },
    );
  }
}
