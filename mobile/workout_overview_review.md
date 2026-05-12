# `lib/modules/workout_overview` — Code Review

Scope: every non-generated file under `lib/modules/workout_overview/`
(`*.freezed.dart` excluded). Evaluated against current Dart 3 / Flutter
/ Freezed v3 best practices and the project's own
`analysis_options.yaml`.

**State of the module.** This module is **partially implemented**. The
`models/` and `services/` folders are present and well-shaped, but
`bloc/`, `screens/`, and `widgets/` are all *empty directories*:

```
lib/modules/workout_overview/
├── bloc/                  ← empty
├── screens/               ← empty
├── widgets/               ← empty
├── models/                ← Freezed view-models + sealed unions
├── services/              ← pure functions
└── workout_overview.dart  ← contains only `library;`
```

Nothing in the rest of the codebase imports `workout_overview` either:

```
$ rg -l workout_overview lib
lib/modules/workout_overview/...   # only itself
```

So this review covers the *foundation* that's been built — view-model
shapes, the assembler, the drop resolver, the planned-summary
formatter — and flags both the issues in that foundation and the
holes that will become bugs as soon as the screen and bloc are wired
up.

The TL;DR is short because there's much less code here than in the
other two modules.

---

## TL;DR — Top items, in order of impact

| # | Item                                                                                                          | Severity |
|---|---------------------------------------------------------------------------------------------------------------|----------|
| 1 | Module is half-built: no bloc, no screen, no widgets, no navigation. The barrel exports nothing.              | High     |
| 2 | `ExerciseViewModelAssembler._lookupPlannedExercise` throws `StateError` — a domain consistency violation, not a programming error | High |
| 3 | `DropResolver._resolveOnto` has two consecutive `if` branches that both `return noop()` — looks like an unfinished merge | **Bug** |
| 4 | `_buildSetRows` zips planned vs executed sets *by index*, not by position. Sparse / non-zero-based positions silently misalign | Medium |
| 5 | `MutationKind` enum is dead code (no references anywhere in `lib`)                                            | Medium   |
| 6 | `assemble` rebuilds the planned-exercise lookup via two-deep nested scan for *every* session exercise — O(N × M) | Medium |
| 7 | `SupersetGroupViewModel.supersetTag: String?` re-encodes "single vs superset" as nullability instead of a sealed kind | Medium |
| 8 | `workout_overview.dart` barrel is empty (`library;` only)                                                     | Low      |
| 9 | `PlannedSummaryFormatter._fmtKg` doesn't handle `kg = 0` consistently with the program-management formatter   | Low      |
| 10 | `DropResolver._listEquals` is yet another inlined copy of `listEquals`                                       | Low      |
| 11 | `ExerciseViewModel` carries both `sessionExercise` (which references the planned id) and `plannedExerciseInSnapshot` directly — duplicated invariant | Low |

Severity legend: **Bug** · High · Medium · Low.

---

## 1. What's done well

Even with most of the module missing, the foundation is shaped well.

1.  **All sealed types are Freezed sealed unions with explicit
    `unionKey: 'type'`.** `DropTarget`, `DropIntent`, and (next door
    in `models/exercise_view_model.dart`) the implicit
    `SetRowViewModel` shape are consistent with the domain layer's
    idioms.

2.  **`DropIntent` is the right output of `DropResolver`.** Instead of
    each caller producing its own bloc events, `DropResolver` emits a
    single sealed `DropIntent` (`reorder` / `createSuperset` /
    `noop`). A future bloc can pattern-match on it once.

3.  **`ExerciseViewModelAssembler` is purely a function** of a
    `SessionState`. No Bloc, no DB, no `DateTime.now()`. The fact that
    it can be unit-tested today, before the bloc exists, is exactly
    what you want from a presentation-layer mapper.

4.  **`SupersetGroupViewModel` groups exercises by adjacent
    `supersetTag` equality**, which mirrors the domain's "superset =
    consecutive exercises with the same tag" invariant. No separate
    `GroupKind` field needed.

5.  **`SetRowViewModel.isNextLogTarget`** lifts the "this is the row
    the user logs to next" decision into the view-model so the widget
    doesn't recompute it from `Cursor` shape at render time.

6.  **`abstract final class` static-only services.** `DropResolver`,
    `ExerciseViewModelAssembler`, `PlannedSummaryFormatter` all use
    the project's idiomatic shape (same as `RelativeDateFormatter`,
    `SessionHistorySummarizer`, `DomainErrorPresenter`).

