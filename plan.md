# Workout overview UX improvement plan

## Why

Two real-world failures from a live session:

1. **Supersets are undiscoverable.** The only way to combine two exercises into a superset on this screen is to long-press a card and drag it onto another card. There is no menu item, no labelled button, no hint. In the gym, you couldn't find it.
2. **No auto-scroll while dragging.** When you long-press to reorder, dragging near the top/bottom edge of the screen does *nothing* — the list does not scroll. You had to use a second hand. This directly violates the "sweaty-hands ergonomics" pillar of the app.

Everything below addresses these two and a handful of related issues uncovered during the analysis.

## Analysis: what the screen does today

Relevant files:

- [workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart) — hosts the list, the drag/drop wiring, the action bar.
- [exercise_card.dart](mobile/lib/modules/workout_overview/widgets/exercise_card.dart) — `_Actions` builds the per-card ⋮ menu.
- [superset_card.dart](mobile/lib/modules/workout_overview/widgets/superset_card.dart) — wraps a contiguous superset run; has an "Ungroup" button.
- [drop_resolver.dart](mobile/lib/modules/workout_overview/services/drop_resolver.dart) — pure resolver that turns (drag origin, drop target) into a [`DropIntent`](mobile/lib/modules/workout_overview/models/drop_intent.dart).
- [workout_overview_bloc.dart](mobile/lib/modules/workout_overview/bloc/workout_overview_bloc.dart) — dispatches `createSuperset` / `reorderUnfinished` / `removeSuperset` via the engine.

### Current superset-creation UX

- Source: any standalone unfinished exercise (not already in a superset).
- Gesture: `LongPressDraggable` on the entire card body (250 ms hold) → drag a compact pill.
- Drop target: another unfinished, non-grouped exercise card (`DragTarget<ExerciseDragPayload>` wrapping every `_DraggableExercise`).
- Feedback on hover: `AnimatedScale` to 0.98 on the target card, border switches to `primary` at 2 px width.
- ⋮ menu items per card: **Replace, Mark done, Skip, Open video**. *No "Group into superset" entry.*
- No coach mark, no help text.

### Current reorder UX

- Same `LongPressDraggable`. Drop targets are `_ReorderGap` widgets between every group — 32 dp tall at rest, 48 dp tall when hovering, a thin centered line that expands into a 6 dp primary bar when accepting.
- The `CustomScrollView` has no `ScrollController`. There is no auto-scroller. Dragging at the edge does not scroll the list.

### What the workout *day* editor (program management) does for comparison

[workout_day_editor_screen.dart](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart):

- Uses `ReorderableListView` (with auto-scroll built in) for reorder.
- Drag-onto-card *also* exists for supersets.
- Crucially, the per-card ⋮ menu has **"Group into superset"** which opens a "Group with…" picker dialog ([_promptGroupInto](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L543)).
- Shows a one-shot coach-mark snackbar on entry: *"Swipe left to delete · Long-press to reorder · Use the ⋮ menu for more"*.

The workout *overview* screen (in-session, sweaty hands) has none of these affordances. That is the gap.

## Best-practice synthesis

1. **Drag-and-drop is always a redundant gesture, never a sole one.** Material and iOS HIG both call this out: drag is "hidden", so every drag-only feature needs a tap-driven path. We already follow this rule on the program-editor screen; we don't on the in-session screen — the screen where it matters most.
2. **Edge auto-scroll is table stakes for any reorderable mobile list.** Trello, Notion, Reminders, Photos, every Material `ReorderableListView`, every iOS drag-list. Industry norms: trigger zone ≈ 80–120 dp from each edge; speed ramps from ~200 dp/s at the threshold to ~1000 dp/s at the edge.
3. **Distinct drop semantics need distinct visual feedback.** "Drop *between* cards = reorder" and "drop *onto* a card = create superset" are different operations. Today the visual difference is subtle (line-bar vs. scale-0.98+border). With one hand and sweat on the screen, you don't see it. Show a label.
4. **In-session ergonomics are the hard floor.** All new affordances must satisfy the CLAUDE.md rule: ≥56 dp primary, ≥48 dp targets in this surface, `actionLabel` typography for buttons. The ⋮ icon today is small (20 px) — keep it, but make sure dialog items inside satisfy 48 dp.
5. **First-run coach marks beat every other discoverability technique** when used sparingly. The program editor uses one. The overview screen should match.

## Proposed improvements, ordered by impact

### P0 — Fix discoverability of supersets ✅ done

**P0.1 Add "Group into superset…" to the per-card ⋮ menu.** ✅ done

