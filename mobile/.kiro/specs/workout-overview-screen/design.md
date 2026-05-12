# Design Document

## Introduction

This design turns the **workout-overview-screen** requirements into an
implementable plan. The overview is a single screen with a single
BLoC, three pure-Dart helpers (planned-summary formatter, exercise
viewmodel assembler, drop-resolver), a small set of reusable widgets
(Exercise_Tile, Superset_Frame, Set_Row, the four mutation sheets),
and one localised navigation change (re-bind `SessionRoutes.active`,
add `SessionRoutes.focus`).

The design respects four constraints from the steering and the
requirements:

- **Offline-first isolation** — no networking package, no `dart:io`
  HTTP/socket classes (R19).
- **Engine-only mutations** — UI depends on `SessionFlowEngine` and
  `Clock` via constructor injection; no Drift leakage; never calls
  `SessionRepository` mutation methods directly (R20).
- **Engine semantics drive enablement** — affordance enablement
  states (skip/replace/log set/reorder/superset) follow the engine's
  state-machine rules so the UI never asks the engine for an
  operation that will throw.
- **Module conventions** — folder layout, sealed `Event`/`State`,
  single-quotes, `package:zamaj/...` imports, theme tokens (R21).

---

## 1. High-Level Architecture

### 1.1 Layering

```
┌──────────────────────────────────────────────────────────────────┐
│ lib/modules/workout_overview/                 (THIS SPEC)        │
│                                                                  │
│  screens/ ──► widgets/ ──► bloc/ ──► services/ ──► models/       │
│                          │                                       │
│                          └──► domain.dart barrel                 │
│                               (Session, SessionExercise,         │
│                                ExecutedSet, ExerciseState,       │
│                                SubstituteExercise,               │
│                                MeasurementType,                  │
│                                ActualSetValues,                  │
│                                PlannedSetValues,                 │
│                                Cursor, SessionState,             │
│                                SessionFlowEngine, DomainError,   │
│                                Clock)                            │
├──────────────────────────────────────────────────────────────────┤
│ lib/modules/workout_day_picker/  (entry: pushes SessionRoutes.   │
│                                   active with Workout_Overview_  │
│                                   Args)                          │
│ lib/navigation/                  (re-binds active; adds focus    │
│                                   placeholder)                   │
│ lib/modules/domain/              (UNCHANGED)                     │
│ lib/modules/persistence/         (UNCHANGED)                     │
│ lib/core/                        (UNCHANGED)                     │
└──────────────────────────────────────────────────────────────────┘
```

The overview has no knowledge of Drift, `dart:io`, or networking
packages. It consumes the already-instantiated `SessionFlowEngine`
from the app composition root (added by the picker spec).

### 1.2 Module Folder Structure

```
lib/modules/workout_overview/
├── workout_overview.dart                    # Public barrel export
├── bloc/
│   ├── workout_overview_bloc.dart
│   ├── workout_overview_event.dart
│   ├── workout_overview_state.dart
│   └── bloc.dart                            # sub-barrel
├── screens/
│   └── workout_overview_screen.dart
├── widgets/
│   ├── exercise_tile.dart
│   ├── superset_frame.dart
│   ├── set_row.dart
│   ├── planned_summary_label.dart
│   ├── per_exercise_actions.dart
│   ├── notes_section.dart
│   ├── extra_work_section.dart
│   ├── focus_call_to_action.dart
│   ├── log_set_sheet.dart
│   ├── edit_set_sheet.dart
│   ├── replacement_dialog.dart
│   ├── add_note_sheet.dart
│   ├── add_extra_work_sheet.dart
│   ├── end_session_dialog.dart
│   ├── workout_overview_loading_view.dart
│   ├── workout_overview_error_view.dart
│   └── workout_overview_not_found_view.dart
├── services/
│   ├── planned_summary_formatter.dart       # pure Dart
│   ├── exercise_view_model_assembler.dart   # pure Dart
│   └── drop_resolver.dart                   # pure Dart
└── models/
    ├── workout_overview_args.dart           # freezed
    ├── exercise_view_model.dart             # freezed
    ├── set_row_view_model.dart              # freezed
    ├── superset_group_view_model.dart       # freezed
    └── drop_intent.dart                     # freezed sealed
```

The Focus_Mode_Route route-name constant is added to the existing
shared file `lib/navigation/session_routes.dart` (created by the
picker spec). The placeholder screen for that route lives next to it
at `lib/navigation/focus_mode_placeholder_screen.dart`.

### 1.3 Dependency Injection

`flutter_bloc`, `equatable`, `package:clock`, and
`url_launcher` are required runtime dependencies. The first three
already ship from prior specs; **`url_launcher` is the one new
package** introduced by this spec, used only inside the screen layer
to hand video URLs to the host OS (R3 AC4, R19 AC2).

Composition (extension to existing `lib/app.dart` providers — already
wired by the picker):

