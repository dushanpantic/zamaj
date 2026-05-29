# Screen decomposition plan

Goal: break large screen files into focused widget files for readability,
reviewability, and rebuild locality. This document records (1) the modern
Flutter best practices that justify the work, (2) the one Dart constraint that
shapes *how* we split, (3) a per-screen verdict for all 13 screens, and
(4) concrete extraction plans for the files that warrant it.

---

## 1. Modern Flutter best practices (the "why")

These are the principles the refactor is optimizing for. They come from the
official Flutter performance docs and current (2026) community consensus.

1. **Prefer `StatelessWidget`/`StatefulWidget` classes over `Widget _build…()`
   helper methods.** A widget class is a node in the element tree with its own
   `BuildContext`; a helper method is just inlined code that rebuilds whenever
   its *enclosing* `build()` runs. Splitting into widget classes:
   - localizes rebuilds (a child only rebuilds when *its* inputs change),
   - enables `const` constructors (Flutter reuses the element, skips the
     rebuild entirely),
   - gives each piece a name, a constructor contract, and a single
     responsibility — which is the actual readability win.

2. **`const` everywhere it's legal.** A `const` widget with `const` arguments is
   canonicalized and never rebuilt. Extraction into small widgets creates many
   more `const` opportunities than a monolithic `build()` does.

3. **Push state down, keep it small.** A `StatefulWidget` should own only the
   state it needs (a controller, a timer, an animation). Big screens today mix
   screen-level state with leaf-level state in one `State`. Extraction lets each
   stateful concern (e.g. an elapsed-time ticker, a marquee animation) own its
   own short-lived state.

4. **One widget = one responsibility = one file.** This is the repo's existing
   convention (see §3). Reviewers can diff a 60-line widget file; they cannot
   meaningfully review a 2,000-line screen.

5. **Lift shared callbacks via constructor, not via the tree.** Reaching back up
   the element tree (`findAncestorStateOfType`) to call a screen method is a
   coupling smell and blocks extraction. Pass an explicit callback down instead.

