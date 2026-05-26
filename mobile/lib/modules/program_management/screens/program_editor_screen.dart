import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/relative_date_formatter.dart';
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
  final Set<String> _expandedDayDraftIds = {};

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

  Future<void> _showAddWorkoutDaySheet(ProgramEditorEditing state) async {
    final colors = Theme.of(context).appColors;
    final bloc = context.read<ProgramEditorBloc>();
    final duplicatable = state.draft.workoutDays
        .where((d) => d.persistedId != null)
        .toList();

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => _AddWorkoutDaySheet(
        existingDays: duplicatable,
        onCreateEmpty: (name) {
          bloc.add(ProgramEditorWorkoutDayAdded(name: name));
        },
        onDuplicateExisting: (draftId) {
          bloc.add(ProgramEditorWorkoutDayDuplicated(draftId: draftId));
        },
        onOpenPasteImport: () {
          Navigator.of(context).pushNamed(ProgramManagementRoutes.planImport);
        },
      ),
    );
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
              onPressed: () => _showAddWorkoutDaySheet(state),
              tooltip: 'Add workout day',
              child: const Icon(Icons.add),
            ),
            body: Column(
              children: [
                if (lastSaveError != null)
                  DomainErrorBanner(error: lastSaveError),
                if (!isCreateMode)
                  _ProgramStatsHeader(
                    dayCount: draft.workoutDays.length,
                    exerciseCount: state.totalExerciseCount,
                    lastEdited: state.programUpdatedAt,
                  ),
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
                onPressed: () => _showAddWorkoutDaySheet(state),
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
        final preview = state.exercisePreviewFor(day);
        final canDuplicate = day.persistedId != null;
        final isExpanded = _expandedDayDraftIds.contains(day.draftId);

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
          onDuplicate: canDuplicate
              ? () => context.read<ProgramEditorBloc>().add(
                  ProgramEditorWorkoutDayDuplicated(draftId: day.draftId),
                )
              : null,
          onDelete: () =>
              _onDeletePressed(draftId: day.draftId, summary: summary),
          isEditing: _editingDayDraftId == day.draftId,
          onEnterRename: () => setState(() => _editingDayDraftId = day.draftId),
          onExitRename: () {
            if (_editingDayDraftId == day.draftId) {
              setState(() => _editingDayDraftId = null);
            }
          },
          exercisePreview: preview,
          isExpanded: isExpanded,
          onToggleExpand: preview.isEmpty
              ? null
              : () => setState(() {
                  if (isExpanded) {
                    _expandedDayDraftIds.remove(day.draftId);
                  } else {
                    _expandedDayDraftIds.add(day.draftId);
                  }
                }),
        );
      },
    );
  }
}

class _ProgramStatsHeader extends StatelessWidget {
  const _ProgramStatsHeader({
    required this.dayCount,
    required this.exerciseCount,
    required this.lastEdited,
  });

  final int dayCount;
  final int exerciseCount;
  final DateTime? lastEdited;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final parts = <String>[
      '$dayCount ${dayCount == 1 ? 'day' : 'days'}',
      '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
    ];
    if (lastEdited != null) {
      final relative = RelativeDateFormatter.format(
        lastEdited!,
        clock.now().toUtc(),
      );
      parts.add('edited $relative');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: Text(
        parts.join(' · '),
        style: typography.caption.copyWith(color: colors.onSurfaceMuted),
      ),
    );
  }
}

class _AddWorkoutDaySheet extends StatefulWidget {
  const _AddWorkoutDaySheet({
    required this.existingDays,
    required this.onCreateEmpty,
    required this.onDuplicateExisting,
    required this.onOpenPasteImport,
  });

  final List<WorkoutDayDraft> existingDays;
  final ValueChanged<String> onCreateEmpty;
  final ValueChanged<String> onDuplicateExisting;
  final VoidCallback onOpenPasteImport;

  @override
  State<_AddWorkoutDaySheet> createState() => _AddWorkoutDaySheetState();
}

enum _AddWorkoutDayMode { menu, empty, duplicate }

