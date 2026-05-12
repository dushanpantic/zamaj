# Implementation Plan: Workout Overview Screen

## Overview

Implement the `WorkoutOverviewScreen` and its supporting BLoC,
view-model assembler, drop resolver, planned-summary formatter,
widgets, and navigation wiring. Work proceeds bottom-up: module
scaffold and offline guard first, then pure-Dart value objects and
services with their tests, then the BLoC, then the widgets and
screen, then the navigation re-binding that swaps
`SessionRoutes.active` from the picker's placeholder to the real
overview screen and adds the new `SessionRoutes.focus` placeholder.
No domain or Drift change is required by this spec — every engine
method already exists.

**Not duplicated here (already done in prior specs):**

- `flutter_bloc`, `equatable`, `package:clock`, `freezed`, and
  `json_serializable` are already in `pubspec.yaml`.
- `lib/core/app_colors.dart`, `lib/core/app_spacing.dart`,
  `lib/core/app_typography.dart`, `lib/core/app_theme.dart`, and
  `lib/core/app_error.dart` exist and are read directly.
- `SessionFlowEngine`, `SessionState`, `Cursor`, `Session`,
  `SessionExercise`, `ExecutedSet`, `ExerciseState`,
  `MeasurementType`, `ActualSetValues`, `PlannedSetValues`, and the
  `Exercise` / `WorkoutDay` aggregates are already exported by
  `package:zamaj/modules/domain/domain.dart`.
- `lib/navigation/session_routes.dart`,
  `lib/navigation/app_router.dart`, and the picker's BLoC are wired
  by the workout-day-picker spec.

**Testing scope:** Only pure-Dart service tests are written (unit and
property-based) for the new `PlannedSummaryFormatter`,
`ExerciseViewModelAssembler`, and `DropResolver`. BLoC tests, widget
tests, and screen/integration tests are out of scope, matching the
convention established by the prior UI specs
(`program-management/tasks.md`, `workout-day-picker/tasks.md`).
Property-based tests appear alongside the service they validate.

Conventions:

- Module lives under `lib/modules/workout_overview/` with barrel
  `workout_overview.dart` (R21 AC1).
- Sealed `Event` and `State` families with `Equatable` (R21 AC3).
- `package:zamaj/...` imports, single quotes, `const` everywhere the
  lint demands (R21 AC4).
- Token usage through `Theme.of(context).appColors`, `AppSpacing`,
  `AppTypography` — no hard-coded colors or pixel values in widget
  files (R21 AC7).
- Property tests live alongside the service they validate and run
  ≥100 iterations inside standard `test()` blocks.

## Tasks

- [x] 1. Module scaffold and offline guard
  - [x] 1.1 Create the module folder scaffolding:
    `lib/modules/workout_overview/{bloc,screens,widgets,services,models}/`
    and an empty barrel file
    `lib/modules/workout_overview/workout_overview.dart`
    - _Requirements: R21 AC1, R21 AC2_
    - _Design: §1.2_

  - [x] 1.2 Extend `tool/check_offline_imports.sh` to additionally
    scan `lib/modules/workout_overview/` against the existing
    forbidden list (no new patterns); emit `<file>:<line>:<offending
    symbol>` on violations and exit non-zero
    - _Requirements: R19 AC1, R20 AC6_
    - _Design: §12.1, §12.2_

  - [x] 1.3 Add `url_launcher` to `pubspec.yaml` under `dependencies`
    pinned to the most recent stable major (`^6.x`); run
    `flutter pub get` and verify `package:url_launcher/url_launcher.dart`
    resolves
    - _Requirements: R3 AC4, R19 AC2_
    - _Design: §12.3_

  - [x] 1.4 Add the `static const focus = '/session-focus';`
    constant to the existing
    `lib/navigation/session_routes.dart` `SessionRoutes` class
    - _Requirements: R16 AC3_
    - _Design: §2.1_

  - [x] 1.5 Create
    `lib/navigation/focus_mode_placeholder_screen.dart` modelled on
    the existing `SessionActivePlaceholderScreen` shape: a `Scaffold`
    that displays the passed `sessionId` and a back affordance,
    reading colors and typography through theme tokens
    - _Requirements: R16 AC4_
    - _Design: §2.3_

