# Implementation Plan: Workout Day Picker

## Overview

Implement the `WorkoutDayPickerScreen` and its supporting BLoC,
services, and navigation hooks. The work proceeds bottom-up: module
scaffold and offline guard first, then pure-Dart services (window,
formatter, summarizer) with their tests, then the BLoC, then the
screen and widgets, and finally the navigation wiring that connects
`ProgramListScreen` to the picker and the picker to a placeholder
session-active route. No domain or Drift change is required by this
spec — every entry point already exists.

**Not duplicated here (already done in prior specs):**

- `flutter_bloc`, `equatable`, `package:clock`, `freezed`, and
  `json_serializable` are already in `pubspec.yaml`.
- `lib/core/app_colors.dart`, `lib/core/app_spacing.dart`,
  `lib/core/app_typography.dart`, `lib/core/app_theme.dart`,
  `lib/core/app_error.dart`, and `lib/core/schema_versions.dart`
  exist and are read directly.
- `ProgramRepository`, `SessionRepository`, `SessionFlowEngine`, and
  the `Session` / `Program` / `WorkoutDay` aggregates are already
  exported by `package:zamaj/modules/domain/domain.dart`.

**Testing scope:** Only pure-Dart service tests are written (unit and
property-based) for the new `RelativeDateFormatter`,
`CurrentWeekWindow`, and `SessionHistorySummarizer`. BLoC tests,
widget tests, and screen/integration tests are out of scope, matching
the convention established by the prior UI spec
(`program-management/tasks.md`). Property-based tests appear alongside
the service they validate.

Conventions:

- Module lives under `lib/modules/workout_day_picker/` with barrel
  `workout_day_picker.dart` (R13 AC1).
- Sealed `Event` and `State` families with `Equatable` (R13 AC3).
- `package:zamaj/...` imports, single quotes, `const` everywhere the
  lint demands (R13 AC4).
- Property tests live alongside the service they validate and run
  ≥100 iterations inside standard `test()` blocks.

## Tasks

- [x] 1. Module scaffold and offline guard
  - [x] 1.1 Create the module folder scaffolding:
    `lib/modules/workout_day_picker/{bloc,screens,widgets,services,models,navigation}/`
    and an empty barrel file
    `lib/modules/workout_day_picker/workout_day_picker.dart`
    - _Requirements: R13 AC1, R13 AC2_
    - _Design: §1.2_

  - [x] 1.2 Extend `tool/check_offline_imports.sh` to additionally
    scan `lib/modules/workout_day_picker/` against the existing
    forbidden list (no new patterns); emit `<file>:<line>:<offending
    symbol>` on violations and exit non-zero
    - _Requirements: R11 AC1, R11 AC2, R12 AC5_
    - _Design: §12.1, §12.2_

  - [x] 1.3 Create the shared route-name file
    `lib/navigation/session_routes.dart` with
    `abstract final class SessionRoutes { static const active = '/session-active'; }`
    - _Requirements: R6 AC6_
    - _Design: §2.1_

  - [x] 1.4 Create
    `lib/modules/workout_day_picker/navigation/workout_day_picker_routes.dart`
    with `abstract final class WorkoutDayPickerRoutes { static const picker = '/workout-day-picker'; }`
    - _Requirements: R6 AC5_
    - _Design: §2.1_

