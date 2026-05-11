# Program Management — UX Redesign Plan

Follow-up to `fix_plan.md` after Pass 1 + Pass 2 shipped. The feature now
persists correctly, but the in-session authoring flow still carries too much
chrome, too many taps, and a few broken affordances. This plan reshapes the
Workout Day editor and the Exercise editor around a single principle:

> Mutations are local, cheap, and immediately persistent. The UI shows the
> result, not the plumbing.

---

## What the user asked for

1. **Flat single exercises.** A group with one exercise should render as one
   row, not a whole card with "Single" chip, banner, outline, and
   "+ Add exercise" footer link eating half the screen.
2. **Add Exercise modal defaults.** Rep-based should be the preselected type
   and the `Add` button should enable as soon as a name is typed — no need to
   tap the already-selected chip to force a rebuild.
3. **After Add, drop straight into Exercise Editor.** No second tap, no
   intermediate save.
4. **Fresh exercise opens with one empty planned set + a duplicate button.**
5. **No Save button on Workout Day editor.** Every change auto-saves.
6. **Drag-drop to build a superset.** Drop exercise A onto exercise B and the
   two merge into a superset; the result renders as a grouped card.

## What I'd add on top (bad flows spotted during review)

7. **"Add group" vs "Add exercise" distinction is an artifact.** Users think
   in exercises; groups are a storage concept. Replace the `+` action with
   "Add Exercise" that creates a new single-exercise group + an exercise at
   the end of the day in one gesture.
8. **Empty groups are unreachable in steady state once 1–6 land.** Delete
   them eagerly instead of surfacing a cardinality error banner.
9. **Superset collapse.** Removing all but one exercise from a superset
   should smoothly become a flat single again (falls out of the derived
   `kind()` but needs to re-render without the card chrome).
10. **Stop seeding measurement type in the Add dialog.** The user picks type
    inside the Exercise Editor, where the confirmation-on-change flow lives.
    Fresh exercises default to rep-based. The type toggle in the Add dialog
    is redundant UI and a second place to get type wrong.
11. **Workout Day screen refreshes on return from Exercise Editor.** The set
    count / type label on the flat tile needs to reflect whatever the user
    just edited.

---

## Design principles driving the passes

- **One source of truth per screen.** Workout Day editor persists groups +
  exercise-level metadata. Exercise Editor persists sets + planned rest +
  video URL + notes. No cross-writes.
- **Derived group kind.** Never ask the user to pick "Single" vs "Superset".
  Drag things together to get a superset; pull the last-but-one out to get a
  single.
- **Auto-save everywhere mutations are cheap.** The Workout Day editor
  mutations (rename, reorder, delete, merge) all run through the existing
  `_persist` diff; wire that to fire after every event instead of only on
  `WorkoutDaySavePressed`. The Exercise Editor keeps an explicit `Save` — its
  edits are value-heavy and the user benefits from an explicit commit.
- **Side-effect states for navigation.** Use transient bloc states (emit and
  immediately follow with the next `Editing` state) for "a new exercise was
  just created, go navigate". Keeps events-in / states-out clean.
- **Historical immutability is non-negotiable.** All of this still goes
  through `ProgramRepository`; snapshots inside sessions stay untouched
  (spec R11).

---

## Pass 1 — Small, independent fixes

Land first. Each of these is one-file-ish and unlocks the bigger passes.

### 1.1 Fix the Add Exercise dialog

**File:** `lib/modules/program_management/screens/workout_day_editor_screen.dart`
(inside `_AddExerciseDialog`)

- Add `onChanged: (_) => setState(() {})` to the name `TextField` so the
  `Add` button enables in real time as the user types.
- Add `onSubmitted: (_) => _submit(...)` so pressing Enter confirms when the
  name is non-empty.
- Remove the measurement-type toggle from the dialog entirely. The Exercise
  Editor already handles measurement-type selection with a confirmation
  prompt and is the correct home for it (spec R5 AC5–AC7).
- `ExerciseAddedToGroup` event will hard-code `measurementType:
  MeasurementType.repBased()` for new exercises (rep-based is the MVP
  default per the product brief).

Downstream: delete the now-unused `_MeasurementTypeToggle` and `_TypeChip`
classes in this file (they are a duplicate of
`widgets/measurement_type_selector.dart` anyway).