```dart
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

The overview BLoC receives `SessionFlowEngine` and `Clock` through
its constructor (R20 AC3). Widgets do not own these references.

---

## 2. Routes and Navigation

### 2.1 Route Constants

Edit the existing `lib/navigation/session_routes.dart`:

```dart
abstract final class SessionRoutes {
  static const active = '/session-active';
  static const focus  = '/session-focus';   // NEW (R16 AC3)
}
```

### 2.2 Re-Binding `SessionRoutes.active`

The picker currently pushes `SessionRoutes.active` with a `String
sessionId` argument that lands in `SessionActivePlaceholderScreen`.
This spec:

1. Replaces the binding inside `lib/navigation/app_router.dart` so
   that `SessionRoutes.active` constructs `WorkoutOverviewScreen`
   from `Workout_Overview_Args`.
2. **Deletes** `lib/navigation/session_active_placeholder_screen.dart`
   (R17 AC2). Nothing else in the codebase imports it.
3. Updates the picker's BLoC navigation-intent push site to wrap the
   `sessionId` in `Workout_Overview_Args(sessionId: ...)` instead of
   passing a raw `String`. This is the only edit to the picker
   module.

The new `_sessionActiveRoute` factory mirrors the picker's
`_pickerRoute`:

```dart
static Route<dynamic> _sessionActiveRoute(RouteSettings settings) {
  final args = settings.arguments;
  if (args is! WorkoutOverviewArgs) {
    throw ArgumentError(
      'SessionRoutes.active expects WorkoutOverviewArgs '
      'but received ${args.runtimeType}',
    );
  }
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (context) => BlocProvider(
      create: (_) => WorkoutOverviewBloc(
        sessionFlowEngine: context.read<SessionFlowEngine>(),
        clock: context.read<Clock>(),
      )..add(WorkoutOverviewOpened(args.sessionId)),
      child: const WorkoutOverviewScreen(),
    ),
  );
}
```

### 2.3 Adding `SessionRoutes.focus` Placeholder

Create `lib/navigation/focus_mode_placeholder_screen.dart` modeled
after the existing `SessionActivePlaceholderScreen` shape: a tiny
`Scaffold` that displays the passed `sessionId` and a back affordance
(R16 AC4). Register it in `AppRouter.onGenerateRoute`:

```dart
static Route<dynamic> _sessionFocusRoute(RouteSettings settings) {
  final sessionId = settings.arguments! as String;
  return MaterialPageRoute<void>(
    settings: settings,
    builder: (_) => FocusModePlaceholderScreen(sessionId: sessionId),
  );
}
```

The focus-mode-screen spec replaces this binding without touching
the overview module.

### 2.4 Navigation Flow

```
ProgramListScreen
  └─► WorkoutDayPickerScreen        [Train action]                   (existing)
        └─► WorkoutOverviewScreen   [Start / Resume]                 (NEW binding)
              └─► FocusModePlaceholderScreen
                                    [Focus CTA]                      (NEW route)
                                    (replaced by focus-mode-screen later)
```

Returning from the focus route pops the navigator; the overview
listens via `pushNamed(...).whenComplete(refresh)` and dispatches
`WorkoutOverviewReturnedFromFocus` (R16 AC5).

---

## 3. BLoC Design

The overview has one BLoC: `WorkoutOverviewBloc`. All events and
states extend `Equatable` and live in sealed class families.

### 3.1 Events

```dart
sealed class WorkoutOverviewEvent extends Equatable {
  const WorkoutOverviewEvent();
  @override List<Object?> get props => const [];
}

final class WorkoutOverviewOpened extends WorkoutOverviewEvent {
  const WorkoutOverviewOpened(this.sessionId);
  final String sessionId;
  @override List<Object?> get props => [sessionId];
}

final class WorkoutOverviewRefreshRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewRefreshRequested();
}

final class WorkoutOverviewReturnedFromFocus extends WorkoutOverviewEvent {
  const WorkoutOverviewReturnedFromFocus();
}

final class WorkoutOverviewScreenRetryRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewScreenRetryRequested();
}

final class WorkoutOverviewExerciseExpansionToggled extends WorkoutOverviewEvent {
  const WorkoutOverviewExerciseExpansionToggled(this.sessionExerciseId);
  final String sessionExerciseId;
  @override List<Object?> get props => [sessionExerciseId];
}

final class WorkoutOverviewLogSetSubmitted extends WorkoutOverviewEvent {
  const WorkoutOverviewLogSetSubmitted({
    required this.sessionExerciseId,
    required this.actualValues,
  });
  final String sessionExerciseId;
  final ActualSetValues actualValues;
  @override List<Object?> get props => [sessionExerciseId, actualValues];
}

final class WorkoutOverviewExecutedSetEditSubmitted extends WorkoutOverviewEvent {
  const WorkoutOverviewExecutedSetEditSubmitted({
    required this.executedSetId,
    required this.actualValues,
  });
  final String executedSetId;
  final ActualSetValues actualValues;
  @override List<Object?> get props => [executedSetId, actualValues];
}

final class WorkoutOverviewSkipConfirmed extends WorkoutOverviewEvent {
  const WorkoutOverviewSkipConfirmed(this.sessionExerciseId);
  final String sessionExerciseId;
  @override List<Object?> get props => [sessionExerciseId];
}

final class WorkoutOverviewReplaceSubmitted extends WorkoutOverviewEvent {
  const WorkoutOverviewReplaceSubmitted({
    required this.sessionExerciseId,
    required this.substituteName,
    required this.substituteMeasurementType,
  });
  final String sessionExerciseId;
  final String substituteName;
  final MeasurementType substituteMeasurementType;
  @override List<Object?> get props => [
    sessionExerciseId, substituteName, substituteMeasurementType,
  ];
}

final class WorkoutOverviewDropResolved extends WorkoutOverviewEvent {
  const WorkoutOverviewDropResolved(this.intent);
  final DropIntent intent;
  @override List<Object?> get props => [intent];
}

final class WorkoutOverviewSupersetUngroupRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewSupersetUngroupRequested(this.sessionExerciseIds);
  final List<String> sessionExerciseIds;
  @override List<Object?> get props => [sessionExerciseIds];
}

final class WorkoutOverviewAddNoteSubmitted extends WorkoutOverviewEvent {
  const WorkoutOverviewAddNoteSubmitted(this.body);
  final String body;
  @override List<Object?> get props => [body];
}

final class WorkoutOverviewAddExtraWorkSubmitted extends WorkoutOverviewEvent {
  const WorkoutOverviewAddExtraWorkSubmitted(this.body);
  final String body;
  @override List<Object?> get props => [body];
}

final class WorkoutOverviewEndSessionConfirmed extends WorkoutOverviewEvent {
  const WorkoutOverviewEndSessionConfirmed();
}

final class WorkoutOverviewOpenVideoRequested extends WorkoutOverviewEvent {
  const WorkoutOverviewOpenVideoRequested(this.url);
  final String url;
  @override List<Object?> get props => [url];
}

final class WorkoutOverviewErrorDismissed extends WorkoutOverviewEvent {
  const WorkoutOverviewErrorDismissed();
}
```

### 3.2 States

```dart
sealed class WorkoutOverviewState extends Equatable {
  const WorkoutOverviewState();
  @override List<Object?> get props => const [];
}

