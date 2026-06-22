# Spec: Remove Exercise from Superset (Workout Overview)

## Intent Description

During a live session, the workout-overview screen lets a lifter group exercises
into supersets and ungroup them, but the only way to *leave* a group is to
**Ungroup** the whole thing — there is no way to pull a single exercise out while
keeping the rest of the superset intact. (Member extraction was explicitly
deferred as out of scope in [superset-drag-drop-ux.md](superset-drag-drop-ux.md);
this spec implements it.)

This change adds **Remove from superset**: a per-member action that pulls one
exercise out of its superset and drops it back into the list as a standalone
exercise positioned **immediately under the superset**, keeping the remaining
members grouped and in order. The exercise itself is untouched — its planned and
logged sets and its state come with it; only its grouping and position change.

The action is offered only when it makes sense. A **fully-unfinished** superset
with **3 or more** members offers **Remove from superset** on each member; if any
member of the superset is already finished (done/skipped), the group is treated as
a fixed anchor and offers only **Ungroup** (matching how the rest of the
in-session structural edits treat partially-finished groups). A superset with
**exactly 2** members does *not* offer it — removing one of two would leave
a lone, still-tagged member (a degenerate one-member "superset"); instead the
header's existing **Ungroup** is the right tool, splitting both into standalone
exercises while preserving their order. Removal is a non-destructive structural
change, so it takes effect immediately with **no confirmation dialog** and an
**Undo** snackbar that restores the exercise to its prior membership and
position. Finally, superset members gain **A1 / A2 / A3…** position labels that
**renumber live** as membership changes, so the pairing stays legible after a
removal, ungroup, or reorder.

Scope is confined to the in-session workout-overview surface. The frozen session
snapshot, separate planned/actual tracking, and immutability rules are
untouched — extraction is a session-structure change in the same family as
reorder and ungroup.

## Architecture Specification

### Layer & module placement
All work lives under `mobile/lib/modules/workout_overview/`, plus a pure ordering
helper in `mobile/lib/modules/domain/` and possibly one engine/repository method.
No persistence **schema** or migration change. No new networking. Domain stays
pure Dart. UI talks to data only through domain repository/engine contracts.

### Behavior: how a superset is represented
A superset is a **contiguous run** of session exercises sharing a `supersetTag`,
detected by `groupBySupersetRun` and assembled into a
`SupersetGroupViewModel.superset` (a lone or null-tagged run becomes a
`.single`). Two consequences drive this design:

- Removing the **last** member is just "clear its tag in place" — it is already
  directly under the group.
- Removing a **first or middle** member requires **repositioning** it to sit
  immediately after the group's last remaining member; otherwise clearing the
  tag splits the run into two supersets. The remaining members must stay one
  contiguous run.

### Ordering rule (pure domain)
- **Owner:** a new pure helper on `SupersetOrdering`
  (`domain/services/superset_ordering.dart`), mirroring the existing
  `blockedOrderForCreate` / `orderForAppend`. Call it conceptually
  `orderForExtract`: given the current ordered ids and the member being
  extracted, it returns the new unfinished-id order with the extracted id placed
  **immediately after the group's last remaining member**, every other exercise
  keeping its relative order. Unit/property tested in `test/`.

### Engine / repository
The operation is: clear the member's `supersetTag` **and** reposition it, as one
atomic unit (a mid-operation failure must not leave a split run).
- **Preferred:** reuse the existing primitives — `removeSuperset(sessionId,
  sessionExerciseIds: [memberId])` (already validates the member is unfinished
  and tagged) composed with `reorderUnfinished(orderedUnfinishedIds)` from the
  `orderForExtract` result.
- **Acceptable alternative if composing two ops can't be made atomic:** a new
  single transactional method (e.g. `SessionFlowEngine.removeFromSuperset` +
  `SessionRepository.removeFromSuperset`).
- `/plan` decides which, under the hard constraint: **atomic, and the remaining
  members stay one contiguous run.** No schema/migration change either way.

### UI affordance (decision: per-member kebab item)
Per the in-session rule "the card surface is reserved for LOG SET; every
secondary action lives in the kebab," **Remove from superset** is a new entry in
the existing per-member overflow menu — the inverse of the existing
**Group into superset…** item (suggested icon `Icons.link_off`). This is the
best-practice fit: consistent with the established pattern, adds no competing
tap target to the row (sweaty-hands), and avoids a novel swipe gesture that could
fire by accident mid-set.

- `widgets/exercise_card.dart`: add `_MenuAction.removeFromSuperset` and an
  `onRemoveFromSupersetPressed` callback, rendered next to the group-into slot.
