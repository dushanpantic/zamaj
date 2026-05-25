# Plan — Workout Day Picker UX overhaul

## Goal

Make the day picker do exactly one job — **let the user pick today's workout and start it** — without nudging, judging, or asking them to interpret jargon.

## Diagnosis: what's wrong today

### 1. The recommendation badge is the worst offender ([day_recommendation_badge.dart](mobile/lib/modules/workout_day_picker/widgets/day_recommendation_badge.dart))

Four labels are emitted from `lastCompleted` vs `referenceNow`:

| Days since | Label | Tint |
|---|---|---|
| never | "New" | primary |
| 0 | "Rested today" | muted |
| 1–2 | "Soon" | amber/warning |
| 3+ | "Ready" | green/exerciseCompleted |

Problems:

- **"Rested today" is semantically inverted.** It fires when the user *trained* this day today, not when they *rested* it. Anyone reading the label without context will mis-parse it. This is a real bug, not just polish.
- **"Soon" and "Ready" are coaching.** The amber/green color encoding tells the user *whether they should train this day*. Per [product-context.md](product-context.md): *"No coaching / AI recommendations. The app records what you do; it does not tell you what to lift."* The badges directly violate that non-goal.
- **Redundant with the history line.** The tile already says *"Last completed: 3 days ago"* directly under the title. The badge re-encodes the same number into a color-coded judgement; the user has to read both and reconcile them.
- **Color-as-meaning is also an a11y problem.** Green/amber semantics depend on color perception. We don't need them — and we don't *want* them, per the non-goal above.

**Conclusion: delete the badge entirely.** This is the headline change. The rest of the plan covers what's left after that subtraction.

### 2. The history block is wordy where it should be glanceable ([day_tile_history_labels.dart](mobile/lib/modules/workout_day_picker/widgets/day_tile_history_labels.dart))

Two text lines per tile:

- Primary: `"Last completed: 3 days ago"` or `"Not completed yet"`
- Secondary: `"2× this week · 14 total"` or `"Not completed this week"`

Issues:

- `"Last completed:"` is a label for a single value. Drop the label; the relative date carries the meaning. `"3 days ago"` reads cleaner than `"Last completed: 3 days ago"`.
- `"2× this week"` is interesting on a non-weekly program (PPL × 2 = 6 days, push hit twice) but **most days in a typical program are hit once a week** — so the line frequently reads `"Not completed this week"` for a day the user did 6 days ago, which is psychologically negative and not actionable.
- `"14 total"` is a vanity counter. It rarely changes decisions; it's clutter.
- The `invariantViolation` debug string at [day_tile_history_labels.dart:37-41](mobile/lib/modules/workout_day_picker/widgets/day_tile_history_labels.dart#L37-L41) leaks a snake_case identifier into the UI. Should never reach a user; if it does, it should read as a real error or be silently swallowed.

### 3. "N exercise groups" is jargon ([day_tile.dart:35-38](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L35-L38))

Subtitle reads `"1 exercise group"` / `"5 exercise groups"`. A lifter does not think in *groups* — they think in *exercises* and *supersets*. Group count answers a structural question ("how many cards on the next screen") but not a content question ("what am I about to do").

### 4. Active session is under-emphasised

A day with an in-progress session looks identical to the other tiles except for the button label changing `START` → `RESUME`. Resuming an interrupted session is the **highest-priority action** when it exists; the screen should make it impossible to miss.

### 5. Loading title flickers

App bar title shows `"Loading…"` until the program loads, then snaps to the program name. The bloc already knows the `programId` from the route; we can fetch the program name eagerly or just show a neutral title.

### 6. Appbar refresh icon is redundant

Pull-to-refresh is already wired ([workout_day_picker_screen.dart:209-214](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L209-L214)). The icon button is a discoverability backup at best — at the cost of header clutter.

## Design principles (derived from [product-context.md](product-context.md))

1. **No coaching.** The screen shows *facts about the program and history*; it does not interpret them.
2. **Sweaty-hands rules do NOT apply here.** This screen is pre-session, on dry hands. Standard `touchMin` (48 dp). We can afford denser layouts here than in [workout_overview/](mobile/lib/modules/workout_overview/) or [focus_mode/](mobile/lib/modules/focus_mode/).
3. **Planned-vs-actual is sacred** — but neither is the focus on this screen. This is the *picker*; planned/actual lives inside the session.
4. **One primary action per tile.** Tap the tile → start (or resume). The filled button is the visual cue; the tile is the hit area.

## Proposed changes, in implementation order

Each step is independently shippable. Stop at any point and the screen is still better than today.

### Step 1 — Delete the recommendation badge *(highest impact, smallest diff)*

- Remove [day_recommendation_badge.dart](mobile/lib/modules/workout_day_picker/widgets/day_recommendation_badge.dart) entirely.
- Drop the `Row` + `Flexible(title) + DayRecommendationBadge` structure in [day_tile.dart:57-80](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L57-L80); the title becomes a plain `Text`.
- No tests to migrate beyond removing any direct widget tests of the badge.

After this step the user already gets what they asked for: no more misleading labels.

### Step 2 — Tighten the history line

Replace the two-line history block with a single, label-free line:

- Never done → `"Not done yet"` (muted)
- Done today → `"Today"`
- Done yesterday → `"Yesterday"`
- Otherwise → `"3 days ago"` (using existing [relative_date_formatter.dart](mobile/lib/core/relative_date_formatter.dart))

Drop the `"N× this week"` and `"N total"` lines. They're stats, not picker-relevant decisions. **If we want to surface lifetime totals, that belongs on Recent Sessions, not here.**

Keep [day_history_summary.dart](mobile/lib/modules/workout_day_picker/models/day_history_summary.dart) as-is — totals/week counts are cheap to compute and may be used elsewhere; this is purely a presentation simplification in [day_tile_history_labels.dart](mobile/lib/modules/workout_day_picker/widgets/day_tile_history_labels.dart). Also kill the `invariantViolation` user-visible string; if it's truly impossible, `assert` it; otherwise render a generic error.

### Step 3 — Show exercises, not "groups"

In [day_tile.dart:35-38](mobile/lib/modules/workout_day_picker/widgets/day_tile.dart#L35-L38), replace the subtitle:

- Compute total exercise count across all groups.
- Render `"5 exercises"` (or `"1 exercise"`). Drop the group count entirely from this surface — supersets become visible on the next screen where they actually matter.
- Optionally: append a preview of the first 2 exercise names truncated, e.g. `"5 exercises · Bench, Squat…"`. Powerful, but raises the question of which exercises lead — leave this as a follow-up unless trivial.

### Step 4 — Make the active session unmissable

When `summary.activeSessionId != null`:

- Add a left accent border (4dp) on the tile using `colors.primary`.
- Add a single small chip near the title: `"IN PROGRESS"` (this is *status*, not coaching — it states a fact about app state). Use `colors.primary` tinted.
- Consider auto-scrolling that tile into view on load if it's not the first item.

Pinning it to the top of the list is tempting but reorders the program — which the user reads spatially. **Do not reorder.** The accent + chip is enough.

### Step 5 — Whole-tile is the hit target

Wrap the tile in `InkWell` / `Material` so tapping anywhere on the tile triggers the same action as the button:

- `START` for tiles without an active session.
- `RESUME` for tiles with one.
- Keep the filled button as the visual affordance (and as the explicit fallback for accessibility) — but route both gestures through the same handler.
- Respect `launchInFlightWorkoutDayId` — disable taps while a launch is in flight, same as the button does today.

This makes the screen feel responsive and removes the "where do I tap" micro-decision.

### Step 6 — Drop the appbar refresh icon

Remove the refresh `IconButton` at [workout_day_picker_screen.dart:128-132](mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart#L128-L132). Pull-to-refresh stays. Keep the history icon — that's a navigation entry point with no equivalent gesture.

### Step 7 — Eager title

Show the program name in the appbar as soon as it's known. Two options, in order of preference:

1. **Pass the program name through the route** (it's known by the caller — Program list) and seed the bloc state with it. The appbar reads from a `name` field that's available even in `Loading`.
2. If routing changes are too invasive, just show a blank title during the brief load instead of `"Loading…"`.

This is small-feeling but eliminates a flicker on every entry.

## What is explicitly NOT in scope

- **No streaks, no "recommended next day" highlighting, no smart sort.** Those are coaching by the back door. Same reasons as deleting the badge.
- **No weekly progress meter at the program level** (e.g., "2/4 days this week"). Possibly worthwhile later, but it's a *new feature*, not a UX fix.
- **No drag-to-reorder of days.** Day order is the program's; it belongs in the program editor.

## Acceptance check

After Step 1 alone, a reasonable person scanning the screen can answer:

- *"What's in this day?"* → the title and exercise count
- *"When did I last do it?"* → the relative date
- *"What do I tap to start?"* → the filled button (or anywhere on the tile after Step 5)

…without encountering any text that *judges* whether they should train today. That's the bar.

## Update [product-context.md](product-context.md)?

No. The screen's role ("Choose which day of the program to do today; resume an in-progress session if one exists") doesn't change. The badge removal is a *de-scoping* that aligns with the existing "no coaching" non-goal — already documented.
