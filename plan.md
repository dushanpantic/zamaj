# Plan — Workout overview: tap-to-log set circle, drop the LOG SET button

## Goal

Make the workout-overview screen overview-first. Remove the always-on `LOG SET`
button and the always-expanded numeric editor from each exercise card; promote
the per-set indicator circle to the primary "log this set" affordance. Keep
deviation logging (actual ≠ planned) possible, but demote it behind one tap.

## Current state (verified)

- Only the **current** exercise auto-expands; all other cards are collapsed
  (`_initialExpansionFor` / `_expansionForOpenTargets` in
  `mobile/lib/modules/workout_overview/bloc/workout_overview_bloc.dart`).
- The loggable set row is **always** rendered with an open editor: two 64dp ±
  counter rows + a 56dp `LOG SET` button (`_Editor`, `_NumericField`,
  `_StepButton` in `mobile/lib/modules/workout_overview/widgets/set_row.dart`).
- The set indicator circle is `Icons.adjust` (18px), **deliberately chosen to
  NOT look tappable** — see the comment at `_StatusIcon` in `set_row.dart`.
- A sensible one-tap value already exists: `SetRowViewModel.suggestedActualValues`
  (last executed set's actual) with a planned-as-actual fallback
  (`_plannedAsActual` in `set_row.dart`).
- `SetRow` is shared by single cards **and** superset members (both go through
  `ExerciseCard._ExpandedBody`), so changing `SetRow` covers both surfaces.
- Undo is feasible: `SessionFlowEngine.deleteExecutedSet` exists and Focus mode
  already wires an undo with it (`focus_mode_bloc.dart` `_onUndoRequested`).
- No undo exists on the overview today; correction is tap-completed-row → edit.

## Why not the literal "circle logs, editor gone" idea

`planned ≠ actual` is pillar #1 (honest record). A blind one-tap that logs the
*suggested* value silently records wrong numbers on every deviation — the exact
case the app exists to capture. So deviation capture must be **demoted, not
removed**, and the quick-log path must have **cheap, visible recovery** (undo).
The circle must also be redesigned to actually read as a button (≥56–64dp,
ripple, fill-to-check) — its current form intentionally signals "not a button."

## Decision fork (resolve before building)

- **A — Inline deviation editing (RECOMMENDED, this plan).** Tap circle =
  quick-log suggested value + undo. Tap row body = reveal inline ± editor for a
  deviation, then confirm. Editor stays but is opt-in.
- **B — Route deviations to Focus.** Overview rows become read-only; the circle
  quick-logs, and a secondary affordance opens Focus mode at that set for any
  change. Purest "overview is only overview," but a screen transition per
  deviation. Heavier for same-as-last sets.
- **C — Status quo.** Keep the always-on editor.

This plan implements **A**. Switching to B mainly changes step 3 (replace the
inline editor reveal with a "open in Focus" navigation).

## Recommended design (Option A)

Collapsed loggable row, single line:

```
Set 2    100kg × 5     (→ 100 × 5 dimmed suggestion)        ◯ (56–64dp, tappable)
```

- **Primary tap = check-circle.** Logs `suggestedActualValues ?? plannedAsActual`.
  Fires `Haptics.tap()`, animates fill→check, then shows an UNDO snackbar.
- **Tap row body / planned-actual numbers = reveal inline ± editor** (the
  existing `_Editor`), with a compact confirm (checkmark, not a full-width LOG
  SET button). Used to log a deviation deliberately.
- **Completed rows** keep today's tap-to-edit behavior; their status icon stays
  the filled check (non-interactive beyond the existing row tap).
- The standalone `LOG SET` button is removed.

## Implementation steps

### 1. `set_row.dart` — collapsed loggable row + tappable circle
- Add local state `bool _editorOpen` (loggable rows only; default `false`).
- Change `showEditor` so a loggable row shows the editor only when `_editorOpen`
  is true (completed/trailing keep `_editingExisting`; future stays false).
- Replace `_StatusIcon`'s loggable branch with a real button: a ≥56–64dp
  `InkWell`/`IconButton` target (sweaty-hands floor — these are in-session
  modules), primary-colored ring that fills to a check on press, with a
  `semanticLabel`/tooltip like "Log set". Keep completed/future/trailing icons
  as-is (still 18px, non-interactive).
- Add `_quickLogValues()` → `widget.viewModel.suggestedActualValues ??
  _plannedAsActual(widget.viewModel.plannedValues)`. On circle tap:
  - if values non-null → `widget.onLogSet(values, plannedSetIdInSnapshot)`.
  - if null (no plan, no prior — rare) → open the editor instead of logging.
- Make the collapsed loggable row body tappable to toggle `_editorOpen`
  (reveals the ± editor for a deviation). Use the planned/actual text region or
  the whole row minus the circle.
- In `_Editor`: drop the full-width 56dp `LOG SET` FilledButton; replace with a
  compact confirm (checkmark) consistent with the row circle. Editing an
  existing set keeps a `SAVE`/confirm affordance. `onSubmit` unchanged.
- Respect tokens: `AppSpacing`, `AppRadius`, `Theme.of(context).appColors`,
  `AppTypography.standard` (numeric readouts use `numeric`/`numericLarge`).

### 2. Visual feedback for quick-log
- On tap, animate the circle ring→filled check (short `AnimatedSwitcher` or
  `AnimatedContainer`, ~120ms to match existing card animations).
- Keep the existing `lastTouchedSessionExerciseId` accent
  (`highlightLoggable`) so focus returns to the right card after a rest.

### 3. Undo wiring (overview bloc)
Mirror Focus mode's pattern:
- After a successful `_onSetLogged`, capture the newly created executed set's id
  for the touched exercise (read it off the returned `SessionState` — the last
  executed set on `event.sessionExerciseId`).
- Surface an UNDO affordance. Cheapest: have the screen show a snackbar with an
  UNDO action after a log (the screen already calls `Haptics.tap()` in the
  `onLogSet` callback in `workout_overview_screen.dart`). UNDO dispatches a new
  `WorkoutOverviewSetLogUndone` event → `_engine.deleteExecutedSet(...)` via
  `_runMutation`.
- Add `WorkoutOverviewSetLogUndone` to `workout_overview_event.dart` and a
  handler in `workout_overview_bloc.dart` mirroring `_onSetEdited`'s shape.
- Keep tap-completed-row-to-edit as the durable correction path (already works).

### 4. Screen glue (`workout_overview_screen.dart`)
- In the `onLogSet` callbacks (single at ~L759, superset at ~L894), after
  dispatching `WorkoutOverviewSetLogged`, show the UNDO snackbar referencing the
  just-logged set. Use `ScaffoldMessenger`; keep duration short (~4s).
- No layout changes needed in the screen itself; the card got shorter.

### 5. Cleanup
- Remove now-dead code paths in `set_row.dart` tied to the always-on editor /
  LOG SET button. Don't leave `// removed` comments or unused `_var`s.
- Confirm `exercise_card.dart` `_ExpandedBody` and `superset_card.dart` need no
  changes (they pass through `SetRow`); verify after the edit.

## Ergonomics / token compliance (mandatory)

- Circle tap target ≥56dp (aim 64dp) — `workout_overview/` is a sweaty-hands
  module. No hard-coded colors/pixels; use `appColors`, `AppSpacing`,
  `AppRadius`. Numeric values use `numeric`/`numericLarge`. Primary actions keep
  `actionLabel` typography.

## Tests & verification

- Test scope here is **domain + persistence only** (per CLAUDE.md) — no
  widget/bloc tests. The bloc change (undo event) can be covered if an existing
  bloc test harness exists; otherwise rely on engine tests already covering
  `deleteExecutedSet`.
- This is a UI change, so **verify in the running app** (the `verify`/`run`
  skills or `mcp__dart__*`): on-plan quick-log (one tap logs correct value),
  undo removes it, deviation path (tap row → edit → confirm) records the changed
  value, superset members behave identically, completed-row edit still works,
  session-ended state disables logging.
- Run `tool/ci.sh` (imports → codegen → format → analyze → test) before done.

## Out of scope / risks

- Persisting coach-mark / onboarding for the new circle gesture — discoverability
  may need a one-time hint (the screen already has a coach-mark mechanism;
  per-process `static bool`, persistence deferred). Consider a short tip the
  first time a loggable circle is shown.
- If Option B is chosen later, step 3's inline editor reveal is replaced by Focus
  navigation; undo still applies to the quick-log.

## product-context.md

The workout-overview feature description mentions "expandable for inline set
logging." After this change, update that line to reflect tap-to-log + opt-in
deviation editing (user-facing behavior changed). Single-edit, same change set.
