# `lib/modules/workout_day_picker` — Code Review

Scope: every non-generated file under `lib/modules/workout_day_picker/`
(`*.freezed.dart` files excluded). Evaluated against current Dart 3 /
Flutter / `flutter_bloc` / Freezed v3 best practices and the project's
own `analysis_options.yaml`.

This is a small, well-scoped module: one bloc, one screen, six widgets,
three pure services, three Freezed models. The architectural shape is
already good — bloc-per-screen, sealed state, presentational widgets,
pure services for date math and aggregation. The findings below are
mostly about idiom, tiny bugs, and avoiding hidden module coupling.

---

## TL;DR — Top items, in order of impact

| # | Item                                                                                                            | Severity |
|---|-----------------------------------------------------------------------------------------------------------------|----------|
| 1 | `DayTile._Skeleton` has no `const` constructor — fails `prefer_const_constructors` and rebuilds on every parent rebuild | **Bug**  |
| 2 | Bloc exposes a `StreamController<String> navigationIntents`, screen subscribes manually — re-invents `BlocListener` for one-shot side effects | High     |
| 3 | Hidden dependency on `program_management` for `DomainErrorPresenter` and `ProgramEditorArgs`/`ProgramManagementRoutes` | High     |
| 4 | `_runFullLoad` flashes a fresh `WorkoutDayPickerLoading` on every refresh/return, even when data is already cached | Medium   |
| 5 | `DayTileHistoryLabels` renders the raw assertion string `'no_last_completed_with_nonzero_week_count'` to users  | Medium   |
| 6 | N+1 tile loading: `_loadTileStatus` issues one `listSessionsForWorkoutDay(...)` per day                          | Medium   |
| 7 | `WorkoutDayPickerLoaded.copyWith` uses the `T? Function()?` "explicit-null" pattern; verbose                    | Medium   |
| 8 | Inconsistent event constructor style (positional `WorkoutDayPickerStartPressed(this.workoutDayId)` vs named)     | Low      |
| 9 | `WorkoutDayPickerStartPressed` and `WorkoutDayPickerResumePressed` events lack `props` overrides on the no-arg variants | Low |
| 10 | `RelativeDateFormatter._weekdayName` is hand-rolled; `intl` already provides this                              | Low      |
| 11 | `workout_day_picker.dart` barrel exports bloc + screen + services but leaves `widgets/` private (good) — but exports `services/relative_date_formatter.dart` which is internal | Low |
| 12 | Magic numbers (`width: 96`, `width: 120` in `DayTile`)                                                          | Low      |
| 13 | `WorkoutDayPickerBloc.close()` does not `await` `super.close()`                                                 | Low      |
| 14 | Whole tile list rebuilds when only `launchInFlightWorkoutDayId` flips                                            | Low      |

Severity legend: **Bug** · High · Medium · Low.

---

## 1. What's done well

Worth keeping; future modules should imitate these.

1.  **`SessionHistorySummarizer` and `CurrentWeekWindow` are pure
    static services** with no Flutter, no Bloc, no I/O. Both are
    obvious to unit-test and free of `DateTime.now()`. `CurrentWeekWindow`
    accepts the reference instant; `SessionHistorySummarizer` takes
    the window as input. This separation is the right shape.

2.  **`DayTileStatus` is a sealed union** (`loading` / `loaded` /
    `failure`) so each tile renders independently, and a tile-level
    failure doesn't take down the whole screen. The screen-level
    failure is a separate state (`WorkoutDayPickerScreenFailure`).
    Two-level failure handling done right.

3.  **`DayViewModel` is a Freezed wrapper around `WorkoutDay` +
    `DayTileStatus`**, decoupling presentation state from the domain
    type while keeping the domain entity intact. Tile retry can swap
    just the `status` field via `copyWith`.

4.  **`AppClock` (via `package:clock`) is injected.** `Clock` is a
    constructor parameter to `WorkoutDayPickerBloc`. Tests can pass
    `Clock.fixed(...)`. No `DateTime.now()` calls leak through the
    bloc.

5.  **`StartResumeActionButton` is presentational and reusable.** The
    `isResume`/`busy`/`enabled`/`onPressed` API is small and exhaustive;
    the screen can re-use the same widget for both verbs.

6.  **The screen splits empty/error/loading/loaded into named
    private widgets** (`_LoadedBody`, `_TransientErrorBanner`,
    `_NotFoundView`) instead of inlining ever-deepening trees. Easy
    to follow.

7.  **Exhaustive `switch` in `_titleFor` and `_body`** ensures that
    when a new state variant is added (e.g. `WorkoutDayPickerDeleted`),
    the compiler will refuse to build until the screen handles it.
    This is a real Dart-3 advantage being used well here.

8.  **`StartResumeActionButton` correctly uses `AppSpacing.touchMin`**
    so the button always meets the 48dp tap target.

---