final class WorkoutOverviewInitial extends WorkoutOverviewState {
  const WorkoutOverviewInitial();
}

final class WorkoutOverviewLoading extends WorkoutOverviewState {
  const WorkoutOverviewLoading(this.sessionId);
  final String sessionId;
  @override List<Object?> get props => [sessionId];
}

final class WorkoutOverviewSessionNotFound extends WorkoutOverviewState {
  const WorkoutOverviewSessionNotFound(this.sessionId);
  final String sessionId;
  @override List<Object?> get props => [sessionId];
}

final class WorkoutOverviewScreenFailure extends WorkoutOverviewState {
  const WorkoutOverviewScreenFailure({
    required this.sessionId,
    required this.error,
  });
  final String sessionId;
  final DomainError error;
  @override List<Object?> get props => [sessionId, error];
}

final class WorkoutOverviewLoaded extends WorkoutOverviewState {
  const WorkoutOverviewLoaded({
    required this.sessionState,
    required this.exerciseGroups,                // assembled view models
    required this.expandedSessionExerciseIds,    // ephemeral UI state
    this.mutationInFlight,                       // non-null disables mutations
    this.lastTransientError,                     // non-null shows banner
  });

  final SessionState sessionState;
  final List<SupersetGroupViewModel> exerciseGroups;
  final Set<String> expandedSessionExerciseIds;
  final MutationKind? mutationInFlight;
  final DomainError? lastTransientError;

  @override List<Object?> get props => [
    sessionState,
    exerciseGroups,
    expandedSessionExerciseIds,
    mutationInFlight,
    lastTransientError,
  ];
}

enum MutationKind {
  reorder,
  createSuperset,
  removeSuperset,
  skip,
  replace,
  logSet,
  editSet,
  addNote,
  addExtraWork,
  endSession,
}
```

`SupersetGroupViewModel` is the per-frame bundle. It contains either
one `ExerciseViewModel` (standalone tile) or N `ExerciseViewModel`s
sharing a non-null `supersetTag`:

```dart
@freezed
abstract class SupersetGroupViewModel with _$SupersetGroupViewModel {
  const factory SupersetGroupViewModel({
    required String? supersetTag,         // null for standalone
    required List<ExerciseViewModel> exercises,
  }) = _SupersetGroupViewModel;
}

@freezed
abstract class ExerciseViewModel with _$ExerciseViewModel {
  const factory ExerciseViewModel({
    required SessionExercise sessionExercise,
    required Exercise plannedExerciseInSnapshot,
    required String plannedSummary,
    required List<SetRowViewModel> setRows,
    required bool isCursorTarget,
    required int? cursorSetIndex,        // non-null when isCursorTarget
    required MeasurementType effectiveMeasurementType,
  }) = _ExerciseViewModel;
}

@freezed
abstract class SetRowViewModel with _$SetRowViewModel {
  const factory SetRowViewModel({
    required int position,
    required PlannedSetValues? plannedValues,    // null for "extra" actual sets
    required ExecutedSet? executedSet,           // null for not-yet-logged sets
    required bool isNextLogTarget,               // true for the row matching cursor.setIndex
  }) = _SetRowViewModel;
}
```

### 3.3 Transitions

| Trigger | From | To |
|---|---|---|
| `Opened(sessionId)` | * | `Loading(sessionId)` then `Loaded` / `SessionNotFound` / `ScreenFailure` |
| `RefreshRequested` | `Loaded` | `Loading` then `Loaded` |
| `ReturnedFromFocus` | `Loaded` | `Loading` then `Loaded` (full reload, R16 AC5) |
| `ScreenRetryRequested` | `ScreenFailure` | `Loading` then `Loaded` / `SessionNotFound` / `ScreenFailure` |
| `ExerciseExpansionToggled(id)` | `Loaded` | `Loaded` with toggled `expandedSessionExerciseIds` |
| `LogSetSubmitted(...)` | `Loaded` (no in-flight) | `Loaded(mutationInFlight=logSet)`, then `Loaded` with refreshed `sessionState` (success) or `Loaded(lastTransientError=e)` (failure) |
| `ExecutedSetEditSubmitted(...)` | as above | as above with `mutationInFlight=editSet` |
| `SkipConfirmed(id)` | as above | as above with `mutationInFlight=skip` |
| `ReplaceSubmitted(...)` | as above | as above with `mutationInFlight=replace` |
| `DropResolved(intent)` | as above | as above with `mutationInFlight=reorder` or `createSuperset` per `intent` |
| `SupersetUngroupRequested(...)` | as above | as above with `mutationInFlight=removeSuperset` |
| `AddNoteSubmitted(body)` | as above | as above with `mutationInFlight=addNote` |
| `AddExtraWorkSubmitted(body)` | as above | as above with `mutationInFlight=addExtraWork` |
| `EndSessionConfirmed` | as above | as above with `mutationInFlight=endSession` |
| `ErrorDismissed` | `Loaded(lastTransientError=e)` | `Loaded(lastTransientError=null)` |

### 3.4 Concurrency Rules

- The BLoC uses `Bloc<E,S>` with the default sequential event handler.
  R18 AC4 is satisfied because the screen treats
  `mutationInFlight != null` as "disable all mutation affordances",
  and any submitted event between `mutationInFlight` set and the
  response is queued FIFO.
- Expansion toggles, `OpenVideoRequested`, and `ErrorDismissed` are
  **not** treated as mutations — they do not set `mutationInFlight`
  and they bypass the disable gate.

### 3.5 Refresh-on-Mutation Strategy

The engine's contract is: every mutation method returns a fresh
`SessionState`. The BLoC's mutation handlers therefore never need to
re-call `resumeSession` after a successful mutation — they just
replace `state.sessionState` with the engine's return value and
re-assemble `exerciseGroups` via the assembler service.

The two paths that DO call `resumeSession` are:
1. `Opened` and `ScreenRetryRequested` (initial / retry load).
2. `RefreshRequested` and `ReturnedFromFocus` (explicit reload).

### 3.6 Video Launch Side Effect

`WorkoutOverviewOpenVideoRequested(url)` is treated like the picker's
navigation intent: the BLoC pushes the URL string onto a private
`StreamController<String> _videoLaunchIntents` and the screen layer
subscribes via `BlocListener`-equivalent and calls
`url_launcher.launchUrl(Uri.parse(url), mode:
LaunchMode.externalApplication)`. Keeping the URL launch out of the
BLoC keeps the BLoC pure-Dart-friendly even though we do NOT write
BLoC tests for this module per the testing scope.

Alternative considered: emitting a transient `Loaded` state with a
one-shot `pendingVideoUrl`. Rejected because it adds a state shape
that exists only for one frame and that re-entry from the navigator
or rebuild would have to revert.

---

## 4. Load Algorithm

### 4.1 Initial Load

```
on WorkoutOverviewOpened(sessionId):
  emit Loading(sessionId)
  try:
    sessionState = await engine.resumeSession(sessionId: sessionId)
    groups = ExerciseViewModelAssembler.assemble(sessionState)
    emit Loaded(sessionState, exerciseGroups: groups,
                expandedSessionExerciseIds: const {})
  on NotFoundError:
    emit SessionNotFound(sessionId)
  on DomainError e:
    emit ScreenFailure(sessionId, e)
