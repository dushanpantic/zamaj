# Requirements Document

## Introduction

The **workout-day-picker** feature is the screen the athlete sees between
selecting a Program and entering Focus Mode. It is the bridge between the
already-completed `program-management` UI and the already-completed
`session-flow-engine`. Given a Program, the picker lists that Program's
Workout Days, shows lightweight history per day (when each day was last
trained, how many sessions exist for it), and starts or resumes a Session
via `SessionFlowEngine` when the user taps a day.

The feature covers:

- A picker screen that lists every Workout Day of a Program in template
  order.
- Per-day display of the Program's exercise group count, the date and
  relative description of the day's most recent completed Session, and the
  total Session count for that day in the current week and overall.
- Detection of an in-progress (not-yet-ended) Session for a day, surfaced
  as a distinct "Resume" affordance rather than "Start".
- A launch action that delegates to `SessionFlowEngine.startSession` for
  fresh starts and `SessionFlowEngine.resumeSession` for in-progress
  Sessions, navigates to the session-active route, and refreshes per-day
  history when the user returns.
- A deterministic, locale-neutral relative-date formatter for "Today",
  "Yesterday", weekday names within the last seven days, and absolute
  ISO-style dates beyond that window.
- Empty, loading, error, and not-found surfaces consistent with the rest
  of the app.
- An entry point from `ProgramListScreen` so the user can move from
  picking a Program to picking its day in two taps.

The feature explicitly does NOT deliver:

- The Workout Overview screen, the Focus Mode screen, the rest timer, or
  export (those are separate specs).
- Editing a Workout Day's structure (that lives in `program-management`'s
  `Workout_Day_Editor_Screen`).
- Calendar scheduling, reminders, or push notifications — the user
  manually picks a day every time, per the product brief.
- Multi-Program "Today" aggregation or an "Active Program" concept.
- Any UI for the Workout Overview screen; this spec's launch action ends
  at the navigation hand-off described in Requirement 6.

## Glossary

- **Workout_Day_Picker_Module**: The Flutter feature module that owns
  every screen, BLoC, widget, and service described by this spec. Lives
  under `lib/modules/workout_day_picker/` following the conventions in
  `init.md`.
- **Workout_Day_Picker_Screen**: The single screen this spec introduces.
  Lists every Workout Day for one Program with per-day history and a
  launch action.
- **Workout_Day_Picker_Args**: The typed navigation argument carrying the
  `String programId` whose Workout Days the screen displays.
- **Day_Tile**: One row of the Workout_Day_Picker_Screen corresponding to
  one Workout Day. Renders the day's name, its exercise group count, its
  history summary, and its launch affordance.
- **Day_History_Summary**: The per-day aggregate carrying the day's last
  completed `Session` timestamp (nullable), its total completed Session
  count, its completed-this-week Session count, and the optional active
  `Session` id when an unfinished Session exists.
- **Active_Session**: A `Session` whose `endedAt` field is null. Per
  `session-flow-engine` the engine considers an ended session read-only;
  the picker therefore distinguishes ended (completed history) from
  active (resumable).
- **Completed_Session**: A `Session` whose `endedAt` field is non-null.
- **Current_Week_Window**: The half-open `[start, end)` interval starting
  at 00:00:00 of the current Monday in the device's local time zone and
  ending at 00:00:00 of the following Monday. "This week" counts of
  Sessions reference this window.
- **Relative_Date_Formatter**: The pure Dart service that turns a
  `DateTime` and a reference "now" into a short human label ("Today",
  "Yesterday", a weekday name, or an ISO `YYYY-MM-DD` date).
- **Session_History_Summarizer**: The pure Dart service that consumes a
  `List<Session>` for one Workout Day and produces one
  `Day_History_Summary`.
- **Program_Repository**: The abstract contract at
  `lib/modules/domain/repositories/program_repository.dart`. The picker
  reads `listWorkoutDaysForProgram` and `getProgram`; it never writes.
- **Session_Repository**: The abstract contract at
  `lib/modules/domain/repositories/session_repository.dart`. The picker
  reads `listSessionsForWorkoutDay`; it never writes directly.
