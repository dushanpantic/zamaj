import 'dart:async';

import 'package:flutter/material.dart';
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
  ) async {
    if (candidates.isEmpty) return;
    final pickedId = await GroupWithPickerDialog.show(
      context: context,
      candidates: candidates,
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
          body: _body(context, state),
          bottomNavigationBar: state is WorkoutOverviewLoaded
              ? _BottomActionBar(
                  state: state,
                  onAddNote: _handleAddNote,
                  onAddExtraWork: _handleAddExtraWork,
                  onFocusMode: () => _handleOpenFocusMode(state),
                )
              : null,
        );
      },
    );
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

  Widget _body(BuildContext context, WorkoutOverviewState state) {
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

class _LoadedBody extends StatefulWidget {
  const _LoadedBody({
    required this.state,
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
  final void Function(ExerciseViewModel) onReplace;
  final void Function(ExerciseViewModel) onSkip;
  final void Function(ExerciseViewModel) onMarkDone;
  final void Function(String tag) onUngroup;
  final void Function(ExerciseViewModel, List<ExerciseViewModel>) onGroupInto;
  final void Function(String url) onOpenVideo;
  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;

  @override
  State<_LoadedBody> createState() => _LoadedBodyState();
}

class _LoadedBodyState extends State<_LoadedBody> {
  /// Per-process gate: the coach-mark fires once per cold start, then never
  /// again until the app is killed. Persisting "once-ever" is deferred to
  /// the planned cross-screen coach-mark refactor.
  static bool _coachMarkShownThisSession = false;

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
                    );
                  }
                  final groupIndex = (index - 1) ~/ 2;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: _GroupBuilder(
                      group: state.groups[groupIndex],
                      state: state,
                      onReplace: widget.onReplace,
                      onSkip: widget.onSkip,
                      onMarkDone: widget.onMarkDone,
                      onUngroup: widget.onUngroup,
                      onGroupInto: widget.onGroupInto,
                      onOpenVideo: widget.onOpenVideo,
                      canMutate: canMutate,
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
    required this.onReplace,
    required this.onSkip,
    required this.onMarkDone,
    required this.onUngroup,
    required this.onGroupInto,
    required this.onOpenVideo,
    required this.canMutate,
  });

  final SupersetGroupViewModel group;
  final WorkoutOverviewLoaded state;
  final void Function(ExerciseViewModel) onReplace;
  final void Function(ExerciseViewModel) onSkip;
  final void Function(ExerciseViewModel) onMarkDone;
  final void Function(String tag) onUngroup;
  final void Function(ExerciseViewModel, List<ExerciseViewModel>) onGroupInto;
  final void Function(String url) onOpenVideo;
  final bool canMutate;

  /// Other unfinished, non-grouped exercises in the session — the set of
  /// valid partners for a "Group into superset…" pairing started from
  /// [source]. Used only for the menu-driven path; the drag path resolves
  /// the same way through the drop resolver.
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
    return _DraggableExercise(
      exercise: exercise,
      isInSuperset: false,
      canMutate: canMutate,
      child: ExerciseCard(
        viewModel: exercise,
        isExpanded: state.expandedExerciseIds.contains(
          exercise.sessionExercise.id,
        ),
        canMutate: canMutate,
        isLastTouched:
            state.lastTouchedSessionExerciseId == exercise.sessionExercise.id,
        onToggleExpansion: () => context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewExpansionToggled(exercise.sessionExercise.id),
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
        onGroupIntoPressed: candidates.isEmpty
            ? null
            : () => onGroupInto(exercise, candidates),
        showDragHandle: true,
      ),
    );
  }

  Widget _buildSuperset(
    BuildContext context,
    String tag,
    List<ExerciseViewModel> exercises,
  ) {
    return SupersetCard(
      tag: tag,
      exercises: exercises,
      expandedExerciseIds: state.expandedExerciseIds,
      canMutate: canMutate,
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
class _DraggableExercise extends StatelessWidget {
  const _DraggableExercise({
    required this.exercise,
    required this.isInSuperset,
    required this.canMutate,
    required this.child,
  });

  final ExerciseViewModel exercise;
  final bool isInSuperset;
  final bool canMutate;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final isUnfinished = exercise.sessionExercise.state is UnfinishedState;
    final canDrag = canMutate && isUnfinished && !isInSuperset;

    return DragTarget<ExerciseDragPayload>(
      onWillAcceptWithDetails: (details) {
        if (!canMutate) return false;
        if (details.data.sessionExerciseId == exercise.sessionExercise.id) {
          return false;
        }
        if (!isUnfinished) return false;
        if (exercise.sessionExercise.supersetTag != null) return false;
        return true;
      },
      onAcceptWithDetails: (details) {
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewDropResolved(
            draggedSessionExerciseId: details.data.sessionExerciseId,
            target: DropTarget.ontoExercise(exercise.sessionExercise.id),
          ),
        );
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        final card = _MaybeDraggable(
          canDrag: canDrag,
          payload: ExerciseDragPayload(exercise.sessionExercise.id),
          exerciseName: _exerciseDisplayName(exercise),
          child: AnimatedScale(
            duration: const Duration(milliseconds: 80),
            scale: highlight ? 0.98 : 1,
            child: Stack(
              children: [
                child,
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
    required this.child,
  });

  final bool canDrag;
  final ExerciseDragPayload payload;
  final String exerciseName;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!canDrag) return child;
    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = (screenWidth * 0.7).clamp(220.0, 360.0);
    return LongPressDraggable<ExerciseDragPayload>(
      data: payload,
      delay: const Duration(milliseconds: 250),
      onDragStarted: Haptics.grab,
      feedback: _DragFeedbackPill(exerciseName: exerciseName, width: pillWidth),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

/// Compact pill shown under the finger while dragging an exercise card.
/// Occludes far less of the screen than dragging the full card, so the
/// user can see and aim at the reorder gaps between groups.
class _DragFeedbackPill extends StatelessWidget {
  const _DragFeedbackPill({required this.exerciseName, required this.width});

  final String exerciseName;
  final double width;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Material(
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
    );
  }
}

/// Drop zone between two exercise groups. The hit area is always
/// [_restHitHeight] tall so the user has a comfortable target while
/// dragging; the visible indicator is just a thin centered line at rest
/// and expands into a full-width primary bar when a drag is hovering.
class _ReorderGap extends StatelessWidget {
  const _ReorderGap({
    required this.sessionId,
    required this.unfinishedIndex,
    required this.enabled,
  });

  final String sessionId;
  final int unfinishedIndex;
  final bool enabled;

  static const double _restHitHeight = 32;
  static const double _hoverHitHeight = 48;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DragTarget<ExerciseDragPayload>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (details) {
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewDropResolved(
            draggedSessionExerciseId: details.data.sessionExerciseId,
            target: DropTarget.beforeIndex(unfinishedIndex),
          ),
        );
      },
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty && enabled;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          height: hovering ? _hoverHitHeight : _restHitHeight,
          alignment: Alignment.center,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            curve: Curves.easeOut,
            height: hovering ? 6 : 2,
            margin: EdgeInsets.symmetric(
              horizontal: hovering ? 0 : AppSpacing.xl,
            ),
            decoration: BoxDecoration(
              color: hovering
                  ? colors.primary
                  : colors.outline.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
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
    required this.onAddNote,
    required this.onAddExtraWork,
    required this.onFocusMode,
  });

  final WorkoutOverviewLoaded state;
  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;
  final VoidCallback onFocusMode;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final hasOpenTarget = state.sessionState.openTargets.isNotEmpty;
    final canMutate = !state.isEnded && !state.mutationInFlight;

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
                label: const Text('Focus'),
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
