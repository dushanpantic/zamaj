# Design Document

## Introduction

This design turns the **workout-day-picker** requirements into an
implementable plan. The picker is a single screen with a single BLoC,
two pure-Dart services (date formatter, history summarizer), and two
small navigation hooks: an entry from `ProgramListScreen` and a
placeholder destination (`Session_Active_Route`) that the
`workout-overview-screen` spec replaces later.

The design respects four constraints:

- **Offline-first isolation** — no networking package, no `dart:io`
  HTTP/socket classes (R11).
- **Repository contracts only** — UI depends on `ProgramRepository`
  (read), `SessionRepository` (read), `SessionFlowEngine`, and `Clock`
  via constructor injection; no Drift leakage (R12).
- **No direct mutation of sessions** — every Session write path goes
  through `SessionFlowEngine.startSession` / `resumeSession` (R4 AC5,
  R5 AC6).
- **Module conventions** — folder layout, sealed `Event`/`State`,
  single-quotes, `package:zamaj/...` imports (R13).

---

## 1. High-Level Architecture

### 1.1 Layering

```
┌──────────────────────────────────────────────────────────────────┐
│ lib/modules/workout_day_picker/               (THIS SPEC)         │
│                                                                   │
│  screens/ ──► widgets/ ──► bloc/ ──► services/ ──► models/        │
│                           │                                       │
│                           └──► domain.dart barrel                 │
│                                (Program, WorkoutDay,              │
│                                 Session, SessionState,            │
│                                 ProgramRepository,                │
│                                 SessionRepository,                │
│                                 SessionFlowEngine,                │
│                                 DomainError, Clock)               │
├──────────────────────────────────────────────────────────────────┤
│ lib/modules/program_management/   (entry point: ProgramListTile)  │
│ lib/modules/domain/               (UNCHANGED)                     │
│ lib/modules/persistence/          (UNCHANGED)                     │
│ lib/core/                          (UNCHANGED)                    │
└──────────────────────────────────────────────────────────────────┘
```

The picker has no knowledge of Drift, `dart:io`, or networking
packages. It consumes the already-instantiated `SessionFlowEngine`
from the app composition root.

### 1.2 Module Folder Structure

```
lib/modules/workout_day_picker/
├── workout_day_picker.dart                # Public barrel export
├── bloc/
│   ├── workout_day_picker_bloc.dart
│   ├── workout_day_picker_event.dart
│   ├── workout_day_picker_state.dart
│   └── bloc.dart                          # sub-barrel
├── screens/
│   └── workout_day_picker_screen.dart
├── widgets/
│   ├── day_tile.dart
│   ├── day_tile_history_labels.dart
│   ├── start_resume_action_button.dart
│   ├── workout_day_picker_loading_view.dart
│   ├── workout_day_picker_empty_view.dart
│   └── workout_day_picker_error_view.dart
├── services/
│   ├── relative_date_formatter.dart
│   ├── session_history_summarizer.dart
│   └── current_week_window.dart
├── models/
│   ├── day_history_summary.dart           # freezed
│   ├── day_view_model.dart                # freezed
│   └── workout_day_picker_args.dart       # freezed
└── navigation/
    └── workout_day_picker_routes.dart     # route-name constants
```

The Session_Active_Route route-name constant (R6 AC6) lives in a
**shared** navigation file outside this module — `lib/navigation/session_routes.dart`
— because both this module and the future `workout-overview-screen`
module bind to it.

### 1.3 Dependency Injection

`flutter_bloc`, `equatable`, and `package:clock` are already in
`pubspec.yaml` (added by prior specs). No new runtime dependency.

Composition (inside `lib/bootstrap.dart` and `lib/app.dart`):

```dart
// lib/bootstrap.dart  (already exists; extend wiring)
final sessionFlowEngine = SessionFlowEngine(sessionRepo, clock);
runApp(MainApp(
  programRepo: programRepo,
  sessionRepo: sessionRepo,
  sessionFlowEngine: sessionFlowEngine,
  clock: clock,
));
```

```dart
// lib/app.dart
return MultiRepositoryProvider(
  providers: [
    RepositoryProvider<ProgramRepository>.value(value: programRepo),
    RepositoryProvider<SessionRepository>.value(value: sessionRepo),
    RepositoryProvider<SessionFlowEngine>.value(value: sessionFlowEngine),
    RepositoryProvider<Clock>.value(value: clock),
  ],
  child: MaterialApp(
    onGenerateRoute: AppRouter.onGenerateRoute,
    initialRoute: ProgramManagementRoutes.programList,
  ),
);
```