Sources:
- [Flutter performance best practices](https://docs.flutter.dev/perf/best-practices)
- [Flutter App Best Practices 2026 — Startup House](https://startup-house.com/blog/flutter-app-best-practices)
- [Flutter Performance Optimization 2026 — dev.to](https://dev.to/techwithsam/flutter-performance-optimization-2026-make-your-app-10x-faster-best-practices-2p07)

---

## 2. The Dart constraint that shapes the work

Most of the inline widgets in these screens are **library-private**
(`_GroupBuilder`, `_ReorderGap`, `_PanelHeader`, …). Privacy in Dart is
per-*library* (per-file). The moment a `_Foo` class moves to its own file it is
no longer visible to the original screen unless it is made **public** (drop the
`_`) or the two files are joined into one library with `part`/`part of`.

Two viable strategies:

| Strategy | What it means | Pros | Cons |
|---|---|---|---|
| **A. Public widget per file** (recommended, matches repo) | Rename `_Foo` → `Foo`, move to `widgets/foo.dart`, import via `package:zamaj/…` | Matches the existing convention exactly; each widget is independently testable/reusable; clean imports | Widget names become module-public even when only the screen uses them |
| **B. `part` / `part of`** | Keep `_Foo` private, split the file with `part 'foo.dart';` + `part of '…';` | Preserves privacy; tightly-coupled screen-internal types keep referencing each other | The repo uses `part` only for codegen today — introduces a new hand-written pattern; tooling/格 noise |

**Recommendation: Strategy A** for everything, because the codebase already
standardizes on "one public widget per file in `widgets/`" (verified: every
existing extracted widget is public and imported by path; no hand-written
`part` files exist). Where a cluster of widgets shares a private helper type
(e.g. the drag payload / drag-session classes in workout_overview), promote that
helper to a public type in its own file too, or keep the *whole cluster* in one
new file under a `widgets/` subfolder so they share a library.

Naming: keep the leading-underscore name only while a widget stays inside its
screen file. On extraction, the `_` is dropped and the file is `snake_case` of
the class name (repo convention, e.g. `_ExerciseCard` → `exercise_card.dart`).

---

## 3. Conventions observed in this codebase (follow these)

- UI feature modules live under `lib/modules/<feature>/` with `screens/` and
  `widgets/` siblings. Extracted widgets go in `widgets/`, **one public widget
  per file**, imported via `package:zamaj/modules/<feature>/widgets/<name>.dart`.
- UI tokens are mandatory: `Theme.of(context).appColors`, `AppSpacing.*`,
  `AppRadius.*`, `AppTypography.*`. No raw pixels/colors. (CLAUDE.md)
- `workout_overview/` and `focus_mode/` are the live-in-the-gym surfaces with
  the sweaty-hands ergonomics rules (64×64 dp counters, `numericLarge` inputs,
  ≥56 dp primary actions). Extraction must **preserve every existing size and
  style verbatim** — this is a structural refactor, not a visual change.
- **Tests cover domain + persistence only.** There are no widget tests and
  CLAUDE.md says not to add them. That means these refactors are **not** guarded
  by a test suite — they must be behavior-preserving by construction and
  verified by `dart analyze` + a manual run (see §7).
- Cross-module imports go through barrels; within-module widget imports are
  direct file imports (e.g. `widgets/exercise_card.dart`).

---

## 4. Per-screen verdict (all 13 screens)

| # | Screen | Lines | Inline classes | Verdict |
|---|---|---:|---:|---|
| 1 | workout_overview/screens/workout_overview_screen.dart | 2014 | 26 | **Tier 1 — split** ✅ DONE (now 362) |
| 2 | program_management/screens/workout_day_editor_screen.dart | 1431 | 20 | **Tier 1 — split** ✅ DONE (now 296) |
| 3 | focus_mode/screens/focus_mode_screen.dart | 1345 | 22 | **Tier 1 — split** ✅ DONE (now 105) |
| 4 | program_management/screens/program_editor_screen.dart | 835 | 6 | **Tier 2 — split** ✅ DONE (now 323) |
| 5 | program_management/screens/exercise_editor_screen.dart | 774 | 7 | **Tier 2 — split** ✅ DONE (now 193) |
| 6 | exercise_library/screens/exercise_library_editor_screen.dart | 473 | 6 | Tier 3 — optional |
| 7 | exercise_library/screens/exercise_library_list_screen.dart | 420 | 6 | Tier 3 — leave |
| 8 | program_management/screens/plan_preview_screen.dart | 410 | 6 | Tier 3 — optional |
| 9 | export/screens/recent_sessions_screen.dart | 334 | 6 | Tier 3 — leave |
| 10 | program_management/screens/program_list_screen.dart | 330 | 6 | Tier 3 — leave |
| 11 | exercise_library/screens/link_suggestion_screen.dart | 312 | 7 | Tier 3 — leave |
| 12 | workout_day_picker/screens/workout_day_picker_screen.dart | 291 | 5 | Tier 3 — leave |
| 13 | program_management/screens/plan_import_screen.dart | 291 | 4 | Tier 3 — leave |

**General observation:** screens 6–13 already follow the target pattern
(screen shell → state-views + `_LoadedView`/`_LoadedBody` + a few small inline
widgets) and most of their heavy widgets are already in `widgets/`. They are not
the problem. The 5 Tier 1/2 files hold ~6,400 of the ~9,260 screen lines.

---

## 5. Tier 1 — detailed extraction plans

### 5.1 workout_overview_screen.dart (2014 → ~300 line shell)

This file is the biggest win. It bundles three unrelated concerns: the BLoC
screen shell, the scrollable loaded body, and an entire **drag-and-drop
subsystem**. Target structure (new files under `workout_overview/widgets/`,
plus a `workout_overview/drag/` folder for the DnD cluster):

Extract to `widgets/`:
- `workout_overview_app_bar_title.dart` ← `_LoadedAppBarTitle` (+ its
  `_exerciseCounts` helper)
- `session_elapsed_label.dart` ← `_SessionElapsedLabel` (self-contained
  stateful ticker)
- `workout_overview_bottom_bar.dart` ← `_BottomActionBar` + `_SecondaryActionButton`
- `transient_error_banner.dart` ← `_TransientErrorBanner`
- `session_ended_banner.dart` ← `_SessionEndedBanner`
- `delayed_mutation_indicator.dart` ← `_DelayedMutationIndicator`
- `workout_overview_not_found_view.dart` ← `WorkoutOverviewNotFoundView`
  (currently inline though siblings live in `widgets/`)

Extract the drag-and-drop cluster to a new `workout_overview/drag/` folder
(these share private types, so keep them in one library or promote shared types
to public):
- `drag_session.dart` ← `_DragSession` → `DragSession` (ChangeNotifier)
- `drag_auto_scroller.dart` ← `_DragAutoScroller` → `DragAutoScroller`
- `drag_handle.dart` ← `_DragHandle`, `_DragFeedbackPill`
- `draggable_exercise.dart` ← `_DraggableExercise`, `_SupersetDropOverlay`
- `reorder_gap.dart` ← `_ReorderGap`
- `superset_reorder_gap.dart` ← `_SupersetReorderGap`
- shared `_exerciseDisplayName` helper → a small public function or method on
  the view model.

Extract the body + group dispatch:
- `widgets/workout_overview_loaded_body.dart` ← `_LoadedBody` (+ `_CurrentFocus`
  can stay with the screen or move with the body) — owns the scroll controller,
  auto-scroller, coach-mark.
- `widgets/workout_group_builder.dart` ← `_GroupBuilder` (single vs superset
  dispatch, group-candidate logic).

What stays in `workout_overview_screen.dart`: `WorkoutOverviewScreen` +
`_WorkoutOverviewScreenState` (the BLoC consumer, event handlers like
`_handleReplace`/`_handleSkip`/…, snackbars, and the `build`/`_body` switch).
~300 lines.

Note: the screen-level handlers are passed down today as callbacks already, so
the body/group widgets can keep taking them via constructor — no new coupling.

### 5.2 workout_day_editor_screen.dart (1431 → ~250 line shell)

Holds the program-day editor with a bespoke drag/drop + reorder + dismiss tile
system, duplicated once for flat rows and once for superset members.

**Fix first (blocks clean extraction):** `_FlatExerciseRow` and `_SupersetCard`
call `context.findAncestorStateOfType<_WorkoutDayEditorScreenState>()` to invoke
`_navigateToExercise`. Replace this with an explicit `onNavigateToExercise`
callback threaded from the screen → `_EditingBody` → `_ExerciseList` → tiles.
Once that's gone, the tiles extract cleanly.

Extract to `widgets/`:
- `workout_day_name_field.dart` ← `_NameField`
- `workout_day_save_chip.dart` ← `_SaveChip`
- `workout_day_save_error_banner.dart` ← `_SaveErrorBanner`
- `workout_day_exercise_list.dart` ← `_ExerciseList`
- `editor_flat_exercise_row.dart` ← `_FlatExerciseRow`
- `editor_superset_card.dart` ← `_SupersetCard`
- `editor_exercise_tile_content.dart` ← `_ExerciseTileContent`, `_WarmupBadge`,
  `_SupersetPositionBadge`, `_RestChip` (the shared tile-internal chips)
- `add_exercise_dialog.dart` ← `_AddExerciseDialog` + `_startAddExercise`
- shared types: `_GroupMenuAction` enum and `_ExerciseDragPayload` →
  `editor_drag_payload.dart` (public) so the row and superset card can both use
  them.

What stays: `WorkoutDayEditorScreen` + state, `_EditingBody`, `_LoadingView`,
`_NotFoundView`.

### 5.3 focus_mode_screen.dart (1345 → ~250 line shell)

Holds the panel-card system (current/previous/upcoming variants), a generic
marquee, and the pinned bottom bar.

Extract to `widgets/` (this module already has a rich `widgets/` folder):
- `focus_marquee_text.dart` ← `_MarqueeText` (fully generic; reusable)
- `focus_up_next_strip.dart` ← `_UpNextStrip` (note: a `focus_up_next.dart`
  already exists — reconcile/replace rather than duplicate)
- `focus_panel_slot.dart` ← `_PanelSlot` + `FocusPanelRole` enum + `_roleFor`
- `focus_current_panel_card.dart` ← `_CurrentPanelCard`
- `focus_previous_panel_card.dart` ← `_PreviousPanelCard`
- `focus_upcoming_panel_card.dart` ← `_UpcomingPanelCard`
- `focus_panel_header.dart` ← `_PanelHeader` + `_WarmupPill`
- `focus_planned_and_last.dart` ← `_PlannedAndLast` (+ `_formatPlanned`/
  `_formatLast` → either co-located public helpers or a small formatter)
- `focus_current_values_panel.dart` ← `_CurrentValuesPanel`
- `focus_pinned_bottom_bar.dart` ← `_PinnedBottomBar` + `_UndoLastSetButton`
- `focus_panel_actions_menu.dart` ← `_PanelActionsMenu` + `_PanelMenuAction`
- `focus_switch_exercise_button.dart` ← `_SwitchExerciseButton`
- `focus_mode_state_views.dart` ← `_LoadingView`, `_NotFoundView`, `_ErrorView`,
  `_TransientErrorBanner` (or fold into the shared state-views — see §6.1)
- `focus_ready_body.dart` ← `_ReadyBody`

What stays: `FocusModeScreen` + state (listeners, app-bar builder, body switch).

---

## 6. Tier 2 — detailed extraction plans

### 6.1 program_editor_screen.dart (835)

Two issues: `_build*` helper methods in the State, and a large inline bottom
sheet.

- Convert `_buildScaffold` / `_buildAppBar` / `_buildWorkoutDayList` from
  methods to widgets:
  - `widgets/program_editor_app_bar.dart` (the name `TextField` app bar)
  - `widgets/program_editor_day_list.dart` (the reorderable list + empty state)
- Extract the bottom sheet (it's a mini state machine): the whole
  `_AddWorkoutDaySheet` + `_AddWorkoutDayMode` + `_SheetOption` →
  `widgets/add_workout_day_sheet.dart`. Its `_buildMenu`/`_buildEmptyForm`/
  `_buildDuplicatePicker` methods can stay as private methods *inside that new
  widget's State* (acceptable — they're small and local) or become `_Menu`/
  `_EmptyForm`/`_DuplicatePicker` sub-widgets.
- `_ProgramStatsHeader` → `widgets/program_stats_header.dart`.

### 6.2 exercise_editor_screen.dart (774)

The form body and the library-link section are the two heavy blocks.

- `widgets/exercise_editor_form.dart` ← `_EditorBody` (the 200-line form).
  Optionally decompose further into field clusters
  (`_PlannedSetsSection`, etc.) but the form is cohesive — one file is fine.
- `widgets/exercise_library_link_section.dart` ← `_LibraryLinkSection` +
  `_LibraryAction` enum. This is ~230 lines of dialogs/sheets/repo calls and is
  the strongest single extraction in this file.
- `widgets/exercise_editor_scaffolds.dart` (or individual files) ←
  `_EditorScaffold`, `_LoadingScaffold`, `_NotFoundScaffold`.

What stays: `ExerciseEditorScreen` + state (controllers, `_syncControllers`,
discard/pop handling, state→scaffold switch).

---

## 7. Cross-cutting opportunities (optional, do AFTER Tier 1/2)

### 7.1 Shared state-views are duplicated ~10×
Nearly every screen reimplements its own near-identical `_LoadingView`,
`_FailureView`/`_ErrorView`, `_NotFoundView`, `_EmptyView`, and a transient
error banner (icon + title + body + action button). Candidate: a small set of
reusable building blocks in `lib/building_blocks/` (e.g. `CenteredMessageView`,
`RetryView`). **Caveat:** verify the variants are truly interchangeable before
unifying — some differ in icon size (48 vs 64), button type, and copy. This is a
separate, lower-risk-if-careful cleanup; do not bundle it with the structural
splits.

### 7.2 Reusable generic widgets surfaced by extraction
`_MarqueeText` (focus) and the elapsed-timer label (overview) are fully generic
and could live in `building_blocks/` if reuse appears. Don't pre-emptively
generalize; extract in place first.

---

## 8. Verification strategy (important — no widget tests guard this)

Because the test suite is domain+persistence only, each extraction must be a
**pure move** with no behavior change. For every file:

1. Move the class verbatim; change only `_Name` → `Name` and add imports. Do not
   "improve" widget internals in the same step.
2. `tool/check_offline_imports.sh` — confirm no UI→drift/network leak introduced
   by new imports.
3. `dart run build_runner build --force-jit` only if any codegen input changed
   (these are pure widget moves, so usually not needed).
4. `dart analyze` (via `tool/ci.sh`, which also runs format + tests) — must be
   clean.
5. **Manual run by the user** (visual validation is the user's step — these are
   the sweaty-hands surfaces, so confirm drag/drop, reorder, LOG SET, rest
   timer, and coach-marks still behave). I will not launch the app to validate;
   I'll hand it back for a visual pass.

---

## 9. Suggested sequencing

Smallest-blast-radius first; one screen per PR/commit so each is reviewable.

1. ✅ **exercise_editor_screen.dart** (Tier 2) — clean callback boundaries, no DnD;
   good warm-up that proves the extraction recipe. **DONE** (774 → 193): extracted
   `widgets/exercise_library_link_section.dart`, `widgets/exercise_editor_form.dart`,
   and `widgets/exercise_editor_scaffolds.dart` (Loading/NotFound/Editor scaffolds).
   Pure move; `dart analyze` clean, offline-imports guard OK. Awaiting user visual pass.
2. ✅ **program_editor_screen.dart** (Tier 2) — converts `_build*` methods + sheet.
   **DONE** (835 → 323): extracted `widgets/program_stats_header.dart` (`ProgramStatsHeader`),
   `widgets/program_editor_app_bar.dart` (`ProgramEditorAppBar`, a `PreferredSizeWidget`;
   dropped the unused `name`/`isCreateMode` params), `widgets/add_workout_day_sheet.dart`
   (`AddWorkoutDaySheet` + private `_AddWorkoutDayMode`/`_SheetOption` kept in-file), and
   `widgets/program_editor_day_list.dart` (`ProgramEditorDayList` — empty state + reorderable
   list; reads the bloc directly, takes editing/expand state + callbacks via constructor).
   `_buildScaffold` state switch stays in the screen. Pure move; `dart analyze` clean,
   offline-imports guard OK. Awaiting user visual pass.
3. ✅ **focus_mode_screen.dart** (Tier 1) — many small panel widgets, mostly
   stateless, low coupling. **DONE** (1345 → 105): extracted to `widgets/` —
   `focus_marquee_text.dart` (`FocusMarqueeText`), `focus_up_next_strip.dart`
   (`FocusUpNextStrip`; replaced the dead `focus_up_next.dart`/`FocusUpNext`,
   which had no callers), `focus_panel_slot.dart` (`FocusPanelSlot` + public
   `FocusPanelRole` enum + `focusPanelRoleFor`), `focus_current_panel_card.dart`,
   `focus_previous_panel_card.dart`, `focus_upcoming_panel_card.dart`,
   `focus_panel_header.dart` (`FocusPanelHeader` + in-file `_WarmupPill`),
   `focus_planned_and_last.dart` (`FocusPlannedAndLast` + public
   `focusFormatPlanned`/`focusFormatLast`), `focus_current_values_panel.dart`,
   `focus_pinned_bottom_bar.dart` (`FocusPinnedBottomBar` + in-file
   `_UndoLastSetButton`), `focus_panel_actions_menu.dart` (`FocusPanelActionsMenu`
   + in-file `_PanelMenuAction`), `focus_switch_exercise_button.dart`,
   `focus_mode_state_views.dart` (`FocusLoadingView`/`FocusNotFoundView`/
   `FocusErrorView`/`FocusTransientErrorBanner`), and `focus_ready_body.dart`
   (`FocusReadyBody`). Screen keeps `FocusModeScreen` + state (bloc listeners,
   `_appBarFor`, `_body` switch). Pure move; `dart analyze` clean, format clean,
   offline-imports guard OK. Awaiting user visual pass.
4. ✅ **workout_day_editor_screen.dart** (Tier 1) — do the `findAncestorStateOfType`
   fix first, then extract the tile/superset DnD. **DONE** (1431 → 296): replaced
   the `findAncestorStateOfType<_WorkoutDayEditorScreenState>` lookups by threading
   an `onNavigateToExercise` callback screen → `_EditingBody` → `WorkoutDayExerciseList`
   → tiles. Extracted to `widgets/`: `editor_drag_payload.dart` (`ExerciseDragPayload`
   + `GroupMenuAction`, both promoted to public so the row + superset card share them),
   `editor_exercise_tile_content.dart` (`EditorExerciseTileContent` + `EditorWarmupBadge`
   public; `_SupersetPositionBadge`/`_RestChip` kept private in-file),
   `add_exercise_dialog.dart` (public `startAddExercise` fn + private `_AddExerciseDialog`),
   `editor_flat_exercise_row.dart` (`EditorFlatExerciseRow`), `editor_superset_card.dart`
   (`EditorSupersetCard`), `workout_day_exercise_list.dart` (`WorkoutDayExerciseList`;
   reads the bloc from context, takes the nav callback via constructor),
   `workout_day_name_field.dart` (`WorkoutDayNameField`), `workout_day_save_chip.dart`
   (`WorkoutDaySaveChip`), `workout_day_save_error_banner.dart` (`WorkoutDaySaveErrorBanner`).
   Screen keeps `WorkoutDayEditorScreen` + state, `_EditingBody`, `_LoadingView`,
   `_NotFoundView`. Pure move; `dart analyze` clean (whole `lib/`), format clean,
   offline-imports guard OK. Awaiting user visual pass.
5. ✅ **workout_overview_screen.dart** (Tier 1) — largest; extract the DnD cluster
   last when the recipe is well-practiced. **DONE** (2014 → 362). DnD logic
   promoted to public and moved to `services/`: `drag_session.dart` (`DragSession`,
   the ChangeNotifier) and `drag_auto_scroller.dart` (`DragAutoScroller`, the
   Ticker-driven scroller; uses the existing `services/drag_auto_scroll.dart`
   `computeScrollDelta` helper). Rather than the proposed new `drag/` folder, the
   DnD *widgets* went to `widgets/` to match the repo's one-public-widget-per-file
   convention: `drag_handle.dart` (`DragHandle` + in-file `_DragFeedbackPill`),
   `draggable_exercise.dart` (`DraggableExercise` + in-file `_SupersetDropOverlay`),
   `reorder_gap.dart` (`ReorderGap`), `superset_reorder_gap.dart`
   (`SupersetReorderGap`). Leaf widgets to `widgets/`:
   `workout_overview_app_bar_title.dart` (`WorkoutOverviewAppBarTitle`, keeps its
   `_exerciseCounts` static), `session_elapsed_label.dart` (`SessionElapsedLabel`),
   `workout_overview_bottom_bar.dart` (`WorkoutOverviewBottomBar` + in-file
   `_SecondaryActionButton`), `transient_error_banner.dart` (`TransientErrorBanner`),
   `session_ended_banner.dart` (`SessionEndedBanner`),
   `delayed_mutation_indicator.dart` (`DelayedMutationIndicator`). Body + group
   dispatch to `widgets/`: `workout_overview_loaded_body.dart`
   (`WorkoutOverviewLoadedBody` — owns scroll controller, auto-scroller, drag
   session, coach-mark) and `workout_group_builder.dart` (`WorkoutGroupBuilder` —
   single/superset dispatch + group-candidate logic). The shared
   `_exerciseDisplayName`/`_displayName` helpers were replaced by a public
   `displayName` extension getter on `ExerciseViewModel`
   (`models/exercise_view_model.dart`), used by both the screen and the group
   builder. Note: `WorkoutOverviewNotFoundView` was already in `widgets/`
   (the §5.1 "currently inline" note was stale). Screen keeps `WorkoutOverviewScreen`
   + state (BLoC consumer, `_handle*` event handlers, snackbars, `_resolveCurrent`,
   `_CurrentFocus`, `_titleFor`, `_body` switch). Pure move; `dart analyze` clean
   (whole `lib/`), format clean, offline-imports guard OK. Awaiting user visual pass.
6. (Optional) Cross-cutting shared state-views (§7.1).

Each step: pure move → `tool/ci.sh` clean → hand to user for a visual pass
before starting the next.

---

## 10. Out of scope

- No visual/behavioral changes. Sizes, colors, copy, haptics, and animation
  durations are preserved verbatim.
- No new widget tests (per CLAUDE.md).
- No bloc/domain/persistence changes. This is UI-layer file organization only.
- product-context.md needs **no** update: no user-facing screen or feature is
  added, removed, or renamed (CLAUDE.md rule).