- [x] 2. Pure-Dart value types and models
  - [x] 2.1 Define `WorkoutOverviewArgs`
    (`models/workout_overview_args.dart`) as a freezed class with a
    required `String sessionId`; add `part` directives and run
    `dart run build_runner build --force-jit`
    - _Requirements: R1 AC1, R17 AC1, R17 AC3_
    - _Design: §1.2, §2.2_

  - [x] 2.2 Define `SetRowViewModel`
    (`models/set_row_view_model.dart`) as a freezed class with
    required `int position`, nullable `PlannedSetValues plannedValues`,
    nullable `ExecutedSet executedSet`, and required
    `bool isNextLogTarget`; regenerate
    - _Requirements: R3 AC2, R13 AC4_
    - _Design: §3.2, §5.2_

  - [x] 2.3 Define `ExerciseViewModel`
    (`models/exercise_view_model.dart`) as a freezed class with
    required `SessionExercise sessionExercise`, required
    `Exercise plannedExerciseInSnapshot`, required
    `String plannedSummary`, required `List<SetRowViewModel> setRows`,
    required `bool isCursorTarget`, nullable `int cursorSetIndex`,
    and required `MeasurementType effectiveMeasurementType`;
    regenerate
    - _Requirements: R2, R3, R13_
    - _Design: §3.2, §5.1_

  - [x] 2.4 Define `SupersetGroupViewModel`
    (`models/superset_group_view_model.dart`) as a freezed class with
    nullable `String supersetTag` and required
    `List<ExerciseViewModel> exercises`; regenerate
    - _Requirements: R1 AC2, R6_
    - _Design: §3.2, §5.1_

  - [x] 2.5 Define `DropTarget` and `DropIntent`
    (`models/drop_intent.dart`) as freezed sealed unions per the
    design pseudocode: `DropTarget.beforeIndex(int)`,
    `DropTarget.ontoExercise(String)`, `DropTarget.outside()`;
    `DropIntent.reorder({sessionId, orderedUnfinishedIds})`,
    `DropIntent.createSuperset({sessionId, sessionExerciseIds})`,
    `DropIntent.noop()`. Use `@Freezed(unionKey: 'type')`. Regenerate
    - _Requirements: R4, R5_
    - _Design: §7_

  - [x] 2.6 Define the `MutationKind` enum in
    `bloc/workout_overview_state.dart` (or a sibling file)
    enumerating every kind named in the design §3.2 mutation table:
    `reorder`, `createSuperset`, `removeSuperset`, `skip`, `replace`,
    `logSet`, `editSet`, `addNote`, `addExtraWork`, `endSession`
    - Implemented as a sibling file `models/mutation_kind.dart` so
      it can be imported by the BLoC (when added in Task 5) and any
      view layer without dragging the BLoC file in.
    - _Requirements: R18 AC4_
    - _Design: §3.2_

