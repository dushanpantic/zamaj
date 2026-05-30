# UI improvement plan — Zamaj

A deep-dive review of every screen in the app against (1) modern UI/UX best
practices and (2) the tell-tale signals of LLM-generated UI, plus a prioritized
plan to remove the inconsistencies and "AI smell" without losing what already
works.

This is a **plan/working artifact**, not a spec, and a sibling to
[colors.md](colors.md) — it deliberately leans on that document's palette work
rather than repeating it. It does **not** change [product-context.md](product-context.md)
(no screen is added, removed, or renamed here — this is polish, not product
scope).

> **Status:** Phase 0 decisions are **closed** (see Part 4 → Phase 0). The
> remaining phases are sequenced and ready to implement.

> **Verdict up front:** the bones are genuinely good. There's a real token
> system ([app_spacing.dart](mobile/lib/core/app_spacing.dart),
> [app_typography.dart](mobile/lib/core/app_typography.dart),
> [app_colors.dart](mobile/lib/core/app_colors.dart)), a semantic theme, honest
> dark-first decisions, and the sweaty-hands ergonomics rule is real and mostly
> followed. The problem is **not** taste — it's **drift**: the same molecule
> (empty state, error state, loading state, section header, numeric stepper,
> confirm dialog, status badge) is re-implemented per file with small
> differences, because the app was clearly built screen-by-screen. That
> screen-by-screen drift is itself the loudest "made by an LLM" signal, and it's
> the thing this plan is mostly about.

---

## Part 1 — Deep dive: modern UI/UX best practices (for *this* app)

Not generic listicle material — these are the principles that matter for a
**dark-first, sweaty-hands, offline gym logbook whose soul is planned-vs-actual
honesty**, and how each one applies here.

### 1.1 One source of truth per visual dimension — and *complete* coverage
A mature design system tokenizes **every** visual decision, not just the easy
three. Zamaj tokenizes spacing, radius, color, and type — but **not** icon
sizes, **not** motion/durations, **not** border widths, **not** elevation
layers. Wherever a dimension lacks a token, the code hand-picks literals, and
those literals drift (see Part 3). Best practice: if a value appears in more
than one widget, it's a token.

### 1.2 Components over copies (DRY at the molecule level)
The unit of reuse in a modern UI codebase is the **component**, not the token.
Empty states, error states, loading skeletons, section headers, confirm dialogs,
status pills, and numeric steppers should each exist **once** and be configured,
not re-authored per screen. This is the single highest-leverage change available
here.

### 1.3 Vertical rhythm and spacing discipline
Tokens make spacing *legal*; rhythm makes it *good*. The same logical gap (e.g.
"space between a section header and its content") should use the **same** token
everywhere. Right now the gap after a heading is `sm` in one screen, `md` in
another, `xs` elsewhere. Pick a rhythm (e.g. section→content = `md`,
item→item = `sm`, group→group = `xl`) and hold it.

### 1.4 A restrained, intentional type scale — used as intended
[app_typography.dart](mobile/lib/core/app_typography.dart) is well-designed
(tabular numerics, a clear ramp). Best practice is to **map each role to exactly
one style** and never improvise. Today the "empty-state heading" role is
rendered as `title` (20px) on one screen and `titleSmall` (16px) on another —
same role, two sizes. Lock roles to styles.

### 1.5 Dark mode = tonal elevation, not shadows
On near-black, depth reads through **lighter surfaces**, not drop shadows.
[colors.md §1.1](colors.md) already nails this critique: there are only three
surface levels (`background → surface → surfaceVariant`), so a bottom sheet or
dialog sitting *above* a card has nowhere lighter to go. Modern dark UIs use 4
tonal steps. (This plan defers the palette swap to colors.md but adds the 4th
elevation token.)