```

### 4.2 Refresh / Return-From-Focus

`RefreshRequested` and `ReturnedFromFocus` re-run the initial-load
algorithm with the `sessionId` carried in the current `Loaded` state
(or in `Loading` if a refresh was already in flight). The expanded
set is **preserved** across reloads — UX research from existing
training apps shows users frequently come back from focus mode and
want their previously expanded panel still expanded.

### 4.3 Mutation Algorithm (shared shape)

```
on <MutationEvent>:
  if state is not Loaded: return
  if state.mutationInFlight != null: return    // R18 AC 4
  emit Loaded(... mutationInFlight: kindForEvent)
  try:
    sessionState = await engine.<method>(...)
    groups = ExerciseViewModelAssembler.assemble(sessionState)
    emit Loaded(sessionState, exerciseGroups: groups,
                expandedSessionExerciseIds: state.expandedSessionExerciseIds,
                mutationInFlight: null,
                lastTransientError: null)
  on DomainError e:
    emit Loaded(... mutationInFlight: null, lastTransientError: e)
```

Every mutation handler is the same shape; only the engine method and
its arguments change. This is implemented via a private helper
`Future<void> _runMutation(emit, MutationKind kind, Future<SessionState> Function() op)`.

---

## 5. Exercise View Model Assembler (R1, R2, R3, R13)

The assembler turns a `SessionState` into a render-ready
`List<SupersetGroupViewModel>` so the widget layer never performs
snapshot lookups itself.

```dart
abstract final class ExerciseViewModelAssembler {
  static List<SupersetGroupViewModel> assemble(SessionState sessionState);
}
```

### 5.1 Algorithm

```
assemble(sessionState):
  session = sessionState.session
  cursor  = sessionState.cursor
  sortedExercises = session.sessionExercises sorted ascending by position

  groups: List<SupersetGroupViewModel> = []
  currentTag: String? = sentinel
  currentBuffer: List<ExerciseViewModel> = []

  for each ex in sortedExercises:
    plannedExercise = lookup ex.plannedExerciseIdInSnapshot in
                      session.snapshot.workoutDay.exerciseGroups[*].exercises
    plannedSummary = PlannedSummaryFormatter.summarize(plannedExercise)
    setRows = buildSetRows(ex, plannedExercise, cursor)
    isCursorTarget = cursor is ActiveCursor &&
                     cursor.sessionExerciseId == ex.id
    cursorSetIndex = isCursorTarget ? cursor.setIndex : null
    effectiveMt = ex.state is ReplacedState
                    ? state.substitute.measurementType
                    : plannedExercise.measurementType
    vm = ExerciseViewModel(...)

    if ex.supersetTag != null && ex.supersetTag == currentTag:
      currentBuffer.add(vm)
    else:
      flushBuffer(groups, currentTag, currentBuffer)
      currentTag = ex.supersetTag
      currentBuffer = [vm]

  flushBuffer(groups, currentTag, currentBuffer)
  return groups

flushBuffer(groups, tag, buffer):
  if buffer.isEmpty: return
  if tag == null:
    for vm in buffer: groups.add(SupersetGroupViewModel(tag: null, exercises: [vm]))
  else:
    groups.add(SupersetGroupViewModel(tag: tag, exercises: List.from(buffer)))
```

### 5.2 Set Row Construction

```
buildSetRows(sessionExercise, plannedExercise, cursor):
  plannedSets = plannedExercise.sets sorted ascending by position
  executedSets = sessionExercise.executedSets sorted ascending by position
  rows: List<SetRowViewModel> = []

  for i in 0 ..< plannedSets.length:
    plannedValues = plannedSets[i].plannedValues
    executedSet = i < executedSets.length ? executedSets[i] : null
    isNextLogTarget = (cursor is ActiveCursor &&
                      cursor.sessionExerciseId == sessionExercise.id &&
                      cursor.setIndex == i)
    rows.add(SetRowViewModel(
      position: i,
      plannedValues: plannedValues,
      executedSet: executedSet,
      isNextLogTarget: isNextLogTarget,
    ))

  // Extra executed sets beyond the planned count (defensive — should not
  // happen under the engine's invariants but keeps rendering safe)
  for j in plannedSets.length ..< executedSets.length:
    rows.add(SetRowViewModel(
      position: j,
      plannedValues: null,
      executedSet: executedSets[j],
      isNextLogTarget: false,
    ))

  return rows