- [x] 3. Pure-Dart services
  - [x] 3.1 Implement `PlannedSummaryFormatter`
    (`services/planned_summary_formatter.dart`) as an
    `abstract final class` with `static String summarize(Exercise
    plannedExercise)` per design §6: handle empty sets, all-equal
    rep-based, all-equal time-based, mixed-values fallback, and the
    `_fmtKg` helper for trailing `.0` stripping
    - _Requirements: R13 AC1_
    - _Design: §6_

  - [x] 3.2 Write
    `test/modules/workout_overview/services/planned_summary_formatter_test.dart`
    covering: empty sets list returns "0 sets"; one rep-based set
    returns "<kg>kg 1×<reps>"; multiple rep-based sets all equal
    returns "<kg>kg <n>×<reps>"; mixed rep-based sets returns
    "<n> sets"; all-equal time-based returns "<n>×<duration>s";
    mixed time-based returns "<n> sets"; integer kg drops decimal;
    fractional kg keeps one decimal
    - _Requirements: R13 AC1_
    - _Design: §6_

  - [x] 3.3 Implement `ExerciseViewModelAssembler`
    (`services/exercise_view_model_assembler.dart`) as an
    `abstract final class` with `static
    List<SupersetGroupViewModel> assemble(SessionState
    sessionState)` per design §5: walk session exercises in
    ascending position, group by `supersetTag`, build set rows per
    §5.2, mark cursor target when applicable, compute
    `effectiveMeasurementType` honouring `ReplacedState`
    - _Requirements: R1 AC2, R2 AC6, R3 AC2, R13 AC4, R14 AC3_
    - _Design: §5_

  - [x] 3.4 Write
    `test/modules/workout_overview/services/exercise_view_model_assembler_test.dart`
    covering: one standalone unfinished exercise → cursor target on
    set 0 with isCursorTarget true; mixed standalone + superset →
    grouping reflects supersetTag adjacency; replaced exercise →
    effectiveMeasurementType equals substitute's; completed exercise
    → no cursor; cursor.completed → no isCursorTarget; extra
    executed sets beyond planned count produce trailing rows with
    null plannedValues
    - _Requirements: R1 AC2, R2 AC5, R2 AC6, R3 AC2, R5 AC1, R13 AC4_
    - _Design: §5_

  - [x] 3.5 Implement `DropResolver`
    (`services/drop_resolver.dart`) as an `abstract final class`
    with `static DropIntent resolve({sessionId, groups, draggedId,
    target})` per design §7.1: handle the noop branches first
    (outside, dragged-not-unfinished, drop-on-self, same-superset,
    cross-superset, same-position gap), then the `reorder` and
    `createSuperset` branches
    - _Requirements: R4, R5_
    - _Design: §7_

  - [x] 3.6 Write
    `test/modules/workout_overview/services/drop_resolver_test.dart`
    covering each branch from §7.1 with a small hand-crafted
    `groups` argument: drop outside → noop; drop on self → noop;
    drop on locked → noop; drop into same gap → noop; drop into
    different gap → reorder with correctly-permuted ids; drop on
    unfinished outside any superset → createSuperset with
    `[draggedId, targetId]`; drop within same superset → noop; drop
    across superset boundaries → noop
    - _Requirements: R4, R5 AC1–AC4_
    - _Design: §7.1_

  - [x] 3.7 Write
    `test/modules/workout_overview/services/assembler_determinism_property_test.dart`:
    generate ≥100 random `SessionState` values via
    `anySessionStateForOverview` (extend
    `test/support/generators.dart` if needed); invoke
    `assemble` twice; assert equality
    - _Requirements: R5 (engine determinism reused)_
    - _Design: §5.3, §13.2_

  - [x] 3.8 Write
    `test/modules/workout_overview/services/assembler_order_property_test.dart`:
    generate ≥100 random `SessionState` values; assert flattening
    `groups[*].exercises[*].sessionExercise` equals
    `session.sessionExercises` sorted ascending by position
    - _Requirements: R1 AC2_
    - _Design: §5.1, §13.2_

  - [x] 3.9 Write
    `test/modules/workout_overview/services/assembler_count_property_test.dart`:
    generate ≥100 random `SessionState` values; assert flattened
    exercise count equals `session.sessionExercises.length`
    - _Requirements: R1 AC2_
    - _Design: §5.1, §13.2_

  - [x] 3.10 Write
    `test/modules/workout_overview/services/drop_resolver_self_property_test.dart`:
    generate ≥100 random `(groups, draggedId)` pairs; assert
    `resolve(target: ontoExercise(draggedId))` returns `Noop`
    - _Requirements: R5 AC2_
    - _Design: §7.1_

  - [x] 3.11 Write
    `test/modules/workout_overview/services/drop_resolver_same_position_property_test.dart`:
    generate ≥100 random `(groups, draggedId)` pairs where
    `draggedId` is unfinished; locate its current unfinished index
    `i`; assert `resolve(target: beforeIndex(i))` returns `Noop` AND
    `resolve(target: beforeIndex(i+1))` returns `Noop`
    - _Requirements: R4 (no-op same-position semantics)_
    - _Design: §7.1_

- [x] 4. Checkpoint — services + tests
  - [x] 4.1 Run `dart run build_runner build --force-jit`,
    `flutter analyze`, and `flutter test
    test/modules/workout_overview/services/` and ensure zero
    analyzer warnings and zero test failures; ask the user if
    questions arise
    - build_runner: 0 outputs written (everything up to date).
    - flutter test (workout_overview/services): 32/32 passing.
    - flutter analyze: 0 warnings/errors in this spec's code. Two
      pre-existing warnings remain in the session-flow-engine spec
      (unused `_clock` field in
      `lib/modules/domain/services/session_flow_engine.dart:28` and
      unused `totalCount` local in
      `test/domain/services/session_flow_engine_ordering_property_test.dart:268`).
      User opted to leave them; they will likely be picked up by
      the rest-timer or focus-mode spec when clock usage returns.

