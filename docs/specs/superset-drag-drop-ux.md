# Spec: Superset Drag-and-Drop UX (Workout Overview)

## Intent Description

The live workout-overview screen lets a lifter reorder exercises and group them
into supersets by drag-and-drop, with a tap-only **Move up / Move down**
fallback for sweaty hands. Two behaviors don't match expectation:

1. **A new superset lands in the wrong place.** Forming a superset by dragging
   one card onto another (or via the "Group into superset" picker) places the
   new group at the *earliest* of the two exercises' positions, regardless of
   which card was the drop target. Given `A · [X,Y] · B`, dragging the upper
   card **A** down onto **B** produces `[A,B] · [X,Y]` — the group stays at the
   top — when the lifter expects `[X,Y] · [A,B]`, i.e. the new group appearing
   where the **drop target** sits. (Dragging **B** up onto **A** already lands
   correctly, but only incidentally, because **A** was already the topmost.)
   The expected rule: the new superset occupies the **drop target's** slot, with
   member order **dragged-then-target**.

2. **A superset can't be moved as a unit.** There is no affordance to reorder a
   whole superset relative to the other groups. The only workaround is to
   ungroup it and rebuild it in the desired spot by moving its members one at a
   time. The lifter expects to drag the whole group to a new position and —
   mirroring the existing per-exercise fallback — to move it with a tap-only
   **Move up / Move down**.

This change corrects the placement rule (1) and adds whole-superset reordering
(2). It does **not** change how supersets are created, appended to, ungrouped,
logged, or run in focus mode. Per the decisions taken during specification:
dragging a whole superset only **reorders** it (dropping a superset onto another
card or another superset is a no-op — no merging or nesting); whole-superset
moves gain a tap-only Move up/Move down; and dragging a single member *out* of a
superset (extraction) is **out of scope** — Ungroup remains the only way to
leave a group. Scope is confined to the workout-overview in-session surface; the
frozen session snapshot, separate planned/actual tracking, and immutability
rules are untouched.

## Architecture Specification

### Layer & module placement
All work lives under `mobile/lib/modules/workout_overview/` except the
placement-rule fix, which lives in `mobile/lib/modules/domain/`. No persistence
schema or migration change. No new networking. Domain stays pure Dart.

### Change 1 — new-superset placement at the drop target

- **Owner of the rule:** `domain/services/superset_ordering.dart` →
  `SupersetOrdering.blockedOrderForCreate`. Today it anchors the contiguous
  block at `allIds.indexWhere(chosen.contains)` (the *earliest* chosen member).
  It must instead anchor at the **drop target's** original slot, while keeping
  the block's internal order equal to the provided `chosenIds`
  (dragged-then-target). Every non-member keeps its relative order around the
  block.
- **Threading the target identity:** the target is currently implicit. The
  drop/menu paths already pass `chosenIds = [draggedId, targetId]`
  (`DropResolver._resolveOnto`, `_handleGroupInto`). The anchor must be derived
  from the **target** (the second/last element today). `/plan` decides the exact
  mechanism — an explicit `anchorId` parameter threaded through
  `SessionFlowEngine.createSuperset`, `DriftSessionRepository.createSuperset`,
  and `CreateSupersetIntent`, **or** a documented "anchor = target = last chosen
  id" contract on `blockedOrderForCreate`. Either way the resolved order is
  realised by the repo's existing two-phase position write; **no engine grouping
  semantics, no `reorderUnfinished`, no DB constraint handling changes.**
- **Both entry points fixed at once:** drag-onto-card and the picker route
  through `createSuperset`, so fixing the ordering rule corrects both.
- **Append is unaffected:** `orderForAppend` (dragging an ungrouped exercise
  onto an existing superset) keeps its current behavior — the group stays in
  place and the new member lands after the last member.

### Change 2 — whole-superset reordering

Reuses the existing reorder pipeline; the whole-group move is expressed as an
ordinary permutation of unfinished ids, so **no `SessionFlowEngine` /
repository / schema change is required** for the reorder itself.