- **Session_Flow_Engine**: The service at
  `lib/modules/domain/services/session_flow_engine.dart`. The picker uses
  `startSession` and `resumeSession`; it does not call repository write
  methods directly.
- **App_Clock**: The `Clock` instance from `package:clock` injected
  through composition. Every "now" used by the picker (date math,
  history grouping, formatter reference time) comes from this clock so
  tests stay deterministic.
- **Session_Active_Route**: The route name the picker navigates to after
  a successful `startSession` or `resumeSession`. Until the
  `workout-overview-screen` spec lands, this route is a placeholder
  defined under Requirement 6 Acceptance Criterion 6.
- **Offline_Device**: A device with no network connectivity at the
  moment of operation.

## Requirements

### Requirement 1: Workout Day Picker Screen Layout

**User Story:** As an athlete who has opened a Program, I want one
screen that lists that Program's Workout Days with enough context to
pick today's session, so that I can start lifting in two taps.

#### Acceptance Criteria

1. WHEN the Workout_Day_Picker_Screen is opened with a Workout_Day_Picker_Args carrying a programId that resolves to an existing Program through the Program_Repository, THE Workout_Day_Picker_Module SHALL load that Program and its Workout Days through the Program_Repository and display the Program's name in the screen header and the Workout Days as an ordered list whose order equals the Workout Day order persisted by the Program_Repository.
2. THE Workout_Day_Picker_Screen SHALL render one Day_Tile per Workout Day, where each Day_Tile shows the Workout Day's name verbatim, the integer count of its exercise groups labelled "<n> exercise groups" or "<n> exercise group" with the singular form used when n equals 1, and the Workout Day's Day_History_Summary fields per Requirement 3.
3. IF the Workout_Day_Picker_Screen is opened with a programId that does not resolve to an existing Program through the Program_Repository, THEN THE Workout_Day_Picker_Module SHALL display a not-found surface with a back affordance and SHALL NOT attempt to render any Day_Tile.
4. WHILE the Program has zero Workout Days, THE Workout_Day_Picker_Screen SHALL display an empty-state surface naming the Program and offering a single affordance whose tap navigates to the Program_Editor_Screen for the same programId.
5. IF the Program_Repository fails to load the Program or its Workout Days, THEN THE Workout_Day_Picker_Screen SHALL display an error surface containing the typed `DomainError`'s `invariant` or `field` descriptor verbatim and a retry affordance that re-invokes the load.
6. WHILE the initial load is in flight, THE Workout_Day_Picker_Screen SHALL display a loading surface and SHALL NOT render any Day_Tile.

### Requirement 2: Per-Day Session History Load

**User Story:** As an athlete picking a day, I want to see when I last
did it and how often I've trained it, so that I can choose a day I
haven't hit yet.

#### Acceptance Criteria

1. WHEN the Workout_Day_Picker_Screen displays a list of Workout Days, THE Workout_Day_Picker_Module SHALL invoke `SessionRepository.listSessionsForWorkoutDay(workoutDayId)` exactly once per Workout Day shown.
2. THE Workout_Day_Picker_Module SHALL aggregate every returned `Session` list into one Day_History_Summary per Workout Day through the Session_History_Summarizer (Requirement 9).
3. WHEN the per-day Session list returned for a given Workout Day is empty, THE Day_History_Summary for that day SHALL carry a null last-completed timestamp, an integer total completed Session count of 0, an integer current-week Session count of 0, and a null active Session id.
4. WHEN the per-day Session list returned for a given Workout Day contains at least one Completed_Session, THE Day_History_Summary's last-completed timestamp SHALL equal the maximum `endedAt` value across the Completed_Sessions in that list.
5. THE Day_History_Summary's total completed Session count SHALL equal the count of Completed_Sessions in the per-day list.
6. THE Day_History_Summary's current-week Session count SHALL equal the count of Completed_Sessions whose `endedAt` value lies inside the Current_Week_Window (Requirement 8).
7. WHEN the per-day Session list returned for a given Workout Day contains at least one Active_Session, THE Day_History_Summary's active Session id SHALL equal the id of the Active_Session with the maximum `updatedAt` value across the Active_Sessions in that list; ties on `updatedAt` SHALL be broken by the maximum `startedAt` value, then by the maximum `id` under lexicographic comparison.
8. IF `SessionRepository.listSessionsForWorkoutDay` returns a typed `DomainError` for any Workout Day, THEN THE Workout_Day_Picker_Module SHALL leave that Day_Tile in a per-tile error state that names the failed Workout Day and offers a per-tile retry affordance, AND SHALL render the remaining Day_Tiles normally.

