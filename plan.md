# Program Editor — UX improvement plan

Target screen: [program_editor_screen.dart](mobile/lib/modules/program_management/screens/program_editor_screen.dart)
Related tile: [workout_day_list_tile.dart](mobile/lib/modules/program_management/widgets/workout_day_list_tile.dart)
Related bloc: [program_editor_bloc.dart](mobile/lib/modules/program_management/bloc/program_editor/program_editor_bloc.dart)

This screen sits **outside the gym** (program authoring), so the sweaty-hands rules from [CLAUDE.md](CLAUDE.md) do **not** apply — standard `AppSpacing.touchMin` (48 dp) is the floor. The job to be done is *plan curation*: name a program, lay out the days, drill into each day to assemble exercises.

---

## 1. Current state (what's there today)

- **AppBar** — inline `TextField` for program name (no visible edit affordance); save spinner in actions.
- **Body** — `ReorderableListView` of `WorkoutDayListTile`s. Each tile shows:
  - Day name (single line)
  - Drag handle (right edge, decorative — the whole tile is the drag target via long-press)
  - Swipe-end-to-start → confirmation dialog → delete
  - Tap → workout-day editor (only if `persistedId != null`; otherwise no-op while save is pending)
- **FAB** — `+` opens an `AlertDialog` with a single TextField to name a new day.
- **Empty state** — outlined fitness icon + "No workout days yet" + "Tap + to add a workout day".
- **Bloc** loads bare `WorkoutDay` rows (`groups: []`). It does **not** load the exercises inside each day, so no derived data (exercise count, planned-set summary, "incomplete" status) is currently available to the screen.

---

## 2. Pain points

Ordered by how often a user actually feels them.

1. **Tile carries one fact (name)** — no exercise count, no muscle/focus hint, no "this day has no exercises yet" signal. The user has to drill in to remember what each day contains. Compare to [day_tile.dart](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart) which shows day name + exercise count + history labels.
2. **Day creation is a modal dialog** — interrupts flow, requires precise tapping in a small textfield, no path to "duplicate Day A as Day B" (the single most common authoring move). The dialog has a single field and one purpose.
3. **No undo on delete** — confirmation dialog is the only safety net. A swipe is a fat-finger-friendly gesture; combining it with a destructive confirmation means *every* mis-swipe costs a tap, and a confirmed mistake costs the whole day's exercises with no recovery.
4. **No duplicate** — no way to "copy this day" (e.g., Push A → Push B starting point). Forces full re-authoring of overlapping days.
5. **Drag affordance is weak** — drag handle icon is just decoration; reorder works on long-press anywhere, but nothing teaches that. The handle is right-edge so left-handed thumbs cross the tile.
6. **Program name field has no edit affordance** — unlike the workout-day editor which shows a faint pencil icon when unfocused ([workout_day_editor_screen.dart:357](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L357)), this screen has no hint the AppBar title is editable.
7. **Rename is "go to detail screen"** — the only way to rename a day is to drill into the workout-day editor. Inline rename is missing despite the rest of the editor (workout-day-level, exercise-level) supporting it.
8. **No quick "preview" of a day** — to check whether Day 3 already has the squats you want, you must navigate in and back out.
9. **Confirmation dialog underweights the cost** — `"Delete \"Push A\"? This cannot be undone."` doesn't tell you that you'd be wiping N exercises and M supersets.
10. **Empty state is passive** — icon + sentence + "tap +". Doesn't pull the user into their first action with a primary button. Compare workout-day editor's empty state which has a `FilledButton.icon` `Add exercise`.
11. **No program-level metadata** — total days, total planned exercises, last edited — nothing to anchor the user.
12. **`persistedId == null` tile is silently inert** — newly added days have a brief window where tapping does nothing (no toast, no shimmer, no disabled style). Confusing if save is slow.
13. **AlertDialog focus + keyboard** — when the keyboard pops up, the dialog often gets pushed off-center; on small phones the action buttons sit under the keyboard.

---

## 3. UI/UX principles applied

For *list editor* screens that aren't in the in-session hot path:

