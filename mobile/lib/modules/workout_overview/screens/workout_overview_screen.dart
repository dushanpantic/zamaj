import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_args.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/group_with_picker_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/text_entry_sheet.dart';
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

  /// The single terminal action per live exercise. Its copy adapts to whether
  /// any sets are logged: with none it reads as a destructive "Skip exercise";
  /// with some it reads as "End exercise" and spells out the consequence with
  /// counts. Both confirm paths fire the same [WorkoutOverviewExerciseSkipped]
  /// event — read surfaces derive the honest outcome (skipped vs partial) from
  /// the set counts.
  Future<void> _handleEndOrSkip(ExerciseViewModel viewModel) async {
    final loggedCount = viewModel.sessionExercise.executedSets.length;
    final plannedCount = viewModel.setRows
        .where((r) => r.plannedValues != null)
        .length;
    final hasSets = loggedCount > 0;
    final name = viewModel.plannedExerciseName;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: hasSets ? 'End exercise?' : 'Skip exercise?',
      body: hasSets
          ? 'You\'ve logged $loggedCount of $plannedCount sets for "$name". '
                'You won\'t be able to log the remaining sets — logged values '
                'stay editable.'
          : 'Marks "$name" skipped and moves on. This session only.',
      confirmLabel: hasSets ? 'End exercise' : 'Skip',
      isDestructive: !hasSets,
    );
    if (!mounted || confirmed != true) return;
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewExerciseSkipped(viewModel.sessionExercise.id),
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
    final body = await TextEntrySheet.show(
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
    final body = await TextEntrySheet.show(
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
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'End session?',
      body:
          'Locks all values. You can still edit completed sets, but can\'t '
          'log new ones.',
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return BlocBuilder<WorkoutOverviewBloc, WorkoutOverviewState>(
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
        onEndOrSkip: _handleEndOrSkip,
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
