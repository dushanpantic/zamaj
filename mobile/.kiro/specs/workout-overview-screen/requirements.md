# Requirements Document

## Introduction

The **workout-overview-screen** is the editable workspace the athlete
sees once a Session is active. It is the destination of the
`workout-day-picker`'s "Start" / "Resume" affordance and the entry
point to the future `focus-mode-screen`. It exposes the entire Session
structure — every exercise, every set, every note — in a compact,
scrollable, editable surface that survives backgrounding, supports
manual logging when the phone was offline, and lets the athlete reshape
the remaining workout (reorder, supersets, replacements, skips,
notes, extra work, end-session) without leaving the screen.

The feature covers:

- A screen that loads a Session by id through `SessionFlowEngine`,
  renders one tile per `SessionExercise` in template position order,
  visually distinguishes Exercise States (`unfinished` / `completed` /
  `skipped` / `replaced`), shows planned vs actual side by side per set,
  and surfaces the engine's `Cursor` as the "next-up" marker.
- Inline expansion: tapping an exercise tile expands a per-exercise
  detail panel showing every set (planned + actual), the substitute
  (when replaced), notes/video metadata from the snapshot, and the
  per-exercise actions (skip, replace, ungroup, log set, edit set).
- Long-press drag reorder constrained to `unfinished` exercises;
  completed/skipped/replaced exercises are locked at their template
  positions per the engine's `reorderUnfinished` semantics.
- Drag-onto-target superset creation: dropping one unfinished exercise
  on top of another triggers `SessionFlowEngine.createSuperset`. Drops
  between two tiles trigger `reorderUnfinished` instead. Existing
  supersets render with a shared visual frame.
- Superset removal through a per-superset context-menu action that
  calls `SessionFlowEngine.removeSuperset`.
- Exercise replacement through a per-exercise dialog that captures a
  substitute name and `MeasurementType`, then delegates to
  `SessionFlowEngine.replaceExercise`.
- Exercise skipping through a per-exercise action calling
  `SessionFlowEngine.skipExercise`.
- Manual set logging through the expanded panel for any unfinished or
  replaced exercise that still has sets remaining; delegates to
  `SessionFlowEngine.completeSet`.
- Editing values of a previously completed set via the same panel;
  delegates to `SessionFlowEngine.updateExecutedSet`. Editing remains
  available regardless of the parent exercise's state, per engine
  semantics.
- A session-level notes section with an "Add note" affordance backed
  by `SessionFlowEngine.addSessionNote`.
- A session-level extra-work section with an "Add extra work"
  affordance backed by `SessionFlowEngine.addExtraWork`.
- An "End session" overflow action backed by
  `SessionFlowEngine.endSession`. After end, the session becomes
  read-only for new mutations but editing of historical values is
  still allowed per engine semantics.
- A primary "Focus" call-to-action that pushes a new
  `SessionRoutes.focus` route with the `sessionId`. Until
  `focus-mode-screen` lands, this route is bound to a placeholder; the
  binding is replaced wholesale by that spec.
- A dedicated session-level loading, error, and not-found surface
  consistent with the rest of the app.
- Refresh-on-return when control comes back from the focus-mode route.
- Re-binding `SessionRoutes.active` from
  `SessionActivePlaceholderScreen` (added by `workout-day-picker`) to
  `WorkoutOverviewScreen`.

The feature explicitly does NOT deliver:

- The `focus-mode-screen` itself, the rest timer, or any in-set
  execution UI (those are separate specs). The overview only **opens**
  the focus-mode route.
- Background survival, foreground notification, lock-screen timer
  controls, or cold-launch session resume — those live in the
  `rest-timer-and-background-survival` spec. This spec assumes the
  overview is reached by in-app navigation from the picker.
- Export to text (separate `export` spec).
- Editing the Workout Day template — replacements affect only the
  current Session, never the template.
- Calendar scheduling, cross-day analytics, PR celebrations, or any
  social/sharing feature.
- Multi-session aggregation (the screen always shows exactly one
  Session).

## Glossary

- **Workout_Overview_Module**: The Flutter feature module that owns
  every screen, BLoC, widget, value object, and service introduced by
  this spec. Lives under `lib/modules/workout_overview/` following the
  conventions in `init.md` and the prior UI specs.
- **Workout_Overview_Screen**: The single screen this spec
  introduces. Loads one `Session` by id and exposes every read and
  in-session mutation operation defined by the requirements below.
- **Workout_Overview_Args**: The typed navigation argument carrying
  the `String sessionId` whose Session the screen displays.
