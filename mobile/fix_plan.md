# Program Management — Fix Plan

Analysis of `lib/modules/program_management/` against `.kiro/specs/program-management/`
and `mvp-design-doc.md`. The screens exist but a handful of bugs and design choices
make the feature feel "half-working". This plan is ordered by impact.

---

## Pass 1 — Fix the data-loss and dead-end bugs

### 1.1 Exercise editor silently discards planned-set edits

**File:** `lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart`

`_onSavePressed` builds the updated `Exercise` with `sets: exercise.sets`
(the baseline loaded from DB), not `current.draft.sets`. Every weight / reps /
duration edit, plus set adds / deletes / reorders, is thrown on the floor.

**Fix:**

- Build `List<WorkoutSet>` from `current.draft.sets`, mapping
  `PlannedSetDraftValues` → `PlannedSetValues` via `ProgramValidation.validateRepBasedSet`
  / `validateTimeBasedSet`.
- Preserve `persistedId` where present, generate a fresh UUID otherwise.
- Assign `position` by list index.
- Use `measurementType` from the draft (not from the stale baseline) so the
  `set_measurement_type_mismatch` invariant on `Exercise._()` holds after a
  measurement-type switch.
- Pass `createdAt` / `updatedAt` / `schemaVersion` through from the baseline
  exercise for existing sets; for new sets use the same timestamps as the
  parent exercise (the repository will rewrite `updatedAt` anyway).

### 1.2 Exercise editor has no min-set validation

**File:** `lib/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart`

`ExerciseDraftValidation` does not check that `sets.length >= 1`, so the Save
button is active with zero sets. `R5 AC8` requires `[1, 20]`.

**Fix:** add `isSetCountValid` to `ExerciseDraftValidation.compute` and include
it in `canSave`. Also validate each set's values parse correctly (otherwise
`ProgramDraft.toAggregate()` currently coerces invalid text to `0`).

### 1.3 Exercise editor planned-rest message is wrong

**File:** `lib/modules/program_management/screens/exercise_editor_screen.dart`

Message reads `'Enter a valid rest duration (0–600 seconds)'` but validator
allows `0..3600` (one hour, as per R6 AC2). Update to `'0–3600 seconds'`.

### 1.4 Exercise editor walks the entire DB to find one exercise

**Files:**
- `lib/modules/domain/repositories/program_repository.dart`
- `lib/modules/persistence/repositories/drift_program_repository.dart`
- `lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart`

`ExerciseEditorBloc._findExercise` calls `listPrograms()`, then for each
program `listWorkoutDaysForProgram()`, then walks every group and every
exercise. Runs on open and again on save. Noticeable pause scales linearly
with total exercise count across all programs.

**Fix:**

- Add `Future<Exercise?> getExercise(String exerciseId)` to `ProgramRepository`.
- Implement in `DriftProgramRepository` as a single query on the `Exercises`
  table joined with `WorkoutSets` (reuse the existing exercise mapper).
- Replace `_findExercise` calls with `programRepository.getExercise(id)`.

### 1.5 Workout-day name, group reorders, and exercise reorders are never saved

**Files:**
- `lib/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart`
- `lib/modules/program_management/screens/workout_day_editor_screen.dart`

`WorkoutDaySavePressed` is defined and handled in the bloc but is never
dispatched from any UI. The only save path is the per-group save icon, which
skips the day name, group ordering, and cross-group moves.

Per-group save also hardcodes `DateTime.now().toUtc()` and `schemaVersion: 1`
on `Exercise` and `ExerciseGroup`, bypassing `SchemaVersions.domain` and the
repository's timestamp ownership.

**Fix:**

- Add a single top-level **Save** action in the `WorkoutDayEditorScreen` app
  bar (mirroring `ProgramEditorScreen`).
- Replace the per-group save icon with a dirty-indicator dot (the save is
  now a day-level action).
- Rewrite `_onDaySave` to diff the draft against the baseline and issue the
  minimum set of repository calls:
  - `updateWorkoutDay` if the name changed;
  - `reorderExerciseGroups` if order changed;
  - `createExerciseGroup` / `updateExerciseGroup` / `deleteExerciseGroup`
    per group;
  - inside each group, `createExercise` / `updateExercise` / `deleteExercise`
    and `reorderExercises` as needed.
- Remove the per-group save handler (`GroupSavePressed`) and
  `WorkoutDayEditorGroupValidationError` becomes an on-save result surfaced
  at the card the violation occurred on.
- On save success, emit a fresh `WorkoutDayEditorEditing` with the reloaded
  day as the new baseline (do not pop — see 1.7).

Alternative considered: build a "workout-day aggregate save" on the
repository akin to `saveProgramAggregate`. Rejected for now because it
duplicates domain surface area; the diff approach reuses existing methods
and mirrors `ProgramEditorBloc._saveEdit`.

### 1.6 Tapping a newly-added day / exercise is a no-op

