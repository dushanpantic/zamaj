# `lib/modules/program_management` — Code Review

Scope: every non-generated file under `lib/modules/program_management/`
(generated `*.freezed.dart` / `*.g.dart` files are excluded). Evaluated
against current Dart 3 / Flutter / `flutter_bloc` / Freezed v3 best
practices and the project's own `analysis_options.yaml`.

This is the largest feature module in the codebase. The architecture is
sound: bloc-per-screen, Freezed drafts, sealed events/states, a thin
`AggregateSaver` service, a deterministic text-plan parser with sealed
result/error/warning types. The findings below are about robustness,
maintainability, and idiom — not a redesign.

---

## TL;DR — Top items, in order of impact

| #  | Item                                                                                                              | Severity |
| -- | ----------------------------------------------------------------------------------------------------------------- | -------- |
| 1  | `WorkoutDayEditorBloc._persist` is a 260-line non-atomic transaction; partial failures leave inconsistent state    | **Bug**  |
| 2  | Every keystroke in `ProgramEditorBloc` / `WorkoutDayEditorBloc` / `ExerciseEditorBloc` triggers a full repo save  | High     |
| 3  | Moving an exercise between groups **deletes and re-creates** it, losing identity and any future history           | **Bug**  |
| 4  | `_showAddWorkoutDayDialog` leaks its `TextEditingController`                                                       | **Bug**  |
| 5  | `ProgramDraft.toAggregate()` / `_draftExerciseToDomain` call `DateTime.now().toUtc()` directly — bypass `AppClock` | High     |
| 6  | `_listEquals` re-implemented inline; `_closeGroupIfOpen` is dead code                                              | Low      |
| 7  | `ProgramListBloc._loadPrograms` mutates the list returned by the repo (`.sort` in-place)                          | Medium   |
| 8  | `ProgramEditorBloc` saves into `_baselineWorkoutDays` from `_persistEdit` but never re-loads `exerciseGroups` — `groups: const []` is silently dropped on every roundtrip | Medium |
| 9  | Bloc state files hand-roll `copyWith` with `T? Function()?` "explicit-null" wrappers; verbose and easy to misuse  | Medium   |
| 10 | `ProgramValidation` returns string codes (`'name_too_long'`); UI can't pattern-match, can only render             | Medium   |
| 11 | `program_management.dart` barrel is partial and inconsistent (no bloc/screen exports; service exports leak)      | Medium   |
| 12 | `models/program_aggregate.dart` is a one-line re-export wrapper around the domain layer — pure indirection       | Low      |
| 13 | Inconsistent `Equatable` styling: some events/states omit `props => const []`, others always include them         | Low      |
| 14 | `WorkoutDayListTile`'s fallback key (`key ?? ValueKey(name)`) collides if two days share a name                  | Medium   |
| 15 | `TextPlanParser` is a 500-line file with mixed private top-level helpers + sealed classifications                  | Low      |
| 16 | `PlanPreviewScreen` listener navigates on `Saved` / `Discarded`, but the builder still renders a full Scaffold + spinner for those states immediately before the pop | Low |
| 17 | `UrlLauncherExternalLinkLauncher._youtubeHosts` duplicates `youtube.com` and `www.youtube.com`                    | Low      |

The rest of the document walks file-by-file, then expands on these
items.

Severity legend: **Bug** · High · Medium · Low.

---

## 1. What's done well

Worth keeping; future modules should imitate these.

1.  **Bloc separation per screen.** Five focused blocs
    (`ProgramList`, `ProgramEditor`, `WorkoutDayEditor`,
    `ExerciseEditor`, `PlanImport`, `PlanPreview`) with sealed
    event/state hierarchies, each kept under one folder. Tests can fake
    one bloc at a time.

2.  **Drafts mirror the domain.** `ProgramDraft`, `WorkoutDayDraft`,
    `ExerciseGroupDraft`, `ExerciseDraft`, `PlannedSetDraft`,
    `PlannedSetDraftValues` is a faithful Freezed-shaped editor model
    that lets the UI hold partial / invalid input without polluting the
    domain. The `draftId` (UI-stable) vs `persistedId` (repo-stable)
    separation is the right idiom for this pattern.

3.  **Sealed events and states**. `ProgramEditorEvent`,
    `ExerciseEditorState`, `ParseResult`, `PlannedSetDraftValues` are
    all sealed — combined with Dart 3 exhaustive `switch`, every
    consumer has compile-time coverage. `program_list_screen.dart`,
    `workout_day_editor_screen.dart`, `exercise_editor_screen.dart`,
    and `plan_preview_screen.dart` all use exhaustive switches in their
    builders.

4.  **`ValidationResult<T>` is a proper sealed result type.**
    `Valid<T>` / `Invalid<T>` plus a static-only `ProgramValidation`
    class is a clean enough functional shape — much better than
    throwing for input validation.

5.  **`ExternalLinkLauncher` is interface-first** with
    `UrlLauncherExternalLinkLauncher` as the only concrete impl,
    bound at the composition root via `RepositoryProvider`. The bloc
    holds the interface, never `package:url_launcher` itself. Good
    hexagonal hygiene.

6.  **`TextPlanParser` produces structured warnings/errors.** Not a
    `String` blob — `PlanParseError`/`PlanParseWarning` are Freezed
    types with `JsonSerializable` codes (`PlanParseErrorCode`,
    `PlanParseWarningCode`). The UI in `plan_parse_error_banner.dart`
    pattern-matches the code.

7.  **`AggregateSaver` is a single-method service.** Avoids putting
    `draft.toAggregate()` then `saveProgramAggregate(...)` everywhere.
    Clean and testable. `PlanPreviewBloc` and `ProgramEditorBloc` both
    use it.

8.  **`DomainErrorPresenter` is a centralised, pure mapping** from
    `DomainError` to UI text. Easy to test, easy to swap for an i18n
    layer later.

9.  **Theme tokens are used consistently.** Every padding, gap, radius
    and color reads from `AppSpacing` / `AppRadius` / `AppColors` —
    very few magic numbers anywhere. This is well above average for a
    Flutter codebase.

10. **`MeasurementTypeSelector` and `PlannedSetRow`** are extracted
    presentational widgets that wouldn't be tempting to inline. Good
    boundary.

---

## 2. Critical findings

### Bug 2.1 — `WorkoutDayEditorBloc._persist` is a 260-line non-atomic transaction

