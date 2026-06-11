import 'package:flutter/foundation.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

/// Pure resolver that turns a (drag origin, drop target) pair into a typed
/// [DropIntent].
///
/// Callers (the workout-overview bloc) translate the resolved intent into a
/// concrete [SessionFlowEngine] mutation. The resolver itself is stateless,
/// side-effect-free, and tested in isolation with the property suite under
/// `test/modules/workout_overview/services/`.
abstract final class DropResolver {
  static DropIntent resolve({
    required String sessionId,
    required List<SupersetGroupViewModel> groups,
    required String draggedSessionExerciseId,
    required DropTarget target,
  }) {
    final byId = <String, ExerciseViewModel>{
      for (final g in groups)
        for (final ex in g.allExercises) ex.sessionExercise.id: ex,
    };

    if (!byId.containsKey(draggedSessionExerciseId)) {
      return const DropIntent.noop();
    }
    final dragged = byId[draggedSessionExerciseId]!.sessionExercise;
    if (dragged.state is! UnfinishedState) {
      return const DropIntent.noop();
    }

    return switch (target) {
      DropTargetOutside() => const DropIntent.noop(),
      DropTargetGap(:final unfinishedIndex) => _resolveGap(
        sessionId: sessionId,
        unfinishedIds: _unfinishedIdsInOrder(groups),
        draggedId: draggedSessionExerciseId,
        index: unfinishedIndex,
      ),
      DropTargetExercise(:final sessionExerciseId) => _resolveOnto(
        sessionId: sessionId,
        byId: byId,
        draggedId: draggedSessionExerciseId,
        targetId: sessionExerciseId,
      ),
    };
  }

  /// Reorder algorithm: remove dragged from the unfinished sequence, then
  /// insert at the requested gap, adjusting for the self-removal shift so
  /// drag-to-end / drag-to-self produce stable orderings.
  static DropIntent _resolveGap({
    required String sessionId,
    required List<String> unfinishedIds,
    required String draggedId,
    required int index,
  }) {
    final draggedIndex = unfinishedIds.indexOf(draggedId);
    final without = List<String>.of(unfinishedIds)..removeAt(draggedIndex);
    final clampedTarget = index.clamp(0, unfinishedIds.length);
    final insertion = clampedTarget > draggedIndex
        ? clampedTarget - 1
        : clampedTarget;
    final reordered = List<String>.of(without)..insert(insertion, draggedId);
    if (listEquals(reordered, unfinishedIds)) return const DropIntent.noop();
    return DropIntent.reorder(
      sessionId: sessionId,
      orderedUnfinishedIds: reordered,
    );
  }

  /// "Drop onto" semantics. Three sub-cases for a dragged unfinished,
  /// ungrouped exercise:
  ///
  /// - target is unfinished and ungrouped → pair them into a new superset.
  /// - target is unfinished and already in a superset → append the dragged
  ///   exercise to that existing group (P2.3). The whole existing group must
  ///   still be unfinished — the engine re-asserts.
  /// - any other shape (target locked, dragged already grouped, drop on
  ///   self) → noop. There is no drag-to-ungroup: a drop whose dragged
  ///   exercise already carries a `supersetTag` is rejected here, and the
  ///   header ungroup button is the only affordance for leaving a superset.
  static DropIntent _resolveOnto({
    required String sessionId,
    required Map<String, ExerciseViewModel> byId,
    required String draggedId,
    required String targetId,
  }) {
    if (draggedId == targetId) return const DropIntent.noop();

    final dragged = byId[draggedId]!.sessionExercise;
    final target = byId[targetId]?.sessionExercise;
    if (target == null) return const DropIntent.noop();

    if (dragged.supersetTag != null) return const DropIntent.noop();
    if (target.state is! UnfinishedState) return const DropIntent.noop();

    final targetTag = target.supersetTag;
    if (targetTag != null) {
      return DropIntent.appendToSuperset(
        sessionId: sessionId,
        supersetTag: targetTag,
        sessionExerciseId: draggedId,
      );
    }

    return DropIntent.createSuperset(
      sessionId: sessionId,
      sessionExerciseIds: [draggedId, targetId],
    );
  }

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