The picker BLoC receives `ProgramRepository`, `SessionRepository`,
`SessionFlowEngine`, and `Clock` through its constructor (R12 AC3).
Widgets do not own the references.

---

## 2. Screen and Navigation

### 2.1 Navigation Approach

The existing app router (`lib/navigation/app_router.dart`, created by
`program-management`) gets two additions:

```dart
abstract final class WorkoutDayPickerRoutes {
  static const picker = '/workout-day-picker';  // args: WorkoutDayPickerArgs
}

abstract final class SessionRoutes {
  static const active = '/session-active';      // args: String sessionId
}
```

`AppRouter.onGenerateRoute` dispatches `WorkoutDayPickerRoutes.picker`
to `WorkoutDayPickerScreen` and `SessionRoutes.active` to the
placeholder `SessionActivePlaceholderScreen` (R6 AC6) until the
overview-screen spec replaces the binding.

### 2.2 Entry Point from Program List

`ProgramListTile` (already in `program-management`) gets one new
trailing affordance: a "Train" button that, when activated, calls

```dart
Navigator.of(context).pushNamed(
  WorkoutDayPickerRoutes.picker,
  arguments: WorkoutDayPickerArgs(programId: program.id),
);
```

The tap-on-tile behaviour (navigate to editor) is preserved. The
"Train" affordance is a single icon button at the trailing edge. This
is the **only** edit to the `program-management` module required by
this spec; it is additive and does not change any existing assertion
in that spec's tests.

### 2.3 Navigation Flow

```
ProgramListScreen
  ├─► ProgramEditorScreen           [tap tile]            (existing)
  ├─► PlanImportScreen              [FAB: paste]          (existing)
  └─► WorkoutDayPickerScreen        [Train action]        (NEW)
         └─► SessionActivePlaceholderScreen
                                    [Start / Resume]      (NEW route)
                                    (replaced by overview screen later)
```

`SessionActivePlaceholderScreen` is a minimal `Scaffold` that shows
the passed `sessionId` and a back button. It exists solely so the
picker has a real destination during MVP development; the
`workout-overview-screen` spec swaps in the real screen by changing
the router binding.

### 2.4 Screen Catalog

| Screen | Purpose | Key widgets | States surfaced |
|---|---|---|---|
| `WorkoutDayPickerScreen` | List Workout Days for a Program with history; launch session (R1) | `AppBar` (program name + refresh), `ListView.builder`, `DayTile`, `WorkoutDayPickerEmptyView`, `WorkoutDayPickerErrorView`, `WorkoutDayPickerLoadingView` | loading, loaded, empty, programNotFound, screenFailure, launching |
| `SessionActivePlaceholderScreen` | Temporary destination for `Session_Active_Route` (R6 AC6) | `Scaffold` with `SelectableText` of sessionId | static |

---

## 3. BLoC Design

The picker has one BLoC: `WorkoutDayPickerBloc`. All events and
states extend `Equatable` and live in sealed class families.

### 3.1 Events

```dart
sealed class WorkoutDayPickerEvent extends Equatable {
  const WorkoutDayPickerEvent();
  @override List<Object?> get props => const [];
}

final class WorkoutDayPickerOpened extends WorkoutDayPickerEvent {
  const WorkoutDayPickerOpened(this.programId);
  final String programId;
  @override List<Object?> get props => [programId];
}

final class WorkoutDayPickerRefreshRequested extends WorkoutDayPickerEvent {
  const WorkoutDayPickerRefreshRequested();
}

final class WorkoutDayPickerReturnedFromSession extends WorkoutDayPickerEvent {
  const WorkoutDayPickerReturnedFromSession();
}

final class WorkoutDayPickerScreenRetryRequested extends WorkoutDayPickerEvent {
  const WorkoutDayPickerScreenRetryRequested();
}

final class WorkoutDayPickerTileRetryRequested extends WorkoutDayPickerEvent {
  const WorkoutDayPickerTileRetryRequested(this.workoutDayId);
  final String workoutDayId;
  @override List<Object?> get props => [workoutDayId];
}

final class WorkoutDayPickerStartPressed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerStartPressed(this.workoutDayId);
  final String workoutDayId;
  @override List<Object?> get props => [workoutDayId];
}

final class WorkoutDayPickerResumePressed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerResumePressed({
    required this.workoutDayId,
    required this.activeSessionId,
  });
  final String workoutDayId;
  final String activeSessionId;
  @override List<Object?> get props => [workoutDayId, activeSessionId];
}

final class WorkoutDayPickerErrorDismissed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerErrorDismissed();
}
```