---

## 2. Critical findings

### High 2.1 — Module is half-built

```1:lib/modules/workout_overview/workout_overview.dart
library;
```

```
lib/modules/workout_overview/bloc/
lib/modules/workout_overview/screens/
lib/modules/workout_overview/widgets/
```

Three empty folders, an empty barrel, no app router entry, no tests
visible. The module currently provides only the input/output types
for a feature whose UI doesn't exist. That's fine as a
scaffolding step, but it has consequences:

- **Dead-import risk.** `MutationKind` is unreferenced. `DropIntent`
  is unreferenced. `ExerciseViewModelAssembler` is unreferenced. If
  you add a bloc tomorrow against these types, the assumption is
  that they're already exercised — they aren't.
- **Cargo-cult risk.** A future developer copying the bloc shape
  from `workout_day_picker` will inherit High 3.1 from that review
  (`StreamController` navigation intents). Decide the bloc shape
  *first*, then write the bloc.
- **Documentation gap.** There's no `module-doc.md` (or library-level
  comment) explaining what state the bloc will own, what
  `DropResolver` should do that it doesn't, etc.

Either:

- **Finish the module** in a single PR, so all the types have at
  least one production consumer. Right now `ExerciseViewModelAssembler`
  could be deleted and nothing would notice.
- **Or move the types behind a barrel** that re-exports them from
  `program_management` or `domain` where they'd live until the
  module materialises. Half-built modules attract bit-rot.

Concrete proposal: at minimum add a `lib/modules/workout_overview/
README.md` or doc comment on `workout_overview.dart` that lists:

- The intended sealed event hierarchy (`WorkoutOverviewOpened`,
  `WorkoutOverviewSetLogged`, `WorkoutOverviewSetReordered`,
  `WorkoutOverviewSupersetCreated`, …).
- The intended sealed state hierarchy (`WorkoutOverviewInitial`,
  `WorkoutOverviewLoading`, `WorkoutOverviewLoaded`,
  `WorkoutOverviewSessionEnded`, …).
- Which `SessionFlowEngine` methods each event will call.

Otherwise, every model file is an unverified hypothesis.

### High 2.2 — `_lookupPlannedExercise` throws `StateError` on missing snapshot reference

```117:132:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
static Exercise _lookupPlannedExercise(
  SessionExercise sessionExercise,
  Session session,
) {
  for (final group in session.snapshot.workoutDay.exerciseGroups) {
    for (final exercise in group.exercises) {
      if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
        return exercise;
      }
    }
  }
  throw StateError(
    'Planned exercise ${sessionExercise.plannedExerciseIdInSnapshot} '
    'not found in session ${session.id} snapshot',
  );
}
```

The domain layer's invariant is that *every*
`SessionExercise.plannedExerciseIdInSnapshot` resolves inside the
captured snapshot. The `SessionFlowEngine` already enforces this.
**But:**

- A `StateError` is the wrong type for "the database is internally
  inconsistent". The codebase uses `DomainError.deserializationError`
  / `DomainError.notFound` for exactly this case. Throwing a raw
  `StateError` from a presentation-layer service means callers can't
  pattern-match on the failure.

- The assembler is called from what will be the bloc's `_onOpened`,
  which already catches `DomainError`. A `StateError` will escape
  that handler and crash the screen.

**Fix.** Wrap with a domain-shaped failure:

```dart
static Exercise _lookupPlannedExercise(
  SessionExercise sessionExercise,
  Session session,
) {
  for (final group in session.snapshot.workoutDay.exerciseGroups) {
    for (final exercise in group.exercises) {
      if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
        return exercise;
      }
    }
  }
  throw DomainError.notFound(
    entityType: 'Exercise',
    id: sessionExercise.plannedExerciseIdInSnapshot,
  );
}
```

