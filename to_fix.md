# Focus Mode & Workout Overview — Review Findings

Scope: `mobile/lib/modules/focus_mode/**`, `mobile/lib/modules/workout_overview/**`, their blocs,
widgets, services and models, cross-checked against `SessionFlowEngine` contracts.
Severity: 🔴 bug (user-visible or data-affecting) · 🟡 inconsistency / latent bug · 🔵 smell / cleanup.

---

## Status (2026-06-11)

**Replace exercise is being dropped from the UI/bloc** pending a redesign of how
it should behave. The domain/engine/persistence (`replaceExercise`,
`ReplacedState`, `SubstituteExercise`) stay intact and dormant — no new replaced
exercises can be created, but the machinery is ready to re-wire.

As a result the findings split into:

- **Planned now** (replace-independent) → `plans/focus-overview-behavioral-fixes.md`:
  findings **2, 3, 4, 6, 13, 14**.
- **Deferred — pending Replace redesign** (these are all `ReplacedState`
  artifacts that can't occur once Replace is gone): findings **1, 5, 7, 9, 10,
  12**, plus **Decisions 1 & 5** and the interrogation outcomes Q1 (skip &
  mark-done on replaced, both screens) / Q3 (type-changing replace strands sets)
  / Q6 (skip on a quota-met replaced). Revisit these when Replace is redesigned.
- **Out of scope** (unchanged): finding 8 (withdrawn), finding 11 (superset
  definition), 🔵 cleanup 17–26.

---

## 🔴 Bugs

### 1. Focus panel menu offers Skip / Replace on exercises the engine will reject
`focus_mode/widgets/focus_panel_actions_menu.dart:46-74` always lists **Replace exercise** and
**Skip exercise**, regardless of panel state. The engine asserts `UnfinishedState` for both
(`session_flow_engine.dart:715` `_assertUnfinished`) and throws `OrderingError` for `ReplacedState`
and `CompletedState` exercises. Focus mode renders panels for both (replaced panels are loggable;
completed panels keep the menu on previous/upcoming cards — the doc comment in
`focus_previous_panel_card.dart:14-18` even claims "replace / skip / mark-done work without
re-focusing first", which is wrong for completed/replaced states). Result: user taps Skip on a
replaced exercise → confirm dialog → engine throws → error banner. The overview gates these
correctly (`exercise_card.dart:539-540`).
**Fix:** gate the menu items the same way the overview does. `FocusModeViewModel` currently exposes
only `isReplaced`/`isLoggable` — it cannot distinguish `CompletedState` from
unfinished-with-all-sets-logged, so add the underlying state (or an `isUnfinished` flag) to the
view model.

### 2. Stale-drafts race in FocusModeBloc mutation handlers
`flutter_bloc` 9 (no `Bloc.transformer` override, no `bloc_concurrency`) processes events
**concurrently**. `_onSetCompleted` (`focus_mode_bloc.dart:470-523`) captures `current = state`
before `await _engine.completeSet(...)` and uses `current.drafts` *after* the await
(`_assembleAfterMutation(priorDrafts: current.drafts, ...)`). Any draft edit processed during the
await — e.g. bumping the weight on the *other* superset panel while LOG SET is in flight — is
silently reverted when the mutation lands. Same pattern in `_onUndoRequested`,
`_onExerciseSkipped`, `_onExerciseMarkedDone`, `_onExerciseReplaced`.
The overview bloc does this correctly (`workout_overview_bloc.dart:343` re-reads
`final latest = state` after the await).
**Fix:** re-read `state` after the await and merge its drafts, and/or register the mutation
handlers with a `sequential()`/`droppable()` transformer. (Related: `_runMutation`'s
`mutationInFlight` guard reads state at handler start, so two adds in the same microtask window
can both pass — a sequential transformer addresses this too.)

### 3. Logging one superset panel kills a running countdown on another panel and leaks the ticker
`_onSetCompleted` stops the stopwatch ticker only when
`current.activeStopwatchExerciseId == event.sessionExerciseId` (`focus_mode_bloc.dart:481-484`),
but `_assembleAfterMutation` *always* returns a fresh state with `stopwatch: idle` and
`activeStopwatchExerciseId: null` (`focus_mode_bloc.dart:867-877`). So a countdown running on
panel B is silently reset when a set is logged on panel A — and the periodic `Timer` keeps firing
`FocusModeStopwatchTicked` no-ops forever (handler returns early on `!isRunning`) until another
stopwatch starts or the bloc closes. The fallback path in `_reassembleAfterRefresh` →
`_assembleFromSessionState` resets stopwatch state without stopping the ticker either.
**Fix:** either preserve the running stopwatch across unrelated mutations, or stop the ticker
whenever the new state's stopwatch is idle.

### 4. Time-based focus panel hardcodes ±2.5 kg, violating the shared step policy
`core/increment_rules.dart` declares itself "the single source of truth … so the two stepper
presentations can never drift apart" (±1 at ≤ 10 kg, ±2.5 above). The set-row stepper and
`FocusRepBasedPanel` use `IncrementRules.weightSteps`. `FocusTimeBasedPanel` hardcodes
`onWeightBump(-2.5)` / `(2.5)` and literal `'-2.5'`/`'+2.5'` labels
(`focus_time_based_panel.dart:303,314,352,362`). A 5 kg weighted dead-hang bumps ±2.5 in focus mode
but ±1 in the overview editor. The ±5 duration steps are also re-listed as literals instead of
`IncrementRules.durationSteps`.

### 5. Overview quick-log can submit values of the wrong measurement type after a replace
`exercise_view_model_assembler.dart:157-159` sets
`suggestedActualValues: executed.last.actualValues` with no measurement-type check. After
replacing a rep-based exercise (with sets already logged) with a time-based substitute, the
loggable row's one-tap circle (`set_row.dart:177-188 _quickLogValues`) submits the old
`ActualRepBased` values against a time-based exercise → engine `ValidationError` → error banner.
The focus bloc guards exactly this with `_matches(...)` (`focus_mode_bloc.dart:900-934`); the
assembler should too. (Related: pre-replace executed sets render/edit against the substitute's
measurement type in `SetRow`; `SetValueInputMapper.seed` degrades to zeros, and saving would
rewrite a historical set under the new type.)

### 6. A failed undo permanently loses the undo affordance
`_onUndoRequested` clears `undoable` optimistically (`focus_mode_bloc.dart:538`), but the
`DomainError` catch restores only `mutationInFlight`, not `undoable`. A transient failure leaves
the set logged with no way to retry the undo from focus mode.

---

## 🟡 Inconsistencies / latent bugs

### 7. Replaced exercises are dead ends
Engine + overview UI agree that a `ReplacedState` exercise cannot be skipped, re-replaced, or
marked done (`_assertUnfinished`; `exercise_card.dart:539-540` + `canMarkDone` at
`exercise_card.dart:149`). Its only path to terminal is logging **all** substitute sets, so a
user who can't finish a replaced exercise can never reach `isComplete == true` for the session.
Focus mode pretends otherwise (finding 1). Decide the product rule (probably: allow skip on
replaced) and align engine + both UIs.

### 8. ~~"Mark done" gating contradicts itself between the two screens~~ (withdrawn — see note)
**Correction after deeper verification:** the repository auto-completes an unfinished exercise the
moment its logged count reaches the planned count
(`drift_session_repository.dart:398-408`), and `deleteExecutedSet` reverts it. An
"unfinished exercise with all sets logged" therefore cannot persist, and the two screens' gates
(`exercise_card.dart:149` vs `focus_panel_actions_menu.dart:30-31`) are equivalent in practice.
Only the replaced-exercise difference remains, and that is resolved by the decision on finding 7
(see Decisions below).

### 9. App-bar progress counts an unfinished replaced exercise as "done"
`workout_overview_app_bar_title.dart:61`: `done = state is! UnfinishedState`. A replaced exercise
with zero substitute sets logged counts as done — inconsistent with
`SessionFlowEngine.isSessionComplete`, which requires all substitute sets logged.

### 10. CURRENT-chip resolution diverges from openTargets
`workout_overview_screen.dart:254-258` marks every `UnfinishedState` member of the anchor group as
current — including fully-logged members with no open target — and *excludes* loggable
`ReplacedState` members (which focus mode happily pairs in the superset rotation). Should be
derived from `openTargets` membership like everything else.

### 11. Superset "group" definitions differ: tag-based vs contiguity-based
The overview bloc keys the active group by `supersetTag` across the whole session
(`workout_overview_bloc.dart:426-453`), while both assemblers
(`exercise_view_model_assembler.dart:81-113`, `focus_mode_assembler.dart:237-258`) group only
*contiguous* runs of the same tag. The engine keeps members contiguous today, so this is latent —
but if positions ever interleave, expansion/current logic and rendering disagree silently.
Pick one definition (a shared helper) for all three.

### 12. "Up next" label can point at a group that has nothing to log
`FocusModeAssembler._findNextGroup` treats `Unfinished || Replaced` *state* as actionable
(`focus_mode_assembler.dart:270-277`) without checking `executedSets < plannedSetCount`, while
`findNextAnchorAfter` uses `openTargets`. **Scope correction:** because the repository
auto-completes unfinished exercises at quota, this only bites for `ReplacedState` exercises with
all substitute sets logged — they still count as "actionable" for the label while the
auto-advance path correctly skips them. Fix by checking quota (or `openTargets`) like
`findNextAnchorAfter` does.

### 13. Errors on the workout-complete screen are silently swallowed
`_onSessionFailed` attaches `lastTransientError` to `FocusModeWorkoutComplete`
(`focus_mode_bloc.dart:190-196`) and `_onErrorDismissed` can clear it — but
`FocusWorkoutCompleteView` never renders a banner, so that whole path is dead UI.

### 14. Ended-session copy promises in-place editing the overview doesn't provide
End-session dialog: "You can still edit completed sets…" (`workout_overview_screen.dart:165`);
banner: "Completed sets remain editable." (`session_ended_banner.dart:41`). But
`canMutate = !state.isEnded` (`workout_overview_loaded_body.dart:162`) disables all `SetRow`
editing once ended. Post-session editing actually lives in the export module's session-detail
screen. Either allow `updateExecutedSet` from the ended overview (the engine permits it — it has
no `endedAt` check) or reword the copy to point at the right place.

### 15. Stale "drag-to-ungroup" comments describe a feature that doesn't exist
`drop_resolver.dart:82-83` and `draggable_exercise.dart:77-81` say "Drag-to-ungroup remains the
supported flow for leaving a superset", but every drop target rejects payloads with
`supersetTag != null` (top-level gaps, onto-card, superset append target), and intra-group gaps
only reorder. The only ungroup affordance is the header button, which ungroups the *whole* group.

### 16. `UndoableSet` doc describes a transient SnackBar; reality is a persistent row
`undoable_set.dart:3-7` says it "surfaces … for one transient window so the UI can render a
SnackBar". The implementation is a persistent bottom-bar row that survives until the next mutation
or group switch — undo of an arbitrarily old set stays available. Update the doc (or add the
intended expiry).

---

## 🔵 Smells / cleanup

17. **Dead code:** `FocusModeColors` (`focus_rep_based_panel.dart:282-286`) is never used;
    `MoveTargets.hasAny` (`reorder_move_resolver.dart:22`) is never referenced; the
    `isDropTarget` parameters on `ExerciseCard` and `SupersetCard` are never passed by any caller
    in this module.
18. **Tap-to-collapse trap in `SetRow`:** the row-level `InkWell` wraps the *open* editor
    (`set_row.dart:281-288`), so taps on editor padding/gaps collapse it — easy mis-tap with wet
    hands right where the design is supposed to be most forgiving.
19. **Duplicated logic:**
    - `_formatMmss` in `focus_time_based_panel.dart:386` and `focus_rest_timer_bar.dart:81`;
    - `_BigNumericField` / `_BumpRow` duplicated between `focus_rep_based_panel.dart` and
      `focus_bodyweight_panel.dart`;
    - `FocusModeAssembler._summarizePlanned` is a byte-for-byte copy of
      `PlannedSummaryFormatter.summarize`;
    - half-kg rounding `(x * 2).round() / 2` re-implemented in three places
      (`focus_mode_bloc.dart:304`, `IncrementRules.bumpWeight`, `SetValueInputMapper._roundHalfKg`).
20. **Duplicated drag-hover plumbing:** the `_registered` + post-frame `_setRegistered` pattern is
    copy-pasted across `reorder_gap.dart`, `superset_reorder_gap.dart`, `superset_drop_target.dart`
    and `draggable_exercise.dart` — extract a mixin/helper.
21. **Token violations:** `focus_video_button.dart:34` hardcodes `iconSize: 28` (use
    `AppIconSize.*`); `superset_card.dart:104` hardcodes border `width: isDropTarget ? 2 : 1`
    (use `AppStroke.emphasis`/`hairline` like `exercise_card.dart` does).
22. **Deep cross-module imports bypass the barrel rule** (CLAUDE.md): focus_mode imports
    `workout_overview/widgets/replace_exercise_dialog.dart`; both modules deep-import
    `program_management/services/domain_error_presenter.dart` and `external_link_launcher.dart`;
    the replace dialog deep-imports `exercise_library/widgets/library_picker_sheet.dart`. A shared
    error presenter / link launcher living inside `program_management` is also misplaced — they
    belong in `core/` or `building_blocks/`.
23. **`SessionElapsedLabel` uses `DateTime.now()` directly** (`session_elapsed_label.dart:60`)
    instead of the injected `Clock` the rest of the app uses — untestable drift vs `startedAt`.
24. **Replace dialog seeds fields for the wrong measurement type** when the library pick differs
    from the original exercise: `_seedFieldsFor(widget.defaultPlannedValues)`
    (`replace_exercise_dialog.dart:193`) seeds by the runtime type of the *original* planned
    values, leaving e.g. the duration field empty and a stale weight value when switching
    rep-based → time-based. Cosmetic (submit stays disabled until valid), but confusing.
25. **Stopwatch start isn't gated on `mutationInFlight`/`isLoggable`**
    (`focus_mode_bloc.dart:369-388`) — a countdown can start on a panel while a mutation is in
    flight or on a panel whose quota is already met. Harmless today, but inconsistent with every
    other interaction on the screen.
26. **Double-commit on numeric fields:** keyboard "done" fires `onSubmitted` *and* the focus-loss
    listener commit (`focus_rep_based_panel.dart`, `focus_time_based_panel.dart`,
    `focus_bodyweight_panel.dart`). Benign only because state equality dedupes the second emit.

---

## Decisions (design interrogation, 2026-06-11)

1. **Replaced exercises (findings 1, 7):** allow **Skip** and **Mark done** on `ReplacedState`;
   re-replace stays disallowed. Mark done preserves provenance by shrinking
   `substitute.setCount` to the logged count (terminal under the existing
   "replaced with all substitute sets logged" rule — no schema change). Skip transitions to
   `SkippedState`. Engine `_assertUnfinished` call sites for skip/markDone relax to
   unfinished-or-replaced; focus menu gates Replace to unfinished only. `FocusModeViewModel`
   needs the underlying state (or an `isUnfinished` flag) to gate correctly.
2. **Stopwatch vs mutations (finding 3):** make the reset *intentional* — any engine mutation
   stops the countdown **and** the ticker (fixing the leak). One live timing concern at a time.
3. **Undo (findings 6, 16):** keep the persistent until-next-mutation behavior; fix the
   `UndoableSet` doc comment; restore `undoable` when the undo mutation fails.
4. **Ended-session editing (finding 14):** split `canMutate` into `canLog` (false once ended)
   and `canEditExecuted` (true after end). Ended overview allows editing completed sets;
   logging, reorder, skip, replace, notes stay disabled. Copy stays as written.
5. **Pre-replace executed sets after a type-changing replace (finding 5):** render read-only
   when the executed set's actual-values type ≠ current effective measurement type (UI gating
   only). Quick-log suggestion falls back to planned-as-actual on type mismatch, mirroring the
   focus bloc's `_matches` guard.
6. **Draft race (finding 2, technical):** keep the `mutationInFlight` drop semantics
   (double-tap protection); fix the stale read by re-reading `state` after each engine await
   (the overview bloc's existing pattern). Do **not** switch mutations to a `sequential()`
   transformer — queuing a second LOG SET tapped mid-flight would double-log.

---

## Decisions update (interrogation 2, 2026-06-11 — Replace dropped)

Headline: **Replace exercise is dropped from the UI/bloc pending a redesign.**
The domain/engine/persistence stay intact and dormant (no schema/migration
change). This supersedes the disposition of every replace-coupled item above.
Shipped work → `plans/focus-overview-behavioral-fixes.md` (status: approved).

Status of the first-pass decisions, plus new outcomes:

1. **Replaced skip / mark-done (D1, findings 1, 7) — ⏸️ DEFERRED.** No replaced
   exercises can exist once Replace leaves the UI, so the bug can't occur. When
   Replace is redesigned, apply these resolutions:
   - **Both screens** offer Skip + Mark done on replaced (Q1) — not focus-only.
   - **Skip** stays unconditional for *unfinished* (the escape hatch, incl. the
     zero-set trap exercise); for *replaced* it shows only while sets remain to
     log. **Mark done** requires partial progress (`0 < logged < setCount`); at
     quota a replaced exercise is already complete (Q6).
   - Mark done shrinks `substitute.setCount` to the logged count (≥ 1; reject at
     0 — `SubstituteExercise.setCount` must be ≥ 1). Re-replace stays disallowed.
2. **Stopwatch vs mutations (D2, finding 3) — ✅ ACTIVE, strengthened.** Any
   engine mutation stops the countdown + ticker. Implement as the invariant
   *ticker runs iff emitted `stopwatch.isRunning`* so the refresh-fallback path
   can't orphan a `Timer` either. No preserve-across-refresh nuance — a logged
   set means the user moved on (Q4). → Slice 2.2.
3. **Undo (D3, findings 6, 16) — ✅ ACTIVE.** Restore `undoable` when the undo
   mutation fails; keep the persistent-until-next-mutation behavior; fix the
   `UndoableSet` doc. → Slice 2.3.
4. **Ended-session editing (D4, finding 14) — ✅ ACTIVE, confirmed.** Split
   `canMutate` into `canLog` (false once ended) and `canEditExecuted` (true).
   Confirmed option A: enable value edits on the ended overview rather than
   rewording the copy toward the export screen (Q5). → Slice 5.
5. **Pre-replace executed sets after a type-changing replace (D5, finding 5) —
   ⏸️ DEFERRED.** Resolution for when Replace returns: type-mismatched executed
   sets render **inert read-only** — no inline edit, and **no new delete
   affordance** (none exists anywhere today; the overview has no per-set delete).
   They still count toward quota, so they never block completion (Q3).
6. **Draft race (D6, finding 2) — ✅ ACTIVE.** Re-read `state` after each engine
   await and merge its drafts; keep the `mutationInFlight` drop guard; no
   `sequential()` transformer. → Slice 2.1.
7. **Completion logic home (new, finding 9) — ⏸️ DEFERRED with Replace.**
   Finding 9 evaporates without replaced state (`state is! UnfinishedState` is
   already correct then). When it resurfaces, the agreed home is a pure
   `SessionExercise.isComplete` getter (`Completed||Skipped → true`;
   `Replaced → logged >= setCount`; `Unfinished → false`) with
   `Session.isComplete = sessionExercises.every((e) => e.isComplete)` and the
   engine delegating — one canonical definition shared by completion + the
   progress counter (Q2). CURRENT-chip / up-next keep using `openTargets`.

Also deferred with Replace: findings **7, 10, 12** (all `ReplacedState`
artifacts). Out of scope, unchanged: **8** (withdrawn), **11**, 🔵 **17–26**.