### 3.2 States

```dart
sealed class WorkoutDayPickerState extends Equatable {
  const WorkoutDayPickerState();
  @override List<Object?> get props => const [];
}

final class WorkoutDayPickerInitial extends WorkoutDayPickerState {
  const WorkoutDayPickerInitial();
}

final class WorkoutDayPickerLoading extends WorkoutDayPickerState {
  const WorkoutDayPickerLoading(this.programId);
  final String programId;
  @override List<Object?> get props => [programId];
}

final class WorkoutDayPickerProgramNotFound extends WorkoutDayPickerState {
  const WorkoutDayPickerProgramNotFound(this.programId);
  final String programId;
  @override List<Object?> get props => [programId];
}

final class WorkoutDayPickerScreenFailure extends WorkoutDayPickerState {
  const WorkoutDayPickerScreenFailure({
    required this.programId,
    required this.error,
  });
  final String programId;
  final DomainError error;
  @override List<Object?> get props => [programId, error];
}

final class WorkoutDayPickerLoaded extends WorkoutDayPickerState {
  const WorkoutDayPickerLoaded({
    required this.program,
    required this.dayViewModels,            // one per WorkoutDay, in template order
    required this.referenceNow,             // captured at load — used by formatter (R3 AC1)
    required this.window,                   // captured at load — used by summarizer (R8)
    this.launchInFlightWorkoutDayId,        // non-null disables all start/resume affordances
    this.lastTransientError,                // non-null shows the dismissible non-blocking banner
  });

  final Program program;
  final List<DayViewModel> dayViewModels;
  final DateTime referenceNow;
  final CurrentWeekWindow window;
  final String? launchInFlightWorkoutDayId;
  final DomainError? lastTransientError;

  @override List<Object?> get props => [
    program,
    dayViewModels,
    referenceNow,
    window,
    launchInFlightWorkoutDayId,
    lastTransientError,
  ];
}
```

`DayViewModel` is the per-tile fact bundle:

```dart
@freezed
abstract class DayViewModel with _$DayViewModel {
  const factory DayViewModel({
    required WorkoutDay workoutDay,
    required DayTileStatus status,                  // loading | loaded(summary) | failure(error)
  }) = _DayViewModel;
}

@Freezed(unionKey: 'type')
sealed class DayTileStatus with _$DayTileStatus {
  const factory DayTileStatus.loading() = DayTileLoading;
  const factory DayTileStatus.loaded(DayHistorySummary summary) = DayTileLoaded;
  const factory DayTileStatus.failure(DomainError error) = DayTileFailure;
}
```

### 3.3 Transitions

| Trigger | From | To |
|---|---|---|
| `WorkoutDayPickerOpened(programId)` | * | `Loading(programId)` then `Loaded` / `ProgramNotFound` / `ScreenFailure` |
| `WorkoutDayPickerScreenRetryRequested` | `ScreenFailure` | `Loading` then `Loaded` / `ProgramNotFound` / `ScreenFailure` |
| `WorkoutDayPickerTileRetryRequested(id)` | `Loaded` | `Loaded` with the offending tile set to `DayTileStatus.loading()`, then `Loaded` with that tile updated to `loaded` or `failure` |
| `WorkoutDayPickerRefreshRequested` | `Loaded` | `Loading` then `Loaded` (full reload of program + all tiles) |
| `WorkoutDayPickerReturnedFromSession` | `Loaded` | `Loading` then `Loaded` (full reload, R6 AC3) |
| `WorkoutDayPickerStartPressed(id)` | `Loaded` (no in-flight) | `Loaded(launchInFlightWorkoutDayId=id)`, then either navigate + ignore (success) or `Loaded(lastTransientError=e)` (failure) |
| `WorkoutDayPickerResumePressed(id, sid)` | `Loaded` (no in-flight) | same as `Start`, except `NotFoundError` path retries the per-tile summary load (R5 AC4) |
| `WorkoutDayPickerErrorDismissed` | `Loaded(lastTransientError=e)` | `Loaded(lastTransientError=null)` |

### 3.4 Concurrency Rules

- The BLoC uses `Bloc<E,S>` with the default sequential event handler
  (events processed in FIFO order, one at a time). This guarantees
  R10 AC5: no `Start`/`Resume` can fire while one is in flight,
  because the activation event is queued and the screen treats
  `launchInFlightWorkoutDayId != null` as "disable all affordances".
