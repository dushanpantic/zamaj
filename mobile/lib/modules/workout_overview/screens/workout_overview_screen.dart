import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';
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
  /// Per-exercise: which set row is currently expanded (only one at a time
  /// per exercise to keep the card compact). Lives in widget state because
  /// it's pure UI/editor focus, not session truth.
  final Map<String, int> _expandedSetPositions = {};

  void _toggleSetExpansion(String sessionExerciseId, int position) {
    setState(() {
      if (_expandedSetPositions[sessionExerciseId] == position) {
        _expandedSetPositions.remove(sessionExerciseId);
      } else {
        _expandedSetPositions[sessionExerciseId] = position;
      }
    });
  }

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
    final result = await ReplaceExerciseDialog.show(
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

  Future<void> _handleUngroup(String tag) async {
    context.read<WorkoutOverviewBloc>().add(
      WorkoutOverviewSupersetUngrouped(tag),
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

  void _handleOpenFocusMode(String sessionId) {
    Navigator.of(context).pushNamed(SessionRoutes.focus, arguments: sessionId);
  }

  static Cursor? _cursorOf(WorkoutOverviewState s) =>
      s is WorkoutOverviewLoaded ? s.sessionState.cursor : null;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return BlocConsumer<WorkoutOverviewBloc, WorkoutOverviewState>(
      listenWhen: (p, c) => _cursorOf(p) != _cursorOf(c),
      listener: (context, state) {
        final cursor = _cursorOf(state);
        if (cursor is! ActiveCursor) return;
        setState(() {
          _expandedSetPositions[cursor.sessionExerciseId] = cursor.setIndex;
        });
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(_titleFor(state)),
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
                  onFocusMode: () =>
                      _handleOpenFocusMode(state.sessionState.session.id),
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
        expandedSetPositions: _expandedSetPositions,
        onToggleSetExpansion: _toggleSetExpansion,
        onReplace: _handleReplace,
        onSkip: _handleSkip,
        onUngroup: _handleUngroup,
        onOpenVideo: _openVideo,
        onAddNote: _handleAddNote,
        onAddExtraWork: _handleAddExtraWork,
      ),
    };
  }
}

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({
    required this.state,
    required this.expandedSetPositions,
    required this.onToggleSetExpansion,
    required this.onReplace,
    required this.onSkip,
    required this.onUngroup,
    required this.onOpenVideo,
    required this.onAddNote,
    required this.onAddExtraWork,
  });

  final WorkoutOverviewLoaded state;
  final Map<String, int> expandedSetPositions;
  final void Function(String sessionExerciseId, int position)
  onToggleSetExpansion;
  final void Function(ExerciseViewModel) onReplace;
  final void Function(ExerciseViewModel) onSkip;
  final void Function(String tag) onUngroup;
  final void Function(String url) onOpenVideo;
  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;

  @override
  Widget build(BuildContext context) {
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
                      expandedSetPositions: expandedSetPositions,
                      onToggleSetExpansion: onToggleSetExpansion,
                      onReplace: onReplace,
                      onSkip: onSkip,
                      onUngroup: onUngroup,
                      onOpenVideo: onOpenVideo,
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
                    onAddPressed: onAddNote,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ExtraWorkSection(
                    extraWork: state.sessionState.session.extraWork,
                    canAdd: canMutate,
                    onAddPressed: onAddExtraWork,
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
    required this.expandedSetPositions,
    required this.onToggleSetExpansion,
    required this.onReplace,
    required this.onSkip,
    required this.onUngroup,
    required this.onOpenVideo,
    required this.canMutate,
  });

  final SupersetGroupViewModel group;
  final WorkoutOverviewLoaded state;
  final Map<String, int> expandedSetPositions;
  final void Function(String, int) onToggleSetExpansion;
  final void Function(ExerciseViewModel) onReplace;
  final void Function(ExerciseViewModel) onSkip;
  final void Function(String tag) onUngroup;
  final void Function(String url) onOpenVideo;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    return switch (group) {
      SingleGroupViewModel(:final exercise) => _DraggableExercise(
        exercise: exercise,
        isInSuperset: false,
        canMutate: canMutate,
        child: ExerciseCard(
          viewModel: exercise,
          isExpanded: state.expandedExerciseIds.contains(
            exercise.sessionExercise.id,
          ),
          expandedSetPosition:
              expandedSetPositions[exercise.sessionExercise.id],
          canMutate: canMutate,
          onToggleExpansion: () => context.read<WorkoutOverviewBloc>().add(
            WorkoutOverviewExpansionToggled(exercise.sessionExercise.id),
          ),
          onToggleSetExpansion: (pos) =>
              onToggleSetExpansion(exercise.sessionExercise.id, pos),
          onLogSet: (values, plannedSetId) =>
              context.read<WorkoutOverviewBloc>().add(
                WorkoutOverviewSetLogged(
                  sessionExerciseId: exercise.sessionExercise.id,
                  actualValues: values,
                  plannedSetIdInSnapshot: plannedSetId,
                ),
              ),
          onEditSet: (executedSetId, values) =>
              context.read<WorkoutOverviewBloc>().add(
                WorkoutOverviewSetEdited(
                  executedSetId: executedSetId,
                  actualValues: values,
                ),
              ),
          onSkipPressed: () => onSkip(exercise),
          onReplacePressed: () => onReplace(exercise),
          onOpenVideo: onOpenVideo,
          showDragHandle: true,
        ),
      ),
      SupersetGroup(:final tag, :final exercises) => SupersetCard(
        tag: tag,
        exercises: exercises,
        expandedExerciseIds: state.expandedExerciseIds,
        expandedSetPositions: expandedSetPositions,
        canMutate: canMutate,
        onUngroupPressed: () => onUngroup(tag),
        onToggleExpansion: (id) => context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewExpansionToggled(id),
        ),
        onToggleSetExpansion: onToggleSetExpansion,
        onLogSet: (id, values, plannedId) =>
            context.read<WorkoutOverviewBloc>().add(
              WorkoutOverviewSetLogged(
                sessionExerciseId: id,
                actualValues: values,
                plannedSetIdInSnapshot: plannedId,
              ),
            ),
        onEditSet: (executedSetId, values) =>
            context.read<WorkoutOverviewBloc>().add(
              WorkoutOverviewSetEdited(
                executedSetId: executedSetId,
                actualValues: values,
              ),
            ),
        onSkipPressed: (id) =>
            onSkip(exercises.firstWhere((e) => e.sessionExercise.id == id)),
        onReplacePressed: (id) =>
            onReplace(exercises.firstWhere((e) => e.sessionExercise.id == id)),
        onOpenVideo: onOpenVideo,
      ),
    };
  }
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
          child: AnimatedScale(
            duration: const Duration(milliseconds: 80),
            scale: highlight ? 0.98 : 1,
            child: child,
          ),
        );
        return Container(
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: card,
        );
      },
    );
  }
}