```309:572:lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart
Future<void> _persist(
  Emitter<WorkoutDayEditorState> emit, {
  bool navigateToNewExercise = false,
}) async {
  ...
  // 1. updateWorkoutDay (name change)
  // 2. deleteExerciseGroup(...) for removed groups
  // 3. reorderExerciseGroups(...)
  // 4. deleteExercise(...) for moves
  // 5. createExerciseGroup(...) / updateExercise(...) / createExercise(...) / createSet(...) / reorderExercises(...) / updateExerciseGroup(...)
  // 6. reorderExerciseGroups(...) again
  // 7. final getWorkoutDay
  ...
}
```

The body is **9+ separate repository calls** sequenced manually, each
with its own potential `DomainError`. If step 4 succeeds but step 5
throws, the database is now in a partial state (exercises deleted but
not re-created) and the bloc emits `current.draft` unchanged. The user
sees a save error, but their next edit operates on a stale baseline
that mismatches the persisted state.

Equally important: the diff itself isn't trivially correct. The block
that detects "moved" exercises deletes them and re-creates them — see
**Bug 2.3** below.

**Fix.** This needs to be wrapped in a single domain-level "apply this
draft to this workout day" operation that runs inside a Drift
transaction. Two reasonable shapes:

1. **Repository-level method.** Add
   `ProgramRepository.applyWorkoutDayDraft(workoutDayId, draft)` and
   let the Drift implementation wrap the SQL in `transaction(() async
   {...})`. The bloc then makes one call.
2. **Service-level diff applier.** Add a `WorkoutDayDiffApplier`
   service that takes a baseline `WorkoutDay`, a target `Draft`,
   computes the operation list, and submits them via a repository
   `runInTransaction(...)` hook. Same outcome, but lets the diff logic
   be unit-tested without the bloc.

(2) is the smaller blast-radius change because the repository
interface stays domain-only. See `persistence_review.md` Item 4 — that
review already flags the underlying transaction primitive as missing.

In the meantime, even a half-fix helps: at minimum reload baseline
*before* showing the editing state after an error, so subsequent diffs
are computed against reality.

---

### Bug 2.2 — `_showAddWorkoutDayDialog` leaks its `TextEditingController`

```53:111:lib/modules/program_management/screens/program_editor_screen.dart
Future<void> _showAddWorkoutDayDialog() async {
  ...
  final nameController = TextEditingController();
  String? errorText;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(...),
  );
}
```

`TextEditingController` is a `ChangeNotifier` and **must** be disposed
or it leaks its listeners. Every "Add Workout Day" tap from this dialog
leaks one controller for the lifetime of the screen.

The `cancel_subscriptions` / `close_sinks` lints don't catch
`ChangeNotifier`. Either:

- Convert the dialog to a `StatefulWidget` (like
  `_AddExerciseDialog` further down in
  `workout_day_editor_screen.dart`, which does this correctly):

  ```dart
  await showDialog<void>(
    context: context,
    builder: (_) => _AddWorkoutDayDialog(bloc: context.read<ProgramEditorBloc>()),
  );
  ```

- Or dispose it explicitly:

  ```dart
  try {
    await showDialog<void>(...);
  } finally {
    nameController.dispose();
  }
  ```

Prefer the first; the existing `_AddExerciseDialog` is the model.

---

### Bug 2.3 — Cross-group exercise move deletes and re-creates the exercise

```338:469:lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart
final movedExerciseIds = <String>{};
for (final entry in draftExerciseGroupOwnership.entries) {
  final exerciseId = entry.key;
  final newGroupId = entry.value;
  final oldGroupId = baselineExerciseGroupOwnership[exerciseId];
  if (oldGroupId != null && oldGroupId != newGroupId) {
    movedExerciseIds.add(exerciseId);
  }
}
...
for (final exerciseId in movedExerciseIds) {
  await _programRepository.deleteExercise(exerciseId);
}
...
for (var j = 0; j < group.exercises.length; j++) {
  final exerciseDraft = group.exercises[j];
  if (exerciseDraft.persistedId == null ||
      movedExerciseIds.contains(exerciseDraft.persistedId)) {
    final created = await _programRepository.createExercise(
      exerciseGroupId: persistedGroupId,
      ...
    );
    for (final setDraft in exerciseDraft.sets) {
      await _programRepository.createSet(
        exerciseId: created.id,
        plannedValues: _draftValuesToPlanned(setDraft.values),
      );
    }
  }
}
```

When the user drags exercise *Bench Press* from group A into group B,
the bloc:

1. Deletes `Bench Press` from group A.
2. Creates a brand-new `Bench Press` (with a **new exercise id**) in
   group B.
3. Re-creates each of its planned sets (with **new set ids**).

Consequences:

- **Identity is destroyed**. The exercise is a new entity from the
  database's point of view; any past `Session` referencing the old
  `Exercise.id` via `Session.snapshot` is now orphaned (the snapshot
  itself is a captured copy so it survives, but any future feature
  that joins planned-to-executed history will break).
- **Set ids change**, even though the planned values are identical.
- **Created/updated timestamps reset.**

The right model is a `moveExercise(exerciseId, toGroupId, position)`
repository call (and equivalent SQL `UPDATE`), keeping the row's
identity. The `program_management/bloc` layer should not be deleting
domain entities just to relocate them.

(Same shape applies to `ProgramEditorBloc` if you later support moving
workout days between programs.)

---

## 3. High-priority improvements

### High 3.1 — Every keystroke triggers a save

```119:143:lib/modules/program_management/bloc/program_editor/program_editor_bloc.dart
Future<void> _onNameChanged(
  ProgramEditorNameChanged event,
  Emitter<ProgramEditorState> emit,
) async {
  ...
  emit(
    current.copyWith(
      draft: updatedDraft,
      validation: validation,
      lastSaveError: () => null,
    ),
  );

  if (validation.canSave) {
    await _persist(emit);
  }
}
```

`_persist` issues `updateProgram` and (for the workout-day editor)
multiple round-trips. Doing this on every keystroke is wasteful and
janky — on slow disks it adds a perceptible lag, and on every save the
state churns through `isSaving: true` → `isSaving: false`, which is
visible in the UI.

Add a debounce. With `flutter_bloc` the canonical pattern is
`EventTransformer`:

```dart
import 'package:rxdart/rxdart.dart';

EventTransformer<E> _debounce<E>(Duration d) =>
    (events, mapper) => events.debounceTime(d).switchMap(mapper);

ProgramEditorBloc(...) {
  on<ProgramEditorNameChanged>(_onNameChanged,
      transformer: _debounce(const Duration(milliseconds: 300)));
}
```

(or use `bloc_concurrency` package's `restartable()` /
`droppable()` if you'd rather avoid a `rxdart` dep — both packages are
de-facto standards.)

If you don't want to add a dep, at least debounce inside the screen
with a `Timer.periodic(...)`. The bloc autosave-on-every-event pattern
also makes the UI brittle if the user hammers keys faster than
disk I/O.

The same comment applies to `WorkoutDayEditorBloc._onNameChanged`,
`_onQuickExerciseAdded`, `_onGroupDeleted`, `_onGroupsReordered`,
`_onExerciseAddedToGroup`, etc.

### High 3.2 — `DateTime.now().toUtc()` is called directly, bypassing `AppClock`

```23:38:lib/modules/program_management/models/program_editor_draft.dart
ProgramAggregate toAggregate() {
  const uuid = Uuid();
  final now = DateTime.now().toUtc();
  ...
}
```

```602:631:lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart
Exercise _draftExerciseToDomain(
  ExerciseDraft draft, {
  required String exerciseGroupId,
  required int position,
}) {
  final now = DateTime.now().toUtc();
  ...
}
```

The domain review (`domain_review.md`) and this codebase explicitly
inject `AppClock` everywhere else. These two sites skip it. Tests that
need to assert "createdAt equals fixed clock value" can't, and the
behaviour is non-deterministic.

`PlanDraftToAggregate` already does the right thing by accepting an
`AppClock` argument. Thread it through `ProgramDraft.toAggregate()`
and through `WorkoutDayEditorBloc._draftExerciseToDomain`:

```dart
ProgramAggregate toAggregate({required AppClock clock, required Uuid uuid}) {
  final now = clock.now().toUtc();
  ...
}
```

`AggregateSaver.save()` is the natural injection point:

```dart
class AggregateSaver {
  const AggregateSaver(this._programRepository, this._clock, this._uuid);
  ...
  Future<Program> save(ProgramDraft draft) async {
    final aggregate = draft.toAggregate(clock: _clock, uuid: _uuid);
    return _programRepository.saveProgramAggregate(aggregate);
  }
}
```

### High 3.3 — `_persistEdit` reloads workout days but always sets `groups: const []`

```391:417:lib/modules/program_management/bloc/program_editor/program_editor_bloc.dart
final reloadedDraft = ProgramDraft(
  programId: reloadedProgram.id,
  name: reloadedProgram.name,
  workoutDays: reloadedDays
      .map(
        (day) => WorkoutDayDraft(
          draftId: day.id,
          persistedId: day.id,
          name: day.name,
          groups: const [],
        ),
      )
      .toList(),
  schemaVersion: reloadedProgram.schemaVersion,
);
```

After a save in the program editor, every reloaded workout day has
`groups: const []`. This is only OK because the program editor itself
never displays groups (it routes to the workout-day editor for that).
But it's a sharp edge that's not signposted anywhere, and the same
draft type is reused in the workout-day editor where `groups: []`
would mean "delete all exercise groups". Currently the type system
hides this trap behind whichever editor is loaded.

Two options:

1. **Two draft types.** `ProgramDraft` (no groups) and
   `WorkoutDayWithGroupsDraft` for the workout-day editor. More work,
   but the type system enforces the invariant.
2. **A non-nullable explicit-empty marker.** Replace `List<WorkoutDayDraft>`
   in `ProgramDraft` with a `List<WorkoutDayHeadingDraft>` (no `groups`
   field). The `WorkoutDayDraft` type used by the workout-day editor
   keeps `groups`.

The current shape essentially has "tombstone-empty" groups which is
the worst of both worlds.

---

## 4. Medium-priority improvements

### Medium 4.1 — `ProgramListBloc._loadPrograms` mutates a repository return value

```76:87:lib/modules/program_management/bloc/program_list/program_list_bloc.dart
try {
  final programs = await _programRepository.listPrograms();
  programs.sort((a, b) {
    final cmp = b.updatedAt.compareTo(a.updatedAt);
    if (cmp != 0) return cmp;
    return a.name.toLowerCase().compareTo(b.name.toLowerCase());
  });
  emit(ProgramListLoaded(programs: programs));
}
```

The `ProgramRepository.listPrograms()` contract returns
`Future<List<Program>>` and gives no guarantee about whether the
returned list is mutable or unmodifiable. If a future repository
revision returns `List.unmodifiable(...)` (a sensible defensive
choice), this throws at runtime.

Either:

- Always work on a copy:

  ```dart
  final programs = List<Program>.of(await _programRepository.listPrograms());
  programs.sort(...);
  ```

- Or push the sort into the repository (`listPrograms({SortOrder
  order})`). The persistence review already notes that `listPrograms`
  is N+1 — ordering server-side is one of the cheap wins of pushing
  ORDER BY into Drift.

The same potential mutation appears in
`WorkoutDayEditorBloc._onPlannedSetReordered` (calls
`.toList()` after `map`, which is fine), and in
`_onWorkoutDaysReordered` (also `.toList()`). Only this site mutates.

### Medium 4.2 — Hand-rolled `T? Function()?` "explicit null" `copyWith` is verbose and error-prone

```33:51:lib/modules/program_management/bloc/program_list/program_list_state.dart
ProgramListLoaded copyWith({
  List<Program>? programs,
  String? Function()? deletionCandidateId,
  DomainError? Function()? lastDeleteError,
}) {
  return ProgramListLoaded(
    programs: programs ?? this.programs,
    deletionCandidateId: deletionCandidateId != null
        ? deletionCandidateId()
        : this.deletionCandidateId,
    lastDeleteError: lastDeleteError != null
        ? lastDeleteError()
        : this.lastDeleteError,
  );
}
```

This pattern (closure to disambiguate "leave alone" vs "set to null")
is repeated in `ProgramEditorEditing.copyWith`,
`WorkoutDayEditorEditing.copyWith`, `ExerciseEditorEditing.copyWith`,
`WorkoutDayPickerLoaded.copyWith`, and many others. It works but is
boilerplate, easy to misuse (passing `null` instead of `() => null`),
and easy to forget to handle a new field.

Three cleaner options, in increasing order of disruption:

- **Convert the state classes to Freezed.** The existing `Equatable`
  states are simple enough that Freezed `@freezed sealed class Foo` is
  a one-for-one replacement and gives proper `copyWith(field: null)`
  semantics (via `copyWith(field: Value?(null))` in v3, or
  `Object _undefined` sentinels). Freezed is already a dependency.
- **Use a `Sentinel` pattern.** `static const _unset = Object()`, then
  `copyWith({Object? lastDeleteError = _unset})`. Slightly cleaner
  than `Function()?`.
- **Make state-mutation typed events,** e.g. emit a brand-new
  `ProgramListLoaded` from scratch when you want to clear errors,
  no `copyWith` needed. This is what `ExerciseEditorBloc.
  _onMeasurementTypeConfirmed` already does — and it's actually nice
  to read.

If you go with Freezed, the bloc-state files shrink considerably and
all the props-vs-fields drift goes away (see Medium 4.7).

### Medium 4.3 — `ProgramValidation` returns opaque string codes

```16:25:lib/modules/program_management/services/program_validation.dart
static ValidationResult<String> validateProgramName(
  String name, {
  required bool isCreate,
}) {
  final trimmed = name.trim();
  if (trimmed.isEmpty) return const Invalid('name_too_short');
  final maxLength = isCreate ? 120 : 100;
  if (trimmed.length > maxLength) return const Invalid('name_too_long');
  return Valid(trimmed);
}
```

`Invalid.reason` is a `String`, so the UI has to grep for magic
strings (or, more likely, just rendered a hard-coded "Name must be
1–120 chars" message regardless of the reason). The codes
(`'name_too_short'`, `'weight_invalid'`, `'rest_not_whole'`,
`'url_scheme_not_http_https'`, etc.) can't be exhaustively switched
and can't be i18n'd cleanly.

Make this a sealed type:

```dart
sealed class ProgramValidationError {
  const ProgramValidationError();
}
final class NameTooShort extends ProgramValidationError { const NameTooShort(); }
final class NameTooLong extends ProgramValidationError {
  const NameTooLong({required this.actual, required this.max});
  final int actual;
  final int max;
}
final class WeightInvalid extends ProgramValidationError {
  const WeightInvalid({required this.raw});
  final String raw;
}
...
```

`Invalid<T>` then becomes `Invalid<T> { final ProgramValidationError
reason; ... }`, and the UI can pattern-match on each cause. As a
bonus, `error_text:` strings in the screens stop being inline.

### Medium 4.4 — Workout-day name validation: dialog input has no upper bound

```119:128:lib/modules/program_management/screens/program_editor_screen.dart
void _submitAddDay(
  BuildContext dialogContext,
  TextEditingController controller,
  StateSetter setDialogState,
  void Function(String?) setError,
) {
  final trimmed = controller.text.trim();
  if (trimmed.isEmpty) {
    setDialogState(() => setError('Name cannot be empty'));
    return;
  }
  context.read<ProgramEditorBloc>().add(
    ProgramEditorWorkoutDayAdded(name: trimmed),
  );
  ...
}
```

The dialog only checks empty. Domain-level validation
(`ProgramValidation.validateWorkoutDayName`) rejects strings > 100
chars, but the bloc doesn't validate — `WorkoutDayDraftValidation.of`
only checks the *current* draft's name, not new days being added. A
user can paste a 5,000-char paragraph and the bloc will issue
`createWorkoutDay(name: <5kb>)`; the eventual database write may fail
with a `ValidationError` only after a round-trip.

Call `ProgramValidation.validateWorkoutDayName(trimmed)` from the
dialog, surface the error inline (now that `Medium 4.3` is fixed you
can render it nicely), and only dispatch the bloc event on success.

The same pattern applies to the "Add exercise" dialog in
`workout_day_editor_screen.dart:840-845`.

### Medium 4.5 — `program_management.dart` barrel is partial and inconsistent

```1:8:lib/modules/program_management/program_management.dart
library;

export 'models/program_aggregate.dart';
export 'models/program_editor_draft.dart';
export 'services/aggregate_saver.dart';
export 'services/plan_draft_to_aggregate.dart';
export 'services/text_plan/plan_draft.dart';
```

- `bloc/`, `screens/`, `widgets/`, `navigation/` are not exported.
- `services/aggregate_saver.dart` is exported but
  `services/external_link_launcher.dart` (an interface other modules
  bind via `RepositoryProvider`) is not.
- `services/text_plan/text_plan_parser.dart` is the entry point users
  would expect; instead `plan_draft.dart` is exposed.

Decide who the barrel is for:

- **External callers** want `ProgramManagementRouter`,
  `ProgramManagementRoutes`, `ExternalLinkLauncher` (interface only),
  and maybe `AggregateSaver`. They should not see `program_editor_draft.dart`
  or `text_plan_parser.dart` — those are internals.
- **Tests** want everything.

Either delete the barrel and stick with deep imports (current de
facto pattern — most files import the specific file directly), or
make it a proper public surface and forbid deep imports from outside
the module (with `analysis_options.yaml` `avoid_relative_lib_imports`
already on, plus a custom rule or convention check).

The status quo invites half-imports that miss types and full-imports
that pull in too much.

### Medium 4.6 — `models/program_aggregate.dart` is a one-line indirection

```1:1:lib/modules/program_management/models/program_aggregate.dart
export 'package:zamaj/modules/domain/models/program_aggregate.dart';
```

Pure re-export. Either:

- Delete it and have callers import the domain file directly. The
  domain types are already exported via `package:zamaj/modules/domain/domain.dart`
  which is used elsewhere in the bloc files.
- Or convert it into a `program_management/models/program_aggregate.dart`
  that adds module-specific helpers / extension methods.

The current shape adds an import line for zero behaviour.

### Medium 4.7 — `WorkoutDayListTile`'s fallback key

```22:22:lib/modules/program_management/widgets/workout_day_list_tile.dart
key: key ?? ValueKey(name),
```

`ReorderableListView.builder` already requires each item to have a
unique `Key`, and `program_editor_screen.dart:359` correctly passes
`key: ValueKey(day.draftId)`. The fallback `ValueKey(name)` is dead
code in the only call site — but if a future caller forgets to pass
a `key`, two workout days with the same name (very plausible in this
domain — "Push", "Push") would collide and Reorderable would assert.

Either make `key` a required `super.key`:

```dart
class WorkoutDayListTile extends StatelessWidget {
  const WorkoutDayListTile({
    required super.key,   // <—
    required this.name,
    ...
  });
}
```

…or drop the fallback and let the assertion fire at the call site
where it can be fixed.

### Medium 4.8 — `PlanPreviewScreen` renders a Scaffold for terminal states

```55:97:lib/modules/program_management/screens/plan_preview_screen.dart
Widget _buildScaffold(BuildContext context, PlanPreviewState state) {
  return switch (state) {
    ...
    PlanPreviewSaved() => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
    PlanPreviewDiscarded() => const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    ),
  };
}
```

`PlanPreviewSaved` and `PlanPreviewDiscarded` are immediately followed
by a `Navigator.pushNamedAndRemoveUntil` / `Navigator.pop` from the
listener — but the builder still renders a placeholder `Scaffold` with
a spinner for a frame, which can flash on slower devices.

The usual `flutter_bloc` pattern is:

- Keep the previous state's UI visible (use `buildWhen` to ignore
  terminal states), or