…and then assemble's signature stays `List<SupersetGroupViewModel>
assemble(SessionState sessionState)` — domain errors propagate
naturally and the bloc's existing `on DomainError catch (e)` handles
them.

Better still: bake the invariant into the snapshot type so the
lookup can't fail. A `Map<String, Exercise> exercisesById` index in
the snapshot avoids the linear scan *and* makes the absent case a
type error. This is a domain-layer change, not a `workout_overview`
change.

---

## 3. High-priority improvements

### Bug 3.1 — `_resolveOnto` has duplicate dead branches

```56:81:lib/modules/workout_overview/services/drop_resolver.dart
static DropIntent _resolveOnto({
  required String sessionId,
  required List<SupersetGroupViewModel> groups,
  required String draggedId,
  required String targetId,
}) {
  if (draggedId == targetId) return const DropIntent.noop();

  final draggedTag = _supersetTagFor(groups, draggedId);
  final targetTag = _supersetTagFor(groups, targetId);

  if (draggedTag != null && draggedTag == targetTag) {
    return const DropIntent.noop();
  }
  if (draggedTag != null && draggedTag != targetTag) {
    return const DropIntent.noop();
  }

  final targetIsUnfinished = _isUnfinished(groups, targetId);
  if (!targetIsUnfinished) return const DropIntent.noop();

  return DropIntent.createSuperset(
    sessionId: sessionId,
    sessionExerciseIds: [draggedId, targetId],
  );
}
```

The two `if (draggedTag != null …)` branches collapse to a single
`if (draggedTag != null) return const DropIntent.noop();`. The fact
that the original author chose to write the case split this way
suggests one of:

- They *meant* to handle "moving into a foreign superset" differently
  (e.g. join the target's superset, then drop) but didn't finish.
- They left the two cases open intentionally as a TODO marker.

Either way, the current code says "if the dragged exercise is
already in any superset, drop is a no-op". That's a legitimate UX
choice, but it should be a single branch with a comment:

```dart
// We don't currently support moving an exercise that is already in
// a superset onto another exercise (it would need to leave its
// existing superset first). Drag-to-ungroup is the supported flow.
if (draggedTag != null) return const DropIntent.noop();
```

If the *intended* behaviour is "join the target's superset", the
sealed `DropIntent` is missing the `joinSuperset` variant. Add it
before users start dragging things.

### Medium 3.2 — `_buildSetRows` zips by index, not by `position`

```76:115:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
static List<SetRowViewModel> _buildSetRows(
  SessionExercise sessionExercise,
  Exercise plannedExercise,
  Cursor cursor,
) {
  final plannedSets = List<WorkoutSet>.of(plannedExercise.sets)
    ..sort((a, b) => a.position.compareTo(b.position));
  final executedSets = List<ExecutedSet>.of(sessionExercise.executedSets)
    ..sort((a, b) => a.position.compareTo(b.position));

  final rows = <SetRowViewModel>[];

  for (var i = 0; i < plannedSets.length; i++) {
    final executed = i < executedSets.length ? executedSets[i] : null;
    ...
  }

  for (var j = plannedSets.length; j < executedSets.length; j++) {
    rows.add(
      SetRowViewModel(
        position: j,
        plannedValues: null,
        executedSet: executedSets[j],
        ...
      ),
    );
  }
  return rows;
}
```

The function sorts both lists by `.position` and then zips them at
*array index* `i`. This is only correct if both lists are densely
populated at positions 0..N-1. The domain invariants enforce this for
`plannedSets` (the `Exercise._()` constructor body verifies dense
positions). For `executedSets`, the invariant is less obvious — the
domain layer's `ExecutedSet` allows skipped positions because of the
`ExerciseGroup` skip-flow.

For example, suppose `executedSets` contains entries with positions
`[0, 1, 3]` (set 2 was skipped, then 3 was completed). After the
sort, `executedSets[0..2]` exists but
`executedSets[2].position == 3`. The current code pairs:

- `plannedSets[0]` ↔ `executedSets[0]` (position 0)
- `plannedSets[1]` ↔ `executedSets[1]` (position 1)
- `plannedSets[2]` ↔ `executedSets[2]` (position 3 — wrong)
- `plannedSets[3]` ↔ null

…and the UI now shows "Set 3: completed with the values of executed
set at position 3" — labelled as set 3 but actually set 4 of the
plan. Identity mismatch.

**Fix.** Zip by position, not by index:

```dart
final executedByPosition = {
  for (final e in executedSets) e.position: e,
};
final maxPlanned = plannedSets.isEmpty
    ? -1
    : plannedSets.last.position;
final maxExecuted = executedSets.isEmpty
    ? -1
    : executedSets.last.position;
final maxPos = maxPlanned > maxExecuted ? maxPlanned : maxExecuted;