class _MaybeDraggable extends StatelessWidget {
  const _MaybeDraggable({
    required this.canDrag,
    required this.payload,
    required this.child,
  });

  final bool canDrag;
  final ExerciseDragPayload payload;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!canDrag) return child;
    return LongPressDraggable<ExerciseDragPayload>(
      data: payload,
      delay: const Duration(milliseconds: 250),
      feedback: Material(
        elevation: 6,
        color: Colors.transparent,
        child: SizedBox(
          width: MediaQuery.of(context).size.width - AppSpacing.lg * 2,
          child: child,
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: child),
      child: child,
    );
  }
}

class _ReorderGap extends StatelessWidget {
  const _ReorderGap({
    required this.sessionId,
    required this.unfinishedIndex,
    required this.enabled,
  });

  final String sessionId;
  final int unfinishedIndex;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return DragTarget<ExerciseDragPayload>(
      onWillAcceptWithDetails: (_) => enabled,
      onAcceptWithDetails: (details) {
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
          duration: const Duration(milliseconds: 100),
          height: hovering ? 18 : 6,
          margin: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          decoration: BoxDecoration(
            color: hovering ? colors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
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
    final cursor = state.sessionState.cursor;
    final hasActiveSet = cursor is ActiveCursor;
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
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canMutate ? onAddNote : null,
                icon: const Icon(Icons.sticky_note_2_outlined, size: 18),
                label: const Text('Note'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: canMutate ? onAddExtraWork : null,
                icon: const Icon(Icons.add_task, size: 18),
                label: const Text('Extra'),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: hasActiveSet && !state.isEnded ? onFocusMode : null,
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