```

### 5.3 Purity Properties

- No clock reads, no randomness, no I/O.
- Pure function of `SessionState`.
- Determinism: two calls with the same input return equal output.

---

## 6. Planned Summary Formatter (R13)

```dart
abstract final class PlannedSummaryFormatter {
  static String summarize(Exercise plannedExercise) {
    final sets = List.of(plannedExercise.sets)
      ..sort((a, b) => a.position.compareTo(b.position));
    if (sets.isEmpty) return '0 sets';
    final first = sets.first.plannedValues;
    final allSame = sets.every((s) => s.plannedValues == first);

    if (!allSame) return '${sets.length} sets';

    return switch (first) {
      PlannedRepBased(:final weightKg, :final reps) =>
        '${_fmtKg(weightKg)}kg ${sets.length}×$reps',
      PlannedTimeBased(:final durationSeconds) =>
        '${sets.length}×${durationSeconds}s',
    };
  }

  static String _fmtKg(double kg) =>
      kg == kg.truncate() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
}
```

Pure Dart. No locale dependency. The `_fmtKg` helper drops trailing
`.0` for integer kilogram values (e.g. `100kg` rather than `100.0kg`)
while keeping one decimal for fractional values (`97.5kg`).

---

## 7. Drop Resolver (R4, R5)

The drop resolver is the pure-Dart adjudicator that turns a raw
gesture outcome into a typed `DropIntent` that the BLoC can act on.
It has no Flutter dependency — it operates on view-model data only.

```dart
@Freezed(unionKey: 'type')
sealed class DropIntent with _$DropIntent {
  const factory DropIntent.reorder({
    required String sessionId,
    required List<String> orderedUnfinishedIds,
  }) = ReorderIntent;

  const factory DropIntent.createSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) = CreateSupersetIntent;

  const factory DropIntent.noop() = NoopIntent;
}

abstract final class DropResolver {
  static DropIntent resolve({
    required String sessionId,
    required List<SupersetGroupViewModel> groups,
    required String draggedSessionExerciseId,
    required DropTarget target,
  });
}

@Freezed(unionKey: 'type')
sealed class DropTarget with _$DropTarget {
  const factory DropTarget.beforeIndex(int unfinishedIndex) = DropTargetGap;
  const factory DropTarget.ontoExercise(String sessionExerciseId) = DropTargetExercise;
  const factory DropTarget.outside() = DropTargetOutside;
}
```

### 7.1 Resolution Rules

1. If `target` is `DropTargetOutside`, return `DropIntent.noop()`.
2. Compute the current ordered list of unfinished `sessionExerciseId`s
   from `groups`.
3. If `draggedSessionExerciseId` is not in that list (the dragged
   tile was not unfinished), return `DropIntent.noop()`. (Defensive
   — Requirement 4 AC 7 already prevents this gesture path.)
4. If `target` is `DropTargetGap(index)`:
   - Build `orderedUnfinishedIds` by removing `dragged` and inserting
     it at `index`. Clamp `index` to `[0, list.length]`.
   - If the resulting list equals the original, return
     `DropIntent.noop()`.
   - Otherwise return `DropIntent.reorder(sessionId,
     orderedUnfinishedIds)`.
5. If `target` is `DropTargetExercise(targetId)`:
   - If `targetId == draggedSessionExerciseId`, return
     `DropIntent.noop()`.
   - If both `dragged` and `target` are inside the same superset
     (`supersetTag`), return `DropIntent.noop()` (R5 AC 2).
   - If `dragged` is inside a superset and `target` is outside that
     superset, return `DropIntent.noop()` and surface the
     "ungroup-first" hint at the screen layer (R5 AC 3 — the BLoC
     receives `Noop`; the screen handles the hint via its drop
     callback knowing it was a cross-superset drop).
   - Otherwise return `DropIntent.createSuperset(sessionId,
     sessionExerciseIds: [draggedId, targetId])`.

### 7.2 Purity Properties

- No clock reads, no randomness, no I/O.
- Deterministic and order-independent on the `groups` argument's
  internal ordering only insofar as the assembler already guarantees
  that ordering. The resolver itself is a pure function.

---

## 8. Drag-and-Drop Interaction Model

### 8.1 Building Blocks

The drag layer is built directly on Flutter's
`LongPressDraggable<String>` (the dragged payload is the
`sessionExerciseId`) and `DragTarget<String>`. The screen does NOT
use `ReorderableListView` because:

- `ReorderableListView` reorders **all** items; we need to lock
  non-unfinished tiles in place.
- We need a single drag gesture to express **two** intents (reorder
  vs superset) based on the drop type. `DragTarget` lets us model
  each visual zone (gap or tile) independently.

### 8.2 Visual Zones

```
┌─────────────────────────────┐  ← DragTarget (beforeIndex 0) = gap drop site
│  Bench Press [unfinished]   │  ← LongPressDraggable + DragTarget (ontoExercise)
└─────────────────────────────┘
┌─────────────────────────────┐  ← DragTarget (beforeIndex 1) = gap drop site
│  Incline DB [unfinished]    │  ← LongPressDraggable + DragTarget
└─────────────────────────────┘
┌─────────────────────────────┐  ← DragTarget (beforeIndex 2)
│  Cable Fly  [completed]     │  ← NOT draggable, NOT a target
└─────────────────────────────┘
                                 ← (no further gaps under locked tiles)
