# UI improvement plan 4 — de-AI-ing the UI

Audit of every screen in the app against (a) modern mobile UI/UX practice and
(b) the known tell-tale signatures of LLM-generated UI. Findings first, plan at
the end. All paths are relative to `mobile/`.

**Status: decisions closed (2026-06-10 interrogation).** The plan below is
amended to reflect them:

1. Save model: converge **presentation only**; autosave-everywhere is a
   recorded follow-up, not in scope.
2. Replace-exercise form: **scroll-controlled bottom sheet**.
3. Rest-timer overtime: **docs follow code** — no behavior change.
4. Add affordance: **extended FAB on browse screens, app-bar `+` in editors**
   (reverses the first draft's FAB-everywhere rule).
5. Swipe-to-delete: **low-stakes/undoable rows only** — removed from program
   tiles, never added to session history.
6. Scope: **all 8 steps committed**, including the typeface.
7. Typeface: **Barlow**, applied to the **whole app**, bundled as assets.

---

## 1. Reference: the best practices this audit measured against

Condensed to what is relevant for a dark-first, offline, single-user Flutter
app. Each item is used as a yardstick in §4.

**Foundations**

- **Token-driven everything.** Color, type, spacing, radius, motion, opacity
  come from one named scale; a hard-coded literal is a bug. (Zamaj already
  does this better than most hand-made apps — see §3.)
- **Tonal elevation in dark mode.** Depth = lighter surface + outline, not
  drop shadows. One sanctioned shadow at most (drag proxy).
- **Restrained accent budget.** One brand accent doing one job (primary
  action); semantic colors for states; everything else neutral.
- **Typography hierarchy that compresses well.** Few sizes, clear roles,
  tabular figures for any number that changes while visible (timers, counters,
  weights) so digits don't jitter.

**State communication**

- **Skeletons for first paint, inline progress for mutations.** Centered
  spinners are for unknown-duration full-screen waits only — and a local
  SQLite app essentially has none. A blocking scrim+spinner for a <50 ms
  write reads as a flash of broken UI.
- **No layout shift across state changes.** A button that turns into a
  spinner (and back) moves the page; reserve the slot instead.
- **Optimistic UI + undo beats confirm dialogs** for cheap-to-reverse
  actions; confirm dialogs only for the genuinely destructive/irreversible.
- **Errors name the thing and offer the recovery verb.** Never leak internal
  identifiers.

**Ergonomics (mobile, and especially in-gym)**

- **Thumb zone.** Primary actions live in the bottom third; multi-field entry
  on a phone is a bottom sheet or full-screen route, not a centered
  `AlertDialog` (a dialog puts both the fields and the actions in the hardest
  reach zone and fights the keyboard).
- **Touch floors are floors.** 48 dp general; this product's own rule is
  64 dp steppers / ≥56 dp primary actions / `actionLabel` text on the two
  live-session modules.
- **Text scaling must not break fixed-height chrome.** Fixed 48/56/64 dp
  boxes with un-clamped text overflow at 1.3×+ accessibility font sizes; use
  min-heights or clamped scaling on dense numeric chrome.
- **Respect reduced motion** (`MediaQuery.disableAnimations`) for anything
  that self-animates (marquees, progress pulses).

**Consistency (the one that matters most here)**

- **One pattern per problem, app-wide.** Same loading treatment for the same
  archetype of screen, same "add an item" affordance, same save paradigm,
  same destructive-action discovery (swipe vs menu), same modal elevation.
  Per-screen local polish with cross-screen divergence is the single
  strongest signal of generated UI (§2).
- **Copy: sentence case, verb-first buttons, no fluff, one voice.**
- **Platform conventions:** correct share glyph per platform, predictable
  back behavior, icons whose metaphor matches the action.

---

## 2. Reference: tell-tale signs a UI was made by an LLM

What reviewers (and increasingly users) pattern-match on, roughly ordered by
how damning they are:

1. **Cross-screen divergence with local consistency.** Each screen is
   internally coherent but solves the same problem differently from its
   sibling — five editors with four save paradigms, three "add" affordances,
   two loading treatments. LLMs generate screens one conversation at a time;
   humans get bored and extract the pattern.
2. **Copy-pasted micro-blocks instead of abstractions.** The same 10-line
   inline-spinner / badge / banner snippet appearing in N files with the same
   magic numbers (`width: 16, height: 16`).
3. **Dialog-itis.** `AlertDialog` for multi-field forms, for text entry, for
   pickers — because it's the lowest-token modal.
4. **Spinner-itis + layout shift.** Default `CircularProgressIndicator()`
   centered in a `body`, buttons replaced by spinners, scrim overlays for
   instant local writes.
5. **Icon grab-bag.** Semantically-adjacent-but-wrong Material icons:
   `auto_fix_high` (magic wand) for anything smart, `ios_share` on Android,
   sparkles for AI, `calendar_view_week` for "export".
6. **Template look.** Default font, default Material widget chrome, every
   list a card with `borderRadius: 12`, uniform vertical rhythm with no
   moments of deliberate scale contrast.
7. **Chatty or inconsistent copy.** Title Case mixed with sentence case,
   trailing periods on some titles, "Got it" buttons that do nothing,
   exclamation marks, redundant explainer sentences, raw IDs/debug strings
   surfacing in user-facing states.
8. **Cargo-cult interactions.** Pull-to-refresh on local reactive data;
   manual `.then(() => refresh())` chains where a stream/watch already
   exists; confirm dialogs guarding trivially-undoable actions.
9. **Dead alternates.** A maintained light palette behind a hard-pinned
   `ThemeMode.dark`; props/tokens documented but never implemented (doc
   drift), e.g. a semantic color named in docs that doesn't exist in code.
10. **Accessibility theater.** Tooltips and semantic labels present (cheap to
    generate) while structural a11y is missing: no reduced-motion handling,
    fixed heights that break under text scaling, icon-only app-bar actions as
    the sole path to a feature.

---

## 3. What Zamaj already gets right (do not regress)

This codebase is far cleaner than typical generated UI. The audit found
**none** of: gradients, shadow soup, emoji, purple-indigo defaults,
card-in-card nesting, fake stats, lorem remnants, centered hero clichés.
Strengths worth protecting:

- Disciplined token system: `AppColors` (semantic, two palettes),
  `AppTypography` (tabular numeric scale), `AppSpacing`/`AppRadius`/
  `AppStroke`, `AppOpacity`, `AppDuration`/`AppCurve`, `AppElevation` with a
  single sanctioned shadow, `AppInSessionSize` encoding the sweaty-hands rule.
- "The one X for the app" building blocks (`AppStateView`, `AppNoticeBanner`,
  `AppConfirmDialog`, `StatusBadge`, `SectionHeader`, `PrimaryActionButton`)
  with genuinely thoughtful doc comments.
- Real a11y effort: `Semantics` labels on tiles, `CustomSemanticsAction`
  move-up/down fallbacks for drag reorder, tooltip+label on every status
  glyph, tap-only reorder fallback in the kebab menu.
- Ergonomic intent: 64 dp steppers, 56 dp log circle, reserved drag-handle
  slot so titles don't reflow, stable trailing-action widths on day tiles.
- Terse, verb-first copy almost everywhere; planned/actual color split
  consistently applied.

The problems below are therefore mostly **convergence work** — making sibling
screens agree — plus a handful of genuine AI-symptom cleanups.

---

## 4. Findings

Severity: **H** = user-visible inconsistency or rule violation, **M** = polish
/ drift, **L** = nice-to-have.

### A. Loading & saving states are split across two regimes (H)

The classic "each screen generated separately" signature.

- **Skeleton list** (good): program list, program editor, day picker, recent
  sessions, library list, link suggestions.
- **Centered spinner** (divergent): workout-day editor
  (`workout_day_editor_screen.dart:126`), exercise editor
  (`exercise_editor_scaffolds.dart:14`), library editor
  (`exercise_library_editor_screen.dart:189`), workout overview
  (`workout_overview_loading_view.dart`), focus mode
  (`focus_mode_state_views.dart`), plan preview — which uses the **bare,
  un-themed** `CircularProgressIndicator()` four times
  (`plan_preview_screen.dart:76,108,115,118`).
- **Save feedback — four paradigms across five editors:**
  1. Program editor: autosave + 16 px inline app-bar spinner
     (`program_editor_app_bar.dart:75`).
  2. Workout-day editor: autosave + `WorkoutDaySaveChip` + retry.
  3. Exercise editor & library editor: explicit `Save` `TextButton` + full
     scrim overlay spinner during save (`exercise_editor_scaffolds.dart:134`,
     `exercise_library_editor_screen.dart:292`).
  4. Plan preview: `Save` as a `FilledButton` in the app bar + scrim overlay
     (`plan_preview_screen.dart:100–113,150`).
- **Layout shift:** plan import replaces the Parse button with a centered
  spinner while parsing (`plan_import_screen.dart:141–149`).

### B. Sweaty-hands rule violations on the live surface (H)

The product's own signature rule, broken on its flagship screen:

- `WorkoutOverviewBottomBar` Focus button is theme-default **48 dp** with
  14 px `label` style — the rule demands ≥56 dp + `actionLabel`
  (`workout_overview_bottom_bar.dart:66`). The Note/Extra buttons are exactly
  48 dp ("the floor, not the target").
- In-session flows route through **centered `AlertDialog`s with 48 dp
  text-button actions**: skip/mark-done/end confirmations, note & extra-work
  entry (`text_entry_dialog.dart`), the multi-field replace-exercise form
  (`replace_exercise_dialog.dart` — a long form in a dialog), and the
  group-with picker. Top-of-screen reach, small targets, keyboard fights.
- Focus-mode rest timer's mm:ss readout uses `caption` — 12 px,
  **non-tabular**, so digits jitter every second, and it's tiny for an
  across-the-bench glance (`focus_rest_timer_bar.dart:51–54`).
- "End session" — an in-gym primary task — is a 48 dp icon-only app-bar
  button (`workout_overview_screen.dart:206`).

### C. Repeated inline-spinner block instead of a building block (M)

The same hand-rolled `SizedBox(width: 16, height: 16, child:
CircularProgressIndicator(...))` appears in at least four places
(`link_suggestion_screen.dart:231`, `export_preview_sheet.dart:179`,
`program_editor_app_bar.dart:75`, `start_resume_action_button.dart:35`) plus
a 12 px variant (`workout_day_save_chip.dart:45`) and a 24 px variant
(`program_list_tile.dart:95`). Textbook copy-paste tell; sizes are magic
numbers outside the token system.

### D. Modal elevation rule broken by one dialog (M)

House rule: modals sit on `surfaceElevated` (4th tonal step) via
`dialogTheme`. `TextEntryDialog` overrides to `colors.surface` and uses raw
`TextStyle(color: …)` instead of typography tokens
(`text_entry_dialog.dart:68–77`). One-line fixes; high consistency value.

### E. Copy drift (M)

- **"Edit Exercise"** is Title Case (`exercise_editor_scaffolds.dart:100`);
  every other screen title is sentence case ("Edit library entry", "Import
  from text").
- **"Exercise not found."** has a trailing period and is rendered by a
  hand-rolled not-found view that bypasses `AppStateView`
  (`exercise_editor_scaffolds.dart:26–67`) — both a copy and a component
  divergence.
- **Raw IDs leak to the user:** program-editor not-found shows the internal
  `programId` as the message (`program_editor_screen.dart:229`).
- Coach-mark snackbars end in a no-op "Got it" action
  (`workout_day_editor_screen.dart:205`, `session_detail_screen.dart:61`) —
  acceptable as a dismiss affordance, but `⋮` inside copy
  ("Use the ⋮ menu for more") is the kind of meta-reference users shouldn't
  see; name the action ("the menu on each exercise") instead.

### F. Icon semantics (M)

- `Icons.ios_share` used for share/export on an Android-first Flutter app
  (`session_detail_screen.dart:103`, `session_history_tile.dart:91`). Use
  `Icons.share` (adaptive) or platform-select.
- `Icons.auto_fix_high` (magic wand) for "Suggest from your programs" —
  LLM-icon cliché and an opaque metaphor (`exercise_library_list_screen.dart:110`).
  `Icons.link` (it bulk-links) says what it does.
- `Icons.calendar_view_week` for "Export this week"
  (`recent_sessions_screen.dart:39`) — reads as a calendar view toggle, not an
  export. Prefer the share glyph + tooltip, matching session detail.
- Library on program list is `library_books` while the library's own empty
  state and tiles use other glyphs — minor, audit during the pass.

### G. "Add an item" affordance differs per screen (M)

Same hierarchy, three patterns:

- Program list: **extended FAB** ("New program").
- Library list: **extended FAB** ("New entry").
- Program editor: **circular FAB** (icon only, tooltip "Add workout day")
  (`program_editor_screen.dart:258`).
- Workout-day editor: **app-bar `+` icon button** ("Add exercise")
  (`workout_day_editor_screen.dart:246`).

### H. Destructive-action discovery differs per list (M)

- Swipe-to-delete + kebab: program tiles, editor exercise rows, superset
  cards.
- Kebab only: session history tiles, library tiles (archive).
- The swipe gesture is taught once, via a snackbar, on one screen only.
  Decide: swipe everywhere a row is deletable (with kebab fallback), or
  nowhere.

### I. Doc/code drift (M)

- CLAUDE.md names semantic colors `restTimer`/`restTimerOvertime`;
  **`restTimerOvertime` does not exist** in `AppColors`.
- product-context.md promises a "rest timer with overtime indicator";
  the code explicitly removed overtime ("there is no overtime state to
  render", `focus_rest_timer_bar.dart:10–11`,
  `rest_timer_view_model.dart:11`). Either restore the overtime state (it was
  a deliberate ergonomic feature — knowing how far past rest you are) or fix
  both docs. Decide product-side first.

### J. Cargo-cult / structural odds and ends (L–M)

- **Pull-to-refresh on local reactive data** (program list, day picker,
  library, recent sessions) plus manual `.then(() => bloc.refresh())` chains
  after every `pushNamed` — the persistence layer already exposes `watch*`
  streams (the day-picker uses one for the active session). Migrating list
  screens to watch streams removes both the refresh indicator and the manual
  refresh plumbing. (L — works fine today, but it's reflex code.)
- **No reduced-motion handling**: `FocusMarqueeText` auto-scrolls and
  `AnimatedContainer`s run regardless of `MediaQuery.disableAnimations`.
- **Text-scale fragility**: fixed heights (`SessionInProgressBanner` 56 dp,
  64 dp steppers, 48 dp rows) with un-clamped text will overflow at large
  accessibility font sizes. Live-session numeric chrome should use
  `MediaQuery.withClampedTextScaling`; informational text should reflow.
- `SessionInProgressBanner` hand-rolls its accent bar (`width: 4` Container)
  duplicating the `InProgressAccentBar` building block, and hard-codes
  `_height = 56` (`session_in_flight_banner.dart:59,75`).
- Stray literals: `SizedBox(height: 2)` (`add_workout_day_sheet.dart:260`),
  8 px dots (`focus_set_progress.dart:72`), inline
  `fontFamily: 'monospace'` (`plan_import_screen.dart:263`), inline
  `fontWeight: FontWeight.w600` on Save labels
  (`exercise_editor_scaffolds.dart:116`,
  `exercise_library_editor_screen.dart:271`), `minWidth: 24` suffix-icon
  constraints (`program_editor_app_bar.dart`).
- Plan preview labels every non-superset group "Single"
  (`plan_preview_screen.dart:245–266`) — zero-information chrome on the
  common case; show the header only for supersets.
- Plan preview hand-rolls a `_WarningBadge` that duplicates
  `AppNoticeBanner`'s tinted-chrome recipe at a third size — fold into the
  banner (tone: warning, `margin: zero`) or `StatusBadge`.

### K. Identity (H — promoted to in-scope, Step 8)

The app uses the platform default font with default Material chrome. That was
a deliberate MVP choice (documented in `app_typography.dart`), but it is the
single biggest "template/generated" visual signal remaining once §A–§G land.
**Decision: ship Barlow, whole app, in this plan** — see Step 8.
`AppTypography` already centralizes every style, so the change is contained.

---

## 5. The plan

Eight steps, ordered so each is independently shippable and testable.
Scope discipline: no new features — convergence, rule compliance, and one
deliberate identity change (Step 8). Test scope stays domain + persistence
per CLAUDE.md; these are UI-only changes verified by `tool/ci.sh` + manual
visual validation (owner does the visual pass).

### Step 1 — Building blocks for the repeated bits

1. `AppInlineSpinner` in `building_blocks/`: sizes `sm` (12), `md` (16),
   `lg` (24) as named constants (extend `AppIconSize` or a local scale), color
   parameter defaulting to `onSurfaceMuted`. Replace the six hand-rolled
   spinner blocks (§C).
2. `AppLoadingView` (centered, token-colored spinner) for the rare
   full-screen unknown-wait, and a small `AppFormSkeleton` (a few
   `AppSkeletonBar`s in a column) for editor screens.
3. Re-point `SessionInProgressBanner` at `InProgressAccentBar`; replace
   `_height = 56` with a token (reuse `AppInSessionSize.controlMin` is wrong
   semantically — add `AppSpacing.bannerHeight = 56` or use min-height).
4. Sweep the stray literals from §J (height 2 → `xxs`, monospace → a
   `numericMono`-style decision or a named constant, w600 Save labels → use
   `typography.label` as-is or add an `emphasized` label token).

### Step 2 — One loading + one saving story (§A)

1. Rule: **list screens → `AppListSkeleton`; editor screens →
   `AppFormSkeleton`; never a bare default spinner.** Convert workout-day
   editor, exercise editor, library editor, plan preview. (Workout overview
   and focus mode load from local snapshot in ~one frame; keep
   `AppLoadingView` there.)
2. Rule (decided: presentation-only convergence): **editors autosave where
   drafts already autosave; explicit-save editors keep `Save` as an app-bar
   `TextButton` (primary color, enabled state from validation) — no scrim
   overlays.** Replace the two scrim+spinner saves with a disabled form +
   inline app-bar `AppInlineSpinner` (the program editor's existing pattern).
   Plan preview's app-bar `FilledButton` Save becomes the same `TextButton`
   treatment; Discard stays. Autosave-everywhere convergence is a recorded
   follow-up (touches blocs/validation; out of scope here).
3. Plan import: keep the Parse button mounted while parsing — disabled, with
   an `AppInlineSpinner` in its leading slot. No layout shift.

### Step 3 — Live-surface ergonomics compliance (§B)

1. `WorkoutOverviewBottomBar`: Focus button → height
   `AppInSessionSize.controlMin` (56), `actionLabel` style; Note/Extra
   secondary buttons → 56 dp to match.
2. Rest timer readout → `numericMd` (22 px, tabular) in the existing
   `restTimer` color; SKIP unchanged.
3. Convert in-session text entry (note / extra work) from `AlertDialog` to a
   bottom sheet (`surfaceElevated`, drag handle, ≥56 dp commit button) —
   matches `SetValueEditorSheet`, which already exists and does this
   correctly for the export module.
4. Convert the replace-exercise form to a scroll-controlled bottom sheet
   (decided; same chrome as `LibraryPickerSheet`, keyboard handling via
   `viewInsets` padding as proven in `SetValueEditorSheet`). Group-with
   picker likewise.
5. Confirmations (skip / mark done / end session) stay `AppConfirmDialog` —
   they're two-button reads, fine as dialogs — but End session also gets a
   ≥56 dp presence: keep the app-bar icon as a secondary path and rely on the
   confirm dialog; no new chrome.

### Step 4 — Copy and icon pass (§E, §F)

1. "Edit Exercise" → "Edit exercise"; "Exercise not found." → "Exercise not
   found"; replace the hand-rolled not-found scaffold with `AppStateView`.
2. Remove raw IDs from user-facing messages (program-editor not-found shows
   no message, or "It may have been deleted.").
3. Coach-mark copy: "Use the ⋮ menu for more" → "More actions live in each
   exercise's menu".
4. Icons: `ios_share` → `Icons.share` (or `Icons.adaptive.share`) in both
   export locations; `auto_fix_high` → `Icons.link` (both app-bar action and
   empty-state action on the library screens); `calendar_view_week` →
   `Icons.adaptive.share`-style share glyph with the existing "Export this
   week" tooltip.

### Step 5 — Affordance convergence (§G, §H)

1. "Add" affordance rule (decided — reverses the first draft): **extended FAB
   on browse screens, app-bar `+` in editors.** Program list and library keep
   their extended FABs. Program editor's circular FAB becomes an app-bar `+`
   ("Add workout day" tooltip), matching the workout-day editor, which stays
   as-is. Rationale: both editors host drag-to-reorder lists, and a FAB
   occludes the bottom rows' drag handles and drop gaps mid-drag.
2. Destructive-discovery rule (decided): **swipe = low-stakes/undoable
   removal only; real data deletes via kebab + confirm.** Editor draft rows
   keep their `Dismissible`s (undoable). Program tiles **lose** swipe-to-
   delete (`program_list_tile.dart:150` — kebab + confirm remains). Session
   history tiles stay kebab-only. Library tiles stay kebab-only (archive).
   The gesture now has one meaning app-wide; the day-editor coach-mark copy
   ("Swipe left to delete") remains accurate where it shows.

### Step 6 — Doc/code reconciliation (§I)

Decided: **docs follow code.** No behavior change. Delete `restTimerOvertime`
from CLAUDE.md's semantic-color list and fix product-context.md's focus-mode
bullet ("rest timer with overtime indicator" → describes auto-dismiss + the
end-of-rest haptic). The auto-dismiss behavior was a deliberate later
decision per the view-model comment, and the haptic already signals "rest
over".

### Step 7 — Structural a11y hardening (§J)

1. Reduced motion: gate `FocusMarqueeText` auto-scroll on
   `MediaQuery.disableAnimations` (fall back to ellipsis); audit
   `AnimatedContainer`/panel transitions to drop durations to zero under the
   same flag (one helper: `AppDuration.of(context, base)`).
2. Text scaling: wrap the in-session numeric chrome (steppers, log circle,
   rest bar, pinned bottom bars) in `MediaQuery.withClampedTextScaling(
   maxScaleFactor: ~1.3)`; convert fixed `height:` on banners/tiles to
   `constraints: BoxConstraints(minHeight: …)` where content could wrap.
3. (Deferred, L) Stream-based list screens to retire pull-to-refresh and the
   `.then(refresh)` chains — file as its own follow-up; touches blocs, not
   just UI.

### Step 8 — Typeface: Barlow, whole app (§K)

Decided: **Barlow**, applied to the entire `AppTypography` scale (body,
labels, titles, numerals) — a utilitarian grotesque with signage/industrial
heritage that suits the Ember palette without reading as a sports cliché.
Runner-up if it fails acceptance: IBM Plex Sans.

1. Bundle the needed weights as assets (offline-first: no runtime font
   fetching). The scale uses w400/w500/w600/w700; declare them under one
   `Barlow` family in `pubspec.yaml`.
2. Wire `fontFamily` once in `AppTypography.standard` (every style already
   flows from there). Re-tune `height`/`letterSpacing` per style where the
   metrics differ from the platform default — expect a pass over `overline`
   and `actionLabel` tracking.
3. **Acceptance criterion — tabular figures.** Verify Barlow renders the
   `numeric*` styles without digit jitter (the `FontFeature.tabularFigures()`
   requirement). Manual check: a running rest timer and a weight stepper
   crossing 99→100. If Barlow's `tnum` support fails this, switch to IBM
   Plex Sans (guaranteed tabular figures) — same wiring, different asset.
4. Sweep fixed-height chrome after the swap (Step 7.2's min-height work
   covers most of it); Barlow runs slightly narrower than Roboto, so expect
   layout to relax, not tighten.
5. Note the bundle-size delta in the PR description (4 static weights ≈
   ~200 KB total; acceptable).

### Sequencing & verification

- Steps 1→2 are prerequisites for nothing else but reduce diff noise; do them
  first. Steps 3–5 are independent of each other. Step 6 is a 10-minute
  change. Step 7 next-to-last (it touches the most files superficially).
  Step 8 last — it lands after the convergence work so the visual pass
  evaluates one change at a time, and after Step 7.2 so text-scale fixes
  aren't re-done against new metrics.
- After each step: `tool/ci.sh`; visual validation is the owner's pass (per
  working agreement, no app launches from the assistant).
- product-context.md needs updating in the same change **only** for Step 3.3
  /3.4 (dialog → sheet is a user-facing interaction change on a named screen)
  and Step 6.

### Recorded follow-ups (out of scope)

- **Autosave convergence**: move exercise editor + library editor to the
  autosave/save-chip paradigm (touches blocs and partial-draft validation).
- **Stream-based list screens**: retire pull-to-refresh and the
  `.then(refresh)` navigation chains in favor of `watch*` streams.

### Explicit non-goals

- No light-theme polish (`ThemeMode.dark` stays pinned; palette stays
  token-correct).
- No redesign of layouts, navigation, or feature set; no new screens.
- No bloc/architecture refactors (see recorded follow-ups).
