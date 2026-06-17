import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/export/models/recent_sessions_args.dart';
import 'package:zamaj/modules/export/navigation/export_routes.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/workout_day_picker/bloc/bloc.dart';
import 'package:zamaj/modules/workout_day_picker/widgets/day_tile.dart';
import 'package:zamaj/modules/workout_day_picker/widgets/workout_day_picker_empty_view.dart';
import 'package:zamaj/modules/workout_day_picker/widgets/workout_day_picker_error_view.dart';
import 'package:zamaj/modules/workout_day_picker/widgets/workout_day_picker_loading_view.dart';
import 'package:zamaj/navigation/session_routes.dart';
import 'package:zamaj/navigation/widgets/session_in_flight_banner.dart';

class WorkoutDayPickerScreen extends StatefulWidget {
  const WorkoutDayPickerScreen({super.key});

  @override
  State<WorkoutDayPickerScreen> createState() => _WorkoutDayPickerScreenState();
}

class _WorkoutDayPickerScreenState extends State<WorkoutDayPickerScreen> {
  StreamSubscription<String>? _navSubscription;

  @override
  void initState() {
    super.initState();
    _navSubscription = context
        .read<WorkoutDayPickerBloc>()
        .navigationIntents
        .listen(_navigateToActiveSession);
  }

  @override
  void dispose() {
    unawaited(_navSubscription?.cancel());
    super.dispose();
  }

  Future<void> _navigateToActiveSession(String sessionId) async {
    await Navigator.of(
      context,
    ).pushNamed(SessionRoutes.active, arguments: sessionId);
    if (mounted) {
      context.read<WorkoutDayPickerBloc>().add(
        const WorkoutDayPickerReturnedFromSession(),
      );
    }
  }

  void _onRefresh() {
    context.read<WorkoutDayPickerBloc>().add(
      const WorkoutDayPickerRefreshRequested(),
    );
  }

  void _onScreenRetry() {
    context.read<WorkoutDayPickerBloc>().add(
      const WorkoutDayPickerScreenRetryRequested(),
    );
  }

  void _onTileRetry(String workoutDayId) {
    context.read<WorkoutDayPickerBloc>().add(
      WorkoutDayPickerTileRetryRequested(workoutDayId),
    );
  }

  void _onStart(String workoutDayId) {
    context.read<WorkoutDayPickerBloc>().add(
      WorkoutDayPickerStartPressed(workoutDayId),
    );
  }

  void _onResume(String workoutDayId, String activeSessionId) {
    context.read<WorkoutDayPickerBloc>().add(
      WorkoutDayPickerResumePressed(
        workoutDayId: workoutDayId,
        activeSessionId: activeSessionId,
      ),
    );
  }

  void _onDismissError() {
    context.read<WorkoutDayPickerBloc>().add(
      const WorkoutDayPickerErrorDismissed(),
    );
  }

  Future<void> _onEditProgram(String programId) async {
    await Navigator.of(context).pushNamed(
      ProgramManagementRoutes.programEditor,
      arguments: ProgramEditorArgs(programId: programId),
    );
    if (mounted) {
      _onRefresh();
    }
  }

  void _onOpenRecentSessions(String programId) {
    Navigator.of(context).pushNamed(
      ExportRoutes.recentSessions,
      arguments: RecentSessionsArgs(programId: programId),
    );
  }

  // TEMP: snapshot link repair — remove after one-time run.
  /// True while a repair preview/result dialog is on screen, so the bloc
  /// listener does not stack a second dialog on the same transition.
  bool _repairDialogOpen = false;

  // TEMP: snapshot link repair — remove after one-time run.
  void _onRepairRequested() {
    context.read<WorkoutDayPickerBloc>().add(
      const WorkoutDayPickerRepairPreviewRequested(),
    );
  }

  // TEMP: snapshot link repair — remove after one-time run.
  void _onRepairDismissed() {
    context.read<WorkoutDayPickerBloc>().add(
      const WorkoutDayPickerRepairDismissed(),
    );
  }

  // TEMP: snapshot link repair — remove after one-time run.
  void _onRepairConfirmed() {
    context.read<WorkoutDayPickerBloc>().add(
      const WorkoutDayPickerRepairConfirmed(),
    );
  }