- Use `BlocListener` only (no `BlocConsumer`) for terminal one-shot
  events, and let `BlocBuilder` ignore them entirely.

Switch this to:

```dart
return BlocListener<PlanPreviewBloc, PlanPreviewState>(
  listener: _onStateChange,
  child: BlocBuilder<PlanPreviewBloc, PlanPreviewState>(
    buildWhen: (_, current) =>
        current is! PlanPreviewSaved && current is! PlanPreviewDiscarded,
    builder: (context, state) => _buildScaffold(context, state),
  ),
);
```

…and drop the two dead `Scaffold` cases.

### Medium 4.9 — `ProgramEditorScreen.listener` runs on every state change

```132:155:lib/modules/program_management/screens/program_editor_screen.dart
return BlocConsumer<ProgramEditorBloc, ProgramEditorState>(
  listener: (context, state) {
    if (state is ProgramEditorEditing) {
      if (!_nameControllerSynced) {
        _syncNameController(state.draft.name);
        _nameControllerSynced = true;
      }
      ...
    }
  },
  builder: (context, state) => _buildScaffold(context, state),
);
```

No `listenWhen`. The listener fires on every emit — every keystroke,
every save attempt, every isSaving flip. The body is cheap (mostly
guarded with early returns) but cycles like this scale poorly as the
listener gains responsibilities.

Add a `listenWhen` that gates on what actually matters:

```dart
listenWhen: (prev, curr) {
  if (curr is! ProgramEditorEditing) return false;
  if (prev is! ProgramEditorEditing) return true;          // first edit
  return prev.deletionCandidateDraftId != curr.deletionCandidateDraftId
      || (!_nameControllerSynced && curr.draft.name.isNotEmpty);
},
```

The same observation applies to `WorkoutDayEditorScreen` (which does
already have a `listenWhen`, good) and to `ExerciseEditorScreen` (also
has `listenWhen` — good). `ProgramEditorScreen` is the outlier.

### Medium 4.10 — Inconsistent `Equatable` props

```3:12:lib/modules/program_management/bloc/program_list/program_list_event.dart
sealed class ProgramListEvent extends Equatable {
  const ProgramListEvent();
}

final class ProgramListRequested extends ProgramListEvent {
  const ProgramListRequested();

  @override
  List<Object?> get props => [];
}
```

```3:8:lib/modules/workout_day_picker/bloc/workout_day_picker_event.dart
sealed class WorkoutDayPickerEvent extends Equatable {
  const WorkoutDayPickerEvent();

  @override
  List<Object?> get props => const [];
}
```

Some sealed event/state bases declare a default `props => const []` so
no-arg subclasses can skip the override. Others require every
subclass to declare `props => []` even for zero-field events. Two
different files in the same codebase, two different conventions.

Pick one. Defaulting on the base is fewer lines and harder to
forget. (Even better: drop the manual `Equatable` boilerplate by
making these Freezed sealed unions; you get `==`, `hashCode`, and
`copyWith` for free.)

### Medium 4.11 — `UrlLauncherExternalLinkLauncher._youtubeHosts` has duplicates

```7:12:lib/modules/program_management/services/url_launcher_external_link_launcher.dart
static const _youtubeHosts = {
  'youtube.com',
  'youtu.be',
  'm.youtube.com',
  'www.youtube.com',
};
```

`youtube.com` and `www.youtube.com` are both present, and a future
`youtube-nocookie.com` would slip through. Either normalise the host
before lookup:

```dart
String _normalizeHost(String host) =>
    host.toLowerCase().replaceFirst(RegExp(r'^www\.|^m\.'), '');

final mode = _normalizeHost(url.host) == 'youtube.com'
        || _normalizeHost(url.host) == 'youtu.be'
    ? LaunchMode.externalApplication
    : LaunchMode.platformDefault;
```

…or use `endsWith`:

```dart
final h = url.host.toLowerCase();
final isYouTube = h == 'youtu.be' || h == 'youtube.com'
    || h.endsWith('.youtube.com');
```

Minor, but the duplication is a smell.

### Medium 4.12 — `_RepBasedFields` controller-sync dance is fragile

```122:132:lib/modules/program_management/widgets/planned_set_row.dart
@override
void didUpdateWidget(_RepBasedFields oldWidget) {
  super.didUpdateWidget(oldWidget);
  if (oldWidget.weightInput != widget.weightInput &&
      _weightController.text != widget.weightInput) {
    _weightController.text = widget.weightInput;
  }
  if (oldWidget.repsInput != widget.repsInput &&
      _repsController.text != widget.repsInput) {
    _repsController.text = widget.repsInput;
  }
}
```

The double check (`oldWidget` differs AND controller differs) handles
the "I just emitted this value upward so don't echo it back" case,
which works — but only because the parent passes the same string back
on the next rebuild. If the parent ever transforms the value (e.g.
strips whitespace, normalises "1," → "1.0"), this code happily
overwrites the user's caret and selection. Even today, replacing
`_weightController.text = widget.weightInput` truncates the cursor to
the start.

The robust pattern is to preserve `TextEditingValue.selection`:

```dart
final newText = widget.weightInput;
final oldText = _weightController.text;
if (oldText != newText) {
  final cursorAtEnd = _weightController.selection.baseOffset == oldText.length;
  _weightController.value = _weightController.value.copyWith(
    text: newText,
    selection: TextSelection.collapsed(
      offset: cursorAtEnd ? newText.length : _weightController.selection.baseOffset.clamp(0, newText.length),
    ),
  );
}
```