- [ ] 5. BLoC: events, states, and load algorithm
  - [ ] 5.1 Create `bloc/workout_overview_event.dart` with the
    sealed `WorkoutOverviewEvent` family per design §3.1: `Opened`,
    `RefreshRequested`, `ReturnedFromFocus`, `ScreenRetryRequested`,
    `ExerciseExpansionToggled(sessionExerciseId)`,
    `LogSetSubmitted({sessionExerciseId, actualValues})`,
    `ExecutedSetEditSubmitted({executedSetId, actualValues})`,
    `SkipConfirmed(sessionExerciseId)`,
    `ReplaceSubmitted({sessionExerciseId, substituteName, substituteMeasurementType})`,
    `DropResolved(intent)`,
    `SupersetUngroupRequested(sessionExerciseIds)`,
    `AddNoteSubmitted(body)`, `AddExtraWorkSubmitted(body)`,
    `EndSessionConfirmed`, `OpenVideoRequested(url)`,
    `ErrorDismissed`
    - _Requirements: R1, R3 AC4, R4–R8, R10–R12, R15, R16, R18 AC4, R22 AC3_
    - _Design: §3.1_

  - [ ] 5.2 Create `bloc/workout_overview_state.dart` with the
    sealed `WorkoutOverviewState` family per design §3.2: `Initial`,
    `Loading(sessionId)`, `SessionNotFound(sessionId)`,
    `ScreenFailure({sessionId, error})`, `Loaded({sessionState,
    exerciseGroups, expandedSessionExerciseIds, mutationInFlight,
    lastTransientError})`
    - _Requirements: R1, R18 AC1, R18 AC2_
    - _Design: §3.2_

  - [ ] 5.3 Create `bloc/bloc.dart` barrel that re-exports
    `workout_overview_bloc.dart`, `workout_overview_event.dart`,
    and `workout_overview_state.dart`
    - _Requirements: R21 AC1, R21 AC2_
    - _Design: §1.2_

  - [ ] 5.4 Implement `WorkoutOverviewBloc`
    (`bloc/workout_overview_bloc.dart`) with constructor-injected
    `SessionFlowEngine` and `Clock`; private fields for the
    video-launch `StreamController<String>` exposed as
    `Stream<String> videoLaunchIntents`; close the controller in
    `close()`
    - _Requirements: R20 AC3_
    - _Design: §1.3, §3.6_

  - [ ] 5.5 Implement the `on<WorkoutOverviewOpened>` handler
    following design §4.1: emit `Loading(sessionId)`, await
    `engine.resumeSession(sessionId: sessionId)`, on success build
    view models via `ExerciseViewModelAssembler.assemble` and emit
    `Loaded` with empty `expandedSessionExerciseIds`; on
    `NotFoundError` emit `SessionNotFound`; on any other
    `DomainError` emit `ScreenFailure(sessionId, error)`
    - _Requirements: R1 AC1, R1 AC3, R1 AC4, R1 AC5, R18 AC1, R18 AC2_
    - _Design: §4.1_

  - [ ] 5.6 Implement
    `on<WorkoutOverviewScreenRetryRequested>` re-running the
    `Opened` algorithm with the `sessionId` from the current state
    - _Requirements: R18 AC2, R22 AC2_
    - _Design: §3.3_

  - [ ] 5.7 Implement `on<WorkoutOverviewRefreshRequested>` and
    `on<WorkoutOverviewReturnedFromFocus>` as full reloads (same
    algorithm as `Opened`, same `sessionId`); preserve
    `expandedSessionExerciseIds` across the reload
    - _Requirements: R16 AC5, R16 AC6_
    - _Design: §4.2_

  - [ ] 5.8 Implement `on<WorkoutOverviewExerciseExpansionToggled>`:
    when state is `Loaded`, emit `Loaded` with
    `expandedSessionExerciseIds` toggled for the given id; this
    handler does NOT set `mutationInFlight`
    - _Requirements: R3 AC1, R3 AC7_
    - _Design: §3.4_

  - [ ] 5.9 Implement a private `_runMutation(emit, MutationKind
    kind, Future<SessionState> Function() op)` helper following
    design §4.3: short-circuit if state is not `Loaded` or
    `mutationInFlight != null`; emit `Loaded` with
    `mutationInFlight: kind`; await `op()`; on success rebuild
    `exerciseGroups` and emit `Loaded` with the new sessionState,
    cleared mutation flag, and cleared error; on `DomainError` emit
    `Loaded` with cleared mutation flag and `lastTransientError: e`
    - _Requirements: R18 AC3, R18 AC4, R18 AC5, R22 AC1_
    - _Design: §3.4, §4.3_

  - [ ] 5.10 Implement `on<WorkoutOverviewLogSetSubmitted>` calling
    `_runMutation(MutationKind.logSet, () => engine.completeSet(
    sessionExerciseId: e.sessionExerciseId, actualValues: e.actualValues))`
    - _Requirements: R10_
    - _Design: §4.3, §11.1_

  - [ ] 5.11 Implement `on<WorkoutOverviewExecutedSetEditSubmitted>`
    calling `_runMutation(MutationKind.editSet, () =>
    engine.updateExecutedSet(executedSetId: e.executedSetId,
    actualValues: e.actualValues))`
    - _Requirements: R11_
    - _Design: §4.3, §11.1_

  - [ ] 5.12 Implement `on<WorkoutOverviewSkipConfirmed>` calling
    `_runMutation(MutationKind.skip, () =>
    engine.skipExercise(sessionExerciseId: e.sessionExerciseId))`
    - _Requirements: R8_
    - _Design: §4.3, §11.1_

  - [ ] 5.13 Implement `on<WorkoutOverviewReplaceSubmitted>` calling
    `_runMutation(MutationKind.replace, () =>
    engine.replaceExercise(sessionExerciseId: ...,
    substituteName: ..., substituteMeasurementType: ...))`
    - _Requirements: R7_
    - _Design: §4.3, §11.1_

  - [ ] 5.14 Implement `on<WorkoutOverviewDropResolved>` switching
    on the `intent`: `Noop` → ignore; `Reorder(orderedUnfinishedIds)`
    → `_runMutation(MutationKind.reorder, () =>
    engine.reorderUnfinished(sessionId: ..., orderedUnfinishedIds:
    ...))`; `CreateSuperset(sessionExerciseIds)` →
    `_runMutation(MutationKind.createSuperset, () =>
    engine.createSuperset(sessionId: ..., sessionExerciseIds: ...))`
    - _Requirements: R4, R5_
    - _Design: §3.3, §4.3_

  - [ ] 5.15 Implement `on<WorkoutOverviewSupersetUngroupRequested>`
    calling `_runMutation(MutationKind.removeSuperset, () =>
    engine.removeSuperset(sessionId: ..., sessionExerciseIds: ...))`
    - _Requirements: R6_
    - _Design: §4.3, §11.1_

  - [ ] 5.16 Implement `on<WorkoutOverviewAddNoteSubmitted>` and
    `on<WorkoutOverviewAddExtraWorkSubmitted>` calling
    `_runMutation` with the corresponding engine methods; the
    whitespace and length validation (R12 AC5, AC7) is enforced in
    the sheet widgets, not here, but the engine's own validation
    paths still propagate as transient errors
    - _Requirements: R12_
    - _Design: §4.3, §11.1_

  - [ ] 5.17 Implement `on<WorkoutOverviewEndSessionConfirmed>`
    calling `_runMutation(MutationKind.endSession, () =>
    engine.endSession(sessionId: ...))`
    - _Requirements: R15_
    - _Design: §4.3, §11.1_

  - [ ] 5.18 Implement `on<WorkoutOverviewOpenVideoRequested>`
    pushing the `url` onto `_videoLaunchIntents`; this handler does
    NOT set `mutationInFlight`
    - _Requirements: R3 AC4, R19 AC2_
    - _Design: §3.6_

  - [ ] 5.19 Implement `on<WorkoutOverviewErrorDismissed>`: when
    state is `Loaded` and `lastTransientError != null`, emit
    `Loaded` with `lastTransientError: null`
    - _Requirements: R18 AC3 (banner dismissal), R22 AC3_
    - _Design: §3.3_