- File: [exercise_card.dart](mobile/lib/modules/workout_overview/widgets/exercise_card.dart), inside `_Actions`.
- Show only when the exercise is unfinished, not in a superset, and there is at least one other unfinished, non-grouped exercise in the session.
- On tap, open a picker dialog identical in shape to [_promptGroupInto](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L543) — but built fresh in `workout_overview/widgets/group_with_picker_dialog.dart` so the in-session module does not import from `program_management`. List every other unfinished, non-grouped exercise by display name. Tap → dispatch `WorkoutOverviewDropResolved(draggedSessionExerciseId: thisId, target: DropTarget.ontoExercise(pickedId))`. That reuses the resolver path so the bloc logic stays one code path.
- New callback `onGroupIntoPressed: (List<ExerciseViewModel> candidates) → void` on `ExerciseCard`. Wired up in the screen by collecting eligible candidates from `state.groups`.

**P0.2 First-run coach-mark snackbar.** ✅ done

- File: [workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart).
- Mirror the pattern in [_EditingBodyState](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L200) — a static `bool _coachMarkShownThisSession` (process-lifetime, not persisted) gated by "have we ever shown this in this app process". Fire when the loaded state first arrives with ≥2 unfinished standalone exercises.
- Copy: *"Tip: Tap ⋮ on any exercise → Group into superset to combine two. Or long-press and drag one card onto another."*
- 8 s duration, dismissible.

**P0.3 Stronger visual cue when hovering over a drop-onto-card superset target.** ✅ done

- File: [exercise_card.dart](mobile/lib/modules/workout_overview/widgets/exercise_card.dart) (`isDropTarget` path) and `_DraggableExercise` in [workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart).
- When `candidate.isNotEmpty` on the card's `DragTarget`, overlay a centered pill on the card reading *"Group as superset"* with the `Icons.link` icon, primary background, `actionLabel` text. Animated fade-in (120 ms). Tinted background wash on the card (primary @ 8 % alpha).
- Removes ambiguity vs. a reorder-gap hover.

### P1 — Fix one-handed reorder (auto-scroll)

**P1.1 Wire up edge auto-scrolling.**

- File: [workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart).
- Convert `_WorkoutOverviewScreenState` to own a `ScrollController`. Pass it to the `CustomScrollView`.
- Introduce a `_DragAutoScroller` helper that wraps Flutter's `EdgeDraggingAutoScroller`. It receives drag-update events (pointer position in global coords) and ticks the scroller when the pointer is within an edge zone.
- `LongPressDraggable.onDragStarted` → notify the helper "drag begin"; `onDragUpdate` → push pointer; `onDragEnd`/`onDraggableCanceled` → "drag end" → cancel any in-flight scroll.
- `LongPressDraggable` in Flutter exposes `onDragUpdate` via the `Draggable` API. If the granularity is insufficient, fall back to listening at the top-level via a `Listener(behavior: HitTestBehavior.translucent, onPointerMove: …)` wrapping the body while a drag is active.
- Edge zone: 96 dp from top (below the AppBar) and 96 dp from the bottom of the visible viewport (above the `_BottomActionBar`). Compute live with `MediaQuery.padding` + bar heights so the zones sit *inside* the visible scroll area.
- Speed: linear ramp 200 → 1000 dp/s as pointer travels from edge of zone to edge of viewport. Cap by `EdgeDraggingAutoScroller`'s default.

**P1.2 Make superset cards a single hit target for the auto-scroller logic.**

- Today every card body is itself a `DragTarget` (for superset drops). That's fine. Just confirm the `Listener` (if used) wraps the *whole* scroll area, not individual cards — auto-scroll must fire even while the pointer is on top of a non-target widget.

**P1.3 Tests.**

- Per [CLAUDE.md](CLAUDE.md), tests are domain + persistence only. Auto-scroll is widget-layer logic and is not directly testable in this project's test rules.
- However, the helper class `_DragAutoScroller` (or whatever we extract) should expose a pure function `computeScrollDelta({double pointerY, double viewportTop, double viewportBottom, double edgeZone, double maxSpeed})` returning a signed dp/frame value. Move *that* to `lib/modules/workout_overview/services/drag_auto_scroll.dart` and add unit tests under `test/modules/workout_overview/services/`. Property-test: pointer inside the safe band returns 0; pointer at exact edge returns ±maxSpeed; ramp is monotonic.

### P2 — Reduce drag friction further

**P2.1 Differentiate the two drop-target visuals when the same drag is in flight.**

- Already partially covered by P0.3. Pair it: when a drag is active, every visible `_ReorderGap` should *also* expand its visible bar height a notch (e.g., 4 dp instead of 2 dp) and tag itself with a tiny "Move here" label in muted text. That tells the user the two options exist and what each means.

**P2.2 Haptic on hover-zone transitions.**