### 1.2 Auto-seed one planned set on empty Exercise load

**File:** `lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart`
(inside `_onOpened`)

- After converting the loaded `Exercise` to an `ExerciseDraft`, if
  `draft.sets.isEmpty`, replace with `[PlannedSetDraft(draftId: uuid,
  persistedId: null, values: _zeroValuedSet(draft.measurementType))]`.
- Spec R5 AC8 mandates ≥1 planned set per exercise; this enforces the floor
  while giving the user something to type into immediately.

### 1.3 Duplicate button on planned sets

**Files:**
- `lib/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart`
- `lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart`
- `lib/modules/program_management/widgets/planned_set_row.dart`
- `lib/modules/program_management/screens/exercise_editor_screen.dart`

- New event: `PlannedSetDuplicated({required String setDraftId})`.
- Handler copies the set's current `values` (including whatever the user has
  typed), mints a fresh `draftId`, clears `persistedId`, and inserts the
  copy directly after the source in `draft.sets`. Honor the 20-set cap from
  spec R5 AC8 — no-op when the list is already at 20.
- `PlannedSetRow` gains an `onDuplicate` VoidCallback and renders a
  content-copy icon button ( `Icons.content_copy_outlined` ) alongside the
  delete icon. Style consistent with the existing delete button
  (`colors.onSurfaceMuted`, 20px, same constraints).
- `exercise_editor_screen.dart` passes the callback through:
  `onDuplicate: () => bloc.add(PlannedSetDuplicated(setDraftId: ...))`.

### 1.4 Exercise Editor refreshes the Workout Day on pop

**File:** `lib/modules/program_management/screens/workout_day_editor_screen.dart`

- Change the `Navigator.of(context).pushNamed(...)` call for the exercise
  route to `await` and then dispatch a new `WorkoutDayEditorRefreshed` event.
- See 2.2 below for the bloc event; if Pass 2 ships first, this item becomes
  trivial.

---

## Pass 2 — Auto-save Workout Day editor

This is the main structural change. Land Pass 1 first.

### 2.1 Retire the Save button and `WorkoutDaySavePressed` event