for (var p = 0; p <= maxPos; p++) {
  final planned = plannedSets.where((s) => s.position == p).firstOrNull;
  final executed = executedByPosition[p];
  if (planned == null && executed == null) continue;
  rows.add(SetRowViewModel(
    position: p,
    plannedValues: planned?.plannedValues,
    executedSet: executed,
    isNextLogTarget: cursor is ActiveCursor
        && cursor.sessionExerciseId == sessionExercise.id
        && cursor.setIndex == p,
  ));
}
```

(If the domain's invariant *does* guarantee dense `executedSets`
positions and the engine doesn't allow gaps, then this is moot. But
the assembler should still defend, and the invariant should be a
doc comment on `SessionExercise.executedSets`.)

### Medium 3.3 — `MutationKind` is dead code

```1:13:lib/modules/workout_overview/models/mutation_kind.dart
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

No references anywhere in `lib/` or `test/`. Either:

- Delete it (it'll come back when the bloc is written, with the
  proper context).
- Or wire it into the events / states that *will* exist.

Leaving it floating risks confusion: a future developer might add a
new variant here, expecting `flutter_bloc` consumers to switch on it,
and not realise nothing reads the enum yet.

If kept, document its purpose. Is it a discriminator for analytics?
For undo? For optimistic-update batching?

### Medium 3.4 — `assemble` walks the snapshot for every session exercise — O(N × M)

```38:71:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
for (final ex in sorted) {
  final planned = _lookupPlannedExercise(ex, session);
  ...
}
```

```117:132:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
static Exercise _lookupPlannedExercise(...) {
  for (final group in session.snapshot.workoutDay.exerciseGroups) {
    for (final exercise in group.exercises) {
      if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
        return exercise;
      }
    }
  }
  throw StateError(...);
}
```

`assemble` calls `_lookupPlannedExercise` once per `SessionExercise`,
and each call does a full nested scan over the snapshot. Worst case
this is O(N × M) where N is session exercises and M is total planned
exercises in the snapshot. For a typical day with 10 exercises, it's
trivial. For users running 30-exercise programs the scan is still
under 1ms. But the right shape is:

```dart
static List<SupersetGroupViewModel> assemble(SessionState sessionState) {
  final session = sessionState.session;
  final plannedById = <String, Exercise>{
    for (final g in session.snapshot.workoutDay.exerciseGroups)
      for (final e in g.exercises)
        e.id: e,
  };
  ...
  for (final ex in sorted) {
    final planned = plannedById[ex.plannedExerciseIdInSnapshot];
    if (planned == null) throw DomainError.notFound(...);
    ...
  }
}
```

This also lets `DropResolver`'s own scans (`_supersetTagFor`,
`_isUnfinished`, `_unfinishedIdsInOrder`) be replaced with map
lookups — see Medium 3.6.

### Medium 3.5 — `SupersetGroupViewModel.supersetTag: String?` is a sealed-via-nullability anti-pattern

```7:13:lib/modules/workout_overview/models/superset_group_view_model.dart
@freezed
abstract class SupersetGroupViewModel with _$SupersetGroupViewModel {
  const factory SupersetGroupViewModel({
    required String? supersetTag,
    required List<ExerciseViewModel> exercises,
  }) = _SupersetGroupViewModel;
}
```

`supersetTag: null` means "single exercise group"; non-null means
"superset". This is the same pattern Freezed sealed unions exist
specifically to *replace*:

```dart
@Freezed(unionKey: 'type')
sealed class SupersetGroupViewModel with _$SupersetGroupViewModel {
  const factory SupersetGroupViewModel.single(ExerciseViewModel exercise)
      = SingleGroupViewModel;

  const factory SupersetGroupViewModel.superset({
    required String tag,
    required List<ExerciseViewModel> exercises,
  }) = SupersetGroupViewModelGroup;
}
```

…and now the assembler can't construct a "superset with one exercise"
or a "single with two exercises". The invariant is in the type.

This also simplifies the widget code that hasn't been written yet:
`switch (group) { SingleGroupViewModel(:final exercise) => ...,
SupersetGroupViewModelGroup(:final tag, :final exercises) => ... }`.

### Medium 3.6 — Nested scans in `DropResolver`