```

Gap zones appear ONLY between unfinished tiles. Locked (non-unfinished)
tiles do not produce gap zones below them, matching the engine's
"reorder preserves locked positions" semantic.

### 8.3 Gesture Lifecycle

1. Long-press starts on tile X. The `LongPressDraggable` lifts X
   visually (elevation + scale), engages haptic feedback, and dispatches
   a synthetic `DragStart` to the screen.
2. As the user drags, each `DragTarget` reports `onWillAcceptWithDetails`
   to drive its highlight state (gap shows an insertion line; tile
   shows a "make superset" outline).
3. On release, the active `DragTarget` (if any) calls back the screen
   with the dragged id; the screen invokes
   `DropResolver.resolve(...)` and dispatches
   `WorkoutOverviewDropResolved(intent)`.
4. If no `DragTarget` was active (drop outside), the screen emits a
   `WorkoutOverviewDropResolved(DropIntent.noop())`.

### 8.4 Cross-Superset Drag Hint (R5 AC 3)

When the resolver returns `Noop` because the drop crossed a superset
boundary, the screen layer recognises the situation by re-running a
small predicate at the drop site (`dragged.tag != null && target.tag
!= dragged.tag`) and shows an informational `MaterialBanner`
explaining the user must ungroup first. This stays out of the BLoC to
keep mutation banners and informational hints visually distinct.

---

## 9. Widget Composition

### 9.1 Screen Tree

```
WorkoutOverviewScreen
├── AppBar
│   ├── Title: WorkoutDay name + startedAt date subtitle
│   └── Actions: Refresh icon, Overflow (End session)
├── Body (CustomScrollView)
│   ├── SliverPersistentHeader: "Session complete" or "Session ended" pill
│   ├── SliverList of SupersetFrame / ExerciseTile
│   │     where each SupersetFrame internally lays out N ExerciseTiles
│   ├── SliverToBoxAdapter: NotesSection
│   └── SliverToBoxAdapter: ExtraWorkSection
└── BottomBar: FocusCallToAction (persistent, full width)
```

A `MaterialBanner` overlays the top of the body when
`lastTransientError != null` (R18 AC3).

### 9.2 Key Widgets

| Widget | Inputs | Renders | Reqs |
|---|---|---|---|
| `ExerciseTile` | `ExerciseViewModel`, `bool expanded`, `MutationKind?`, callbacks | Tile per Requirement 2; expanded panel per Requirement 3; per-exercise actions per Requirement 9 | R2, R3, R9 |
| `SupersetFrame` | `SupersetGroupViewModel`, `Set<String> expandedIds`, `MutationKind?`, callbacks | Bracketed wrapper around N ExerciseTiles; "Ungroup superset" affordance | R1 AC2, R6 |
| `SetRow` | `SetRowViewModel`, `MeasurementType effective`, `bool canEdit`, callbacks | Planned + actual side by side per Requirement 13; per-row edit affordance per Requirement 11; "Log set" highlight when `isNextLogTarget` | R11, R13 |
| `PerExerciseActions` | `ExerciseViewModel`, `MutationKind?`, callbacks | Buttons row per Requirement 9 | R9 |
| `LogSetSheet` | `MeasurementType`, `ActualSetValues suggested`, callback | Increment-aware form per Requirement 10 | R10 |
| `EditSetSheet` | `MeasurementType`, `ActualSetValues current`, callback | Same shape as LogSetSheet, pre-filled from existing set | R11 |
| `ReplacementDialog` | `MeasurementType original`, callback | Name input + measurement-type dropdown | R7 |
| `AddNoteSheet` | callback | Multi-line text input with 5000-char max validator | R12 AC7 |
| `AddExtraWorkSheet` | callback | Single-line text input | R12 AC4 |
| `EndSessionDialog` | callback | Confirm modal | R15 AC2 |
| `NotesSection` | `List<SessionNote>`, "Add note" callback | List + affordance | R12 AC1, AC3 |
| `ExtraWorkSection` | `List<ExtraWork>`, "Add extra work" callback | List + affordance | R12 AC2, AC4 |
| `FocusCallToAction` | `bool enabled`, callback | Full-width persistent CTA | R16 AC1, AC2 |
| `WorkoutOverviewLoadingView` | — | Single centred spinner | R18 AC1 |
| `WorkoutOverviewErrorView` | `DomainError`, retry callback | Error card with retry | R18 AC2 |
| `WorkoutOverviewNotFoundView` | `String sessionId`, back callback | Not-found card | R1 AC4 |

### 9.3 Increment Buttons (R10 AC3, AC4)

The Log/Edit sheets render increment buttons whose step depends on
the current value — this matches the focus-mode-screen design doc
("If current weight ≤ 10 → ±1, > 10 → ±2.5"). The same rule applies
inside the overview's manual log path so users get a consistent
interaction with focus mode when it lands.

```
weightKg ≤ 10  → buttons: -1   +1
weightKg  > 10 → buttons: -2.5 +2.5
reps           → buttons: -1   +1
durationSeconds → buttons: -10 +10  and  -1   +1
```

Manual numeric input is always available.

---

## 10. Loading, Error, and Empty Views

```
WorkoutOverviewLoadingView    — single centred spinner; AppBar reads
                                "Loading…" until the session loads.

WorkoutOverviewErrorView      — screen-level failure (R1 AC5,
                                R18 AC2); shows the typed error
                                invariant/field text and a Retry
                                button that dispatches
                                WorkoutOverviewScreenRetryRequested.

WorkoutOverviewNotFoundView   — for SessionNotFound state (R1 AC4);
                                an icon, "Session not found", the
                                sessionId verbatim, and a back
                                affordance.