### Requirement 3: Day Tile Display Rules

**User Story:** As a user scanning the picker, I want a quick read on
each day's status, so that I do not have to think while picking.

#### Acceptance Criteria

1. WHEN a Day_Tile's Day_History_Summary carries a non-null last-completed timestamp, THE Day_Tile SHALL display the label "Last completed: <relative-date>" where `<relative-date>` is the output of `Relative_Date_Formatter.format(lastCompleted, now)` (Requirement 7) evaluated with `now` equal to the App_Clock's current time captured at picker load.
2. WHEN a Day_Tile's Day_History_Summary carries a null last-completed timestamp and a current-week Session count of 0, THE Day_Tile SHALL display the label "Not completed yet".
3. WHEN a Day_Tile's Day_History_Summary carries a null last-completed timestamp and a current-week Session count greater than 0, THE Workout_Day_Picker_Module SHALL treat that combination as an invariant violation and SHALL display an inline error on that Day_Tile naming the invariant "no_last_completed_with_nonzero_week_count"; this combination is unreachable through normal data flow but the assertion guards against future drift.
4. WHEN a Day_Tile's Day_History_Summary carries a current-week Session count of 0 and a non-null last-completed timestamp, THE Day_Tile SHALL display a secondary label "Not completed this week".
5. WHEN a Day_Tile's Day_History_Summary carries a current-week Session count greater than 0, THE Day_Tile SHALL display a secondary label "<n>× this week" using the literal multiplication-sign character `×` (U+00D7).
6. WHEN a Day_Tile's Day_History_Summary carries a total completed Session count greater than 0, THE Day_Tile SHALL display a tertiary label "<n> total" with the integer count.
7. WHEN a Day_Tile's Day_History_Summary carries a total completed Session count of 0, THE Day_Tile SHALL omit the tertiary label.
8. WHEN a Day_Tile's Day_History_Summary carries a non-null active Session id, THE Day_Tile SHALL display a visually distinct "In progress" marker and SHALL replace the launch affordance described in Requirement 4 with a "Resume" affordance per Requirement 5.
9. WHEN a Day_Tile's Day_History_Summary carries a null active Session id, THE Day_Tile SHALL display the launch affordance as a "Start" affordance per Requirement 4.

### Requirement 4: Start a Fresh Session

**User Story:** As an athlete with no in-progress session for the day I
picked, I want one tap to start fresh, so that I am not asked
unnecessary questions.

#### Acceptance Criteria

1. WHEN the user activates the "Start" affordance on a Day_Tile whose Day_History_Summary carries a null active Session id, THE Workout_Day_Picker_Module SHALL invoke `SessionFlowEngine.startSession(workoutDayId: <tile's workoutDayId>)` exactly once.
2. WHILE the `startSession` future is pending, THE Workout_Day_Picker_Module SHALL display a per-tile busy indicator on the originating Day_Tile and SHALL ignore further activations of any "Start" or "Resume" affordance on any Day_Tile until the future resolves.
3. WHEN `SessionFlowEngine.startSession` returns a `SessionState`, THE Workout_Day_Picker_Module SHALL navigate to the Session_Active_Route passing the returned `SessionState.session.id` as a route argument.
4. IF `SessionFlowEngine.startSession` throws or returns a typed `DomainError`, THEN THE Workout_Day_Picker_Module SHALL clear the per-tile busy indicator, SHALL leave the Day_Tile in the same display state it occupied immediately before the activation, and SHALL display a non-blocking error indicator that names the error's `invariant` or `field` descriptor verbatim and an "OK" dismiss affordance.
5. THE Workout_Day_Picker_Module SHALL NOT invoke `SessionRepository.startSession` directly; every start path SHALL go through `SessionFlowEngine.startSession`.

### Requirement 5: Resume an In-Progress Session