**Files:**
- `lib/modules/program_management/screens/program_editor_screen.dart`
- `lib/modules/program_management/screens/workout_day_editor_screen.dart`

Both screens guard navigation with `persistedId != null ? navigate : () {}`.
Users hit a dead tap with no feedback.

**Fix:** show a `SnackBar` telling the user to save first, and focus the
Save action. (Auto-save was considered and rejected — it conflicts with the
explicit save model the spec uses and would surprise users mid-edit.)

### 1.7 Program editor pops to the list on every save

**File:** `lib/modules/program_management/bloc/program_editor/program_editor_bloc.dart`

`_saveEdit` emits `ProgramEditorSaved`, the screen pops, and the user has to
reopen to continue editing. Add a day, save, and you've lost your place.

**Fix:**

- In create mode, keep the current behavior: save, emit `Saved`, pop.
- In edit mode, after a successful save reload the program + its workout
  days and emit a fresh `ProgramEditorEditing` with the new baseline.
  `lastSaveError` clears, `deletionCandidateDraftId` clears.
- Screen listener only pops on `Saved` (create mode) or on manual back.

---

## Pass 2 — UX polish

### 2.1 Remove hardcoded `AppColors.dark` usages

**Files:**
- `lib/modules/program_management/screens/workout_day_editor_screen.dart`
- `lib/modules/program_management/widgets/exercise_group_card.dart`
- `lib/modules/program_management/widgets/exercise_tile.dart`

These use `const colors = AppColors.dark;` which bypasses the theme and
breaks any future light/dark switch. Replace with
`final colors = Theme.of(context).appColors;` as the rest of the module
already does.

### 2.2 Program list: consolidate the two floating action buttons

**File:** `lib/modules/program_management/screens/program_list_screen.dart`

Stacked FABs with an Import button below the primary FAB is non-standard on
both Material 3 and iOS conventions and crowds the bottom-right.

**Fix:** keep the primary `FloatingActionButton.extended` for "New program".
Move "Import from text" to the `AppBar.actions` as an icon button with a
tooltip. The empty-state retains both CTAs (unchanged).

### 2.3 Remove dead `SessionRepository` dependency

**File:** `lib/modules/program_management/bloc/program_list/program_list_bloc.dart`

`_sessionRepository` is held with `// ignore: unused_field`. Either:

- Use it to warn on delete if the program has dependent sessions
  (matches the spec's historical-immutability mention), or
- Remove it to keep the BLoC surface honest.

Recommendation: **remove for now**, wire it back when the session module
lands. Update `ProgramManagementRouter.onGenerateRoute` accordingly.

### 2.4 Drop the `WorkoutDaySavePressed` event that goes nowhere

After 1.5 the new day-level save dispatches a single explicit event (rename
to `WorkoutDaySaveRequested` if keeping). Remove `GroupSavePressed` from
`workout_day_editor_event.dart` once the per-group icon is gone.

### 2.5 Draft id regeneration on reload

**File:** `workout_day_editor_bloc.dart::_draftFromWorkoutDay`

Every reload creates fresh `_uuid.v4()` draftIds, which invalidates widget
keys across state emissions. For `ReorderableListView` this means drag
handles can jump mid-gesture. Use the `persistedId` as the `draftId` when
one exists so keys stay stable across reloads.

---

## Pass 3 — Bigger design gap (optional, confirm before starting)

### 3.1 `PlanPreviewScreen` is read-only but R9 AC1 requires editing

**File:** `lib/modules/program_management/screens/plan_preview_screen.dart`

The spec (R9 AC1) requires the preview to render `"every field of the
Plan_Draft in the same structured form as the Program_Editor_Screen"` so
users can touch up parse mistakes before committing. Current implementation
shows only name / measurement label / set count and offers Save or Discard.

**Fix sketch:**

- Reuse `ProgramEditorScreen`'s workout-day list + the
  `WorkoutDayEditorScreen`'s group cards + `ExerciseEditorScreen`'s set
  rows as embedded editors against the `PlanPreviewBloc`'s `ProgramDraft`.
- Add `PlanPreviewBloc` events that mirror the program / workout-day /
  exercise draft-mutation events and apply them to the in-memory draft.
- Keep save / discard at the screen level; delegate the actual save to
  `AggregateSaver` (already wired).

This is a substantial refactor. Suggest extracting the shared editing
widgets into `widgets/editors/` so both screens can consume them.

---

## Verification after each pass

Run the full CI sequence from `tool/ci.sh` after every pass:

```bash
bash tool/check_offline_imports.sh
dart run build_runner build --force-jit
flutter analyze
flutter test
```

Expected: zero analyzer issues across `lib/modules/program_management/`,
all existing domain / persistence / repository / serialization tests stay
green. The module has no BLoC / widget / screen tests per the steering
rules, so green flutter analyze plus manual verification on a device are
the acceptance criteria for the screen-level fixes.