The `_nameController` in `ProgramEditorScreen._syncNameController` and
`ExerciseEditorScreen._syncControllers` already does the right thing
with explicit `TextSelection.collapsed`. The set-row controllers are
the regression.

---

## 5. Low-priority / nits

### Low 5.1 — `TextPlanParser` is one 500-line file

Mixed concerns inside:

- Pure helpers (`_splitLines`, `_isDayHeader`, `_isSupersetMarker`,
  `_isSetLine`).
- Mutable scope classes (`_DayScope`, `_GroupScope`, `_ExerciseScope`).
- Sealed `_Classification` hierarchy.
- Top-level regex constants.
- A `_RestParseResult` private class.
- The main `_parseLines` engine.

The current shape works, but the file is hard to navigate.
Splitting into:

- `text_plan_parser.dart` — public `TextPlanParser.parse`
- `text_plan_tokens.dart` — line classifications, regex, helpers
- `text_plan_scopes.dart` — `_DayScope` / `_GroupScope` / `_ExerciseScope`

…would make it easier to unit-test classification independently from
attachment.

### Low 5.2 — `_closeGroupIfOpen` is dead code

```220:lib/modules/program_management/services/text_plan/text_plan_parser.dart
void _closeGroupIfOpen(_DayScope? currentDay, _GroupScope? currentGroup) {}
```

Empty body. Either implement (e.g. flag empty supersets as
warnings) or delete the four call sites.

### Low 5.3 — Reimplemented `listEquals`

```664:670:lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart
bool _listEquals(List<String> a, List<String> b) {
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
```

Flutter ships this for free: `package:flutter/foundation.dart`'s
`listEquals<T>(List<T>? a, List<T>? b)`. Drop the helper.

(The same applies to `workout_overview/services/drop_resolver.dart` —
see that review.)

### Low 5.4 — `_isDayHeader`, `_isSupersetMarker` could be a single regex

```222:243:lib/modules/program_management/services/text_plan/text_plan_parser.dart
bool _isDayHeader(String trimmed) {
  final lower = trimmed.toLowerCase();
  return lower == 'day' ||
      lower.startsWith('day ') ||
      lower.startsWith('day\t');
}

bool _isSupersetMarker(String trimmed) {
  final lower = trimmed.toLowerCase();
  return lower == 'ss' ||
      lower.startsWith('ss ') ||
      ...
}
```

Seven `startsWith` calls. Replace with:

```dart
final _dayRe = RegExp(r'^day([ \t].*)?$', caseSensitive: false);
final _ssRe  = RegExp(r'^(ss|super-?set)([ \t:].*)?$', caseSensitive: false);
```

Faster, fewer surprises, easier to extend.

### Low 5.5 — `_columnOfToken` returns the *first* occurrence of `token` in `rawLine`

```477:480:lib/modules/program_management/services/text_plan/text_plan_parser.dart
int _columnOfToken(String rawLine, String token) {
  final idx = rawLine.indexOf(token);
  return idx >= 0 ? idx + 1 : 1;
}
```

If a line is `3x10 5kg 5kg` (user accidentally repeats), the column
returned for the *second* `5kg` is the index of the first. Track the
token's actual offset during tokenisation instead.

### Low 5.6 — `MeasurementTypeSelector` builds via two `_TypeChip`s manually

```24:46:lib/modules/program_management/widgets/measurement_type_selector.dart
return Row(
  children: [
    _TypeChip(label: 'Rep-based', ...),
    const SizedBox(width: AppSpacing.sm),
    _TypeChip(label: 'Time-based', ...),
  ],
);
```

When `MeasurementType` gains a third variant (e.g. distance-based),
this widget silently won't render it. `MeasurementType` is sealed, so
the right idiom is:

```dart
final variants = const [
  MeasurementType.repBased(),
  MeasurementType.timeBased(),
];
for (final v in variants)
  _TypeChip(label: _label(v), ...),
```

…and have the compiler complain if a new variant lacks a chip.

### Low 5.7 — `ExerciseEditorBloc._draftToPlannedValues` silent-fallback to zero

```461:482:lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart
Valid(:final value) => PlannedSetValues.repBased(...),
Invalid() => const PlannedSetValues.repBased(weightKg: 0, reps: 0),
```

The `Invalid()` branch silently writes `weightKg: 0, reps: 0` even
though `_onSavePressed` already gates on `validation.canSave`, which
in turn includes `areSetsValid`. So in practice the `Invalid` branch
is unreachable. Make that explicit:

```dart
Invalid() => throw StateError(
  'Invalid set values reached save path; canSave should have blocked this',
),
```

If the assertion fires in production, you've found a real bug. Today
the silent fallback masks it.

### Low 5.8 — `_findNewExerciseId` falls back to "last exercise of last group"

```574:597:lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart
String? _findNewExerciseId(WorkoutDay day) {
  ...
  for (final g in day.exerciseGroups) {
    for (final e in g.exercises) {
      if (!baselineExerciseIds.contains(e.id)) {
        return e.id;
      }
    }
  }
  if (day.exerciseGroups.isNotEmpty) {
    final lastGroup = day.exerciseGroups.last;
    if (lastGroup.exercises.isNotEmpty) {
      return lastGroup.exercises.last.id;
    }
  }
  return null;
}
```

