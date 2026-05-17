# Zamaj — UI/UX Improvement Audit

A screen-by-screen review of the Flutter mobile app against modern mobile UI/UX practices (Material 3, iOS HIG cross-pollination, fitness-app conventions, accessibility, one-handed gym use). Findings are grouped from cross-cutting → per-screen → polish. Each item lists a concrete file reference and a recommendation.

Severity legend:
- **P1** — affects core task completion or accessibility
- **P2** — meaningful friction or polish gap
- **P3** — nice-to-have / consistency

---

## 1. Cross-cutting (applies to most/all screens)

### 1.1 Navigation architecture is push-only — no persistent home
- **Where:** [app.dart](mobile/lib/app.dart), [session_routes.dart](mobile/lib/navigation/session_routes.dart), [program_management_routes.dart](mobile/lib/modules/program_management/navigation/program_management_routes.dart)
- **Problem:** Every screen is a `Navigator.pushNamed` on top of `ProgramList`. There is no bottom navigation, no tab bar, and no shortcut between "Programs", "Recent sessions", "Active session" (when one exists). Returning to Recent Sessions requires drilling back through Picker.
- **Recommend (P1):** Add a `BottomNavigationBar` or `NavigationBar` (M3) at the root level: `Programs` · `History` · `Active`. The Active tab badges when a session is in-flight (resume from anywhere). This is the #1 UX upgrade for daily gym use.

### 1.2 No deep links / restorable state
- **Where:** [app.dart](mobile/lib/app.dart) uses `onGenerateRoute` with no `restorationScopeId`
- **Problem:** Cold-start always lands on Programs. If Android kills the process mid-set, the active session is not auto-restored to its screen.
- **Recommend (P1):** Adopt `go_router` or set `restorationScopeId` + `RestorationMixin` on Focus + Overview. On launch, detect any active session and resume directly.

