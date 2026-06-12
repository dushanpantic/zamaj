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
  /// The block is anchored at the earliest chosen member's slot in [allIds] and
  /// ordered exactly as [chosenIds] is given; every other id keeps its relative
  /// order around the block.
  static List<String> blockedOrderForCreate({
    required List<String> allIds,
    required List<String> chosenIds,
  }) {
    final chosen = chosenIds.toSet();
    final anchorIndex = allIds.indexWhere(chosen.contains);
    final remaining = allIds.where((id) => !chosen.contains(id)).toList();
    return [
      ...remaining.take(anchorIndex),
      ...chosenIds,
      ...remaining.skip(anchorIndex),
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