- **Drag source:** a drag handle on the `SupersetCard` header
  (`widgets/superset_card.dart`, wired in
  `WorkoutGroupBuilder._buildSuperset`), consistent with the per-exercise
  `DragHandle`. Carries a **group-scoped drag payload** (superset tag +
  ordered unfinished member ids) distinct from the per-exercise
  `ExerciseDragPayload`. Eligible only while the session is live and **every**
  member is unfinished (mirrors the existing all-unfinished gate; a group with a
  finished member is a fixed anchor and is not draggable as a whole).
- **Drop target:** the existing between-group `ReorderGap`
  (`widgets/reorder_gap.dart`) accepts the group payload. The intra-superset
  member gaps (`SupersetReorderGap`) and the per-card / per-group "form/append a
  superset" targets (`DraggableExercise`, `SupersetDropTarget`) **reject** the
  group payload — so dropping a superset onto another group is a **no-op**
  (decision: reorder-only).
- **Resolver:** `services/drop_resolver.dart` gains a path that maps
  `(group payload, gap)` to a `ReorderIntent` whose `orderedUnfinishedIds`
  removes the group's member ids and re-inserts them as a **contiguous block** at
  the gap, preserving internal order and every other exercise's relative order.
  Must apply the same self-removal index shift `_resolveGap` already uses, so a
  drop into a gap adjacent to the group's current position is a no-op rather than
  an off-by-one. Contiguity preservation keeps `groupBySupersetRun` rendering the
  block as one superset (tag unchanged).
- **Tap-only fallback:** `services/reorder_move_resolver.dart` gains
  whole-superset Move up / Move down targets — the group jumps the nearest
  unfinished group above/below (mirroring `_standaloneTargets`, all-finished
  groups skipped as anchors; a direction is `null`/disabled at the ends). The
  `SupersetCard` header surfaces these as a menu (the per-member cards already
  carry their own within-group Move up/down; this is the new group-level one).
  Both the drag drop and the menu dispatch through the bloc to the same
  group-reorder path.