### 1.3 Theme is hard-locked to dark
- **Where:** [app.dart:45](mobile/lib/app.dart#L45) — `themeMode: ThemeMode.dark`
- **Problem:** No user setting, no system-follow. Light theme exists in tokens but ships unused.
- **Recommend (P2):** Add a Settings entry (and/or default `ThemeMode.system`). Gym lighting varies — daytime outdoor workouts often want light mode.

### 1.4 Loading states are inconsistent (spinners vs. skeletons)
- **Where:** [program_list_screen.dart:158](mobile/lib/modules/program_management/screens/program_list_screen.dart#L158), [workout_overview_loading_view.dart](mobile/lib/modules/workout_overview/widgets/workout_overview_loading_view.dart), [day_tile.dart:166-198](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L166-L198) (good skeleton)
- **Problem:** `DayTile` shows shimmer-less but structured skeleton bars; everywhere else uses a centered `CircularProgressIndicator`. Spinners feel like nothing's happening; skeletons preserve perceived performance.
- **Recommend (P2):** Adopt the day-tile skeleton pattern app-wide (programs list, day picker initial, recent sessions, overview, focus). Wrap in a `shimmer` package for low-effort polish.

### 1.5 Empty states vary in tone, iconography, and CTAs
- **Where:**
  - [program_list_screen.dart:212](mobile/lib/modules/program_management/screens/program_list_screen.dart#L212) — `fitness_center_outlined`, two CTAs
  - [program_editor_screen.dart:314](mobile/lib/modules/program_management/screens/program_editor_screen.dart#L314) — `fitness_center_outlined`, no CTA (instructs to tap +)
  - [workout_day_editor_screen.dart:295](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L295) — `fitness_center` (filled), no CTA
  - [recent_sessions_screen.dart:190](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L190) — `history` icon, no CTA
  - [workout_day_picker_empty_view.dart](mobile/lib/modules/workout_day_picker/widgets/workout_day_picker_empty_view.dart)
- **Recommend (P2):** Build a single `AppEmptyState` widget — icon, title, body, primary CTA, optional secondary. Use throughout. Always offer a path forward (instead of "tap +", inline a CTA button).

### 1.6 Error views and copy are not standardized
- **Where:** Voice/wording drifts: "Could not load programs" / "Workout day not found." (period) / "Session not found" (no period) / "Program not found" / "Failed to save. Please try again."
- **Recommend (P3):** Single `ErrorScreen` widget with title + body + (retry/back) actions. One copy doc for app-wide tone.

### 1.7 No haptic feedback anywhere ✅ DONE
- **Where:** Set logged, rest timer overtime, drag accepted, replace confirmed, etc.
- **Recommend (P2):** Add `HapticFeedback.lightImpact()` on:
  - Set log success (focus mode + overview)
  - Drag accepted into drop target
  - Rest timer crossing zero (`heavyImpact` once)
  - Long-press to start drag
  - Workout complete
- Gyms are noisy; tactile signals double-confirm action. *(Centralised in [haptics.dart](mobile/lib/core/haptics.dart): `tap`/`grab`/`emphasis`. Wired to set-logged + workout-complete + rest-overtime in Focus, and drag accept + long-press start + set-logged in Overview.)*

### 1.8 Destructive actions block on dialog; no undo  *(not pursuing for now)*
- **Where:** [confirmation_dialog.dart](mobile/lib/modules/program_management/widgets/confirmation_dialog.dart) used by delete program, delete day, delete exercise, skip exercise, end session, change measurement type
- **Problem:** Every destructive flow is dialog-gated. Combined with swipe-to-delete in [program_list_tile.dart:113](mobile/lib/modules/program_management/widgets/program_list_tile.dart#L113), the user gets *both* a swipe and a dialog — the swipe is essentially a slow tap on "delete more vert > delete".
- **Recommend (P1):** Prefer **undo snackbar** for moderate-risk actions (delete one exercise/set, skip exercise). Reserve dialogs for cascading deletes (program with N days, end session). Snackbars are non-blocking, support quick recovery, and the dominant pattern in mobile apps (Gmail, Drive, Apple Notes). *(Decision 2026-05-17: deferred — staying with confirmation dialogs for now.)*

### 1.9 No back-press guard on unsaved editors ✅ DONE
- **Where:** [exercise_editor_screen.dart](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart) — back gesture silently discards in-progress edits; only the explicit "Save" button persists
- **Recommend (P1):** Wrap editor in `PopScope` (Flutter 3.16+). If draft differs from saved state, prompt "Discard changes?" before allowing pop. Same for `WorkoutDayEditor`, `ProgramEditor`, `PlanPreview`. *(Applied to ExerciseEditor + PlanPreview; ProgramEditor/WorkoutDayEditor auto-save so no guard needed.)*

### 1.10 Hard-coded font sizes override design tokens ✅ DONE
- **Where:** Many places override `fontSize:` on a `typography.*` style, defeating the purpose of `AppTypography`:
  - [focus_rep_based_panel.dart:233](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L233) — `fontSize: 44`
  - [focus_mode_screen.dart:232](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L232) — `fontSize: 28`
  - [focus_rest_timer_bar.dart:57](mobile/lib/modules/focus_mode/widgets/focus_rest_timer_bar.dart#L57) — `fontSize: 22`
  - [exercise_card.dart:227](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L227), [276](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L276) — `fontSize: 14` / `12`
  - [workout_day_editor_screen.dart:535, 545, 558, 638](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart) — `fontSize: 14`, `12`
  - [exercise_editor_screen.dart:276](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L276) — `fontSize: 11`
- **Recommend (P2):** Add new semantic typography entries (e.g., `numericHero`, `numericMd`, `badge`) to `AppTypography` and remove all literal `fontSize` overrides. Once. Then they're tunable in one place. *(`numericHero`/`numericMd`/`badge` tokens added; no remaining `fontSize:` overrides in the codebase.)*

### 1.11 Hard-coded colors slip through (CLAUDE.md rule) ✅ DONE
- **Where:**
  - [plan_preview_screen.dart:83](mobile/lib/modules/program_management/screens/plan_preview_screen.dart#L83) — `Colors.black38` overlay
  - [workout_overview_screen.dart:556, 599](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart) — `Colors.transparent` (defensible, but `colors.outline.withValues(alpha: 0)` is the principled form)
- **Recommend (P3):** Add `colors.scrim` token to `AppColors` (both palettes) and use it. Audit for any `Color(0x…)` literals in UI directories. *(`scrim` token shipped in both palettes; the saving overlay in PlanPreview reads from it. Remaining `Colors.transparent` usages are inside `Material(color: ...)` ink wrappers where transparency is the intent.)*

### 1.12 Accessibility: missing semantics, tiny tap targets in some places ✅ DONE
- **Where:**
  - Icon-only buttons rarely have `tooltip` / `Semantics`. Examples are fine (`IconButton` has `tooltip`), but `Icon(...)` alone is announced as "image" by TalkBack.
  - ✅ `IconButton` close on transient error banners uses `constraints: const BoxConstraints()` ([workout_overview_screen.dart:657](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L657), [focus_mode_screen.dart:613](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L613)) — collapses below the 48dp touch min defined by `AppSpacing.touchMin`. *(Banner close buttons now use `touchMin` constraints with a "Dismiss" tooltip.)*
  - ✅ `TextButton` with `minimumSize: const Size(0, 32)` in rest-timer bar ([focus_rest_timer_bar.dart:78,87](mobile/lib/modules/focus_mode/widgets/focus_rest_timer_bar.dart)) — sweaty fingers will miss. *(Rest-timer buttons already at `AppSpacing.touchMin`.)*
- **Recommend (P1):** Audit for any interactive target < 48dp. Add `Semantics(label: ...)` to decorative-looking buttons. Hand-strength reduction is the lived reality between sets. *(Banner-close + rest-timer fixed. Broader `Semantics`/tooltip sweep across icon-only widgets still pending.)*

### 1.13 No pull-to-refresh except on Recent Sessions ✅ DONE
- **Where:** [recent_sessions_screen.dart:105](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L105) has `RefreshIndicator`; [workout_day_picker_screen.dart](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart) has only an AppBar refresh icon; [program_list_screen.dart](mobile/lib/modules/program_management/screens/program_list_screen.dart) has neither.
- **Recommend (P3):** Add `RefreshIndicator` to ProgramList and Day Picker. Mobile users expect it. *(Both screens now have `RefreshIndicator`. ProgramList got a new `ProgramListRefreshed` event so the list stays visible while reloading; Day Picker reuses the existing refresh event. Day Picker's AppBar refresh icon is kept for discoverability.)*

### 1.14 AppBar styling drifts ✅ DONE
- **Where:** [program_list_screen.dart:82-94](mobile/lib/modules/program_management/screens/program_list_screen.dart#L82-L94) sets `backgroundColor: colors.background` + `elevation: 0` explicitly; [workout_day_editor_screen.dart:203-205](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L203-L205) uses `colors.surface` instead. The theme already configures `AppBarTheme`, but screens overwrite it inconsistently.
- **Recommend (P3):** Remove per-screen `AppBar` color overrides; rely on `AppBarTheme` in `AppTheme._build`. Pick one — background for flat hierarchy, surface for elevated. *(All per-screen overrides removed: ProgramList, WorkoutDayEditor, and PlanImport now inherit `AppBarTheme` (background, flat).)*

### 1.15 No global "session in flight" indicator ✅ DONE
- **Where:** App-level
- **Problem:** If a user navigates away from an active session (back to Programs), there's no breadcrumb showing it's still active.
- **Recommend (P2):** Persistent bottom `Banner` (or `MaterialBanner`) when an active session exists: "<Day name> — tap to resume". Common in Spotify, Strong, Hevy, etc. *(Banner shipped; full root-level bottom nav left as a follow-up — see 1.1.)*

### 1.16 Confirmation dialog body text uses muted color ✅ DONE
- **Where:** [confirmation_dialog.dart:59](mobile/lib/modules/program_management/widgets/confirmation_dialog.dart#L59) — body in `colors.onSurfaceMuted`
- **Problem:** Destructive prose ("This cannot be undone") is the least readable text in the dialog. Should be `onSurface` for full contrast; the muted look reads as advisory rather than warning.
- **Recommend (P2):** `colors.onSurface` for body. Optionally tint with `error` only when `isDestructive`. *(Body now uses `onSurface`. Destructive-only error tint left as future polish.)*

---

## 2. Per-screen

### 2.1 ProgramListScreen — [file](mobile/lib/modules/program_management/screens/program_list_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | P2 | Tile shows only program name + raw ISO date. Add workout-day count and "last session: <relative date>" — high-density info that helps choose. |
| b | ✅ DONE | Date format `2026-05-16` ([program_list_tile.dart:133](mobile/lib/modules/program_management/widgets/program_list_tile.dart#L133)) is machine-friendly, not human. Use "Today", "Yesterday", "3 days ago", then date. *(`RelativeDateFormatter` promoted to [core](mobile/lib/core/relative_date_formatter.dart) and used by ProgramListTile — same labels as Recent Sessions / Day Picker.)* |
| c | P2 | Tap routes either to editor (if empty) or picker (if not) — magic-routing surprises users. Two distinct affordances: tile tap → picker, `>` chevron or Edit menu → editor. Or always go to picker with an empty-state "edit program" CTA. |
| d | P3 | Swipe-to-delete duplicates the popup menu's delete. Pick one. Swipe is faster; menu is more discoverable. Keep both only if you'd be willing to A/B test which one survives. |
| e | P2 | Import action is icon-only at top-right and emoji-poor. Surface it in the FAB as a speed-dial (`+` opens "New blank" / "Import from text"). |
| f | P3 | No search/sort. Becomes painful past ~10 programs. Add a top search field (M3 `SearchBar`) when count > 5. |
| g | P3 | FAB extended with "New program" — fine, but on small phones it collides with the last tile during scroll. Consider plain `FloatingActionButton` with tooltip once you add bottom nav. |

### 2.2 PlanImportScreen — [file](mobile/lib/modules/program_management/screens/plan_import_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | ✅ DONE | Blank text area with no placeholder / example format. New users will not know what syntax is expected. Add an expandable "See example" disclosure with a sample plan; or pre-fill the field with a commented template. *(Multiline monospace placeholder shows a 5-line template; expandable "See example format" panel below the input renders the full sample with a "Use this example" CTA that fills the field.)* |
| b | P2 | "Parse" button label is technical. Use "Preview" or "Import" — user mental model is "I'm importing a plan", not "I'm running a parser". |
| c | ✅ DONE | No "paste from clipboard" button. One-tap paste is friction-killer on mobile. *(Toolbar above the input now has a "Paste" `TextButton.icon` that reads the clipboard; falls back to a "Clipboard is empty" snackbar.)* |
| d | P3 | No "clear" button to wipe the field. |
| e | P3 | Failure banner appears under input but the Parse button moves down with it — slight layout jump. Pin the button. |

### 2.3 PlanPreviewScreen — [file](mobile/lib/modules/program_management/screens/plan_preview_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | P2 | Read-only preview forces the user into a full Edit cycle to make any adjustment. Allow inline edits to obvious fields (rename day, edit exercise name) before save. |
| b | P3 | Warning badges are small (icon 14, caption text). Consider a single "X warnings — review" summary at top that scrolls to first warning, with badges below. |
| c | P2 | "Discard" and "Save" both in AppBar — Discard is muted but still right next to a primary action. Move Discard to a `TextButton` left of Save, or to an overflow `IconButton`. |
| d | P3 | `_buildPreviewBody` shows program name as a single line — no metadata (day count, exercise count). |
| e | P3 | Saving overlay uses raw `Colors.black38` (see 1.11). |

### 2.4 ProgramEditorScreen — [file](mobile/lib/modules/program_management/screens/program_editor_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | P2 | Inline AppBar TextField for the name has no label, no background, no underline. On focus it's hard to tell editing is allowed (it just looks like a title). Add a faint underline on focus or a small pencil icon. |
| b | P2 | Auto-save with no visible confirmation: spinner appears, then vanishes. Add a "Saved" microcopy (1.5s) under the title or beside the spinner. |
| c | P2 | Tap-on-tile only navigates if `day.persistedId != null` — newly-added unsaved days silently do nothing on tap ([line 361](mobile/lib/modules/program_management/screens/program_editor_screen.dart#L361)). Disabled state should be visually obvious (greyed out, or wait-for-save indicator on the tile). |
| d | P2 | Add Workout Day dialog uses the global text style; submission errors only show on submit. Validate live (1–100 chars). |
| e | P3 | Workout day list uses `ReorderableListView` — drag handle position depends on the tile widget; verify it's discoverable from tile design ([workout_day_list_tile.dart](mobile/lib/modules/program_management/widgets/workout_day_list_tile.dart)). |

### 2.5 WorkoutDayEditorScreen — [file](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart) (981 lines — see 5.1)

| # | Severity | Finding |
|---|---|---|
| a | P1 | **Two competing gesture systems on the same tiles**: `ReorderableListView` provides the drag-to-reorder, and `LongPressDraggable` + `DragTarget` provide drag-to-create-superset. Long-press triggers the draggable; the reorder handle triggers reorder. This is the spec, but the affordance for "drag exercise A onto B = create superset" is invisible — no hint text, no shadow on drop targets until hover. Add a one-time tutorial overlay or an explicit "create superset" multi-select mode. |
| b | P2 | Add exercise dialog ([line 943](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L943)) uses underline `InputDecoration` while other dialogs use the filled outlined style from `inputDecorationTheme`. Inconsistent. |
| c | ✅ DONE | Empty-state icon is `Icons.fitness_center` (filled), but ProgramList / ProgramEditor use `Icons.fitness_center_outlined`. Pick one — outlined is more in line with M3 "default = outlined, selected = filled". *(Switched to `Icons.fitness_center_outlined`.)* |
| d | P2 | Swipe-left to delete an exercise → dialog → confirm → instant delete with no undo. With 4–8 exercises per day, accidental delete is common. Use undo snackbar (see 1.8). |
| e | P3 | `_findAncestorStateOfType<_WorkoutDayEditorScreenState>` ([line 340, 351](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart)) is a code smell; affects testability of the nav flow but invisible to user. |
| f | P2 | Superset card's inner `ReorderableListView` inside an outer `ReorderableListView` is a fragile pattern — nested scroll/drag behavior can be confusing (drag from inner can "leak" into outer). Consider a dedicated edit-superset modal instead of nested reorder. |
| g | P3 | "Ungroup superset" icon (`call_split`) is opaque. Add `tooltip` (it does) and consider a labeled button when there's vertical space. |
| h | P2 | Subtitle line on each exercise tile ([line 559](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L559)) shows summary like "60.0kg 4×8". For a long exercise list this is dense — bold the set count vs. weight, or use chips. |

### 2.6 ExerciseEditorScreen — [file](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | P1 | "Save" is in the top-right AppBar — for a scrollable form on a tall phone, the user has to scroll back up to save. Either (i) sticky bottom action bar (Save / Cancel), or (ii) auto-save on field blur like ProgramEditor. |
| b | ✅ DONE | Back gesture discards changes silently — no `PopScope` guard. Combined with (a), this is the most error-prone editor in the app. *(`PopScope` guard added to ExerciseEditor — see 1.9.)* |
| c | P2 | Planned rest is raw seconds with no suggestions. Add quick chips: 30s / 60s / 90s / 120s / 180s. |
| d | P2 | Video URL field: no preview, no validation hint. Show a YouTube thumbnail under the field when host matches yt domains. |
| e | P2 | "Add set" silently disables at 20. Show a small hint ("max 20 sets") when disabled. |
| f | P2 | Measurement type change triggers a confirmation dialog AFTER tap — destructive surprise. Instead, render the selector with an inline warning the moment the alternate type is highlighted, or block the change behind an explicit "Change measurement type" overflow action so it's not a one-tap mistake. |
| g | P3 | Saving overlay uses `colors.background.withValues(alpha: 0.6)` — fine, but combined with the in-place spinner, the form looks frozen. Add a "Saving exercise…" label or use a lightweight progress bar at top. |
| h | P3 | Notes is a 4-line TextField — fine, but no character counter visible until the user hits 2000 (silent failure to save until then). Add a "X / 2000" footer when > 1500. |
| i | P3 | Video URL `Open` icon uses a raw `Icons.open_in_new` with conditional color and no tooltip distinct from the field's own enabled state — easy to miss the disabled-vs-enabled difference. |

### 2.7 WorkoutDayPickerScreen — [file](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | ✅ DONE | The primary action — Start / Resume — is an **OutlinedButton** ([start_resume_action_button.dart:27](mobile/lib/modules/workout_day_picker/widgets/start_resume_action_button.dart#L27)). For the screen's top user goal, the button should be `FilledButton` (primary) and visually dominant. The Resume case in particular benefits from contrast (orange filled with white). *(Already a `FilledButton.icon` with `colors.primary` / `colors.onPrimary`.)* |
| b | ✅ DONE | No "today's suggested day" surfacing. Many programs follow a weekly rotation — show a tag "Last done: 3 days ago" → green "ready" / amber "soon" / grey "future" so the user picks without thinking. (`day_tile_history_labels.dart` already provides labels — extend with a recommendation badge.) |
| c | P2 | The AppBar refresh icon duplicates work `RefreshIndicator` could do. Add pull-to-refresh; consider hiding the AppBar refresh once added. |
| d | P3 | The transient error `MaterialBanner` (lines 247) pushes day tiles down on appearance — no animation. Use `AnimatedSwitcher` or replace with a `SnackBar`. |
| e | P3 | "Edit program" is reachable only from the empty state ([workout_day_picker_empty_view.dart](mobile/lib/modules/workout_day_picker/widgets/workout_day_picker_empty_view.dart)). Add an overflow menu (`⋮`) in AppBar with "Edit program", "Recent sessions", "Refresh". |
| f | P3 | Title is the program name, but loading state title is "Loading…" — flicker on every reopen. Use the last-known title as a skeleton title to avoid the jump. |

### 2.8 WorkoutOverviewScreen — [file](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | ✅ DONE | **No overall progress indicator.** During a session the user can't tell at a glance "I'm 3/9 exercises in, 40% done". Add a thin `LinearProgressIndicator` under the AppBar showing fraction of exercises completed, or a "3 of 9" pill in the title. *(AppBar title now stacks workout-day name above a `<done> of <total>` count derived from non-Unfinished exercises.)* |
| b | ✅ DONE | **No total session elapsed time.** Most workout apps show "00:42:13" — pace awareness is core to training. Put a small ticking timer in the AppBar (right side, before End-session icon). *(New `_SessionElapsedLabel` widget ticks every second from `session.startedAt`; freezes to `endedAt - startedAt` once the session ends. Format collapses to `mm:ss` under an hour, `H:mm:ss` above.)* |
| c | P1 | Drag-to-reorder via `_ReorderGap` (6px tall when idle) is **invisible**. Users won't discover it. Either (i) explicit "Reorder" mode toggle, or (ii) make the gap always show a faint dashed divider on the drag handle hover state. The card-onto-card "create superset" also lacks affordance — add a one-time tooltip. |
| d | P2 | Bottom action bar labels "Note" / "Extra" / "Focus" — "Extra" is jargon for "extra work". Either "Add extra" or an icon-only with a longer accessible label. |
| e | P2 | Exercise card's only expansion affordance is a small chevron in the actions row; tap target is the whole header. Make the chevron larger / animated to clarify "tap me". |
| f | P2 | "End session" icon (`stop_circle_outlined`) lives in AppBar — easy to accidentally hit. Add `tooltip` (it does) but also confirm with a count: "End session — N sets logged across M exercises". |
| g | P3 | `_GroupBuilder` ([line 378](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L378)) drags via long-press only (250ms) — slightly different feel from WorkoutDayEditor (default ~500ms). Pin via shared constant. |
| h | P2 | When the active set is below the fold, expanding it doesn't scroll-to-bring-into-view. Use `Scrollable.ensureVisible` on the active row. |
| i | P3 | Skipped exercises remain visible in the list with a "Skipped" badge but no way to *unskip* without restarting. Add an "Undo skip" action in the card's overflow. |
| j | P3 | Session-ended banner is informational — good. But the bottom action bar still shows "Focus" disabled silently. Hide it when ended. |

### 2.9 FocusModeScreen — [file](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart)

This is the **single most-used screen during a workout**. Highest stakes for one-handed usability.

| # | Severity | Finding |
|---|---|---|
| a | ✅ DONE | Entire screen is a `SingleChildScrollView`. During an active set the COMPLETE button can scroll out of view, defeating the one-handed reach goal. Pin the COMPLETE button + rest timer to the bottom in a fixed bar; let only the header / planned / panel scroll. |
| b | P1 | No keyboard shortcut to log a set with the hardware volume rocker (a category-standard feature: Strong, Hevy, FitNotes all support it). Sweaty hands struggle with on-screen taps. Use `HardwareKeyboard.instance.addHandler` or a platform channel for volume keys. |
| c | ✅ DONE | Rest timer bar buttons are 32px tall ([focus_rest_timer_bar.dart:78](mobile/lib/modules/focus_mode/widgets/focus_rest_timer_bar.dart#L78)) — below `AppSpacing.touchMin`. Mid-set hand tremor will misfire. Raise to 48dp. *(Already at `AppSpacing.touchMin` (48dp); banner close buttons in Overview + Focus also fixed.)* |
| d | ✅ DONE | The COMPLETE SET button is good — large, primary. But during *rest*, it remains the focal point even though the user is waiting. When `state.restTimer != null && !timer.isOvertime`, demote COMPLETE and elevate the rest timer (or replace COMPLETE with "SKIP REST → NEXT SET"). |
| e | P2 | "Up next: <name>" is small caption-style ([line 164](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L164)). It's the user's mental "what's coming?" — promote to bodySmall + an `Icons.arrow_forward` chip. |
| f | P2 | Undo last set is a small `TextButton.icon` aligned left ([line 187](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L187)). Industry standard is a transient SnackBar with "UNDO" for ~5s after logging. Move this to a snackbar (the current button can stay as a fallback after the snackbar expires). |
| g | P2 | Replace / Skip / Open Video live in `PopupMenuButton` (`⋮`) in the AppBar — three taps for "skip". For high-frequency actions, surface Skip as an icon next to the title (with confirmation). |
| h | P2 | Set progress pips ([focus_set_progress.dart](mobile/lib/modules/focus_mode/widgets/focus_set_progress.dart)) are 8x8 dots — beautiful but invisible at arm's length. Either thicken (12x12) or replace with a `LinearProgressIndicator` for ≥ 5 sets. |
| i | P2 | No "next exercise's first set" preview. After the last set of an exercise, the auto-advance is jarring. Show "Next: Bench Press 60kg × 8" for 1-2 sec before transitioning, with a swipe-to-skip-preview. |
| j | P3 | The bump buttons (`+2.5 / -2.5`) ([focus_rep_based_panel.dart:260](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L260)) are good but not labelled with the unit (just "+2.5"). Add "kg" or use the field label as context. |
| k | P3 | "Replaced from <name>" appears both in header and again in the planned/last block — duplicates the info. Pick one location (header is better). |
| l | P3 | Workout complete view is minimal — no stats (total volume, time, PRs). Strong/Hevy show a celebratory summary. Add 3 KPIs: sets logged, total volume, session duration. Optional confetti / sound. |
| m | P2 | Stopwatch for time-based exercises lives inside the panel ([focus_time_based_panel.dart](mobile/lib/modules/focus_mode/widgets/focus_time_based_panel.dart)) — verify start/stop is reachable with thumb and visually distinct from the rest timer (two clocks on the screen is risky). |

### 2.10 RecentSessionsScreen — [file](mobile/lib/modules/export/screens/recent_sessions_screen.dart)

| # | Severity | Finding |
|---|---|---|
| a | P2 | Title is "Recent sessions" — no program context. When the user has multiple programs and history, "Recent sessions — <program name>" is clearer (a 2nd-line subtitle works). |
| b | P2 | Bucketing: "This week" / "Earlier". With months of history this means an enormous "Earlier" list. Group by month (or by week). |
| c | P2 | Tile tap opens a formatted text bottom sheet — pure read-only. There's no graph, no PR badges, no "what was my best set". Even a simple "Top set: 80kg × 6" line per tile would add value. |
| d | P2 | "Export this week" is only available when `hasWeekSessions`. There's no equivalent "Export this month" / "Export all". |
| e | P3 | The empty state suggests "finish a workout from the day picker to see it here" — fine, but the user is already on a deep nav. Add a button "Go to day picker". |
| f | P3 | No filter / search (e.g., find a session containing "Bench Press"). |
| g | ✅ DONE | `_isoDate` is hand-rolled — use `intl` or extend the existing date helper for consistency with the ISO date in ProgramListTile. *(Single `DateFormatter.isoDate` helper in [date_formatter.dart](mobile/lib/core/date_formatter.dart) replaces four hand-rolled implementations across UI + domain export formatters.)* |

---

## 3. Interaction patterns

### 3.1 Drag-and-drop discoverability
- The app uses long-press drag to create supersets (overview) and to reorder/regroup exercises (day editor). Both rely on long-press, with no visual hint.
- **Recommend (P1):** Add a "?" / coach-mark first-run overlay or a "Reorder & group" mode toggle in the day editor app bar that highlights all drop targets.

### 3.2 Inline editing
- ProgramEditor's app-bar TextField (inline name) is great. The same idea should apply to WorkoutDayEditor (✓ it does, but with different styling — see 1.14) and could replace dialogs like "Add Workout Day" for an inline create-row pattern.

### 3.3 Mode switching (planning vs. executing)
- The Workout Overview and Focus Mode are both editable in different ways. Mental model "this screen logs values" can blur. Consider a subtle background-color shift when a session is **active** vs **ended**: e.g., a faint surface tint while live, plain when ended. Even 4% alpha of `primary` on the scaffold background communicates "you're in workout mode".

### 3.4 Snackbar conventions
- Snackbars are used for video failure / share failure / clipboard copy. They are not used for set logged, set undone, exercise skipped — moments where confirmation + undo would matter more.
- **Recommend (P2):** Standardize: every mutation visible in the session yields a snackbar with "Undo" when reversible.

### 3.5 Bottom sheets vs. full screens
- Export preview is a bottom sheet — great. Add Workout Day uses a centered AlertDialog — works, but on tall phones the on-screen keyboard pushes it awkwardly. Consider a bottom sheet with `useSafeArea` and `isScrollControlled: true` (like ExportPreviewSheet) for keyboard-paired inputs.

---

## 4. Visual & motion polish

### 4.1 No motion vocabulary
- The app uses Material defaults for route transitions. Consider:
  - `SharedAxisTransition` for sibling navigations (program → day picker)
  - Hero animations on program name (list → picker title) and exercise name (overview → focus)
  - Fade-through for empty-to-loaded states

### 4.2 Cards have flat 0-elevation borders only
- This is consistent across the app — clean. But the "active exercise card" in Overview should pop (e.g., a 2px primary-tinted border, or a faint elevation), helping the eye land. Currently the unfinished + next-target state is *identical visually* to skipped except for the badge.

### 4.3 State badges are pill chips
- Badges (`Done`, `Skipped`, `Replaced`) are tasteful. Add `In progress` for the exercise whose cursor is active — visual feedback that the engine is "on this one".

### 4.4 Numeric stability ✅ DONE
- `AppTypography.numeric` uses tabular figures — good. Verify it's used in **every** number-rendering location (set counts, rest seconds, weight chips). A grep for `fontFeatures` shows it's manually re-added in a few places ([workout_day_editor_screen.dart:638](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L638), [exercise_card.dart:275](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L275)) — those should adopt the token rather than reinventing it. *(No remaining `fontFeatures:` outside `AppTypography`.)*

### 4.5 Color encoding of "planned vs. actual"
- Tokens `planned` (muted) and `actual` (bright) exist and are used in SetRow + Focus. Excellent semantic system. Extend to Recent Sessions tiles when summarizing — "planned 100, did 105" would benefit from the same color story.

---

## 5. Architectural notes that hit UX

### 5.1 Massive screen files
- `workout_day_editor_screen.dart` (981 LOC), `workout_overview_screen.dart` (768), `focus_mode_screen.dart` (619), `exercise_editor_screen.dart` (573). These contain many private widgets — fine in isolation, but they encourage one-off polish (the inconsistencies in 1.4–1.16 emerge here).
- **Recommend (P3):** Extract per-screen private widgets to `widgets/_<name>.dart` files. Easier to maintain consistent style and add visual regression tests.

### 5.2 Per-screen `Theme.of(context).appColors` calls
- Every build pulls the colors. Minor cost, but consider a `ColorsExtension` mixin or a top-level `Builder`. Won't change UX directly but reduces rebuild cost for the most-redrawn surfaces (set-row editing, rest timer ticking).

### 5.3 BlocBuilders rebuilding entire screen body
- `BlocBuilder<FocusModeBloc, FocusModeState>` rebuilds the whole tree on each tick if the rest timer state is included. If the rest timer ticks every second and you see jank, switch to `BlocSelector` for the timer subtree only.

---

## 6. Suggested prioritization (first 2 weeks)

1. ✅ **Pin primary actions** in Focus Mode (a, c, d in 2.9). Single biggest perceived-quality win.
2. ✅ **Session in-flight banner / bottom nav** (1.1, 1.15). Unlocks "resume anywhere". *(banner shipped; full root-level bottom nav left as a follow-up.)*
3. ~~**Undo snackbars for set-level destructive actions** (1.8, 2.8i, 2.9f). Cuts dialog-fatigue.~~ *(not pursuing — see 1.8)*
4. ✅ **Back-press guard on editors** (1.9, 2.6b). Prevents lost work. *(Applied to ExerciseEditor + PlanPreview; ProgramEditor/WorkoutDayEditor auto-save so no guard needed.)*
5. ✅ **Touch-target audit** (1.12, 2.9c). Accessibility floor. *(Rest-timer + transient-error banner close buttons now at `AppSpacing.touchMin`; broader Semantics/tooltip sweep on decorative icons still pending.)*
6. ✅ **Day Picker primary button → FilledButton + recommendation badges** (2.7a–b). Front-door warmth.
7. ✅ **Hardcoded font/color cleanup** (1.10, 1.11). Sets up the rest of the polish work.

8. ✅ **Haptic feedback pass** (1.7). Centralised in [haptics.dart](mobile/lib/core/haptics.dart) and wired into Focus + Overview hot paths.
9. ✅ **Human-readable program-list dates** (2.1b). `RelativeDateFormatter` promoted to core.
10. ✅ **WorkoutOverview AppBar: progress count + elapsed timer** (2.8a, 2.8b). Pace and position visible at a glance.
11. ✅ **PlanImport onboarding: monospace placeholder + paste button + example disclosure** (2.2a, 2.2c). Removes the "blank page" first-run problem.

The remaining items (skeletons, motion, history grouping, etc.) are best done incrementally as those screens see updates — they're cheap individually but add up to a noticeably more refined product.

---

## 7. What's already good (don't break these)

- Strict semantic color/spacing/typography tokens with a lint-like check in CI — the foundation is excellent.
- `AppTypography.numeric` with tabular figures — correct for a workout app.
- `DayTile` skeleton loading — extend, don't replace.
- Bloc state machines map cleanly to UI states (loaded/loading/error/notFound) — the consistent switch-on-state pattern is testable and predictable.
- Snapshot/planned-vs-actual color encoding is unique and useful — most fitness apps muddle this.
- `DomainErrorPresenter` centralizes error copy — this is the right hook to standardize all error views around (see 1.6).