**User Story:** As an athlete who left a session open, I want to pick
the same day and continue where I left off, so that I do not duplicate
or lose work.

#### Acceptance Criteria

1. WHEN the user activates the "Resume" affordance on a Day_Tile whose Day_History_Summary carries a non-null active Session id, THE Workout_Day_Picker_Module SHALL invoke `SessionFlowEngine.resumeSession(sessionId: <Day_History_Summary.activeSessionId>)` exactly once.
2. WHILE the `resumeSession` future is pending, THE Workout_Day_Picker_Module SHALL display a per-tile busy indicator on the originating Day_Tile and SHALL ignore further activations of any "Start" or "Resume" affordance on any Day_Tile until the future resolves.
3. WHEN `SessionFlowEngine.resumeSession` returns a `SessionState`, THE Workout_Day_Picker_Module SHALL navigate to the Session_Active_Route passing the returned `SessionState.session.id` as a route argument.
4. IF `SessionFlowEngine.resumeSession` throws a `NotFoundError`, THEN THE Workout_Day_Picker_Module SHALL re-load the failing Day_Tile's Day_History_Summary per Requirement 2 and SHALL display an inline message on that Day_Tile stating the active session could not be resumed; once the reload completes, the affordance SHALL transition to "Start" if and only if the reloaded Day_History_Summary carries a null active Session id.
5. IF `SessionFlowEngine.resumeSession` throws or returns any typed `DomainError` other than `NotFoundError`, THEN THE Workout_Day_Picker_Module SHALL clear the per-tile busy indicator, SHALL leave the Day_Tile in the same display state it occupied immediately before the activation, and SHALL display a non-blocking error indicator that names the error's `invariant` or `field` descriptor verbatim and an "OK" dismiss affordance.
6. THE Workout_Day_Picker_Module SHALL NOT call any `SessionRepository` mutation method directly; the only path from the picker into Session mutation SHALL be `SessionFlowEngine.startSession` and `SessionFlowEngine.resumeSession`.

### Requirement 6: Navigation Hand-off and History Refresh

**User Story:** As an athlete who finished or paused a session, I want
returning to the picker to show the updated history, so that I always
see truth, not stale state.

#### Acceptance Criteria

1. WHEN the user navigates from the Program_List_Screen to the Workout_Day_Picker_Screen, THE Workout_Day_Picker_Module SHALL receive the chosen programId through typed route arguments and SHALL load Workout Days and Day_History_Summaries per Requirements 1 and 2.
2. WHEN the user navigates from the Workout_Day_Picker_Screen to the Session_Active_Route by activating a "Start" or "Resume" affordance, THE Workout_Day_Picker_Module SHALL push the Session_Active_Route onto the navigator and SHALL NOT replace the Workout_Day_Picker_Screen in the navigation stack.
3. WHEN control returns to the Workout_Day_Picker_Screen after the Session_Active_Route is popped, THE Workout_Day_Picker_Module SHALL re-load the Day_History_Summary for every Workout Day shown per Requirement 2 before re-enabling the "Start" and "Resume" affordances.
4. THE Workout_Day_Picker_Screen SHALL expose a manual "refresh" affordance that, when activated, re-loads the Program through the Program_Repository and re-loads every Day_History_Summary per Requirement 2.
5. THE Program_List_Screen SHALL expose, on every program list tile, a launch affordance whose activation navigates to the Workout_Day_Picker_Screen with that program's id as the Workout_Day_Picker_Args.
6. THE Workout_Day_Picker_Module SHALL declare a `Session_Active_Route` route-name constant in a shared navigation file under `lib/navigation/`, with the value `'/session-active'`; the picker SHALL NOT register a screen for this route, but SHALL pass `SessionState.session.id` as the route argument when navigating to it; until the `workout-overview-screen` spec registers a real screen for this route, the app composition layer SHALL bind the route to a placeholder scaffold that displays the passed session id and a back affordance.

### Requirement 7: Relative-Date Formatter

**User Story:** As a developer building the Day_Tile labels and as a
user reading them, I want compact, predictable date labels with no
locale ambiguity, so that the picker stays scannable and tests stay
deterministic.

#### Acceptance Criteria

