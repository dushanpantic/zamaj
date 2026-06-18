import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

/// Move-up / move-down drop targets for one exercise, resolved against the
/// assembled overview [groups].
class MoveTargets {
  const MoveTargets({this.up, this.down});

  /// Where a "Move up" tap should drop the exercise, or null when up is a
  /// no-op (already at the top of its reorder scope) and the action should be
  /// disabled.
  final DropTarget? up;

  /// Where a "Move down" tap should drop the exercise, or null when down is a
  /// no-op (already at the bottom of its reorder scope).
  final DropTarget? down;

  static const MoveTargets none = MoveTargets();
}

/// Pure resolver for the tap-only "Move up" / "Move down" fallback. Given the
/// assembled [SupersetGroupViewModel] list and a target exercise, it computes
/// the [DropTarget.beforeIndex] each direction should dispatch — the *same*
/// drop-target path the drag reorder gaps use, so it flows through
/// [DropResolver] and `reorderUnfinished` with no engine changes.
///
/// Scope mirrors the drag affordances exactly:
///
/// - A **standalone** exercise moves relative to whole top-level groups,
///   jumping over an entire superset rather than landing inside it (which
///   would split the group). Finished neighbours are skipped — they are fixed
///   anchors that don't participate in the unfinished reorder sequence.
/// - A **superset member** moves only within its own group, swapping with the
///   adjacent unfinished member; it can never escape the group.
///
/// A null direction means the move would be a no-op (the exercise is already
/// at that end of its scope), and the caller should disable that direction.
abstract final class ReorderMoveResolver {
  static MoveTargets targetsFor({
    required List<SupersetGroupViewModel> groups,
    required String sessionExerciseId,
  }) {
    // Locate the exercise and its enclosing group.
    var groupIndex = -1;
    SupersetGroupViewModel? group;
    for (var i = 0; i < groups.length; i++) {
      final contains = groups[i].allExercises.any(
        (e) => e.sessionExercise.id == sessionExerciseId,
      );
      if (contains) {
        groupIndex = i;
        group = groups[i];
        break;
      }
    }
    if (group == null) return MoveTargets.none;

    final target = group.allExercises.firstWhere(
      (e) => e.sessionExercise.id == sessionExerciseId,
    );
    // Only unfinished exercises participate in `reorderUnfinished`.
    if (target.sessionExercise.state is! UnfinishedState) {
      return MoveTargets.none;
    }

    return switch (group) {
      SingleGroupViewModel() => _standaloneTargets(groups, groupIndex),
      SupersetGroup(:final exercises) => _memberTargets(
        exercises,
        groups,
        sessionExerciseId,
      ),
    };
  }

  /// Move up / move down **target unfinished indices** for the whole superset
  /// [supersetTag], moved as one block relative to whole top-level groups
  /// (jumping over an entire neighbouring group, skipping all-finished anchors
  /// just like [_standaloneTargets]). A null direction is a disabled end.
  ///
  /// Returns `(up: null, down: null)` when the tag is unknown or the group
  /// isn't fully unfinished — only a fully-unfinished superset moves as a
  /// whole, mirroring [SupersetReorderResolver.isWholeDragEligible]. The
  /// indices are in the pre-move unfinished coordinate space the drag gaps use,
  /// so dispatching `WorkoutOverviewSupersetReordered(tag, index)` lands the
  /// group identically to dropping it into that gap.
  static ({int? up, int? down}) supersetTargetsFor({
    required List<SupersetGroupViewModel> groups,
    required String supersetTag,
  }) {
    var groupIndex = -1;
    SupersetGroup? group;
    for (var i = 0; i < groups.length; i++) {
      final g = groups[i];
      if (g is SupersetGroup && g.tag == supersetTag) {
        groupIndex = i;
        group = g;
        break;
      }
    }
    if (group == null) return (up: null, down: null);
    final allUnfinished = group.exercises.every(
      (e) => e.sessionExercise.state is UnfinishedState,
    );
    if (!allUnfinished) return (up: null, down: null);

    int? up;
    int? down;
    // Up: drop the block just before the nearest group above with at least one
    // unfinished exercise (all-finished groups are skipped anchors).
    for (var i = groupIndex - 1; i >= 0; i--) {
      if (_unfinishedInGroup(groups[i]) > 0) {
        up = _unfinishedBeforeGroup(groups, i);
        break;
      }
    }
    // Down: drop the block just after the nearest group below with an
    // unfinished exercise — before the first unfinished slot past that group.
    for (var i = groupIndex + 1; i < groups.length; i++) {
      final inGroup = _unfinishedInGroup(groups[i]);
      if (inGroup > 0) {
        down = _unfinishedBeforeGroup(groups, i) + inGroup;
        break;
      }
    }
    return (up: up, down: down);
  }