- Per-tile retries are dispatched in parallel via
  `Future.wait` on the **initial full load** (one per Workout Day),
  but each subsequent per-tile retry runs sequentially through the
  event loop.

### 3.5 Launch Side Effect

The BLoC does not navigate. After a successful `startSession` /
`resumeSession`, it emits a one-shot `WorkoutDayPickerLaunchSuccess`
**state mutation**: the BLoC adds the `Loaded` state with
`launchInFlightWorkoutDayId` cleared, **and** notifies a
`StreamController<String> _navigationIntents` carrying the
`session.id`. `WorkoutDayPickerScreen` subscribes to that stream via
a `BlocListener`-equivalent and calls `Navigator.pushNamed` with
`SessionRoutes.active`. This split keeps the BLoC test-friendly (no
`BuildContext`) while preserving "push, do not replace" (R6 AC2).

Alternative considered: emit a `WorkoutDayPickerNavigating(sessionId)`
state and let `BlocListener` react. Rejected because it adds a
state that exists only for one frame and that re-entry from the
navigator pop would have to revert.

---

## 4. Load Algorithm

### 4.1 Initial Load

```
on WorkoutDayPickerOpened(programId):
  emit Loading(programId)
  now = clock.now()
  window = CurrentWeekWindow.compute(now)
  program = await programRepo.getProgram(programId)
  if program == null:
    emit ProgramNotFound(programId)
    return
  workoutDays = await programRepo.listWorkoutDaysForProgram(programId)
  // load all session lists in parallel; each load lands in its own try/catch
  tileFutures = workoutDays.map((day) =>
    sessionRepo.listSessionsForWorkoutDay(day.id)
      .then((sessions) => DayTileStatus.loaded(
              SessionHistorySummarizer.summarize(sessions, window)))
      .catchError((e) => DayTileStatus.failure(toDomainError(e))));
  tileStatuses = await Future.wait(tileFutures);
  viewModels = workoutDays.zipWith(tileStatuses, ...);
  emit Loaded(program, viewModels, referenceNow: now, window: window, …);

on screen failure (program load throws):
  emit ScreenFailure(programId, toDomainError(e))
```

### 4.2 Per-Tile Reload

Used by `WorkoutDayPickerTileRetryRequested` and by the implicit
reload triggered by `WorkoutDayPickerResumePressed` failing with
`NotFoundError` (R5 AC4):

```
on WorkoutDayPickerTileRetryRequested(workoutDayId):
  if state is not Loaded: return
  emit Loaded with viewModels updated: target tile.status = loading
  try:
    sessions = await sessionRepo.listSessionsForWorkoutDay(workoutDayId)
    summary  = SessionHistorySummarizer.summarize(sessions, window)
    emit Loaded with target tile.status = loaded(summary)
  catch e:
    emit Loaded with target tile.status = failure(toDomainError(e))
```

### 4.3 Full Refresh

`WorkoutDayPickerRefreshRequested` and
`WorkoutDayPickerReturnedFromSession` both re-run the initial-load
algorithm with the same `programId` carried in the current state.
This is intentional: the user expects "refresh" and "I just came
back from a session" to be indistinguishable on screen.

---

## 5. Session History Summarizer (R9)

```dart
// lib/modules/workout_day_picker/services/session_history_summarizer.dart
abstract final class SessionHistorySummarizer {
  static DayHistorySummary summarize(
    List<Session> sessions,
    CurrentWeekWindow window,
  ) {
    DateTime? lastCompleted;
    int totalCompletedCount = 0;
    int thisWeekCount = 0;

    // Pick active session by (updatedAt desc, startedAt desc, id desc)
    Session? bestActive;

    for (final s in sessions) {
      final endedAt = s.endedAt;
      if (endedAt == null) {
        if (bestActive == null || _beats(s, bestActive)) {
          bestActive = s;
        }
        continue;
      }
      totalCompletedCount += 1;
      if (lastCompleted == null || endedAt.isAfter(lastCompleted)) {
        lastCompleted = endedAt;
      }
      if (!endedAt.isBefore(window.start) && endedAt.isBefore(window.end)) {
        thisWeekCount += 1;
      }
    }

    return DayHistorySummary(
      lastCompleted: lastCompleted,
      totalCompletedCount: totalCompletedCount,
      thisWeekCount: thisWeekCount,
      activeSessionId: bestActive?.id,
    );
  }

  static bool _beats(Session candidate, Session current) {
    final byUpdated = candidate.updatedAt.compareTo(current.updatedAt);
    if (byUpdated != 0) return byUpdated > 0;
    final byStarted = candidate.startedAt.compareTo(current.startedAt);
    if (byStarted != 0) return byStarted > 0;
    return candidate.id.compareTo(current.id) > 0;
  }
}
```

