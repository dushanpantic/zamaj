# UI improvement plan — round 3

A fresh audit of every screen in Zamaj against (1) modern mobile UI/UX best
practice and (2) the tell-tale signatures of an AI-generated interface, with a
prioritized, file-level plan to remove them.

This was written without reading prior `ui_improvement*` notes or git history —
it is an independent read of the current code.

> **Scope note:** the deliverable here is the *plan*. Nothing in the codebase has
> been changed. The app is dark-first by deliberate house style; the
> "depth = lighter surface + outline, never a shadow" rule, the planned-vs-actual
> two-colour system, and the sweaty-hands control floors are intentional and are
> treated as constraints, not targets.

> **Decisions resolved 2026-05-31** (see [Decisions](#decisions-resolved-2026-05-31)
> at the end). They reshape Part 4 — read them before executing.

---

## Part 1 — Modern UI/UX best practices (the bar we're measuring against)

The principles a 2025-era mobile product is expected to hit, distilled to the
ones that actually bite this app:

1. **Lead with the user's job, not the data model.** The first screen should be
   the thing the user opens the app to do. Navigation that mirrors the entity
   tree (Programs → Days → Session) is an engineering convenience, not a user
   journey. The core loop of a gym logger is *"open → do today's workout → log
   sets."*

2. **Visual hierarchy through contrast, not uniformity.** Type scale, weight,
   colour, and *size* should encode importance. A screen where every element is
   the same bordered card at the same elevation has no focal point — the eye has
   nowhere to land first.

3. **One primary action per screen.** Make it unmistakable (size, colour,
   position). Demote everything else. Avoid two equal-weight CTAs competing.

4. **Progressive disclosure.** Show the 80% case cleanly; tuck the 20%
   (advanced options, rare states) behind a tap. Don't pre-render every field.

5. **Spacing creates grouping (Gestalt).** Related things sit close; unrelated
   things get air. Generous, *rhythmic* whitespace reads as intentional;
   uniform whitespace everywhere reads as a grid with no opinion.

6. **Motion is feedback, not decoration.** Transitions should explain a state
   change (where did this come from, where did it go). 120–220 ms, eased.

7. **Copy has a voice and is consistent.** Sentence case, consistent casing for
   the same concept, verbs on buttons, no robotic over-explanation. Microcopy
   should sound like a person who lifts wrote it.

8. **Empty states sell the next action and have personality.** Not just
   "Nothing here" — they orient and motivate.

9. **Accessibility is table stakes.** ≥48 dp targets, semantic labels, contrast,
   dynamic type, never colour-alone signalling. (Zamaj already does most of
   this well — credit where due.)

10. **A real type scale + one accent, used with restraint.** Restraint with the
    accent is what makes it read as a *signal*. An accent on everything is an
    accent on nothing.

---

## Part 2 — Tell-tale signals that a UI was built by an LLM

These are the fingerprints. They're not "bad code" — they're the *aesthetic and
structural defaults* a model converges on. Listed so the findings in Part 3 can
point back at them.

- **T1 — IA mirrors the schema.** Screens map 1:1 to entities; the landing
  screen is a CRUD list of the top-level entity. No task-first home. The app is
  organized the way the database is, not the way the day goes.
  *(Reviewed and kept deliberately — see Decisions.)*

- **T2 — "Everything is a card, every card is identical."** Each list renders as
  `AppBar + ListView.separated` of bordered surface tiles at one radius/elevation,
  title + middot-joined caption + trailing kebab. Programs, days, library
  entries, history all look the same. Maximal consistency, zero hierarchy. This
  is the single strongest visual tell.

- **T3 — Uniform rhythm, no focal point.** Equal spacing, equal weight, equal
  size everywhere. Competent and flat. Nothing is *bigger* because it *matters
  more*.

- **T4 — Templated empty/error states.** One component, one layout
  (centered icon → title → one-sentence explainer → button), neutral helpful
  voice, everywhere. Correct, characterless.

- **T5 — Middot metadata strings.** `"4 days · 30 exercises · edited 2w ago"`,
  `"No days yet · Tap to set up"`. The ` · `-joined fact list is a generated-copy
  signature.

- **T6 — Em-dashes and over-explanatory microcopy in UI strings.** `"Kept in
  your history — restore it anytime."` `"This week — ${program}"`. The em-dash is
  the most-cited LLM writing tell, and it has leaked into user-facing copy.

- **T7 — Icon reflex.** A leading glyph attached to every section header and most
  buttons because "sections have icons." Decorative, not informational.

- **T8 — Default dark palette.** Warm-graphite surfaces + a single saturated
  accent + textbook semantic green/red/amber. The safe, generated dark theme.
  (Bonus tell: the colour file comments literally describe having generated three
  warm signals that "read alike" and then splitting them — a model fixing its own
  collision.)

- **T9 — Over-documented, checklist-driven refactors.** Comments read as design
  essays citing internal phase IDs ("G10 / Phase 0.6", "the F4 divergence"). This
  is the residue of an AI working a consistency checklist — strong evidence the
  *whole* UI was AI-iterated. **Targeted for removal in Phase 2.**

- **T10 — A near-perfect token system with a thin layer of leaks.** The
  giveaway is *partial* discipline: a beautiful `AppOpacity`/`AppSpacing`/
  `AppInSessionSize` scale, then stray `0.55`, `width: 28`, `_size = 56`,
  hand-rolled drag handles. Humans are messy uniformly; AI is perfect-then-leaky.

---

## Part 3 — Findings

Split into **systemic** (journey-level) and **concrete inconsistencies**
(measurable, low-risk). Each tagged with the Part-2 signal it exemplifies.

### A. Systemic / journey-level

- **A1 — The app opens on a CRUD list, not the workout. `T1` — DELIBERATE, NOT
  FIXING.** `app.dart` lands on `programList`; the nav graph is the entity tree.
  Raised, reviewed, and **kept on purpose** (see Decisions). Documented here so a
  future audit doesn't re-flag it as a defect.

- **A2 — No hierarchy between high-stakes and housekeeping surfaces. `T2 T3`**
  The "start a workout" tile (`day_tile.dart`), the "edit a program" tile
  (`program_list_tile.dart`), a library entry, and a past session
  (`session_history_tile.dart`) are all the same `surface` rectangle, radius
  `md`, `outline` border, title `titleSmall` + caption + trailing control. The
  one action that matters most gets no more visual weight than archiving a
  library row. **Addressed in Phase 3.**

- **A3 — Empty/error states are a single template. `T4`** Kept as-is on voice
  (see Decisions); only the copy-mechanics fixes in Phase 1 touch them.

- **A4 — Microcopy carries LLM fingerprints. `T6 T5`** Em-dashes in
  `recent_sessions_screen.dart`, `exercise_library_list_screen.dart`,
  `exercise_library_editor_screen.dart`. Middot fact-lists in
  `program_list_tile.dart` and `program_stats_header.dart`. **Mechanical fix in
  Phase 1 — no tone rewrite.**

- **A5 — Accent is everywhere, so it signals nothing. `T3 T8`** `primary`
  (orange) is the current-card border, the log circle, the FAB, the Focus button,
  the in-progress bar, the rest timer, the loggable highlight, the selected chip.
  In-session, several primary-coloured elements compete on one screen.
  **Narrowed in Phase 3 per Decisions:** the LOG SET circle, the LOG SET / primary
  button, and the current-card border stay orange; the rest timer is demoted to
  its own colour.

### B. Concrete inconsistencies (the `T10` leaks)

- **B1 — The same "in progress" state renders two different ways.**
  `workout_day_picker/widgets/day_tile.dart:83` →
  `StatusBadge.pill(label: 'IN PROGRESS')` (pill, UPPERCASE);
  `program_management/widgets/program_list_tile.dart:204` → `'In progress'` as
  inline title-case text in the metadata line. Same concept, two treatments, two
  casings.

- **B2 — The "in progress" accent bar has two sources for one value.**
  `day_tile.dart:117` → `width: 4` (literal); `program_list_tile.dart:134` →
  `width: AppSpacing.xs` (token, also 4). Identical bar, drawn two ways.

- **B3 — Three different bottom-sheet drag handles.**
  `export/widgets/export_preview_sheet.dart` uses framework `showDragHandle: true`;
  `add_workout_day_sheet.dart:83` hand-rolls `width: 40, height: 4`;
  `library_picker_sheet.dart:276` hand-rolls `width: 36`.

- **B4 — Hard-coded alpha literals bypass `AppOpacity`.**
  - `building_blocks/primary_action_button.dart:55` → `alpha: 0.75`
  - `workout_overview/widgets/reorder_gap.dart:117-118` → `0.55`, `0.4`
  - `workout_overview/widgets/superset_reorder_gap.dart:107` → `0.55`
  - `focus_mode/widgets/focus_rest_timer_bar.dart:41` → `0.18` (note:
    `AppOpacity.recede1` is already exactly `0.18`).

- **B5 — Hard-coded pixel sizes under `screens|widgets/` (CLAUDE.md forbids).**
  - `workout_overview/widgets/set_row.dart:375` → `SizedBox(width: 28)`.
  - `workout_overview/widgets/set_row.dart:501` → `static const _size = 56`
    (should be `AppInSessionSize.controlMin`).
  - `workout_day_picker/widgets/day_tile.dart:176,188` → trailing widths
    `96` / `120`.
  - `program_management/widgets/editor_exercise_tile_content.dart:62,167` →
    `SizedBox(height: 2 / width: 2)` (should be `AppSpacing.xxs`).
  - `workout_overview/widgets/notes_section.dart` → hand-drawn bullet
    `width: 4, height: 4` + magic `top: 6` nudge.

- **B6 — Spinner stroke widths are ungoverned literals.** `strokeWidth: 2` (and
  one `1.5`) at `program_list_tile.dart:89`, `workout_day_save_chip.dart:48`,
  `program_editor_app_bar.dart:78`, `start_resume_action_button.dart:38`,
  `export_preview_sheet.dart:177`, `link_suggestion_screen.dart:234`,
  `library_entry_tile.dart:86`.

> The texture of Section B — a meticulous token system with a scatter of raw
> numbers — *is* the `T10` signature.

---

## Part 4 — The plan

Four phases, ordered by impact-per-risk. Phases 0–2 are safe, mechanical, and
high-confidence. Phase 3 is the design move that changes how the app *feels* and
should be reviewed visually by you (per our workflow, I won't launch the app to
validate — you'll eyeball it).

### Phase 0 — Close the token leaks (mechanical, low-risk) → kills `T10`

No visual change intended; removes the "AI-perfect-but-leaky" tell.

- Alpha literals → `AppOpacity` roles, adding roles where none fits (B4).
- Hard-coded sizes → tokens (B5).
- One spinner-stroke token; point all `CircularProgressIndicator`s at it (B6).
- One bottom-sheet drag handle via `showDragHandle: true`; delete the two
  hand-rolled pills (B3).
- One "in progress" treatment + one accent-bar source (B1, B2).

*Exit:* `grep` for raw `alpha: 0.`, stray pixel literals, and `strokeWidth:`
under `screens|widgets/` comes back clean. Consider a CI guard so the leaks can't
re-accrete (sibling to `tool/check_offline_imports.sh`).

### Phase 1 — Copy mechanics (low-risk; **no tone rewrite**) → kills `T6 T5`

Per Decisions, the neutral voice stays. This phase is *mechanical only*:

- Purge em-dashes from user-facing strings (`recent_sessions_screen.dart`,
  `exercise_library_*`). Rewrite as two sentences or a comma — same meaning,
  same register.
- Replace ` · `-joined fact-lists where they read as generated
  (`program_list_tile.dart`, `program_stats_header.dart`) with plain phrasing,
  keeping the neutral tone. Do **not** add personality or rewrite empty-state /
  confirm-dialog voice.

### Phase 2 — Comment cleanup (T9): strip to minimal → kills `T9`

Per Decisions, **strip to minimal / none**. Remove the design-essay and
checklist-narration comments where the code (and token names) already say it;
keep only genuinely non-obvious notes (e.g. *why* a value can't be const, a
non-intuitive gesture-gating rule). Drop all internal phase IDs ("G8 / Phase
0.5", "the F4 divergence", "G10 / Phase 0.6") and the changelog-style "collapses
the old 0.10 / 0.12 / 0.15 …" narration. Worst offenders: `core/app_*.dart`,
`building_blocks/*`, and the headers of the in-session widgets.

*Guardrail:* this is judgement-heavy. Prefer deleting a comment over rewriting
it; if unsure whether a note is load-bearing, keep a one-line version. No
behaviour changes — comments only.

### Phase 3 — Hierarchy & accent discipline (design; review visually) → kills `T2 T3 A2 A5`

- **Differentiate the start/resume day tile from the housekeeping tiles** so the
  day picker has a clear focal point (the thing to start). Pick from filled vs.
  larger title vs. leading status affordance — I'll mock options for you.
- **Demote the rest timer's orange** (per Decisions): give it its own semantic
  colour so it stops competing with the LOG SET action. Leave the LOG SET circle,
  the LOG SET / primary button, and the current-card border orange.
- **Add a step of type-scale contrast** on list tiles (title vs. metadata) so the
  hierarchy has somewhere to live.

---

## Execution — prompt by prompt

Each prompt below is a **self-contained unit of work**: one focused change, its
files, and its exit criteria, sized to land as a single commit (matching the
repo's `implement prompt N` convention). Run them in order — later prompts assume
earlier ones landed. Feed me one at a time; I'll do exactly that prompt and stop.

Run `tool/ci.sh` after each prompt.

---

**Prompt 1 — Alpha literals → `AppOpacity` (B4).**
Replace every raw `withValues(alpha: …)` literal under `lib/` with an
`AppOpacity` role. Add named roles where none fits: a drag/drop-target-active
role (~0.55) for `reorder_gap.dart` / `superset_reorder_gap.dart`, and route the
rest-timer track fill to an existing role (`recede1` = 0.18 already matches).
Files: `building_blocks/primary_action_button.dart`,
`workout_overview/widgets/reorder_gap.dart`,
`workout_overview/widgets/superset_reorder_gap.dart`,
`focus_mode/widgets/focus_rest_timer_bar.dart`, plus any others a fresh
`grep -rn "alpha: 0\." lib` surfaces.
*Exit:* no raw alpha literals remain under `lib/`; `tool/ci.sh` green.

**Prompt 2 — Hard-coded pixel sizes → tokens (B5).**
`set_row.dart` log circle → `AppInSessionSize.controlMin`; "Set N" column width →
a named `AppSpacing`-derived value; `editor_exercise_tile_content.dart` `2`s →
`AppSpacing.xxs`; `day_tile.dart` trailing `96`/`120` → named constants or
intrinsic sizing; `notes_section.dart` bullet → a tiny shared `Bullet` widget
(no magic `top: 6`).
*Exit:* no stray numeric `width:`/`height:`/`SizedBox` literals under
`screens|widgets/` except where a token genuinely doesn't apply; `tool/ci.sh`
green.

**Prompt 3 — Spinner stroke token (B6).**
Add an `AppStroke.indicator` (or equivalent) and point every
`CircularProgressIndicator(strokeWidth:)` at it. Files: `program_list_tile.dart`,
`workout_day_save_chip.dart`, `program_editor_app_bar.dart`,
`start_resume_action_button.dart`, `export_preview_sheet.dart`,
`link_suggestion_screen.dart`, `library_entry_tile.dart`.
*Exit:* no literal `strokeWidth:` on progress indicators; `tool/ci.sh` green.

**Prompt 4 — One bottom-sheet drag handle (B3).**
Adopt `showDragHandle: true` for `add_workout_day_sheet` and
`library_picker_sheet`; delete their hand-rolled pills so all sheets read from
`bottomSheetTheme.dragHandleColor`. Confirm `export_preview_sheet` already
matches.
*Exit:* zero hand-rolled drag-handle containers; `tool/ci.sh` green.

**Prompt 5 — Unify the "in progress" treatment (B1, B2).**
Pick `StatusBadge.pill` as the single rendering; use it (one casing) in both
`day_tile.dart` and `program_list_tile.dart`. Extract one `InProgressAccentBar`
widget (or at minimum route both to `AppSpacing.xs`) so the accent bar has one
source.
*Exit:* "in progress" looks identical in both tiles; one accent-bar definition;
`tool/ci.sh` green.

**Prompt 6 — Purge em-dashes from UI copy (Phase 1).**
Rewrite every em-dash in a user-facing string as two sentences or a comma, same
meaning and register. Files: `recent_sessions_screen.dart`,
`exercise_library_list_screen.dart`, `exercise_library_editor_screen.dart`, plus
any `grep -rn "—" lib` surfaces in `Text(`/string literals (ignore comments).
*Exit:* no em-dashes in user-facing strings; no tone change; `tool/ci.sh` green.

**Prompt 7 — De-generate the middot metadata (Phase 1).**
Replace ` · `-joined fact-lists that read as generated with plain neutral
phrasing in `program_list_tile.dart` and `program_stats_header.dart`. Keep the
current neutral voice; no personality added.
*Exit:* metadata reads naturally, not as a fact-list; `tool/ci.sh` green.

**Prompt 8 — Strip T9 comments in `core/` + `building_blocks/`.**
Strip-to-minimal the design-essay/changelog/phase-ID comments in
`lib/core/app_*.dart` and `lib/building_blocks/*`. Keep only genuinely
non-obvious notes (one line max). Comments only — no behaviour change.
*Exit:* no phase IDs or changelog narration in these dirs; `tool/ci.sh` green.

**Prompt 9 — Strip T9 comments in module widgets/screens.**
Same treatment across `lib/modules/**/widgets|screens`, starting with the
in-session surfaces (`workout_overview/`, `focus_mode/`) whose headers carry the
most essay. Comments only.
*Exit:* no phase IDs / "collapses the old …" narration in module UI; `tool/ci.sh`
green.

**Prompt 10 — Demote the rest timer's orange (Phase 3, accent).**
Give the rest timer its own semantic colour (both palettes in `AppColors`) so it
no longer shares `primary` with the LOG SET action. Leave the LOG SET circle, the
LOG SET / primary button, and the current-card border orange.
Files: `core/app_colors.dart`, `focus_mode/widgets/focus_rest_timer_bar.dart`.
*Exit:* on a resting focus screen, the LOG SET action is the only orange CTA;
`tool/ci.sh` green. **You review visually.**

**Prompt 11 — Differentiate the start/resume day tile (Phase 3, hierarchy).**
*Blocked on a design pick.* I mock 2–3 treatments (filled / larger title /
leading status) for the actionable `day_tile`; you choose; I implement the chosen
one so the day picker has a clear focal point. Update `product-context.md` only if
the change adds/renames a user-facing surface (it shouldn't).
*Exit:* the day to start out-weights housekeeping tiles; `tool/ci.sh` green.
**You review visually.**

**Prompt 12 — Type-scale contrast on list tiles (Phase 3, hierarchy).**
Add one step of contrast between tile title and metadata across the list tiles so
hierarchy reads at a glance, within the existing `AppTypography` scale.
*Exit:* clearer title/metadata separation; consistent across tiles; `tool/ci.sh`
green. **You review visually.**

---

## Decisions (resolved 2026-05-31)

1. **Home screen — keep current flow.** Opening on the Programs list is
   deliberate; no Today/Home screen. A1 is documented-as-intended, not a defect.
2. **In-session accent — keep orange on the LOG SET circle, the LOG SET / primary
   button, and the current-card border.** Demote only the **rest timer** to its
   own colour (Prompt 10).
3. **Copy voice — keep the current neutral register.** Phase 1 is mechanical only:
   em-dashes (Prompt 6) and middot fact-lists (Prompt 7). No tone/personality
   rewrite of empty states or confirm dialogs.
4. **T9 comments — strip to minimal / none** (Prompts 8–9). Delete over rewrite;
   keep only genuinely non-obvious one-liners. Comments only, no behaviour change.