1. THE Relative_Date_Formatter SHALL expose a pure Dart static function `format(DateTime target, DateTime now)` returning a `String`.
2. WHEN `target` and `now` fall on the same local calendar date (same `year`, `month`, and `day` after converting both to local time), THE Relative_Date_Formatter SHALL return the string "Today".
3. WHEN `target` falls on the local calendar date exactly one day before `now`'s local calendar date, THE Relative_Date_Formatter SHALL return the string "Yesterday".
4. WHEN `target` falls on a local calendar date strictly more than one day before `now`'s local calendar date and strictly less than seven days before `now`'s local calendar date, THE Relative_Date_Formatter SHALL return the English weekday name of `target` ("Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday", or "Sunday").
5. WHEN `target` falls on a local calendar date that is greater than or equal to seven days before `now`'s local calendar date, or any number of days after `now`'s local calendar date, THE Relative_Date_Formatter SHALL return the ISO-style string `YYYY-MM-DD` derived from `target`'s local-time year, month, and day, zero-padding month and day to two digits and zero-padding year to four digits.
6. THE Relative_Date_Formatter SHALL NOT depend on the system locale, on `package:intl`, or on any locale-resolution side effect.
7. FOR ALL pairs `(target, now)` where `target == now`, THE Relative_Date_Formatter SHALL return "Today".
8. FOR ALL invocations of `Relative_Date_Formatter.format(t, n)` within the same process, the function SHALL be deterministic — two invocations with the same `t` and `n` SHALL return equal `String` values.

### Requirement 8: Current-Week Window

**User Story:** As a user, I want "this week" to mean a Monday-to-Monday
block in my own time zone, so that the count matches the way my coach
plans my training week.

#### Acceptance Criteria

1. THE Workout_Day_Picker_Module SHALL define the Current_Week_Window as a half-open `[start, end)` interval of `DateTime` values in the device's local time zone.
2. THE `start` of the Current_Week_Window SHALL equal the most recent local-time instant at which the local weekday transitioned to Monday at the local civil time 00:00:00.000, computed from the App_Clock's "now" captured at picker load.
3. THE `end` of the Current_Week_Window SHALL equal `start` plus exactly seven calendar days where the addition is performed by incrementing the local calendar date by seven days and preserving the local civil time 00:00:00.000.
4. THE Current_Week_Window SHALL include every `endedAt` value greater than or equal to `start` and strictly less than `end`.
5. WHEN the App_Clock's "now" falls on Monday at exactly 00:00:00.000 local time, THE `start` of the Current_Week_Window SHALL equal "now" itself.
6. THE Workout_Day_Picker_Module SHALL recompute the Current_Week_Window every time it triggers a Day_History_Summary load per Requirement 2 so that crossing midnight or crossing the Monday boundary between activations produces a fresh window.

### Requirement 9: Session History Summarizer Correctness

**User Story:** As a developer relying on the summarizer for every
Day_Tile, I want its behavior pinned down so future changes cannot
silently break the "this week" or "last completed" labels.

#### Acceptance Criteria

1. FOR ALL `(sessions, window, now)` triples where `sessions` is a `List<Session>` for one Workout Day, `window` is a Current_Week_Window, and `now` is a reference `DateTime`, THE Session_History_Summarizer SHALL produce a Day_History_Summary whose `lastCompleted` is the maximum `endedAt` over Completed_Sessions in `sessions` or null when no Completed_Session exists.
2. FOR ALL `(sessions, window, now)` triples as above, the Session_History_Summarizer's produced `totalCompletedCount` SHALL equal the count of Completed_Sessions in `sessions`.
3. FOR ALL `(sessions, window, now)` triples as above, the Session_History_Summarizer's produced `thisWeekCount` SHALL equal the count of Completed_Sessions in `sessions` whose `endedAt` is in `window`.
4. FOR ALL `(sessions, window, now)` triples as above, the Session_History_Summarizer's produced `activeSessionId` SHALL equal the id selected by the tie-break order defined in Requirement 2 Acceptance Criterion 7 when at least one Active_Session exists in `sessions`, and SHALL equal null otherwise.
5. FOR ALL `(sessions, window, now)` triples as above, the Session_History_Summarizer SHALL produce equal Day_History_Summary values when invoked twice within the same process with the same inputs (determinism property).
6. FOR ALL `(sessions, window, now)` triples as above, the Session_History_Summarizer SHALL produce identical results when `sessions` is reordered into any permutation (order-independence property).
7. THE Session_History_Summarizer SHALL NOT depend on any global state, on `DateTime.now()`, or on a package other than `dart:core`, `package:clock`, and the domain barrel.