```dart
@freezed
abstract class DayHistorySummary with _$DayHistorySummary {
  const factory DayHistorySummary({
    required DateTime? lastCompleted,
    required int totalCompletedCount,
    required int thisWeekCount,
    required String? activeSessionId,
  }) = _DayHistorySummary;
}
```

The summarizer is **pure Dart**: no `DateTime.now()`, no
`Clock.now()` (it does not need "now" because the window is already
materialized), no `dart:io`, no `package:flutter`.

**Determinism (R9 AC5).** No randomness, no clock reads inside.
Pure function of inputs.

**Order independence (R9 AC6).** Both running stats and the
tie-break loop are commutative; the only ordering-sensitive
operation is the tie-break, which uses `_beats` to pick the
extremum.

---

## 6. Current-Week Window (R8)

```dart
// lib/modules/workout_day_picker/services/current_week_window.dart
@freezed
abstract class CurrentWeekWindow with _$CurrentWeekWindow {
  const factory CurrentWeekWindow({
    required DateTime start,   // local time, Monday 00:00:00.000
    required DateTime end,     // start + 7 calendar days, local 00:00:00.000
  }) = _CurrentWeekWindow;

  factory CurrentWeekWindow.compute(DateTime now) {
    final local = now.isUtc ? now.toLocal() : now;
    // Dart: DateTime.monday == 1, sunday == 7
    final daysSinceMonday = (local.weekday - DateTime.monday + 7) % 7;
    final startDate = DateTime(local.year, local.month, local.day)
        .subtract(Duration(days: daysSinceMonday));
    final endDate = DateTime(startDate.year, startDate.month, startDate.day + 7);
    return CurrentWeekWindow(start: startDate, end: endDate);
  }
}
```

**R8 AC5 (Monday at exactly 00:00).** `daysSinceMonday` is 0 and
`startDate` is constructed from `local.year/month/day` with no time
component — equal to "now" itself when `now` is already at local
midnight Monday.

**R8 AC3 ("+7 calendar days").** Using `DateTime(year, month, day +
7)` performs calendar arithmetic that crosses DST transitions
correctly because Dart's `DateTime` constructor normalizes
out-of-range day values to the next month while preserving local
midnight.

**DST robustness.** The window is defined in local civil time, not
in elapsed UTC seconds. A spring-forward week is 23 hours wall-clock
long; a fall-back week is 25 hours. The half-open `[start, end)`
predicate uses `DateTime` comparisons, which compare absolute
instants, so an `endedAt` in either DST gap or overlap is still
correctly classified.

---

## 7. Relative-Date Formatter (R7)

```dart
// lib/modules/workout_day_picker/services/relative_date_formatter.dart
abstract final class RelativeDateFormatter {
  static String format(DateTime target, DateTime now) {
    final t = (target.isUtc ? target.toLocal() : target);
    final n = (now.isUtc ? now.toLocal() : now);
    final targetDate = DateTime(t.year, t.month, t.day);
    final nowDate    = DateTime(n.year, n.month, n.day);
    final deltaDays  = nowDate.difference(targetDate).inDays;
    if (deltaDays == 0) return 'Today';
    if (deltaDays == 1) return 'Yesterday';
    if (deltaDays > 1 && deltaDays < 7) return _weekdayName(t.weekday);
    return _iso(t);
  }

  static String _weekdayName(int weekday) => const {
    DateTime.monday:    'Monday',
    DateTime.tuesday:   'Tuesday',
    DateTime.wednesday: 'Wednesday',
    DateTime.thursday:  'Thursday',
    DateTime.friday:    'Friday',
    DateTime.saturday:  'Saturday',
    DateTime.sunday:    'Sunday',
  }[weekday]!;

  static String _iso(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
```

Pure, locale-neutral, deterministic (R7 AC6 / AC8). Negative
`deltaDays` (target in the future) falls through to the ISO branch
per R7 AC5. The function is **safe for negative `deltaDays`** since
`> 1 && < 7` is false for `<= 0`.

---

## 8. Day Tile Widget

`DayTile` is a `StatelessWidget` that takes a `DayViewModel`, the
`referenceNow`, and three callbacks (`onStartPressed`,
`onResumePressed`, `onRetryPressed`). It renders:

```
┌───────────────────────────────────────────────────────────────┐
│  Upper A                                  ┌───────────────┐   │
│  4 exercise groups                        │     START     │   │
│  Last completed: Tuesday                  └───────────────┘   │
│  2× this week · 8 total                                       │
└───────────────────────────────────────────────────────────────┘
```

```
┌───────────────────────────────────────────────────────────────┐
│  Lower A                                  ┌───────────────┐   │
│  3 exercise groups                        │    RESUME     │   │
│  Last completed: 2025-04-17               └───────────────┘   │
│  In progress · Not completed this week                        │
└───────────────────────────────────────────────────────────────┘
```

```
┌───────────────────────────────────────────────────────────────┐
│  Push                                     ┌───────────────┐   │
│  2 exercise groups                        │     START     │   │
│  Not completed yet                        └───────────────┘   │
└───────────────────────────────────────────────────────────────┘
```

Status branches per R3:

- `DayTileStatus.loading()` → render skeleton lines in place of the
  three text labels; affordance is disabled.
- `DayTileStatus.failure(e)` → render single error line
  `Failed to load history: <invariant or field>` and a small
  "Retry" inline button (R2 AC8, R14 AC3).
- `DayTileStatus.loaded(summary)` → render history labels per R3
  AC1–AC7 and the start/resume action per R3 AC8/AC9.

The action button uses `start_resume_action_button.dart`, which:

- shows `START` when `summary.activeSessionId == null`;
- shows `RESUME` when `summary.activeSessionId != null` along with a
  small "In progress" badge above the secondary label;
- shows a centred spinner when
  `launchInFlightWorkoutDayId == widget.workoutDayId`;
- is **disabled** (not pressable) when
  `launchInFlightWorkoutDayId != null` and is **not** this tile's
  id (R10 AC5).

---

## 9. Repository and Engine Touch Points

### 9.1 Read-only APIs Used

| Source | API | Where used | Reqs |
|---|---|---|---|
| `ProgramRepository.getProgram` | resolve programId at picker open | `WorkoutDayPickerBloc._loadProgram` | R1 AC1, R1 AC3 |
| `ProgramRepository.listWorkoutDaysForProgram` | list days in template order | `WorkoutDayPickerBloc._loadProgram` | R1 AC1, R1 AC2 |
| `SessionRepository.listSessionsForWorkoutDay` | per-day session history | `WorkoutDayPickerBloc._loadTile` | R2 AC1, R2 AC8 |
| `SessionFlowEngine.startSession` | begin fresh session | `WorkoutDayPickerBloc._start` | R4 AC1, R4 AC5 |
| `SessionFlowEngine.resumeSession` | resume active session | `WorkoutDayPickerBloc._resume` | R5 AC1, R5 AC6 |

### 9.2 No Domain or Drift Changes

No domain model is extended, no Drift table is added, no migration
is needed. The picker is built **entirely** on existing contracts.
This is one of its design strengths and the reason it is a good
"warm-up" before the bigger session-side screens.

### 9.3 `Session.updatedAt` Availability

R2 AC7's tie-break on `updatedAt` requires the field to exist on
`Session`. It does — `core-domain-and-persistence` declares it on
`Session` (verified in `lib/modules/domain/models/session.dart`).
The implementation in the summarizer reads `session.updatedAt`
directly.

---

## 10. Loading, Error, and Empty Views

```
WorkoutDayPickerLoadingView   — single centred spinner with the
                                 program name in the AppBar slot
                                 (the program may not yet be loaded,
                                 in which case the AppBar reads
                                 "Loading…")

WorkoutDayPickerEmptyView     — illustration / placeholder, the
                                 sentence "This program has no
                                 workout days yet.", and a primary
                                 button "Edit program" that pushes
                                 ProgramManagementRoutes.programEditor
                                 with the same programId (R1 AC4)

WorkoutDayPickerErrorView     — screen-level failure (R1 AC5,
                                 R10 AC2); shows the typed error
                                 invariant/field text and a Retry
                                 button that dispatches
                                 WorkoutDayPickerScreenRetryRequested

WorkoutDayPickerNotFoundView  — for ProgramNotFound state
                                 (R1 AC3); just an icon, the line
                                 "Program not found", and a back
                                 affordance
```

Per-tile error states are rendered inside `DayTile` itself; they do
not preempt the screen.

The transient banner for failed `Start` / `Resume` (R4 AC4 /
R5 AC5) is a `MaterialBanner` shown at the top of the screen body,
not an `AlertDialog`. Reasons:

- it does not block other tile activations (the BLoC already
  prevents concurrent activations);