- [ ] 6. Checkpoint — BLoC compiles
  - [ ] 6.1 Run `dart run build_runner build --force-jit`,
    `flutter analyze`, and the existing `flutter test
    test/modules/workout_overview/services/` to confirm the BLoC
    compiles and the existing service tests still pass; ensure zero
    analyzer warnings and zero test failures; ask the user if
    questions arise

- [ ] 7. Widgets and screen
  - [ ] 7.1 Build `widgets/planned_summary_label.dart` taking
    `{required String summary, required AppColors colors,
    required AppTypography typography}` (or just reading from
    Theme.of(context)) and rendering the planned summary string
    using `appColors.planned` and a tabular figures style
    - _Requirements: R13 AC2_
    - _Design: §9.2_

  - [ ] 7.2 Build `widgets/set_row.dart`: takes `SetRowViewModel`,
    effective `MeasurementType`, `bool canEdit`, `bool canLog`,
    callbacks `onLogPressed` and `onEditPressed`; renders planned +
    actual side by side per Requirement 13, the `—` placeholder
    when `executedSet == null`, the per-row "Edit" affordance when
    `canEdit && executedSet != null`, and a "Log" affordance when
    `canLog && isNextLogTarget`
    - _Requirements: R3 AC2, R10 AC1, R11 AC1, R13_
    - _Design: §9.2_

  - [ ] 7.3 Build `widgets/per_exercise_actions.dart`: takes
    `ExerciseViewModel`, `MutationKind?` for in-flight gating, and
    callbacks `onLogPressed`, `onReplacePressed`, `onSkipPressed`,
    `onUngroupPressed`; renders the action row per Requirement 9
    AC1 honouring the enablement rules in AC2–AC6
    - _Requirements: R9_
    - _Design: §9.2_

  - [ ] 7.4 Build `widgets/exercise_tile.dart`: takes
    `ExerciseViewModel`, `bool expanded`, `MutationKind?`,
    callbacks `onExpansionToggled`, `onLogPressed`, etc.; renders
    the tile per Requirement 2 with state badge, cursor "Up next"
    marker, and progress label; expands to show notes, video link
    affordance, set rows, and the per-exercise actions per
    Requirement 3
    - _Requirements: R2, R3_
    - _Design: §9.2_

  - [ ] 7.5 Build `widgets/superset_frame.dart`: takes
    `SupersetGroupViewModel`, `Set<String> expandedIds`,
    `MutationKind?`, the same per-tile callbacks, plus
    `onUngroupPressed` (only rendered when the frame contains ≥2
    exercises); renders the bracketed wrapper around each contained
    `ExerciseTile`
    - _Requirements: R1 AC2, R6_
    - _Design: §9.2_

  - [ ] 7.6 Build `widgets/log_set_sheet.dart`: takes
    `MeasurementType`, `ActualSetValues suggested`, callback
    `onSubmit(ActualSetValues)`; renders the rep-based or
    time-based form per Requirement 10 AC3/AC4 with the increment
    rules from §9.3 of the design
    - _Requirements: R10_
    - _Design: §9.3_

  - [ ] 7.7 Build `widgets/edit_set_sheet.dart`: same shape as
    `log_set_sheet.dart` but pre-filled from an existing
    `ExecutedSet`'s `actualValues` and forwarding to
    `WorkoutOverviewExecutedSetEditSubmitted`
    - _Requirements: R11_
    - _Design: §9.2_

  - [ ] 7.8 Build `widgets/replacement_dialog.dart`: takes the
    original `MeasurementType` and a callback
    `onSubmit(String name, MeasurementType mt)`; renders a name
    input with an inline whitespace validator and a measurement-type
    dropdown pre-selected to the original
    - _Requirements: R7_
    - _Design: §9.2_

  - [ ] 7.9 Build `widgets/end_session_dialog.dart`: a confirm
    modal with "Cancel" and "End session" affordances; on confirm
    calls a `VoidCallback onConfirm`
    - _Requirements: R15 AC2_
    - _Design: §9.2_

  - [ ] 7.10 Build `widgets/add_note_sheet.dart` and
    `widgets/add_extra_work_sheet.dart`: bottom-sheet text inputs
    with whitespace validators; the note sheet additionally enforces
    the 5000-character upper bound from R12 AC7 inline before
    submission
    - _Requirements: R12 AC3, AC4, AC5, AC7_
    - _Design: §9.2_

  - [ ] 7.11 Build `widgets/notes_section.dart` and
    `widgets/extra_work_section.dart`: each takes the corresponding
    list and an "Add" callback; renders the items in ascending
    `createdAt` order with their `body` verbatim, and the "Add"
    affordance per Requirement 12
    - _Requirements: R12 AC1, AC2_
    - _Design: §9.2_

  - [ ] 7.12 Build `widgets/focus_call_to_action.dart`: takes
    `bool enabled` and `VoidCallback onPressed`; renders the
    full-width persistent CTA with "Focus" label, disabled state
    showing "All sets done"
    - _Requirements: R16 AC1, AC2_
    - _Design: §9.2_

  - [ ] 7.13 Build the three state widgets:
    `widgets/workout_overview_loading_view.dart`,
    `widgets/workout_overview_error_view.dart` (with the typed
    error invariant/field message and a retry button), and
    `widgets/workout_overview_not_found_view.dart` (with the
    sessionId verbatim and a back affordance)
    - _Requirements: R1 AC4, R1 AC5, R18 AC1, R18 AC2, R22 AC2_
    - _Design: §10_

  - [ ] 7.14 Build `screens/workout_overview_screen.dart`:
    `BlocProvider<WorkoutOverviewBloc>` instantiated by the router;
    `AppBar` with the loaded WorkoutDay name + startedAt subtitle,
    a refresh action dispatching `WorkoutOverviewRefreshRequested`,
    and an overflow menu with "End session" dispatching the
    confirmation dialog → `WorkoutOverviewEndSessionConfirmed`;
    body is a `CustomScrollView` rendering the SupersetFrames,
    Notes section, Extra-work section per design §9.1; persistent
    bottom-bar `FocusCallToAction`; `BlocListener` translates
    `videoLaunchIntents` stream events into
    `url_launcher.launchUrl(Uri.parse(url), mode:
    LaunchMode.externalApplication)`; `BlocListener` on
    `Loaded.lastTransientError` shows a `MaterialBanner` with the
    typed error message and an OK action dispatching
    `WorkoutOverviewErrorDismissed`; `BlocListener` for the focus
    push uses `Navigator.pushNamed(SessionRoutes.focus,
    arguments: sessionId).whenComplete(() => bloc.add(const
    WorkoutOverviewReturnedFromFocus()))`
    - _Requirements: R1, R3 AC4, R12, R15, R16, R18, R19 AC2, R22_
    - _Design: §2.4, §9.1, §10_

  - [ ] 7.15 Implement the drag-and-drop integration inside
    `widgets/exercise_tile.dart` and `widgets/superset_frame.dart`:
    wrap unfinished tiles in `LongPressDraggable<String>` (payload
    = `sessionExerciseId`); render gap `DragTarget<String>` zones
    between consecutive unfinished tiles inside the screen body;
    on drop, call `DropResolver.resolve(...)` and dispatch
    `WorkoutOverviewDropResolved(intent)`; show the cross-superset
    `MaterialBanner` hint for the noop path described in design
    §8.4 (R5 AC3)
    - _Requirements: R4, R5_
    - _Design: §8_

  - [ ] 7.16 Add the public barrel exports to
    `workout_overview.dart`: `bloc/bloc.dart`,
    `models/exercise_view_model.dart`,
    `models/set_row_view_model.dart`,
    `models/superset_group_view_model.dart`,
    `models/drop_intent.dart`,
    `models/workout_overview_args.dart`,
    `screens/workout_overview_screen.dart`,
    `services/planned_summary_formatter.dart`,
    `services/exercise_view_model_assembler.dart`,
    `services/drop_resolver.dart`
    - _Requirements: R21 AC1_
    - _Design: §1.2_