### Requirement 10: Loading, Error, and Empty Surfaces

**User Story:** As a user, when something goes wrong or there is nothing
to show, I want a clear, calm screen that tells me what to do, so that I
am not stranded.

#### Acceptance Criteria

1. WHILE the initial Program and Day_History_Summaries load is in flight, THE Workout_Day_Picker_Screen SHALL show a single loading surface and SHALL NOT render any Day_Tile.
2. IF the Program_Repository fails to return the Program or its Workout Days during initial load, THEN THE Workout_Day_Picker_Screen SHALL show a single screen-level error surface naming the error's `invariant` or `field` descriptor verbatim and offering a retry affordance that re-invokes the load.
3. IF the per-day Session_Repository load fails for one or more Workout Days but the Program load succeeded, THEN THE Workout_Day_Picker_Screen SHALL render the Day_Tile for each failed Workout Day in a per-tile error state per Requirement 2 Acceptance Criterion 8 and SHALL render the remaining Day_Tiles normally.
4. WHEN the Program loaded successfully but contains zero Workout Days, THE Workout_Day_Picker_Screen SHALL show the empty-state surface defined by Requirement 1 Acceptance Criterion 4.
5. WHILE a "Start" or "Resume" busy indicator is displayed on any Day_Tile, THE Workout_Day_Picker_Screen SHALL ignore further activations of any "Start" or "Resume" affordance on any Day_Tile until the originating future resolves, per Requirement 4 Acceptance Criterion 2 and Requirement 5 Acceptance Criterion 2.

### Requirement 11: Offline-First Isolation

**User Story:** As a user in a basement gym, I want the picker — list,
history, start, resume — to work with no network connectivity, so that I
can train regardless of signal.

#### Acceptance Criteria

1. THE Workout_Day_Picker_Module SHALL NOT import any package that performs network I/O, including `package:http`, `package:dio`, `package:web_socket_channel`, `package:grpc`, and `package:socket_io_client`, and SHALL NOT reference any of the `dart:io` classes `HttpClient`, `HttpServer`, `Socket`, `ServerSocket`, `RawSocket`, `SecureSocket`, or `SecureServerSocket`.
2. THE Relative_Date_Formatter and the Session_History_Summarizer SHALL each be pure Dart, SHALL NOT depend on `package:flutter/*` other than `package:flutter/foundation.dart` if needed for `@immutable`, and SHALL NOT import any of the packages or `dart:io` classes listed in Acceptance Criterion 1.
3. WHEN any Workout_Day_Picker_Module screen is opened on an Offline_Device, every in-screen action defined by Requirements 1 through 6 and 10 SHALL complete without issuing any outbound network request from the Workout_Day_Picker_Module itself.

### Requirement 12: Repository Contracts Only

**User Story:** As a developer, I want the picker UI to depend only on
domain-typed repository contracts and the SessionFlowEngine, so that the
UI layer stays swappable and Drift leakage never reaches BLoCs or
widgets.

#### Acceptance Criteria