- [x] 2. Pure-Dart value types and models
  - [x] 2.1 Define `WorkoutDayPickerArgs`
    (`models/workout_day_picker_args.dart`) as a freezed class with a
    required `String programId`; add `part` directives and run
    `dart run build_runner build --force-jit`
    - _Requirements: R1 AC1, R6 AC1_
    - _Design: §1.2_

  - [x] 2.2 Define `DayHistorySummary`
    (`models/day_history_summary.dart`) as a freezed class with
    required `DateTime? lastCompleted`, `int totalCompletedCount`,
    `int thisWeekCount`, and `String? activeSessionId`; regenerate
    - _Requirements: R2 AC3, R2 AC4, R2 AC5, R2 AC6, R2 AC7_
    - _Design: §5_

  - [x] 2.3 Define `DayTileStatus` (`models/day_view_model.dart`) as
    a freezed sealed union with variants `loading`,
    `loaded(DayHistorySummary summary)`, and `failure(DomainError
    error)`; use `@Freezed(unionKey: 'type')`
    - _Requirements: R2 AC8, R10 AC3_
    - _Design: §3.2_

  - [x] 2.4 Define `DayViewModel` (`models/day_view_model.dart`) as
    a freezed class bundling required `WorkoutDay workoutDay` and
    required `DayTileStatus status`; regenerate
    - _Requirements: R1 AC2_
    - _Design: §3.2_

- [ ] 3. Pure-Dart services
  - [ ] 3.1 Implement `CurrentWeekWindow`
    (`services/current_week_window.dart`) as a freezed class with
    fields `DateTime start` and `DateTime end` and a static factory
    `CurrentWeekWindow.compute(DateTime now)` that produces the
    Monday-anchored local-time window per the design pseudocode;
    regenerate
    - _Requirements: R8 AC1, R8 AC2, R8 AC3, R8 AC4, R8 AC5, R8 AC6_
    - _Design: §6_

  - [ ] 3.2 Write `test/modules/workout_day_picker/services/current_week_window_test.dart`
    covering: each weekday produces a Monday-anchored start; Monday at
    exactly 00:00:00.000 returns "now" as start; end equals start +
    7 calendar days; a window spanning a DST spring-forward day; a
    window spanning a DST fall-back day
    - _Requirements: R8 AC2, R8 AC3, R8 AC5_
    - _Design: §6_

  - [ ] 3.3 Implement `RelativeDateFormatter`
    (`services/relative_date_formatter.dart`) as a pure-Dart
    `abstract final class` with `static String format(DateTime target,
    DateTime now)` per the design pseudocode, hard-coded English
    weekday names, and the ISO `YYYY-MM-DD` fallback
    - _Requirements: R7 AC1, R7 AC2, R7 AC3, R7 AC4, R7 AC5, R7 AC6, R7 AC7_
    - _Design: §7_

  - [ ] 3.4 Write
    `test/modules/workout_day_picker/services/relative_date_formatter_test.dart`
    covering: Today (same instant), Today (different times same
    day), Yesterday, every weekday 2–6 days back, ISO branch at 7
    days, ISO branch for future dates, mixed-UTC inputs converting
    via `toLocal()`
    - _Requirements: R7 AC2, R7 AC3, R7 AC4, R7 AC5, R7 AC7_
    - _Design: §7_

  - [ ] 3.5 Write property test
    `test/modules/workout_day_picker/services/relative_date_formatter_determinism_property_test.dart`:
    generate ≥100 random `(target, now)` pairs spanning −365…+365
    days, invoke `format` twice, assert equality
    - _Requirements: R7 AC8_
    - _Design: §11.2_

  - [ ] 3.6 Implement `SessionHistorySummarizer`
    (`services/session_history_summarizer.dart`) as an
    `abstract final class` with `static DayHistorySummary
    summarize(List<Session> sessions, CurrentWeekWindow window)`,
    iterating once with the tie-break helper `_beats`
    - _Requirements: R2 AC3, R2 AC4, R2 AC5, R2 AC6, R2 AC7, R9 AC1, R9 AC2, R9 AC3, R9 AC4_
    - _Design: §5_

  - [ ] 3.7 Write
    `test/modules/workout_day_picker/services/session_history_summarizer_test.dart`
    covering: empty list → all zeros and nulls; one Completed only;
    one Active only; mixed counts; week-window boundary inclusivity
    (start inclusive, end exclusive); active tie-break across
    `updatedAt`, then `startedAt`, then `id`
    - _Requirements: R2 AC3–AC7, R9 AC1–AC4_
    - _Design: §5_

  - [ ] 3.8 Write property test
    `test/modules/workout_day_picker/services/summarizer_count_property_test.dart`:
    generate ≥100 random `List<Session>` plus a random window;
    assert `totalCompletedCount` equals naive count and
    `thisWeekCount` equals naive count
    - _Requirements: R9 AC2, R9 AC3_
    - _Design: §11.2_

  - [ ] 3.9 Write property test
    `test/modules/workout_day_picker/services/summarizer_tiebreak_property_test.dart`:
    generate `≥2` active sessions with controlled `updatedAt /
    startedAt / id` triples; assert `activeSessionId` equals the
    expected extremum
    - _Requirements: R9 AC4_
    - _Design: §11.2_

  - [ ] 3.10 Write property test
    `test/modules/workout_day_picker/services/summarizer_determinism_property_test.dart`:
    invoke twice on the same input and assert equal outputs
    - _Requirements: R9 AC5_
    - _Design: §11.2_

  - [ ] 3.11 Write property test
    `test/modules/workout_day_picker/services/summarizer_permutation_property_test.dart`:
    invoke on every shuffle of the input list and assert equal outputs
    - _Requirements: R9 AC6_
    - _Design: §11.2_