```97:124:lib/modules/workout_overview/services/drop_resolver.dart
static String? _supersetTagFor(
  List<SupersetGroupViewModel> groups,
  String sessionExerciseId,
) {
  for (final g in groups) {
    for (final ex in g.exercises) {
      if (ex.sessionExercise.id == sessionExerciseId) {
        return ex.sessionExercise.supersetTag;
      }
    }
  }
  return null;
}

static bool _isUnfinished(
  List<SupersetGroupViewModel> groups,
  String sessionExerciseId,
) {
  for (final g in groups) {
    for (final ex in g.exercises) {
      if (ex.sessionExercise.id == sessionExerciseId) {
        return ex.sessionExercise.state is UnfinishedState;
      }
    }
  }
  return false;
}
```

Two near-identical nested scans, each called once per drop intent.
Build an index upfront once per resolve:

```dart
final byId = <String, ExerciseViewModel>{
  for (final g in groups)
    for (final ex in g.exercises)
      ex.sessionExercise.id: ex,
};
```

Then `_supersetTagFor` becomes `byId[id]?.sessionExercise.supersetTag`
and `_isUnfinished` becomes
`byId[id]?.sessionExercise.state is UnfinishedState`.

Same `_unfinishedIdsInOrder` walks unconditionally. Single source of
truth, cheaper.

---

## 4. Medium-priority improvements

### Medium 4.1 — `_resolveGap` clamps the target index using the un-mutated source list

```36:54:lib/modules/workout_overview/services/drop_resolver.dart
static DropIntent _resolveGap({
  required String sessionId,
  required List<String> unfinishedIds,
  required String draggedId,
  required int index,
}) {
  final draggedIndex = unfinishedIds.indexOf(draggedId);
  final without = List<String>.of(unfinishedIds)..remove(draggedId);
  final clampedTarget = index.clamp(0, unfinishedIds.length);
  final insertion = clampedTarget > draggedIndex
      ? clampedTarget - 1
      : clampedTarget;
  final reordered = List<String>.of(without)..insert(insertion, draggedId);
  if (_listEquals(reordered, unfinishedIds)) return const DropIntent.noop();
  return DropIntent.reorder(
    sessionId: sessionId,
    orderedUnfinishedIds: reordered,
  );
}
```

`clampedTarget = index.clamp(0, unfinishedIds.length)` — clamps using
the **un-mutated** list length. After removing `draggedId`, the valid
insertion range is `0..unfinishedIds.length - 1`. If `index ==
unfinishedIds.length` (drag past the last item), `clampedTarget` is
`unfinishedIds.length`; after adjustment to
`clampedTarget - 1 = unfinishedIds.length - 1`, the `insert` call
gets `unfinishedIds.length - 1` into a list of size
`unfinishedIds.length - 1`, which inserts at the **last position** —
correct, but the boundary is subtle.

The off-by-one bug to watch is when `draggedIndex == 0` and `index ==
unfinishedIds.length` (drag the first item to the end). Walk:

- `unfinishedIds = [A, B, C, D]`, `draggedId = A`, `index = 4`.
- `draggedIndex = 0`, `without = [B, C, D]`.
- `clampedTarget = 4.clamp(0, 4) = 4`.
- `4 > 0`, so `insertion = 4 - 1 = 3`.
- `[B, C, D]..insert(3, A) = [B, C, D, A]`. Correct.

OK, the math is right. But the implementation is dense enough that a
small inline doc with the algorithm name (this is the "drag-to-index
with self-removal" algorithm; the same one Flutter's
`ReorderableListView` uses internally) helps readers.

### Medium 4.2 — `PlannedSummaryFormatter._fmtKg` formatting edge cases

```22:23:lib/modules/workout_overview/services/planned_summary_formatter.dart
static String _fmtKg(double kg) =>
    kg == kg.truncateToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1);
```

For `kg == 0` returns `'0'`. For `kg == 60.5` returns `'60.5'`. For
`kg == 60.55` returns `'60.6'` (rounded). That's probably the desired
display — the domain validation rejects sub-half-kg precision
(`program_validation.dart:49`) so `60.55` shouldn't reach this
formatter. But the formatter silently rounds rather than asserting.

Also: this is **the third weight formatter** in the codebase:

- `program_management/services/text_plan/plan_pretty_printer.dart:_formatWeight`
- `program_management/services/plan_draft_to_aggregate.dart` (inline ternary)
- `workout_overview/services/planned_summary_formatter.dart:_fmtKg`

They have *similar but not identical* behaviour:

```dart
// plan_pretty_printer.dart:_formatWeight
if (weightKg == weightKg.truncateToDouble()) {
  return weightKg.toInt().toString();
}
return weightKg.toString();
```

```dart
// plan_draft_to_aggregate.dart (inline)
weightInput: weightKg == weightKg.truncateToDouble()
    ? weightKg.toInt().toString()
    : weightKg.toString(),
```

```dart
// planned_summary_formatter.dart:_fmtKg
kg == kg.truncateToDouble() ? kg.toStringAsFixed(0) : kg.toStringAsFixed(1)
```

The third rounds to 1 decimal; the first two preserve all decimals
(so `60.501.toString() = '60.501'`). For 0.5-kg-clamped inputs they
agree, but the formatters are not interchangeable.

Promote to a single `core/weight_formatter.dart`:

```dart
abstract final class WeightFormatter {
  static String formatKg(double kg) {
    if (kg == kg.truncateToDouble()) return kg.toInt().toString();
    return kg.toStringAsFixed(1);
  }
}
```

…and have all three callers use it.

### Medium 4.3 — `assemble` ignores the difference between sessions sharing the same superset tag across non-adjacent positions

```59:69:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
final tagMatches = hasCurrent &&
    ex.supersetTag != null &&
    ex.supersetTag == currentTag;
if (tagMatches) {
  buffer.add(vm);
} else {
  flush();
  currentTag = ex.supersetTag;
  hasCurrent = true;
  buffer.add(vm);
}
```

Suppose the user's session has session exercises ordered by position:

| Position | id | supersetTag |
|----------|----|-------------|
| 0        | A  | `'A'`       |
| 1        | B  | `null`      |
| 2        | C  | `'A'`       |

