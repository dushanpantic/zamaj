# Set-order redesign — supporting out-of-order logging across exercises

Date: 2026-05-17

## 1. Problem

The user went to the gym intending to superset bench press and lat pulldown.
The lat pulldown got taken mid-workout, so the actual sequence ended up being
`bench, lat, bench, bench, lat, lat`. The app could not log this naturally.

Concretely: today there is a single **global cursor** that points at *one*
`(sessionExerciseId, setIndex)` pair. The UI gates set-logging by that cursor,
so the user can only log onto whichever exercise the cursor is currently
parked on. Even inside a superset, the cursor walks one exercise at a time —
it picks the first unfinished exercise in position order and won't move on
until that exercise's planned set count is fulfilled.

The redesign goal: allow the user to freely log a working set on any
in-progress exercise at any moment, with the UI making this obvious and
ergonomic for the in-gym, one-handed use case.

## 2. Key insight: the constraint is in the UI, not the domain

The repository's
[`completeSet`](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L321-L432)
**already accepts any `sessionExerciseId`** and appends an `ExecutedSet` with
dense chronological `position = existingSets.length`. It does not consult the
global cursor.

The engine's
[`completeSet`](mobile/lib/modules/domain/services/session_flow_engine.dart#L275-L323)
only checks `cursor is CompletedCursor` (session-level), not that the supplied
`sessionExerciseId` matches the cursor target.

What gates out-of-order logging today:

- [exercise_view_model_assembler.dart:136-139](mobile/lib/modules/workout_overview/services/exercise_view_model_assembler.dart#L136-L139) — sets `SetRowViewModel.isNextLogTarget` *only* for the row matching the global cursor.
- [set_row.dart:54-62](mobile/lib/modules/workout_overview/widgets/set_row.dart#L54-L62) — non-target rows render in `SetRowMode.pending` and are non-interactive.
- [focus_mode_screen.dart](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart) — only ever renders the single cursor exercise.

So the redesign is primarily an *information architecture* change at the
domain/UI seam and a UI restructure of two screens. The persistence layer
needs only minor cleanup. There is no schema change required for the core
feature.

## 3. Target model

### 3.1 Drop the global cursor

Replace [`Cursor`](mobile/lib/modules/domain/services/cursor.dart) with
per-exercise derived data:

- A `SessionExercise` is **loggable** when its state is `unfinished` or
  `replaced` (and `executedSets.length < plannedSetCount`), OR `completed`
  with the user opting in to add extra sets.
- A `SessionExercise` exposes a derived `nextSetIndex = executedSets.length`
  (the slot the next chronological set would land in). Pure projection, not
  stored.
- `SessionState` no longer carries a `Cursor`. It exposes a derived list of
  `LogTarget(sessionExerciseId, plannedSetIndex)` for *every* exercise that
  is currently loggable. UIs read that list to render their affordances.

```dart
// lib/modules/domain/services/session_state.dart  (after)
abstract class SessionState with _$SessionState {
  const factory SessionState({
    required Session session,
    required List<LogTarget> openTargets,  // one per in-progress exercise
    required bool isComplete,               // derived: every exercise terminal
  }) = _SessionState;
}
```

`suggestedValues` moves to a per-exercise helper on the engine —
`engine.suggestValuesFor(session, sessionExerciseId)` — called from the UI
when a row's editor opens.

**Migration of the engine:**

- Delete `Cursor`, `ActiveCursor`, `CompletedCursor`, `computeCursor`.
- `completeSet` validates the target exercise is in a loggable state
  (`unfinished | replaced | completed`); throw `OrderingError` for
  `skipped`. (Note that allowing `completed` keeps the "extra set on a
  finished exercise" affordance the overview already exposes via
  `SetRowMode.trailing`.)
- `_buildState` rebuilds `SessionState` with `openTargets` + `isComplete`
  instead of `cursor` + `suggestedValues`.

### 3.2 Stop reanchoring exercise positions on state change

Today `completeSet`, `skipExercise`, `replaceExercise` re-anchor the touched
exercise's `position` past all locked exercises and renumber the remaining
unfinished tail (see
[`_renumberUnfinishedAfterLock`](mobile/lib/modules/persistence/repositories/drift_session_repository.dart#L1047-L1079)).
This exists *only* to make the cursor walk past terminal exercises.

With no cursor, this dance is unnecessary and actively harmful:

- It scrambles the visible order in the overview as exercises complete.
- It changes the [export
  formatter](mobile/lib/modules/domain/services/session_export_formatter.dart#L34-L41)
  ordering — supersets that complete get pushed past unfinished singles.
- It breaks the user's mental model: "the order is whatever I plan +
  whatever I manually reorder."

**Change:** positions are set once at `startSession` (template order ×
`_gap`) and changed only by an explicit user reorder. State flips are
state-only writes — no `position` updates.

`reorderUnfinished` keeps its current semantics (drag in the overview),
but now operates against the stable initial ordering rather than a
cursor-driven shuffled one.

### 3.3 Auto-complete on quota fulfilment (unchanged)

When `executedSets.length >= plannedSetCount` after a `completeSet` and the
state was `unfinished`, flip to `completed`. Same as today, minus the
position write.

### 3.4 Explicit "mark done" for partial completion

New action: `markExerciseDone(sessionExerciseId)` — locks an `unfinished`
exercise to `completed` even when fewer than the planned number of sets
were logged. Mirrors `skipExercise` semantically (terminal state) but the
sets that *were* logged are kept and rendered. This replaces the implicit
"do all planned sets to advance the cursor" behavior, which no longer
exists.

UI: a "Mark done" item in the exercise card's action menu, shown next to
"Skip" and "Replace" when the exercise has at least one executed set.

## 4. UI redesign

### 4.1 Workout Overview becomes the primary in-session screen

This is mostly already true structurally — it shows a card per exercise
with expandable set rows. The changes are surgical.

**[`SetRow.mode`](mobile/lib/modules/workout_overview/widgets/set_row.dart#L54-L62) becomes:**

```dart
SetRowMode get mode {
  final executed = viewModel.executedSet;
  if (executed != null && viewModel.plannedValues == null) return SetRowMode.trailing;
  if (executed != null) return SetRowMode.completed;
  if (viewModel.isLoggable) return SetRowMode.loggable;   // renamed from nextTarget
  return SetRowMode.future;                                 // visible but non-interactive
}
```

A row is `loggable` when its exercise is in `unfinished|replaced|completed`
**and** the row's `position == executedSets.length` (the next chronological
slot for *this* exercise). All future rows beyond that stay `future` so the
user can't accidentally log out-of-order *within* a single exercise — the
user's stated need was cross-exercise out-of-order, and within-exercise
sequencing is still a meaningful invariant (rep-progression makes sense in
order).

**The exercise card always shows the loggable row pre-expanded.** That way
in a superset card with two exercises, both "next set" editors are visible
simultaneously, one tap away from a log. Today's per-exercise expansion
state (`_expandedSetPositions`) goes away — the next-loggable row is the
expansion source of truth.

**Subtle highlight on the most-recently-touched exercise's loggable row.**
A faint accent so the eye returns to where it left off after a rest.
Driven by `WorkoutOverviewLoaded.lastTouchedSessionExerciseId`, updated
when the user logs a set or interacts with a card.

**Drag-reorder stays.** Same superset/reorder semantics on the new stable
position ordering.

### 4.2 Focus Mode — superset-aware, optional

Focus Mode today is a single-exercise zen view. For the new model it
becomes optional and superset-aware:

- The screen accepts a starting `sessionExerciseId`.
- If that exercise has a `supersetTag`, render a vertically-stacked panel
  per exercise in the same group, each with its own current values panel
  and `LOG SET` button. The rest timer remains global to the screen — when
  the user logs a set on exercise A inside the superset, the rest timer
  uses A's planned rest.
- If no `supersetTag`, render the existing single-exercise layout.
- "Up next" walks to the next group (single or superset) past the current
  one.
- A "switch" affordance in the app bar lets the user jump to any other
  in-progress exercise/group without leaving Focus Mode.

The bottom action bar from the overview keeps a "FOCUS" CTA but it's no
longer the privileged path. Users who don't want zen mode never have to
visit it.

### 4.3 Removing UI ↔ cursor entanglement

- `FocusModeBloc` no longer hinges every decision on cursor advancement.
  Set-completion still re-seeds the draft from the new
  `engine.suggestValuesFor(...)` for whichever exercise was just logged on.
- `WorkoutOverviewBloc._expansionWithCursor` becomes
  `_expansionForOpenTargets` — auto-expands every loggable exercise's card
  on initial load and on each refresh.
- `ExerciseViewModel` loses `isCursorTarget` / `cursorSetIndex`. It gains
  `isLoggable` (any next-slot row exists) and inherits `setRows` with the
  new `isLoggable` flag per row.

## 5. Persistence

### 5.1 Schema

No column changes. The cursor was never persisted; it was always derived.

### 5.2 Migration

We are bumping the destructive [v6→v7
migration](mobile/lib/modules/persistence/database/migrations.dart#L32-L36)
pattern: rep targets did the same thing recently and the user is the sole
installer.

- Bump [`SchemaVersions.drift`](mobile/lib/core/schema_versions.dart#L7)
  from `7` → `8`. Domain stays at `5` (no on-disk shape change).
- Add a v7→v8 migration that **re-anchors `session_exercises.position`** to
  template order for any in-flight sessions: `position = snapshotIndex *
  1024`, where `snapshotIndex` walks the captured snapshot in workout-day
  group/exercise order. This undoes any prior reanchoring shuffles so the
  visible ordering after upgrade matches the snapshot.
- No row wipe — sessions and history stay.

The repository code itself stops writing `position` on state change as soon
as the migration ships; pre-existing rows get re-normalized once by the
migration, after which all positions are stable.

### 5.3 Repository contract trim

[`SessionRepository`](mobile/lib/modules/domain/repositories/session_repository.dart):

- `completeSet`/`skipExercise`/`replaceExercise`/`deleteExecutedSet`: drop
  the implicit reanchor side effect. Method signatures unchanged.
- Add `markExerciseDone({required String sessionExerciseId})`.
- No method removed (back-compat with the engine that calls them).

## 6. Tests

The codebase scopes tests to domain + persistence (per
[CLAUDE.md](mobile/CLAUDE.md)). All tests live there; no widget/bloc tests.

**Update / remove:**

- `test/domain/services/session_flow_engine_*.dart` — remove cursor
  assertions, add per-exercise logging assertions.
- `test/modules/workout_overview/services/exercise_view_model_assembler_test.dart`
  — update to the cursor-less assembler API.
- `test/modules/focus_mode/services/focus_mode_assembler_test.dart` —
  rewrite around the new "exercise or superset group" focus model.
- `test/repository/position_order_test.dart` — assert positions are stable
  across state transitions (the inverse of what it likely asserts today).

**Add:**

- Engine test: log alternating sets on two exercises in a superset; assert
  ExecutedSet.position is dense chronological *per exercise* and that
  exercise positions are unchanged.
- Engine test: log a set on a `completed` exercise (extra set); assert it
  appends, state stays `completed`.
- Engine test: log a set on a `skipped` exercise; assert it throws
  `OrderingError`.
- Engine test: `markExerciseDone` with N executed (N < planned); subsequent
  log attempts throw; previously-logged sets remain readable.
- Persistence migration test: seed v7 rows whose positions were
  reanchored, run upgrade, assert positions are renormalized to snapshot
  order.
- Property test: for any sequence of `completeSet` calls on a mixed set of
  exercises, the visible ordering (positions) is invariant.

**Property test that does NOT change:** snapshot immutability across
mutations stays intact.

## 7. Phased implementation

Sized to keep each PR independently testable. CLAUDE.md says "one bundled
PR" can be preferred for refactors — the user is solo, so I'd land this as
a single feature branch but with clear commits per phase.

1. (COMPLETED) **Engine: cursor removal + per-exercise targets.** Update `SessionState`,
   delete `Cursor`, rewrite engine, update domain tests. Repo unchanged at
   this phase — keep its reanchoring, just don't read it. (UI still
   compiles against the old API surface via temporary shims.)
2. (COMPLETED) **Repository: stop reanchoring; add `markExerciseDone`.** Update repo
   tests for the stable-position invariant.
3. (COMPLETED) **Migration v7→v8.** Re-normalize positions. Integration test on a
   seeded v7 db.
4. **Workout Overview UI.** Switch `SetRowMode` semantics, auto-expand all
   loggable rows, drop the cursor-driven expansion logic, add the
   "Mark done" menu entry.
5. **Focus Mode UI.** Superset-aware layout; "switch exercise" affordance.
6. **Cleanup.** Delete `Cursor` files, `cursor.dart`, the freezed
   generated artifacts, and any imports. Confirm
   `tool/check_offline_imports.sh` and `tool/ci.sh` are green.

## 8. Risks and edge cases

- **Within-exercise out-of-order:** intentionally still disallowed. The
  user's concrete pain was cross-exercise; within-exercise sequencing
  matches the planned progression (e.g. ascending weights). If a future
  request asks for it, the `ExecutedSet.position` field is already a free
  index — we'd just stop tying it to `executedSets.length` and add a
  "skip set" UI.
- **Rest timer in supersets:** the current model is "per just-completed
  exercise's `plannedRestSeconds`." That stays fine — in a true superset
  the user typically wants minimal rest between A and B and a real rest
  after the round, but encoding that is out of scope for this redesign and
  the user can override the timer manually.
- **Export ordering:** with stable positions, exports reflect the planned
  order verbatim, not the cursor-shuffled order. Verify the formatter test
  goldens; regenerate via `dart run
  tool/generate_aggregate_goldens.dart` if intentional changes appear.
- **Extra sets on completed:** today's `SetRowMode.trailing` displays them,
  but there's no UI to *add* one. Add an explicit "+ Add extra set" action
  inside the completed exercise's expanded card.
- **Undo last set:** Focus Mode's undo button removes the most recent
  executed set on the currently-focused exercise. With the multi-exercise
  Focus Mode, scope undo to the last-logged exercise within the visible
  group rather than a global "last logged anywhere."

## 9. Flutter best practices to observe

The codebase is already disciplined; the redesign should preserve that:

- **Layer isolation** — keep the offline-first guard happy. No `drift`,
  `dart:io`, `http`, etc. imports leak into `core`, `domain`, or UI
  modules; UI talks to domain through repository contracts and the engine.
  Run `tool/check_offline_imports.sh` before each commit.
- **Pure domain** — `SessionFlowEngine` stays stateless. All state lives
  in the database; the engine reads and returns. Same for the new
  `LogTarget` projection.
- **freezed sealed types** — `LogTarget` and any new state unions use
  `@Freezed(unionKey: 'type')` with a private `._()` constructor for
  invariants, mirroring `RepTarget` and `ExerciseState`.
- **Build runner** — every model change needs `dart run build_runner build
  --force-jit`. Don't hand-edit `*.freezed.dart` / `*.g.dart`.
- **Tokens** — keep using `Theme.of(context).appColors`,
  `AppSpacing.*`, `AppRadius.*`, `AppTypography.*`. The new "loggable
  highlight" should land as a new semantic color (e.g.
  `colors.loggableHint`) added to both palettes in
  [app_colors.dart](mobile/lib/core/app_colors.dart) rather than a one-off
  alpha.
- **Bloc state equality** — keep using `Equatable` / freezed equality so
  `BlocBuilder` doesn't over-rebuild when the same `SessionState` arrives
  twice from the watch stream.
- **Selective rebuilds** — for the workout-overview card list, consider
  `BlocSelector` per card if the existing `BlocBuilder` rebuilds all cards
  on every mutation. Profile before optimizing — for ~10 cards it's
  probably fine.
- **Stream lifecycle** — `watchSession` is the source of truth for both
  blocs. Mutations write, the stream re-emits, the bloc reassembles. Keep
  it. The new `LogTarget` list is derived inside the engine's `_buildState`,
  so each stream emission carries a fresh consistent projection.
- **Controllers** — `SetRow` already owns its `TextEditingController`s
  and disposes them. With every loggable row pre-expanded, more controllers
  are alive at once; double-check there's no leak when an exercise flips
  state and a row disappears (`dispose` should fire via `ValueKey` on the
  row).
- **Const constructors** — keep them where the inputs allow; the new
  `LogTarget` and updated `SessionState` should both be const-constructible.
- **No widget tests** — per CLAUDE.md, test coverage stays at domain +
  persistence. Manual smoke-test the overview and focus mode on device
  before declaring done.

## 10. What this redesign does *not* do

- It does not introduce session-level concurrency, sync, or networking.
  The offline-first contract is untouched.
- It does not change the immutable session snapshot or the canonical JSON
  hash. Snapshot capture stays at `startSession`.
- It does not change the planned/actual separation. Planned values still
  live on the template; actual values still live on `ExecutedSet`s tagged
  with `plannedSetIdInSnapshot`.
- It does not change session export formats beyond reordering. Goldens
  will need regeneration if the position re-normalization changes any
  existing session's export, but the format is unchanged.