The fallback branch is reached when the diff thinks no exercise is
new — meaning the navigation event fired spuriously and we're about
to navigate the user into "whatever was last in the day". Either the
caller already wouldn't have requested navigation, or the branch is a
bug. Worth either tightening (don't navigate) or documenting why this
is the desired behaviour.

### Low 5.9 — `_AddExerciseDialog` listens via `onChanged: (_) => setState(() {})`

```853:858:lib/modules/program_management/screens/workout_day_editor_screen.dart
TextField(
  controller: _nameController,
  autofocus: true,
  ...
  onChanged: (_) => setState(() {}),
  onSubmitted: (_) => _submit(),
  ...
)
```

`setState(() {})` is used purely to re-evaluate the disabled state of
the Confirm button (`onPressed: _nameController.text.trim().isEmpty ?
null : _submit`). This rebuilds the entire dialog on every keystroke
to update an enabled flag.

Cleaner: a `ValueListenableBuilder<TextEditingValue>` rebuilds only
the FilledButton:

```dart
ValueListenableBuilder<TextEditingValue>(
  valueListenable: _nameController,
  builder: (_, v, __) => FilledButton(
    onPressed: v.text.trim().isEmpty ? null : _submit,
    ...
  ),
),
```

### Low 5.10 — Constructors styled inconsistently

```42:46:lib/modules/workout_day_picker/bloc/workout_day_picker_event.dart
final class WorkoutDayPickerStartPressed extends WorkoutDayPickerEvent {
  const WorkoutDayPickerStartPressed(this.workoutDayId);

  final String workoutDayId;
  ...
}
```

Single-positional. But `WorkoutDayPickerResumePressed` uses named
required parameters. Most `program_management` events use named —
this is the picker module flagged in passing because
`program_management/widgets/program_list_tile.dart` interacts with
both. Pick one style; named is the project norm.

(Detailed in `workout_day_picker_review.md`.)

---

## 6. File-by-file notes (program_management)

### `program_management.dart`

Already covered in Medium 4.5. The `library;` directive without an
attached dartdoc comment is pointless in Dart 3. Either:

- Add a library-level doc: `/// Public entry point for ...` then
  `library;`.
- Or remove the directive and just keep the `export`s.

### `navigation/program_management_router.dart`

- Uses `switch (settings.name) { ... }` to dispatch — clean.
- Each route creates the bloc inline. `AggregateSaver` is *constructed
  inline* at each call site rather than provided. With three call
  sites that share `AggregateSaver(context.read<ProgramRepository>())`,
  this is OK; if a fourth appears, register it once via
  `RepositoryProvider`.
- `settings.arguments! as WorkoutDayArgs` is a bang-then-cast. If a
  caller dispatches the route with a typo'd payload, the cast throws
  at navigation time rather than at compile time. Acceptable for a
  Flutter `onGenerateRoute`, but consider matching with `is`:

  ```dart
  final args = settings.arguments;
  if (args is! WorkoutDayArgs) return null;   // 404
  ```

  That keeps the router from crashing on unknown payloads.

### `navigation/program_management_routes.dart`

- Holds path constants and argument classes. The args classes are
  not Freezed, unlike `WorkoutDayPickerArgs`. Inconsistent — see
  `workout_day_picker_review.md` Medium 4.x.
- `WorkoutDayArgs`/`ExerciseArgs`/`PlanPreviewArgs` are
  `class … { const constructor; final fields; }` with no
  `==`/`hashCode`. Currently they're only used as `Navigator.pushNamed`
  arguments, so identity-based equality is fine.

### `models/program_aggregate.dart`

One-line re-export — see Medium 4.6. Delete or expand.

### `models/program_editor_draft.dart`

- All five draft types use Freezed cleanly. `PlannedSetDraftValues`
  uses `unionKey: 'type'`, consistent with the domain.
- `ProgramDraft.toAggregate()` is the right place for the draft→domain
  conversion, but it directly creates `Uuid()` and `DateTime.now()` —
  see High 3.2.
- `WorkoutDayDraft.persistedId` is `String?` while `draftId` is
  `String`. Good.
- `ExerciseGroupDraft.kind()` derives from `exercises.length` — this
  is brittle if a future variant of `ExerciseGroupKind` is added. The
  function should be a `switch` over a sealed type, not a length
  check.

  In practice today the domain only has `single` / `superset`, and
  the implicit "≥2 ⇒ superset" rule is documented elsewhere. Worth a
  doc comment.

### `bloc/program_list/`

- `program_list_event.dart` and `program_list_state.dart` are minimal
  and read well.
- `ProgramListDeleteCancelled` carries a `programId` parameter that
  is never actually used by `_onDeleteCancelled`. Could be argument-less.
- `_loadPrograms` mutates the returned list — Medium 4.1.

### `bloc/program_editor/`

- Reasonably clean structure.
- `_baselineWorkoutDays` is `List<WorkoutDay>` stored as a private
  field. It's `unmodifiable` after each load, which is good — but the
  bloc's lifetime is tied to the navigation route, so the baseline
  survives across e.g. background/foreground cycles only as long as
  the screen lives.
- `_onWorkoutDayDeleteRequested`: the bloc stores a candidate id but
  the screen has to render the confirmation dialog itself by
  listening for state changes. Awkward dance — see also
  `ProgramListBloc` which does the *same* thing differently
  (the screen calls `ConfirmationDialog.show` directly from
  `_onDeleteRequested`, then dispatches Confirmed/Cancelled events).
  Pick one pattern.
- `_persistEdit` is 100+ lines — split into smaller helpers (compute
  diff, apply diff, reload).
- `_persistCreate` doesn't reload `_baselineWorkoutDays` from the
  new aggregate's groups (it only fetches `listWorkoutDaysForProgram`
  which returns header rows). Same potential mismatch as Medium 3.3.

### `bloc/workout_day_editor/`

- Largest bloc in the module. Already covered: Bug 2.1, Bug 2.3,
  High 3.1, High 3.2.
- `static const _uuid = Uuid();` is great — `Uuid()` is const.
  `program_editor_bloc.dart` uses `final _uuid = const Uuid();` for
  the same effect; consider standardising on `static const`.
- `_findNewExerciseId` — Low 5.8.
- The `_listEquals` helper — Low 5.3.

### `bloc/exercise_editor/`

- The largest event union in the module (18 events), but every event
  is appropriately granular (per-field changes).
- `_plannedRestInput` is a separate non-state field. The reason is
  that the user types `'18'` then `'180'` — we want the raw text
  preserved without forcing it through the draft (`plannedRestSeconds`
  is `int?`). This works, but it splits the source of truth: the bloc
  has authoritative draft state in two places (the draft + the
  free-floating `_plannedRestInput`). Consider extending the draft
  with a `plannedRestInput: String` field so all draft state lives in
  one Freezed type. That also fixes the "what about restoring the
  draft after process death" question.
- `_onSavePressed` recomputes validation, refuses to save if invalid
  — good.
- `_draftToPlannedValues` falls back silently to zero — Low 5.7.
- `_emptySet(pending)` reinitialises both `weightInput` and
  `repsInput` to empty strings on a measurement-type confirm. Good.
- `_pendingDialogShown` is a local field that prevents re-opening
  the confirmation dialog — but it's stored in `_ExerciseEditorScreenState`,
  not the bloc, so the truth lives in two places. Worth pulling into
  state (`pendingMeasurementChange` already exists; the screen could
  use that as its sole gate).

### `bloc/plan_import/`