1. **Information density beats minimalism** when each row represents a real, complex artifact. A bare name forces drill-in; one or two derived facts cut navigation in half.
2. **Direct manipulation > modes** — inline rename, drag-anywhere-to-reorder, swipe-to-delete with undo. Dialogs only for *create new* or *truly destructive on heavy artifacts*.
3. **Optimistic actions with reversal** beat preemptive confirmation, except for actions whose blast radius is large and discovery rate is low. For a single workout day, undo-snackbar is the right default; for "delete program containing 12 days" (handled elsewhere) a hard confirm is fine.
4. **Progressive disclosure** — show enough on the tile that the user can decide whether to drill in; expand-in-place when more is wanted; full screen only when editing.
5. **Surface the cost of destructive actions in their copy** — "Delete Push A (8 exercises, 1 superset)?" puts the weight in the title where eyes actually land.
6. **Empty states are first-use UI** — they should advertise the primary action with a real button, and ideally suggest a shortcut (template, paste-import).
7. **Multiple paths to the same outcome** — FAB for new, sheet for "duplicate / new / from text", inline button in empty state. Don't force everything through one entry point.
8. **Affordance > documentation** — visible drag handle that's actually a `ReorderableDragStartListener`, visible edit pencil on inline name fields. Stop relying on snackbar coach-marks.
9. **Mirror neighbor screens** — the workout-day picker's `DayTile` is the read-side of the same artifact. The editor's tile should be visually familiar (same card shape, same kind of badge slots) so users build one mental model.

---

## 4. Proposed improvements

Grouped by **impact × effort**, not by visual order on the screen.

### P0 — high impact, low–medium effort  ✅ shipped

**P0-1. Richer day tile: name + derived facts + warning state.** ✅
Add to each tile:
- Exercise count (`8 exercises`) — primary subtitle.
- "Empty" badge or muted style when the day has zero exercises (a *plan-completeness* signal — bare days are usually unfinished drafts).
- Optional: superset count / warmup count if non-zero (`8 exercises · 1 superset · 2 warmups`), formatted via a new `WorkoutDaySummaryFormatter` paralleling [planned_draft_summary_formatter.dart](mobile/lib/modules/program_management/services/planned_draft_summary_formatter.dart).
- Visual shape: switch from raw `ListTile` to a card matching [day_tile.dart](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart) (surface bg, outline border, `AppRadius.md`, `AppSpacing.md/lg` padding) so the editor and picker feel like the same family.