- File: [workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart). Today we only `Haptics.grab` on drag start and `Haptics.tap` on drop. Add a light `Haptics.selectionChange` (add to [haptics.dart](mobile/lib/core/haptics.dart) if not present — use `HapticFeedback.selectionClick`) on each `DragTarget`'s first `onWillAccept → true` after a candidate enters. Use a small state field on `_DraggableExercise` / `_ReorderGap` so the haptic fires once per entry, not on every frame.

**P2.3 Append an exercise to an existing superset.**

This is a real workflow ("I want to add a third exercise to the pair I already made"). The risk vector — the assembler groups by *contiguous run* of matching `supersetTag` — is real but manageable if the engine handles position + tag together. The design below stays away from the unsafe path (overwriting tags from the bloc with two sequential calls).

**Engine change (single new method, atomic):**

- New `SessionFlowEngine.addToSuperset({sessionId, supersetTag, sessionExerciseId})` in [session_flow_engine.dart](mobile/lib/modules/domain/services/session_flow_engine.dart). One method, one repository call, one Drift transaction.
- Preconditions (all checked before the write, raising the existing typed errors used by `createSuperset` / `removeSuperset`):
  - The session exists.
  - The named `supersetTag` corresponds to a non-empty contiguous run of members in the session, **all in `UnfinishedState`**. If any existing member is Completed/Skipped/Replaced, refuse — the group is already partially closed and joining it would mix terminal and live members.
  - The exercise being added exists, is in `UnfinishedState`, and has `supersetTag == null` (not currently in any group).
- Behaviour: keep the existing tag (no UUID rotation). Stamp the tag onto the new exercise and reposition it to sit immediately after the last existing member of the group. Positions are recomputed only for the rows that need to move; the rest are untouched.

**Repository change:**

- New `SessionRepository.addToSuperset(...)` contract in [session_repository.dart](mobile/lib/modules/domain/repositories/session_repository.dart) and Drift impl in [drift_session_repository.dart](mobile/lib/modules/persistence/repositories/drift_session_repository.dart). The impl does:
  1. Locate the existing group members by `supersetTag`, sorted by `position`.
  2. Compute the target insertion `position` (last existing member's `position + 1`).
  3. Update the new exercise's `supersetTag` and `position`, plus shift every exercise that comes after the insertion point. (Or, depending on how positions are encoded today — gapless ints vs. with gaps — only the new row's position is changed and trailing rows shift.) The exact shift logic mirrors what `reorderUnfinished` already does so we don't invent new position math.
- All in one transaction. If anything fails, nothing writes.

**Resolver change:**

- [drop_resolver.dart](mobile/lib/modules/workout_overview/services/drop_resolver.dart): in `_resolveOnto`, when the target has a non-null `supersetTag` and the dragged exercise does NOT (and is Unfinished), resolve to a new `DropIntent.appendToSuperset(sessionId, supersetTag, draggedId)` instead of returning noop.
- New variant `DropIntent.appendToSuperset` in [drop_intent.dart](mobile/lib/modules/workout_overview/models/drop_intent.dart).
- Bloc dispatches `_engine.addToSuperset(...)` via the same `_runMutation` path used by every other engine call.

**Picker dialog (extends P0.1):**

- The "Group with…" dialog also lists existing superset groups as targets, rendered as one entry per group (e.g. *"Add to: BB Bench Press + DB Row"* with the `Icons.link` leading icon).
- Selecting a group entry dispatches the same `WorkoutOverviewDropResolved(target: DropTarget.ontoExercise(anyMemberOfGroupId))` — the resolver routes it through the append path automatically.

**Tests:**

- Extend [drop_resolver_test.dart](mobile/test/modules/workout_overview/services/drop_resolver_test.dart) with the new append intent — both happy path and every precondition-failure case (target group not all Unfinished; dragged already grouped; dragged not Unfinished).
- New engine tests under `test/modules/domain/services/` covering `addToSuperset` happy path, precondition errors, position contiguity invariant after append.
- Persistence tests under `test/integration/` exercising the Drift repo end-to-end (using `makeInMemoryDatabase()`).

**What this design intentionally avoids:**

- No bloc-level orchestration of two mutations. Atomicity sits in the engine + repository transaction.
- No UUID tag rotation. The tag is stable across appends, so anything observing tag identity (the assembler, the "ungroup" handler that fetches all members by tag, future analytics if any) keeps working.
- No mixing of terminal and live members in one group. The precondition forces the workflow to be: finish your group, or unwind partial completions, before extending it.

### P3 — Polish

**P3.1 Wider drag-handle hit target on cards.** Today the handle is a 20 px icon inside an inset Row — the *long-press anywhere on the card* is what actually triggers drag. That's fine, but pad the visible `Icons.drag_indicator` to a 48 dp square so users who instinctively grab the handle hit it cleanly. No behavioural change — long-press anywhere still works.