## 2. Critical findings

### Bug 2.1 — `_Skeleton` is missing `const`

```163:175:lib/modules/workout_day_picker/widgets/day_tile.dart
class _Skeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SkeletonBar(width: 160, color: colors.surfaceVariant),
        const SizedBox(height: AppSpacing.xs),
        _SkeletonBar(width: 120, color: colors.surfaceVariant),
      ],
    );
  }
}
```

No constructor at all, which means no implicit `const` constructor —
which means **`prefer_const_constructors` will fire** at every call
site that does `_Skeleton()`. The bloc emits a `DayTileLoading` for
each loading tile, and `DayTile._statusBody` does:

```87:97:lib/modules/workout_day_picker/widgets/day_tile.dart
return switch (viewModel.status) {
  DayTileLoading() => _Skeleton(),
  ...
};
```

…which is *not* a `const` invocation. Every parent rebuild allocates
a new `_Skeleton` widget. For a list with five tiles all in
loading state, that's five allocations per rebuild, and the analyzer
flagged it.

**Fix:**

```dart
class _Skeleton extends StatelessWidget {
  const _Skeleton();

  @override
  Widget build(BuildContext context) {
    ...
  }
}
```

…and the call site becomes `const _Skeleton()`.

Same opportunity: `_SkeletonBar(width: 160, color: colors.surfaceVariant)`
can't be const because `colors.surfaceVariant` is read from `Theme.of`,
but the parent `_Skeleton()` can be const today.

---

## 3. High-priority improvements

### High 3.1 — Custom `StreamController` for navigation is re-implementing `BlocListener`

```39:48:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
final StreamController<String> _navigationIntents =
    StreamController<String>.broadcast();

Stream<String> get navigationIntents => _navigationIntents.stream;

@override
Future<void> close() async {
  await _navigationIntents.close();
  return super.close();
}
```

```28:34:lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart
@override
void initState() {
  super.initState();
  _navSubscription = context
      .read<WorkoutDayPickerBloc>()
      .navigationIntents
      .listen(_navigateToActiveSession);
}
```

The bloc has a *second* output channel: alongside emitted states, it
emits "navigate now" intents on a broadcast stream. The screen
subscribes manually in `initState`, holds the subscription in a
nullable field, and cancels it in `dispose`.

This works, but it's a re-implementation of what `BlocListener` does
for free — and it sidesteps the standard bloc lifecycle. Subscribers
that don't listen lose intents (no buffering). The bloc's lifetime is
also no longer self-contained.

There are two idiomatic alternatives, in order of preference:

1.  **Add a terminal state.** Define
    `WorkoutDayPickerNavigatingToSession(sessionId)` as a real state
    (it's already a logical state — the user is now in a session). The
    screen's `BlocListener` then handles
    `current is WorkoutDayPickerNavigatingToSession` and pushes the
    route. After
    `WorkoutDayPickerReturnedFromSession`, the bloc transitions back
    to `WorkoutDayPickerLoaded` (already happens — it re-runs the
    full load). The custom stream goes away.

2.  **Use the existing `lastTransientError` pattern, but as a
    "lastNavigationIntent".** Carry a `String? sessionIdToNavigateTo`
    field on the `Loaded` state. The screen has a `listenWhen` that
    fires only when this transitions from `null` to non-null. The bloc
    nulls it out on a `NavigationConsumed` event after the listener
    has fired.

Either way, the broadcast `StreamController` and the manual
subscription disappear, and you stop having two answers to "what is
the current state of the picker".

Note also: `StreamController.broadcast()` is the wrong choice if there's
only ever one listener. Single-subscription is what `bloc` itself uses
internally for state. But the better fix is to delete the channel
entirely.

### High 3.2 — Hidden cross-module dependency on `program_management`

```7:9:lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
```

```5:6:lib/modules/workout_day_picker/widgets/workout_day_picker_error_view.dart
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
```

```5:5:lib/modules/workout_day_picker/widgets/day_tile.dart
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
```

The `workout_day_picker` module reaches into the `program_management`
module for:

- `DomainErrorPresenter` (used in 3 places).
- `ProgramEditorArgs` and `ProgramManagementRoutes` (for the "Edit
  program" deep link from the empty state).

This is a layering bug. Two unrelated feature modules should not
depend on each other directly. `DomainErrorPresenter` is a *generic*
utility — it doesn't belong inside `program_management`. The fact that
two other modules now depend on it transitively means a future
refactor of `program_management` (rename, extract, split, delete) will
ripple through unrelated code.

**Fix:**

1.  Move `services/domain_error_presenter.dart` to
    `lib/core/domain_error_presenter.dart`. It depends only on
    `lib/modules/domain/errors.dart`, which is the right module
    boundary.
2.  Either move the program-management route constants to a shared
    `lib/navigation/` folder, or expose the "open editor for program"
    intent through a callback wired by the composition root, so
    `workout_day_picker` doesn't bake in a string route literal.

After both moves, the only modules `workout_day_picker` imports from
are `domain/` and `core/` — which is the intended dependency arrow.

### High 3.3 — `program_management/program_list_tile.dart` imports back into `workout_day_picker`

```6:7:lib/modules/program_management/widgets/program_list_tile.dart
import 'package:zamaj/modules/workout_day_picker/models/workout_day_picker_args.dart';
import 'package:zamaj/modules/workout_day_picker/navigation/workout_day_picker_routes.dart';
```

Combined with High 3.2 this means `workout_day_picker` and
`program_management` have a **circular module dependency**: each
imports from the other. The analyzer doesn't catch this because Dart
allows cyclic imports as long as there's no top-level reference
cycle, but the modules are not independently buildable.

`ProgramListTile.build` calls `Navigator.pushNamed(WorkoutDayPickerRoutes.picker, ...)`
inline. The right move is to inject the navigation intent as a
callback at the screen level:

```dart
ProgramListTile(
  program: program,
  onTap: ...,
  onDeleteRequested: ...,
  onTrain: () => Navigator.of(context).pushNamed(
    WorkoutDayPickerRoutes.picker,
    arguments: WorkoutDayPickerArgs(programId: program.id),
  ),
)
```

Now `ProgramListTile` knows nothing about `workout_day_picker`.

(Same kind of fix is appropriate for `WorkoutDayPickerEmptyView`,
which today calls `program_management` directly via the screen's
`_onEditProgram` callback — that one is already correctly hidden
behind a callback. Good. Apply the same pattern to the tile.)

---

## 4. Medium-priority improvements

### Medium 4.1 — `_runFullLoad` flashes a Loading state on every event

```257:301:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
Future<void> _runFullLoad({
  required String programId,
  required Emitter<WorkoutDayPickerState> emit,
}) async {
  emit(WorkoutDayPickerLoading(programId));
  ...
  emit(WorkoutDayPickerLoaded(...));
}
```

`_runFullLoad` is called from:

- `_onOpened` — first time the screen opens. Loading is appropriate.
- `_onScreenRetryRequested` — full retry after a screen-level failure.
  Loading is appropriate.
- `_onRefreshRequested` — pull-to-refresh / manual refresh. Loading
  flashes the spinner and *throws away the previously-loaded data*,
  which is jarring UX.
- `_onReturnedFromSession` — fires every time the user comes back from
  a session. Same problem: spinner flashes for no reason.

The expected behavior for in-place refresh is "show the existing data
with a small refreshing indicator, then atomically swap in the new
data". The current implementation does the opposite.

**Fix.** Either:

- Add an `isRefreshing` field on `WorkoutDayPickerLoaded` and skip the
  `WorkoutDayPickerLoading` emit when refreshing:

  ```dart
  Future<void> _runFullLoad({
    required String programId,
    required Emitter<WorkoutDayPickerState> emit,
    required bool isRefresh,
  }) async {
    final current = state;
    if (isRefresh && current is WorkoutDayPickerLoaded) {
      emit(current.copyWith(isRefreshing: () => true));
    } else {
      emit(WorkoutDayPickerLoading(programId));
    }
    ...
    emit(WorkoutDayPickerLoaded(...));
  }
  ```

- Or split refresh out: `_refresh` only updates `dayViewModels` and
  doesn't transition the screen-level state at all.

This also kills the brief race where `referenceNow` jumps backwards
(if the refresh's `_clock.now()` returns earlier than the previous
load's reference, e.g. due to clock skew — unlikely, but the bloc
doesn't guard).

### Medium 4.2 — `_loadTileStatus` is N+1 over sessions

```303:319:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
Future<DayTileStatus> _loadTileStatus({
  required String workoutDayId,
  required CurrentWeekWindow window,
}) async {
  try {
    final sessions = await _sessionRepository.listSessionsForWorkoutDay(
      workoutDayId,
    );
    final DayHistorySummary summary = SessionHistorySummarizer.summarize(
      sessions,
      window,
    );
    return DayTileStatus.loaded(summary);
  } on DomainError catch (e) {
    return DayTileStatus.failure(e);
  }
}
```

Called from `_runFullLoad` via `Future.wait(workoutDays.map(...))`:
one round-trip per workout day. Two issues:

1.  The `persistence_review.md` (item 3) already notes that
    `listSessionsForWorkoutDay` is itself N+1 in the Drift layer. So
    we have N (days) × N (sessions per day) round-trips.
2.  `Future.wait` issues all of them concurrently. Drift uses a single
    SQLite connection; concurrent reads serialise at the driver layer
    so the parallelism is illusory.

Add a batch API to `SessionRepository`:

```dart
Future<Map<String, List<Session>>> listSessionsForWorkoutDays(
  Iterable<String> workoutDayIds,
);
```

…and reshape the bloc to make one call:

```dart
final sessionsByDay = await _sessionRepository.listSessionsForWorkoutDays(
  workoutDays.map((d) => d.id),
);
final viewModels = [
  for (final day in workoutDays)
    DayViewModel(
      workoutDay: day,
      status: DayTileStatus.loaded(
        SessionHistorySummarizer.summarize(
          sessionsByDay[day.id] ?? const [],
          window,
        ),
      ),
    ),
];
```

This change is on the persistence side; the bloc-side change is
trivial once the API exists.

### Medium 4.3 — `DayTileHistoryLabels` renders an internal assertion to users

```32:42:lib/modules/workout_day_picker/widgets/day_tile_history_labels.dart
final invariantViolation = lastCompleted == null && weekCount > 0;

return Column(
  crossAxisAlignment: CrossAxisAlignment.start,
  children: [
    if (invariantViolation)
      Text(
        'no_last_completed_with_nonzero_week_count',
        style: typography.bodySmall.copyWith(color: colors.error),
      )
```

The string `'no_last_completed_with_nonzero_week_count'` is a snake_case
assertion identifier, not a user-facing message. If a session ever ends
up with `endedAt` going through the summarizer but somehow doesn't get
captured in `lastCompleted`, the user sees this raw string in red.

The right idiom for "this should never happen" is `assert`:

```dart
assert(
  !(lastCompleted == null && weekCount > 0),
  'DayHistorySummary invariant: cannot have weekCount > 0 with null lastCompleted',
);
```

In release builds the assertion is stripped and the impossible case
becomes the same as "no history" — a graceful degradation.

If the case *is* reachable in production (e.g. clock drift on
device), pick a user-readable message ("Could not compute last
completed date") and put the developer-facing string in
`debugPrint`.

### Medium 4.4 — `WorkoutDayPickerLoaded.copyWith` uses the `T? Function()?` boilerplate

```65:85:lib/modules/workout_day_picker/bloc/workout_day_picker_state.dart
WorkoutDayPickerLoaded copyWith({
  Program? program,
  List<DayViewModel>? dayViewModels,
  DateTime? referenceNow,
  CurrentWeekWindow? window,
  String? Function()? launchInFlightWorkoutDayId,
  DomainError? Function()? lastTransientError,
}) {
  return WorkoutDayPickerLoaded(
    program: program ?? this.program,
    dayViewModels: dayViewModels ?? this.dayViewModels,
    referenceNow: referenceNow ?? this.referenceNow,
    window: window ?? this.window,
    launchInFlightWorkoutDayId: launchInFlightWorkoutDayId != null
        ? launchInFlightWorkoutDayId()
        : this.launchInFlightWorkoutDayId,
    lastTransientError: lastTransientError != null
        ? lastTransientError()
        : this.lastTransientError,
  );
}
```

The same `T? Function()?` "explicit-null" idiom as in
`program_management`. Verbose, easy to misuse, and not enforced by the
analyzer. See `program_management_review.md` Medium 4.2 for the
options. The path of least resistance is to convert these state
classes to Freezed sealed unions — Freezed is already a dependency.

### Medium 4.5 — `_currentProgramId` is exhaustive but lossy

```321:330:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
String? _currentProgramId() {
  final current = state;
  return switch (current) {
    WorkoutDayPickerLoaded(:final program) => program.id,
    WorkoutDayPickerLoading(:final programId) => programId,
    WorkoutDayPickerProgramNotFound(:final programId) => programId,
    WorkoutDayPickerScreenFailure(:final programId) => programId,
    WorkoutDayPickerInitial() => null,
  };
}
```

The `WorkoutDayPickerInitial` returns `null` and the caller
(`_onScreenRetryRequested`) early-returns silently. That's plausible
but means a retry pressed in a glitched state quietly does nothing.

Two options:

- Make `programId` a required parameter on `WorkoutDayPickerInitial`
  too (the bloc always knows what program it was created for — see
  `app_router.dart:_pickerRoute` which dispatches `WorkoutDayPickerOpened(args.programId)` immediately after `BlocProvider.create`).
- Or convert the early-return to an assert; the bloc should never
  receive a `RetryRequested` while in `Initial`.

### Medium 4.6 — `_onResumePressed` falls through to `_loadTileStatus` on `NotFoundError`

```190:233:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
} on NotFoundError {
  final latest = state;
  if (latest is! WorkoutDayPickerLoaded) return;

  final targetIndex = latest.dayViewModels.indexWhere(
    (vm) => vm.workoutDay.id == event.workoutDayId,
  );
  if (targetIndex < 0) {
    emit(latest.copyWith(launchInFlightWorkoutDayId: () => null));
    return;
  }

  emit(
    latest.copyWith(
      launchInFlightWorkoutDayId: () => null,
      dayViewModels: _withTileStatus(
        latest.dayViewModels,
        targetIndex,
        const DayTileStatus.loading(),
      ),
    ),
  );

  final reloaded = await _loadTileStatus(
    workoutDayId: event.workoutDayId,
    window: latest.window,
  );
  ...
}
```

This handles the "user resumes a stale session that was deleted on
another device" case (good!), but the catch's intent is invisible.
Add a comment:

```dart
} on NotFoundError {
  // The session id we tried to resume has been deleted (e.g. by a
  // sync from another device, or by data eviction). Refresh just
  // this tile so the user can start a fresh session.
  ...
}
```

Also, the bloc currently catches `NotFoundError` regardless of which
entity wasn't found. If `resumeSession` ever surfaces a `NotFoundError`
for the *workout day* (vs the *session*), the bloc will reload the
tile, find no active session, and silently swallow the error. That's
arguably fine, but unexpected.

`NotFoundError` is a Freezed type with an `entityType` field — match
on it:

```dart
} on NotFoundError catch (e) {
  if (e.entityType != 'Session') rethrow;
  ...
}
```

### Medium 4.7 — `Future.wait` swallows errors

```282:286:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
final tileStatuses = await Future.wait(
  workoutDays.map(
    (day) => _loadTileStatus(workoutDayId: day.id, window: window),
  ),
);
```

`_loadTileStatus` catches `DomainError` and returns
`DayTileStatus.failure(e)`, so `Future.wait` itself won't fail. But
unexpected exceptions (a `StateError`, an unhandled `TypeError` from
a bad mapper) propagate, and `Future.wait` cancels the still-running
futures by *not awaiting them* — they keep running but their results
are discarded. The first thrown exception is what `Future.wait`
re-throws.

Two improvements:

1.  Use `eagerError: false` (the default) **with** a final `try` in
    `_loadTileStatus` that catches `Object` and returns a generic
    failure. That way the bloc shows a per-tile error rather than
    crashing the screen.

    ```dart
    Future<DayTileStatus> _loadTileStatus(...) async {
      try {
        ...
      } on DomainError catch (e) {
        return DayTileStatus.failure(e);
      } catch (e, st) {
        // Last-resort guard; the persistence layer is supposed to
        // only throw DomainError, but never trust it.
        FlutterError.reportError(FlutterErrorDetails(exception: e, stack: st));
        return DayTileStatus.failure(...some sentinel DomainError...);
      }
    }
    ```

2.  Or pivot to a batch API (Medium 4.2) and replace `Future.wait`
    entirely.

---

## 5. Low-priority / nits

### Low 5.1 — Inconsistent event constructor style

```42:48:lib/modules/workout_day_picker/bloc/workout_day_picker_event.dart
final class WorkoutDayPickerStartPressed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerStartPressed(this.workoutDayId);

  final String workoutDayId;

  @override
  List<Object?> get props => [workoutDayId];
}

final class WorkoutDayPickerResumePressed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerResumePressed({
    required this.workoutDayId,
    required this.activeSessionId,
  });
  ...
}
```

`StartPressed` uses positional, `ResumePressed` uses named. The
`program_management` events all use named. Pick one — named is the
project default. Add `{required}` where it isn't already.

### Low 5.2 — Missing `props` on no-arg events

```19:25:lib/modules/workout_day_picker/bloc/workout_day_picker_event.dart
final class WorkoutDayPickerRefreshRequested extends WorkoutDayPickerEvent {
  const WorkoutDayPickerRefreshRequested();
}

final class WorkoutDayPickerReturnedFromSession extends WorkoutDayPickerEvent {
  const WorkoutDayPickerReturnedFromSession();
}
```

These rely on the base class's default `props => const []`. That's
correct — but the *other* no-arg events in this same file
(`WorkoutDayPickerScreenRetryRequested`, `WorkoutDayPickerErrorDismissed`)
also rely on the default, which is great consistency.

But: `ProgramListEvent`/`ProgramEditorEvent` in the
`program_management` module require *every* subclass to override
`props => []`. Same codebase, two conventions. Pick one repo-wide
(see `program_management_review.md` Medium 4.10).

### Low 5.3 — `RelativeDateFormatter._weekdayName` is hand-rolled

```14:33:lib/modules/workout_day_picker/services/relative_date_formatter.dart
static String _weekdayName(int weekday) {
  switch (weekday) {
    case DateTime.monday:
      return 'Monday';
    case DateTime.tuesday:
      return 'Tuesday';
    ...
    default:
      throw ArgumentError('Unknown weekday: $weekday');
  }
}
```

`DateTime.weekday` is always in `1..7`, so the `default` clause is
unreachable. If/when i18n lands, `intl`'s `DateFormat.EEEE().format(t)`
gives the same string and handles locales. Until then, this is
acceptable but worth tagging.

Also, the `_iso` helper does what `DateFormat('yyyy-MM-dd').format(t)`
does for free. Same trade-off.

### Low 5.4 — Magic widths in `DayTile._trailing`

```100:122:lib/modules/workout_day_picker/widgets/day_tile.dart
return switch (viewModel.status) {
  DayTileLoading() => const SizedBox(width: 96, height: AppSpacing.touchMin),
  DayTileFailure() => SizedBox(
    height: AppSpacing.touchMin,
    child: TextButton.icon(...),
  ),
  DayTileLoaded(:final summary) => SizedBox(
    width: 120,
    child: _LoadedTrailing(...),
  ),
};
```

`96` and `120` are raw pixels, not `AppSpacing.*` tokens. The
codebase otherwise reads pixels exclusively from the spacing scale.
Promote these to `AppSpacing` (or a tile-specific constant) so they
move together with the design system:

```dart
abstract final class _Layout {
  static const double trailingWidth = 120;
  static const double trailingPlaceholderWidth = 96;
}
```

### Low 5.5 — `WorkoutDayPickerBloc.close()` ordering

```44:48:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
@override
Future<void> close() async {
  await _navigationIntents.close();
  return super.close();
}
```

The method is `async` and `await`s `_navigationIntents.close()`, then
returns the unawaited `Future` from `super.close()`. This *works* —
`async` automatically chains the returned future — but the explicit
`await` is missing for symmetry:

```dart
@override
Future<void> close() async {
  await _navigationIntents.close();
  await super.close();
}
```

This change also matters because `super.close()` will close the bloc's
internal state stream; if it throws, the current code returns a
broken Future. Awaiting makes the failure visible.

(Caveat: once you implement High 3.1 and remove the
`_navigationIntents` controller entirely, this whole override goes
away.)

### Low 5.6 — Whole tile list rebuilds on `launchInFlightWorkoutDayId` change

```192:217:lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart
ListView.separated(
  ...
  itemBuilder: (context, index) {
    final vm = state.dayViewModels[index];
    return DayTile(
      key: ValueKey(vm.workoutDay.id),
      viewModel: vm,
      referenceNow: state.referenceNow,
      launchInFlightWorkoutDayId: state.launchInFlightWorkoutDayId,
      ...
    );
  },
),
```

Every tile receives `launchInFlightWorkoutDayId` even though only one
tile (or zero) actually cares. When the user taps Start on day A,
`state.launchInFlightWorkoutDayId = 'A'`, the entire `BlocBuilder`
rebuilds (which is fine), and every `DayTile` rebuilds — including
days B..N for which nothing has changed.

This is fine performance-wise for ~10 tiles. If picker grows to a
program with dozens of days, two small optimisations help:

1.  Use `BlocSelector<WorkoutDayPickerBloc, WorkoutDayPickerState, String?>`
    around just the action button, so only the busy tile rebuilds.
2.  Move `launchInFlightWorkoutDayId` out of the tile's API and
    have the tile read it from the bloc directly. The trailing button
    becomes a `BlocSelector` widget that selects the slice it cares
    about.

### Low 5.7 — `workout_day_picker.dart` barrel exports internal services

```1:11:lib/modules/workout_day_picker/workout_day_picker.dart
library;

export 'bloc/bloc.dart';
export 'models/day_history_summary.dart';
export 'models/day_view_model.dart';
export 'models/workout_day_picker_args.dart';
export 'navigation/workout_day_picker_routes.dart';
export 'screens/workout_day_picker_screen.dart';
export 'services/current_week_window.dart';
export 'services/relative_date_formatter.dart';
export 'services/session_history_summarizer.dart';
```

External callers (the app router, `program_management/widgets/program_list_tile.dart`)
need:

- `workout_day_picker_routes.dart` (the route name constant)
- `workout_day_picker_args.dart` (the args type)
- `workout_day_picker_bloc.dart` (only because `app_router.dart` constructs the bloc)
- `workout_day_picker_screen.dart` (only because `app_router.dart` mounts the screen)

They do **not** need `relative_date_formatter.dart` or
`session_history_summarizer.dart`. Those are pure internal services
that should be hidden behind the barrel. Same observation for
`day_view_model.dart` and `day_history_summary.dart` — they're only
ever instantiated by the bloc.

Tightening the barrel:

```dart
library;

export 'bloc/workout_day_picker_bloc.dart' show WorkoutDayPickerBloc;
export 'bloc/workout_day_picker_event.dart';
export 'bloc/workout_day_picker_state.dart';
export 'models/workout_day_picker_args.dart';
export 'navigation/workout_day_picker_routes.dart';
export 'screens/workout_day_picker_screen.dart' show WorkoutDayPickerScreen;
```

Anyone wanting to test `SessionHistorySummarizer` imports it deep.

### Low 5.8 — `DayTileHistoryLabels._secondaryLine` accepts `lastCompleted` but only checks for null

```73:81:lib/modules/workout_day_picker/widgets/day_tile_history_labels.dart
String? _secondaryLine(DateTime? lastCompleted, int weekCount) {
  if (lastCompleted == null) {
    return null;
  }
  if (weekCount == 0) {
    return 'Not completed this week';
  }
  return '$weekCount× this week';
}
```

`lastCompleted` is only used as a "do we have history?" boolean. The
parameter would be clearer as a `bool hasHistory` derived in the
caller:

```dart
String? _secondaryLine({required bool hasHistory, required int weekCount}) {
  if (!hasHistory) return null;
  ...
}
```

…with the caller:

```dart
final hasHistory = lastCompleted != null;
final secondary = _secondaryLine(hasHistory: hasHistory, weekCount: weekCount);
```

Tiny, but improves the type signature's intent.

### Low 5.9 — `CurrentWeekWindow.contains` docstring is missing

```27:29:lib/modules/workout_day_picker/services/current_week_window.dart
bool contains(DateTime instant) {
  return !instant.isBefore(start) && instant.isBefore(end);
}
```

Is the window `[start, end)` or `(start, end]`? The implementation is
`[start, end)` (half-open, the standard programmer convention).
Worth documenting on the method:

```dart
/// Returns true if [instant] falls within the half-open window
/// `[start, end)`. `start` is inclusive, `end` is exclusive.
///
/// Comparison uses the natural `DateTime` ordering; both [instant]
/// and the window bounds are expected to be in the same timezone
/// (the factory uses local time).
bool contains(DateTime instant) {
  ...
}
```

Same for `CurrentWeekWindow.compute` — it accepts any `DateTime` but
converts UTC to local. A caller passing a UTC-typed instant will get
a Monday-of-local-week result. That's the intended behaviour but
isn't obvious.

### Low 5.10 — `_navigationIntents` is `broadcast` but has at most one listener

(Subsumed by High 3.1.) For documentary value: even if you keep the
controller pattern for now, `StreamController<String>()`
(single-subscription) is more correct for a single listener. Broadcast
streams have weaker delivery semantics (no buffering) and can drop
events if no one is listening at the moment they're emitted.

### Low 5.11 — `SessionHistorySummarizer._beats` could be `Comparable`

```40:46:lib/modules/workout_day_picker/services/session_history_summarizer.dart
static bool _beats(Session candidate, Session current) {
  final byUpdated = candidate.updatedAt.compareTo(current.updatedAt);
  if (byUpdated != 0) return byUpdated > 0;
  final byStarted = candidate.startedAt.compareTo(current.startedAt);
  if (byStarted != 0) return byStarted > 0;
  return candidate.id.compareTo(current.id) > 0;
}
```

Works. If you ever need this comparison elsewhere, lift it to a
`SessionRecencyOrdering` `Comparator<Session>` so `List<Session>.sort`
can use it too.

### Low 5.12 — `_runFullLoad` shadows local `program` with a `program?` pattern

```263:277:lib/modules/workout_day_picker/bloc/workout_day_picker_bloc.dart
final Program? program;
final List<WorkoutDay> workoutDays;
try {
  program = await _programRepository.getProgram(programId);
  if (program == null) {
    emit(WorkoutDayPickerProgramNotFound(programId));
    return;
  }
  workoutDays = await _programRepository.listWorkoutDaysForProgram(
    programId,
  );
} on DomainError catch (e) {
  emit(WorkoutDayPickerScreenFailure(programId: programId, error: e));
  return;
}
```

`final Program? program;` requires the variable to be definitely
assigned exactly once before being read. The Dart analyzer correctly
proves this via flow analysis. But the line below uses `program.id`
(non-null) outside the try, relying on the early `return`. That
works (Dart 3 flow analysis narrows after the null check), but the
ergonomics improve if you just declare `final Program program` after
the null check:

```dart
final Program program;
final List<WorkoutDay> workoutDays;
try {
  final fetched = await _programRepository.getProgram(programId);
  if (fetched == null) {
    emit(WorkoutDayPickerProgramNotFound(programId));
    return;
  }
  program = fetched;
  workoutDays = await _programRepository.listWorkoutDaysForProgram(programId);
} on DomainError catch (e) {
  emit(WorkoutDayPickerScreenFailure(programId: programId, error: e));
  return;
}
```

Minor cosmetic.

---

## 6. File-by-file notes

### `workout_day_picker.dart`

Covered in Low 5.7. Tighten or remove.

### `bloc/`

- `bloc.dart` — sensible facade re-export of bloc/event/state.
- `workout_day_picker_bloc.dart` — see High 3.1, Medium 4.1, 4.2, 4.6,
  4.7. The bloc body is otherwise well-structured: each event handler
  is short, all state is read-then-modify via `if (current is!
  WorkoutDayPickerLoaded) return`. Worth a comment explaining that the
  guard pattern means "we ignore events that arrive after a state
  reset".
- `workout_day_picker_event.dart` — see Low 5.1, Low 5.2.
- `workout_day_picker_state.dart` — see Medium 4.4.

### `models/`

- `day_history_summary.dart` — minimal Freezed value type. Good.
  No `JsonSerializable` — that's correct (it's a UI shape, not a
  persisted entity).
- `day_view_model.dart` — `DayTileStatus` is a sealed Freezed union;
  `DayViewModel` is a Freezed record. Both correct.
- `workout_day_picker_args.dart` — Freezed wrapper around a single
  `programId`. Consistent.

### `navigation/`

- One-line constants file. Could fold into `workout_day_picker.dart`
  but it's idiomatic to keep route constants separate.

### `screens/`

- `workout_day_picker_screen.dart` — see High 3.1, High 3.2.
  Otherwise clean. `_LoadedBody` is a standalone widget which is
  appropriate, and the `_TransientErrorBanner` is a small inline
  helper.
- The `actions:` list in the AppBar uses a `state is WorkoutDayPickerLoaded
  ? [...] : null` ternary that produces `List<Widget>?`. `AppBar.actions`
  accepts `List<Widget>?` so this is fine, but a small `const <Widget>[]`
  for the non-loaded case avoids the `null`-vs-empty ambiguity.

### `services/`

- `current_week_window.dart` — Freezed `@freezed abstract class … with _$ … `
  + private `_()` constructor + named `.compute(now)` factory. Same
  pattern as `domain/`. Clean. Add a docstring (Low 5.9).
- `relative_date_formatter.dart` — see Low 5.3.
- `session_history_summarizer.dart` — `abstract final class …` with
  static-only members. Same pattern as `DomainErrorPresenter`. Good.

### `widgets/`

- `day_tile.dart` — see Bug 2.1, Low 5.4, Low 5.6.
- `day_tile_history_labels.dart` — see Medium 4.3, Low 5.8.
- `start_resume_action_button.dart` — clean, small, presentational.
  The label `'RESUME'`/`'START'` is in all-caps; that's design intent,
  not a bug.
- `workout_day_picker_empty_view.dart` — fine.
- `workout_day_picker_error_view.dart` — fine, but see High 3.2 about
  the `DomainErrorPresenter` import.
- `workout_day_picker_loading_view.dart` — tiny and right.

---

## 7. Cross-cutting suggestions

1.  **Move `DomainErrorPresenter` to `lib/core/`.** Two reasons:
    `workout_day_picker` shouldn't depend on `program_management`,
    and presenters of a *domain* concept naturally belong in `core/`.

2.  **Add a `BatchSessionRepository` or extend `SessionRepository`
    with `listSessionsForWorkoutDays(...)`.** This is the single
    biggest perf win for the picker — combined with the persistence
    review's `N+1` fix, the picker can load N days in 1–2 queries.

3.  **Consider Freezed-based bloc states.** Same recommendation as the
    program-management review. The state classes here are simpler
    than program-management's, so the conversion is mechanical and
    pays off immediately in `copyWith`'s readability (Medium 4.4).

4.  **Document the autoresume behaviour.** When the picker loads a day
    with an active session, the trailing button switches to RESUME.
    Tapping it `resumeSession`s. That path is well-tested today, but
    a doc comment on `DayHistorySummary.activeSessionId` would
    make the contract explicit:

    ```dart
    /// Non-null iff this day has a single in-progress session.
    /// If multiple are open (shouldn't happen but the summarizer
    /// guards), the "most recent" wins by (updatedAt, startedAt, id).
    required String? activeSessionId,
    ```

5.  **Add bloc tests for `_runFullLoad` happy + sad paths.** Pin the
    `Clock`, use a fake `ProgramRepository`/`SessionRepository`, and
    assert that the state machine ends in `WorkoutDayPickerLoaded`
    with `referenceNow == clock.now()`. None visible in the repo so
    far.

6.  **Add a widget test for `DayTile` that exercises the three
    `DayTileStatus` branches.** Combined with golden files this would
    prevent the `_Skeleton` regression (Bug 2.1) from drifting back
    in.

---

## 8. Suggested order of fixes

1.  **Bug 2.1** — one-line `const` constructor.
2.  **High 3.2 + High 3.3** — move `DomainErrorPresenter` to `core/`,
    invert the `program_management` ↔ `workout_day_picker` callback
    direction. Both unblock further refactors.
3.  **Medium 4.1** — refresh without flashing the spinner. Direct UX
    improvement.
4.  **Medium 4.2** — batch the tile-status fetch. Direct perf
    improvement; coupled to a persistence-side change.
5.  **High 3.1** — remove `_navigationIntents` in favour of a state
    machine. Larger refactor but pays off in test coverage.
6.  **Medium 4.3, 4.6, 4.7 + Low 5.x** — idiomatic cleanup.
