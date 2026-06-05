import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_event.dart';
import 'package:zamaj/modules/program_management/bloc/program_editor/program_editor_state.dart';
import 'package:zamaj/modules/program_management/models/workout_day_summary.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
import 'package:zamaj/modules/program_management/widgets/add_workout_day_sheet.dart';
import 'package:zamaj/modules/program_management/widgets/program_editor_app_bar.dart';
import 'package:zamaj/modules/program_management/widgets/program_editor_day_list.dart';
import 'package:zamaj/modules/program_management/widgets/program_stats_header.dart';

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
      backgroundColor: colors.surfaceElevated,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (sheetContext) => AddWorkoutDaySheet(
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
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Delete workout day?',
      body: 'Deletes "$dayName" and its $cost.',
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
    return switch (state) {
      ProgramEditorInitial() ||
      ProgramEditorLoading() => const Scaffold(body: AppListSkeleton()),
      ProgramEditorNotFound(:final programId) => Scaffold(
        appBar: AppBar(),
        body: AppStateView(
          icon: Icons.error_outline,
          tone: AppStateTone.error,
          title: 'Program not found',
          message: programId,
          primaryAction: AppStateAction(
            label: 'Go back',
            onPressed: () => Navigator.of(context).pop(),
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
          final presentedSaveError = lastSaveError == null
              ? null
              : DomainErrorPresenter.present(lastSaveError);
          return Scaffold(
            appBar: ProgramEditorAppBar(
              nameController: _nameController,
              nameFocus: _nameFocus,
              isSaving: isSaving,
            ),
            floatingActionButton: FloatingActionButton(
              onPressed: () => _showAddWorkoutDaySheet(state),
              tooltip: 'Add workout day',
              child: const Icon(Icons.add),
            ),
            body: Column(
              children: [
                if (presentedSaveError != null)
                  AppNoticeBanner(
                    title: presentedSaveError.title,
                    body: presentedSaveError.body,
                  ),
                if (!isCreateMode)
                  ProgramStatsHeader(
                    dayCount: draft.workoutDays.length,
                    exerciseCount: state.totalExerciseCount,
                    lastEdited: state.programUpdatedAt,
                  ),
                Expanded(
                  child: ProgramEditorDayList(
                    state: state,
                    workoutDays: visibleDays,
                    editingDayDraftId: _editingDayDraftId,
                    expandedDayDraftIds: _expandedDayDraftIds,
                    onAddWorkoutDay: () => _showAddWorkoutDaySheet(state),
                    onDeletePressed: _onDeletePressed,
                    onEnterRename: (draftId) =>
                        setState(() => _editingDayDraftId = draftId),
                    onExitRename: (draftId) {
                      if (_editingDayDraftId == draftId) {
                        setState(() => _editingDayDraftId = null);
                      }
                    },
                    onToggleExpand: (draftId) => setState(() {
                      if (_expandedDayDraftIds.contains(draftId)) {
                        _expandedDayDraftIds.remove(draftId);
                      } else {
                        _expandedDayDraftIds.add(draftId);
                      }
                    }),
                  ),
                ),
              ],
            ),
          );
        }(),
    };
  }
}
