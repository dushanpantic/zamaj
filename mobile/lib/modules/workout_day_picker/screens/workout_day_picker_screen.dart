import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/export/models/recent_sessions_args.dart';
import 'package:zamaj/modules/export/navigation/export_routes.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return BlocBuilder<WorkoutDayPickerBloc, WorkoutDayPickerState>(
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
                  ]
                : null,
          ),
          body: _body(context, state),
        );
      },
    );
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

    // A session in progress for a day not shown here (e.g. another program)
    // can't surface Resume on any tile, so offer it as a banner. Routed
    // through the bloc so returning from the session refreshes this screen.
    final offscreenActiveSession = state.hasOffscreenActiveSession
        ? state.activeSession
        : null;

    return Column(
      children: [
        if (presentedError != null)
          AppNoticeBanner(
            title: presentedError.title,
            body: presentedError.body,
            onDismiss: onDismissError,
          ),
        if (offscreenActiveSession != null)
          SessionInProgressBanner(
            session: offscreenActiveSession,
            onTap: () => onResume(
              offscreenActiveSession.workoutDayId,
              offscreenActiveSession.id,
            ),
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