  // TEMP: snapshot link repair — remove after one-time run.
  Future<void> _showRepairPreviewDialog(
    WorkoutDayPickerRepairPreview preview,
  ) async {
    _repairDialogOpen = true;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Repair history links'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This rewrites the library links frozen inside past session '
              'snapshots so they show up in history and progress again. It '
              'changes completed history and cannot be undone.',
            ),
            const SizedBox(height: AppSpacing.md),
            _RepairCountRow(
              label: 'Sessions scanned',
              value: preview.sessionsScanned,
            ),
            _RepairCountRow(
              label: 'Sessions to update',
              value: preview.sessionsToChange,
            ),
            _RepairCountRow(
              label: 'Exercises to re-link',
              value: preview.exercisesToReLink,
            ),
            _RepairCountRow(label: 'Unmatched', value: preview.unmatched),
            _RepairCountRow(
              label: 'Current unlinked',
              value: preview.currentUnlinked,
            ),
            _RepairCountRow(
              label: 'Skipped (deleted day)',
              value: preview.daysMissing,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: preview.sessionsToChange == 0
                ? null
                : () => Navigator.of(dialogContext).pop(true),
            child: const Text('Repair'),
          ),
        ],
      ),
    );
    _repairDialogOpen = false;
    if (!mounted) return;
    if (confirmed ?? false) {
      _onRepairConfirmed();
    } else {
      _onRepairDismissed();
    }
  }

  // TEMP: snapshot link repair — remove after one-time run.
  Future<void> _showRepairResultDialog(
    WorkoutDayPickerRepairResult result,
  ) async {
    _repairDialogOpen = true;
    final leftover = result.unmatched + result.currentUnlinked;
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Repair complete'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RepairCountRow(
              label: 'Sessions changed',
              value: result.sessionsChanged,
            ),
            _RepairCountRow(
              label: 'Exercises re-linked',
              value: result.exercisesReLinked,
            ),
            _RepairCountRow(label: 'Unmatched', value: result.unmatched),
            _RepairCountRow(
              label: 'Current unlinked',
              value: result.currentUnlinked,
            ),
            _RepairCountRow(
              label: 'Skipped (deleted day)',
              value: result.daysMissing,
            ),
            if (leftover > 0) ...[
              const SizedBox(height: AppSpacing.md),
              const Text(
                'Link more exercises to a library entry in the editor, then '
                'run this again to repair the rest.',
              ),
            ],
          ],
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Done'),
          ),
        ],
      ),
    );
    _repairDialogOpen = false;
    if (!mounted) return;
    _onRepairDismissed();
  }

  // TEMP: snapshot link repair — remove after one-time run.
  void _onRepairStateChanged(WorkoutDayPickerState state) {
    if (state is! WorkoutDayPickerLoaded || _repairDialogOpen) return;
    final preview = state.repairPreview;
    final result = state.repairResult;
    if (preview != null) {
      unawaited(_showRepairPreviewDialog(preview));
    } else if (result != null) {
      unawaited(_showRepairResultDialog(result));
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return BlocConsumer<WorkoutDayPickerBloc, WorkoutDayPickerState>(
      // TEMP: snapshot link repair — remove after one-time run. React only when
      // the preview/result becomes available so the dialog shows exactly once
      // per transition.
      listenWhen: (previous, current) =>
          _repairBecameVisible(previous, current),
      listener: (context, state) => _onRepairStateChanged(state),
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(_titleFor(state)),
            actions: state is WorkoutDayPickerLoaded
                ? [
                    IconButton(
                      onPressed: () => _onOpenRecentSessions(state.program.id),
                      icon: const Icon(Icons.history),
                      tooltip: 'Recent sessions',
                    ),
                    // TEMP: snapshot link repair — remove after one-time run.
                    PopupMenuButton<String>(
                      onSelected: (value) {
                        if (value == 'repair-history-links') {
                          _onRepairRequested();
                        }
                      },
                      itemBuilder: (context) => const [
                        PopupMenuItem(
                          value: 'repair-history-links',
                          child: Text('Repair history links'),
                        ),
                      ],
                    ),
                  ]
                : null,
          ),
          body: _body(context, state),
        );
      },
    );
  }

  // TEMP: snapshot link repair — remove after one-time run.
  bool _repairBecameVisible(
    WorkoutDayPickerState previous,
    WorkoutDayPickerState current,
  ) {
    if (current is! WorkoutDayPickerLoaded) return false;
    final previousLoaded = previous is WorkoutDayPickerLoaded ? previous : null;
    final previewAppeared =
        current.repairPreview != null && previousLoaded?.repairPreview == null;
    final resultAppeared =
        current.repairResult != null && previousLoaded?.repairResult == null;
    return previewAppeared || resultAppeared;
  }

  String _titleFor(WorkoutDayPickerState state) {
    // The title shows the program name across every state that carries it.
    // ProgramNotFound has none, so the bar stays empty and the 'not found'
    // message lives in the body AppStateView instead.
    return switch (state) {
      WorkoutDayPickerInitial(:final programName) => programName,
      WorkoutDayPickerLoading(:final programName) => programName,
      WorkoutDayPickerProgramNotFound() => '',
      WorkoutDayPickerScreenFailure(:final programName) => programName,
      WorkoutDayPickerLoaded(:final program) => program.name,
    };
  }

  Widget _body(BuildContext context, WorkoutDayPickerState state) {
    return switch (state) {
      WorkoutDayPickerInitial() ||
      WorkoutDayPickerLoading() => const WorkoutDayPickerLoadingView(),
      WorkoutDayPickerProgramNotFound() => AppStateView(
        icon: Icons.search_off,
        title: 'Program not found',
        primaryAction: AppStateAction(
          label: 'Back',
          onPressed: () => Navigator.of(context).maybePop(),
        ),
      ),
      WorkoutDayPickerScreenFailure(:final error) => WorkoutDayPickerErrorView(
        error: error,
        onRetry: _onScreenRetry,
      ),
      WorkoutDayPickerLoaded() => _LoadedBody(
        state: state,
        onEditProgram: () => _onEditProgram(state.program.id),
        onTileRetry: _onTileRetry,
        onStart: _onStart,
        onResume: _onResume,
        onDismissError: _onDismissError,
      ),
    };
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.onEditProgram,
    required this.onTileRetry,
    required this.onStart,
    required this.onResume,
    required this.onDismissError,
  });

  final WorkoutDayPickerLoaded state;
  final VoidCallback onEditProgram;
  final void Function(String workoutDayId) onTileRetry;
  final void Function(String workoutDayId) onStart;
  final void Function(String workoutDayId, String activeSessionId) onResume;
  final VoidCallback onDismissError;

  @override
  Widget build(BuildContext context) {
    final transientError = state.lastTransientError;

    if (state.dayViewModels.isEmpty) {
      return WorkoutDayPickerEmptyView(
        programName: state.program.name,
        onEditProgram: onEditProgram,
      );
    }

    final presentedError = transientError == null
        ? null
        : DomainErrorPresenter.present(transientError);

    // While any session is in progress, no new day can be started — so the one
    // available action (resume) lives in a banner at the top. Routed through
    // the bloc so returning from the session refreshes this screen.
    final activeSession = state.activeSession;

    return Column(
      children: [
        if (presentedError != null)
          AppNoticeBanner(
            title: presentedError.title,
            body: presentedError.body,
            onDismiss: onDismissError,
          ),
        if (activeSession != null)
          SessionInProgressBanner(
            session: activeSession,
            onTap: () => onResume(activeSession.workoutDayId, activeSession.id),
          ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              context.read<WorkoutDayPickerBloc>().add(
                const WorkoutDayPickerRefreshRequested(),
              );
            },
            child: ListView.separated(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom:
                    AppSpacing.xxxl + MediaQuery.viewPaddingOf(context).bottom,
              ),
              itemCount: state.dayViewModels.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final vm = state.dayViewModels[index];
                return DayTile(
                  key: ValueKey(vm.workoutDay.id),
                  viewModel: vm,
                  referenceNow: state.referenceNow,
                  launchInFlightWorkoutDayId: state.launchInFlightWorkoutDayId,
                  startLocked: state.activeSession != null,
                  onStartPressed: onStart,
                  onResumePressed: onResume,
                  onRetryPressed: onTileRetry,
                );
              },
            ),
          ),
        ),
      ],
    );
  }
}

// TEMP: snapshot link repair — remove after one-time run.
/// A single "label … value" row inside the repair preview/result dialog.
class _RepairCountRow extends StatelessWidget {
  const _RepairCountRow({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(child: Text(label, style: textTheme.bodyMedium)),
          const SizedBox(width: AppSpacing.md),
          Text('$value', style: AppTypography.standard.numeric),
        ],
      ),
    );
  }
}