- [ ] 4. Checkpoint — services + tests
  - [ ] 4.1 Run `dart run build_runner build --force-jit`,
    `flutter analyze`, and `flutter test test/modules/workout_day_picker/services/`
    and ensure zero analyzer warnings and zero test failures; ask
    the user if questions arise

- [ ] 5. BLoC: events, states, and load algorithm
  - [ ] 5.1 Create `bloc/workout_day_picker_event.dart` with the
    sealed `WorkoutDayPickerEvent` family per design §3.1
    (`Opened`, `RefreshRequested`, `ReturnedFromSession`,
    `ScreenRetryRequested`, `TileRetryRequested(workoutDayId)`,
    `StartPressed(workoutDayId)`,
    `ResumePressed({workoutDayId, activeSessionId})`,
    `ErrorDismissed`)
    - _Requirements: R1 AC1, R2 AC8, R4 AC1, R5 AC1, R6 AC3, R6 AC4, R10 AC2, R10 AC3, R14 AC2, R14 AC3_
    - _Design: §3.1_

  - [ ] 5.2 Create `bloc/workout_day_picker_state.dart` with the
    sealed `WorkoutDayPickerState` family per design §3.2
    (`Initial`, `Loading(programId)`, `ProgramNotFound(programId)`,
    `ScreenFailure({programId, error})`, `Loaded({...})`)
    - _Requirements: R1 AC1, R1 AC3, R1 AC5, R1 AC6, R10 AC1, R10 AC2_
    - _Design: §3.2_

  - [ ] 5.3 Create `bloc/bloc.dart` barrel that re-exports
    `workout_day_picker_bloc.dart`,
    `workout_day_picker_event.dart`, and
    `workout_day_picker_state.dart`
    - _Requirements: R13 AC1, R13 AC2_
    - _Design: §1.2_

  - [ ] 5.4 Implement `WorkoutDayPickerBloc`
    (`bloc/workout_day_picker_bloc.dart`) with constructor-injected
    `ProgramRepository`, `SessionRepository`, `SessionFlowEngine`,
    and `Clock`; private fields for the navigation-intent
    `StreamController<String>` exposed as `Stream<String>
    navigationIntents`; close the controller in `close()`
    - _Requirements: R12 AC3_
    - _Design: §1.3, §3.5_

  - [ ] 5.5 Implement the `on<WorkoutDayPickerOpened>` handler
    following design §4.1: capture `now = clock.now()`, compute
    window, load Program, branch to `ProgramNotFound` when null,
    fetch workout-day list, kick off per-day session-list loads in
    parallel with per-future error mapping, assemble `DayViewModel`s,
    emit `Loaded`; on top-level throw emit `ScreenFailure`
    - _Requirements: R1 AC1, R1 AC3, R1 AC4, R1 AC5, R1 AC6, R2 AC1, R2 AC2, R2 AC8, R8 AC6_
    - _Design: §4.1_

  - [ ] 5.6 Implement
    `on<WorkoutDayPickerScreenRetryRequested>` re-running the
    `Opened` algorithm with the `programId` from the current state
    - _Requirements: R10 AC2, R14 AC2_
    - _Design: §3.3_

  - [ ] 5.7 Implement `on<WorkoutDayPickerTileRetryRequested>` per
    design §4.2: emit `Loaded` with the target tile set to
    `loading`, await `listSessionsForWorkoutDay`, emit `Loaded`
    with the tile updated to `loaded` or `failure`
    - _Requirements: R2 AC8, R10 AC3, R14 AC3_
    - _Design: §4.2_

  - [ ] 5.8 Implement `on<WorkoutDayPickerRefreshRequested>` and
    `on<WorkoutDayPickerReturnedFromSession>` as full reloads
    (same algorithm as `Opened`, same `programId`)
    - _Requirements: R6 AC3, R6 AC4_
    - _Design: §4.3_

  - [ ] 5.9 Implement `on<WorkoutDayPickerStartPressed>`: short-circuit
    when `launchInFlightWorkoutDayId != null`; otherwise emit
    `Loaded` with the field set, call
    `sessionFlowEngine.startSession(workoutDayId: ...)`, on
    success push the returned `sessionState.session.id` to
    `_navigationIntents` and emit `Loaded` with the field cleared;
    on `DomainError` emit `Loaded` with `lastTransientError`
    populated and the field cleared
    - _Requirements: R4 AC1, R4 AC2, R4 AC3, R4 AC4, R4 AC5, R10 AC5_
    - _Design: §3.3, §3.5_

  - [ ] 5.10 Implement `on<WorkoutDayPickerResumePressed>`:
    short-circuit when `launchInFlightWorkoutDayId != null`;
    otherwise emit `Loaded` with the field set, call
    `sessionFlowEngine.resumeSession(sessionId: ...)`, on success
    push the returned `sessionState.session.id` to
    `_navigationIntents` and emit `Loaded` with the field cleared;
    on `NotFoundError` clear the field and trigger a per-tile
    reload (R5 AC4); on any other `DomainError` clear the field
    and set `lastTransientError`
    - _Requirements: R5 AC1, R5 AC2, R5 AC3, R5 AC4, R5 AC5, R5 AC6, R10 AC5, R14 AC4_
    - _Design: §3.3, §3.5_

  - [ ] 5.11 Implement `on<WorkoutDayPickerErrorDismissed>`:
    when state is `Loaded` and `lastTransientError != null`, emit
    `Loaded` with `lastTransientError: null`
    - _Requirements: R10 AC2 (transient banner dismissal), R14 AC1_
    - _Design: §3.3_