**Prerequisite (bloc change):** [program_editor_bloc.dart:73-86](mobile/lib/modules/program_management/bloc/program_editor/program_editor_bloc.dart#L73-L86) currently builds drafts with `groups: const []`. Two options:
- (Cheap) Add a `programRepository.countExercisesByDay(programId) → Map<workoutDayId, ExerciseCounts>` and merge into the draft view, keeping `groups` empty for save logic.
- (Right thing) Load the full `ProgramAggregate` so the draft is real. Heavier change; pays off if we want richer summaries / inline preview.

Recommend the cheap path first; revisit when P1-3 (inline expand) lands.

**P0-2. Inline rename on the tile.** ✅
Long-press (or tap-pencil) → tile flips to an inline `TextField` with confirm/cancel; commit dispatches `ProgramEditorWorkoutDayRenamed` (the event already exists in the bloc but is unused from the UI). Removes a whole round-trip to the day editor for one of the most common edits.

**P0-3. Delete = optimistic + snackbar undo (replace dialog).** ✅
- Swipe or menu → remove from list immediately, dispatch delete event.
- `SnackBarAction("UNDO", ...)` re-inserts at the same index for ~5 s.
- Keep the existing `ConfirmationDialog` **only** for days with > N exercises (e.g. > 3), and update its body to surface the cost: `"Delete Push A? This removes 12 exercises and 1 superset."`
- Add `'undo last delete'` event to the bloc (re-create with original `persistedId` is fine because save is eventually-consistent; or hold the deleted draft in state until the snackbar dismisses).

**P0-4. Empty-state CTA.** ✅
Replace the static "Tap + to add a workout day" with a primary `FilledButton.icon(Icons.add, "Add workout day")` that opens the create flow, and a secondary `TextButton("Paste a plan", ...)` linking to [plan_import_screen.dart](mobile/lib/modules/program_management/screens/plan_import_screen.dart). Two real next steps, not a hint about a FAB.

**P0-5. Visible drag affordance.** ✅
Move the drag handle to the **leading** edge of the tile (left), wrap it in a `ReorderableDragStartListener(index: i, child: Icon(Icons.drag_indicator))`, and give it ~24 px footprint inside an `AppSpacing.touchMin`-wide column so it's actually grabbable. Right-edge stays a `PopupMenuButton` (kebab) for tile actions.

**P0-6. Per-tile action menu (kebab).** ✅ (Duplicate item rendered but disabled until P1-1.)
A `PopupMenuButton<_DayMenuAction>` on the trailing edge with:
- *Rename* (triggers P0-2)
- *Duplicate* (P1-1)
- *Delete* (triggers P0-3)
This gives an alt-path to delete that doesn't rely on swipe (accessibility win) and is the canonical place to put rare/dangerous actions.

**P0-7. Program-name edit affordance.** ✅
Mirror the workout-day editor's `_NameField` pattern: faint `Icons.edit` suffix when unfocused, hide when focused. ~10 lines.

### P1 — high impact, medium effort  ✅ shipped

**P1-1. Duplicate day.** ✅
- Menu action *Duplicate*.
- Bloc event `ProgramEditorWorkoutDayDuplicated(draftId)`.
- Repo: clone the WorkoutDay + its ExerciseGroups + Exercises + WorkoutSets with new IDs, inserted **immediately after** the source. New name: `"<original> (copy)"`.
- This is the highest-value single feature missing; users currently re-author every variation by hand.

**P1-2. "Add workout day" sheet replacing the AlertDialog.** ✅
A `showModalBottomSheet` with three options:
- Empty day (current behavior; name field)
- Duplicate of… (picker over existing days)
- Paste plain text (forward to `plan_import` scoped to "append to current program" — requires a small extension to the import flow)
Bottom sheets keep the input above the keyboard, give room for icons + descriptions, and avoid the AlertDialog focus issues.

**P1-3. Inline expand: peek at the day's exercises without leaving.** ✅
Tap a `chevron_right` (or the row body) → tile expands to show the first ~3–5 exercises as a static list. "Edit day →" link at the bottom of the expanded panel goes to the full editor.
- Requires loading the full ProgramAggregate (see P0-1 alt path). Done by reusing the full `listWorkoutDaysForProgram` data the bloc was already loading for summaries; preview names are surfaced via `ProgramEditorEditing.dayExercisePreviews`.
- Lets users scan "is this the day with the bench work?" without navigating.
- Keep collapse state local to the screen (don't persist).

**P1-4. Header strip with program stats.** ✅
Below the AppBar, a slim row with: `N days · M exercises · last edited <relative>` rendered in `caption` / `bodySmall`. Free orientation, helps the user know if they're in the right program. Reuses existing fields (`updatedAt`, derived counts).

### P2 — nice-to-have, lower priority

**P2-1. Day color / index dot.**
A small leading circle with the day's position (`1`, `2`, …) or a user-pickable accent color. Cheap scan aid for users with many days.

**P2-2. "Move to another program" action.**
Menu option that opens a program picker and rebinds the workout day. Rare but powerful for users splitting / merging programs.

**P2-3. Templates in the create sheet.**
"Start from a template" → Push/Pull/Legs, Upper/Lower, Full Body. Each materialises a skeleton day with named-but-empty exercises ready to be filled. Out of scope unless the project grows a templates feature.

**P2-4. Keyboard / accessibility pass.**
- Semantics labels on drag handle ("Drag to reorder day 3 of 5").
- Focus order: name field → tile list → FAB.
- Live-region announce on delete + undo.
This should be uncontroversial but is real work; bundle with the visual refresh.

---

## 5. Detailed spec — recommended P0 layout

Mock (textual) of the proposed tile, replacing the current single-line ListTile:

```
┌──────────────────────────────────────────────────────────┐
│ ⋮⋮  Push A                                         ⋯     │
│ ⋮⋮  8 exercises · 1 superset · 2 warmups               │
└──────────────────────────────────────────────────────────┘
   ↑                                                  ↑
   drag handle (Icons.drag_indicator, left-edge,      kebab menu
   wrapped in ReorderableDragStartListener)           (Rename / Duplicate / Delete)
```

Empty-day variant:

```
┌──────────────────────────────────────────────────────────┐
│ ⋮⋮  Push A                                  [EMPTY] ⋯    │
│ ⋮⋮  No exercises yet · Tap to add                      │
└──────────────────────────────────────────────────────────┘
```

Tokens:
- Container: `colors.surface`, `Border.all(colors.outline)`, `AppRadius.md`, vertical padding `AppSpacing.md`, horizontal padding `AppSpacing.lg`.
- Name: `AppTypography.standard.titleSmall`, color `colors.onSurface`.
- Subtitle: `AppTypography.standard.caption`, color `colors.onSurfaceMuted` (or `colors.error` when EMPTY badge is shown — reuse the "no sets planned" treatment from [planned_draft_summary_formatter.dart:38](mobile/lib/modules/program_management/services/planned_draft_summary_formatter.dart#L38)).
- EMPTY badge: pill, `colors.error.withValues(alpha: 0.12)` bg, `colors.error` text — same recipe as `_InProgressChip` in `day_tile.dart`.
- Drag handle column: 32 dp wide, vertically centered, `Icons.drag_indicator` at 20 px in `colors.onSurfaceMuted`.
- Kebab: `PopupMenuButton<_DayMenuAction>` with the three items above. Items use `Icons.edit`, `Icons.copy`, `Icons.delete_outline` (last in `colors.error`).
- Min tile height: `AppSpacing.touchMin + AppSpacing.sm * 2` ≈ 64 dp.

---

## 6. Implementation order

1. **Step 1 — visual + tile refresh (P0-1 lite, P0-5, P0-6, P0-7).**
   No bloc changes yet. Just adopt the card shape, drag handle on the left, kebab menu (with Rename/Delete wired; Duplicate disabled with a tooltip), name edit affordance. Subtitle reads "N exercises" sourced from the cheap repo count query. This alone moves the screen out of "stub" territory.
2. **Step 2 — inline rename (P0-2) and optimistic delete + undo (P0-3).**
   Bloc additions: a transient `recentlyDeleted` slot on `ProgramEditorEditing` to power the snackbar's UNDO. Refactor delete path so the dialog only fires for "heavy" days.
3. **Step 3 — empty-state CTA (P0-4).**
   Pure UI; no bloc work.
4. **Step 4 — duplicate day (P1-1).**
   Repo + bloc + menu enable. Largest single feature in the plan.
5. **Step 5 — create sheet (P1-2) and program stats header (P1-4).**
   Bottom sheet replaces the AlertDialog; piggybacks on the existing "create empty day" event plus the new "duplicate day" event.
6. **Step 6 — inline expand (P1-3).**
   Requires switching the editor's bloc from "list of names" to "full aggregate" — defer until the rest has shipped and we've felt the pain of the cheap-count path.
7. **Step 7 — P2 polish** as standalone changes if/when they earn priority.

---

## 7. Out of scope

- Templates library (P2-3).
- Cross-program operations beyond move (P2-2): no merge, no diff.
- Any change to how *sessions* see a program — snapshot semantics are intentional ([product-context.md](product-context.md)) and must not regress.
- Visual theme changes to `AppColors` / `AppTypography`; everything here uses existing tokens.
- Re-architecting the bloc beyond loading exercise counts; the `groups: []` shortcut survives until P1-3.

---

## 8. Risks / things to verify before building

- **Exercise counts query cost.** Adding a per-day count on screen open means an extra read. Verify the offline-only Drift path is fine; should be (it's a `COUNT(*) GROUP BY workout_day_id`).
- **Undo on delete** must round-trip safely if the bloc has already persisted the deletion. Either (a) hold the delete until snackbar dismiss, or (b) re-create with the same ID — confirm the repository accepts re-creation with an explicit ID without violating uniqueness.
- **Optimistic UI + save in progress.** The bloc already serialises mutations through `_persist`; new events must follow the same pattern so the on-disk order matches the UI order shown to the user.
- **Snapshot safety.** Sessions snapshot at start, so editing a program *during* an active session is allowed and must remain so. Nothing in this plan changes that.