- **Bloc:** `WorkoutOverviewBloc` handles the group reorder by resolving to the
  existing `ReorderIntent` and calling `reorderUnfinished` (a new event or an
  extension of `WorkoutOverviewDropResolved` carrying the group payload/target —
  `/plan`'s call). The existing `_runMutation` in-flight guard and
  optimistic-state handling are reused unchanged.

### Cross-cutting constraints (must hold)
- **UI ↔ data only via domain contracts.** No `drift`/`AppDatabase` references
  in `workout_overview`. The new resolver/move logic stays in pure, unit-tested
  services (`DropResolver`, `ReorderMoveResolver`, `SupersetOrdering`).
- **Sweaty-hands ergonomics** (`workout_overview/` rule): the superset-header
  drag handle and its Move up/down menu trigger meet the in-session tap-target
  floor (handle ≥ the existing `kExerciseLeadingSlotWidth`; menu items
  comfortably tappable). No hard-coded pixels/colors — use `AppSpacing`,
  `AppRadius`, `appColors`, `AppTypography`.
- **Finished/locked exercises stay fixed.** All new ordering operates over the
  unfinished sequence only; terminal exercises keep their slots, exactly as the
  current reorder/create do.
- **Ended-session lock** unchanged: no structural drag/move when the session has
  ended (`canMutate`/`canLog` already gate this).
- **Docs:** the workout-overview bullet in
  [product-context.md](../../product-context.md) is updated in the same change
  to mention reordering a whole superset (the screen's feature set shifts).

### Out of scope (explicit)
- Merging or nesting supersets via whole-group drag.
- Dragging a single member out of a superset (extraction). Ungroup stays the
  only way to leave a group.
- Any change to focus mode, session export, the day-editor superset builder, or
  the frozen-snapshot/immutability rules.

## Acceptance Criteria

### A. New-superset placement (Change 1)
- **A1 — drop-target anchoring.** Given groups rendered top-to-bottom as
  `A · [X,Y] · B` (all unfinished), dragging **A onto B** yields
  `[X,Y] · [A,B]` (new group at B's slot, member order A then B). PASS only if
  the new superset occupies the drop target's position. FAIL if it stays at A's
  slot.
- **A2 — symmetric case still correct.** From the same start, dragging
  **B onto A** yields `[B,A] · [X,Y]` (group at A's slot, order B then A).
- **A3 — order is dragged-then-target.** In every create case the new group's
  member order is `[dragged, target]`, independent of their prior top/bottom
  positions.
- **A4 — picker parity.** Forming the same pairing through the "Group into
  superset" picker (source = dragged, picked = target) produces the identical
  placement and order as the equivalent drag.
- **A5 — non-members preserved.** Exercises not in the new group keep their
  relative order; finished/terminal exercises keep their absolute slots.
- **A6 — append unchanged.** Dragging an ungrouped exercise onto an existing
  superset still appends it after the last member and leaves the group's
  position unchanged.

### B. Whole-superset drag reorder (Change 2)
- **B1 — handle present & gated.** A fully-unfinished superset shows a header
  drag handle while the session is live; a superset with any finished member, or
  an ended session, shows no whole-group drag handle.
- **B2 — reorder via gap.** Dragging a whole superset onto a between-group gap
  moves all its members as one contiguous block to that position; internal
  member order and the superset tag are preserved, and it still renders as one
  superset afterward.
- **B3 — others preserved.** All non-dragged groups (standalone and superset)
  keep their relative order; finished exercises keep their slots.
- **B4 — no-op on self-adjacent gap.** Dropping the group into the gap
  immediately above or below its current position produces no change (no
  off-by-one shuffle).
- **B5 — drop-on-group is a no-op.** Dragging a superset onto a standalone card
  or another superset makes no structural change (no merge, no nesting); those
  targets do not highlight as acceptors for a group payload.
- **B6 — member reorder unaffected.** The intra-superset member drag/gaps and a
  standalone card's "form/append superset" drops still behave exactly as before
  (the group payload is rejected by those targets; the per-exercise payload by
  the gap-group path).

### C. Whole-superset Move up/down fallback (Change 2)
- **C1 — menu present.** A fully-unfinished superset header exposes Move up /
  Move down actions.
- **C2 — jumps whole groups.** Move up places the superset immediately above the
  nearest group above that contains an unfinished exercise; Move down places it
  immediately below the nearest such group below. All-finished groups are
  skipped as fixed anchors.
- **C3 — ends disabled.** Move up is disabled/absent when the superset is already
  the topmost movable group; Move down when it is the bottommost.
- **C4 — equivalence with drag.** A Move up/down lands the group in the same
  position the equivalent gap drag would.

### D. Non-regression & quality
- **D1 — pure-service tests.** `SupersetOrdering`, `DropResolver`, and
  `ReorderMoveResolver` changes are covered by unit/property tests under
  `test/`; existing `superset_ordering_test.dart` expectations are updated to the
  new anchoring rule (the three current cases assert earliest-anchor and must be
  rewritten to target-anchor).
- **D2 — engine/repo untouched for reorder.** Whole-group reorder dispatches the
  existing `reorderUnfinished`; no new engine grouping method and no schema
  migration are introduced.
- **D3 — ergonomics & tokens.** New controls obey the workout-overview
  sweaty-hands tap-target floor and use design tokens (no literal px/colors).
- **D4 — `tool/ci.sh` green** (offline-imports guard, codegen, format, analyze,
  test).
- **D5 — product-context.md** workout-overview bullet updated to reflect
  whole-superset reordering.

## Consistency Gate
- [x] Intent is unambiguous — placement rule (anchor at drop target,
  order dragged-then-target) and whole-group reorder (drag-to-gap + Move up/down,
  reorder-only) are stated with worked examples and explicit out-of-scope items.
- [x] Every behavior/goal maps to an acceptance criterion — placement → A1–A6;
  whole-group drag → B1–B6; tap fallback → C1–C4; non-regression/docs → D1–D5.
- [x] Architecture constrains without over-engineering — reuses
  `reorderUnfinished` and `ReorderIntent` for the group move (no new engine/DB
  work); localizes the placement fix to `SupersetOrdering`; defers merging and
  member extraction.
- [x] Terminology consistent across artifacts — "drop target", "dragged",
  "superset", "contiguous block", "unfinished", "Move up/down", "no-op" used
  uniformly.
- [x] No contradictions between artifacts — reorder-only / no-merge / no
  extraction held consistently in intent, architecture, and B5/out-of-scope.