### 1.6 Touch ergonomics as a first-class, *measured* rule
The CLAUDE.md sweaty-hands rule (64dp counters, 56dp primary actions, 36px
numeric inputs) is excellent and ahead of most apps. Best practice is to make it
**impossible to violate accidentally** by encoding it in shared components, so a
new in-session control inherits the right sizes rather than re-deriving them.
Today each control re-specifies `64`, `56`, `48` by hand — and a couple slip
(the focus rest-timer SKIP target and the inline ± editor sit at the 48dp floor,
not the in-session target).

### 1.7 Every screen owes four states: loading, empty, error, content
Zamaj actually *covers* all four on most screens (commendable, and rare). The
best-practice gap is **consistency of treatment**: loading is a content-shaped
**skeleton** on two screens and a bare centered **spinner** on five. Skeletons
that mirror the real layout are the modern default because they preserve spatial
expectation; pick one approach and apply it everywhere.

### 1.8 Feedback & motion as a small, named system
Haptics are used thoughtfully ([haptics.dart](mobile/lib/core/haptics.dart) on
log/complete/rest-end — great). Motion is not: durations of 80/120/150/200/220/250/500ms
appear with no naming. Modern systems define ~3 durations (e.g. `fast`/`base`/`slow`)
and ~2 curves, and everything uses them. Consistent motion is a large part of
what makes a UI feel "designed by a person."

### 1.9 Microcopy: terse, confident, consistent voice
Product copy should sound like one decisive person, not a helpful assistant.
Best practice: short, verb-first, no hedging, no explaining the obvious
consequence in a full sentence. (Part 2 shows where the current copy drifts into
"assistant voice" — this is also one of the strongest AI tells.)

### 1.10 Accessibility beyond the happy path
- **Contrast:** push in-session numerics + primary actions toward AAA (7:1), per
  [colors.md §1.4](colors.md). The biggest live risk is the **amber collision**
  flagged in [colors.md §2](colors.md): `warning`, `exerciseReplaced`, and
  `primary` are three near-identical warm hues — fix before public launch.
- **Never state-by-color-alone:** mostly satisfied (checks, glyphs, words), but
  status vocabulary is inconsistent (§Part 3).
- **Semantics:** `semanticLabel` is used on some icons and not others; tap
  targets are mostly ≥48dp. Make semantic labelling a property of the shared
  icon-button component so it's never forgotten.

### 1.11 One primary action per screen, obvious at a glance
Strong here — the FAB on lists, the single pinned `LOG SET` in focus, the single
`Focus:` button in overview. Keep this discipline as components are unified.

---

## Part 2 — Deep dive: tell-tale signals of AI-generated UI

What actually betrays LLM authorship in a Flutter app — and where each shows up
in this repo. The signals are ordered by how strongly they point at "an LLM
generated this, screen by screen, without a unifying pass."

### 2.1 The same molecule re-implemented per file (the #1 signal)
LLMs generate each screen in its own context window, so shared concepts get
**re-derived** instead of imported. Hard evidence:
- **15** bespoke `_EmptyView` / `_FailureView` / `_NotFoundView` private classes
  across 6 screen files — each a centered `Column(icon + title + body + button)`
  with slightly different icon sizes and heading styles.