  /// Number of unfinished exercises in `groups[0 .. groupIndex - 1]`.
  static int _unfinishedBeforeGroup(
    List<SupersetGroupViewModel> groups,
    int groupIndex,
  ) {
    var count = 0;
    for (var i = 0; i < groupIndex; i++) {
      count += _unfinishedInGroup(groups[i]);
    }
    return count;
  }

  static int _unfinishedInGroup(SupersetGroupViewModel group) => group
      .allExercises
      .where((e) => e.sessionExercise.state is UnfinishedState)
      .length;

  static MoveTargets _standaloneTargets(
    List<SupersetGroupViewModel> groups,
    int groupIndex,
  ) {
    DropTarget? up;
    DropTarget? down;

    // Move up: drop just before the nearest group above that holds at least
    // one unfinished exercise (all-finished groups are skipped anchors).
    for (var i = groupIndex - 1; i >= 0; i--) {
      if (_unfinishedInGroup(groups[i]) > 0) {
        up = DropTarget.beforeIndex(_unfinishedBeforeGroup(groups, i));
        break;
      }
    }

    // Move down: drop just after the nearest group below with an unfinished
    // exercise — i.e. before the first unfinished slot past that whole group.
    for (var i = groupIndex + 1; i < groups.length; i++) {
      final inGroup = _unfinishedInGroup(groups[i]);
      if (inGroup > 0) {
        down = DropTarget.beforeIndex(
          _unfinishedBeforeGroup(groups, i) + inGroup,
        );
        break;
      }
    }

    return MoveTargets(up: up, down: down);
  }

  static MoveTargets _memberTargets(
    List<ExerciseViewModel> members,
    List<SupersetGroupViewModel> groups,
    String sessionExerciseId,
  ) {
    // Absolute unfinished index of every exercise across all groups — the
    // coordinate space `reorderUnfinished` (and DropTarget.beforeIndex) uses.
    final unfinishedIndexById = <String, int>{};
    var counter = 0;
    for (final g in groups) {
      for (final e in g.allExercises) {
        if (e.sessionExercise.state is UnfinishedState) {
          unfinishedIndexById[e.sessionExercise.id] = counter++;
        }
      }
    }

    // Unfinished members of this group, in order — the within-group scope.
    final unfinishedMemberIds = members
        .where((e) => e.sessionExercise.state is UnfinishedState)
        .map((e) => e.sessionExercise.id)
        .toList();
    final pos = unfinishedMemberIds.indexOf(sessionExerciseId);
    if (pos < 0) return MoveTargets.none;

    DropTarget? up;
    DropTarget? down;
    if (pos > 0) {
      final prevId = unfinishedMemberIds[pos - 1];
      up = DropTarget.beforeIndex(unfinishedIndexById[prevId]!);
    }
    if (pos < unfinishedMemberIds.length - 1) {
      final nextId = unfinishedMemberIds[pos + 1];
      // Land immediately after the next member — still inside the contiguous
      // same-tag run, so the group stays intact.
      down = DropTarget.beforeIndex(unfinishedIndexById[nextId]! + 1);
    }

    return MoveTargets(up: up, down: down);
  }
}