The domain layer's rules — as documented in `domain_review.md` —
state that supersets must be *contiguous* (consecutive positions
share a tag, or there's no tag). The assembler honours this: A and
C wouldn't be grouped because B in the middle has `null`. But there
is no assertion that says "this shouldn't happen at the domain
layer". If the domain ever produces a configuration like the above,
the assembler silently degrades to three separate groups, and the
user will see C labelled as "single" even though its tag is `'A'`.

Two options:

- Add an `assert` in the assembler that catches non-contiguous
  superset tags in debug builds, with a clear message.
- Or change `SessionExercise.supersetTag` to a value type that
  encodes the position invariant at the domain layer.

This is best fixed in the domain layer — `assemble` is a downstream
victim.

### Medium 4.4 — Exercise view model duplicates id linkage

```7:18:lib/modules/workout_overview/models/exercise_view_model.dart
@freezed
abstract class ExerciseViewModel with _$ExerciseViewModel {
  const factory ExerciseViewModel({
    required SessionExercise sessionExercise,
    required Exercise plannedExerciseInSnapshot,
    required String plannedSummary,
    required List<SetRowViewModel> setRows,
    required bool isCursorTarget,
    required int? cursorSetIndex,
    required MeasurementType effectiveMeasurementType,
  }) = _ExerciseViewModel;
}
```

`sessionExercise.plannedExerciseIdInSnapshot` must equal
`plannedExerciseInSnapshot.id`. Anyone constructing this view model
manually (a test, a future bloc helper) could supply mismatched
values. Cleaner:

- Drop `plannedExerciseInSnapshot` and let the widget look it up
  through a small accessor (slow path), *or*
- Add an assertion in a custom Freezed `_()` constructor body, *or*
- Wrap the pair in a domain-level type
  `(SessionExercise, Exercise) plannedAndSession`.

The first is the cheapest if `plannedSummary` is the only thing the
widget reads from `plannedExerciseInSnapshot` (it appears that's the
case). In that case, drop the planned-exercise field entirely —
`plannedSummary` already encodes the relevant data.

---

## 5. Low-priority / nits

### Low 5.1 — `workout_overview.dart` is empty

```1:lib/modules/workout_overview/workout_overview.dart
library;
```

`library;` without an attached doc comment is a no-op. Either delete
the file or use it as a barrel:

```dart
/// Workout overview module.
///
/// Provides view-models, services, and (eventually) bloc/screen for
/// the active-session "see all exercises at once" screen.
library;

export 'models/exercise_view_model.dart';
export 'models/superset_group_view_model.dart';
export 'models/set_row_view_model.dart';
export 'models/drop_intent.dart';
export 'models/workout_overview_args.dart';
export 'services/drop_resolver.dart';
export 'services/exercise_view_model_assembler.dart';
export 'services/planned_summary_formatter.dart';
```

…and add the bloc/screen/widget exports as you implement them. Even
without the latter, the barrel gives external consumers a single
import line.

### Low 5.2 — `DropResolver._listEquals` is yet another copy

```125:132:lib/modules/workout_overview/services/drop_resolver.dart
static bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

`package:flutter/foundation.dart` exports
`bool listEquals<T>(List<T>? a, List<T>? b)` — exactly this
function with null-tolerance. Same observation as
`program_management_review.md` Low 5.3. Use it everywhere.

### Low 5.3 — `assemble` mutates intermediate buffers

```19:36:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
void flush() {
  if (buffer.isEmpty) return;
  if (currentTag == null) {
    for (final vm in buffer) {
      groups.add(
        SupersetGroupViewModel(supersetTag: null, exercises: [vm]),
      );
    }
  } else {
    groups.add(
      SupersetGroupViewModel(
        supersetTag: currentTag,
        exercises: List<ExerciseViewModel>.of(buffer),
      ),
    );
  }
  buffer.clear();
}
```

The local `void flush()` closure mutates `buffer`, `currentTag`,
`hasCurrent`, and `groups`. Closures over mutable state work but are
hard to test in isolation. A purely-functional implementation
(returning the accumulator):

```dart
static List<SupersetGroupViewModel> assemble(SessionState s) {
  ...
  final folded = sorted.fold<(List<SupersetGroupViewModel>, _Pending?)>(
    (const [], null),
    (acc, ex) => _consume(acc, ex, ...),
  );
  return [...folded.$1, if (folded.$2 != null) _flush(folded.$2!)];
}
```

…is a *lot* more code in Dart without `fp`-style helpers. Worth
keeping the imperative `flush()` for readability. Just note that the
function depends on `buffer.clear()` being called or it'll double-emit
on a future change.

### Low 5.4 — `_buildSetRows` uses positional index in the cursor check

```88:101:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
for (var i = 0; i < plannedSets.length; i++) {
  final executed = i < executedSets.length ? executedSets[i] : null;
  final isNextLogTarget = cursor is ActiveCursor &&
      cursor.sessionExerciseId == sessionExercise.id &&
      cursor.setIndex == i;
  ...
}
```

`cursor.setIndex == i` — same loop index used twice. If `Cursor.setIndex`
is a *position*, not an index (the names overlap), the check could be
off. The domain layer doesn't define which is which clearly in the
single file I read; verify against `domain/services/session_flow_engine.dart`.

If `setIndex` is a position, switch to `cursor.setIndex == plannedSets[i].position`.

### Low 5.5 — `WorkoutOverviewArgs` is a single-field Freezed wrapper

```5:9:lib/modules/workout_overview/models/workout_overview_args.dart
@freezed
abstract class WorkoutOverviewArgs with _$WorkoutOverviewArgs {
  const factory WorkoutOverviewArgs({required String sessionId}) =
      _WorkoutOverviewArgs;
}
```

The `program_management` module uses plain classes for the same shape
(`WorkoutDayArgs`, `ExerciseArgs`). The `workout_day_picker` module
uses Freezed (`WorkoutDayPickerArgs`). The workout_overview module
follows the picker, fine. But the codebase has *two* conventions
for routing arg classes. Standardise on one (Freezed is fine — gives
free `==`, `hashCode`, `toString`).

### Low 5.6 — `flush()` adds singles into separate groups but `else` adds the whole buffer

```19:36:lib/modules/workout_overview/services/exercise_view_model_assembler.dart
if (currentTag == null) {
  for (final vm in buffer) {
    groups.add(
      SupersetGroupViewModel(supersetTag: null, exercises: [vm]),
    );
  }
} else {
  groups.add(
    SupersetGroupViewModel(
      supersetTag: currentTag,
      exercises: List<ExerciseViewModel>.of(buffer),
    ),
  );
}
```

If `currentTag == null` the buffer is always exactly one element (the
`tagMatches` clause is `false` when `ex.supersetTag == null` regardless
of state), so the `for (final vm in buffer)` loop is misleading —
it suggests multiple singles can be flushed at once when only one
ever is. Replace with the single case explicitly:

```dart
if (currentTag == null) {
  assert(buffer.length == 1,
      'A null-tag flush must contain exactly one exercise');
  groups.add(SupersetGroupViewModel(
    supersetTag: null,
    exercises: [buffer.single],
  ));
}
```

This also reinforces the invariant for readers.

### Low 5.7 — `DropResolver._listEquals` could use record-based result

```49:53:lib/modules/workout_overview/services/drop_resolver.dart
final reordered = List<String>.of(without)..insert(insertion, draggedId);
if (_listEquals(reordered, unfinishedIds)) return const DropIntent.noop();
return DropIntent.reorder(
  sessionId: sessionId,
  orderedUnfinishedIds: reordered,
);
```

When `_listEquals(reordered, unfinishedIds)` is true (i.e. drop didn't
move anything), returning `noop` is correct. But `noop` is also what
`_resolveOnto` returns for the "this is bad UX, refuse" cases. A
finer-grained `noop` variant — `noopBecauseUnchanged` vs
`noopBecauseUnsupported` — would help analytics and tests
distinguish "expected" no-ops from "we refused to do that" no-ops.

Optional but informative.

---

## 6. File-by-file notes

### `workout_overview.dart`

See Low 5.1.

### `models/`

- `drop_intent.dart` — both `DropTarget` and `DropIntent` are
  sealed Freezed unions with `unionKey: 'type'`. Consistent. Good.
- `exercise_view_model.dart` — see Medium 4.4.
- `mutation_kind.dart` — see Medium 3.3.
- `set_row_view_model.dart` — minimal Freezed value. Good.
  `position: int` is an Index, not the planned set's position — see
  Low 5.4.
- `superset_group_view_model.dart` — see Medium 3.5.
- `workout_overview_args.dart` — see Low 5.5.

### `services/`

- `drop_resolver.dart` — see Bug 3.1, Medium 3.6, Medium 4.1,
  Low 5.2, Low 5.7. The `_resolveGap` algorithm is correct, just
  dense.
- `exercise_view_model_assembler.dart` — see High 2.2, Medium 3.2,
  Medium 3.4, Medium 4.3, Low 5.3, Low 5.4, Low 5.6.
- `planned_summary_formatter.dart` — see Medium 4.2.

### `bloc/`, `screens/`, `widgets/`

Empty. See High 2.1.

---

## 7. Cross-cutting suggestions

1.  **Decide whether to finish or pause the module.** Right now it's
    in a zombie state: enough code to look implemented in the file
    tree but no consumers. Add a `TODO.md` in the folder, or move the
    types into a "pre-implementation" folder until the bloc is
    written. The current arrangement breeds drift between the types
    and what eventually needs them.

2.  **Add a unit test for `ExerciseViewModelAssembler.assemble`.**
    Even before the bloc exists, `assemble` is a pure function with
    well-defined input/output. Hand-craft a `SessionState` with a
    superset, a single, and a skipped exercise; assert on the
    resulting `List<SupersetGroupViewModel>` shape. This will also
    surface Medium 3.2 (the index-vs-position issue) faster than a
    code review.

3.  **Add a unit test for `DropResolver.resolve`.** Same reasoning.
    Tests for:
    - drop onto self → noop
    - drop into same superset → noop
    - drop from a superset onto a non-superset → noop (today;
      `createSuperset` if you implement Bug 3.1's intended behaviour)
    - drop a single onto a single → createSuperset
    - drag-to-rear/front gap → reorder

4.  **Wait to write the bloc until you've fixed `DomainErrorPresenter`'s
    location (see workout-day-picker review High 3.2).** Otherwise
    `workout_overview` will pick up the same cross-module dependency.

5.  **Treat the High and Medium items above as design TODOs**
    visible to whoever picks this module up. They're cheaper to fix
    before the bloc is written than after; the bloc's event handlers
    will encode the current assembler/resolver behaviour and rebound
    bugs become noticeably more expensive.

---

## 8. Suggested order of fixes

1.  **High 2.2** — replace `StateError` with a `DomainError`. One
    line. Lets future bloc code use the standard error path.
2.  **Bug 3.1** — disambiguate or implement the two branches in
    `_resolveOnto`. Decide the UX semantics now.
3.  **Medium 3.2** — zip by position. Catches the bug class at
    its source.
4.  **Medium 3.3** — delete or wire `MutationKind`.
5.  **Medium 3.5** — sealed superset/single union.
6.  **High 2.1** — write the bloc, screen, and widgets, *or* document
    the decision to defer them.