- [ ] 8. Navigation re-binding and picker hand-off
  - [ ] 8.1 Update the picker's launch-success path: change every
    push of `SessionRoutes.active` inside
    `lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart`
    (the BlocListener on `videoLaunchIntents`-equivalent / launch
    intent) from passing a raw `String sessionId` to passing
    `WorkoutOverviewArgs(sessionId: sessionId)`; this is the only
    edit to the picker module
    - _Requirements: R17 AC4_
    - _Design: §2.2, §14 decision 10_

  - [ ] 8.2 Replace `_sessionActiveRoute` in
    `lib/navigation/app_router.dart` so it constructs
    `WorkoutOverviewScreen` from `WorkoutOverviewArgs` per design
    §2.2: throw `ArgumentError` when `settings.arguments` is not a
    `WorkoutOverviewArgs`; provide the BLoC via `BlocProvider` that
    reads `SessionFlowEngine` and `Clock` from `RepositoryProvider`s
    and dispatches `WorkoutOverviewOpened(args.sessionId)`
    - _Requirements: R17 AC1, R17 AC2, R17 AC3_
    - _Design: §2.2_

  - [ ] 8.3 Add `_sessionFocusRoute` to
    `lib/navigation/app_router.dart` per design §2.3 binding
    `SessionRoutes.focus` to `FocusModePlaceholderScreen` with the
    `sessionId` route argument
    - _Requirements: R16 AC4_
    - _Design: §2.3_

  - [ ] 8.4 Delete
    `lib/navigation/session_active_placeholder_screen.dart` and
    remove its import from `lib/navigation/app_router.dart`; verify
    no other file imports it via
    `grep -r 'session_active_placeholder_screen' lib/`
    - _Requirements: R17 AC2_
    - _Design: §2.2, §14 decision 9_