- `widgets/superset_card.dart`: thread a per-member remove callback (mirroring
  `memberMoveBuilder`), supplied **only when the superset has ≥ 3 members and
  every member is unfinished** (and the session is live) — so the item never
  appears in a 2-member group, in a partially-finished group, or after the
  session ends.
- `screens/workout_overview_screen.dart` / `widgets/workout_group_builder.dart`:
  wire the callback to dispatch a new bloc event.
- `bloc/workout_overview_event.dart`: new
  `WorkoutOverviewSupersetMemberRemoved(sessionExerciseId)`.
- `bloc/workout_overview_bloc.dart`: handler resolves the order via
  `SupersetOrdering.orderForExtract` and runs the engine op through the existing
  `_runMutation` in-flight guard / optimistic-state path.

### A1 / A2 position labels (live renumber)
Superset members currently render **no** position label in-session. Introduce
A-labels (`A1`, `A2`, `A3`…) on each member, derived from the member's index
within its assembled run — so they renumber automatically whenever the run
changes (removal, ungroup, reorder). Derivation lives in the assembler /
`SupersetGroupViewModel` or is computed by `superset_card.dart` from member
index (mirrors the editor's `_positionLabel`); rendered on the member card.
`/plan` picks the exact seam. Standalone (`.single`) exercises get no label.

### No-confirm + Undo
Removal is reversible structure, not data loss: **no confirmation dialog.** On
success, surface an **Undo** snackbar (mirror the optimistic snackbar-undo in
`program_editor` — `_showUndoSnackbar` + a `…Undone` event), whose action
restores the exercise's prior `supersetTag` and its exact prior position within
the group. The pre-removal membership/position must be captured so Undo can
reinstate it; `/plan` decides the state plumbing (transient bloc state vs.
re-group event carrying the original anchor).

### Cross-cutting constraints (must hold)
- **Offline-first isolation:** no `drift`/`AppDatabase`/`sqlite3` in
  `workout_overview`; ordering logic stays in pure, unit-tested domain services.
- **Sweaty-hands ergonomics** (`workout_overview/` rule): the new menu item is
  comfortably tappable; no new control is added to the member row.
- **Immutable snapshot untouched:** extraction changes session structure only
  (like reorder/ungroup); planned/actual values and the frozen snapshot are
  unchanged.
- **Ended-session lock:** no extraction when the session has ended
  (`canMutate`/`canLog` already gate this).
- **Tokens:** no hard-coded px/colors — `AppSpacing`, `AppRadius`, `appColors`,
  `AppTypography` (use `AppTypography.standard.*`; labels are short text, not
  numeric readouts).

### Out of scope (explicit)
- **Drag-to-extract.** Pulling a member out by dragging it to a gap remains out
  of scope (the menu action is the only extraction affordance); the sibling
  spec's reorder-only drag rules are unchanged.
- **Editor surface.** The program/template superset builder
  (`editor_superset_card.dart`) is unchanged — its swipe still *deletes*; this
  spec does not touch planning.
- **Focus mode.** No new extraction affordance inside focus mode; it simply
  reflects the post-extraction structure on its next assembly, as ungroup
  already does.
- Merging/nesting supersets; any change to export or the frozen-snapshot rules.

## Acceptance Criteria

Terminology: a **superset** is a contiguous run of exercises sharing a
`supersetTag`; **member count** is the number of exercises in that run (any
state); **extract / remove** clears one member's tag and repositions it.

### A. Affordance availability
- **A1 — offered on a fully-unfinished 3+ superset.** Every member of a superset
  with **≥ 3** members, all of them unfinished, exposes a **Remove from superset**
  item in its per-member overflow menu while the session is live. PASS only if
  present under those conditions.
- **A2 — hidden on exactly 2.** No member of a **2**-member superset shows
  **Remove from superset**; the header's **Ungroup** is the only leave action.
- **A3 — hidden on standalone & partially-finished groups.** A standalone
  (`.single`) exercise never shows it; and if **any** member of a superset is
  finished (done/skipped), **no** member of that superset shows it (the group is a
  fixed anchor) — only **Ungroup** remains.
- **A4 — ended-session lock.** Once the session has ended, no member shows
  **Remove from superset**.

### B. Removal behavior & ordering (≥ 3 members)
- **B1 — pulled out and kept.** Removing a member clears its `supersetTag` and it
  reappears as a standalone exercise; its planned/logged sets and its state are
  unchanged.
- **B2 — placed right under the superset.** The removed exercise lands
  **immediately below** the superset (directly after the group's last remaining
  member, before whatever group followed the superset).
- **B3 — remaining members stay one superset.** Given `[A1,A2,A3]`, removing the
  **middle** member A2 yields the superset `[A1, A3]` followed immediately by the
  standalone former-A2; the remaining members render as **one** contiguous
  superset (not split into two).
- **B4 — first member case.** Removing the **first** member A1 from `[A1,A2,A3]`
  yields superset `[A2, A3]` followed immediately by standalone former-A1.
- **B5 — others preserved.** Every exercise not involved keeps its relative
  order; finished/terminal exercises keep their absolute slots.
- **B6 — group shrinks to 2.** After removing one member of a 3-member superset,
  the resulting 2-member superset no longer offers **Remove from superset** (only
  **Ungroup**), per A2.

### C. Exactly-2 rule (ungroup only)
- **C1 — ungroup splits both.** Ungrouping a 2-member superset turns both members
  into standalone exercises.
- **C2 — order preserved.** After ungroup the two exercises keep the order they
  had inside the superset (existing `removeSuperset` behavior — no new work
  beyond hiding Remove).

### D. No-confirm + Undo
- **D1 — no confirmation.** Selecting **Remove from superset** applies
  immediately with no confirmation dialog.
- **D2 — undo restores membership & position.** An **Undo** affordance (snackbar)
  is shown after removal; invoking it re-adds the exercise to its original
  superset at its **exact prior position** (e.g. removing A2 from `[A1,A2,A3]`
  then Undo restores `[A1,A2,A3]`).
- **D3 — undo expiry is safe.** Letting the snackbar dismiss without tapping
  leaves the removal in place; no further change occurs.
- **D4 — stale undo fails safely.** If the session changed since the removal
  (another mutation ran, the session ended, or the member is no longer
  re-groupable), tapping Undo leaves the post-removal state intact and surfaces a
  brief, dismissible message ("Couldn't undo — the workout changed"); it never
  produces a split run or a partially-restored group.

### E. A1 / A2 position labels (live renumber)
- **E1 — labels shown (and announced).** Each superset member displays a position
  label `A1`, `A2`, `A3`… in member order; standalone exercises show none. The
  label is also exposed to assistive tech (a semantics label such as "Superset
  position A1 of 3") so superset membership is perceivable non-visually.
- **E2 — renumber after removal.** After removing a member, the remaining members
  renumber contiguously from `A1` (e.g. `[A1,A2,A3]` remove A2 → remaining group
  shows `A1`, `A2`).
- **E3 — renumber after reorder/ungroup.** Reordering members or ungrouping
  updates/clears labels to match the new structure with no stale numbering.

### F. Non-regression, ergonomics & docs
- **F1 — pure-service tests.** `SupersetOrdering.orderForExtract` (and any new
  engine/repo method) is covered by unit/property tests under `test/`; existing
  superset ordering/grouping tests still pass.
- **F2 — atomic, single run.** The extraction (tag-clear + reposition) is atomic;
  a failure leaves the prior structure intact, and success never yields a split
  run. No schema/migration change.
- **F3 — ergonomics & tokens.** The new menu item meets the in-session
  tap-target expectations and uses design tokens (no literal px/colors); no new
  control is added to the member row.
- **F4 — `tool/ci.sh` green** (offline-imports guard, codegen, format, analyze,
  test).
- **F5 — product-context.md updated.** The workout-overview bullet in
  [product-context.md](../../product-context.md) is updated in the same change to
  mention removing a single exercise from a superset and the A1/A2 member labels.

## Consistency Gate
- [x] Intent is unambiguous — extraction (pull out, keep, place right under the
  group), the 3-vs-2 member rule, no-confirm + Undo, and live A-labels are stated
  with worked examples and explicit out-of-scope items.
- [x] Every behavior/goal maps to an acceptance criterion — affordance → A1–A4;
  extraction/ordering → B1–B6; exactly-2 → C1–C2; no-confirm/undo → D1–D3;
  labels → E1–E3; non-regression/docs → F1–F5.
- [x] Architecture constrains without over-engineering — reuses
  `groupBySupersetRun`, `removeSuperset`/`reorderUnfinished`, the
  `SupersetOrdering` family, the kebab pattern, and the existing snackbar-undo
  precedent; defers drag-to-extract and the exact atomic mechanism to `/plan`.
- [x] Terminology consistent across artifacts — "superset", "member", "contiguous
  run", "extract/remove", "Ungroup", "unfinished", "standalone", "A-label" used
  uniformly and aligned with [superset-drag-drop-ux.md](superset-drag-drop-ux.md).
- [x] No contradictions between artifacts — supersedes the sibling spec's
  member-extraction deferral (via menu, not drag); kebab-only affordance and
  immutable-snapshot rules held consistently in intent, architecture, and
  out-of-scope.