- it shows the typed error verbatim (R14 AC1);
- it dismisses on a single "OK" tap, after which the BLoC clears
  `lastTransientError`.

---

## 11. Tests

Test files live under `test/modules/workout_day_picker/`. Generators
extend the existing `test/support/generators.dart` rather than
adding a parallel file.

### 11.1 Service Unit Tests (pure Dart)

| Service | File | Cases |
|---|---|---|
| `RelativeDateFormatter` | `services/relative_date_formatter_test.dart` | Today, yesterday, each weekday within window, ISO branch, equal-instant returns "Today", target-in-future returns ISO, DST spring-forward / fall-back days |
| `CurrentWeekWindow.compute` | `services/current_week_window_test.dart` | Each weekday produces correct Monday-anchored start; Monday at 00:00:00 returns "now"; end = start + 7 days; window across DST boundary |
| `SessionHistorySummarizer` | `services/session_history_summarizer_test.dart` | Empty list → zeros + nulls; mixed active/completed; active tie-break (updatedAt > startedAt > id); thisWeek boundary inclusivity (start inclusive, end exclusive); order-independence |

### 11.2 Property-Based Tests (PBT)

| Req | Property | File | Strategy |
|---|---|---|---|
| R9 AC2/AC3 | totalCompletedCount and thisWeekCount equal direct list counts | `services/summarizer_count_property_test.dart` | Generate random `List<Session>`, compute via summarizer, assert against naive count loop |
| R9 AC4 | activeSessionId tie-break is correct | `services/summarizer_tiebreak_property_test.dart` | Generate sessions with controlled `updatedAt`/`startedAt`/`id` distributions, assert chosen id matches the lexicographic max |
| R9 AC5 | determinism | `services/summarizer_determinism_property_test.dart` | Generate inputs, invoke twice, assert equal outputs |
| R9 AC6 | order independence | `services/summarizer_permutation_property_test.dart` | Generate inputs, shuffle, invoke, assert equal outputs |
| R7 AC8 | formatter determinism | `services/relative_date_formatter_determinism_property_test.dart` | Generate `(target, now)` pairs and assert two calls produce equal strings |

### 11.3 BLoC Unit Tests (`bloc_test`)

| Scenario | File | Reqs |
|---|---|---|
| Opened with unknown programId emits `ProgramNotFound` | `bloc/workout_day_picker_bloc_test.dart` | R1 AC3 |
| Opened with known programId and 0 workout days → `Loaded` with empty `dayViewModels` and screen shows empty view via widget tests | same | R1 AC4 |
| Initial load: `getProgram` throws → `ScreenFailure` carrying the typed `DomainError` | same | R1 AC5, R10 AC2 |
| Initial load: 3 workout days where day 2's session list throws → `Loaded` with day 2 in `DayTileStatus.failure` | same | R2 AC8, R10 AC3 |
| `StartPressed` while another launch is in flight → second event ignored (no `startSession` call) | same | R4 AC2, R10 AC5 |
| `StartPressed` succeeds → navigation intent emitted with returned session id | same | R4 AC1, R4 AC3 |
| `StartPressed` failure → `lastTransientError` set | same | R4 AC4 |
| `ResumePressed` with `NotFoundError` → triggers per-tile reload | same | R5 AC4 |
| `RefreshRequested` and `ReturnedFromSession` re-run full load | same | R6 AC3, R6 AC4 |

### 11.4 Widget Tests

For each screen state (loading, loaded happy path, loaded with in-progress, screen failure, program-not-found, empty, per-tile failure):

- assert the expected widget tree is rendered;
- assert dispatched events on the relevant interactions
  (`tap Train`, `tap Start`, `tap Resume`, `tap Retry`, `tap
  Refresh`).

`MockSessionFlowEngine`, `MockProgramRepository`, and
`MockSessionRepository` live under `test/support/` and implement the
domain interfaces (no Drift involvement).

### 11.5 Navigation Integration Test

One integration test exercises the full path: `ProgramListScreen →
Train → WorkoutDayPickerScreen → Start → SessionActivePlaceholderScreen
→ back → WorkoutDayPickerScreen refresh`. Uses an in-memory
`FakeProgramRepository` and `FakeSessionRepository` from
`test/support/`.

---

## 12. Offline-First and Import Allowlist

### 12.1 Forbidden Imports

Same as `program-management`'s allowlist:

- `package:http`, `package:dio`, `package:web_socket_channel`,
  `package:grpc`, `package:socket_io_client`.
