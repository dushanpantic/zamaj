# Workout Overview — UX Improvement Plan

## 1. Reframing the screen

Today the Workout Overview behaves like a stack of editors: every unfinished exercise is force-expanded so its inline LOG SET editor is always visible. That made sense when the overview was the only in-session surface — but **Focus mode is now the primary logging surface**. The overview's job is to be the **map** of the session, not the cockpit.

A useful reframe: the overview is the *plan + status* view. Its real jobs, in order:

1. **Situational awareness** — "where am I, what's done, what's next, how long have I been here." Quick scan, no scrolling required for typical 5–8 exercise days.
2. **Course correction** — equipment busy, need to swap; want to reorder; want to form/break a superset; want to mark something done early or skip.
3. **Jump back into Focus** — one tap to resume on the current exercise (or pick a different one).
4. **Inline logging (escape hatch)** — possible, but no longer the dominant interaction. Used for one-off accessories the user is breezing through without engaging Focus mode.

Optimising for jobs 1–3 is what fixes the clutter. Job 4 still works — it just stops being the default.

## 2. Problems with the current screen (evidence-based)

### 2.1 Force-expansion = visual clutter
[workout_overview_bloc.dart:396-415](mobile/lib/modules/workout_overview/bloc/workout_overview_bloc.dart#L396-L415) auto-expands every exercise present in `openTargets` on every state refresh and on first load. For a typical "all unfinished" workout this means every card opens its `_ExpandedBody`, which renders:

- a per-set row showing planned vs. actual + status icon ([set_row.dart:308-339](mobile/lib/modules/workout_overview/widgets/set_row.dart#L308-L339))
- for the loggable row: a 64×64 step button, a 36-px `numericLarge` field, another 64×64 step button, then a **56 dp `LOG SET` button** ([set_row.dart:432-472](mobile/lib/modules/workout_overview/widgets/set_row.dart#L432-L472))
- multiplied by 1–2 fields (weight + reps, or duration + optional weight)

Net: a single rep-based exercise with one loggable row consumes roughly **250–300 dp** of vertical space — and most of it duplicates what Focus mode already shows better. On a 6-exercise day the user must scroll past ~1.6k dp of editors to see the bottom of the list, even though they almost never need any of them.

The card also already has a 48 dp expand chevron in its header ([exercise_card.dart:418-422](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L418-L422)), so the affordance to open the editor on demand is already in place — the auto-expand is overriding the user's choice.

### 2.2 "Tap to log" is a false signifier
[set_row.dart:367-372](mobile/lib/modules/workout_overview/widgets/set_row.dart#L367-L372) renders the literal text **"Tap to log"** for loggable rows that have no executed set yet. Right next to it sits a primary-coloured `radio_button_unchecked` icon ([set_row.dart:395-399](mobile/lib/modules/workout_overview/widgets/set_row.dart#L395-L399)) that **looks like a button but does nothing**: the only tappable area inside `_Header` is the surrounding `InkWell` ([set_row.dart:278-287](mobile/lib/modules/workout_overview/widgets/set_row.dart#L278-L287)), and that ink-well is only enabled for `completed`/`trailing` rows (its `onTap` is `null` for loggable). Logging actually happens via the LOG SET button further down. So the user is told "tap to log" next to a circle that doesn't respond. Classic affordance/signifier mismatch (Norman): the system is lying about what the user can do.

This was probably correct in an earlier design where the row was the action surface. It's vestigial now.

### 2.3 Density crowds out the things the screen is actually for
The information that matters for jobs 1–3 — exercise name, planned summary, progress (`3/5`), state badge, rest, kebab — *is* in the header. But it's competing with the always-open editor for attention. Hierarchy is inverted: the management layer is what the user came for, and it's de-emphasised under the editing layer.

The kebab menu is fine in principle, but `Replace` is the single most likely action on this screen (per the user's brief: "equipment busy"). Burying it one tap deeper than `LOG SET` doesn't match frequency.

### 2.4 "Current exercise" is invisible
The overview has no signal that says "this is the one Focus mode will open." The Focus button at the bottom *will* open `openTargets.first`, but the user can't see which card that is without inferring from order/state. The `lastTouchedSessionExerciseId` hint in [workout_overview_state.dart:83-84](mobile/lib/modules/workout_overview/bloc/workout_overview_state.dart#L83-L84) only highlights *after* a log, not before — useless if the user is arriving on the screen mid-session.

### 2.5 Per-card Focus is missing
The bottom-bar Focus button always anchors to `openTargets.first`. If the user wants to focus on a *different* unfinished exercise (e.g. wants to do a later accessory now), they have no per-card hook. A small Focus affordance per unfinished card closes this gap.

## 3. UI/UX principles guiding the fix

| Principle | Where it bites here |
|---|---|
| **Progressive disclosure** (Nielsen) | Don't open editors the user hasn't asked for. Collapse by default; reveal on demand. |
| **Signifiers match affordances** (Norman) | Don't say "tap to log" next to a non-tappable icon. Tappable things look tappable; static things don't. |
| **Match screen to primary job** | Overview is for orientation + correction. Optimize chrome for that, not for logging. |
| **Recognition over recall** | Show the user where they are. Mark the "current" exercise; don't make them count. |
| **Fitts's Law (sweaty-hands variant)** | 48 dp floor is enforced — but on overview, *which* targets exist matters more than their size. Fewer, clearer targets per card. |
| **Information density vs. scan-ability** | Collapsed-card content should fit in one fixed-height row per exercise so a 6–8 exercise day fits without scrolling on a typical 6" phone. |
| **One primary action per surface** | The single primary action on overview is **Focus** (jump into logging). Everything else is secondary. |

## 4. Concrete improvements

These are ordered so each builds on the previous; you can ship them in batches.

### P0 — Stop auto-expanding everything
**Change**: rewrite `_expansionForOpenTargets` ([workout_overview_bloc.dart:396](mobile/lib/modules/workout_overview/bloc/workout_overview_bloc.dart#L396)) and `_initialExpansionFor` ([workout_overview_bloc.dart:386](mobile/lib/modules/workout_overview/bloc/workout_overview_bloc.dart#L386)) so that:

- **Initial expansion is empty** — `_initialExpansionFor` returns `{}`.
- **Refresh keeps the user's manual choice.** A card the user opened stays open until they collapse it or the exercise hits a terminal state with all sets logged. Refresh no longer *adds* loggable cards to the set.
- Loggable status is communicated by other means (state badge, the "current" treatment in P1) — not by force-opening the editor.

**Why**: turns a wall of editors into a scannable list. The user can still tap the chevron / card header on any card to open its editor when they want to log inline. Matches the user's mental model that overview ≠ logging surface.

**Edge case**: when a user is mid-edit on a loggable row and a refresh comes in (e.g. autosave from another mutation), the editor must not slam shut. `SetRow._editingExisting` guards this for completed rows; for loggable rows, the card-expansion flag is what guards. Since this change only stops *adding* IDs to the set on refresh, anything the user opened stays open — no regression.

**Tests**: update bloc tests that assert auto-expansion (`test/.../workout_overview_bloc_test.dart`). The "loggable cards are auto-expanded on initial load" expectation flips to "no cards are expanded on initial load".

### P0 — Kill the misleading "Tap to log" affordance
**Change** in [set_row.dart:367-372](mobile/lib/modules/workout_overview/widgets/set_row.dart#L367-L372):

- For `loggable` mode with no executed set, drop the "Tap to log" string. Render the actual column as `—` (same as `future`/`completed`-empty).
- Change the status icon for `loggable` mode from `radio_button_unchecked` to something that does *not* read as a button: e.g. `Icons.adjust` at the same `colors.primary` (still signals "this is the active one"), or a small primary-coloured dot. The point is "indicator, not control."
- Leave the LOG SET button as the only signifier for logging — which it already is, and which it visually reads as.

**Why**: closes the affordance/signifier gap. The user's complaint is correct; the fix is removing the lie, not adding behaviour.

**Alternative considered, rejected for now**: make the circle *actually* log planned values verbatim ("quick-log"). Tempting (one-tap accessory logging), but risks accidental logs from a wet thumb, and adds a third path to a flow that already has LOG SET + Focus mode. Reconsider only if the user later asks for quick-log explicitly.

### P1 — Mark the "current" exercise
**Change**: in the assembled `groups` list, identify the *first* unfinished exercise (or first member of the first unfinished superset). On its `ExerciseCard`:

- Apply a left accent border (2 dp, `colors.primary`) or a thin top accent strip.
- Show a small `CURRENT` chip in the header next to the state badge (or replace the empty state-badge slot for unfinished current).
- Auto-expand **this one card** (and only this one) on first load. This is the single sanctioned auto-expand: it preserves "open the screen, log immediately if you want" while removing the wall.

**Why**: gives the user the recognition cue P0 strips out. Anchors the Focus button (which already targets `openTargets.first`) visually. Matches the Focus screen's "one exercise at a time" model.

**Implementation note**: the "current" identity comes from `openTargets.first.sessionExerciseId`, the same value the Focus button uses ([workout_overview_screen.dart:184-194](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L184-L194)). For a superset, all members of the active group should get the chip; expand only the first member, to keep height bounded.

### P1 — Promote Replace to a card-level affordance
**Change**: when an exercise is unfinished and `canMutate`, surface a `Replace` text button in the card header (right side, before the kebab). Drop the duplicate `Replace` entry from the kebab to avoid two paths.

**Why**: the user's brief calls equipment-busy → replace the canonical "things went wrong" flow. Frequency-of-use should match depth-of-access. The kebab still owns the less common actions: Skip, Mark done, Group into superset, Open video.

**Counterpoint**: adds a second control to the header row, which is what we're trying to declutter. Mitigation: the action row inside `_Actions` already has the chevron + kebab; adding a compact `Replace` icon-button (24 dp tap target inside the 48 dp slot, using `Icons.swap_horiz`) is a single extra glyph. Test on a real device — if it crowds the title at small widths, fall back to keeping it in the kebab.

### P1 — Per-card Focus affordance for the "current" card
**Change**: on the marked-current card, render a small inline "Focus →" button at the end of the header (small, secondary, e.g. text button). It does the same navigation as the bottom bar's Focus button. Hide on non-current cards.

**Why**: makes Focus reachable from where the user's eye already is, without forcing them down to the bottom bar. Also a fallback if the user wants to grab a *different* exercise: tap that card's chevron to expand → log inline, **or** scroll up/down to the next exercise and use whatever exercise becomes current.

**Defer**: per-card Focus on *any* unfinished card (not just current) is the bigger change. Worth doing only if the user asks for it — adds chrome to every card.

### P2 — Compact collapsed-card layout
With expansion gone by default, the collapsed card is the dominant unit. Audit `_Header` for density wins:

- Drop the `_RestIndicator` from the collapsed header into the expanded body (rest only matters when you're actively between sets — and at that point you're in Focus mode, not here).
- Tighten the header padding from `EdgeInsets.fromLTRB(md, md, xs, md)` to `EdgeInsets.fromLTRB(md, sm, xs, sm)` so collapsed height drops by ~16 dp without breaking touch targets (the chevron / kebab keep their 48 dp footprint).
- Verify the resulting header height stays ≥ 64 dp so the whole-card tap target is comfortable.

**Why**: turns a typical 6-exercise day into a no-scroll surface on a 6.1" phone. The user can see the whole plan at once — the actual job of the screen.

### P2 — Sticky "Current" summary at top (optional)
On scroll, pin a thin (~32 dp) header strip that shows the current exercise name + progress + a tiny Focus button. Mirrors the iOS Music "now playing" pattern.

**Why**: if the user scrolls past the current card to manage upcoming exercises, they don't lose context or have to scroll back to launch Focus.

**Defer** if P1's per-card Focus and the marked-current treatment feel sufficient — this is icing.

### P3 — Bottom bar: clarify the Focus CTA
Currently shows `Focus` with no context. Change to `Focus: <current exercise name>` (truncated), so the user can confirm *which* exercise the button will open before tapping. Disabled state stays "Focus" when no `openTargets`.

**Why**: removes the "wait, which exercise will this open?" moment. Tiny copy change, large clarity win.

## 5. What stays the same

- The drag-to-reorder gaps, drag-onto-card to form a superset, intra-superset drag — all of that is solid and orthogonal to the expansion model. Don't touch.
- The notes / extra-work sections at the bottom. Same purpose, same place.
- The transient error banner, session-ended banner, mutation-in-flight indicator. All correct.
- The `lastTouchedSessionExerciseId` highlight inside an expanded loggable row — keep it (subtle, useful when the user *does* open the editor).
- Sweaty-hands ergonomics inside the editor (64 dp steppers, 36 px numerics, 56 dp LOG SET). When the editor *is* shown, it stays oversized. The CLAUDE.md rule still applies.

## 6. What this is not

- **Not a redesign of Focus mode.** Focus is the primary surface; this plan strengthens that by getting overview out of its way.
- **Not a removal of inline logging.** The chevron / card-tap still opens the editor on any card. The change is who opens it (user, not system).
- **Not a navigation change.** Same routes, same arguments. Per-card Focus uses the same `pushNamed(SessionRoutes.focus, …)` the bottom bar uses.

## 7. Recommended ship order

1. **P0** (Stop auto-expand + kill "Tap to log") — minimum-viable declutter. Ship together; they're a single coherent "overview is no longer an editing screen" change. Update bloc tests.
2. **P1** (Current marker + auto-expand-only-current + promote Replace + per-card Focus on current) — restores the "log immediately if you want, focus immediately, swap immediately" speed without the wall.
3. **P2** (Compact header + optional sticky summary) — density polish; measure on a real phone before committing.
4. **P3** (Focus button label with exercise name) — trivial copy fix, can land any time.

After P0+P1, the screen should feel like the **map**: open it, see the plan, see where you are, jump to Focus or swap an exercise. The editor is still there if you want it — it just doesn't dominate the screen any more.

## 8. Open questions to confirm before implementation

- For supersets at the "current" position, expand the first member only, or expand all members (since Focus mode pairs them)? Defaulting to first-member-only keeps the screen short; happy to flip.
- Should the kebab keep `Replace` as a secondary entry for accessibility/discoverability, or remove entirely once the header button exists? Defaulting to remove (avoid two paths); willing to keep both if you prefer.
- On the `current` chip: badge text `CURRENT`, `NEXT`, `▸` glyph, or just the accent border with no chip? Recommend chip text for clarity; happy to go subtler.