- [ ] 9. Final checkpoint
  - [ ] 9.1 Run the full check sequence:
    `tool/check_offline_imports.sh`,
    `dart run build_runner build --force-jit`,
    `flutter analyze`, and `flutter test`; ensure zero analyzer
    warnings, zero offline-import violations, and zero test
    failures across the new and pre-existing suites; ask the user
    if questions arise

## Notes

- Tasks marked with `*` are optional (low-risk validation already
  implied by another test). This spec has none of those today —
  every task is mandatory because the overview is the central hub
  the focus-mode and export specs both depend on.
- Each task references the requirements and design sections it
  implements for traceability.
- Generated files (`*.freezed.dart`, `*.g.dart`) must be
  regenerated after Tasks 2.x via
  `dart run build_runner build --force-jit`.
- All test files go under `test/modules/workout_overview/`
  matching the source layout.
- BLoC, widget, and integration tests are intentionally out of
  scope per the testing convention established by
  `program-management/tasks.md` and `workout-day-picker/tasks.md`;
  if a regression surfaces later, add the test then.
- `FocusModePlaceholderScreen` is intentionally tiny — it is
  replaced wholesale by the `focus-mode-screen` spec without
  touching this module.
- The picker-side argument-type change (Task 8.1) is the only edit
  to the picker module required by this spec; it is a localised
  type-safety improvement with no behavioural impact.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4", "1.5"] },
    { "id": 1, "tasks": ["2.1", "2.2", "2.5", "2.6"] },
    { "id": 2, "tasks": ["2.3", "2.4"] },
    { "id": 3, "tasks": ["3.1", "3.3", "3.5"] },
    { "id": 4, "tasks": ["3.2", "3.4", "3.6", "3.7", "3.8", "3.9", "3.10", "3.11"] },
    { "id": 5, "tasks": ["4.1"] },
    { "id": 6, "tasks": ["5.1", "5.2", "5.3"] },
    { "id": 7, "tasks": ["5.4"] },
    { "id": 8, "tasks": ["5.5", "5.6", "5.7", "5.8", "5.9"] },
    { "id": 9, "tasks": ["5.10", "5.11", "5.12", "5.13", "5.14", "5.15", "5.16", "5.17", "5.18", "5.19"] },
    { "id": 10, "tasks": ["6.1"] },
    { "id": 11, "tasks": ["7.1", "7.6", "7.7", "7.8", "7.9", "7.10", "7.11", "7.12", "7.13"] },
    { "id": 12, "tasks": ["7.2", "7.3"] },
    { "id": 13, "tasks": ["7.4"] },
    { "id": 14, "tasks": ["7.5"] },
    { "id": 15, "tasks": ["7.14", "7.15", "7.16"] },
    { "id": 16, "tasks": ["8.1", "8.2", "8.3", "8.4"] },
    { "id": 17, "tasks": ["9.1"] }
  ]
}
```
