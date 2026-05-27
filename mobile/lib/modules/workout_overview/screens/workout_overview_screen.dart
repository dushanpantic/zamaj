import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_args.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroll.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';
import 'package:zamaj/modules/workout_overview/widgets/group_with_picker_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/notes_section.dart';
import 'package:zamaj/modules/workout_overview/widgets/replace_exercise_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/superset_card.dart';
import 'package:zamaj/modules/workout_overview/widgets/text_entry_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/workout_overview_error_view.dart';
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
                ? _LoadedAppBarTitle(state: state)
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
              ? _BottomActionBar(
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
        currentExerciseName: _displayName(anchor),
      );
    }
    return _CurrentFocus(currentIds: {anchorId}, currentExerciseName: null);
  }

  static String _displayName(ExerciseViewModel vm) =>
      switch (vm.sessionExercise.state) {
        ReplacedState(:final substitute) => substitute.name,
        _ => vm.plannedExerciseName,
      };

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
      WorkoutOverviewLoaded() => _LoadedBody(
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

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({
    required this.state,
    required this.currentSessionExerciseIds,
    required this.onReplace,
    required this.onSkip,
    required this.onMarkDone,
    required this.onUngroup,
    required this.onGroupInto,
    required this.onOpenVideo,
    required this.onAddNote,
    required this.onAddExtraWork,
  });

  final WorkoutOverviewLoaded state;
  final Set<String> currentSessionExerciseIds;
  final void Function(ExerciseViewModel) onReplace;
  final void Function(ExerciseViewModel) onSkip;
  final void Function(ExerciseViewModel) onMarkDone;
  final void Function(String tag) onUngroup;
  final void Function(
    ExerciseViewModel,
    List<ExerciseViewModel>,
    List<SupersetGroup>,
  )
  onGroupInto;
  final void Function(String url) onOpenVideo;
  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody>
    with SingleTickerProviderStateMixin {
  /// Per-process gate: the coach-mark fires once per cold start, then never
  /// again until the app is killed. Persisting "once-ever" is deferred to
  /// the planned cross-screen coach-mark refactor.
  static bool _coachMarkShownThisSession = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  late final _DragAutoScroller _autoScroller;
  final _DragSession _dragSession = _DragSession();

  @override
  void initState() {
    super.initState();
    _autoScroller = _DragAutoScroller(
      tickerProvider: this,
      scrollController: _scrollController,
      viewportTopProvider: _viewportTop,
      viewportBottomProvider: _viewportBottom,
      edgeZone: 96,
      maxSpeed: 1000,
    );
  }

  @override
  void dispose() {
    _autoScroller.dispose();
    _scrollController.dispose();
    _dragSession.dispose();
    super.dispose();
  }

  double _viewportTop() {
    final box = _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return 0;
    return box.localToGlobal(Offset.zero).dy;
  }

  double _viewportBottom() {
    final box = _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return double.infinity;
    final origin = box.localToGlobal(Offset.zero);
    return origin.dy + box.size.height;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowCoachMark();
  }

  @override
  void didUpdateWidget(covariant _LoadedBody old) {
    super.didUpdateWidget(old);
    _maybeShowCoachMark();
  }

  void _maybeShowCoachMark() {
    if (_coachMarkShownThisSession) return;
    final unfinishedStandalone = widget.state.groups.where((g) {
      if (g is! SingleGroupViewModel) return false;
      return g.exercise.sessionExercise.state is UnfinishedState;
    }).length;
    if (unfinishedStandalone < 2) return;
    _coachMarkShownThisSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colors = Theme.of(context).appColors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: colors.surface,
          content: Text(
            'Tip: Tap ⋮ on any exercise → Group into superset to combine '
            'two. Or long-press and drag one card onto another.',
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

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = context.read<WorkoutOverviewBloc>();
    final transient = state.lastTransientError;
    final canMutate = !state.isEnded && !state.mutationInFlight;

    return Stack(
      children: [
        CustomScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          slivers: [
            if (transient != null)
              SliverToBoxAdapter(
                child: _TransientErrorBanner(
                  error: transient,
                  onDismiss: () =>
                      bloc.add(const WorkoutOverviewErrorDismissed()),
                ),
              ),
            if (state.isEnded)
              const SliverToBoxAdapter(child: _SessionEndedBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverList.builder(
                itemCount: state.groups.length * 2 + 1,
                itemBuilder: (context, index) {
                  if (index.isEven) {
                    final gapIndex = index ~/ 2;
                    return _ReorderGap(
                      sessionId: state.sessionState.session.id,
                      unfinishedIndex: _unfinishedIndexAt(
                        state.groups,
                        gapIndex,
                      ),
                      enabled: canMutate,
                      dragSession: _dragSession,
                    );
                  }
                  final groupIndex = (index - 1) ~/ 2;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: _GroupBuilder(
                      group: state.groups[groupIndex],
                      state: state,
                      currentSessionExerciseIds:
                          widget.currentSessionExerciseIds,
                      onReplace: widget.onReplace,
                      onSkip: widget.onSkip,
                      onMarkDone: widget.onMarkDone,
                      onUngroup: widget.onUngroup,
                      onGroupInto: widget.onGroupInto,
                      onOpenVideo: widget.onOpenVideo,
                      canMutate: canMutate,
                      autoScroller: _autoScroller,
                      dragSession: _dragSession,
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList.list(
                children: [
                  SessionNotesSection(
                    notes: state.sessionState.session.notes,
                    canAdd: canMutate,
                    onAddPressed: widget.onAddNote,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ExtraWorkSection(
                    extraWork: state.sessionState.session.extraWork,
                    canAdd: canMutate,
                    onAddPressed: widget.onAddExtraWork,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
        if (state.mutationInFlight)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }

  /// Translates a gap-between-groups index into the "unfinished count at or
  /// before this gap" the reorder semantics want — i.e. the number of
  /// unfinished exercises that appear strictly before the gap.
  int _unfinishedIndexAt(List<SupersetGroupViewModel> groups, int gapIndex) {
    var count = 0;
    for (var i = 0; i < gapIndex && i < groups.length; i++) {
      for (final ex in groups[i].allExercises) {
        if (ex.sessionExercise.state is UnfinishedState) count++;
      }
    }
    return count;
  }
}

class _GroupBuilder extends StatelessWidget {
  const _GroupBuilder({
    required this.group,
    required this.state,
    required this.currentSessionExerciseIds,
    required this.onReplace,
    required this.onSkip,
    required this.onMarkDone,
    required this.onUngroup,
    required this.onGroupInto,
    required this.onOpenVideo,
    required this.canMutate,
    required this.autoScroller,
    required this.dragSession,
  });

  final SupersetGroupViewModel group;
  final WorkoutOverviewLoaded state;
  final Set<String> currentSessionExerciseIds;
  final void Function(ExerciseViewModel) onReplace;
  final void Function(ExerciseViewModel) onSkip;
  final void Function(ExerciseViewModel) onMarkDone;
  final void Function(String tag) onUngroup;
  final void Function(
    ExerciseViewModel,
    List<ExerciseViewModel>,
    List<SupersetGroup>,
  )
  onGroupInto;
  final void Function(String url) onOpenVideo;
  final bool canMutate;
  final _DragAutoScroller autoScroller;
  final _DragSession dragSession;

  /// Other unfinished, non-grouped exercises in the session — the set of
  /// valid partners for a *new* superset paired with [source]. Used only
  /// for the menu-driven path; the drag path resolves the same way through
  /// the drop resolver.
  List<ExerciseViewModel> _groupCandidatesFor(ExerciseViewModel source) {
    final result = <ExerciseViewModel>[];
    for (final g in state.groups) {
      if (g is! SingleGroupViewModel) continue;
      final other = g.exercise;
      if (other.sessionExercise.id == source.sessionExercise.id) continue;
      if (other.sessionExercise.state is! UnfinishedState) continue;
      if (other.sessionExercise.supersetTag != null) continue;
      result.add(other);
    }
    return result;
  }

  /// Existing supersets [source] can be appended to. A group is eligible
  /// only when every member is still unfinished — mixing terminal and
  /// live members in one group is the unsafe state addToSuperset refuses.
  List<SupersetGroup> _eligibleSupersetGroupsFor(ExerciseViewModel source) {
    final result = <SupersetGroup>[];
    if (source.sessionExercise.supersetTag != null) return result;
    for (final g in state.groups) {
      if (g is! SupersetGroup) continue;
      final allUnfinished = g.exercises.every(
        (e) => e.sessionExercise.state is UnfinishedState,
      );
      if (allUnfinished) result.add(g);
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return switch (group) {
      SingleGroupViewModel(:final exercise) => _buildSingle(context, exercise),
      SupersetGroup(:final tag, :final exercises) => _buildSuperset(
        context,
        tag,
        exercises,
      ),
    };
  }

  Widget _buildSingle(BuildContext context, ExerciseViewModel exercise) {
    final candidates = canMutate
        ? _groupCandidatesFor(exercise)
        : const <ExerciseViewModel>[];
    final eligibleGroups = canMutate
        ? _eligibleSupersetGroupsFor(exercise)
        : const <SupersetGroup>[];
    final exerciseId = exercise.sessionExercise.id;
    final isCurrent = currentSessionExerciseIds.contains(exerciseId);
    return _DraggableExercise(
      exercise: exercise,
      isInSuperset: false,
      canMutate: canMutate,
      autoScroller: autoScroller,
      dragSession: dragSession,
      child: ExerciseCard(
        viewModel: exercise,
        isExpanded: state.expandedExerciseIds.contains(exerciseId),
        canMutate: canMutate,
        isCurrent: isCurrent,
        isLastTouched: state.lastTouchedSessionExerciseId == exerciseId,
        onToggleExpansion: () => context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewExpansionToggled(exerciseId),
        ),
        onLogSet: (values, plannedSetId) {
          Haptics.tap();
          context.read<WorkoutOverviewBloc>().add(
            WorkoutOverviewSetLogged(
              sessionExerciseId: exercise.sessionExercise.id,
              actualValues: values,
              plannedSetIdInSnapshot: plannedSetId,
            ),
          );
        },
        onEditSet: (executedSetId, values) =>
            context.read<WorkoutOverviewBloc>().add(
              WorkoutOverviewSetEdited(
                executedSetId: executedSetId,
                actualValues: values,
              ),
            ),
        onSkipPressed: () => onSkip(exercise),
        onMarkDonePressed: () => onMarkDone(exercise),
        onReplacePressed: () => onReplace(exercise),
        onOpenVideo: onOpenVideo,
        onGroupIntoPressed: (candidates.isEmpty && eligibleGroups.isEmpty)
            ? null
            : () => onGroupInto(exercise, candidates, eligibleGroups),
        showDragHandle: true,
      ),
    );
  }

  Widget _buildSuperset(
    BuildContext context,
    String tag,
    List<ExerciseViewModel> exercises,
  ) {
    // Per-member absolute unfinishedIndex (index into the global unfinished
    // sequence). `reorderUnfinished` operates on that absolute index, so each
    // intra-superset gap dispatches a [DropTarget.beforeIndex] computed from
    // this map.
    final unfinishedIndexById = <String, int>{};
    var unfinishedCounter = 0;
    for (final g in state.groups) {
      for (final ex in g.allExercises) {
        if (ex.sessionExercise.state is UnfinishedState) {
          unfinishedIndexById[ex.sessionExercise.id] = unfinishedCounter++;
        }
      }
    }

    Widget memberWrap(ExerciseViewModel member, Widget card) {
      if (!canMutate) return card;
      if (member.sessionExercise.state is! UnfinishedState) return card;
      return _SupersetMemberDraggable(
        exercise: member,
        autoScroller: autoScroller,
        dragSession: dragSession,
        child: card,
      );
    }

    // Gap position: 0..exercises.length. Map each position to the absolute
    // unfinishedIndex the drop should target:
    //   - position 0 → above the first unfinished member.
    //   - position k (between two members) → just before exercises[k] when
    //     it's unfinished; otherwise no gap.
    //   - position N → just after the last unfinished member.
    Widget gapWrap(int position) {
      if (!canMutate) return const SizedBox.shrink();
      // Find the unfinishedIndex this gap targets, if any.
      int? targetIndex;
      if (position == 0) {
        // Gap above first member — anchor to the first unfinished member of
        // the group, if any.
        for (final ex in exercises) {
          final idx = unfinishedIndexById[ex.sessionExercise.id];
          if (idx != null) {
            targetIndex = idx;
            break;
          }
        }
      } else if (position == exercises.length) {
        // Gap below last member — one past the last unfinished member.
        for (var i = exercises.length - 1; i >= 0; i--) {
          final idx = unfinishedIndexById[exercises[i].sessionExercise.id];
          if (idx != null) {
            targetIndex = idx + 1;
            break;
          }
        }
      } else {
        // Between two consecutive members. Anchor to the member *below* the
        // gap (its unfinishedIndex), so dropping here inserts before it.
        // Only render the gap when both neighbours are unfinished — otherwise
        // a drop would either be impossible or could break contiguity.
        final upper = exercises[position - 1];
        final lower = exercises[position];
        final upperUnf = upper.sessionExercise.state is UnfinishedState;
        final lowerUnf = lower.sessionExercise.state is UnfinishedState;
        if (upperUnf && lowerUnf) {
          targetIndex = unfinishedIndexById[lower.sessionExercise.id];
        }
      }
      if (targetIndex == null) {
        // Default visual spacing between members; nothing draggable.
        if (position == 0 || position == exercises.length) {
          return const SizedBox.shrink();
        }
        return const SizedBox(height: AppSpacing.sm);
      }
      return _SupersetReorderGap(
        supersetTag: tag,
        unfinishedIndex: targetIndex,
        dragSession: dragSession,
      );
    }

    return SupersetCard(
      tag: tag,
      exercises: exercises,
      expandedExerciseIds: state.expandedExerciseIds,
      canMutate: canMutate,
      currentSessionExerciseIds: currentSessionExerciseIds,
      lastTouchedSessionExerciseId: state.lastTouchedSessionExerciseId,
      onUngroupPressed: () => onUngroup(tag),
      onToggleExpansion: (id) => context.read<WorkoutOverviewBloc>().add(
        WorkoutOverviewExpansionToggled(id),
      ),
      onLogSet: (id, values, plannedId) {
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewSetLogged(
            sessionExerciseId: id,
            actualValues: values,
            plannedSetIdInSnapshot: plannedId,
          ),
        );
      },
      onEditSet: (executedSetId, values) =>
          context.read<WorkoutOverviewBloc>().add(
            WorkoutOverviewSetEdited(
              executedSetId: executedSetId,
              actualValues: values,
            ),
          ),
      onSkipPressed: (id) =>
          onSkip(exercises.firstWhere((e) => e.sessionExercise.id == id)),
      onMarkDonePressed: (id) =>
          onMarkDone(exercises.firstWhere((e) => e.sessionExercise.id == id)),
      onReplacePressed: (id) =>
          onReplace(exercises.firstWhere((e) => e.sessionExercise.id == id)),
      onOpenVideo: onOpenVideo,
      memberBuilder: memberWrap,
      gapBuilder: gapWrap,
    );
  }
}

/// Mirrors the display-name logic in [ExerciseCard]: a replaced exercise
/// shows its substitute's name, everything else shows the planned name.
/// Used as the label inside the compact drag-feedback pill.
String _exerciseDisplayName(ExerciseViewModel viewModel) {
  final state = viewModel.sessionExercise.state;
  return switch (state) {
    ReplacedState(:final substitute) => substitute.name,
    _ => viewModel.plannedExerciseName,
  };
}

/// Wraps an exercise card with both a Draggable (handle on the card)
/// and a DragTarget (the whole card body accepts drops to start a
/// superset). The reorder gaps between cards are separate widgets.
class _DraggableExercise extends StatefulWidget {
  const _DraggableExercise({
    required this.exercise,
    required this.isInSuperset,
    required this.canMutate,
    required this.autoScroller,
    required this.dragSession,
    required this.child,
  });

  final ExerciseViewModel exercise;
  final bool isInSuperset;
  final bool canMutate;
  final _DragAutoScroller autoScroller;
  final _DragSession dragSession;
  final Widget child;

  @override
  State<_DraggableExercise> createState() => _DraggableExerciseState();
}

class _DraggableExerciseState extends State<_DraggableExercise> {
  bool _registered = false;

  void _setRegistered(bool value) {
    if (_registered == value) return;
    _registered = value;
    if (value) {
      Haptics.selectionChange();
      widget.dragSession.hoverEntered();
    } else {
      widget.dragSession.hoverLeft();
    }
  }

  @override
  void dispose() {
    if (_registered) {
      _registered = false;
      widget.dragSession.hoverLeft();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isUnfinished =
        widget.exercise.sessionExercise.state is UnfinishedState;
    final canDrag = widget.canMutate && isUnfinished && !widget.isInSuperset;

    return DragTarget<ExerciseDragPayload>(
      onWillAcceptWithDetails: (details) {
        if (!widget.canMutate) return false;
        if (details.data.sessionExerciseId ==
            widget.exercise.sessionExercise.id) {
          return false;
        }
        if (!isUnfinished) return false;
        if (widget.exercise.sessionExercise.supersetTag != null) return false;
        // A dragged exercise that is itself part of a superset cannot
        // create or append to a new superset by being dropped onto a
        // standalone card. Drag-to-ungroup remains the supported flow
        // for leaving a superset; the within-superset reorder gaps
        // handle in-place moves.
        if (details.data.supersetTag != null) return false;
        return true;
      },
      onLeave: (_) => _setRegistered(false),
      onAcceptWithDetails: (details) {
        _setRegistered(false);
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewDropResolved(
            draggedSessionExerciseId: details.data.sessionExerciseId,
            target: DropTarget.ontoExercise(widget.exercise.sessionExercise.id),
          ),
        );
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        if (highlight != _registered) {
          // candidate count changed via builder rebuild; sync our flag in a
          // post-frame callback so the haptic fires on the enter transition.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _setRegistered(highlight);
          });
        }
        final card = _MaybeDraggable(
          canDrag: canDrag,
          payload: ExerciseDragPayload(
            sessionExerciseId: widget.exercise.sessionExercise.id,
            supersetTag: widget.exercise.sessionExercise.supersetTag,
          ),
          exerciseName: _exerciseDisplayName(widget.exercise),
          autoScroller: widget.autoScroller,
          dragSession: widget.dragSession,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 80),
            scale: highlight ? 0.98 : 1,
            child: Stack(
              children: [
                widget.child,
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 120),
                      opacity: highlight ? 1 : 0,
                      child: _SupersetDropOverlay(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        return card;
      },
    );
  }
}

/// Hover overlay shown on a card that's a valid drop target for a
/// superset-create gesture. Tints the card with the primary colour at low
/// alpha and centres a "Group as superset" pill so the user can tell this
/// drop is different from a reorder-into-gap drop.
class _SupersetDropOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.link, size: 18, color: colors.onPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Group as superset',
                style: typography.actionLabel.copyWith(color: colors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MaybeDraggable extends StatelessWidget {
  const _MaybeDraggable({
    required this.canDrag,
    required this.payload,
    required this.exerciseName,
    required this.autoScroller,
    required this.dragSession,
    required this.child,
  });

  final bool canDrag;
  final ExerciseDragPayload payload;
  final String exerciseName;
  final _DragAutoScroller autoScroller;
  final _DragSession dragSession;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!canDrag) return child;
    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = (screenWidth * 0.7).clamp(220.0, 360.0);
    return LongPressDraggable<ExerciseDragPayload>(
      data: payload,
      delay: const Duration(milliseconds: 250),
      onDragStarted: () {
        Haptics.grab();
        autoScroller.begin();
        dragSession.begin();
      },
      onDragUpdate: (details) =>
          autoScroller.updatePointer(details.globalPosition.dy),
      onDragEnd: (_) {
        autoScroller.end();
        dragSession.end();
      },
      onDraggableCanceled: (_, _) {
        autoScroller.end();
        dragSession.end();
      },
      feedback: _DragFeedbackPill(
        exerciseName: exerciseName,
        width: pillWidth,
        dragSession: dragSession,
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

/// Compact pill shown under the finger while dragging an exercise card.
/// Occludes far less of the screen than dragging the full card, so the
/// user can see and aim at the reorder gaps between groups. Fades to 60%
/// opacity (P3.2) when the pointer has been outside every valid drop
/// target for more than 250 ms, signalling "no target here".
class _DragFeedbackPill extends StatelessWidget {
  const _DragFeedbackPill({
    required this.exerciseName,
    required this.width,
    required this.dragSession,
  });

  final String exerciseName;
  final double width;
  final _DragSession dragSession;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return AnimatedBuilder(
      animation: dragSession,
      builder: (context, _) {
        final dimmed = dragSession.isOutsideStable;
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: dimmed ? 0.6 : 1.0,
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              width: width,
              height: AppSpacing.touchMin,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.primary, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, size: 20, color: colors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      exerciseName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.label.copyWith(color: colors.onSurface),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Icon(Icons.swap_vert, size: 18, color: colors.onSurfaceMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Drop zone between two exercise groups. The hit area is always
/// [_restHitHeight] tall so the user has a comfortable target while
/// dragging; the visible indicator is a thin centered line at rest, a
/// taller bar with a muted "Move here" label while a drag is active, and
/// a full-width primary bar when a drag is hovering directly over it.
class _ReorderGap extends StatefulWidget {
  const _ReorderGap({
    required this.sessionId,
    required this.unfinishedIndex,
    required this.enabled,
    required this.dragSession,
  });

  final String sessionId;
  final int unfinishedIndex;
  final bool enabled;
  final _DragSession dragSession;

  @override
  State<_ReorderGap> createState() => _ReorderGapState();
}

class _ReorderGapState extends State<_ReorderGap> {
  static const double _restHitHeight = 32;
  static const double _activeHitHeight = 40;
  static const double _hoverHitHeight = 48;

  bool _registered = false;

  void _setRegistered(bool value) {
    if (_registered == value) return;
    _registered = value;
    if (value) {
      Haptics.selectionChange();
      widget.dragSession.hoverEntered();
    } else {
      widget.dragSession.hoverLeft();
    }
  }

  @override
  void dispose() {
    if (_registered) {
      _registered = false;
      widget.dragSession.hoverLeft();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return AnimatedBuilder(
      animation: widget.dragSession,
      builder: (context, _) {
        final dragActive = widget.dragSession.active && widget.enabled;
        return DragTarget<ExerciseDragPayload>(
          onWillAcceptWithDetails: (details) {
            if (!widget.enabled) return false;
            // Members of a superset reorder inside their own group via the
            // intra-superset gaps. Letting them land on a top-level gap
            // would split the contiguous run and silently break the group.
            if (details.data.supersetTag != null) return false;
            return true;
          },
          onLeave: (_) => _setRegistered(false),
          onAcceptWithDetails: (details) {
            _setRegistered(false);
            Haptics.tap();
            context.read<WorkoutOverviewBloc>().add(
              WorkoutOverviewDropResolved(
                draggedSessionExerciseId: details.data.sessionExerciseId,
                target: DropTarget.beforeIndex(widget.unfinishedIndex),
              ),
            );
          },
          builder: (context, candidate, _) {
            final hovering = candidate.isNotEmpty && widget.enabled;
            if (hovering != _registered) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _setRegistered(hovering);
              });
            }
            final height = hovering
                ? _hoverHitHeight
                : dragActive
                ? _activeHitHeight
                : _restHitHeight;
            final barHeight = hovering
                ? 6.0
                : dragActive
                ? 4.0
                : 2.0;
            final barMargin = hovering
                ? 0.0
                : dragActive
                ? AppSpacing.lg
                : AppSpacing.xl;
            final barColor = hovering
                ? colors.primary
                : dragActive
                ? colors.primary.withValues(alpha: 0.55)
                : colors.outline.withValues(alpha: 0.4);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: height,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      height: barHeight,
                      margin: EdgeInsets.symmetric(horizontal: barMargin),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  if (dragActive && !hovering) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        'Move here',
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
                        height: barHeight,
                        margin: EdgeInsets.symmetric(horizontal: barMargin),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}

/// Wraps an unfinished superset member with a [LongPressDraggable] so it can
/// be dragged onto a [_SupersetReorderGap] inside the same group to reorder.
/// The payload carries the source `supersetTag`; only intra-superset gaps
/// with the matching tag will accept it (the main-list reorder gaps and the
/// onto-card targets both refuse non-null tags).
class _SupersetMemberDraggable extends StatelessWidget {
  const _SupersetMemberDraggable({
    required this.exercise,
    required this.autoScroller,
    required this.dragSession,
    required this.child,
  });

  final ExerciseViewModel exercise;
  final _DragAutoScroller autoScroller;
  final _DragSession dragSession;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = (screenWidth * 0.7).clamp(220.0, 360.0);
    return LongPressDraggable<ExerciseDragPayload>(
      data: ExerciseDragPayload(
        sessionExerciseId: exercise.sessionExercise.id,
        supersetTag: exercise.sessionExercise.supersetTag,
      ),
      delay: const Duration(milliseconds: 250),
      onDragStarted: () {
        Haptics.grab();
        autoScroller.begin();
        dragSession.begin();
      },
      onDragUpdate: (details) =>
          autoScroller.updatePointer(details.globalPosition.dy),
      onDragEnd: (_) {
        autoScroller.end();
        dragSession.end();
      },
      onDraggableCanceled: (_, _) {
        autoScroller.end();
        dragSession.end();
      },
      feedback: _DragFeedbackPill(
        exerciseName: _exerciseDisplayName(exercise),
        width: pillWidth,
        dragSession: dragSession,
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

/// Drop zone between two members of the same superset (or at the top/bottom
/// edges of the member list). Accepts only payloads whose `supersetTag`
/// matches [supersetTag] — that gating is what keeps the contiguous run
/// intact: an outsider dropped here would split the group, and a member
/// dropped onto a top-level gap would do the same in reverse.
///
/// On accept, dispatches a [DropTarget.beforeIndex] with the absolute
/// unfinishedIndex this gap was anchored to. The existing reorder path in
/// the engine permutes positions among unfinished slots; tags are
/// untouched, so the assembler still treats the group as one superset.
class _SupersetReorderGap extends StatefulWidget {
  const _SupersetReorderGap({
    required this.supersetTag,
    required this.unfinishedIndex,
    required this.dragSession,
  });

  final String supersetTag;
  final int unfinishedIndex;
  final _DragSession dragSession;

  @override
  State<_SupersetReorderGap> createState() => _SupersetReorderGapState();
}

class _SupersetReorderGapState extends State<_SupersetReorderGap> {
  static const double _restHitHeight = 8;
  static const double _activeHitHeight = 24;
  static const double _hoverHitHeight = 32;

  bool _registered = false;

  void _setRegistered(bool value) {
    if (_registered == value) return;
    _registered = value;
    if (value) {
      Haptics.selectionChange();
      widget.dragSession.hoverEntered();
    } else {
      widget.dragSession.hoverLeft();
    }
  }

  @override
  void dispose() {
    if (_registered) {
      _registered = false;
      widget.dragSession.hoverLeft();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return AnimatedBuilder(
      animation: widget.dragSession,
      builder: (context, _) {
        final dragActive = widget.dragSession.active;
        return DragTarget<ExerciseDragPayload>(
          onWillAcceptWithDetails: (details) {
            return details.data.supersetTag == widget.supersetTag;
          },
          onLeave: (_) => _setRegistered(false),
          onAcceptWithDetails: (details) {
            _setRegistered(false);
            Haptics.tap();
            context.read<WorkoutOverviewBloc>().add(
              WorkoutOverviewDropResolved(
                draggedSessionExerciseId: details.data.sessionExerciseId,
                target: DropTarget.beforeIndex(widget.unfinishedIndex),
              ),
            );
          },
          builder: (context, candidate, _) {
            final hovering = candidate.isNotEmpty;
            if (hovering != _registered) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _setRegistered(hovering);
              });
            }
            final height = hovering
                ? _hoverHitHeight
                : dragActive
                ? _activeHitHeight
                : _restHitHeight;
            final barHeight = hovering
                ? 4.0
                : dragActive
                ? 2.0
                : 0.0;
            final barColor = hovering
                ? colors.primary
                : colors.primary.withValues(alpha: 0.55);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: height,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _TransientErrorBanner extends StatelessWidget {
  const _TransientErrorBanner({required this.error, required this.onDismiss});

  final DomainError error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final presented = DomainErrorPresenter.present(error);
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  presented.title,
                  style: typography.label.copyWith(color: colors.error),
                ),
                const SizedBox(height: 2),
                Text(
                  presented.body,
                  style: typography.bodySmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDismiss,
            tooltip: 'Dismiss',
            icon: Icon(Icons.close, color: colors.onSurfaceMuted, size: 18),
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchMin,
              minHeight: AppSpacing.touchMin,
            ),
          ),
        ],
      ),
    );
  }
}

class _SessionEndedBanner extends StatelessWidget {
  const _SessionEndedBanner();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.exerciseCompleted.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.exerciseCompleted.withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.check_circle, color: colors.exerciseCompleted, size: 20),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Session ended. Completed sets remain editable.',
              style: AppTypography.standard.bodySmall.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActionBar extends StatelessWidget {
  const _BottomActionBar({
    required this.state,
    required this.currentExerciseName,
    required this.onAddNote,
    required this.onAddExtraWork,
    required this.onFocusMode,
  });

  final WorkoutOverviewLoaded state;

  /// Display name of the exercise the Focus button will open, or null when
  /// there's no open target. Shown as `Focus: <name>` so the user can
  /// confirm the target before tapping.
  final String? currentExerciseName;
  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;
  final VoidCallback onFocusMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final hasOpenTarget = state.sessionState.openTargets.isNotEmpty;
    final canMutate = !state.isEnded && !state.mutationInFlight;
    final label = currentExerciseName == null
        ? 'Focus'
        : 'Focus: $currentExerciseName';

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.sm,
          AppSpacing.lg,
          AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: colors.surface,
          border: Border(top: BorderSide(color: colors.outline)),
        ),
        child: Row(
          children: [
            _SecondaryActionButton(
              icon: Icons.sticky_note_2_outlined,
              tooltip: 'Add note',
              onPressed: canMutate ? onAddNote : null,
            ),
            const SizedBox(width: AppSpacing.xs),
            _SecondaryActionButton(
              icon: Icons.add_task,
              tooltip: 'Add extra work',
              onPressed: canMutate ? onAddExtraWork : null,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: FilledButton.icon(
                onPressed: hasOpenTarget && !state.isEnded ? onFocusMode : null,
                icon: const Icon(Icons.center_focus_strong, size: 18),
                label: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Square 48dp icon button used in the bottom action bar for secondary
/// actions (Note, Extra). Outlined to read as a peer of the primary
/// FilledButton next to it, sized to satisfy [AppSpacing.touchMin].
class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.touchMin,
      height: AppSpacing.touchMin,
      child: Tooltip(
        message: tooltip,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: const Size.square(AppSpacing.touchMin),
          ),
          child: Icon(icon, size: 20, semanticLabel: tooltip),
        ),
      ),
    );
  }
}

/// AppBar title for the loaded state. Stacks the workout-day name above a
/// `done of total · mm:ss` status line so the user always knows their
/// position and pace at a glance.
class _LoadedAppBarTitle extends StatelessWidget {
  const _LoadedAppBarTitle({required this.state});

  final WorkoutOverviewLoaded state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final counts = _exerciseCounts(state);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          state.sessionState.session.snapshot.workoutDay.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Row(
          children: [
            Text(
              '${counts.done} of ${counts.total}',
              style: typography.numericSm.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            Text(
              '  ·  ',
              style: typography.labelSmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
            _SessionElapsedLabel(
              startedAt: state.sessionState.session.startedAt,
              endedAt: state.sessionState.session.endedAt,
            ),
          ],
        ),
      ],
    );
  }

  static ({int done, int total}) _exerciseCounts(WorkoutOverviewLoaded state) {
    var done = 0;
    var total = 0;
    for (final group in state.groups) {
      for (final ex in group.allExercises) {
        total++;
        if (ex.sessionExercise.state is! UnfinishedState) done++;
      }
    }
    return (done: done, total: total);
  }
}

/// Ticking elapsed-time readout. Counts up from [startedAt] every second
/// while the session is live; freezes at `endedAt - startedAt` once the
/// session ends.
class _SessionElapsedLabel extends StatefulWidget {
  const _SessionElapsedLabel({required this.startedAt, required this.endedAt});

  final DateTime startedAt;
  final DateTime? endedAt;

  @override
  State<_SessionElapsedLabel> createState() => _SessionElapsedLabelState();
}

class _SessionElapsedLabelState extends State<_SessionElapsedLabel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _maybeStartTicker();
  }

  @override
  void didUpdateWidget(covariant _SessionElapsedLabel old) {
    super.didUpdateWidget(old);
    if (old.endedAt != widget.endedAt) {
      _ticker?.cancel();
      _ticker = null;
      _maybeStartTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _maybeStartTicker() {
    if (widget.endedAt != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final end = widget.endedAt ?? DateTime.now().toUtc();
    final seconds = end.difference(widget.startedAt).inSeconds;
    return Text(
      _formatElapsed(seconds < 0 ? 0 : seconds),
      style: typography.numericSm.copyWith(color: colors.onSurfaceMuted),
    );
  }

  static String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }
}

/// Drives edge auto-scroll on the workout-overview list while a drag is in
/// flight. The list is a [CustomScrollView] with no built-in auto-scroll, so
/// we tick from a [Ticker] and jump the [ScrollController] each frame based
/// on the pointer's global Y position relative to the visible viewport.
class _DragAutoScroller {
  _DragAutoScroller({
    required TickerProvider tickerProvider,
    required this.scrollController,
    required this.viewportTopProvider,
    required this.viewportBottomProvider,
    this.edgeZone = 96.0,
    this.maxSpeed = 1000.0,
  }) {
    _ticker = tickerProvider.createTicker(_onTick);
  }

  final ScrollController scrollController;
  final double Function() viewportTopProvider;
  final double Function() viewportBottomProvider;
  final double edgeZone;
  final double maxSpeed;

  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _pointerY = 0;
  bool _active = false;

  void begin() {
    _active = true;
    _lastElapsed = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void updatePointer(double globalY) {
    if (!_active) return;
    _pointerY = globalY;
  }

  void end() {
    _active = false;
    _lastElapsed = null;
    if (_ticker.isActive) _ticker.stop();
  }

  void dispose() {
    _ticker.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_active) return;
    final last = _lastElapsed;
    _lastElapsed = elapsed;
    if (last == null) return;
    final dt = (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return;
    final velocity = computeScrollDelta(
      pointerY: _pointerY,
      viewportTop: viewportTopProvider(),
      viewportBottom: viewportBottomProvider(),
      edgeZone: edgeZone,
      maxSpeed: maxSpeed,
    );
    if (velocity == 0) return;
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final target = (position.pixels + velocity * dt).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) {
      position.jumpTo(target);
    }
  }
}

/// Shared in-flight drag state for the workout-overview list. Tracks:
///
/// - `active`: whether a long-press drag is currently in flight. Drives the
///   reorder-gap "Move here" affordance (P2.1).
/// - hover entries / exits across every [DragTarget] in the list. When the
///   pointer has been outside every valid target for more than 250 ms the
///   carried [_DragFeedbackPill] fades to 60 % opacity (P3.2).
class _DragSession extends ChangeNotifier {
  bool _active = false;
  int _hoverCount = 0;
  Timer? _outsideTimer;
  bool _isOutsideStable = false;

  bool get active => _active;

  /// `true` when a drag is active, the pointer is not currently inside any
  /// valid drop target, and it has been outside for ≥ 250 ms. Used by the
  /// drag-feedback pill to signal "no target here".
  bool get isOutsideStable => _active && _isOutsideStable;

  void begin() {
    if (_active) return;
    _active = true;
    _hoverCount = 0;
    _isOutsideStable = false;
    _scheduleOutsideTimer();
    notifyListeners();
  }

  void end() {
    if (!_active && _hoverCount == 0 && !_isOutsideStable) return;
    _active = false;
    _hoverCount = 0;
    _isOutsideStable = false;
    _outsideTimer?.cancel();
    _outsideTimer = null;
    notifyListeners();
  }

  void hoverEntered() {
    _hoverCount++;
    if (_hoverCount == 1) {
      _outsideTimer?.cancel();
      _outsideTimer = null;
      if (_isOutsideStable) {
        _isOutsideStable = false;
        notifyListeners();
      }
    }
  }

  void hoverLeft() {
    if (_hoverCount == 0) return;
    _hoverCount--;
    if (_hoverCount == 0 && _active) {
      _scheduleOutsideTimer();
    }
  }

  void _scheduleOutsideTimer() {
    _outsideTimer?.cancel();
    _outsideTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_active || _hoverCount > 0) return;
      _isOutsideStable = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _outsideTimer?.cancel();
    super.dispose();
  }
}
