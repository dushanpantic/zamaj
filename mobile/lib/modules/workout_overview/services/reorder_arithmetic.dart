import 'package:flutter/foundation.dart';

/// Shared "remove ids → insert the block at the adjusted gap → no-op if
/// unchanged" arithmetic used by both the single-exercise drag ([DropResolver])
/// and the whole-superset drag ([SupersetReorderResolver]).
///
/// Both move a contiguous block out of the unfinished id sequence and reinsert
/// it at a gap expressed in the *original* sequence's coordinate space, so the
/// insertion point must be shifted left by however many block ids sat before
/// the gap (the self-removal shift). Keeping the math in one place means a
/// regression can't fix one caller while silently breaking the other.
abstract final class ReorderArithmetic {
  /// Moves [block] (ids already present in [unfinishedIds], reinserted in the
  /// given order) so it lands at [targetIndex] in the gap coordinate space of
  /// the original [unfinishedIds]. Returns the resulting order, or null when it
  /// equals [unfinishedIds] — a no-op drop (e.g. a self-adjacent gap).
  static List<String>? reorderBlock({
    required List<String> unfinishedIds,
    required List<String> block,
    required int targetIndex,
  }) {
    final blockSet = block.toSet();
    final without = unfinishedIds
        .where((id) => !blockSet.contains(id))
        .toList();
    final clampedTarget = targetIndex.clamp(0, unfinishedIds.length);
    var removedBefore = 0;
    for (var i = 0; i < clampedTarget && i < unfinishedIds.length; i++) {
      if (blockSet.contains(unfinishedIds[i])) removedBefore++;
    }
    final insertion = clampedTarget - removedBefore;
    final reordered = List<String>.of(without)..insertAll(insertion, block);
    if (listEquals(reordered, unfinishedIds)) return null;
    return reordered;
  }
}
