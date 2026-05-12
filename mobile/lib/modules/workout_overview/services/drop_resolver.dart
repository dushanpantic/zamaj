import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

abstract final class DropResolver {
  static DropIntent resolve({
    required String sessionId,
    required List<SupersetGroupViewModel> groups,
    required String draggedSessionExerciseId,
    required DropTarget target,
  }) {
    final unfinishedIds = _unfinishedIdsInOrder(groups);

    if (target is DropTargetOutside) return const DropIntent.noop();
    if (!unfinishedIds.contains(draggedSessionExerciseId)) {
      return const DropIntent.noop();
    }

    return switch (target) {
      DropTargetGap(:final unfinishedIndex) => _resolveGap(
        sessionId: sessionId,
        unfinishedIds: unfinishedIds,
        draggedId: draggedSessionExerciseId,
        index: unfinishedIndex,
      ),
      DropTargetExercise(:final sessionExerciseId) => _resolveOnto(
        sessionId: sessionId,
        groups: groups,
        draggedId: draggedSessionExerciseId,
        targetId: sessionExerciseId,
      ),
      DropTargetOutside() => const DropIntent.noop(),
    };
  }

  static DropIntent _resolveGap({
    required String sessionId,
    required List<String> unfinishedIds,
    required String draggedId,
    required int index,
  }) {
    final draggedIndex = unfinishedIds.indexOf(draggedId);
    final without = List<String>.of(unfinishedIds)..remove(draggedId);
    final clampedTarget = index.clamp(0, unfinishedIds.length);
    final insertion = clampedTarget > draggedIndex
        ? clampedTarget - 1
        : clampedTarget;
    final reordered = List<String>.of(without)..insert(insertion, draggedId);
    if (_listEquals(reordered, unfinishedIds)) return const DropIntent.noop();
    return DropIntent.reorder(
      sessionId: sessionId,
      orderedUnfinishedIds: reordered,
    );
  }

  static DropIntent _resolveOnto({
    required String sessionId,
    required List<SupersetGroupViewModel> groups,
    required String draggedId,
    required String targetId,
  }) {
    if (draggedId == targetId) return const DropIntent.noop();

    final draggedTag = _supersetTagFor(groups, draggedId);
    final targetTag = _supersetTagFor(groups, targetId);

    if (draggedTag != null && draggedTag == targetTag) {
      return const DropIntent.noop();
    }
    if (draggedTag != null && draggedTag != targetTag) {
      return const DropIntent.noop();
    }

    final targetIsUnfinished = _isUnfinished(groups, targetId);
    if (!targetIsUnfinished) return const DropIntent.noop();

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
      for (final ex in g.exercises) {
        if (ex.sessionExercise.state is UnfinishedState) {
          ids.add(ex.sessionExercise.id);
        }
      }
    }
    return ids;
  }

  static String? _supersetTagFor(
    List<SupersetGroupViewModel> groups,
    String sessionExerciseId,
  ) {
    for (final g in groups) {
      for (final ex in g.exercises) {
        if (ex.sessionExercise.id == sessionExerciseId) {
          return ex.sessionExercise.supersetTag;
        }
      }
    }
    return null;
  }

  static bool _isUnfinished(
    List<SupersetGroupViewModel> groups,
    String sessionExerciseId,
  ) {
    for (final g in groups) {
      for (final ex in g.exercises) {
        if (ex.sessionExercise.id == sessionExerciseId) {
          return ex.sessionExercise.state is UnfinishedState;
        }
      }
    }
    return false;
  }

  static bool _listEquals(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
