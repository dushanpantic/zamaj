# Zamaj UI/UX Improvements — Deep Dive

A screen-by-screen audit of the mobile app against mobile UI/UX best practices for one-handed, gym-floor use. References point to current code so each recommendation is grounded in a concrete file/line.

The app is in a strong place: design tokens are centralized, semantic colors exist, tap targets are gated at 48 dp via [AppSpacing.touchMin](mobile/lib/core/app_spacing.dart#L15), tabular figures are wired for numerics, dark-first palette, and haptics are stubbed in. The bullets below are about turning that solid scaffolding into a more forgiving, fast, and self-explanatory experience under real gym conditions (sweat, gloves, sunlight, divided attention, screen-locked phone in pocket).

---

## 0. Cross-cutting principles to optimize for

Most of the screen-level recommendations later boil down to one of these. Calling them out so the rationale is reusable:

1. **One-handed reachability.** Sweat + plates + chalk means users tap with a thumb while the other hand is occupied. Primary actions belong in the bottom third of the screen.
2. **Forgiveness over confirmation.** Every "Are you sure?" interrupts the flow. Prefer optimistic actions + undo (snackbar) for anything reversible.
3. **At-a-glance numerics.** During a heavy set, the user shouldn't read prose; weight, reps, planned vs. actual, set N/M should be scannable from arm's length.
4. **Don't lose focus to the keyboard.** Numeric input on Android/iOS pops a keyboard that covers the LOG button. Either avoid the keyboard (steppers) or move LOG above the keyboard.
5. **Stay-awake + screen-on.** A workout app whose screen dims mid-rest is broken. Wakelock during active sessions is table stakes.
6. **Audible/haptic feedback for blind interactions.** When the phone is on a bench, the user must hear "rest done" without looking.

---

## 1. Global / cross-app concerns

### 1.1 Wakelock during active sessions (critical, missing)
Nothing in [focus_mode_screen.dart](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart) or [workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart) keeps the screen awake. A user mid-set will see the phone lock between sets when the rest timer is most useful. Add `wakelock_plus` (offline-safe, no networking) and acquire it whenever an active session is in scope, release on end/pop.

### 1.2 No bottom navigation, no clear "home"
The app's root is `ProgramList`. Reaching the recent-sessions list requires drilling into a program first via the AppBar history icon at [workout_day_picker_screen.dart:122-126](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L122). Consider either:
- A 2-tab `BottomNavigationBar` (Programs / History) at the root, or
- A persistent global "History" entry point in the AppBar of `ProgramListScreen`.

This becomes more pressing once users have a single "current" program — they will navigate to history more than to the program editor.

### 1.3 Light theme is declared but recommended-default is dark
[app_theme.dart:8-12](mobile/lib/core/app_theme.dart#L8) documents `ThemeMode.dark` as the default. Verify the `MaterialApp` wiring actually does this and that `ThemeMode.system` isn't quietly opted-in. Gyms are dark, screens are bright; honoring system is a worse default here than usual. Add a settings affordance later, but ship dark.

### 1.4 No "system" font-scale stress test
With `AppTypography.numericHero` at 44pt, larger system text scales will overflow the rep/weight rows in [focus_rep_based_panel.dart:159](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L139-L158). Either:
- Wrap the two-column `kg × reps` row in `FittedBox`/auto-shrinking text, or
- Cap the text-scale-factor for these specific widgets via `MediaQuery.withClampedTextScaling`.

### 1.5 Haptics are wired but minimal
[Haptics.tap/grab/emphasis](mobile/lib/core/haptics.dart) is invoked only on log/drag/rest-overtime. Add:
- A `Haptics.warning` on destructive confirms (skip, delete) — telegraphs the action before the user reads the dialog.
- A heavier vibration when the rest timer crosses zero, on top of the `emphasis` already there — most users miss the visual color flip while loading a plate. (Today's overtime trigger lives at [focus_mode_screen.dart:54-56](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L53-L56).)

### 1.6 No sound option for rest timer
Vibration alone is insufficient when the phone is on a bench across the room. Add an optional rest-finished chime (system default sound, no asset shipped) with a persistent setting. Critical for circuit/timer-based workouts.

### 1.7 Status of "loading" is uniform but uninformative
Every screen drops to a centered `CircularProgressIndicator` (e.g. [_LoadingView in focus_mode_screen.dart:793-801](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L793-L801), [program_list_screen.dart:163-172](mobile/lib/modules/program_management/screens/program_list_screen.dart#L163-L172)). The `DayTile` already has a nicer skeleton shimmer pattern at [day_tile.dart:183-215](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L183-L215). Hoist the skeleton concept into a shared building block and use it on `ProgramList`, `RecentSessionsScreen`, and `WorkoutOverview` initial loads so the user sees the *shape* of what's coming.

### 1.8 Empty-state CTAs vary
Compare:
- [Program list empty view](mobile/lib/modules/program_management/screens/program_list_screen.dart#L217-L274): icon + headline + secondary line + two full-width buttons. Good.
- [Workout day editor empty view](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L295-L319): icon + "tap + to add one." No button.
- [Recent sessions empty view](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L183-L217): icon + two-line copy. No action.

Standardize: every empty state has (icon, heading, supporting copy, primary action). The "tap the +" guidance in the workout-day editor is especially weak — the user has to look up at the AppBar.

### 1.9 Error banners use three slightly different visual treatments
- [WorkoutOverview _TransientErrorBanner](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L611-L669): rounded card with icon + title + body + dismiss.
- [FocusMode _TransientErrorBanner](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L879-L931): same idea, slightly different padding.
- [WorkoutDayPicker _TransientErrorBanner](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L244-L262): MaterialBanner (full-width, sharp corners, "OK" not "Dismiss").
- [WorkoutDayEditor _SaveErrorBanner](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L882-L913): flat tinted strip, no dismiss.

Extract a single `AppErrorBanner` widget; reuse everywhere. Right now the visual language for "something failed" shifts based on which module you're in.

### 1.10 Snackbars use default Material treatment
[workout_overview_screen.dart:45-47](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L45-L47) and [plan_import_screen.dart:64-66](mobile/lib/modules/program_management/screens/plan_import_screen.dart#L64-L66) use plain `SnackBar(content: Text(...))`. The theme styles the surface, but snackbars are *the* mechanism for undo. Build an `AppSnackbar.show(...)` helper that:
- Tints success vs. error vs. neutral.
- Always offers an action slot (defaults to dismiss).
- Has a longer duration for destructive actions you want undone (6 s vs default 4 s).

### 1.11 No app-wide undo for skip/delete-set
Confirmation dialogs are everywhere ([workout_overview_screen.dart:80-93](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L79-L93), [focus_mode_screen.dart:697-710](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L697-L710)). They're modal, they interrupt flow, and they kill momentum. Focus Mode already has the right pattern with [_UndoLastSetButton](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L571-L598): act first, undo within ~10 s. Extend it to:
- Skip exercise → snackbar with Undo.
- Delete planned set in editor.
- Delete program / workout day (with longer undo window).

Keep dialogs only for truly destructive operations the engine can't undo.

### 1.12 Drag-and-drop is the only way to create a superset
[workout_overview_screen.dart:481-535](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L481-L535) requires long-press-drag-onto-another-exercise. This is discoverable for power users but invisible to first-timers. Add a "Group with previous" / "Group with next" action to the exercise card overflow menu so the same operation is keyboard/screen-reader reachable.

### 1.13 Reorder gaps are 6 px tall and invisible
[_ReorderGap](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L570-L609) is only 6 px tall when idle and provides no affordance hint. Most users will think drag-onto-card is the only target. Either:
- Show a faint dashed line on hover/long-press, or
- Make the gap interactive only after a drag starts (it is — but it's invisible until then).

A subtle ghost-line that fades in *while* a drag is active would solve discoverability without permanent visual debt.

### 1.14 No global "what changed" toast on session end
After "End session" the screen stays put but data becomes read-only ([_SessionEndedBanner](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L671-L708)). A confirmation snackbar — "Session saved · X sets across Y exercises" — would close the loop and prompt the user to navigate to recent sessions.

### 1.15 Accessibility / semantics
- Numeric `Text(... typography.numericHero ...)` widgets are scattered without `Semantics(label: 'Weight, 100 kg')`. Screen readers read the bare number; pair every numeric readout with a semantic label.
- Bump buttons in [focus_rep_based_panel.dart:256-291](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L256-L291) are buttons with only `+2.5` text. Add `tooltip` or `Semantics(label: 'Increase weight by 2.5 kg')`.
- Drag targets and reorder handles have no `Semantics` actions. Reorder via screen reader is currently impossible.

### 1.16 Color contrast
- `loggableHint` background uses `alpha: 0.08` over `surface` ([set_row.dart:249-260](mobile/lib/modules/workout_overview/widgets/set_row.dart#L249-L260)) — the highlight is so subtle it's nearly invisible in well-lit gyms. Bump to 0.14–0.18.
- `colors.planned` is `0xFF9A9AA6` on a `0xFF17171C` surface. Contrast ratio ~5.5:1 — passes AA for body but only just; tabular planned summaries at `caption` (12 pt) sit close to the AA boundary. Either bump weight to 500 or pick a lighter planned color.

---

## 2. Program List screen

[program_list_screen.dart](mobile/lib/modules/program_management/screens/program_list_screen.dart)

### 2.1 The "Programs" header lacks search/filter
Once a user has more than ~6 programs the FAB-and-list pattern starts to fail. Add a `SliverAppBar` with a built-in search field. Even simpler: collapse the AppBar title to a search input on scroll. Not urgent for MVP, but the screen is structurally ready for it.

### 2.2 Tap behavior is inconsistent when a program has 0 workout days
[program_list_screen.dart:133-144](mobile/lib/modules/program_management/screens/program_list_screen.dart#L133-L144) routes 0-day programs to the editor, others to the picker. Useful but invisible. Show a small "empty" badge or a dim "0 days" label on those tiles so users understand why tap-behavior differs.

### 2.3 The list tile shows only `updatedAt`
[program_list_tile.dart:57-62](mobile/lib/modules/program_management/widgets/program_list_tile.dart#L57-L62) shows the last-updated date but not workout-day count or last-session date. For most users "when did I last *do* this?" is more meaningful than "when did I last *edit* this?". Add a line like `4 days · last session 2 days ago`.

### 2.4 Dismiss-to-delete is confusing
[program_list_tile.dart:114-131](mobile/lib/modules/program_management/widgets/program_list_tile.dart#L114-L131) wraps the whole tile in a `Dismissible` that, on confirm, *opens a dialog* and never actually dismisses. The user sees the tile fall back into place after the swipe even on the confirm path. Either:
- Actually animate the tile out optimistically and rely on snackbar-undo (see 1.11), or
- Drop the swipe gesture and lean on the overflow menu, which already has Delete.

The current half-implementation is the worst of both.

### 2.5 The FAB hides the last row
"New program" extended FAB sits over the last list tile when scrolled. The bottom padding at [program_list_screen.dart:298-303](mobile/lib/modules/program_management/screens/program_list_screen.dart#L298-L303) is `xxxl` (48) but the extended FAB is ~56 high plus margin. Bump to `xxxl + xl` or use `Scaffold.floatingActionButtonLocation` + `SafeArea` accounting.

---

## 3. Workout Day Picker

[workout_day_picker_screen.dart](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart) + [day_tile.dart](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart)

### 3.1 The Start/Resume button shares a column with the title
[day_tile.dart:131-141](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L131-L141) puts the action in a fixed 120 px trailing column. With long day names + a recommendation badge + history labels, the tile gets cramped. Consider:
- Move the primary action to the **bottom-right** corner of the tile (so the title can take the full row width), or
- Render Resume as a wider button-row at the bottom of the tile when an `activeSessionId` exists (because "resume" is much more important than "start").

### 3.2 No visual hint that pulling refreshes
[workout_day_picker_screen.dart:209-237](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L209-L237) wires `RefreshIndicator` but also shows a Refresh icon in the AppBar. Two affordances for the same action is fine, but a first-time user only learns about the pull gesture by accident. Add a one-time hint or rely solely on the AppBar action.

### 3.3 AppBar shows program name as title but no breadcrumb
After deep-linking from `SessionInFlightBanner`, the user may have skipped `ProgramList`. The `Loading…` placeholder ([line 144](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L144)) is fine, but once loaded showing only `program.name` makes "where am I?" ambiguous. Add a `Text('Workout day', style: caption)` super-label above the program name.

### 3.4 Day recommendation badge is opaque
[day_recommendation_badge.dart](mobile/lib/modules/workout_day_picker/widgets/day_recommendation_badge.dart) — I didn't pull this open, but if the badge says "Recommended" without explaining why, add an optional tap-for-tooltip with the heuristic ("Hasn't been done in 7 days", "Most-skipped this week").

---

## 4. Workout Overview screen

[workout_overview_screen.dart](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart)

### 4.1 AppBar status line is good — extend it
[_LoadedAppBarTitle](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L778-L832) shows `done of total · mm:ss`. Excellent. Add a thin `LinearProgressIndicator` directly under the AppBar showing `done/total` — a glance at the top edge of the screen tells the user how far they are without reading numbers. (Today the only progress bar is `mutationInFlight` at [line 351-357](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L351-L357), which collides with this idea — choose one mode at a time.)

### 4.2 Bottom action bar weights `Focus` at 2× (good) but the labels are cramped
[_BottomActionBar](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L710-L773) uses `Note`/`Extra`/`Focus`. On a 360 dp screen the Note/Extra buttons are ~80 dp wide, with an icon and a 4-char label. Lose the icons on those two and keep them only on `Focus`, or make the bar two rows.

### 4.3 End-session is a tiny icon
[workout_overview_screen.dart:187-194](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L186-L194) puts the end-session button in the AppBar as a `stop_circle_outlined`. It's the highest-stakes action on the screen yet has the smallest target and lives at the top. After session is ended state changes dramatically (read-only); consider:
- Render it as a full-width button in the bottom action bar when the session has ≥1 logged set, or
- Add a secondary "End session" pill below the AppBar status line.

### 4.4 Drag-handle ergonomics
[exercise_card.dart:175-185](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L175-L185) renders a 20 px `drag_indicator` on the left edge. Looks like an affordance, but the entire card is the drag target (long-press anywhere). Either:
- Make only the drag handle initiate a drag (`ReorderableDragStartListener`) — explicit, but easier for novices.
- Or remove the visual handle and rely on long-press, with a one-time toast: "Long-press to reorder."

The current state is a half-affordance: it *looks* like a tap target but isn't one. The handle column is also too narrow for thumb-targeting.

### 4.5 "Mark done" semantics need surfacing
The button only appears once at least one set is logged ([exercise_card.dart:85-86](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L85-L86)). The label and dialog body ([workout_overview_screen.dart:95-109](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L95-L109)) say "Locks ... with the sets you have already logged." Good. But:
- The state badge `Done` (green pill) is identical whether the user logged 3/3 or 1/3 — bad signal. Show `Done · 1/3` for partial completions.
- Consider auto-marking-done when the user completes the last planned set (with snackbar undo). Right now finishing the last set still leaves the exercise as `Unfinished` until they tap something. This is a frequent annoyance.

### 4.6 SetRow editor opens in-place on tap of completed sets
[set_row.dart:265-269](mobile/lib/modules/workout_overview/widgets/set_row.dart#L265-L269): tapping a completed row toggles an inline editor. Editor exposes weight + reps + LOG/SAVE. On phones with notches/keyboards, the editor opens beneath but the LOG button gets covered by the soft keyboard. Either:
- Use a bottom-sheet for edits-after-the-fact, or
- Add `Scaffold(resizeToAvoidBottomInset: true)` if not already, and ensure the editor scrolls into view on focus (`ensureVisible`).

### 4.7 Loggable highlight is too subtle
[set_row.dart:249-260](mobile/lib/modules/workout_overview/widgets/set_row.dart#L249-L260) uses an 0.08-alpha background and 0.35-alpha border on `loggableHint`. In a sunlit gym, this is invisible. See 1.16.

### 4.8 "Tap to log" copy on the actual column doubles the affordance
The status column already shows a "next" icon and the editor is already expanded inline ([set_row.dart:204-210](mobile/lib/modules/workout_overview/widgets/set_row.dart#L204-L210) — `showEditor` for loggable mode is always true when `canMutate`). The "Tap to log" text at [set_row.dart:349](mobile/lib/modules/workout_overview/widgets/set_row.dart#L349) is misleading since the inputs are already there; replace with the suggested values, or the planned values dimmed.

### 4.9 Step buttons next to text field create a 3-row stack
[set_row.dart:556-602](mobile/lib/modules/workout_overview/widgets/set_row.dart#L556-L602) — text field + 2 steppers + LOG SET. Vertically this is ~180 px per row, with 2 fields side-by-side. Reasonable. But the focus-mode editor at [focus_rep_based_panel.dart](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart) takes the same screen real estate and renders much larger. Pick one: either the inline overview editor is the cramped one or it isn't, but the visual difference is jarring when comparing the same set inside vs. outside Focus.

### 4.10 Reorder gaps + drag targets on cards conflict semantically
Dropping onto a card creates a superset ([workout_overview_screen.dart:507-516](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L500-L516)); dropping on a gap reorders ([line 583-594](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L583-L594)). The visual difference between the two drop zones at hover time is faint: gap expands from 6→18 px and tints primary; card scales to 0.98. Make the difference louder:
- Card gets a dashed primary border with "Group" overlay text.
- Gap shows a solid primary bar with "Reorder here" overlay.

### 4.11 No way to delete a session note
[notes_section.dart:131-162](mobile/lib/modules/workout_overview/widgets/notes_section.dart#L131-L162) renders notes as bullet items with no actions. If the user mis-types, they can't fix it. Add long-press → delete (snackbar undo).

### 4.12 Session-ended banner sits inside the scroll view
[workout_overview_screen.dart:285-286](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L285-L286) emits the banner as a `SliverToBoxAdapter`. Once the user scrolls down it disappears, and the AppBar still shows the ticking elapsed timer — which is frozen but reads as live unless the user looks twice. Promote the banner to a non-scrolling pinned slot below the AppBar.

---

## 5. Focus Mode screen

[focus_mode_screen.dart](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart) — the highest-leverage screen in the app.

### 5.1 LOG SET button is *below* the editor, *below* the keyboard
[focus_mode_screen.dart:493-516](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L493-L516) places `_PanelCompleteButton` at the bottom of the panel column, inside the scroll view. When the user taps a numeric field, the keyboard slides up and covers LOG SET. The user has to:
1. Type the value.
2. Dismiss the keyboard (tap outside).
3. Tap LOG SET.

This is one extra tap per set, every set. Fixes:
- Pin LOG SET to the bottom of the screen (like `_PinnedBottomBar` for rest/undo).
- Or attach LOG SET to the keyboard toolbar via `Form.flush` + a custom `keyboardActions` row.
- Or — best — eliminate the keyboard entirely by relying on steppers (1.4); the text field is a fallback and should require an explicit "Edit" tap.

### 5.2 The big numeric "edit" field is too easy to focus accidentally
[focus_rep_based_panel.dart:127-156](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L127-L156) makes the entire weight/reps numeric a `TextField`. Tapping the number raises the keyboard. With chalky fingers and the field as the most visually prominent element, accidental focus is common. Consider:
- Display the number as `Text` by default; show an `IconButton(edit)` adjacent that opens the keyboard explicitly, or
- Make the bump buttons primary (large), and put manual editing behind a small "..." menu.

### 5.3 The kg ×reps cross is decorative; align numbers as a single readout
[focus_rep_based_panel.dart:138-145](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L138-L143) renders `×` between two equally-weighted columns. Visual weight is balanced when the *actual* importance is asymmetric: reps move every set, weight is occasionally bumped. Make weight the dominant column (bigger), reps secondary; the `×` becomes a hint, not a label.

### 5.4 Planned vs. last values are buried below the editor
[_PlannedAndLast](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L338-L418) shows two small rows of caption-label + numeric. These are the *target* — the most important reference the user needs while logging. Put them *above* the editor (header area), make them tappable to seed the editor ("Use last set's values"), and make `Last` more visually different from `Planned` (today both use `numeric` style at the same size).

### 5.5 "Up next" is text-only, far from the primary action
[focus_mode_screen.dart:173-184](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L173-L184) shows "Up next: Exercise X" as small caption text below the panel. Most fitness apps put it as a slim card with the next exercise's name + planned target, optionally tappable to jump. Currently it's purely informational. Make it a `FocusUpNext` card with a small "Jump →" button if tap-to-skip is desired.

### 5.6 Switch-exercise affordance is a popup menu
[_SwitchExerciseButton](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L746-L791) opens an `ActionSheet`-like popup. With 10+ exercises this becomes a tall list and one-handed reachability dies. Consider:
- A swipe-left/right gesture on the panel card to move between exercises (with haptic), or
- A horizontal mini-strip at the top with dots/avatars per exercise.

### 5.7 Stopwatch UI: START/STOP color flips dramatically
[focus_time_based_panel.dart:159-176](mobile/lib/modules/focus_mode/widgets/focus_time_based_panel.dart#L159-L176) — start is primary orange, stop is error red. The error red on STOP implies "danger" — but stop is the normal, expected action. Use `success` or neutral surface for stop. Reserve `error` for actual destructive states.

### 5.8 Stopwatch text field is disabled while running
[focus_time_based_panel.dart:194-220](mobile/lib/modules/focus_mode/widgets/focus_time_based_panel.dart#L194-L220) disables manual edit during a run. Fine, but the field is greyed in a way that looks broken. Either visually replace it with a centered "Recording…" pill or maintain the same readout that's already at the hero text above.

### 5.9 Add-weight toggle for time-based is a small text button
[focus_time_based_panel.dart:331-343](mobile/lib/modules/focus_mode/widgets/focus_time_based_panel.dart#L331-L342) — "Add weight" sits at the bottom as a small icon+label. For weighted dips/pull-ups (a common case) the user has to scroll-find this. Promote to a toggle chip near the duration row.

### 5.10 Rest timer bar's `+15` is fixed
[focus_rest_timer_bar.dart:74-82](mobile/lib/modules/focus_mode/widgets/focus_rest_timer_bar.dart#L74-L82) only offers +15. Most lifters want +30 or +60. Either add an additional button or long-press for +60. (Don't add a dialog — preserve the one-tap flow.)

### 5.11 No visual rest-progress
The rest bar shows mm:ss + a label. Add a thin progress arc / linear bar showing elapsed-vs-planned so the user sees "almost there" peripherally without reading numbers. Today's color hint (orange → red on overtime) is binary.

### 5.12 Replace-exercise dialog is opaque about defaults
The dialog defaults to the planned values ([replace_exercise_dialog.dart](mobile/lib/modules/workout_overview/widgets/replace_exercise_dialog.dart) via [_handleReplace at focus_mode_screen.dart:670-695](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L670-L695)). For users substituting "DB bench" with "BB bench" the planned weight is rarely transferable. Show a "From: original" + "To: substitute" comparison and pre-fill the substitute side blank by default — make picking the values an explicit decision, not a one-tap-accept.

### 5.13 No keyboard-aware bottom inset for the pinned bar
[_PinnedBottomBar](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L520-L569) doesn't wrap in `SafeArea` or `MediaQuery.viewInsets`. When the keyboard opens, the rest timer + undo button can be pushed off-screen on certain devices. Verify with the iOS simulator + Android API 33+.

---

## 6. Program editor

[program_editor_screen.dart](mobile/lib/modules/program_management/screens/program_editor_screen.dart)

### 6.1 Program name lives in the AppBar as a TextField
[program_editor_screen.dart:268-308](mobile/lib/modules/program_management/screens/program_editor_screen.dart#L268-L308). On most platforms a TextField in an AppBar has cramped vertical bounds and odd hit areas. The hint vs. the entered value share the same typography, so the field looks unfocused even when active. Consider:
- Move the name field into a dedicated header row below the AppBar.
- Keep the AppBar title as the current name (or "New program" placeholder), and tap-to-edit jumps focus.

### 6.2 Saving status is a single 16 px spinner
[program_editor_screen.dart:292-305](mobile/lib/modules/program_management/screens/program_editor_screen.dart#L292-L305) — easy to miss. Combine with an absolute-positioned status: "Saved · just now" / "Saving…" / "Failed to save" in the AppBar caption slot.

### 6.3 No "rename day" affordance in the list
[program_editor_screen.dart:362-374](mobile/lib/modules/program_management/screens/program_editor_screen.dart#L362-L374) — workout day tiles navigate to the day editor on tap (where rename happens). Long-press could surface rename + delete inline.

### 6.4 The "Add Workout Day" dialog is custom-built
[program_editor_screen.dart:53-110](mobile/lib/modules/program_management/screens/program_editor_screen.dart#L53-L110) reimplements an AlertDialog with manual error styling. Replace with the existing `TextEntryDialog` pattern (or generalize the one in [workout_overview](mobile/lib/modules/workout_overview/widgets/text_entry_dialog.dart)). One dialog API for the whole app.

### 6.5 Drag-to-reorder days uses Material's `ReorderableListView`
Default Material reorder long-press is heavy and noisy. The handle is the entire tile. Consider adding an explicit `ReorderableDragStartListener` on the tile's drag handle so taps on the body navigate without risk of grabbing.

---

## 7. Workout day editor

[workout_day_editor_screen.dart](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart)

### 7.1 Two reorder mechanisms on the same screen
[workout_day_editor_screen.dart:321-360](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L321-L360) uses `ReorderableListView` for groups. Inside a superset card ([line 721-873](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L721-L873)) there's a *nested* `ReorderableListView` plus a `LongPressDraggable` + `DragTarget` for cross-group drags. Three reorder paradigms in one screen. Pick one:
- Keep `ReorderableListView` for in-list ordering.
- Use the drag-to-group only for forming supersets.
- Move ungrouping into the superset header (already done at [line 703-717](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L703-L717)).

The current state is power-user-only.

### 7.2 Swipe-to-delete on exercise rows uses red background but the gesture isn't telegraphed
[workout_day_editor_screen.dart:427-461](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L427-L461) — `Dismissible` with `endToStart` direction. No leading peek/hint. First-time discovery is zero. Same issue as in [program_list_tile.dart](mobile/lib/modules/program_management/widgets/program_list_tile.dart).

### 7.3 Saving spinner in AppBar steals an icon slot
[workout_day_editor_screen.dart:208-220](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L208-L220) — fine, but the "+" icon next to it is a similar size. Saving and Add visually compete. Make Saving a non-interactive caption ("Saving…") instead of a spinner-icon.

### 7.4 Quick-add dialog has no measurement-type choice
[_AddExerciseDialog](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L915-L979) only takes a name. The exercise lands as rep-based by default. Add a small toggle for rep / time, or, since the user has to open the exercise editor anyway, label that flow: "Add → fill details on next screen."

### 7.5 The validation banner doesn't tell the user *what's wrong*
[_SaveErrorBanner](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L882-L913) says "Failed to save. Please try again." — generic. Use the existing `DomainErrorPresenter` (used elsewhere) to surface field-specific reasons.

---

## 8. Exercise editor

[exercise_editor_screen.dart](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart)

### 8.1 Save button lives in the AppBar as a TextButton
[exercise_editor_screen.dart:336-355](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L336-L355) — small target, far from the form. For mobile, prefer a bottom-anchored save bar that's always reachable while scrolling through long forms (this one has 5+ fields plus a set list).

### 8.2 "Discard changes?" pops on any back gesture, even if nothing changed
[exercise_editor_screen.dart:243-247](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L243-L247) — `canPop: !bloc.isDirty` is correct; verify `isDirty` is false on initial load and stays false until the user actually types. The `autofocus: true` on the name field at [line 417](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L417) makes the keyboard pop immediately; combined with `isDirty=true` from any keystroke (incl. accidental), the user can't back out without a dialog.

### 8.3 Measurement type switch is hidden inside a confirm dialog
[exercise_editor_screen.dart:88-123](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L88-L123) — switching rep ↔ time wipes all planned values and triggers a confirm dialog. Right behavior, wrong surface: change the selector to render `Disabled (would clear N sets) — tap to switch` so the user sees the cost before tapping.

### 8.4 Reorderable set rows + delete-via-icon
[exercise_editor_screen.dart:451-508](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L451-L508) — `ReorderableListView` with delete + duplicate icons in each row. The drag handle isn't separated from the body, so any long-press starts reorder. Add an explicit handle.

### 8.5 The notes field uses 4 lines, no character counter
[exercise_editor_screen.dart:532-546](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L532-L546) — 2000-char limit per validation but no counter. Add `buildCounter` (it's hidden on the day-name field at [workout_day_editor_screen.dart:279-281](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L279-L281), so the pattern is known) and show it at, say, 1800 characters onward.

### 8.6 Video URL open button is far from the field
The icon to open the video is rendered to the right of the field ([exercise_editor_screen.dart:572-591](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart#L572-L591)). On RTL/narrow screens this gets cramped. Use a suffix icon inside the `InputDecoration` so the affordance is clearly part of the field.

---

## 9. Plan Import / Preview

[plan_import_screen.dart](mobile/lib/modules/program_management/screens/plan_import_screen.dart) + [plan_preview_screen.dart](mobile/lib/modules/program_management/screens/plan_preview_screen.dart)

### 9.1 The plan-text field has no syntax help inline
[plan_import_screen.dart:114-122](mobile/lib/modules/program_management/screens/plan_import_screen.dart#L114-L122) — the "Paste or type your plan" header is descriptive but minimal. The example is hidden behind a disclosure. New users will fail their first attempt without opening the example. Options:
- Auto-expand the example on the first load (collapse after they type), or
- Use a multi-line `decoration.hintText` showing the format inline.

### 9.2 Errors land below the field with no jump
[plan_parse_error_banner.dart](mobile/lib/modules/program_management/widgets/plan_parse_error_banner.dart) (didn't open) renders at [plan_import_screen.dart:123-127](mobile/lib/modules/program_management/screens/plan_import_screen.dart#L123-L127). When the text is long, the user may not see the error. Consider:
- Scrolling the error into view on appear.
- Highlighting the offending line in the text input itself (line + column from the parser).

### 9.3 Plan preview lacks "Edit before saving"
[plan_preview_screen.dart](mobile/lib/modules/program_management/screens/plan_preview_screen.dart) is read-only — only Save / Discard. If the parser misinterprets a line, the user has to discard, edit, re-parse. Add inline edits (or at minimum a "Back" that returns to the import screen with the same text preserved).

### 9.4 Warning chips don't link to the source line
[plan_preview_screen.dart:357-403](mobile/lib/modules/program_management/screens/plan_preview_screen.dart#L357-L403) shows a warning per exercise but no line number. The parser must know the line; surface it as `Line 7: Invalid rest token "2hr"`.

---

## 10. Recent Sessions / History

[recent_sessions_screen.dart](mobile/lib/modules/export/screens/recent_sessions_screen.dart)

### 10.1 Two flat sections, no calendar view
"This week" + "Earlier" is the minimum. Heavy users will want a month-at-a-glance heatmap. Defer to v2, but the screen has room for it.

### 10.2 Tile tap opens an export sheet, not a session detail
[recent_sessions_screen.dart:148-162](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L148-L162) — tapping a past session opens a *text export preview*. This is surprising. Users expect tap-on-session = "see what I did". The export should be a secondary action (icon in the corner, swipe action, or overflow menu).

### 10.3 Week export icon-only in AppBar
[recent_sessions_screen.dart:29-37](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L29-L37) uses `Icons.calendar_view_week`. Icon alone is opaque. Either add `tooltip` (it does) and a long-press text fallback, or use an `IconButton.extended` with the label "Export week".

### 10.4 Pull-to-refresh only when items exist
[recent_sessions_screen.dart:91-93](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L91-L93) skips the `RefreshIndicator` for the empty view. After completing a session and returning here, an empty state may be stale; allow pulling on the empty state too.

---

## 11. Misc widgets

### 11.1 `ConfirmationDialog` always uses two `TextButton`s with the same visual weight
[confirmation_dialog.dart:61-78](mobile/lib/modules/program_management/widgets/confirmation_dialog.dart#L61-L78). Destructive actions should use `FilledButton` with `error` background so the user can't tap-through-confirm. The current pattern: both buttons look like text, only color differs. On a tilted phone in a bright gym the color is hard to distinguish.

### 11.2 Drag-feedback uses `Material(elevation: 6)`
[workout_overview_screen.dart:555-563](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L555-L563) renders the dragged card with elevation but the same width — useful. But on iOS the shadow looks Android-y. Use `BoxShadow` from the theme or wrap in `CupertinoTheme` for platform-correct feedback. Cosmetic, defer.

### 11.3 Numeric formatting differs by site
[set_row.dart:340-345](mobile/lib/modules/workout_overview/widgets/set_row.dart#L339-L345) shows actual rep-based values as `"${weight} × $reps"` without `kg` suffix; [focus_mode_screen.dart:411](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L411) shows the same data as `"${weight}kg × $reps"`. Pick one and centralize in `WeightFormatter`.

### 11.4 Skeletons exist only in `DayTile`
[day_tile.dart:183-215](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L183-L215) has a nice skeleton bar. Extract to a shared `AppSkeleton` and use it on every loading list (program list, recent sessions, workout overview initial load).

---

## 12. Suggested priority order

If shipping incrementally, the highest-value-per-effort moves:

1. **Wakelock during sessions** (1.1) — fixes a real blocker, low LoC.
2. **Move LOG SET above the keyboard / pin to bottom** (5.1) — every set, every workout.
3. **Sound + heavier haptic on rest-overtime** (1.5, 1.6) — phone-on-bench problem.
4. **Snackbar-undo replaces confirmation dialogs for skip + delete-set** (1.11) — restores flow.
5. **Standardize empty-state and error-banner widgets** (1.8, 1.9) — pays back across screens.
6. **Auto-mark-done on last set logged** (4.5) — small, very visible UX win.
7. **Tap-session → detail view, export → secondary** (10.2) — sets up history as a first-class destination.
8. **One-time hint for long-press reorder / drag-onto-card supersets** (1.13, 4.10) — discoverability without permanent visual cost.
9. **Skeleton component reuse + better loading states** (1.7, 11.4).
10. **Accessibility pass: semantics on numeric readouts, bump buttons, drag handles** (1.15).

After that, the structural changes (bottom nav, exercise editor save bar, plan-import inline help, week export rework) are good v2 candidates.
