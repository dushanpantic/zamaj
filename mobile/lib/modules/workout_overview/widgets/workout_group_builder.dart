import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroller.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/drag_handle.dart';
import 'package:zamaj/modules/workout_overview/widgets/draggable_exercise.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';
import 'package:zamaj/modules/workout_overview/widgets/superset_card.dart';
import 'package:zamaj/modules/workout_overview/widgets/superset_reorder_gap.dart';

/// Dispatches a single overview row to either a standalone [ExerciseCard]
/// (wrapped in a [DraggableExercise] drop target) or a [SupersetCard],
/// wiring up the per-member drag handles and intra-superset reorder gaps.
class WorkoutGroupBuilder extends StatelessWidget {
  const WorkoutGroupBuilder({
    super.key,
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
  final DragAutoScroller autoScroller;
  final DragSession dragSession;

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
    final isUnfinished = exercise.sessionExercise.state is UnfinishedState;
    // Handle visibility intentionally ignores mutationInFlight: gating it on
    // canMutate (which flips false during the in-flight window) made the
    // header shift left/right on every LOG SET as the 48 dp handle slot
    // collapsed and reappeared. Drops started mid-flight resolve safely —
    // the DragTarget and bloc both reject when canMutate is false.
    final canDrag = !state.isEnded && isUnfinished;
    return DraggableExercise(
      exercise: exercise,
      canMutate: canMutate,
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
        dragHandle: canDrag
            ? DragHandle(
                exercise: exercise,
                exerciseName: exercise.displayName,
                autoScroller: autoScroller,
                dragSession: dragSession,
              )
            : null,
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

    Widget? memberDragHandle(ExerciseViewModel member) {
      // Same reasoning as _buildSingle: keep the handle slot stable across
      // the in-flight window so the member header doesn't shift on LOG SET.
      if (state.isEnded) return null;
      if (member.sessionExercise.state is! UnfinishedState) return null;
      return DragHandle(
        exercise: member,
        exerciseName: member.displayName,
        autoScroller: autoScroller,
        dragSession: dragSession,
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
      return SupersetReorderGap(
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
      memberDragHandleBuilder: memberDragHandle,
      gapBuilder: gapWrap,
    );
  }
}
