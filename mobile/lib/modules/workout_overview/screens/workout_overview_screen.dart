import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_args.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/group_with_picker_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/replace_exercise_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/text_entry_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/workout_overview_app_bar_title.dart';
import 'package:zamaj/modules/workout_overview/widgets/workout_overview_bottom_bar.dart';
import 'package:zamaj/modules/workout_overview/widgets/workout_overview_error_view.dart';
import 'package:zamaj/modules/workout_overview/widgets/workout_overview_loaded_body.dart';
import 'package:zamaj/modules/workout_overview/widgets/workout_overview_loading_view.dart';
import 'package:zamaj/navigation/session_routes.dart';

/// Editable session workspace. Hosts the assembled list of exercise cards,
/// drag-targets between them for reorder, the notes / extra-work sections,
/// and the bottom action bar.
class WorkoutOverviewScreen extends StatefulWidget {
  const WorkoutOverviewScreen({super.key});

  @override
  State<WorkoutOverviewScreen> createState() => _WorkoutOverviewScreenState();
}

class _WorkoutOverviewScreenState extends State<WorkoutOverviewScreen> {
  Future<void> _openVideo(String url) async {
    final launcher = context.read<ExternalLinkLauncher>();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final result = await launcher.launch(uri);
    if (!mounted) return;
    if (result is ExternalLinkFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open video: ${result.reason}')),
      );
    }
  }

  Future<void> _handleReplace(ExerciseViewModel viewModel) async {
    final state = context.read<WorkoutOverviewBloc>().state;
    if (state is! WorkoutOverviewLoaded) return;
    final defaults = resolveReplaceExerciseDefaults(
      sessionExerciseId: viewModel.sessionExercise.id,
      session: state.sessionState.session,
    );
    if (defaults == null) return;
    final result = await presentReplaceFlow(
      context: context,
      plannedExerciseName: viewModel.plannedExerciseName,
      defaultMeasurementType: viewModel.effectiveMeasurementType,
      defaultPlannedValues: defaults.plannedValues,
      defaultSetCount: defaults.setCount,
    );
    if (!mounted || result == null) return;
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewExerciseReplaced(
        sessionExerciseId: viewModel.sessionExercise.id,
        substituteName: result.name,
        substituteMeasurementType: result.measurementType,
        substitutePlannedValues: result.plannedValues,
        substituteSetCount: result.setCount,
        substituteMetadata: result.metadata,
        substituteLibraryExerciseId: result.libraryExerciseId,
      ),
    );
  }

  Future<void> _handleSkip(ExerciseViewModel viewModel) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Skip exercise?',
      body:
          'Skipping "${viewModel.plannedExerciseName}" marks it as not done '
          'and moves on. This affects this session only.',
      confirmLabel: 'Skip',
      isDestructive: true,
    );
    if (!mounted || confirmed != true) return;
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewExerciseSkipped(viewModel.sessionExercise.id),
    );
  }

  Future<void> _handleMarkDone(ExerciseViewModel viewModel) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Mark done?',
      body:
          'Locks "${viewModel.plannedExerciseName}" as done with the sets '
          'you have already logged. You can still edit those sets.',
      confirmLabel: 'Mark done',
      isDestructive: false,
    );
    if (!mounted || confirmed != true) return;
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewExerciseMarkedDone(viewModel.sessionExercise.id),
    );
  }

  Future<void> _handleUngroup(String tag) async {
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewSupersetUngrouped(tag),
    );
  }

  Future<void> _handleGroupInto(
    ExerciseViewModel source,
    List<ExerciseViewModel> candidates,
    List<SupersetGroup> supersetGroups,
  ) async {
    if (candidates.isEmpty && supersetGroups.isEmpty) return;
    final pickedId = await GroupWithPickerDialog.show(
      context: context,
      candidates: candidates,
      supersetGroups: supersetGroups,
    );
    if (!mounted || pickedId == null) return;
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewDropResolved(
        draggedSessionExerciseId: source.sessionExercise.id,
        target: DropTarget.ontoExercise(pickedId),
      ),
    );
  }

  Future<void> _handleAddNote() async {
    final body = await TextEntryDialog.show(
      context: context,
      title: 'Add note',
      hint: 'e.g. left shoulder pain',
      confirmLabel: 'Add',
      maxLength: 5000,
    );
    if (!mounted || body == null) return;
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewSessionNoteAdded(body),
    );
  }

  Future<void> _handleAddExtraWork() async {
    final body = await TextEntryDialog.show(
      context: context,
      title: 'Add extra work',
      hint: 'e.g. 3 calf sets',
      confirmLabel: 'Add',
    );
    if (!mounted || body == null) return;
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewExtraWorkAdded(body),
    );
  }

  Future<void> _handleEndSession() async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'End session?',
      body:
          'Ending the session locks all values. You can still edit completed '
          'sets afterward, but no new sets can be logged.',
      confirmLabel: 'End',
      isDestructive: true,
    );
    if (!mounted || confirmed != true) return;
    context.read<WorkoutOverviewBloc>().add(
      const WorkoutOverviewSessionEnded(),
    );
  }

  void _handleOpenFocusMode(WorkoutOverviewLoaded state) {
    final openTargets = state.sessionState.openTargets;
    if (openTargets.isEmpty) return;
    Navigator.of(context).pushNamed(
      SessionRoutes.focus,
      arguments: FocusModeArgs(
        sessionId: state.sessionState.session.id,
        anchorSessionExerciseId: openTargets.first.sessionExerciseId,
      ),
    );
  }

  void _showSetLoggedSnackBar(BuildContext context, String executedSetId) {
    final colors = Theme.of(context).appColors;
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: colors.surface,
        content: Text(
          'Set logged',
          style: AppTypography.standard.bodySmall.copyWith(
            color: colors.onSurface,
          ),
        ),
        action: SnackBarAction(
          label: 'UNDO',
          textColor: colors.primary,
          onPressed: () => context.read<WorkoutOverviewBloc>().add(
            WorkoutOverviewSetLogUndone(executedSetId),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return BlocConsumer<WorkoutOverviewBloc, WorkoutOverviewState>(
      listenWhen: (prev, curr) =>
          curr is WorkoutOverviewLoaded &&
          curr.lastLoggedExecutedSetId != null &&
          (prev is! WorkoutOverviewLoaded ||
              prev.lastLoggedExecutedSetId != curr.lastLoggedExecutedSetId),
      listener: (context, state) {
        if (state is! WorkoutOverviewLoaded) return;
        final id = state.lastLoggedExecutedSetId;
        if (id == null) return;
        _showSetLoggedSnackBar(context, id);
      },
      builder: (context, state) {
        final focus = state is WorkoutOverviewLoaded
            ? _resolveCurrent(state)
            : null;
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: state is WorkoutOverviewLoaded
                ? WorkoutOverviewAppBarTitle(state: state)
                : Text(_titleFor(state)),
            actions: state is WorkoutOverviewLoaded
                ? [
                    if (!state.isEnded)
                      IconButton(
                        tooltip: 'End session',
                        onPressed: state.mutationInFlight
                            ? null
                            : _handleEndSession,
                        icon: const Icon(Icons.stop_circle_outlined),
                      ),
                  ]
                : null,
          ),
          body: _body(context, state, focus),
          bottomNavigationBar: state is WorkoutOverviewLoaded
              ? WorkoutOverviewBottomBar(
                  state: state,
                  currentExerciseName: focus?.currentExerciseName,
                  onAddNote: _handleAddNote,
                  onAddExtraWork: _handleAddExtraWork,
                  onFocusMode: () => _handleOpenFocusMode(state),
                )
              : null,
        );
      },
    );
  }

  /// Resolves "what's current" for a loaded session: the set of session
  /// exercise IDs that should get the CURRENT chip + accent (every
  /// unfinished member of the active superset, or the lone single), and
  /// the display name of the first open target for the bottom Focus
  /// button label.
  _CurrentFocus _resolveCurrent(WorkoutOverviewLoaded state) {
    final openTargets = state.sessionState.openTargets;
    if (openTargets.isEmpty) {
      return const _CurrentFocus(
        currentIds: <String>{},
        currentExerciseName: null,
      );
    }
    final anchorId = openTargets.first.sessionExerciseId;
    for (final g in state.groups) {
      ExerciseViewModel? anchor;
      for (final ex in g.allExercises) {
        if (ex.sessionExercise.id == anchorId) {
          anchor = ex;
          break;
        }
      }
      if (anchor == null) continue;
      final ids = <String>{
        for (final ex in g.allExercises)
          if (ex.sessionExercise.state is UnfinishedState)
            ex.sessionExercise.id,
      }..add(anchorId);
      return _CurrentFocus(
        currentIds: ids,
        currentExerciseName: anchor.displayName,
      );
    }
    return _CurrentFocus(currentIds: {anchorId}, currentExerciseName: null);
  }

  String _titleFor(WorkoutOverviewState state) {
    return switch (state) {
      WorkoutOverviewInitial() || WorkoutOverviewLoading() => 'Loading…',
      WorkoutOverviewNotFound() => 'Session not found',
      WorkoutOverviewLoadFailure() => 'Could not load session',
      WorkoutOverviewLoaded(:final sessionState) =>
        sessionState.session.snapshot.workoutDay.name,
    };
  }

  Widget _body(
    BuildContext context,
    WorkoutOverviewState state,
    _CurrentFocus? focus,
  ) {
    return switch (state) {
      WorkoutOverviewInitial() ||
      WorkoutOverviewLoading() => const WorkoutOverviewLoadingView(),
      WorkoutOverviewNotFound() => const WorkoutOverviewNotFoundView(),
      WorkoutOverviewLoadFailure(:final error) => WorkoutOverviewErrorView(
        error: error,
        onRetry: () => context.read<WorkoutOverviewBloc>().add(
          const WorkoutOverviewRetried(),
        ),
      ),
      WorkoutOverviewLoaded() => WorkoutOverviewLoadedBody(
        state: state,
        currentSessionExerciseIds: focus?.currentIds ?? const <String>{},
        onReplace: _handleReplace,
        onSkip: _handleSkip,
        onMarkDone: _handleMarkDone,
        onUngroup: _handleUngroup,
        onGroupInto: _handleGroupInto,
        onOpenVideo: _openVideo,
        onAddNote: _handleAddNote,
        onAddExtraWork: _handleAddExtraWork,
      ),
    };
  }
}

/// Bundle of "what's current" the screen-level builder resolves once and
/// passes to both the loaded body (for per-card chip + accent) and the
/// bottom Focus button (for its `Focus: <name>` label).
class _CurrentFocus {
  const _CurrentFocus({
    required this.currentIds,
    required this.currentExerciseName,
  });

  /// IDs of every exercise that should render as "current". For singles,
  /// just the lone open target; for supersets, every unfinished member of
  /// the active group (since Focus mode pairs them).
  final Set<String> currentIds;

  /// Display name of the first open target for the bottom Focus button
  /// label. Null when there's no open target.
  final String? currentExerciseName;
}