```

There is no separate "empty" state for the overview itself — a
Session always has at least one `SessionExercise` because the
snapshot was taken from a Workout Day whose creation already enforced
the non-empty exercise list.

The transient banner for failed in-session mutations is a
`MaterialBanner` shown at the top of the screen body, not an
`AlertDialog`, for the same reasons documented in the picker spec
(non-blocking, verbatim error text, single-tap dismiss).

---

## 11. Engine Touch Points

### 11.1 Methods Called

| Source | API | Where used | Reqs |
|---|---|---|---|
| `SessionFlowEngine.resumeSession` | initial load + refresh + return-from-focus | `_loadSession` | R1, R16 AC5, R18 AC2 |
| `SessionFlowEngine.completeSet` | log a new set | `_runMutation(logSet)` | R10 |
| `SessionFlowEngine.updateExecutedSet` | edit an existing set | `_runMutation(editSet)` | R11 |
| `SessionFlowEngine.skipExercise` | skip an unfinished exercise | `_runMutation(skip)` | R8 |
| `SessionFlowEngine.replaceExercise` | replace with substitute | `_runMutation(replace)` | R7 |
| `SessionFlowEngine.reorderUnfinished` | reorder | `_runMutation(reorder)` | R4 |
| `SessionFlowEngine.createSuperset` | superset | `_runMutation(createSuperset)` | R5 |
| `SessionFlowEngine.removeSuperset` | ungroup | `_runMutation(removeSuperset)` | R6 |
| `SessionFlowEngine.addSessionNote` | add note | `_runMutation(addNote)` | R12 AC3 |
| `SessionFlowEngine.addExtraWork` | add extra work | `_runMutation(addExtraWork)` | R12 AC4 |
| `SessionFlowEngine.endSession` | end session | `_runMutation(endSession)` | R15 |
| `SessionFlowEngine.suggestValues` | pre-fill log sheets for non-cursor exercises (R14 AC2) | `_buildSuggestedValues` | R14 |

### 11.2 No Domain or Drift Changes

No domain model is extended, no Drift table is added, no migration is
needed. The overview is built **entirely** on existing engine /
domain contracts. This is one of its design strengths and the reason
it can land before focus mode: it exercises every existing engine
operation in a real UI without forcing schema work.

---

## 12. Offline-First and Import Allowlist

### 12.1 Forbidden Imports

Same allowlist as the picker:

- `package:http`, `package:dio`, `package:web_socket_channel`,
  `package:grpc`, `package:socket_io_client`.
- `dart:io` HTTP/socket classes.
- `package:drift/*`, `package:drift_flutter/*`,
  `package:sqlite3/*`.
- Any `*.g.dart` file under `lib/modules/persistence/`.
- Symbols `AppDatabase`, `NativeDatabase`, `driftDatabase`,
  `GeneratedDatabase`.

`url_launcher` is NOT a forbidden package. It uses platform channels,
not network I/O. R19 AC2 documents this explicitly.

### 12.2 `tool/check_offline_imports.sh` Extension

The script gets one additional scan directory:
`lib/modules/workout_overview/`. The forbidden set is shared with the
existing scans; no new patterns are required.

### 12.3 New Runtime Dependency

`url_launcher: ^6.x` is added to `pubspec.yaml`. The version pin
should match the most recent stable major at the time the spec lands.
Add it to the `dependencies` block; no platform-specific manifest
changes are needed for the MVP because the URLs are launched in the
external app (`LaunchMode.externalApplication`), which uses the OS
default handler.

---

## 13. Tests

Per the testing convention established by `program-management/tasks.md`
and `workout-day-picker/tasks.md`:

- **In scope:** Pure-Dart service unit tests for the three new
  services (`PlannedSummaryFormatter`, `ExerciseViewModelAssembler`,
  `DropResolver`). Property-based tests for the assembler's invariants
  and for the drop-resolver's idempotency/no-op behaviour.
- **Out of scope:** BLoC tests, widget tests, screen tests,
  integration tests. If a regression surfaces later, add the test
  then.

Test files live under `test/modules/workout_overview/`. Generators
extend the existing `test/support/generators.dart` rather than adding
a parallel file.

### 13.1 Service Unit Tests (pure Dart)

| Service | File | Cases |
|---|---|---|
| `PlannedSummaryFormatter` | `services/planned_summary_formatter_test.dart` | All-equal rep-based sets, mixed rep-based sets, all-equal time-based sets, mixed time-based sets, integer vs fractional kg formatting, single set, empty sets |
| `ExerciseViewModelAssembler` | `services/exercise_view_model_assembler_test.dart` | One standalone unfinished exercise → cursor target on set 0; multiple standalone exercises → cursor on first unfinished; one superset of two → grouped together; mixed standalone + superset preserved in position order; replaced exercise → effectiveMeasurementType = substitute's; completed exercise → no cursor target; cursor.completed → no isCursorTarget anywhere; extra executed sets beyond planned count produce trailing rows with null `plannedValues` |
| `DropResolver` | `services/drop_resolver_test.dart` | Drop outside → noop; drop on self → noop; drop on locked → noop; drop into same gap → noop; drop into different gap → reorder with correctly-permuted ids; drop on unfinished outside any superset → createSuperset; drop within same superset → noop; drop across supersets → noop |

### 13.2 Property-Based Tests (PBT)

| Property | File | Strategy |
|---|---|---|
| Assembler determinism | `services/assembler_determinism_property_test.dart` | Generate random `SessionState`, invoke twice, assert equal output |
| Assembler preserves position order | `services/assembler_order_property_test.dart` | Generate random `SessionState`, assert flattened `exerciseGroups[*].exercises[*].sessionExercise` matches `session.sessionExercises` sorted by position |
| Assembler exercise count | `services/assembler_count_property_test.dart` | Generate random `SessionState`, assert flattened exercise count equals `session.sessionExercises.length` |
| Drop resolver self-drop is noop | `services/drop_resolver_self_property_test.dart` | Generate any `groups` and any `draggedId`, assert resolve(target=onto(draggedId)) returns `Noop` |
| Drop resolver gap-to-same-position is noop | `services/drop_resolver_same_position_property_test.dart` | Generate any `groups` and any unfinished `draggedId`, find its current index `i`, assert resolve(target=beforeIndex(i)) returns `Noop` AND resolve(target=beforeIndex(i+1)) returns `Noop` |

Each PBT runs ≥100 iterations using a seeded `Random` and the
generators in `test/support/generators.dart` (extend with
`anySessionStateForOverview` if not already present).

### 13.3 Generator Extensions

Add to `test/support/generators.dart`:

- `anyExerciseViewModel(Random rng)` — produces a random
  `ExerciseViewModel` consistent with the engine's invariants.
- `anySupersetGroupViewModel(Random rng)` — produces a random
  group with 1 or 2–4 exercises sharing a tag.
- `anyOverviewGroups(Random rng)` — produces an ordered list of
  `SupersetGroupViewModel` with mixed standalone and superset entries
  in plausible positions.

These layer on top of the existing `anySession` / `anyCursorableSession`
generators added by the engine spec.

---

## 14. Open Questions and Design Decisions

1. **Persistent expanded set across reloads.** The
   `expandedSessionExerciseIds` field is preserved across
   `RefreshRequested` and `ReturnedFromFocus` reloads. Justification:
   users frequently come back from focus mode to inspect the panel
   they just acted on; clearing the set would force them to
   re-expand. The set is cleared by an explicit
   `WorkoutOverviewExerciseExpansionToggled` event only.

2. **Drag-and-drop without `ReorderableListView`.** We chose
   `LongPressDraggable` + `DragTarget` because we need (a) two
   distinct drop semantics from one gesture and (b) lock-in-place
   tiles. Trade-off: more bespoke code than the built-in
   `ReorderableListView`, but the built-in widget cannot satisfy R4
   AC 7 (locked exercise immobility) and R5 AC 1 (drop-onto-tile to
   superset) simultaneously. The drop-resolver service makes the
   logic testable in pure Dart.

3. **Replacement is a dialog, not a sheet.** A modal dialog with
   "name" + "measurement type" is two fields — small enough that a
   sheet would feel oversized. The sheet pattern is reserved for
   set-value entry (Log/Edit) which has incrementers and a primary
   numeric focus.

4. **Skip is confirmed, not undoable.** The engine's
   `skipExercise` transitions state to `skipped` permanently; the
   only escape is to `replaceExercise` afterward (which the engine
   rejects because the state is no longer unfinished). A confirmation
   modal is the cheapest way to prevent accidental taps.

5. **End session is confirmed, not auto-triggered.** When the cursor
   becomes `Cursor.completed`, the screen shows a "Session complete"
   indicator (R1 AC 7) but **does not** auto-call `endSession`. The
   user may still want to log extra work or add notes after every
   exercise is done. End is always an explicit action.

6. **Editing executed sets remains enabled after end.** Per engine
   Requirement 6.2, executed sets can be edited regardless of
   exercise state and after session end. The overview honours this
   so historical corrections remain possible (R15 AC 5).

7. **Focus CTA is persistent at the bottom.** A bottom bar keeps the
   primary action one-thumb-reachable in keeping with the product's
   one-handed-usage UX goal. Disabled-state shows "All sets done"
   instead of vanishing so the layout is stable.

8. **Video link launches externally.** No in-app video player. The
   `url_launcher` call uses `LaunchMode.externalApplication` to hand
   the URL to the OS, matching the design-doc rule "open externally
   in YouTube; never embedded inline."

9. **Re-binding `SessionRoutes.active` deletes the placeholder.**
   `SessionActivePlaceholderScreen` was always temporary; this spec
   replaces it. Leaving it in the codebase as dead code is contrary
   to project conventions (`code-style.md`: "Don't leave dead code").

10. **The picker-side argument-type change.** Changing the argument
    pushed to `SessionRoutes.active` from `String` to
    `Workout_Overview_Args` is an additive type-safety improvement.
    The picker's BLoC tests are out of scope (per the picker's
    testing convention) and the change is local to the BLoC's launch
    side effect — see `WorkoutDayPickerBloc._onStartPressed` and
    `_onResumePressed`.

11. **No `SessionRepository` injection into the overview.** The
    overview only ever needs the engine. R20 AC 4 says the module
    "MAY hold a `SessionRepository` reference solely for read-only
    queries it cannot obtain through the engine." The MVP scope of
    this spec needs none of those, so the constructor takes only
    `SessionFlowEngine` and `Clock`.

12. **`Clock` injection, even though we read time only for display.**
    Display labels for `startedAt` and `endedAt` are derived from
    the loaded `Session` itself; `Clock` is only used if a future
    requirement adds "elapsed since start" display. We inject it
    eagerly so that requirement does not later force a constructor
    change.

---

## 15. Requirement Coverage Matrix

| Requirement | Design elements |
|---|---|
| R1 Session load + layout | §2.2 route binding, §3.2 `Loaded` state, §4.1 load algorithm, §5 assembler, §9.1 screen tree |
| R2 Tile display rules | §5 assembler, §9.2 ExerciseTile widget |
| R3 Inline expansion | §3.1 `ExerciseExpansionToggled`, §3.2 `expandedSessionExerciseIds`, §9.2 ExerciseTile expanded panel |
| R4 Long-press reorder | §7 drop resolver (reorder branch), §8 drag-and-drop model |
| R5 Drag-onto-target superset | §7 drop resolver (superset branch), §8 drag-and-drop model |
| R6 Superset removal | §3.1 `SupersetUngroupRequested`, §9.2 SupersetFrame |
| R7 Replacement | §3.1 `ReplaceSubmitted`, §9.2 ReplacementDialog |
| R8 Skip | §3.1 `SkipConfirmed`, §9.2 EndSessionDialog (sibling pattern) |
| R9 Per-exercise actions | §9.2 PerExerciseActions, enablement rules in §3 |
| R10 Manual set logging | §3.1 `LogSetSubmitted`, §9.2 LogSetSheet, §9.3 increment rules |
| R11 Edit executed set | §3.1 `ExecutedSetEditSubmitted`, §9.2 EditSetSheet + SetRow per-row affordance |
| R12 Notes + extra work | §3.1 `AddNoteSubmitted`/`AddExtraWorkSubmitted`, §9.2 NotesSection/ExtraWorkSection sheets |
| R13 Planned vs actual | §6 PlannedSummaryFormatter, §9.2 SetRow rendering |
| R14 Suggested values | §3.5 mutation refresh, §11.1 `suggestValues` use |
| R15 End session | §3.1 `EndSessionConfirmed`, §9.2 EndSessionDialog, §9.1 AppBar overflow |
| R16 Focus entry + return refresh | §2.1 routes, §2.3 placeholder, §3.6 video stream pattern, §9.1 FocusCallToAction |
| R17 Active route re-binding | §2.2 binding swap |
| R18 Loading/error/transient surfaces | §3.4 concurrency, §10 surface views |
| R19 Offline isolation | §12 allowlist + url_launcher justification |
| R20 Engine-only mutations | §1.3 DI, §11.1 engine touch points only, §12 allowlist |
| R21 Module conventions | §1.2 folder structure, sealed events/states (§3), token usage in §9 |
| R22 Verbatim error content | §10 banner content, §3.4 transient banner shape |