- **Session_Flow_Engine**: The service at
  `lib/modules/domain/services/session_flow_engine.dart`. The overview
  reads its `SessionState` and calls every mutation method through it;
  the overview never invokes `SessionRepository` mutation methods
  directly (mirrors the picker's R12 contract).
- **Session_State**: The value object at
  `lib/modules/domain/services/session_state.dart` bundling
  `Session`, `Cursor`, and an optional `ActualSetValues
  suggestedValues`.
- **Cursor**: The sealed value object at
  `lib/modules/domain/services/cursor.dart`: `Cursor.active(...)`
  points at the next unfinished set; `Cursor.completed()` indicates
  every exercise is in a terminal state.
- **Exercise_Tile**: One row of the Workout_Overview_Screen
  corresponding to one `SessionExercise`. Renders the exercise name,
  planned summary, actual progress (e.g. "3 / 4"), state badge, the
  cursor "next-up" marker when applicable, the inline expansion
  toggle, and the per-exercise actions.
- **Superset_Frame**: The visual grouping wrapper that renders a set
  of `SessionExercise`s sharing the same non-null `supersetTag` as a
  single bracketed unit. Carries a per-frame "Ungroup" affordance.
- **Set_Row**: One row inside an expanded Exercise_Tile representing
  one planned or executed set. Renders the planned values, the
  executed actual values when present, an in-line edit affordance
  for executed values, and a "Log set" affordance for the next
  unfinished set.
- **Suggested_Set_Values**: The `ActualSetValues` returned by
  `SessionFlowEngine.suggestValues` for the current cursor position.
  Used to pre-fill the manual log-set form.
- **Drag_Drop_Mode**: The interaction state entered by long-pressing
  an unfinished Exercise_Tile. While active, the dragged tile may be
  dropped between two other tiles (reorder) or directly on top of
  another unfinished tile (superset). On completion the BLoC
  dispatches the appropriate engine call.
- **Replacement_Dialog**: A modal that captures the substitute
  exercise name and `MeasurementType` and forwards them to
  `SessionFlowEngine.replaceExercise`.
- **Add_Note_Sheet**: A bottom-sheet text-entry surface forwarding the
  body to `SessionFlowEngine.addSessionNote`.
- **Add_Extra_Work_Sheet**: A bottom-sheet text-entry surface
  forwarding the body to `SessionFlowEngine.addExtraWork`.
- **Log_Set_Sheet**: A bottom-sheet form pre-filled with
  `Suggested_Set_Values`, forwarding the captured values to
  `SessionFlowEngine.completeSet`.
- **Edit_Set_Sheet**: A bottom-sheet form initialised from an existing
  `ExecutedSet`'s actual values, forwarding the captured values to
  `SessionFlowEngine.updateExecutedSet`.
- **End_Session_Confirmation**: A modal that confirms the user wants
  to end the Session before calling `SessionFlowEngine.endSession`.
- **Session_Active_Route**: The route name constant
  `SessionRoutes.active` (`'/session-active'`). Currently bound to
  `SessionActivePlaceholderScreen`; this spec re-binds it to
  `Workout_Overview_Screen`.
- **Focus_Mode_Route**: The new route name constant added by this
  spec — `SessionRoutes.focus` (`'/session-focus'`). Bound to a tiny
  placeholder until `focus-mode-screen` lands.
- **Offline_Device**: A device with no network connectivity at the
  moment of operation.
- **App_Clock**: The `Clock` instance from `package:clock` injected
  through composition. Anywhere the overview captures a "now" for
  display (e.g. relative date labels on notes/extra-work) it reads
  from this clock.

## Requirements

### Requirement 1: Session Load and Screen Layout

**User Story:** As an athlete who just tapped Start or Resume in the
picker, I want the overview to open on the right Session and lay out
the whole workout at a glance, so that I can scan it and start
working.

#### Acceptance Criteria

1. WHEN the Workout_Overview_Screen is opened with a Workout_Overview_Args carrying a sessionId that resolves to an existing Session through SessionFlowEngine.resumeSession, THE Workout_Overview_Module SHALL load the resulting Session_State and render the Workout Day's name (from `session.snapshot.workoutDay.name`) in the screen header alongside an absolute `YYYY-MM-DD` started-at label derived from `session.startedAt` in the device's local time zone.
2. THE Workout_Overview_Screen SHALL render exactly one Exercise_Tile per `SessionExercise` in the loaded Session, ordered ascending by `position`, where every consecutive run of `SessionExercise`s sharing the same non-null `supersetTag` value is wrapped in a single Superset_Frame whose internal order also follows ascending `position`.
3. WHILE the initial Session_Flow_Engine.resumeSession future is pending, THE Workout_Overview_Screen SHALL display a single screen-level loading surface and SHALL NOT render any Exercise_Tile.
4. IF Session_Flow_Engine.resumeSession throws a `NotFoundError`, THEN THE Workout_Overview_Screen SHALL display a not-found surface stating the Session could not be found, naming the sessionId verbatim, and offering a single back affordance.
5. IF Session_Flow_Engine.resumeSession throws or returns any typed `DomainError` other than `NotFoundError`, THEN THE Workout_Overview_Screen SHALL display a single screen-level error surface containing the typed `DomainError`'s `invariant` or `field` descriptor verbatim and a retry affordance that re-invokes the load.
6. THE Workout_Overview_Screen SHALL display the Workout Day's name verbatim in the screen header without truncation other than what the rendered text widget naturally enforces.
7. WHEN the loaded Session_State's `cursor` is `Cursor.completed`, THE Workout_Overview_Screen SHALL display a non-blocking "Session complete" indicator near the screen header AND SHALL still render every Exercise_Tile per AC 1.2 with their respective state visualisations.

### Requirement 2: Exercise Tile Display Rules

**User Story:** As a user scanning the list mid-workout, I want each
exercise to communicate its plan, its progress, and what state it is
in without me having to expand it, so that I can decide what to do
next at a glance.

#### Acceptance Criteria

1. WHEN an Exercise_Tile renders a `SessionExercise` whose `state` is `UnfinishedState` and whose `executedSets.length == 0`, THE Exercise_Tile SHALL display the exercise name from the snapshot, a planned-summary label derived from the snapshot's planned sets per Requirement 13, no progress label, and the per-exercise actions defined in Requirement 9.
2. WHEN an Exercise_Tile renders a `SessionExercise` whose `state` is `UnfinishedState` or `ReplacedState` with `executedSets.length > 0` and `executedSets.length` strictly less than the planned set count in the snapshot, THE Exercise_Tile SHALL display a progress label of the form "<executedCount> / <plannedCount> sets" using the literal `/` slash character with single spaces, where `executedCount = executedSets.length` and `plannedCount` is the planned set count for that exercise in the snapshot.
3. WHEN an Exercise_Tile renders a `SessionExercise` whose `state` is `CompletedState`, THE Exercise_Tile SHALL display a "Completed" badge using `appColors.exerciseCompleted` and SHALL render the exercise name and planned summary at the muted foreground color `appColors.onSurfaceMuted`.
4. WHEN an Exercise_Tile renders a `SessionExercise` whose `state` is `SkippedState`, THE Exercise_Tile SHALL display a "Skipped" badge using `appColors.exerciseSkipped` and SHALL render the exercise name and planned summary at `appColors.onSurfaceMuted`.
5. WHEN an Exercise_Tile renders a `SessionExercise` whose `state` is `ReplacedState`, THE Exercise_Tile SHALL display a "Replaced" badge using `appColors.exerciseReplaced` and SHALL display a secondary line "→ <substituteName>" identifying the substitute by the value of `state.substitute.name` verbatim, in addition to the original planned exercise name from the snapshot at `appColors.onSurfaceMuted`.
6. WHEN the loaded Session_State's `cursor` is `ActiveCursor` and its `sessionExerciseId` equals the rendered `SessionExercise`'s `id`, THE Exercise_Tile SHALL display a visually distinct "Up next" marker using a left-edge accent in `appColors.actual` AND SHALL display a secondary label "Set <n+1> of <plannedCount>" where `n` equals the `cursor.setIndex`.
7. WHEN an Exercise_Tile renders a `SessionExercise` whose `state` is `UnfinishedState` and a `supersetTag` is non-null, THE Exercise_Tile SHALL render inside its surrounding Superset_Frame and SHALL omit any standalone "Make superset" affordance.
8. WHEN an Exercise_Tile renders a `SessionExercise` whose `supersetTag` is null AND whose `state` is `UnfinishedState`, THE Exercise_Tile SHALL be eligible as both a Drag_Drop_Mode source and target per Requirement 5.
9. WHEN an Exercise_Tile renders a `SessionExercise` whose `state` is not `UnfinishedState`, THE Exercise_Tile SHALL be ineligible as a Drag_Drop_Mode source and as a Drag_Drop_Mode reorder/superset drop target per Requirement 5.

### Requirement 3: Inline Exercise Expansion

**User Story:** As a user managing a workout, I want to drill into one
exercise without losing my place, so that I can see and edit its sets,
notes, and metadata, then collapse it again.

#### Acceptance Criteria

1. WHEN the user activates an Exercise_Tile's expansion affordance, THE Workout_Overview_Module SHALL toggle the expanded state of that Exercise_Tile, AND SHALL preserve the expanded state of every other Exercise_Tile unchanged.
2. WHILE an Exercise_Tile is expanded, THE Exercise_Tile SHALL render one Set_Row per planned set in the snapshot for that exercise plus one Set_Row per `ExecutedSet` exceeding the planned count, ordered by ascending planned position followed by ascending `ExecutedSet.position` for any extras, where each planned-only row shows the planned values per Requirement 13 and each executed row additionally shows the actual values from the corresponding `ExecutedSet`.
3. WHILE an Exercise_Tile is expanded, THE Exercise_Tile SHALL render the exercise's snapshot `notes` (when non-null and non-empty) verbatim under a "Notes" subhead.
4. WHILE an Exercise_Tile is expanded AND the snapshot exercise's `videoUrl` is non-null and non-empty, THE Exercise_Tile SHALL render an inline action labelled "Open video" that, when activated, dispatches a `WorkoutOverviewOpenVideoRequested` event carrying the `videoUrl` string. The actual external launch is performed by the screen layer through the `url_launcher` package; this spec does not embed any in-app player.
5. WHILE an Exercise_Tile is expanded AND the rendered `SessionExercise.state` is `ReplacedState`, THE Exercise_Tile SHALL render the substitute's `name`, `measurementType`, and the substitute's `metadata.notes` (when present) under a "Replaced with" subhead in addition to the original planned exercise's metadata.
6. WHILE an Exercise_Tile is expanded, THE Exercise_Tile SHALL render the per-exercise action affordances defined in Requirement 9 below the Set_Rows.
7. WHEN the user collapses an Exercise_Tile through its expansion affordance, THE Exercise_Tile SHALL hide every element introduced by AC 3.2 through AC 3.6 and return to the row described by Requirement 2.

### Requirement 4: Long-Press Reorder of Unfinished Exercises

**User Story:** As an athlete adapting on the fly, I want to long-press
an unfinished exercise and drop it into a new position among other
unfinished exercises, so that I can reshape the order without leaving
the screen.

#### Acceptance Criteria

1. WHEN the user long-presses an Exercise_Tile whose `state` is `UnfinishedState`, THE Workout_Overview_Module SHALL enter Drag_Drop_Mode for that Exercise_Tile and SHALL show a lift/drag visual treatment on it for the duration of the gesture.
2. WHILE Drag_Drop_Mode is active, THE Workout_Overview_Module SHALL highlight every gap between two Exercise_Tiles that are both `UnfinishedState` (and not separated by a non-Unfinished Exercise_Tile) as a valid reorder drop site, AND SHALL highlight every other unfinished Exercise_Tile as a valid superset drop target per Requirement 5.
3. WHEN the user releases the dragged Exercise_Tile over a valid reorder drop site, THE Workout_Overview_Module SHALL compute the new order of all unfinished exercise IDs by removing the dragged id from its current position and inserting it at the drop site's index in the unfinished sub-list, AND SHALL invoke `SessionFlowEngine.reorderUnfinished(sessionId, orderedUnfinishedIds: <new order>)` exactly once.
4. WHEN the user releases the dragged Exercise_Tile over an empty area or over a non-Unfinished tile that is not a valid superset target, THE Workout_Overview_Module SHALL exit Drag_Drop_Mode without invoking any engine method.
5. IF `SessionFlowEngine.reorderUnfinished` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.
6. WHILE any engine mutation initiated by Drag_Drop_Mode is in flight, THE Workout_Overview_Module SHALL ignore further long-press starts on any Exercise_Tile until the future resolves.
7. THE Workout_Overview_Module SHALL NOT initiate any reorder drag from an Exercise_Tile whose `state` is `CompletedState`, `SkippedState`, or `ReplacedState`.

### Requirement 5: Drag-Onto-Target Superset Creation

**User Story:** As an athlete combining two exercises into a superset,
I want to drop one onto the other, so that I do not need a multi-step
form.

#### Acceptance Criteria

1. WHEN the user releases an Exercise_Tile that is currently in Drag_Drop_Mode (per Requirement 4 AC 1) directly on top of another Exercise_Tile whose `state` is `UnfinishedState`, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.createSuperset(sessionId, sessionExerciseIds: <ids>)` exactly once where `<ids>` contains exactly the dragged Exercise_Tile's id followed by the target Exercise_Tile's id.
2. WHEN the dragged Exercise_Tile and the target Exercise_Tile already share the same non-null `supersetTag`, THE Workout_Overview_Module SHALL treat the gesture as a no-op and SHALL exit Drag_Drop_Mode without invoking any engine method.
3. WHEN the dragged Exercise_Tile is currently inside a Superset_Frame and is dropped onto an Exercise_Tile not in that Superset_Frame, THE Workout_Overview_Module SHALL treat the gesture as a no-op and SHALL exit Drag_Drop_Mode without invoking any engine method, AND SHALL display a non-blocking informational indicator stating that the dragged exercise must first be ungrouped through the Superset_Frame's "Ungroup" affordance.
4. WHEN the target Exercise_Tile's `state` is not `UnfinishedState`, THE Workout_Overview_Module SHALL treat the gesture as a no-op and SHALL exit Drag_Drop_Mode without invoking any engine method.
5. IF `SessionFlowEngine.createSuperset` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.

### Requirement 6: Superset Removal

**User Story:** As an athlete who changed my mind about a superset, I
want to ungroup it, so that the two exercises are independent again.

#### Acceptance Criteria

1. THE Workout_Overview_Module SHALL render every Superset_Frame with a single context-menu affordance whose label is "Ungroup superset" and whose activation dispatches a `WorkoutOverviewSupersetUngroupRequested` event carrying the list of `SessionExercise.id` values currently inside the Superset_Frame in ascending `position` order.
2. WHEN the BLoC handles `WorkoutOverviewSupersetUngroupRequested`, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.removeSuperset(sessionId, sessionExerciseIds: <ids>)` exactly once.
3. IF every `SessionExercise` in the affected Superset_Frame is in `UnfinishedState`, THEN the engine call SHALL be issued; otherwise THE Workout_Overview_Module SHALL display a non-blocking informational indicator stating that supersets containing non-unfinished exercises cannot be ungrouped and SHALL NOT issue the engine call.
4. IF `SessionFlowEngine.removeSuperset` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.

### Requirement 7: Exercise Replacement

**User Story:** As an athlete who can't perform an exercise as planned,
I want to swap it for a substitute that fits, so that my session stays
useful.

#### Acceptance Criteria

1. WHEN the user activates the "Replace" action on an expanded Exercise_Tile whose `state` is `UnfinishedState`, THE Workout_Overview_Module SHALL present the Replacement_Dialog pre-populated with empty fields and the `MeasurementType` of the original planned exercise from the snapshot pre-selected.
2. WHEN the user submits the Replacement_Dialog with a substitute name containing at least one non-whitespace character and a chosen `MeasurementType`, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.replaceExercise(sessionExerciseId, substituteName, substituteMeasurementType)` exactly once.
3. IF the user submits the Replacement_Dialog with a substitute name that is empty or whitespace-only, THEN THE Replacement_Dialog SHALL display an inline validation message and SHALL NOT invoke the engine.
4. WHEN the user activates the "Replace" action on an expanded Exercise_Tile whose `state` is not `UnfinishedState`, THE Workout_Overview_Module SHALL NOT present the Replacement_Dialog and SHALL render the "Replace" action as disabled.
5. IF `SessionFlowEngine.replaceExercise` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.
6. WHEN `SessionFlowEngine.replaceExercise` returns a fresh Session_State, THE Workout_Overview_Module SHALL re-render the affected Exercise_Tile per Requirement 2 AC 5 (Replaced state visualisation) without collapsing other Exercise_Tiles' expansion state.

### Requirement 8: Exercise Skip

**User Story:** As an athlete who wants to move on past an exercise I
won't perform, I want one tap to skip it, so that the session keeps
flowing.

#### Acceptance Criteria

1. WHEN the user activates the "Skip" action on an expanded Exercise_Tile whose `state` is `UnfinishedState`, THE Workout_Overview_Module SHALL present a confirmation modal with two affordances: "Cancel" (dismisses the modal) and "Skip" (proceeds).
2. WHEN the user confirms the skip, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.skipExercise(sessionExerciseId)` exactly once.
3. WHEN the user activates the "Skip" action on an expanded Exercise_Tile whose `state` is not `UnfinishedState`, THE Workout_Overview_Module SHALL render the "Skip" action as disabled and SHALL NOT present the confirmation modal.
4. IF `SessionFlowEngine.skipExercise` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.

### Requirement 9: Per-Exercise Actions

**User Story:** As a user inside one exercise's panel, I want one
predictable place to find every action I can take on it, so that I do
not hunt across the screen.

#### Acceptance Criteria

1. THE Workout_Overview_Module SHALL render the per-exercise action set inside every expanded Exercise_Tile, in this exact order: "Log set", "Edit set" (per-row, see Requirement 11), "Replace", "Skip", and (when applicable) "Ungroup superset".
2. WHEN the rendered `SessionExercise.state` is `UnfinishedState` or `ReplacedState` AND `executedSets.length` is strictly less than the planned set count, THE Workout_Overview_Module SHALL render the "Log set" action as enabled and tied to the next set per Requirement 10.
3. WHEN the rendered `SessionExercise.state` is `CompletedState`, `SkippedState`, or has `executedSets.length` equal to the planned set count, THE Workout_Overview_Module SHALL render the "Log set" action as disabled.
4. THE Workout_Overview_Module SHALL render the "Replace" action as enabled if and only if `state` is `UnfinishedState`, per Requirement 7 AC 4.
5. THE Workout_Overview_Module SHALL render the "Skip" action as enabled if and only if `state` is `UnfinishedState`, per Requirement 8 AC 3.
6. THE Workout_Overview_Module SHALL render the "Ungroup superset" action only when the rendered `SessionExercise.supersetTag` is non-null, and SHALL gate its enablement per Requirement 6 AC 3.

### Requirement 10: Manual Set Logging

**User Story:** As an athlete logging from memory after the fact, or
as an athlete preferring to log inline rather than enter focus mode, I
want to enter a set's actual values directly from the overview, so
that I never need to leave the editable workspace to record progress.

#### Acceptance Criteria

1. WHEN the user activates the "Log set" action on an expanded Exercise_Tile that is eligible per Requirement 9 AC 2, THE Workout_Overview_Module SHALL present the Log_Set_Sheet pre-filled with `Suggested_Set_Values` derived from the engine's last `Session_State.suggestedValues` field for the affected exercise's next set per Requirement 14.
2. WHEN the user submits the Log_Set_Sheet with `ActualSetValues` whose variant matches the effective `MeasurementType` for the exercise (substitute's type for `ReplacedState`, original snapshot type otherwise), THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.completeSet(sessionExerciseId, actualValues)` exactly once.
3. WHEN the Log_Set_Sheet is presented for a `RepBasedMeasurement` exercise, THE Log_Set_Sheet SHALL render numeric inputs for `weightKg` (with -2.5 / +2.5 increment buttons when the current weightKg is greater than 10, or -1 / +1 increment buttons when the current weightKg is less than or equal to 10) and `reps` (with -1 / +1 increment buttons), and SHALL accept manual numeric edits.
4. WHEN the Log_Set_Sheet is presented for a `TimeBasedMeasurement` exercise, THE Log_Set_Sheet SHALL render a numeric input for `durationSeconds` with -1 / +1 and -10 / +10 increment buttons.
5. IF `SessionFlowEngine.completeSet` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.
6. WHEN `SessionFlowEngine.completeSet` returns a fresh Session_State whose `cursor` is `Cursor.completed`, THE Workout_Overview_Module SHALL re-render per Requirement 1 AC 7 (the "Session complete" indicator) without auto-navigating away.

### Requirement 11: Editing Previously Completed Sets

**User Story:** As an athlete who mistyped a value, I want to edit a
completed set's actual values, so that my history reflects truth even
after the set is logged.

#### Acceptance Criteria

1. WHEN the user activates a Set_Row's per-row edit affordance (rendered for any Set_Row corresponding to an existing `ExecutedSet` regardless of the parent exercise's state), THE Workout_Overview_Module SHALL present the Edit_Set_Sheet pre-filled with that `ExecutedSet`'s current `actualValues`.
2. WHEN the user submits the Edit_Set_Sheet with `ActualSetValues` whose variant matches the effective `MeasurementType` for the exercise, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.updateExecutedSet(executedSetId, actualValues)` exactly once.
3. THE Workout_Overview_Module SHALL render the per-row edit affordance for every executed Set_Row even when the parent Exercise_Tile's `state` is `CompletedState`, `SkippedState`, or `ReplacedState`, per Session_Flow_Engine Requirement 6.2.
4. IF `SessionFlowEngine.updateExecutedSet` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.

### Requirement 12: Session Notes and Extra Work

**User Story:** As an athlete recording observations and unplanned
work, I want a simple text input for both, so that nothing about the
session is lost.

#### Acceptance Criteria

1. THE Workout_Overview_Screen SHALL render a "Notes" section listing every `SessionNote` in the loaded Session in ascending `createdAt` order, each rendered with its `body` verbatim.
2. THE Workout_Overview_Screen SHALL render an "Extra work" section listing every `ExtraWork` in the loaded Session in ascending `createdAt` order, each rendered with its `body` verbatim.
3. THE Workout_Overview_Screen SHALL render an "Add note" affordance that opens the Add_Note_Sheet; on submission with a non-whitespace body, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.addSessionNote(sessionId, body)` exactly once.
4. THE Workout_Overview_Screen SHALL render an "Add extra work" affordance that opens the Add_Extra_Work_Sheet; on submission with a non-whitespace body, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.addExtraWork(sessionId, body)` exactly once.
5. IF the user submits either sheet with a body that is empty or whitespace-only, THEN THE submitting sheet SHALL display an inline validation message and SHALL NOT invoke any engine method.
6. IF either engine call throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.
7. WHEN the user submits the Add_Note_Sheet with a body whose length exceeds 5000 characters, THE Add_Note_Sheet SHALL display an inline validation message stating the 5000-character limit and SHALL NOT invoke any engine method.

### Requirement 13: Planned vs Actual Visualisation

**User Story:** As a user, I want to see the planned target and what
I performed side by side without one screaming louder than the other,
so that deviations look like adaptation, not error.

#### Acceptance Criteria

1. THE Workout_Overview_Module SHALL derive each `SessionExercise`'s planned summary from the snapshot's `WorkoutSet` list for that exercise, formatted as one of:
   - "<weightKg>kg <plannedSetCount>×<reps>" when every planned `WorkoutSet` shares the same `weightKg` and `reps` for `RepBasedMeasurement`;
   - "<plannedSetCount>×<durationSeconds>s" when every planned `WorkoutSet` shares the same `durationSeconds` for `TimeBasedMeasurement`;
   - "<plannedSetCount> sets" when planned values vary across the exercise's sets.
2. THE Workout_Overview_Module SHALL render planned-value text using `appColors.planned` and actual-value text using `appColors.actual`, with the visual distinction applied through weight/typography rather than hue intensity per the steering's planned-vs-actual rule.
3. WHEN a Set_Row corresponds to an executed set whose `actualValues` deviate from the planned `WorkoutSet` at the same position (different `weightKg` or `reps` for rep-based; different `durationSeconds` for time-based), THE Set_Row SHALL still render both values without any error styling, badge, or warning.
4. WHEN a Set_Row corresponds to a planned set with no matching `ExecutedSet`, THE Set_Row SHALL render only the planned values and a placeholder dash `—` in the actual-value slot.

### Requirement 14: Suggested Set Values from the Engine

**User Story:** As a user about to log the next set, I want the form
pre-filled with the most-recent value I performed for this exercise
or, failing that, the planned value, so that I rarely have to type.

#### Acceptance Criteria

1. WHEN the BLoC presents the Log_Set_Sheet for an Exercise_Tile that matches the current `Cursor.active.sessionExerciseId`, THE Workout_Overview_Module SHALL pre-fill the sheet with the engine's last `Session_State.suggestedValues` field.
2. WHEN the BLoC presents the Log_Set_Sheet for an Exercise_Tile that does NOT match the current `Cursor.active.sessionExerciseId`, THE Workout_Overview_Module SHALL pre-fill the sheet by calling `SessionFlowEngine.suggestValues(session, Cursor.active(sessionExerciseId: <tile id>, setIndex: <executedCount>))` and using the returned `ActualSetValues`.
3. THE Workout_Overview_Module SHALL ensure the sheet's variant matches the effective `MeasurementType` for the exercise (`substitute.measurementType` for `ReplacedState`, snapshot exercise's `measurementType` otherwise).

### Requirement 15: End Session

**User Story:** As an athlete done for the day, I want one place to
mark the session ended, so that history is sealed and the picker can
show me a fresh start next time.

#### Acceptance Criteria

1. THE Workout_Overview_Screen SHALL render an "End session" overflow affordance in the screen header.
2. WHEN the user activates the "End session" affordance AND the loaded Session's `endedAt` is null, THE Workout_Overview_Module SHALL present the End_Session_Confirmation modal with two affordances: "Cancel" (dismisses) and "End session" (proceeds).
3. WHEN the user confirms the end, THE Workout_Overview_Module SHALL invoke `SessionFlowEngine.endSession(sessionId)` exactly once.
4. WHEN `SessionFlowEngine.endSession` returns a fresh Session_State whose `session.endedAt` is non-null, THE Workout_Overview_Module SHALL re-render the screen with: the "End session" affordance disabled, every "Log set" / "Replace" / "Skip" / Drag_Drop_Mode entry point disabled, and a header pill "Session ended at <YYYY-MM-DDTHH:MM>" derived from the local-time `session.endedAt`.
5. WHEN the loaded Session's `endedAt` is non-null on screen open, THE Workout_Overview_Module SHALL render every mutation affordance described by Requirements 4–10 and 12 as disabled, EXCEPT for the per-row "Edit set" affordance from Requirement 11 which SHALL remain enabled per Session_Flow_Engine Requirement 6.2.
6. IF `SessionFlowEngine.endSession` throws or returns any typed `DomainError`, THEN THE Workout_Overview_Module SHALL leave the Session_State unchanged and SHALL display a non-blocking transient error indicator naming the error's `invariant` or `field` descriptor verbatim with an "OK" dismiss affordance.

### Requirement 16: Focus Mode Entry and Refresh on Return

**User Story:** As an athlete, I want a primary action to drop straight
into the next set's focus screen, and when I come back the overview
should reflect any sets I logged in there.

#### Acceptance Criteria

1. THE Workout_Overview_Screen SHALL render a primary "Focus" call-to-action affordance, persistent at the bottom of the screen, that pushes the Focus_Mode_Route onto the navigator with the loaded `sessionId` as the route argument.
2. WHEN the loaded Session_State's `cursor` is `Cursor.completed`, THE Workout_Overview_Screen SHALL render the "Focus" affordance as disabled and SHALL render a static label "All sets done" beneath it.
3. THE Workout_Overview_Module SHALL declare the Focus_Mode_Route as a route-name constant `static const focus = '/session-focus';` on the existing `lib/navigation/session_routes.dart` `SessionRoutes` class.
4. THE app composition layer SHALL bind the Focus_Mode_Route to a tiny `FocusModePlaceholderScreen` until the `focus-mode-screen` spec replaces the binding; the placeholder SHALL display the passed sessionId and a back affordance, mirroring the existing `SessionActivePlaceholderScreen`.
5. WHEN control returns to the Workout_Overview_Screen after the Focus_Mode_Route is popped, THE Workout_Overview_Module SHALL re-load the Session_State by calling `SessionFlowEngine.resumeSession(sessionId)` exactly once before re-enabling the "Focus" affordance.
6. THE Workout_Overview_Screen SHALL also expose a manual "refresh" affordance in the screen header whose activation re-loads the Session_State by calling `SessionFlowEngine.resumeSession(sessionId)`.

### Requirement 17: Route Re-Binding for Active Session

**User Story:** As a developer wiring this screen into the existing
app shell, I want the picker's existing "active session" hand-off to
land on the real overview instead of the placeholder, so that no
caller in the codebase has to learn a new route.

#### Acceptance Criteria

1. THE Workout_Overview_Module SHALL expose a single screen entry point `WorkoutOverviewScreen` that consumes a `Workout_Overview_Args` carrying the `sessionId`.
2. THE app composition layer SHALL re-bind `SessionRoutes.active` (currently `SessionActivePlaceholderScreen`) to construct `WorkoutOverviewScreen` from `settings.arguments` interpreted as `Workout_Overview_Args` AND SHALL delete `SessionActivePlaceholderScreen` from the codebase as part of this spec.
3. IF `settings.arguments` for `SessionRoutes.active` is not a `Workout_Overview_Args`, THEN the route SHALL throw an `ArgumentError` clearly identifying the expected type, mirroring the picker's `WorkoutDayPickerArgs` handling.
4. THE workout-day-picker's existing call site that pushes `SessionRoutes.active` with a `String sessionId` SHALL be updated to push `Workout_Overview_Args(sessionId: ...)` instead. This is the only edit to `lib/modules/workout_day_picker/` required by this spec; it is a localized argument-type change with no behavioural impact on the picker's tests.

### Requirement 18: Loading, Error, and Transient Surfaces

**User Story:** As a user, when a mutation fails or the screen loads
slowly, I want a calm, non-blocking surface that tells me what
happened, so that I am not stranded.

#### Acceptance Criteria

1. WHILE the initial Session load is in flight (Requirement 1 AC 3), THE Workout_Overview_Screen SHALL show a single screen-level loading surface and SHALL NOT render any Exercise_Tile, Notes section, Extra-work section, or Focus affordance.
2. IF the initial Session load fails per Requirement 1 AC 5, THEN THE Workout_Overview_Screen SHALL show a single screen-level error surface naming the error's `invariant` or `field` descriptor verbatim and offering a retry affordance.
3. WHEN any in-session mutation fails per Requirements 4–8, 10–12, or 15 (i.e. raises a `DomainError`), THE Workout_Overview_Screen SHALL show the failure as a single non-blocking `MaterialBanner` near the top of the screen body containing the error's `invariant` or `field` descriptor verbatim and an "OK" dismiss affordance, AND SHALL leave the underlying Session_State unchanged.
4. WHILE any engine mutation initiated by Requirements 4–8, 10–12, or 15 is in flight, THE Workout_Overview_Module SHALL display a per-action busy indicator on the originating affordance and SHALL ignore further activations of any mutation affordance until the future resolves.
5. THE Workout_Overview_Module SHALL display at most one transient error banner at a time; subsequent failures SHALL replace the displayed banner.

### Requirement 19: Offline-First Isolation

**User Story:** As a user training in a basement gym, I want every
overview action to work without a network, so that I can log
regardless of signal.

#### Acceptance Criteria

1. THE Workout_Overview_Module SHALL NOT import any package that performs network I/O, including `package:http`, `package:dio`, `package:web_socket_channel`, `package:grpc`, and `package:socket_io_client`, and SHALL NOT reference any of the `dart:io` classes `HttpClient`, `HttpServer`, `Socket`, `ServerSocket`, `RawSocket`, `SecureSocket`, or `SecureServerSocket`.
2. The video-link-launching path of Requirement 3 AC 4 SHALL be implemented by passing the URL string to `package:url_launcher`, which uses platform channels — not network I/O — to hand the URL to the host OS. The Workout_Overview_Module SHALL NOT itself open any HTTP connection or request the URL's contents.
3. WHEN any Workout_Overview_Module screen is opened on an Offline_Device, every in-screen action defined by Requirements 1–18 SHALL complete (modulo `url_launcher`'s OS-mediated external launch) without issuing any outbound network request from the Workout_Overview_Module itself.

### Requirement 20: Repository Contracts and Engine-Only Mutations

**User Story:** As a developer, I want the overview to depend only on
the domain barrel and `SessionFlowEngine`, so that no Drift type ever
leaks into widgets and every Session mutation goes through the engine.

#### Acceptance Criteria

1. THE Workout_Overview_Module, defined as all non-generated Dart source files under `lib/modules/workout_overview/` (excluding `*.freezed.dart` and `*.g.dart` siblings), SHALL depend only on `lib/core/`, on the domain barrel `package:zamaj/modules/domain/domain.dart`, on the navigation files under `lib/navigation/`, and on the module's own files, and SHALL NOT import any file under `lib/modules/persistence/`.
2. THE Workout_Overview_Module SHALL NOT import `package:drift/drift.dart`, `package:drift/native.dart`, `package:drift_flutter/drift_flutter.dart`, `package:sqlite3/sqlite3.dart`, `package:sqlite3/common.dart`, any Drift-generated type, or any `*.g.dart` file located under `lib/modules/persistence/`, from any BLoC, screen, widget, or service.
3. THE Workout_Overview_Module SHALL receive `SessionFlowEngine` and `Clock` instances through constructor parameters whose declared types resolve to the abstract contracts and value types defined under `lib/modules/domain/`, and SHALL NOT resolve these dependencies via service locators, global singletons, or setter injection.
4. THE Workout_Overview_Module SHALL NOT call any `SessionRepository` mutation method (`startSession`, `endSession`, `completeSet`, `updateExecutedSet`, `skipExercise`, `replaceExercise`, `reorderUnfinished`, `addSessionNote`, `addExtraWork`, `createSuperset`, `removeSuperset`) directly; every Session mutation path SHALL go through a `SessionFlowEngine` method. The module MAY hold a `SessionRepository` reference solely for read-only queries it cannot obtain through the engine; the MVP does not yet need this.
5. THE Workout_Overview_Module SHALL NOT reference, construct, or open any of the symbols `AppDatabase`, `NativeDatabase`, `driftDatabase`, or `GeneratedDatabase`, and SHALL NOT invoke any constructor or factory that returns a subtype of `GeneratedDatabase`.
6. IF the offline-imports check (`tool/check_offline_imports.sh` extended to cover `lib/modules/workout_overview/`) detects any import or symbol reference forbidden by Acceptance Criteria 1, 2, or 5, THEN THE check SHALL exit with a non-zero status code and SHALL emit, for each violation, a message identifying the offending file path, the line number, and the forbidden import or symbol.

### Requirement 21: Module Structure and Conventions

**User Story:** As a developer, I want the overview module to follow
the project's existing UI-feature conventions, so that future modules
can be built the same way.

#### Acceptance Criteria

1. THE Workout_Overview_Module SHALL live under `lib/modules/workout_overview/` and SHALL expose a single barrel file `lib/modules/workout_overview/workout_overview.dart` that re-exports every type intended for consumption outside the module.
2. THE Workout_Overview_Module SHALL organise its source under `bloc/`, `screens/`, `widgets/`, `services/`, and `models/` subdirectories per the conventions in `init.md`.
3. THE Workout_Overview_Module SHALL use the `flutter_bloc` pattern with sealed `Event` and `State` class families whose concrete subclasses extend `Equatable`, per the conventions in `init.md`.
4. THE Workout_Overview_Module SHALL use single quotes for Dart string literals, SHALL apply the `const` keyword to every constructor invocation flagged by the `prefer_const_constructors` lint in the project's `analysis_options.yaml`, SHALL use `package:zamaj/...` imports for every cross-directory import within `lib/`, and SHALL NOT use relative `lib/` imports.
5. THE Workout_Overview_Module SHALL NOT contain any `print` call in its source files; any diagnostic output SHALL go through `log` from `dart:developer` or through a BLoC observer consistent with `init.md`.
6. WHEN `flutter analyze` is run against the project with the existing `analysis_options.yaml`, the Workout_Overview_Module source files SHALL produce zero errors, zero warnings, and zero lint violations.
7. THE Workout_Overview_Module SHALL read every color, spacing, and typography token through the `Theme.of(context).appColors` extension and the `AppSpacing` / `AppTypography` constants in `lib/core/`; widget files SHALL NOT contain hard-coded `Color(0x...)` literals or hard-coded pixel values for spacing, padding, or radius, per `.kiro/steering/ui-tokens.md`.

### Requirement 22: Error Surface Verbatim Content

**User Story:** As a user, when the overview can't do what I asked, I
want a clear message that names the failure, so that I can decide
whether to retry or fix the underlying problem.

#### Acceptance Criteria

1. WHEN any `SessionFlowEngine` call invoked by the Workout_Overview_Module returns or throws a typed `DomainError` (`ValidationError`, `OrderingError`, `NotFoundError`, `ImmutabilityError`, `VersionMismatchError`, `DeserializationError`), THE Workout_Overview_Module SHALL surface a non-empty message that contains the error's `invariant` or `field` descriptor verbatim and, WHERE the error carries an `entityId` or `sessionExerciseId` or `sessionId`, contains that identifier verbatim.
2. IF a screen-level error surface is shown per Requirement 18 AC 2, THEN activating its retry affordance SHALL re-invoke the full initial load (`SessionFlowEngine.resumeSession`) exactly once per activation and SHALL replace the screen-level error surface with the loading surface for the duration of that re-load.
3. IF a transient banner is shown per Requirement 18 AC 3, THEN activating its "OK" dismiss affordance SHALL clear the banner without invoking any engine method.