- Tiny and clean: 3 events, 4 states, ~40-line bloc.
- `PlanImportState` is a sealed class that holds `text` in the base —
  nice.
- `PlanImportFailure.error` is a `PlanParseError` (Freezed), not a
  raw String. Good.

### `bloc/plan_preview/`

- Also small. `PlanPreviewSaved` and `PlanPreviewDiscarded` are
  terminal states — see Medium 4.8 about the rendering of these
  states.
- `_onOpened` constructs a fresh `Uuid()` and `AppClock()` inline
  rather than injecting them. Same observation as High 3.2.

### `screens/`

Covered widget-by-widget above. A few more notes:

- `program_list_screen.dart`: `_FailureView`/`_EmptyView` are inline
  private classes. Fine for now; if they grow, extract to widgets/.
- `plan_preview_screen.dart`: the warning grouping in
  `_buildPreviewBody` recomputes `warningsByExerciseId` on every
  build — push into state or memoise.
- `workout_day_editor_screen.dart` does this anti-pattern:

  ```dart
  final screenState = context
      .findAncestorStateOfType<_WorkoutDayEditorScreenState>();
  screenState?._navigateToExercise(id);
  ```

  Reaching across into the state ancestor is fragile (the private
  state class is brittle to renames; also there's no guarantee the
  ancestor still exists). Pass `_navigateToExercise` down through the
  tree as a callback instead.

### `services/`

- `aggregate_saver.dart` — already discussed.
- `domain_error_presenter.dart` — pure mapping with exhaustive
  `switch` on the sealed `DomainError`. Clean. As soon as
  the app needs i18n, this is the single seam to swap.
- `external_link_launcher.dart` — interface + sealed result. Good.
- `plan_draft_to_aggregate.dart` — accepts `Uuid` and `AppClock` as
  arguments. Use this as the model for High 3.2.
- `program_validation.dart` — see Medium 4.3 (string codes).
  Validation is duplicated between this file and
  `ProgramDraftValidation` / `WorkoutDayDraftValidation` /
  `ExerciseDraftValidation` (which live in the bloc state files).
  Consider folding the state-side validation into
  `ProgramValidation.*` and have the state-side wrappers be thin.
- `text_plan/text_plan_parser.dart` — see Low 5.1–5.5.
- `text_plan/plan_pretty_printer.dart` — symmetric to the parser
  but doesn't have its own round-trip property test in the test/
  folder I can see. Consider:

  ```
  property: forall draft. parse(print(draft)) ≈ draft
  ```

  …limited to the subset the printer covers (no notes/video etc.).
- `url_launcher_external_link_launcher.dart` — see Medium 4.11.

### `widgets/`

Generally clean. Specific notes:

- `confirmation_dialog.dart` — solid. The `show` static helper is
  the right API surface.
- `domain_error_banner.dart` — uses `withValues(alpha: ...)` rather
  than `withOpacity` (deprecated in Flutter 3.27+). Good.
- `measurement_type_selector.dart` — see Low 5.6.
- `plan_parse_error_banner.dart` — exhaustive switch on
  `PlanParseErrorCode`. Good.
- `plan_text_input.dart` — sets `maxLength: 100000` to mirror the
  parser; this is fine but creates a hidden coupling. Consider
  exposing `TextPlanParser.maxInputLength` as a public constant.
- `planned_set_row.dart` — see Medium 4.12.
- `program_list_tile.dart` — uses
  `_formatDate(DateTime date)` for an ISO-ish display. The
  `RelativeDateFormatter` in the picker module does this better and
  understands "today/yesterday"; consider promoting it to
  `core/` and reusing.
- `workout_day_list_tile.dart` — see Medium 4.7.

---

## 7. Cross-cutting suggestions

These would each touch multiple files; included separately.

1. **Add `bloc_test` coverage for `_persist` paths.** Especially the
   "save fails after partial mutation" case (Bug 2.1). A failing
   test that uses a fake `ProgramRepository` which throws on the 3rd
   call would force the transaction question.

2. **Adopt `bloc_concurrency` for event ordering.** `_onNameChanged`,
   `_onWorkoutDaysReordered`, etc. can interleave. Today the bloc
   processes events serially (the default `concurrent` transformer
   is OK with `on<E>` because each handler is awaited), but if a
   handler ever spawns parallel work the state becomes interleaved.
   Pin them with `transformer: sequential()` from `bloc_concurrency`
   to make the contract explicit.

3. **Promote `domain_error_presenter.dart` and `confirmation_dialog.dart`
   to `core/`.** Both are used (or would be used) by
   `workout_day_picker` and `workout_overview`. Right now
   `workout_day_picker_screen.dart` imports them from
   `package:zamaj/modules/program_management/services/`, which means
   `workout_day_picker` has a hidden dependency on `program_management`.

4. **Inject `Uuid` and `AppClock` via the composition root.** Today
   they're created inline in three different places
   (`program_editor_draft.dart`, `workout_day_editor_bloc.dart`,
   `plan_preview_bloc.dart`). Register both as `RepositoryProvider`
   in `app.dart`, then `context.read<Uuid>()`.

5. **Replace hand-rolled state `copyWith`s with Freezed sealed
   unions.** This eliminates the `T? Function()?` boilerplate (Medium
   4.2), the inconsistent `Equatable` props (Medium 4.10), and gives
   every state class a free `when`/`map` that's exhaustive at compile
   time. Freezed v3 supports sealed bloc state classes natively.

6. **Document the editor's "save on every change" UX intentionally.**
   Even with debouncing (High 3.1), the app's save model is "autosave"
   not "explicit save". This works, but it should be a documented
   product decision — right now it reads as accidental, and the
   `Save` button in `ExerciseEditorScreen` is the only place where
   the user explicitly saves, which contradicts the autosave model
   in the other editors.

---

## 8. Suggested order of fixes

1. **Bug 2.2** (the controller leak) — one-line fix, applies any
   user-facing impact reduction immediately.
2. **High 3.2** (`AppClock` injection) — small, makes everything
   downstream testable.
3. **Bug 2.3** (move-doesn't-delete) — requires repository support
   but should not wait. Even an interim "move" implementation in the
   repository that re-uses ids would unblock the bloc.
4. **Bug 2.1** (transaction wrapping) — paired with the persistence
   review's transaction primitive. Largest change, biggest payoff.
5. **High 3.1** (debouncing) — UX and I/O win.
6. **Medium 4.x and Low 5.x** — bundle into idiomatic cleanup PRs.
