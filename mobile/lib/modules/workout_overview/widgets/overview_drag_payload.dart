/// Sealed payload carried by every workout-overview drag.
///
/// Each overview drop zone is a single `DragTarget<OverviewDragPayload>` that
/// branches on the variant in `onWillAcceptWithDetails` — one discrimination
/// idiom across all targets, with no two type-scoped `DragTarget`s competing
/// at the same hit-test offset. The accept/reject branches stay explicit and
/// exhaustive because the union is sealed.
sealed class OverviewDragPayload {
  const OverviewDragPayload();
}

/// A single exercise dragged by its per-card handle.
///
/// [supersetTag] is the dragged exercise's current `supersetTag`. Drop targets
/// gate on it: main-list reorder gaps and onto-card targets accept only
/// payloads with `supersetTag == null`, while reorder gaps inside a superset
/// accept only payloads whose `supersetTag` matches the group. This keeps
/// within-superset reordering contiguous and prevents accidental breakage of
/// an existing group.
final class ExerciseDragPayload extends OverviewDragPayload {
  const ExerciseDragPayload({
    required this.sessionExerciseId,
    required this.supersetTag,
  });
  final String sessionExerciseId;
  final String? supersetTag;
}

/// A whole superset dragged by its header handle.
///
/// Carries the group [tag] and its ordered unfinished [memberIds]. Only the
/// between-group reorder gap accepts it (dispatching a whole-superset reorder);
/// every other target rejects it, leaving member reorder and onto-card grouping
/// to the [ExerciseDragPayload] path.
final class SupersetDragPayload extends OverviewDragPayload {
  const SupersetDragPayload({required this.tag, required this.memberIds});
  final String tag;
  final List<String> memberIds;
}