- `_SkeletonBar` is defined **twice, identically** — in
  [program_list_screen.dart:248](mobile/lib/modules/program_management/screens/program_list_screen.dart#L248)
  and [day_tile.dart:271](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L271)
  (the program-list copy even has a comment admitting it borrows "the
  `_SkeletonBar` idiom from `day_tile.dart`").
- **Two confirm-dialog systems:** a shared
  [ConfirmationDialog](mobile/lib/modules/program_management/widgets/confirmation_dialog.dart)
  (bordered, radius `lg`, themed buttons) used in most places, *and* a
  hand-rolled `AlertDialog` in
  [recent_sessions_screen.dart:181](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L181)
  with stock styling and an error-colored text button. Same job, two looks.

### 2.2 Token-faithful but rhythm-blind
A human designer composing the whole app develops muscle memory for spacing; an
LLM picks a locally-plausible token each time. The tokens are *always legal* but
the rhythm wanders — heading→content gaps alternate `xs`/`sm`/`md` across
screens with no rule. This "every value is reasonable, no value is consistent"
texture is a hallmark.

### 2.3 Missing-token literal soup (icons + motion especially)
Where a token *doesn't* exist, the LLM reaches for a "reasonable" number and the
numbers scatter:
- **Icon sizes:** `size: 18` ×29, `size: 20` ×23, plus 12/14/16/24/26/32/48/64.
  The same role — a kebab/inline action glyph — is `18` in one card and `20` in
  another. No `AppIconSize` token exists.
- **Empty vs error icon size is semantically inverted per screen:** error icon
  is `48` but empty icon is `64` in
  [program_list_screen.dart](mobile/lib/modules/program_management/screens/program_list_screen.dart#L284)
  and [exercise_library_list_screen.dart](mobile/lib/modules/exercise_library/screens/exercise_library_list_screen.dart#L200),
  yet recent_sessions uses `64` for *all* states.
- **Motion:** 80/120/150/200/220/250/500ms, none named.
- Loose pixel literals (`width: 28`, `top: 6`, `width: 4` bullet dots, `height: 32`
  mini-buttons) sprinkled where a token should be.

### 2.4 Two implementations of one interaction
The app has **one** conceptual control — "nudge a number with ±, tap to type an
override" — but it exists twice, never reconciled:
- [set_row.dart `_NumericField`](mobile/lib/modules/workout_overview/widgets/set_row.dart#L712):
  step buttons flank a centered field; fixed steps `[-2.5, 2.5]`; `numericLarge`
  (36px); `_StepButton` is 64×64.
- [focus_rep_based_panel.dart `_BigNumericField` + `_BumpRow`](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L182):
  field on top, bump buttons in a row *below*; dynamic `IncrementRules.weightSteps`;
  `numericHero` (44px); bump buttons 48dp tall.

Same data (weight × reps), two layouts, two type sizes, two step policies. This
is the clearest "assembled from separate generations" fingerprint in the app.

> **Decision (kept distinct):** the two presentations stay separate by design —
> the compact card row and the big focus panel have genuinely different
> ergonomic jobs. What's *not* defensible is the **step-policy divergence**
> (fixed `[-2.5, 2.5]` vs `IncrementRules.weightSteps`) and the untokenized
> sizes. Remediation (F3) keeps two widgets but routes both through one
> increment source and the new size/type tokens, so the difference is
> intentional rather than accidental.

### 2.5 Inconsistent status vocabulary
"How we show state" has no single rule: an **uppercase pill** ("IN PROGRESS",
[day_tile.dart:210](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L210)),
a **Title-case pill** ("Skipped"/"Replaced",
[exercise_card.dart:367](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L367)),
and an **icon-only** marker (done check, warmup flame) all coexist. Each is
defensible alone; together they read as three authors.

### 2.6 Ad-hoc tracking on uppercase text
Uppercase/label text gets letter-spacing applied by hand at three different
values — `0.5` (baked into `actionLabel`), `0.6`
([recent_sessions section header](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L216)),
`1.2` ([rest-timer SKIP](mobile/lib/modules/focus_mode/widgets/focus_rest_timer_bar.dart#L72)) —
with no "overline/eyebrow" style to centralize it.

### 2.7 Same action, different chrome
`LOG SET` is a 64dp-tall `FilledButton` with radius `lg` and a "Set 3 of 4"
sub-label in focus mode
([focus_complete_button.dart:36](mobile/lib/modules/focus_mode/widgets/focus_complete_button.dart#L36)),
but a 56dp `FilledButton` with radius `md` (theme default) and no sub-label in
the inline set editor
([set_row.dart:604](mobile/lib/modules/workout_overview/widgets/set_row.dart#L604)).
The same verb should look the same.

### 2.8 Stock Material peeking through the custom skin
Most of the app is carefully tokenized, which makes the spots that fall back to
raw Material stand out as "the LLM just used the widget": bare `ChoiceChip`s
([exercise_library_list_screen.dart:299](mobile/lib/modules/exercise_library/screens/exercise_library_list_screen.dart#L299)),
default `PopupMenuButton`/`ListTile` menu items, a default `MaterialBanner`, and
the one hand-rolled `AlertDialog`. None are themed to match the rest.

### 2.9 "Assistant voice" microcopy
Empty/confirm copy explains consequences in full, reassuring sentences — the
tone of a helpful chatbot, not a terse product:
- "Archive "X"? It will stay linked to past data but stop appearing in the
  picker. You can restore it later."
- "Skipping "X" marks it as not done and moves on. This affects this session only."
- "Locks "X" as done with the sets you have already logged. You can still edit
  those sets."

Each is *correct*; collectively the "verb + reassurance sentence + scope
clarification" cadence is uniform and bot-like.

### 2.10 Typographic punctuation habits
Heavy, consistent use of the em dash `—` and the literal ellipsis glyph `…`
(used in 11 files, e.g. `'Loading…'`). Strong stylistic signature of generated
text — fine to keep, but worth knowing it's a tell.

### 2.11 Narrating-the-rationale comments
Not user-facing, but the strongest meta-signal in the source: comments that
*argue for* the design ("quiet checks read cleaner than a wall of text pills",
"the card's 2dp primary border is the 'current' signal on its own", "~20dp of
width instead of the ~70dp the old WARMUP pill took"). Designers rarely
self-justify inline; LLMs do, because they were explaining while generating.

---

## Part 3 — Findings inventory (what's actually inconsistent)

Cross-cutting issues, each with concrete evidence. Severity: **P1** = visible
inconsistency users feel; **P2** = drift that erodes polish; **P3** = code-health
/ low-visibility.

| # | Area | Finding | Evidence | Sev |
|---|------|---------|----------|-----|
| F1 | State views | 15 bespoke Empty/Failure/NotFound classes; no shared component | 6 screen files | **P1** |
| F2 | Loading | Skeletons on 2 screens, bare `CircularProgressIndicator` on 5+ (26 spinner usages) | program_list & day_tile vs recent_sessions, library, program_editor, plan_preview, plan_import | **P1** |
| F3 | Numeric stepper | Two presentations **kept by design**, but step policy diverges (fixed vs `IncrementRules`) and sizes are untokenized | set_row `_NumericField` vs focus `_BigNumericField`+`_BumpRow` | **P2** |
| F4 | Primary action | `LOG SET` differs in height (64 vs 56), radius (`lg` vs `md`), sub-label | focus_complete_button vs set_row `_Editor` | **P1** |
| F5 | Confirm dialogs | Shared `ConfirmationDialog` vs one inline `AlertDialog` | recent_sessions_screen:181 | **P2** |
| F6 | Status vocab | Uppercase pill / Title-case pill / icon-only all used for "state" | day_tile, exercise_card | **P2** |
| F7 | Empty heading | Role rendered as `title` (20) vs `titleSmall` (16) vs `textTheme.titleMedium` | program_list:335, recent_sessions:237, workout_day_picker:276 | **P2** |
| F8 | Icon sizes | No token; 18/20 used interchangeably for the same role (+12/14/16/24/26/32/48/64) | repo-wide (52 occurrences of 18/20 alone) | **P2** |
| F9 | Motion | 7 unnamed durations; no motion tokens | repo-wide | **P3** |
| F10 | Tracking | Uppercase letter-spacing hand-set at 0.5/0.6/1.2 | typography, recent_sessions, rest_timer | **P3** |
| F11 | Section headers | 3 treatments (muted+tracking label / icon+label row / boxed titleSmall) | recent_sessions, notes_section, plan_preview | **P2** |
| F12 | Stock Material | Un-themed ChoiceChip / PopupMenu / MaterialBanner / AlertDialog | library list, exercise_card, workout_day_picker | **P2** |
| F13 | Microcopy | "Assistant voice" — long reassurance sentences, inconsistent terseness | confirm + empty copy throughout | **P2** |
| F14 | Elevation | Only 3 surface tokens; sheets/dialogs can't sit above cards | app_colors + every modal | **P2** |
| F15 | In-session floor | SKIP target & inline ± editor sit at 48dp, below the in-session target | focus_rest_timer_bar, set_row `_Editor` | **P2** |
| F16 | Color collision | `warning` = `exerciseReplaced` = `#F59E0B`, adjacent to `primary` orange — **resolved by Ember** (`warning`→yellow `#FACC15`, `exerciseReplaced`→violet `#C084FC`) | app_colors.dart | **P1** (a11y) |
| F17 | FAB theming | Each FAB re-specifies `backgroundColor`/`foregroundColor`; no FAB theme | program_list, library, program_editor | **P3** |

---

## Part 4 — The plan

Phase 0 below is **decisions** (closed — not a prompt). The work itself is **six
vertical slices**, each sized to one prompt / one PR. Every slice **builds a
component *and* migrates its consumers in the same pass**, so nothing ships as
dead code and each slice is independently verifiable. Lazy tokens (Phase 0.6)
are authored inside the slice that first needs them. Nothing here changes
behavior, data, or the bloc layer — presentation only; all new tokens follow the
CLAUDE.md rule (token files / both palettes; never hard-code).

### Phase 0 — Decisions (CLOSED)
These were the one-way doors. Everything downstream is authored against them.

1. **Palette → "Ember" (colors.md Option A).** Keep the orange hero; warm the
   neutrals so the accent feels at home; **split the amber collision (F16):**
   `warning` → yellow `#FACC15` / light `#CA8A04`, `exerciseReplaced` → violet
   `#C084FC` / light `#9333EA`. Lowest-risk direction; the app still looks like
   itself. Phase 1 tokens are authored against the full Ember Dark/Light tables
   in [colors.md §Option A](colors.md). *(No new `restTimerOvertime` token needed
   — the bar auto-dismisses at zero.)*
2. **Status vocabulary → icon for positive, pill for exceptions.** Done /
   warmup = icon glyph (with tooltip + semantic label); Skipped / Replaced =
   Title-case pill. **One sanctioned pill exception: in-progress** stays a
   labeled pill on the day tile — resuming a live session is high-stakes enough
   to spell out, and it keeps the existing left-edge-stripe + label pairing.
   Drives F6.
3. **Loading → skeletons for content, spinner only for blocking saves.**
   Content-shaped skeletons on every list/screen load; a centered spinner (or
   scrim overlay) reserved for save/commit waits where the layout can't be
   predicted (e.g. plan-preview save). Drives F2.
4. **Numeric stepper → keep two distinct controls.** The compact card row and
   the big focus panel stay separate by design; they share only the new size /
   type tokens and one step-increment source — they are **not** merged into a
   single widget. Drives F3.
5. **Light mode → dark-only focus (for now).** Build and verify every component
   against the dark palette (the lived-in surface). Keep the Ember light table
   token-correct and compiling, but don't gate the work on light-mode polish.
   Drives Phase 5.
6. **Token rollout → lazy, not big-bang.** Land only what the first slice needs
   now (Ember swap + `AppIconSize`); add motion / stroke / 4th-elevation /
   overline tokens when the component that needs them is built. Tagged
   `[now]` / `[lazy]` in Phase 1.
7. **Microcopy → concise, but keep a little warmth.** Trim the assistant
   cadence, but retain a brief consequence note on destructive actions
   (delete / end / discard) where it reduces anxiety. Not a flat "terse
   imperative" rewrite. Drives F13 / Phase 4.

### Execution order at a glance

| # | Slice (one prompt each) | Builds | Closes | Live surface? | Risk |
|---|-------------------------|--------|--------|---------------|------|
| 1 ✅ | Foundation: Ember + icons | `AppIconSize`, `AppIcon` | F16, F8 | no | low |
| 2 | State views + loading | `AppStateView`, `AppSkeleton` | F1, F2, F7 | no | low |
| 3 | Status + section vocab | `StatusBadge`, `SectionHeader` (+overline, +stroke) | F6¹, F10, F11 | no | low |
| 4 | Dialogs + Material theming | `AppConfirmDialog`, theme entries (+4th surface) | F5, F12, F14, F17 | no | low |
| 5 | **Live session surface** | `PrimaryActionButton`, shared stepper policy | F3, F4, F15, F6² | **yes** | **high** |
| 6 | Microcopy + motion + verify | (+`AppDuration`/`Curve`) | F13, F9 | touch-up | low |

¹ day-tile in-progress pill. ² exercise-card state badges (deferred to the live
pass so the session screen is edited only once). Slices 1→4 never touch
`workout_overview/` or `focus_mode/`.

Each slice authors the `[lazy]` tokens it's the first to need; everything follows
the CLAUDE.md token rule. Build + migrate live in the **same** prompt — don't
land a component without its callers.

---

### Prompt 1 — Foundation: Ember palette + icon tokens  ✅ DONE
> **Status: complete.** Ember Dark/Light swapped in
> [app_colors.dart](mobile/lib/core/app_colors.dart) (F16 split + warmed
> neutrals, names unchanged); `AppIconSize` + `AppIcon` authored in
> [app_icon.dart](mobile/lib/core/app_icon.dart); 52 literal `Icon(size:)`
> usages across 32 non-live files migrated onto the tokens (the app-bar
> `iconTheme` default too). Per the risk guardrail, `workout_overview/` and
> `focus_mode/` were **not** touched — their icon literals migrate in Prompt 5,
> when the live surface is edited once. `tool/ci.sh` green (analyze clean, 633
> tests pass).
- **Build:** `AppIconSize` (e.g. `xs 12`, `sm 16`, `md 18`, `lg 20`, `xl 24`,
  `status 18`, `emptyState/errorState 64`); `AppIcon` wrapper (size from token;
  `semanticLabel` optional, **required for interactive** icons).
- **Apply:** swap `AppColors.dark`/`light` to the Ember Dark/Light tables from
  [colors.md §Option A](colors.md), **including the F16 split** (`warning`→yellow,
  `exerciseReplaced`→violet) and warmed neutrals — a pure value swap, names
  unchanged; migrate the 100+ literal `Icon(size:)` usages onto `AppIcon`/`AppIconSize`.
- **Closes:** F16 (amber collision), F8 (icon-size soup).
- **Verify:** `tool/ci.sh`; visual diff is yours (Ember is a value swap, so the
  shift should be subtle). No live-surface logic touched.

### Prompt 2 — State views + loading skeletons *(biggest bang)*
- **Build:** `AppStateView` (empty / error / not-found: icon, title, body,
  primary + optional secondary action); `AppSkeleton` / `AppSkeletonBar` + list/tile
  skeleton helpers, in `lib/building_blocks/`.
- **Migrate:** replace all **15** bespoke `_EmptyView`/`_FailureView`/`_NotFoundView`;
  delete **both** `_SkeletonBar` copies; convert content spinners → skeletons
  across program_list, workout_day_picker, recent_sessions, exercise_library,
  program_editor. **Keep the plan-preview SAVE overlay a spinner** (blocking save,
  per Phase 0.3).
- **Closes:** F1 (duplicated state views), F2 (loading), F7 (heading drift).
- **Verify:** `tool/ci.sh`; no live surface.

### Prompt 3 — Status + section vocabulary
- **Build:** `StatusBadge` (Phase 0.2: icon branch for done/warmup; pill branch
  for in-progress + Skipped/Replaced); `SectionHeader`. Author the `[lazy]`
  **overline** text style (one tracking value, kill 0.5/0.6/1.2) and `[lazy]`
  **`AppStroke`** (hairline/emphasis).
- **Migrate (non-live):** day-tile "IN PROGRESS" → `StatusBadge` pill;
  "This week"/"Earlier", Notes, Extra-work, plan-preview day titles, form-group
  labels → `SectionHeader`.
- **Closes:** F6 (day-tile half), F10 (tracking), F11 (section headers).
- **Note:** exercise-card state badges are intentionally **deferred to Prompt 5**
  so the live session screen is edited only once.

### Prompt 4 — Dialogs + Material theming
- **Build:** make `AppConfirmDialog` the single confirm path; add `chipTheme`,
  `popupMenuTheme`, `dialogTheme`, `floatingActionButtonTheme`, `bannerTheme` to
  [app_theme.dart](mobile/lib/core/app_theme.dart); author the `[lazy]` **4th
  elevation surface** (`surfaceElevated`) for sheets/dialogs.
- **Migrate:** convert the recent_sessions inline `AlertDialog`; drop the
  per-FAB `backgroundColor`/`foregroundColor` overrides (now themed); let
  ChoiceChip/PopupMenu/MaterialBanner inherit the skin.
- **Closes:** F5 (confirm dialogs), F12 (stock Material), F14 (elevation),
  F17 (FAB theming).

### Prompt 5 — Live session surface *(careful, last)*
> Re-read the CLAUDE.md **sweaty-hands** section before starting. Isolated PR.
- **Apply:** `PrimaryActionButton` for both `LOG SET` (focus) and `LOG SET`/`SAVE`
  (set-row inline editor) — one height/radius/label, optional sub-label; route
  both steppers (`set_row` `_NumericField` + `focus_rep_based_panel`) through one
  increment source (`IncrementRules`) and the size/type tokens, **keeping the two
  presentations** (Phase 0.4); lift the rest-timer **SKIP** target and the inline
  ± editor to the in-session size floor (F15); apply `StatusBadge` to
  exercise-card states.
- **Closes:** F3 (stepper policy), F4 (`LOG SET` chrome), F15 (in-session floor),
  F6 (card half).
- **Verify:** `tool/ci.sh` (domain+persistence only — no widget tests per
  CLAUDE.md), then **a real session is your sign-off**, per colors.md §6.

### Prompt 6 — Microcopy, motion & verification
- **Microcopy (F13, Phase 0.7):** concise and verb-led, but keep a brief
  consequence note on destructive actions. Example: *"Archive "X"? Hidden from
  the picker, kept in your history."* Normalize `'Loading…'`/titles; settle
  `…` vs `...` once.
- **Motion (F9):** author the `[lazy]` `AppDuration`/`AppCurve`; migrate the
  handful of animated widgets.
- **Accessibility/verify (Phase 0.5):** confirm in-session numerics + primary
  actions hit AAA against **Ember dark**; tap-target floors via tokens; no state
  by color alone. Spot-check light for compile/token-correctness only.

---

## Risk notes
- **Slices 1–4 are low-risk** and never touch `workout_overview/` or
  `focus_mode/`. **Prompt 5 is the only high-risk slice** — keep it isolated and
  do it after the components are proven elsewhere.
- **One-way door — CLOSED:** palette is Ember (Phase 0.1); nothing else blocks.
- **Out of scope:** any new feature/screen; product-context changes (none
  needed); re-theming beyond Ember's value swap.

## What to deliberately keep
The dark-first near-black canvas, planned-vs-actual as a value (not hue) pair,
the rationed single accent, the tabular-figure numerics, thoughtful haptics, the
four-states discipline, and the sweaty-hands sizing rule. The goal is to make
these **consistently** applied — not to redesign them.