- [ ] 6. Checkpoint — BLoC compiles
  - [ ] 6.1 Run `dart run build_runner build --force-jit`,
    `flutter analyze`, and the existing
    `flutter test test/modules/workout_day_picker/services/` to
    confirm the new BLoC compiles and the existing service tests
    still pass; ensure zero analyzer warnings and zero test failures;
    ask the user if questions arise

- [ ] 7. Widgets and screen
  - [ ] 7.1 Build `widgets/start_resume_action_button.dart`: takes
    `{required bool isResume, required bool busy, required bool
    enabled, required VoidCallback onPressed}`; renders an outlined
    button labelled `START` or `RESUME`; renders a centred spinner
    when `busy`; renders disabled when `!enabled`
    - _Requirements: R3 AC8, R3 AC9, R4 AC2, R5 AC2, R10 AC5_
    - _Design: §8_

  - [ ] 7.2 Build `widgets/day_tile_history_labels.dart`: takes
    `{required DayHistorySummary summary, required DateTime
    referenceNow}`; renders the three label lines per R3 AC1–AC7
    using `RelativeDateFormatter.format` and the literal `×` character
    - _Requirements: R3 AC1, R3 AC2, R3 AC3, R3 AC4, R3 AC5, R3 AC6, R3 AC7_
    - _Design: §8_

  - [ ] 7.3 Build `widgets/day_tile.dart`: takes `DayViewModel`,
    `referenceNow`, `launchInFlightWorkoutDayId`, and three
    callbacks (`onStartPressed`, `onResumePressed`,
    `onRetryPressed`); switches on `DayTileStatus` to render the
    skeleton, the loaded labels + action button, or the per-tile
    error with retry per design §8
    - _Requirements: R1 AC2, R2 AC8, R3 AC8, R3 AC9, R10 AC3_
    - _Design: §8_

  - [ ] 7.4 Build the three state widgets:
    `widgets/workout_day_picker_loading_view.dart`,
    `widgets/workout_day_picker_empty_view.dart` (with the "Edit
    program" affordance), and
    `widgets/workout_day_picker_error_view.dart` (with the typed
    error invariant/field message and a retry button)
    - _Requirements: R1 AC4, R1 AC5, R10 AC1, R10 AC2, R10 AC4, R14 AC1_
    - _Design: §10_

  - [ ] 7.5 Build `screens/workout_day_picker_screen.dart`:
    `BlocProvider<WorkoutDayPickerBloc>` instantiated with the
    repositories and engine read from `RepositoryProvider`s;
    `AppBar` with the loaded program name (or "Loading…") and a
    refresh action that dispatches `WorkoutDayPickerRefreshRequested`;
    body switches on the state to render the matching widget; a
    `BlocListener` translates `_navigationIntents` stream events
    into `Navigator.pushNamed(SessionRoutes.active,
    arguments: sessionId).whenComplete(() =>
    bloc.add(const WorkoutDayPickerReturnedFromSession()))`; on
    `lastTransientError != null` show a `MaterialBanner` with the
    typed error message and an OK action dispatching
    `WorkoutDayPickerErrorDismissed`
    - _Requirements: R1 AC1, R1 AC3, R1 AC4, R1 AC5, R1 AC6, R4 AC3, R5 AC3, R6 AC2, R6 AC3, R6 AC4, R10, R14 AC1_
    - _Design: §2.4, §10_

  - [ ] 7.6 Add the public barrel exports to
    `workout_day_picker.dart`: `bloc/bloc.dart`,
    `models/day_history_summary.dart`,
    `models/day_view_model.dart`,
    `models/workout_day_picker_args.dart`,
    `navigation/workout_day_picker_routes.dart`,
    `screens/workout_day_picker_screen.dart`,
    `services/current_week_window.dart`,
    `services/relative_date_formatter.dart`,
    `services/session_history_summarizer.dart`
    - _Requirements: R13 AC1_
    - _Design: §1.2_

- [ ] 8. Navigation wiring
  - [ ] 8.1 Add a "Train" trailing icon button to
    `lib/modules/program_management/widgets/program_list_tile.dart`
    that calls `Navigator.of(context).pushNamed(
    WorkoutDayPickerRoutes.picker,
    arguments: WorkoutDayPickerArgs(programId: program.id))`;
    preserve the existing tap-on-tile-to-editor behaviour
    - _Requirements: R6 AC1, R6 AC5_
    - _Design: §2.2_

  - [ ] 8.2 Create
    `screens/session_active_placeholder_screen.dart` (a tiny
    `Scaffold` showing the passed session id and a back button) and
    register `SessionRoutes.active` to it in the existing
    `onGenerateRoute` (or app router) inside `lib/app.dart` or the
    router file; mark the file with a comment noting it is replaced
    by the future `workout-overview-screen`
    - _Requirements: R6 AC6_
    - _Design: §2.3, §13 decision 6_

  - [ ] 8.3 Register `WorkoutDayPickerRoutes.picker` in
    `onGenerateRoute`: the route parses
    `WorkoutDayPickerArgs` from `settings.arguments` and pushes
    `WorkoutDayPickerScreen` with a `BlocProvider` that constructs
    the BLoC and dispatches `WorkoutDayPickerOpened(args.programId)`
    - _Requirements: R6 AC1, R6 AC5_
    - _Design: §2.1, §2.3_

- [ ] 9. Final checkpoint
  - [ ] 9.1 Run the full check sequence:
    `tool/check_offline_imports.sh`,
    `dart run build_runner build --force-jit`,
    `flutter analyze`,
    and `flutter test`; ensure zero analyzer warnings, zero offline-
    import violations, and zero test failures across the new and
    pre-existing suites; ask the user if questions arise

## Notes

- Tasks marked with `*` are optional (low-risk validation already
  implied by another test). This spec has none of those today —
  every task is mandatory because the picker is on the critical
  path to the next two screens.
- Each task references the requirements and design sections it
  implements for traceability.
- Generated files (`*.freezed.dart`, `*.g.dart`) must be
  regenerated after Tasks 2.x and 3.1 via
  `dart run build_runner build --force-jit`.
- All test files go under `test/modules/workout_day_picker/`
  matching the source layout.
- BLoC, widget, and integration tests are intentionally out of
  scope per the testing convention established by
  `program-management/tasks.md`; if a regression surfaces later, add
  the test then.
- The `SessionActivePlaceholderScreen` is intentionally tiny — it
  is replaced wholesale by the `workout-overview-screen` spec
  without touching this module.

## Model Selection Guide

**Run with Sonnet** (mechanical scaffolding, boilerplate, simple
delegation):

- 1.1, 1.3, 1.4 — folder layout and route-name files
- 1.2 — extending the existing offline-imports script with one
  additional scan path (no new patterns)
- 2.1–2.4 — adding freezed classes and unions
- 3.1, 3.3 — translating the design pseudocode for the window and
  the formatter into Dart
- 5.1–5.3 — declaring events, states, and the BLoC barrel
- 5.11 — trivial transient-error reducer
- 6.1 — checkpoint run
- 7.1, 7.2, 7.4 — building stateless widgets that take props and
  render labels/buttons
- 7.6 — exporting from the barrel
- 8.1, 8.2, 8.3 — wiring the route table
- 9.1 — running the check sequence

**Run with Opus** (state machines, concurrency, property tests):

- 3.6 — `SessionHistorySummarizer` (tie-break and stat
  computation in one pass; must be order-independent)
- 3.2 — `CurrentWeekWindow` tests including DST cases
- 3.5, 3.8–3.11 — property tests (generator design and shrinking
  matter more than the test bodies)
- 5.4 — BLoC scaffolding with the `StreamController` lifecycle
- 5.5 — `Opened` handler (parallel per-day loads with per-future
  error containment is easy to get wrong)
- 5.9, 5.10 — `Start`/`Resume` handlers (concurrency guards plus
  `NotFoundError` reload path)
- 7.3, 7.5 — `DayTile` and the screen wiring (`BlocListener`
  for the navigation-intents stream)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4"] },
    { "id": 1, "tasks": ["2.1", "2.2", "2.3", "2.4"] },
    { "id": 2, "tasks": ["3.1", "3.3", "3.6"] },
    { "id": 3, "tasks": ["3.2", "3.4", "3.5", "3.7", "3.8", "3.9", "3.10", "3.11"] },
    { "id": 4, "tasks": ["4.1"] },
    { "id": 5, "tasks": ["5.1", "5.2", "5.3"] },
    { "id": 6, "tasks": ["5.4"] },
    { "id": 7, "tasks": ["5.5", "5.6", "5.7", "5.8", "5.9", "5.10", "5.11"] },
    { "id": 8, "tasks": ["6.1"] },
    { "id": 9, "tasks": ["7.1", "7.2", "7.4"] },
    { "id": 10, "tasks": ["7.3", "7.5", "7.6"] },
    { "id": 11, "tasks": ["8.1", "8.2", "8.3"] },
    { "id": 12, "tasks": ["9.1"] }
  ]
}
```
