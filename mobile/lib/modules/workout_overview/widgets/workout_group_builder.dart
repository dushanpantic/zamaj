import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroller.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/services/reorder_move_resolver.dart';
import 'package:zamaj/modules/workout_overview/services/superset_remove_eligibility.dart';
import 'package:zamaj/modules/workout_overview/services/superset_reorder_resolver.dart';
import 'package:zamaj/modules/workout_overview/widgets/add_exercise_sheet.dart';
import 'package:zamaj/modules/workout_overview/widgets/drag_handle.dart';
import 'package:zamaj/modules/workout_overview/widgets/draggable_exercise.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';
import 'package:zamaj/modules/workout_overview/widgets/overview_drag_payload.dart';
import 'package:zamaj/modules/workout_overview/widgets/superset_card.dart';
import 'package:zamaj/modules/workout_overview/widgets/superset_drop_target.dart';
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
    required this.onEndOrSkip,
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

  /// The single adaptive terminal action (Skip exercise / End exercise).
  final void Function(ExerciseViewModel) onEndOrSkip;
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

  /// Opens the add-exercise sheet in "replace" mode for [exercise] — same
  /// two-step flow as Add, but headed `Replacing: <name>` and with the original
  /// excluded from its own dedup block-set (re-picking its own movement as the
  /// replacement is allowed). On confirm, dispatches the composed replace.
  Future<void> _onReplacePressed(
    BuildContext context,
    ExerciseViewModel exercise,
  ) async {
    final bloc = context.read<WorkoutOverviewBloc>();
    final id = exercise.sessionExercise.id;
    final plan = await AddExerciseSheet.show(
      context,
      session: state.sessionState.session,
      excludeSessionExerciseId: id,
      replacingName: exercise.displayName,
    );
    if (plan == null) return;
    bloc.add(
      WorkoutOverviewReplaceRequested(sessionExerciseId: id, plan: plan),
    );
  }

  /// Builds the tap-only Move up/down handler for [exerciseId] aimed at
  /// [target], or null when that direction is a no-op (so the menu disables
  /// it). Reuses the drag reorder path — the same event the reorder gaps
  /// dispatch — so no engine/resolver change is needed.
  VoidCallback? _moveHandler(
    BuildContext context,
    String exerciseId,
    DropTarget? target,
  ) {
    if (target == null) return null;
    return () {
      Haptics.tap();
      context.read<WorkoutOverviewBloc>().add(
        WorkoutOverviewDropResolved(
          draggedSessionExerciseId: exerciseId,
          target: target,
        ),
      );
    };
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
    final moveTargets = canMutate && isUnfinished
        ? ReorderMoveResolver.targetsFor(
            groups: state.groups,
            sessionExerciseId: exerciseId,
          )
        : MoveTargets.none;
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
        onEndOrSkipPressed: () => onEndOrSkip(exercise),
        onOpenVideo: onOpenVideo,
        onAddSetPressed: () {
          Haptics.tap();
          context.read<WorkoutOverviewBloc>().add(
            WorkoutOverviewExtraSetRequested(exerciseId),
          );
        },
        onResumePressed: () {
          Haptics.tap();
          context.read<WorkoutOverviewBloc>().add(
            WorkoutOverviewResumeRequested(exerciseId),
          );
        },
        onReplacePressed: () {
          Haptics.tap();
          _onReplacePressed(context, exercise);
        },
        onGroupIntoPressed: (candidates.isEmpty && eligibleGroups.isEmpty)
            ? null
            : () => onGroupInto(exercise, candidates, eligibleGroups),
        onMoveUp: _moveHandler(context, exerciseId, moveTargets.up),
        onMoveDown: _moveHandler(context, exerciseId, moveTargets.down),
        dragHandle: canDrag
            ? DragHandle(
                payload: ExerciseDragPayload(
                  sessionExerciseId: exerciseId,
                  supersetTag: exercise.sessionExercise.supersetTag,
                ),
                feedbackLabel: exercise.displayName,
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
        payload: ExerciseDragPayload(
          sessionExerciseId: member.sessionExercise.id,
          supersetTag: member.sessionExercise.supersetTag,
        ),
        feedbackLabel: member.displayName,
        autoScroller: autoScroller,
        dragSession: dragSession,
      );
    }

    // Per-member tap-only reorder: scoped to within-group swaps, mirroring the
    // intra-superset gaps. ReorderMoveResolver disables a direction at the
    // group's unfinished ends so a move can never break the group.
    ({VoidCallback? up, VoidCallback? down}) memberMove(
      ExerciseViewModel member,
    ) {
      if (!canMutate || member.sessionExercise.state is! UnfinishedState) {
        return (up: null, down: null);
      }
      final id = member.sessionExercise.id;
      final targets = ReorderMoveResolver.targetsFor(
        groups: state.groups,
        sessionExerciseId: id,
      );
      return (
        up: _moveHandler(context, id, targets.up),
        down: _moveHandler(context, id, targets.down),
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

    // Append-via-drag: an outside (ungrouped) exercise dropped anywhere on
    // the group joins it as a 3rd+ member. Gated on every member still being
    // unfinished — the engine refuses a group mixing terminal and live
    // members, same as the menu-driven "Group into superset" path. The anchor
    // is any unfinished member; the resolver only reads its tag.
    final allUnfinished = exercises.every(
      (e) => e.sessionExercise.state is UnfinishedState,
    );

    // The whole group can be dragged as one block only while the session is
    // live and every member is unfinished. Gated on the unit-tested eligibility
    // predicate (not canMutate) so the handle slot doesn't flicker during the
    // LOG-SET in-flight window — same reasoning as the per-member handle above.
    final canDragGroup = SupersetReorderResolver.isWholeDragEligible(
      groups: state.groups,
      supersetTag: tag,
      isEnded: state.isEnded,
    );
    final groupDragHandle = canDragGroup
        ? DragHandle(
            payload: SupersetDragPayload(
              tag: tag,
              memberIds: exercises.map((e) => e.sessionExercise.id).toList(),
            ),
            feedbackLabel: 'Superset (${exercises.length})',
            isGroup: true,
            semanticLabel: 'Drag superset',
            autoScroller: autoScroller,
            dragSession: dragSession,
          )
        : null;

    // Per-member "Remove from superset": offered on every member only when the
    // group is eligible (live, fully unfinished, 3+ members) per the shared
    // eligibility predicate — so the kebab item appears on all members or none,
    // and disappears the moment the group shrinks to two. Dispatches the bloc
    // event, which routes through the atomic engine extraction.
    final canRemoveMembers = SupersetRemoveEligibility.canRemoveFromGroup(
      group,
      canMutate: canMutate,
    );
    VoidCallback? memberRemove(ExerciseViewModel member) {
      if (!canRemoveMembers) return null;
      return () {
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewSupersetMemberRemoved(member.sessionExercise.id),
        );
      };
    }

    // Tap-only whole-group reorder for the header kebab. Resolves to the same
    // unfinished target indices the group drag uses (shared resolver), then
    // dispatches the whole-superset reorder event — disabled directions arrive
    // as null and the kebab greys them out.
    final groupMoveTargets = canMutate
        ? ReorderMoveResolver.supersetTargetsFor(
            groups: state.groups,
            supersetTag: tag,
          )
        : (up: null, down: null);
    VoidCallback? groupMoveHandler(int? targetIndex) {
      if (targetIndex == null) return null;
      return () {
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewSupersetReordered(
            supersetTag: tag,
            targetUnfinishedIndex: targetIndex,
          ),
        );
      };
    }

    final card = SupersetCard(
      tag: tag,
      exercises: exercises,
      expandedExerciseIds: state.expandedExerciseIds,
      canMutate: canMutate,
      currentSessionExerciseIds: currentSessionExerciseIds,
      lastTouchedSessionExerciseId: state.lastTouchedSessionExerciseId,
      groupDragHandle: groupDragHandle,
      onUngroupPressed: () => onUngroup(tag),
      onMoveUp: groupMoveHandler(groupMoveTargets.up),
      onMoveDown: groupMoveHandler(groupMoveTargets.down),
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
      onEndOrSkipPressed: (id) =>
          onEndOrSkip(exercises.firstWhere((e) => e.sessionExercise.id == id)),
      onOpenVideo: onOpenVideo,
      onAddSetPressed: (id) {
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewExtraSetRequested(id),
        );
      },
      onResumePressed: (id) {
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewResumeRequested(id),
        );
      },
      onReplacePressed: (id) {
        Haptics.tap();
        _onReplacePressed(
          context,
          exercises.firstWhere((e) => e.sessionExercise.id == id),
        );
      },
      memberDragHandleBuilder: memberDragHandle,
      memberMoveBuilder: memberMove,
      memberRemoveBuilder: memberRemove,
      gapBuilder: gapWrap,
    );

    return SupersetDropTarget(
      anchorSessionExerciseId: exercises.first.sessionExercise.id,
      canAccept: canMutate && allUnfinished,
      dragSession: dragSession,
      child: card,
    );
  }
}
