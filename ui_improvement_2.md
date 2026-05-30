# UI improvement plan 2 — Zamaj

A second deep-dive review of every screen against (1) modern UI/UX best
practices and (2) the tell-tale signals of LLM-generated UI — this time *after*
the six-slice [round 1](#relationship-to-round-1) pass. It's a **plan/working
artifact**, not a spec, and (like its predecessor) it changes **no** product
scope: no screen is added, removed, or renamed, so [product-context.md](product-context.md)
needs no edit. This is polish on top of polish.

> **Verdict up front:** round 1 worked. The component vocabulary it built
> (`AppStateView`, `AppSkeleton`, `StatusBadge`, `SectionHeader`,
> `AppConfirmDialog`, `PrimaryActionButton`) is real, and the **non-live**
> surface is now genuinely consistent — clean state views, one confirm path,
> tokenized icons, terse microcopy. The remaining problems are narrower and
> sharper, and they cluster in two places:
>
> 1. **The live surface is a time capsule.** `workout_overview/` and
>    `focus_mode/` were deliberately fenced off from slices 1–4 and only
>    partially touched in slice 5. The parts slice 5 didn't name still run
>    *pre-round-1 code* — the exact 48-vs-64 icon, `titleSmall`-vs-`title`
>    heading, and bespoke-state-view drift that round 1 eradicated everywhere
>    else. Two epochs of code now coexist in one app, and the seam is visible.
> 2. **Round 1 opened token slots it never filled.** `AppStroke` was authored
>    and then used **zero** times for emphasis. No token was ever minted for
>    **opacity**, so 15 hand-picked alpha values drift across the codebase the
>    way icon sizes used to. The 4th elevation surface exists but the live
>    panels still fake depth with an alpha ladder.
>
> Round 2 is therefore mostly **finishing** — completing the migration into the
> fenced-off island, and closing the token gaps round 1 left ajar — plus a small
> second tier of duplication (inline notice banners) that round 1's full-screen
> `AppStateView` never covered.

---

## Relationship to round 1

[ui_improvement.md](ui_improvement.md) (now deleted; recoverable at git
`903e71d:ui_improvement.md`) closed findings **F1–F17** across six prompts. This
document does **not** re-litigate those — where round 1 landed, it landed. It
uses a fresh **G-series** (G1–G11) for round-2 findings, and is explicit about
which are *residue* of a round-1 decision (the live surface was intentionally
deferred — see round 1's risk guardrail) versus *new* gaps.

Everything here follows the same house rules round 1 did: presentation only — no
behaviour, data, or bloc changes; every new value is a token in `lib/core/**`
(both palettes); UI reads tokens, never literals; the live surface
(`workout_overview/`, `focus_mode/`) is edited **last**, in one isolated,
sweaty-hands-aware pass.

---

## Part 1 — Deep dive: modern UI/UX best practices (round-2 lens)

Round 1's Part 1 covered the foundational principles (one source of truth per
dimension, components over copies, four states, restrained type scale). Those
still hold. These are the *next-level* principles round 1 didn't get to — the
ones that separate "has a design system" from "the design system is actually
enforced and complete."

### 1.1 A token is only as good as its adoption
Authoring a token does nothing; **migrating callers onto it** is the whole
point. Round 1 authored `AppStroke` (`hairline` 1 / `emphasis` 2) and then never
routed the 2 px emphasis borders through it — so the token is documentation, not
truth, and the literals it was meant to retire are still there (G5). Best
practice: a token lands **with** its migration in the same change, and ideally a
guard (lint / `tool/check_*`) makes the literal illegal afterward. An unadopted
token is worse than no token — it implies a discipline the code doesn't keep.

### 1.2 Opacity is a visual dimension — it deserves a scale
Spacing, radius, color, type, motion, icon size, and stroke are all tokenized
here. **Alpha is not** — and it's just as much a design decision. "A subtle
tinted fill," "a notice border," "a disabled foreground," "a scrim" are
*semantic roles*, and each should map to one alpha, not be re-guessed per file.
Right now the same role takes two or three values (G4). Mature systems expose a
small opacity ramp (e.g. `tintSubtle` / `tint` / `borderTint` / `muted` /
`scrim`) so a tint is *named*, not *numbered*.

### 1.3 On dark, depth is tonal surfaces — applied consistently, not faked twice
Round 1 added the 4th surface (`surfaceElevated`) so modals can sit above cards.
But the focus panels build their own depth out of `surface.withValues(alpha:
0.18 → 0.25 → 0.3 → 0.5)` — a hand-rolled recede ladder that bypasses the tonal
system entirely (G6). And one banner reaches for a literal `Colors.black`
drop-shadow (G6), which is exactly the move the dark-first house style rejects
("depth comes from the lighter surface + outline, not a shadow" —
[app_theme.dart:152](mobile/lib/core/app_theme.dart#L152)). Pick one depth model
and use it for *all* depth.

### 1.4 A half-finished migration manufactures new inconsistency
This is the subtle one. Before round 1, every screen had a bespoke state view —
uniformly bad, but uniform. After a migration that covers 10 of 15 call sites,
the *same role* now has *two* treatments that each look deliberate: the
`AppStateView` look (icon 64, heading `title`) and the legacy look (icon 48,
heading `titleSmall`). A user who sees the recent-sessions error and then the
focus-mode error sees two different designs (G1). Partial migration doesn't
halve the drift — it relocates and disguises it. Best practice: a component
migration is **all or nothing per role**; if the live surface must wait, it
waits as a *tracked* island, not a forgotten one.

### 1.5 "Inline notice" is a component family, just like "empty state"
Round 1 unified the **full-screen** state (`AppStateView`). But the **inline**
sibling — a one-line error/warning/info strip pinned above a list or inside a
card — is its own recurring molecule, and it's currently re-authored four times
(G2). A complete system has *both*: a full-bleed state for "this whole screen is
empty/broken," and a compact banner for "this thing went wrong but the screen is
otherwise fine." They should look like relatives, sized by the same tokens.

### 1.6 Consistency *across the states of one screen*, not just across screens
A screen is loading, then loaded, then maybe failing. The chrome that frames all
three — the app bar title especially — should behave by one rule. Today some
screens keep a stable title and put state in the body (`program_list`), while
others mutate the **title** to mirror the state, surfacing `'Loading…'` and
`'Could not load sessions'` in the app bar *and* repeating them in the body's
`AppStateView` (G8). Decide once: is the title an anchor or a status line?

### 1.7 Don't bypass the theme you went to the trouble of defining
`inputDecorationTheme`, `dividerTheme`, and the button themes exist precisely so
a field/divider/button looks the same everywhere for free. When a widget
re-specifies `filled` / `fillColor` / `OutlineInputBorder` by hand (the three
focus numeric panels) or re-draws a `Divider(height: 1, thickness: 1)` the theme
already provides (G7), it's both redundant and a drift risk — the local copy
won't track a future theme change. If a one-off genuinely needs to differ,
that's a sign the *theme* needs a variant, not that the call site should fork.

---

## Part 2 — Deep dive: tell-tale signals of AI-generated UI (the subtler tier)

Round 1's Part 2 catalogued the loud tells (15 bespoke state views, two
`_SkeletonBar` copies, icon-size soup). Those are gone. What's left is the
quieter, more *interesting* layer — the tells that survive a first cleanup pass
and specifically betray **how** this app was built: screen-by-screen, then
partially unified, by a tool that explained itself as it went.

### 2.1 The residue island — code from two epochs in one repo (the #1 remaining tell)
The single loudest signal now is **internal inconsistency in time**: most of the
app speaks round-1 vocabulary, but `workout_overview/` and `focus_mode/` still
speak the original dialect. The focus error view uses `Icon(size: 48)` and a
`titleSmall` heading ([focus_mode_state_views.dart:66](mobile/lib/modules/focus_mode/widgets/focus_mode_state_views.dart#L66));
the focus *complete* view three files over uses `Icon(size: 64)` and a `title`
heading ([focus_workout_complete_view.dart:28](mobile/lib/modules/focus_mode/widgets/focus_workout_complete_view.dart#L28)) —
the **exact** 48-vs-64 / `title`-vs-`titleSmall` split round 1 called out as F7/F8
and fixed everywhere a human would have looked first. A person refactoring the
app would have swept the whole tree; an agent told "don't touch the live surface
in slices 1–4" left a clean fault line through the middle of the codebase. That
fault line is the fingerprint.

### 2.2 Magic-number alpha soup (the color analog of icon-size soup)
Round 1 killed the `size: 18` / `size: 20` icon soup. The identical pathology
survives one layer down, in **opacity**: 15 distinct `withValues(alpha:)` values,
with the same role taking different numbers in different files — a "primary
tinted fill" is `0.08` in [superset_drop_target.dart:145](mobile/lib/modules/workout_overview/widgets/superset_drop_target.dart#L145),
`0.10` in [set_row.dart:515](mobile/lib/modules/workout_overview/widgets/set_row.dart#L515),
and `0.12` in [library_link_chip.dart:22](mobile/lib/modules/program_management/widgets/library_link_chip.dart#L22);
an "error notice border" is `0.4`, `0.5`, **and** `0.6` across the four banners.
Every value is plausible; no value is shared. That "locally-reasonable,
globally-arbitrary" texture is the same tell, just in the one dimension round 1
never tokenized.

### 2.3 Near-twin widgets that diverge only in trivia
[DomainErrorBanner](mobile/lib/modules/program_management/widgets/domain_error_banner.dart)
and [TransientErrorBanner](mobile/lib/modules/workout_overview/widgets/transient_error_banner.dart)
are the same banner — same `error` @ `0.12` fill, same `error` @ `0.4` border,
same `AppRadius.md`, same icon + `label`/`error` title + `bodySmall` body +
close affordance. They differ *only* in the kind of detail two separate
generations would differ on: one uses `AppIcon` (tokenized), the other raw
`Icon(size: 20)`; one closes with a `GestureDetector`, the other with a 48 dp
`IconButton`; one spaces the title and body with `AppSpacing.xs`, the other with
a literal `SizedBox(height: 2)`. When two widgets agree on everything that's hard
and disagree on everything that's trivial, they weren't copied — they were
*re-derived*.

### 2.4 Bypassing the theme that was just built
A tell specific to a *partially* systematized codebase: the global
`inputDecorationTheme` exists and is used by every `TextField` on the non-live
surface, but the three focus numeric panels each hand-roll `filled` + `fillColor:
colors.surfaceVariant` + an `OutlineInputBorder`
([focus_rep_based_panel.dart:219](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L219)).
An agent generating the focus panel in isolation reconstructs the decoration
from scratch because it can't "see" that a theme already encodes it.

### 2.5 Dead tokens — authored, documented, never used
`AppStroke.emphasis` (2) has a docstring explaining it's "the 2 px stroke
reserved for focused / active borders" and **zero** usages
([app_spacing.dart:33](mobile/lib/core/app_spacing.dart#L33)); the five places
that draw a 2 px active border hard-code `width: 2` (or `2.0`) right next to the
token that exists for it. A token written but never wired in is the residue of
"author the abstraction, then generate the consumers separately."

### 2.6 Decorative shadow on a dark-first canvas
`BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 8 …)` on the
focus transient error banner ([focus_mode_state_views.dart:117](mobile/lib/modules/focus_mode/widgets/focus_mode_state_views.dart#L117))
is the generic Material "elevated container" reflex applied to a near-black UI
where it does almost nothing — and it's the only drop-shadow in the app's notice
surfaces. Stock-Material muscle memory poking through the custom skin.

### 2.7 Self-justifying rationale comments (carryover)
Still present, still a meta-tell: comments that *argue for* the design rather
than describe it — "the card's 2dp primary border is the 'current' signal on its
own" ([exercise_card.dart:338](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L338)),
"Replace is no longer in the kebab — the icon button above owns it"
([exercise_card.dart:392](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L392)).
Harmless, occasionally useful, but a reliable signature. Out of scope to chase;
noted for honesty.

---

## Part 3 — Findings inventory

Cross-cutting issues with concrete evidence. **P1** = visible inconsistency a
user feels; **P2** = drift that erodes polish; **P3** = code-health /
low-visibility. "Residue" marks a finding that is leftover from round 1's
deliberate live-surface deferral; "new" marks a gap round 1 didn't scope.

| # | Area | Finding | Evidence | Sev | Kind |
|---|------|---------|----------|-----|------|
| G1 | State views | 5 live-surface state views never moved to `AppStateView`; reproduce the 48-vs-64 icon + `titleSmall`-vs-`title` drift round 1 fixed (F7/F8) | [focus_mode_state_views.dart](mobile/lib/modules/focus_mode/widgets/focus_mode_state_views.dart) (NotFound L31, Error L66), [workout_overview_error_view.dart](mobile/lib/modules/workout_overview/widgets/workout_overview_error_view.dart) (Error L29, NotFound L70), [focus_workout_complete_view.dart:28](mobile/lib/modules/focus_mode/widgets/focus_workout_complete_view.dart#L28) | **P1** | residue |
| G2 | Inline notice | One "inline error/notice banner" re-implemented 4× (3 hand-rolled `Container`s + 1 `MaterialBanner`); border-alpha drifts 0.4/0.5/0.6; no shared component | [domain_error_banner.dart](mobile/lib/modules/program_management/widgets/domain_error_banner.dart), [transient_error_banner.dart](mobile/lib/modules/workout_overview/widgets/transient_error_banner.dart), [focus_mode_state_views.dart:94](mobile/lib/modules/focus_mode/widgets/focus_mode_state_views.dart#L94), [workout_day_picker_screen.dart:248](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L248) | **P1** | new |
| G3 | Icon sizes | 31 raw `Icon(size:)` literals on the live surface never migrated to `AppIcon`/`AppIconSize` (F8 residue — round 1 deferred); same role drifts 12/16/18/20/24/48/64 | `workout_overview/` + `focus_mode/` (e.g. [exercise_card.dart:319](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L319),L416,L424; [focus_time_based_panel.dart:154](mobile/lib/modules/focus_mode/widgets/focus_time_based_panel.dart#L154)) | **P2** | residue |
| G4 | Opacity | No opacity token; 15 distinct `withValues(alpha:)` values, same role takes 2–3 (primary tint 0.08/0.10/0.12; notice border 0.4/0.5/0.6) | repo-wide (40+ sites; see §2.2) | **P2** | new |
| G5 | Stroke | `AppStroke.emphasis` used **0×**; 5 raw `width: 2`/`2.0` active borders + one untokenized `width: 1.5` | [app_spacing.dart:33](mobile/lib/core/app_spacing.dart#L33) vs [exercise_card.dart:103](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L103), [set_row.dart:516](mobile/lib/modules/workout_overview/widgets/set_row.dart#L516), [editor_flat_exercise_row.dart:191](mobile/lib/modules/program_management/widgets/editor_flat_exercise_row.dart#L191), [editor_superset_card.dart:224](mobile/lib/modules/program_management/widgets/editor_superset_card.dart#L224), [drag_handle.dart:117](mobile/lib/modules/workout_overview/widgets/drag_handle.dart#L117), [focus_current_panel_card.dart:40](mobile/lib/modules/focus_mode/widgets/focus_current_panel_card.dart#L40) | **P2** | new |
| G6 | Elevation/depth | Focus panels fake depth with a `surface` alpha ladder (0.18/0.25/0.3/0.5) instead of tonal tokens; a literal `Colors.black` drop-shadow violates the dark-first no-shadow rule; drag feedback uses untokenized `elevation: 4`/`8` | [focus_previous_panel_card.dart:56](mobile/lib/modules/focus_mode/widgets/focus_previous_panel_card.dart#L56), [focus_up_next_strip.dart:31](mobile/lib/modules/focus_mode/widgets/focus_up_next_strip.dart#L31), [focus_upcoming_panel_card.dart:59](mobile/lib/modules/focus_mode/widgets/focus_upcoming_panel_card.dart#L59), [focus_current_panel_card.dart:38](mobile/lib/modules/focus_mode/widgets/focus_current_panel_card.dart#L38), [focus_mode_state_views.dart:117](mobile/lib/modules/focus_mode/widgets/focus_mode_state_views.dart#L117), [drag_handle.dart:107](mobile/lib/modules/workout_overview/widgets/drag_handle.dart#L107) | **P2** | new |
| G7 | Theme bypass | 3 focus numeric panels re-specify `filled`/`fillColor`/`OutlineInputBorder` instead of `inputDecorationTheme`; 2 `Divider`s re-draw `height/thickness: 1` the `dividerTheme` already sets | [focus_rep_based_panel.dart:219](mobile/lib/modules/focus_mode/widgets/focus_rep_based_panel.dart#L219), focus_time_based_panel, focus_bodyweight_panel; [exercise_card.dart:544](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L544) | **P2** | new |
| G8 | App-bar titles | Title-across-states is inconsistent: `program_list`/`exercise_library_list` keep a stable title; `recent_sessions`/`workout_day_picker` mutate it per state, surfacing `'Loading…'`/`'Could not load sessions'` in the bar *and* the body | [recent_sessions_screen.dart:45](mobile/lib/modules/export/screens/recent_sessions_screen.dart#L45), [workout_day_picker_screen.dart:138](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L138) | **P3** | new |
| G9 | Microcopy | Not-found title punctuation drifts: `'Workout day not found.'` / `'Library entry not found.'` (period, statement) vs `'Program not found'` / `'Session not found'` (none) | [workout_day_editor_screen.dart:150](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L150), [exercise_library_editor_screen.dart:210](mobile/lib/modules/exercise_library/screens/exercise_library_editor_screen.dart#L210) | **P3** | new |
| G10 | Spacing | Untokenized magic dims: mini-button heights `Size(0, 36)` / `Size(0, 32)`; loose `SizedBox(width: 2/4)`, `EdgeInsets.only(top: 6)` | [workout_day_list_tile.dart:353](mobile/lib/modules/program_management/widgets/workout_day_list_tile.dart#L353), [exercise_card.dart:591](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L591), [focus_panel_header.dart:65](mobile/lib/modules/focus_mode/widgets/focus_panel_header.dart#L65), [workout_day_list_tile.dart:300](mobile/lib/modules/program_management/widgets/workout_day_list_tile.dart#L300) | **P3** | new |
| G11 | Stock Material | Live-surface PopupMenu items are stock `ListTile` + leading `Icon` (un-tokenized icon sizes, default densities) where the menu could be a small themed row | [exercise_card.dart:441](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L441) | **P3** | new |

---

## Part 4 — The plan

Four vertical slices, one prompt / one PR each, in the round-1 mould: **build a
token/component *and* migrate its consumers in the same pass**, low-risk first,
the live surface **last** and **isolated**. Decisions (Phase 0) are settled up
front so each slice is authored against a fixed target.

### Phase 0 — Decisions (CLOSED)

These were the open forks; all are now settled (interrogated 2026-05-30).
Everything downstream is authored against them.

1. **Opacity → a small semantic scale, collapsed to canonical (G4). ✅**
   Author `AppOpacity` in `lib/core/` with a *minimal* named ramp; map each role
   to **one** value and accept the near-imperceptible shifts (0.10 → `tintFill`,
   0.5/0.6 notice-border → `borderTint`, 0.15/0.18 → `tintFill`). The point is
   true consistency, not preserving the current drift. Proposed names/values:
   - `tintFill` = **0.12** (the dominant notice/badge fill; the most common
     existing value),
   - `tintFillSubtle` = **0.08** (faint drag/hover wash),
   - `borderTint` = **0.4** (notice/badge hairline border over a tint),
   - `muted` = **0.5** (disabled foreground / secondary glyph),
   - reuse the existing `scrim` **color token** for overlays rather than minting
     `background.withValues(alpha: 0.6)` ad hoc.
   The focus recede ladder (0.18/0.25/0.3/0.5) is a **separate axis** — it lands
   in Phase 0.3, not on this scale.
2. **Stroke → adopt the token that already exists (G5). ✅** No new token. Route
   every active/focused 2 px border through `AppStroke.emphasis` and every
   hairline through `AppStroke.hairline`. **Collapse the lone `1.5` to
   `emphasis` (2)** — canonical-over-bespoke, same philosophy as the opacity
   call; don't mint a thin step for one site.
3. **Depth → tokenize the ladder, keep the look (G6). ✅** Chose option (a): the
   focus recede ladder is a *de-emphasis* effect (cards fade toward the
   background as they leave "current"), **not** modal elevation, so it is **not**
   flattened onto `surfaceElevated`. Name the 0.18/0.25/0.3/0.5 steps as a
   `recede1…recede4` surface-tint scale (in `AppOpacity`); focus panels look
   exactly as they do today, just sourced from tokens. Separately: **delete the
   `Colors.black` drop-shadow** (depth = lighter surface + outline), and keep
   **one sanctioned shadow** — `AppElevation.drag` — for the lifted drag proxy
   only (the one place a shadow earns its keep, per Material drag convention);
   tokenize the current `elevation: 4`/`8` onto it.
4. **Inline notice → one `AppNoticeBanner`, inline strips only (G2). ✅** A
   compact strip: tone (`error`/`warning`/`info`), icon, title + optional body,
   optional dismiss / action. Chrome from the `AppOpacity` tints +
   `AppStroke.hairline`; sibling to `AppStateView`, not a replacement.
   Hand-rolled `Container` (not `MaterialBanner`) so it inherits the house tints,
   with the picker's `MaterialBanner` folded in too. **Scope is the 4 persistent
   in-layout banners only** — transient `SnackBar`/toast styling stays as-is
   (a different, transient pattern; out of scope this round).
5. **App-bar title → an anchor, not a status line (G8). ✅** The title shows the
   screen's identity (`'Programs'`, `'Recent sessions'`, or the contextual
   *program name* on the picker's loaded state). It does **not** become
   `'Loading…'` / `'Could not load sessions'` — those live in the body
   `AppStateView` only. Loaded-state contextual titles (program name) are fine.
6. **Inline compact action height → one named token (G10). ✅** The sub-48 dp
   inline buttons (`Size(0, 32)` "Open video", `Size(0, 36)` duplicate-day) are
   **not** primary actions, so a sub-`touchMin` height is defensible. Pick a
   single value (**36**) as a named compact-action height token and route both
   onto it — killing the 32-vs-36 drift while keeping the dense inline feel.
   (Not bumped to 48; these aren't the live-session sweaty-hands controls.)
7. **Enforcement → convention only (no CI guard). ✅** No new `tool/check_*`
   gate for alpha/stroke literals; rely on the CLAUDE.md token rule + review.
   (So the *migration completeness* in each slice carries the weight — land the
   token **with** its callers, every caller, or the soup quietly regrows.)
8. **Live surface stays last and isolated.** Slices 1–3 never touch
   `workout_overview/` or `focus_mode/`. Slice 4 is the only one that does — the
   high-risk, sweaty-hands-aware pass. Re-read the CLAUDE.md sweaty-hands section
   before it.

### Execution order at a glance

| # | Slice (one prompt each) | Builds | Closes | Live surface? | Risk |
|---|-------------------------|--------|--------|---------------|------|
| 1 ✅ | Token gaps: opacity + stroke + depth policy | `AppOpacity`, adopt `AppStroke`, `AppElevation.drag` | G4¹, G5¹, G6¹ | no | low |
| 2 | `AppNoticeBanner` + non-live migration | `AppNoticeBanner` | G2¹ | no | low |
| 3 | Screen-consistency polish (non-live) | title rule, copy, spacing tokens | G8, G9, G10¹, G11¹ | no | low |
| 4 | **Live-surface finish** (isolated) | — (migration only) | G1, G3, G7, plus live halves of G2/G4/G5/G6/G10/G11 | **yes** | **high** |

¹ non-live half only; the live remainder closes in slice 4.

---

### Prompt 1 — Token gaps: opacity, stroke, depth ✅ COMPLETE (2026-05-30)
> **Done.** `AppOpacity` ([app_opacity.dart](mobile/lib/core/app_opacity.dart))
> and `AppElevation` ([app_elevation.dart](mobile/lib/core/app_elevation.dart))
> authored; every **non-live** alpha/stroke/elevation literal migrated onto a
> token (fills/badges → `tintFill`, notice/badge borders → `borderTint`,
> disabled foregrounds → `muted`, `background@0.6` scrims → the `scrim` color
> token, the chip `selectedColor` 0.18 → `tintFill`); the theme focus border +
> the two editor drop-target borders → `AppStroke.emphasis`; both editor drag
> feedbacks → `AppElevation.drag`. `recede1…recede4` + `tintFillSubtle` are
> authored now and consumed by the **live** surface in slice 4. **`AppElevation.drag`
> = 8** (the live drag handle's existing value, the more deliberate lifted-proxy
> step; the editor's mid-drag 4→8 shift is imperceptible on the near-black
> canvas). **Deliberately left:** `primary_action_button`'s `onPrimary @ 0.75`
> sub-label — an *enabled* secondary-foreground singleton, outside the three
> targeted role families and the ramp; collapsing it to `muted` (0.5) would be a
> wrong-role mapping that visibly dims the CTA sub-label. `tool/ci.sh` green
> (format/analyze clean, 633 tests pass).
- **Build:** `AppOpacity` (Phase 0.1 ramp, both-palette-agnostic — alpha is
  brightness-independent so it lives in one place); adopt `AppStroke` (no new
  token, just wire it); add `AppElevation.drag` (the single sanctioned shadow,
  Phase 0.3).
- **Migrate (non-live only):** swap every non-live `withValues(alpha: …)` magic
  number onto `AppOpacity` (notice fills/borders, chip/badge tints, disabled
  foregrounds); replace `background.withValues(alpha: 0.6)` scrims with the
  `scrim` token; route non-live `width: 2` borders through `AppStroke.emphasis`;
  point the editor drag elevations (`editor_flat_exercise_row`,
  `editor_superset_card`) at `AppElevation.drag`.
- **Closes:** G4 (non-live), G5 (non-live), G6 (non-live shadow/elevation).
- **Verify:** `tool/ci.sh`. Pure value swap — visual diff should be ~nil.
- **No CI guard** (Phase 0.7): convention only. The safety net is *migration
  completeness* — every non-live alpha/stroke literal moves onto a token in this
  same pass, leaving no stragglers to seed a new soup.

### Prompt 2 — `AppNoticeBanner` + non-live migration
- **Build:** `AppNoticeBanner` in [building_blocks/](mobile/lib/building_blocks/)
  (Phase 0.4) — tone, icon, title, optional body, optional dismiss/action;
  chrome from `AppOpacity` + `AppStroke`.
- **Migrate (non-live):** delete `DomainErrorBanner` and the picker's
  `_TransientErrorBanner` (`MaterialBanner`), route their call sites through
  `AppNoticeBanner`. Leave the two **live** banners
  (`workout_overview/transient_error_banner`, `focus`'s `FocusTransientErrorBanner`)
  for slice 4.
- **Closes:** G2 (non-live half).
- **Verify:** `tool/ci.sh`.

### Prompt 3 — Screen-consistency polish (non-live)
- **App-bar titles (G8):** apply the Phase 0.5 rule — stop surfacing
  `'Loading…'` / `'Could not load sessions'` in `recent_sessions` /
  `workout_day_picker` app bars; keep a stable identity title (loaded-state
  program name is fine), state stays in the body.
- **Microcopy (G9):** normalize not-found titles to no terminal period
  (`'Workout day not found'`, `'Library entry not found'`), matching
  `'Program not found'` / `'Session not found'`.
- **Spacing (G10, non-live):** tokenize the magic mini-button heights and loose
  literals (`Size(0, 36)`, `top: 6`, `width: 4`) onto `AppSpacing` /
  `AppInSessionSize`; if a sub-`touchMin` inline button height is genuinely
  needed, add one named token rather than a bare `32`/`36`.
- **Stock Material (G11, non-live):** only if any non-live `PopupMenu`/`ListTile`
  patterns remain after round 1 — most already inherit the theme; verify and
  leave the live one for slice 4.
- **Closes:** G8, G9, G10 (non-live), G11 (non-live).
- **Verify:** `tool/ci.sh`.

### Prompt 4 — Live-surface finish *(careful, last, isolated)*
> **Re-read the CLAUDE.md sweaty-hands section before starting.** This is the
> only slice that edits `workout_overview/` and `focus_mode/`; a real session is
> the visual sign-off (per round 1 / colors.md §6). Isolated PR.
- **State views (G1):** migrate all 5 live state views to `AppStateView` —
  `FocusNotFoundView`, `FocusErrorView`, `WorkoutOverviewErrorView`,
  `WorkoutOverviewNotFoundView`, and `FocusWorkoutCompleteView` (the last as
  `AppStateTone.success`). Delete the bespoke `Column`s; the icon-size and
  heading drift dies with them.
- **Icons (G3):** migrate the 31 live `Icon(size:)` literals onto
  `AppIcon`/`AppIconSize` (the residue F8 explicitly deferred in round 1's
  Prompt 5).
- **Inline notice (G2 live):** route `transient_error_banner` and
  `FocusTransientErrorBanner` through `AppNoticeBanner`; **drop the
  `Colors.black` drop-shadow** in the process.
- **Stroke (G5 live):** `exercise_card` / `set_row` / `drag_handle` active
  borders → `AppStroke.emphasis`; settle the focus card's `1.5`.
- **Depth (G6 live):** replace the focus `surface.withValues(alpha:)` recede
  ladder with the Phase 0.3 named tints; point `drag_handle`'s `elevation: 8` at
  `AppElevation.drag`.
- **Theme bypass (G7):** route the three focus numeric panels through
  `inputDecorationTheme` (or a named theme variant if they must differ); drop the
  hand-drawn `Divider(height: 1, thickness: 1)` in favour of the `dividerTheme`
  default.
- **Spacing/Material (G10/G11 live):** tokenize the live magic dims; tidy the
  exercise-card popup menu if it can share a themed row without behaviour change.
- **Closes:** G1, G3, G7, and the live remainder of G2, G5, G6, G10, G11.
- **Verify:** `tool/ci.sh` (domain+persistence only — no widget tests, per
  CLAUDE.md), then **run a real session** as the sign-off.

---

## Risk notes
- **Slices 1–3 are low-risk** and never touch the live surface. **Slice 4 is the
  only high-risk one** — components are proven on the non-live surface first,
  exactly as round 1 sequenced it.
- **No one-way doors.** Every change is a presentational value/component swap;
  nothing here touches the palette (Ember is settled), data, blocs, or product
  scope.
- **Out of scope:** any new screen/feature; `product-context.md` (no change);
  re-theming beyond token adoption; light-mode polish (still deferred — verify
  token-correctness/compile only); the rationale-comment style (§2.7 — noted,
  not chased).

## What to deliberately keep
Everything round 1's "keep" list named (dark-first canvas, planned-vs-actual as
a value pair, the single rationed accent, tabular numerics, thoughtful haptics,
the four-states discipline, sweaty-hands sizing) — **plus** the round-1
component vocabulary itself (`AppStateView`, `StatusBadge`, `SectionHeader`,
`AppConfirmDialog`, `PrimaryActionButton`, the unified stepper). Round 2 doesn't
redesign any of it; it finishes carrying that vocabulary across the last fence
and names the two dimensions (opacity, stroke) that were still being guessed.