**P3.2 "Drop to cancel" affordance.** When a drag is in flight and the pointer is outside every valid target for >250 ms, fade the carried pill to 60 % opacity to signal "no target here". Pure UI; no resolver change.

**P3.3 Bottom-bar Focus button placement.** Today FOCUS is the only primary action and lives in the bottom bar next to two outlined icons. Consider an unrelated polish pass on its label hierarchy — out of scope for this plan but flagging.

## Out of scope (deliberately deferred)

- **Extract a single exercise out of a superset.** Same family of risk as P2.3 but without a confirmed workflow need yet — would need yet another engine API and `DropIntent` variant. The existing "Ungroup" button (dissolves the whole group) is the supported escape hatch for now. Revisit if you find yourself reaching for it.
- Replacing `LongPressDraggable` + custom `DragTarget` with `ReorderableListView`. The day editor uses `ReorderableListView`, but our screen needs drop-onto-card semantics (supersets) that the standard widget doesn't support. Keeping the freeform approach; just adding what's missing.
- A multi-select "combine selected" mode. Powerful but introduces a mode. Reconsider only if P0.1/P0.2 don't land discoverability.
- Persisting "coach mark shown" across app launches via `shared_preferences`. Deferred to a future cross-screen refactor that covers every coach-mark at once.

## Suggested execution order

1. **P1.1 first.** Most painful issue (can't reorder one-handed at all). Self-contained, won't conflict with later work.
2. **P0.1 + P0.3.** Discoverability win plus a cheap visual fix in the same file.
3. **P0.2.** Coach mark — trivial once the menu item exists.
4. **P2.3 last among the substantive items.** Touches engine + repo + resolver, so it lands after the cheap wins are in. Ship behind a one-commit sequence: engine + repo + tests → resolver + intent + tests → UI wiring → picker-dialog extension. That ordering lets each layer stabilise before the next leans on it.
5. **P2.1 + P2.2.** Polish around the now-working drag flow.
6. **P3.\*** as time permits.

## Files touched (estimate)

- `lib/modules/workout_overview/screens/workout_overview_screen.dart` — scroll controller, auto-scroller wiring, coach-mark, drop-target visual.
- `lib/modules/workout_overview/widgets/exercise_card.dart` — new menu item, callback, hover overlay.
- `lib/modules/workout_overview/widgets/group_with_picker_dialog.dart` — new file.
- `lib/modules/workout_overview/services/drag_auto_scroll.dart` — new file (pure helper).
- `lib/modules/workout_overview/services/drop_resolver.dart` — new append branch in `_resolveOnto`.
- `lib/modules/workout_overview/models/drop_intent.dart` — new `DropIntent.appendToSuperset` variant.
- `lib/modules/workout_overview/bloc/workout_overview_bloc.dart` — dispatch new intent.
- `lib/modules/domain/services/session_flow_engine.dart` — new `addToSuperset` method.
- `lib/modules/domain/repositories/session_repository.dart` — new contract method.
- `lib/modules/persistence/repositories/drift_session_repository.dart` — Drift impl in one transaction.
- `test/modules/workout_overview/services/drop_resolver_test.dart` — extend.
- `test/modules/workout_overview/services/drag_auto_scroll_test.dart` — new.
- `test/modules/domain/services/` — new engine tests for `addToSuperset`.
- `test/integration/` — new end-to-end test for the append flow.

No layer-rule conflicts: all changes stay in `workout_overview/`, no new imports of `drift` / networking in UI, no domain → flutter leaks.

## Open questions for the author

### 1. Does the engine expose `addToSuperset`? — *Answered: no; we add one.*

[session_flow_engine.dart:397](mobile/lib/modules/domain/services/session_flow_engine.dart#L397) only has `createSuperset` and `removeSuperset`. `createSuperset` stamps a freshly-generated UUID `supersetTag` onto every listed exercise and does NOT enforce `supersetTag == null` on inputs — so it would technically work to "fake" append by passing `[newId, ...existingMembers]`. But that path is the bug-prone one: the assembler groups by *contiguous run* of matching `supersetTag`, so we'd also need a separate `reorderUnfinished` call — two sequential mutations, no atomicity, and the tag UUID rotates on every append.

**Decision (drives P2.3 design):** add a dedicated `SessionFlowEngine.addToSuperset` that takes the existing `supersetTag` and the new exercise's id and does position-fix + tag-stamp in a single Drift transaction. Tag is preserved (not rotated). See P2.3 above for the full contract.

### 2. Coach-mark cadence — *decided.*

Use the **per-app-process** flag (matches [workout_day_editor_screen.dart:201](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L201) — a `static bool _coachMarkShownThisSession`). The tip shows once per cold start.

Persisting "once-ever" via `shared_preferences` is deferred to a future cross-screen refactor that covers every coach-mark in the app at once, rather than introducing the persistence pattern for a single new tip.