1. THE Workout_Day_Picker_Module, defined as all non-generated Dart source files under `lib/modules/workout_day_picker/` (excluding `*.freezed.dart` and `*.g.dart` siblings), SHALL depend only on `lib/core/`, on the `lib/modules/domain/` barrel `package:zamaj/modules/domain/domain.dart`, and on the module's own files for its data-access and engine needs, and SHALL NOT import any file under `lib/modules/persistence/`.
2. THE Workout_Day_Picker_Module SHALL NOT import `package:drift/drift.dart`, `package:drift/native.dart`, `package:drift_flutter/drift_flutter.dart`, `package:sqlite3/sqlite3.dart`, `package:sqlite3/common.dart`, any Drift-generated type, or any `*.g.dart` file located under `lib/modules/persistence/`, from any BLoC, screen, widget, or service.
3. THE Workout_Day_Picker_Module SHALL receive `ProgramRepository`, `SessionRepository`, `SessionFlowEngine`, and `Clock` instances through constructor parameters whose declared types resolve to the abstract contracts and value types defined under `lib/modules/domain/`, and SHALL NOT resolve these dependencies via service locators, global singletons, or setter injection.
4. THE Workout_Day_Picker_Module SHALL NOT reference, construct, or open any of the symbols `AppDatabase`, `NativeDatabase`, `driftDatabase`, or `GeneratedDatabase`, and SHALL NOT invoke any constructor or factory that returns a subtype of `GeneratedDatabase`.
5. IF the offline-imports check (`tool/check_offline_imports.sh` extended to cover `lib/modules/workout_day_picker/`) detects any import or symbol reference forbidden by Acceptance Criteria 1, 2, or 4, THEN THE check SHALL exit with a non-zero status code and SHALL emit, for each violation, a message identifying the offending file path, the line number, and the forbidden import or symbol.

### Requirement 13: Module Structure and Conventions

**User Story:** As a developer, I want the picker module to follow the
project's existing conventions, so that future feature modules can be
built the same way.

#### Acceptance Criteria

1. THE Workout_Day_Picker_Module SHALL live under `lib/modules/workout_day_picker/` and SHALL expose a single barrel file `lib/modules/workout_day_picker/workout_day_picker.dart` that re-exports every type intended for consumption outside the module.
2. THE Workout_Day_Picker_Module SHALL organize its source under `bloc/`, `screens/`, `widgets/`, `services/`, and `models/` subdirectories per the conventions in `init.md`.
3. THE Workout_Day_Picker_Module SHALL use the `flutter_bloc` pattern with sealed `Event` and `State` class families whose concrete subclasses extend `Equatable`, per the conventions in `init.md`.
4. THE Workout_Day_Picker_Module SHALL use single quotes for Dart string literals, SHALL apply the `const` keyword to every constructor invocation flagged by the `prefer_const_constructors` lint in the project's `analysis_options.yaml`, SHALL use `package:zamaj/...` imports for every cross-directory import within `lib/`, and SHALL NOT use relative `lib/` imports.
5. THE Workout_Day_Picker_Module SHALL NOT contain any `print` call in its source files; any diagnostic output SHALL go through `log` from `dart:developer` or through a BLoC observer consistent with `init.md`.
6. WHEN `flutter analyze` is run against the project with the existing `analysis_options.yaml`, the Workout_Day_Picker_Module source files SHALL produce zero errors, zero warnings, and zero lint violations.

### Requirement 14: Error Surfaces and Validation

**User Story:** As a user, when the picker can't do what I asked, I want
a clear message that names the failure, so that I can decide whether to
retry or fix the underlying problem.

#### Acceptance Criteria

1. WHEN any `ProgramRepository`, `SessionRepository`, or `SessionFlowEngine` call invoked by the Workout_Day_Picker_Module returns a typed `DomainError` (`ValidationError`, `OrderingError`, `NotFoundError`, `ImmutabilityError`, `VersionMismatchError`, `DeserializationError`), THE Workout_Day_Picker_Module SHALL surface a non-empty message that contains the error's `invariant` or `field` descriptor verbatim and, WHERE the error carries an `entityId`, contains that `entityId` verbatim.
2. IF a screen-level error surface is shown per Requirement 10 Acceptance Criterion 2, THEN activating its retry affordance SHALL re-invoke the full initial load (Program plus all Day_History_Summaries) exactly once per activation and SHALL replace the screen-level error surface with the loading surface for the duration of that re-load.
3. IF a per-tile error surface is shown per Requirement 10 Acceptance Criterion 3, THEN activating its retry affordance SHALL re-invoke `SessionRepository.listSessionsForWorkoutDay` for that Workout Day exactly once per activation and SHALL replace the per-tile error surface with a per-tile loading indicator for the duration of that re-load.
4. WHEN the Workout_Day_Picker_Module surfaces a `NotFoundError` per Requirement 5 Acceptance Criterion 4, the message SHALL state that the in-progress session could not be resumed and SHALL identify the affected Workout Day by its name.