- `dart:io` HTTP/socket classes.
- `package:drift/*`, `package:drift_flutter/*`,
  `package:sqlite3/*`.
- Any `*.g.dart` file under `lib/modules/persistence/`.
- Symbols `AppDatabase`, `NativeDatabase`, `driftDatabase`,
  `GeneratedDatabase`.

### 12.2 `tool/check_offline_imports.sh` Extension

The script gets one additional scan directory:
`lib/modules/workout_day_picker/`. The forbidden set is shared with
the existing scans; no new patterns are required.

### 12.3 No New Runtime Dependencies

`flutter_bloc`, `equatable`, `package:clock`, and `freezed`/`json_serializable`
codegen are already in the project. The picker introduces zero new
packages.

---

## 13. Open Questions and Design Decisions

1. **No "Active Program" abstraction.** The picker is parameterized
   by `programId`. A future "Today" tab can be layered on top by
   resolving a single `activeProgramId` and pushing this screen
   with it. Adding active-program state now would be premature; the
   product brief explicitly de-emphasizes calendar / scheduling
   concepts.

2. **Train affordance vs tap-on-tile.** We chose a trailing icon on
   `ProgramListTile` because the existing tap action (navigate to
   editor) is itself useful: the user often opens the picker but
   sometimes opens the editor first to verify the plan. Replacing
   the tap with the picker would force a context-menu for editing,
   which is one tap more. Keeping both as siblings is the lowest-
   friction shape.

3. **Monday-anchored week.** The product brief gives no week
   anchor, but coaches' "weekly volume" planning is universally
   Monday-to-Sunday in this market. We hard-code Monday for the
   summarizer; if a future requirement demands user-configurable
   week start, the change is local to `CurrentWeekWindow.compute`.

4. **"Resume" button instead of automatic resume.** When an active
   session exists, we **prompt** rather than auto-route. This
   prevents accidental jumps when the user opens the picker out of
   habit (e.g. forgetting they left a session open last night).

5. **`NotFoundError` on resume reloads the tile.** Rather than
   showing a hard error, the BLoC re-runs the tile summary
   (R5 AC4). Rationale: the only way `resumeSession` 404s is if the
   session was deleted between summary load and resume tap; the
   tile reload reflects the new truth and the user can pick again.

6. **Placeholder `Session_Active_Route`.** The picker would block
   on a missing destination if it had to wait for
   `workout-overview-screen`. The placeholder route is a 30-line
   `Scaffold` that displays the passed session id, lives in
   `lib/navigation/`, and is replaced by the overview-screen spec
   without touching the picker.

7. **Pure-Dart `relative_date_formatter`.** We considered
   `package:intl`'s `DateFormat.E()` for weekday names but rejected
   it: it pulls in locale resolution side effects, breaks offline
   determinism on first-launch on some Androids, and would force a
   locale assertion in tests. Hard-coding English weekday names is
   fine because the app is single-locale by design.

8. **`Session.updatedAt`-based tie-break.** When multiple active
   sessions exist for one day (theoretically impossible, but
   defensively handled), we pick the most recently mutated one.
   This matches the intuition that the user's last interaction is
   the one they want to resume.

---

## 14. Requirement Coverage Matrix

| Requirement | Design elements |
|---|---|
| R1 Picker layout | §2 screen catalog, §3.2 `WorkoutDayPickerLoaded` state |
| R2 Per-day history load | §3.3 transitions, §4.1 initial load, §5 summarizer |
| R3 Day tile display rules | §3.2 `DayViewModel`, §8 DayTile widget |
| R4 Start fresh | §3.1 `StartPressed`, §3.5 launch side effect, §9.1 engine call |
| R5 Resume | §3.1 `ResumePressed`, §3.5 launch side effect, §4.2 per-tile reload on 404 |
| R6 Navigation + refresh | §2.1 routes, §2.2 entry from list, §2.3 flow, §4.3 refresh |
| R7 Relative date formatter | §7 formatter |
| R8 Current-week window | §6 window service |
| R9 Summarizer correctness | §5 summarizer, §11.2 PBT |
| R10 Surfaces | §10 loading/error/empty views, §3.4 concurrency rules |
| R11 Offline isolation | §12 allowlist, services are pure Dart |
| R12 Repository contracts only | §1.3 DI, §9 read APIs, §12 allowlist |
| R13 Module conventions | §1.2 folder structure, sealed events/states (§3) |
| R14 Error surfaces | §10 banner/views, §3.5 `lastTransientError`, §9 verbatim `DomainError` text |