**Files:**
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart`
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_state.dart`
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart`
- `lib/modules/program_management/screens/workout_day_editor_screen.dart`

- Drop `WorkoutDaySavePressed` event and its handler (`_onDaySave` stays,
  but becomes a private `_persist(emit)` method).
- Every mutation handler (`_onNameChanged`, `_onGroupAdded`,
  `_onGroupDeleted`, `_onGroupsReordered`, `_onExerciseAdded`,
  `_onExerciseRemoved`, `_onExerciseReordered`, plus the new drag/duplicate
  events from later passes) calls `_persist(emit)` as its final line.
- `_persist(emit)` encapsulates the current diff+save logic from the old
  `_onDaySave`. Replace the `WorkoutDayEditorSaving` state emission with a
  flag on `WorkoutDayEditorEditing`: `bool isSaving`. The UI shows a small
  "Saving…" / "Saved" indicator in the app bar (no modal overlay).
- Drop `WorkoutDayEditorGroupValidationError` state. With 2.4's eager
  empty-group cleanup and implicit group kind, that state is unreachable in
  user-driven flows. Keep the handler in `on ValidationError` but surface
  via `lastSaveError` on `Editing` if the domain ever throws.

### 2.2 Add `WorkoutDayEditorRefreshed` event

**Files:** same as 2.1.

- `WorkoutDayEditorRefreshed` reloads the workout day via
  `programRepository.getWorkoutDay(persistedId)`, rebuilds the baseline, and
  emits a fresh `WorkoutDayEditorEditing`. Used when returning from the
  Exercise Editor so that the flat tile's measurement-type label and set
  counts stay accurate.
- Dispatched from
  `Navigator.of(context).pushNamed(...).then((_) => bloc.add(const WorkoutDayEditorRefreshed()));`
  at every point the screen navigates to the Exercise Editor.

### 2.3 Side-effect state for "just-created exercise, go navigate"

**Files:** event + state + bloc + screen.

- New state: `WorkoutDayEditorExerciseCreated({required WorkoutDayDraft draft,
  required String exerciseId})`.
- In `_onExerciseAdded` (and the new top-level `QuickExerciseAdded` from 3.1
  below), after `_persist(emit)` completes and the baseline reload has
  produced a persisted id for the new exercise, emit
  `WorkoutDayEditorExerciseCreated(...)` then immediately emit the normal
  `WorkoutDayEditorEditing`.
- Screen's `BlocListener` handles `WorkoutDayEditorExerciseCreated` by
  pushing the Exercise Editor route with `ExerciseArgs(exerciseId: ...)` and
  chaining `.then((_) => bloc.add(const WorkoutDayEditorRefreshed()))`.
- Navigation-from-state is a transient side effect. We never leave the
  screen on that state; the listener fires the push and the bloc has already
  moved on to `Editing`.

### 2.4 Delete empty groups eagerly

**File:** `workout_day_editor_bloc.dart`.

- After every mutation handler's local draft update, run a cleanup pass:
  `groups = groups.where((g) => g.exercises.isNotEmpty).toList()`.
- The `empty_group` invariant check in `_cardinalityInvariant` goes away
  alongside `WorkoutDayEditorGroupValidationError`. Group kind is derived
  from `exercises.length` so 1 → single, ≥2 → superset is always valid by
  construction.

---

## Pass 3 — Workout Day editor rendering: flat singles + drag-to-superset

### 3.1 Replace the top-right `+` with "Add Exercise"

**Files:**
- `lib/modules/program_management/screens/workout_day_editor_screen.dart`
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart`
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart`

- App bar action becomes a single `IconButton(Icons.add,
  tooltip: 'Add exercise')` that opens the (simplified) `_AddExerciseDialog`.
- On `Add` in the dialog, dispatch a new top-level event
  `QuickExerciseAdded({required String name})`. The bloc:
  1. Creates a new `ExerciseGroupDraft` containing one `ExerciseDraft` with
     the given name, rep-based measurement, no sets, no rest, no metadata.
  2. Appends the new group at the end of `draft.groups`.
  3. Calls `_persist(emit)`.
  4. Reads the reloaded baseline, finds the freshly-created exercise id
     (the last exercise in the last group, matched by name + no prior
     persisted id), emits `WorkoutDayEditorExerciseCreated`.
- Drop `ExerciseGroupAdded` event. Groups-without-exercises is a concept the
  new UX no longer exposes.
- The in-card `+ Add exercise` link stays on superset cards (see 3.3) and
  dispatches the existing `ExerciseAddedToGroup(groupDraftId: ..., name: ...,
  measurementType: repBased())` path, with the same "created → navigate"
  side-effect chain.

### 3.2 Render single-exercise groups flat

**Files:**
- `lib/modules/program_management/widgets/exercise_group_card.dart`
  (refactor scope)
- `lib/modules/program_management/screens/workout_day_editor_screen.dart`

Replace `ExerciseGroupCard` with two renderers keyed off
`group.exercises.length`:

- **Flat single** (exactly one exercise): render an `ExerciseTile`
  directly as a reorderable item in the outer `ReorderableListView`. The
  tile already has a drag handle + delete. No outer card, no "Single" chip,
  no banner. Row becomes ~48dp tall.
- **Superset card** (≥2 exercises): keep the card chrome, rename the label
  pill to "Superset" (drop the "Single" variant). The card has its own
  group-level drag handle (for reordering the group against other groups)
  and an inner `ReorderableListView.builder` + `+ Add exercise` footer.

Structural detail: the outer `ReorderableListView` in `_GroupList` already
keys items on `group.draftId`; that stays. What changes is the `itemBuilder`:

```dart
itemBuilder: (context, index) {
  final group = draft.groups[index];
  return group.exercises.length == 1
      ? _FlatExerciseGroupRow(key: ValueKey(group.draftId), group: group, reorderIndex: index, ...)
      : _SupersetGroupCard(key: ValueKey(group.draftId), group: group, reorderIndex: index, ...);
},
```

`_FlatExerciseGroupRow` wraps an `ExerciseTile` and exposes the outer-list
drag handle via `ReorderableDragStartListener(index: reorderIndex!)`. The
tile's own drag handle (used for reordering within a superset) is hidden in
the flat case.

`_SupersetGroupCard` is essentially today's `ExerciseGroupCard` minus the
per-kind label logic, minus the cardinality error banner (2.4 made it
unreachable), and plus the drag+drop target hooks from 3.3.

Delete `_CardinalityErrorBanner`.

### 3.3 Drag an exercise onto another exercise → superset

**Files:**
- `lib/modules/program_management/widgets/exercise_tile.dart`
- `lib/modules/program_management/screens/workout_day_editor_screen.dart`
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart`
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart`

- New payload type (private to the screen):
  `class _ExerciseDragPayload { final String groupDraftId; final String
  exerciseDraftId; }`.
- Wrap each `ExerciseTile` with both a
  `LongPressDraggable<_ExerciseDragPayload>` and a
  `DragTarget<_ExerciseDragPayload>`. The `LongPressDraggable` uses a
  `feedback` widget that renders the tile with elevation + shadow;
  `childWhenDragging` dims the original.
  - We use `LongPressDraggable` (not `Draggable`) so normal taps still open
    the Exercise Editor and short drags on the existing drag handle still
    drive the `ReorderableListView`.
- `DragTarget.onWillAcceptWithDetails` accepts if the source and target
  exercise ids differ.
- `DragTarget.onAcceptWithDetails` dispatches new event:
  `ExerciseDraggedOntoExercise({required String sourceGroupDraftId,
  required String sourceExerciseDraftId, required String targetGroupDraftId,
  required String targetExerciseDraftId})`.
- Bloc handler:
  1. If source and target groups are the same: no-op (ordering within a
     group is already handled by the ReorderableListView). Alternatively,
     treat a drop as "move the source to immediately after the target"; keep
     this as an enhancement if the reorderable list makes it awkward.
  2. Otherwise, remove the source exercise from its group. If the source
     group is now empty, drop it (Pass 2.4 cleanup). Insert the source
     exercise into the target group immediately after the target exercise.
  3. Call `_persist(emit)`.
- The merged group naturally has ≥2 exercises and renders as a
  `_SupersetGroupCard` on the next build (3.2).

Optional polish: while a `LongPressDraggable` is active, render a subtle
highlight ring around valid drop targets and a "Combine into superset" hint
near the cursor. Not required for the MVP behavior.

### 3.4 Remove the hardcoded `AppColors.dark` from the superset card

Already tracked in Pass 2.1 of `fix_plan.md`. Ensure the rewritten
`_SupersetGroupCard` uses `Theme.of(context).appColors` — no regressions.

---

## Pass 4 — Exercise Editor polish tied to the new add flow

### 4.1 Exercise Editor opens focused on the name field

**File:** `lib/modules/program_management/screens/exercise_editor_screen.dart`

- When the editor opens for a freshly-created exercise (detectable by
  `ExerciseEditorBloc` loading an exercise whose name equals the default
  "Unnamed exercise" or by passing an `autoFocusName: true` arg through
  `ExerciseArgs`), autofocus the name TextField and select its contents so
  the user can type the real name without tapping.
- Lowest-friction variant: always autofocus the name field on open and
  select-all; users editing an existing exercise can just dismiss the
  keyboard. Flag as a minor UX choice, default to "always autofocus".

### 4.2 Exercise Editor save confirmation is silent

Today the editor pops on save. Keep that. After the pop, the Workout Day
editor receives the `.then(...)` callback from 2.2 and refreshes. The user
sees the flat tile update in place — no "Saved" snackbar needed on either
screen; the fact that the editor closed is the confirmation.

If a save fails, the existing `lastSaveError` path already keeps the editor
on screen with the domain error banner. Unchanged.

---

## Resolved design decisions

1. **Drop = merge.** Dragging a single-exercise tile onto another exercise
   always merges them into a superset. Reordering at the group level uses
   the explicit drag handle.
2. **Drag within a superset = reorder.** The inner `ReorderableListView`
   handles reordering exercises within a superset card via its drag handles.
3. **Autofocus on Exercise Editor open: always.** Select-all the name field
   so the user can immediately type.
4. **Superset names are out of scope.** The card label is the static
   "Superset" pill. No user-named groups until a future spec change.

---

## Verification after each pass

Run the full CI sequence from `tool/ci.sh`:

```bash
bash tool/check_offline_imports.sh
dart run build_runner build --force-jit
flutter analyze
flutter test
```

Expected: zero analyzer issues across `lib/modules/program_management/`,
all domain / persistence / repository / serialization tests stay green. No
BLoC / widget / screen tests are added per steering rules; manual
verification on a device is the acceptance criterion for the screen-level
changes.

Manual checks per pass:

- **Pass 1:** Open Add Exercise dialog, type a name → `Add` enables
  immediately. Press Enter → dialog closes, exercise appears. Open the new
  exercise → Exercise Editor shows one empty planned set with a duplicate
  button. Tap duplicate → identical second set appears.
- **Pass 2:** Rename the day → return to program → reopen → name persists.
  Delete a group → reopen → stays deleted. No Save button anywhere. Small
  "Saving…" indicator briefly appears on each mutation.
- **Pass 3:** Create a single exercise → it renders as a flat row, ~48dp
  tall, no card. Long-press and drag it onto another single exercise → both
  collapse into a superset card. Remove all but one exercise from the
  superset → card collapses back to a flat row.
- **Pass 4:** Tap the `+` action → Exercise Editor opens autofocused on
  name, ready for typing. Save → back on Workout Day editor, the new tile
  shows the final name and set count.

---

## Pass 5 — Program Editor auto-save

The Program Editor currently requires an explicit Save button. Same treatment
as the Workout Day editor: auto-save every mutation.

### 5.1 Retire `ProgramEditorSavePressed` and the Save button

**Files:**
- `lib/modules/program_management/bloc/program_editor/program_editor_bloc.dart`
- `lib/modules/program_management/bloc/program_editor/program_editor_event.dart`
- `lib/modules/program_management/bloc/program_editor/program_editor_state.dart`
- `lib/modules/program_management/screens/program_editor_screen.dart`

- Drop `ProgramEditorSavePressed` event.
- Extract the current `_saveEdit` logic into a private `_persist(emit)`
  method.
- In **create mode**, the first mutation that produces a valid name (trimmed
  length 1–120) triggers `_persist(emit)` which calls
  `_aggregateSaver.save(draft)`. After the first successful save, the bloc
  transitions to edit mode (sets `isCreateMode: false`, stores the returned
  `programId` on the draft, reloads baseline). Subsequent mutations use the
  edit-mode diff path.
- In **edit mode**, every mutation handler (`_onNameChanged`,
  `_onWorkoutDayAdded`, `_onWorkoutDayRenamed`,
  `_onWorkoutDayDeleteConfirmed`, `_onWorkoutDaysReordered`) calls
  `_persist(emit)` as its final line.
- Add `bool isSaving` flag to `ProgramEditorEditing` state. The UI shows a
  small "Saving…" / "Saved ✓" indicator in the app bar instead of a Save
  button.
- Drop `ProgramEditorSaving` state (replaced by the flag).
- `ProgramEditorSaved` state is no longer needed (the screen never pops on
  save; the user navigates back manually).

### 5.2 Delete workout day auto-saves after confirmation

Already handled by 5.1: `_onWorkoutDayDeleteConfirmed` calls `_persist(emit)`
which diffs the draft against the baseline and issues the
`deleteWorkoutDay(id)` call. The confirmation dialog stays (spec R3 AC7–AC9).

### 5.3 Add workout day auto-saves immediately

`_onWorkoutDayAdded` appends the new day to the draft and calls
`_persist(emit)`. The diff detects a new day with `persistedId == null` and
calls `createWorkoutDay(programId: ..., name: ...)`. After reload, the day
has a `persistedId` and is tappable immediately — no more "Save the program
before editing this day" snackbar.

### 5.4 Remove the "save first" snackbar guard

**File:** `lib/modules/program_management/screens/program_editor_screen.dart`

- The `onTap` for each `WorkoutDayListTile` no longer checks
  `day.persistedId != null`. Since every mutation auto-saves, the persisted
  id is always available by the time the user can tap the tile.
- Remove the snackbar fallback.

---

## Deferred / out of scope

- Inline editing of the superset's position label (names for supersets).
- Drag-to-reorder between arbitrary scroll positions with velocity-scroll;
  `ReorderableListView` handles reorders, `LongPressDraggable` handles
  merges, and we accept that reordering a single onto a position deep in
  another group requires two gestures (drag-to-merge, then drag within the
  group).
- `PlanPreviewScreen` full editing (tracked in `fix_plan.md` Pass 3 / Spec
  R9 AC1). Unrelated to this redesign.
