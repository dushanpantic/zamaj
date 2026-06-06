# Plan: Post-session set correction (v1)

**Created**: 2026-06-06
**Branch**: master
**Status**: implemented

## Goal

Let the lifter correct a mis-logged set's **actual values** (weight × reps, duration, or
bodyweight reps) from the session detail review screen — but only on sessions in the
**current week** (the same Mon–Sun window the recent-sessions list already buckets as
"This week"), which maps to the end-of-week coach-report deadline. This delivers on
product pillar 1 (planned vs. actual are first-class) by making the "actual" column a
faithful, correctable record. It is the deliberate, *narrow* softening of immutability that
[product-context.md](product-context.md) already anticipates — values-only, never adding or
removing sets, and never touching the frozen plan snapshot.

The domain layer already permits this: `SessionFlowEngine.updateExecutedSet`
([session_flow_engine.dart:347](mobile/lib/modules/domain/services/session_flow_engine.dart#L347))
has **no `endedAt` guard**, unlike `completeSet`/`deleteExecutedSet`. So no domain, engine, or
schema change is needed for the mutation itself — the work is a reactive bloc, an
in-week affordance gate, and a calm bottom-sheet editor, all inside the `export/` module.

## Acceptance Criteria

- [ ] On a session whose `endedAt` is in the current Mon–Sun week, tapping a logged set's actual-value cell opens a bottom-sheet editor seeded with that set's current actual values.
- [ ] Saving an edit persists the new actual values via `SessionFlowEngine.updateExecutedSet`; the detail screen re-renders with the corrected actual value with no manual refresh.
- [ ] The planned column is never changed by an edit — only `ExecutedSet.actualValues` changes; the snapshot stays frozen.
- [ ] Sessions outside the current week show **no** edit affordance — the screen reads exactly as it does today (pure read-only).
- [ ] Set lines with no logged set (skipped / unfinished planned sets, `executedSet == null`) are never editable, even in-week.
- [ ] No path on the detail screen can add or delete a set; the engine's `completeSet`/`deleteExecutedSet` immutability guards are untouched.
- [ ] A one-time coach-mark ("Tap a logged value to fix it") appears on first open of an in-week editable session detail (per-process `static bool`, no `shared_preferences`), and not on subsequent opens that process.
- [ ] Editing an executed set's values on an **ended** session is covered by a domain/persistence test that locks the no-guard behavior.
- [ ] [product-context.md](product-context.md) reflects the shipped capability (line 18 "not yet built" removed; line 44 no longer describes the session detail as purely read-only).
- [ ] `tool/ci.sh` passes (offline-import guard → codegen → format → analyze → test); no Drift/`AppDatabase` leak into the `export/` UI.

## User-Facing Behavior

> No `/specs` artifacts exist for this task (we deliberately chose `/plan` over `/specs`).
> These scenarios are authored here as the behavioral contract; each Step traces to one or more.

```gherkin
Feature: Correct a mis-logged set after a session

  Background:
    Given a completed session that ended earlier this week
    And the session detail screen is open

  Scenario: Edit a logged set's actual values
    When I tap the actual value of a logged set
    Then a bottom-sheet editor opens seeded with that set's current actual values
    When I change the value and tap SAVE
    Then the set's actual value updates on the detail screen
    And the planned value for that set is unchanged

  Scenario: Skipped and unfinished sets are not editable
    When I view a set line that has no logged value
    Then it shows no edit affordance and does not respond to taps

  Scenario: Out-of-week sessions are locked
    Given a completed session that ended in a previous week
    When the session detail screen is open
    Then no set line responds to taps
    And the screen reads exactly as a read-only review

  Scenario: Cannot add or remove sets
    When I review a completed session this week
    Then there is no control to add a set or delete a logged set

  Scenario: First-time discovery hint
    Given I have not yet seen the correction hint this app session
    When I open an editable in-week session detail
    Then a one-time coach-mark explains that tapping a logged value edits it
    And it does not reappear on the next editable detail I open this app session
```

## Steps

### Step 1: Lock the "edit ended-session values persists" behavior with a test

**Complexity**: standard
**RED**: Add a test (persistence/integration, e.g. under `test/integration/` using `makeInMemoryDatabase()`, and/or `test/domain/` for the engine) that: starts a session, logs a set, ends the session, then calls `SessionFlowEngine.updateExecutedSet` (and/or `SessionRepository.updateExecutedSet`) on that ended session and asserts the actual values are updated and persisted — and that **no** `ImmutabilityError` is thrown. Written to fail if anyone later adds an `endedAt` guard to the update path.
**GREEN**: Expected to pass as-is (no guard exists). If the existing engine/assembler path trips on an ended session, fix minimally without adding an immutability guard.
**REFACTOR**: None expected.
**Files**: `mobile/test/integration/*` and/or `mobile/test/domain/services/session_flow_engine_*_test.dart`
**Commit**: `test(session): lock value edit on ended session against future regression`

### Step 2: Pure in-week editability helper

**Complexity**: standard
**RED**: Add a test (in `test/` mirroring `export/services`, following the existing `SessionHistoryAssembler` snapshot-test precedent) for a pure helper `SessionEditability.canEditValues(session, window)` (or equivalent) returning `true` only when `session.endedAt != null && window.contains(session.endedAt!)`. Cover: in-week ended, out-of-week ended, and (defensively) null `endedAt`.
**GREEN**: Implement the pure helper in `lib/modules/export/services/`.
**REFACTOR**: Reuse `CurrentWeekWindow` rather than recomputing week math.
**Files**: `mobile/lib/modules/export/services/session_editability.dart`, `mobile/test/.../session_editability_test.dart`
**Commit**: `feat(export): add in-week set-edit editability helper`

### Step 3: Reactive SessionDetailBloc (read via watchSession, write via engine)

**Complexity**: complex
**RED**: N/A for automated tests — CLAUDE.md scopes tests to domain + persistence and forbids `bloc_test`. Verification is `dart analyze` + the Step 2 helper test + manual visual validation by the user. (The testable seam — editability — is covered in Step 2.)
**GREEN**: Add `SessionDetailBloc` + event/state to `lib/modules/export/bloc/`. Constructor takes the already-hydrated `Session` (for instant first paint, no loading flash), `SessionRepository`, `SessionFlowEngine`, and `Clock`. On create: compute `canEdit` once via `SessionEditability` + `CurrentWeekWindow.compute(clock.now())`, emit a loaded state immediately from the seed session, then subscribe to `SessionRepository.watchSession(session.id)` and re-emit on each change. Add a `SetValueEdited(executedSetId, ActualSetValues)` event that calls `SessionFlowEngine.updateExecutedSet` (the `watchSession` stream re-emits the fresh `Session`; the returned `SessionState` is discarded). State carries the assembled read-only groups (`ExerciseViewModelAssembler.assembleReadOnly`) and `canEdit`. Wire `_sessionDetailRoute` in [export_router.dart](mobile/lib/modules/export/navigation/export_router.dart) to provide the bloc via `BlocProvider`, reading the engine/repo/clock from context. Convert `SessionDetailScreen` to a `BlocBuilder` consumer. **No visible behavior change yet** — still renders read-only.
**REFACTOR**: Export the new bloc from the `export.dart` barrel; keep `SessionDetailArgs` as-is (`session.id` supplies the watch key).
**Files**: `mobile/lib/modules/export/bloc/session_detail_bloc.dart` (+ event/state, + `bloc.dart`/`export.dart` barrels), `mobile/lib/modules/export/navigation/export_router.dart`, `mobile/lib/modules/export/screens/session_detail_screen.dart`
**Commit**: `feat(export): make session detail reactive via SessionDetailBloc`

### Step 4: Bottom-sheet set-value editor at normal density

**Complexity**: complex
**RED**: N/A automated (UI widget; widget tests excluded by CLAUDE.md). If the text↔`ActualSetValues` parse/seed logic is extracted as a pure mapper, add a focused unit test for it where the layout allows it to be tested; otherwise verify by `dart analyze` + manual validation.
**GREEN**: Build a `SetValueEditorSheet` in `lib/modules/export/widgets/` — a modal bottom sheet, measurement-type-aware (rep-based / time-based / bodyweight), seeded with the current `ActualSetValues`, returning a new `ActualSetValues` on SAVE. Use **normal 48 dp** tap targets (`AppSpacing.touchMin`) and standard typography — this is the `export/` review surface, **not** the 64 dp `AppInSessionSize` sweaty-hands surface. Reuse `SetValueFormatter` for any display and mirror the parse/round semantics from [set_row.dart](mobile/lib/modules/workout_overview/widgets/set_row.dart) `_readValues`/`_seedFromViewModel` (half-kg rounding, non-negative). Do **not** import or resize the in-session `_Editor`/`_StepButton`.
**REFACTOR**: To avoid duplicating the parse/seed logic, prefer extracting a small pure mapper shared by the sheet (and optionally `set_row.dart` later). If extraction into the in-session widget proves invasive, keep the mapper self-contained in `export/` and note the duplication for `/code-review` (semantic-duplication / refactor-opportunity reviewers).
**Files**: `mobile/lib/modules/export/widgets/set_value_editor_sheet.dart` (+ optional pure mapper + its test)
**Commit**: `feat(export): add post-session set-value editor sheet`

### Step 5: Make in-week logged set lines tappable → open the sheet

**Complexity**: standard
**RED**: N/A automated (UI). Verified by `dart analyze` + manual validation against the Gherkin scenarios.
**GREEN**: Thread `canEdit` from `SessionDetailBloc` state through `SessionDetailGroupCard` → `_Exercise` → `_SetLine` in [session_detail_exercise_card.dart](mobile/lib/modules/export/widgets/session_detail_exercise_card.dart). When `canEdit && row.executedSet != null`, wrap the actual-value cell in an `InkWell` (≥48 dp hit target) that opens `SetValueEditorSheet` seeded from `row.executedSet!.actualValues`; on SAVE, dispatch `SetValueEdited(row.executedSet!.id, newValues)`. All other rows stay inert. Add a subtle affordance cue on editable cells (consistent with existing tokens).
**REFACTOR**: Keep `_SetLine` a `StatelessWidget`; pass an `onEdit` callback down rather than reaching for the bloc inside the leaf widget.
**Files**: `mobile/lib/modules/export/widgets/session_detail_exercise_card.dart`, `mobile/lib/modules/export/screens/session_detail_screen.dart`
**Commit**: `feat(export): tap a logged set this week to correct its values`

### Step 6: One-time discovery coach-mark

**Complexity**: standard
**RED**: N/A automated (UI). Verified by manual validation: appears on first editable open, absent on the next.
**GREEN**: Add a per-process `static bool` flag (matching the project coach-mark cadence) that shows a one-time hint ("Tap a logged value to fix it") the first time an editable (in-week) session detail is opened in this app process. No `shared_preferences` (deferred per the existing cross-screen refactor note).
**REFACTOR**: Mirror the existing coach-mark presentation widget/tokens rather than inventing a new style.
**Files**: `mobile/lib/modules/export/screens/session_detail_screen.dart` (+ existing coach-mark building block if one is shared)
**Commit**: `feat(export): one-time hint for post-session set correction`

### Step 7: Update product-context.md

**Complexity**: trivial
**RED**: N/A (docs).
**GREEN**: Update [product-context.md](product-context.md): remove the "not yet built" qualifier on line 18 and state that in-week entries are correctable; revise line 44 so the session detail is no longer described as purely "Read-only" (e.g. "review … with in-week correction of mis-logged values").
**REFACTOR**: Keep it current-state only (no roadmap), per the product-context scope rule.
**Files**: `product-context.md`
**Commit**: `docs: note in-week post-session set correction`

## Complexity Classification

| Step | Rating | Why |
|------|--------|-----|
| 1 | standard | Behavioral lock test in the tested domain/persistence scope |
| 2 | standard | New pure helper + test within an existing pattern |
| 3 | complex | New bloc + reactive wiring; bends "blocs depend on engine for session flow"; cross-file |
| 4 | complex | New UI abstraction + reuse-vs-duplication decision for value parse/seed |
| 5 | standard | Affordance wiring within existing widgets |
| 6 | standard | Coach-mark within an existing pattern |
| 7 | trivial | Documentation only |

## Pre-PR Quality Gate

- [x] All tests pass (`tool/ci.sh`) — 678 passed
- [x] `dart analyze` clean
- [x] `dart format` clean
- [x] `tool/check_offline_imports.sh` passes (no Drift/`AppDatabase`/networking leak into `export/`)
- [~] `/code-review` — inline per-step + final holistic review done (see build output); full agent suite available on request
- [x] product-context.md updated (Step 7)
- [ ] User has visually validated the edit flow (visual validation is the user's)

## Risks & Open Questions

- **Thin automated coverage by design.** CLAUDE.md restricts tests to domain + persistence (no `bloc_test`, no widget tests). The mutation already lives in the engine, so most net-new code (bloc, sheet, affordance, coach-mark) ships verified only by `dart analyze` + the user's manual validation. Steps 1–2 carry the only meaningful automated tests. *Mitigation*: keep logic out of widgets (pure editability helper, pure value mapper) so the testable seams are real.
- **Architecture bend (accepted in interrogation).** `SessionDetailBloc` reads via `SessionRepository.watchSession` while writing via `SessionFlowEngine`. This stretches CLAUDE.md's "UI blocs depend on the engine for session flow," justified because a post-session review is not session flow and `assembleReadOnly` already lives in the UI layer. *Alternative if a reviewer objects:* add a read-only `watchSession`-shaped method to the engine.
- **Week-rollover lock is silent.** A session flips from editable to locked exactly when it crosses the Mon–Sun boundary — consistent with the existing "This week"/"Earlier" bucketing the user already sees, but it can lock between visits. Accepted.
- **Parse/seed duplication.** Step 4 risks re-implementing set_row.dart's measurement-type parse/round logic. *Mitigation*: extract a shared pure mapper if non-invasive; otherwise flag for `/code-review`.
- **Offline-import guard on `export/`.** The new bloc must touch data only through domain contracts (`SessionRepository`, `SessionFlowEngine`) — never Drift/`AppDatabase`. `tool/check_offline_imports.sh` enforces this; keep imports clean.

## Plan Review Summary

_Pending — see chat for the inline four-lens review; formal parallel persona review available on request._

## Build Progress

### Steps

- [x] Step 1: Lock "edit ended-session values persists" with a test
- [x] Step 2: Pure in-week editability helper
- [x] Step 3: Reactive SessionDetailBloc (read via watchSession, write via engine)
- [x] Step 4: Bottom-sheet set-value editor at normal density
- [x] Step 5: Make in-week logged set lines tappable → open the sheet
- [x] Step 6: One-time discovery coach-mark
- [x] Step 7: Update product-context.md

### Acceptance Criteria

- [x] Tapping a logged set this week opens an editor seeded with current actual values
- [x] Saving persists via `updateExecutedSet` and re-renders without manual refresh
- [x] Planned column / snapshot never changes on edit
- [x] Out-of-week sessions show no edit affordance (pure read-only)
- [x] `executedSet == null` rows are never editable
- [x] No add/delete of sets; engine immutability guards untouched
- [x] One-time coach-mark on first in-week editable open (per-process)
- [x] Domain/persistence test locks ended-session value-edit behavior
- [x] product-context.md updated to current state
- [x] `tool/ci.sh` + offline-import guard pass