class _AddWorkoutDaySheetState extends State<_AddWorkoutDaySheet> {
  _AddWorkoutDayMode _mode = _AddWorkoutDayMode.menu;
  final TextEditingController _nameController = TextEditingController();
  String? _nameError;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submitEmpty() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) {
      setState(() => _nameError = 'Name cannot be empty');
      return;
    }
    Navigator.of(context).pop();
    widget.onCreateEmpty(trimmed);
  }

  void _submitDuplicate(String draftId) {
    Navigator.of(context).pop();
    widget.onDuplicateExisting(draftId);
  }

  void _submitPasteImport() {
    Navigator.of(context).pop();
    widget.onOpenPasteImport();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.lg,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: AppSpacing.md),
                  decoration: BoxDecoration(
                    color: colors.outline,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              Row(
                children: [
                  if (_mode != _AddWorkoutDayMode.menu)
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: colors.onSurfaceMuted,
                      ),
                      onPressed: () => setState(() {
                        _mode = _AddWorkoutDayMode.menu;
                        _nameError = null;
                      }),
                      tooltip: 'Back',
                    ),
                  Expanded(
                    child: Text(
                      switch (_mode) {
                        _AddWorkoutDayMode.menu => 'Add workout day',
                        _AddWorkoutDayMode.empty => 'New empty day',
                        _AddWorkoutDayMode.duplicate => 'Duplicate a day',
                      },
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              switch (_mode) {
                _AddWorkoutDayMode.menu => _buildMenu(colors, typography),
                _AddWorkoutDayMode.empty => _buildEmptyForm(colors, typography),
                _AddWorkoutDayMode.duplicate => _buildDuplicatePicker(
                  colors,
                  typography,
                ),
              },
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenu(AppColors colors, AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SheetOption(
          icon: Icons.add,
          title: 'Empty day',
          subtitle: 'Start from a blank workout day.',
          onTap: () => setState(() => _mode = _AddWorkoutDayMode.empty),
        ),
        _SheetOption(
          icon: Icons.copy,
          title: 'Duplicate of…',
          subtitle: widget.existingDays.isEmpty
              ? 'No existing days to copy yet.'
              : 'Copy an existing day as a starting point.',
          enabled: widget.existingDays.isNotEmpty,
          onTap: () => setState(() => _mode = _AddWorkoutDayMode.duplicate),
        ),
        _SheetOption(
          icon: Icons.content_paste,
          title: 'Paste plain text',
          subtitle: 'Import a typed-out plan from your clipboard.',
          onTap: _submitPasteImport,
        ),
      ],
    );
  }

  Widget _buildEmptyForm(AppColors colors, AppTypography typography) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _nameController,
          autofocus: true,
          textInputAction: TextInputAction.done,
          style: typography.body.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
            labelText: 'Day name',
            hintText: 'e.g. Push A',
            errorText: _nameError,
          ),
          onChanged: (_) {
            if (_nameError != null) setState(() => _nameError = null);
          },
          onSubmitted: (_) => _submitEmpty(),
        ),
        const SizedBox(height: AppSpacing.lg),
        FilledButton(
          onPressed: _submitEmpty,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
            minimumSize: const Size.fromHeight(AppSpacing.touchMin),
          ),
          child: const Text('Add day'),
        ),
      ],
    );
  }

  Widget _buildDuplicatePicker(AppColors colors, AppTypography typography) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: widget.existingDays.length,
        separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
        itemBuilder: (context, index) {
          final day = widget.existingDays[index];
          return _SheetOption(
            icon: Icons.copy,
            title: day.name,
            subtitle: 'Copies the day and renames it "<name> (copy)".',
            onTap: () => _submitDuplicate(day.draftId),
          );
        },
      ),
    );
  }
}

class _SheetOption extends StatelessWidget {
  const _SheetOption({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final fg = enabled ? colors.onSurface : colors.onSurfaceMuted;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.md),
          onTap: enabled ? onTap : null,
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: colors.outline),
            ),
            child: Row(
              children: [
                Icon(icon, color: fg),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: typography.titleSmall.copyWith(color: fg),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (enabled)
                  Icon(Icons.chevron_right, color: colors.onSurfaceMuted),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
