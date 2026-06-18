/// Pure ordering math for live-session superset edits.
///
/// The Drift session repository owns the two-phase, UNIQUE-dodging position
/// writes; this service owns only the *target order* those writes realise.
/// Keeping the ordering here makes it testable without a database and states
/// the contiguity rule the overview/focus assemblers depend on (a superset is
/// rendered only from a contiguous run of same-tag rows) in one place.
abstract final class SupersetOrdering {
  /// The id order after grouping [chosenIds] into one contiguous block.
  ///
  /// The block is anchored at [anchorId]'s slot — the drop target. The reorder
  /// resolver and the "Group into superset" picker both place the drop target
  /// last in [chosenIds], so callers pass `anchorId: chosenIds.last`. Anchoring
  /// at the target (rather than at the earliest chosen member) is what makes a
  /// new group land where the lifter dropped it.
  ///
  /// "Anchored at [anchorId]'s slot" means the block is inserted among the
  /// non-member ids at the count of non-members that precede [anchorId] in
  /// [allIds]: non-members above the target stay above the new group, those
  /// below stay below. The block is ordered exactly as [chosenIds] is given
  /// (preserving the caller's dragged-then-target order) and every non-member
  /// keeps its relative order. [anchorId] must be one of [chosenIds].
  static List<String> blockedOrderForCreate({
    required List<String> allIds,
    required List<String> chosenIds,
    required String anchorId,
  }) {
    if (!chosenIds.contains(anchorId)) {
      throw ArgumentError.value(
        anchorId,
        'anchorId',
        'must be one of chosenIds',
      );
    }
    final chosen = chosenIds.toSet();
    final remaining = <String>[];
    var nonMembersBeforeAnchor = 0;
    var seenAnchor = false;
    for (final id in allIds) {
      if (id == anchorId) {
        seenAnchor = true;
        continue;
      }
      if (chosen.contains(id)) continue;
      remaining.add(id);
      if (!seenAnchor) nonMembersBeforeAnchor++;
    }
    return [
      ...remaining.take(nonMembersBeforeAnchor),
      ...chosenIds,
      ...remaining.skip(nonMembersBeforeAnchor),
    ];
  }

  /// The unfinished id order after appending [draggedId] to a superset.
  ///
  /// [draggedId] is extracted from [unfinishedIds] and reinserted immediately
  /// after the last existing [memberIds] entry, so the run stays contiguous.
  static List<String> orderForAppend({
    required List<String> unfinishedIds,
    required List<String> memberIds,
    required String draggedId,
  }) {
    final result = List<String>.of(unfinishedIds)..remove(draggedId);
    final insertAfter = result.indexOf(memberIds.last);
    result.insert(insertAfter + 1, draggedId);
    return result;
  }
}
