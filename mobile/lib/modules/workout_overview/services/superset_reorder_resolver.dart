import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/reorder_arithmetic.dart';

/// Pure resolver for reordering a *whole* superset as one contiguous block,
/// plus the eligibility predicate that gates the drag handle and the Move
/// up/down actions.
///
/// A group move is just an ordinary permutation of the unfinished id sequence,
/// so it routes through the existing `reorderUnfinished` engine path with no
/// new engine method or schema change — exactly like a single-exercise drag.
/// The block keeps its member order and its shared tag; finished exercises are
/// fixed anchors that never enter the unfinished sequence and so keep their
/// absolute slots.
abstract final class SupersetReorderResolver {
  /// Resolves dropping the whole superset [supersetTag] into the between-group
  /// gap [targetUnfinishedIndex] (the same `unfinishedIndex` coordinate space
  /// the drag gaps and [DropTarget.beforeIndex] use) into a [DropIntent].
  ///
  /// No-ops when the tag is unknown/stale, the group isn't fully unfinished, or
  /// the drop leaves the order unchanged (a self-adjacent gap).
  static DropIntent resolve({
    required String sessionId,
    required List<SupersetGroupViewModel> groups,
    required String supersetTag,
    required int targetUnfinishedIndex,
  }) {
    final group = _supersetWithTag(groups, supersetTag);
    if (group == null || !_allUnfinished(group)) {
      return const DropIntent.noop();
    }

    final memberIds = group.exercises.map((e) => e.sessionExercise.id).toList();
    final reordered = ReorderArithmetic.reorderBlock(
      unfinishedIds: _unfinishedIdsInOrder(groups),
      block: memberIds,
      targetIndex: targetUnfinishedIndex,
    );
    if (reordered == null) return const DropIntent.noop();
    return DropIntent.reorder(
      sessionId: sessionId,
      orderedUnfinishedIds: reordered,
    );
  }

  /// Whether [supersetTag]'s group can be dragged or moved as a whole: the
  /// session is live ([isEnded] false), the tagged superset still exists, and
  /// every member is unfinished. The widget layer hides the handle and the
  /// Move actions when this is false; keeping the gate here makes the
  /// "no handle on a finished member / ended session" guarantee unit-testable.
  static bool isWholeDragEligible({
    required List<SupersetGroupViewModel> groups,
    required String supersetTag,
    required bool isEnded,
  }) {
    if (isEnded) return false;
    final group = _supersetWithTag(groups, supersetTag);
    return group != null && _allUnfinished(group);
  }

  static SupersetGroup? _supersetWithTag(
    List<SupersetGroupViewModel> groups,
    String tag,
  ) {
    for (final g in groups) {
      if (g is SupersetGroup && g.tag == tag) return g;
    }
    return null;
  }

  static bool _allUnfinished(SupersetGroup group) =>
      group.exercises.every((e) => e.sessionExercise.state is UnfinishedState);

  static List<String> _unfinishedIdsInOrder(
    List<SupersetGroupViewModel> groups,
  ) {
    final ids = <String>[];
    for (final g in groups) {
      for (final ex in g.allExercises) {
        if (ex.sessionExercise.state is UnfinishedState) {
          ids.add(ex.sessionExercise.id);
        }
      }
    }
    return ids;
  }
}
