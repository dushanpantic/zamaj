# Focus mode — superset UX redesign

Stop reordering cards when the active panel rotates. Keep partners in **planned (chronological) position order**, and expand only whichever panel is currently active. Make "previous" partners smaller than "upcoming" ones so a glance reveals where you are in the round.

This plan covers the why, the visual design at each size, the interaction rules, edge cases, and the file-by-file changes. It does **not** change the rotation logic — only the layout.

---

## 1. Problem with today's layout

Today, [focus_mode_screen.dart](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart) renders:

```
┌───────────────────────────────┐
│ active card (full editor)     │   ← always at top
├───────────────────────────────┤
│ partner A (compact)           │   ← rest, in planned order
│ partner B (compact)           │
└───────────────────────────────┘
│ LOG SET (pinned)              │
```

When the active swaps (auto-rotation after each logged set, e.g. A → B → C → A …), the card representing A teleports from the top "active" slot down into a partner row, B jumps up to take its place, C stays put. The spatial map of the superset shuffles every set. Between sets, with sweaty hands and a 1-second glance, the user has to re-anchor: *which one is mine now?* That micro-disorientation is the friction worth eliminating.

In a 3-exercise superset the swap is worse: the user wants to mentally walk **down the list in order**, not chase a moving expanded card.

---

## 2. UX principles we're optimising for

1. **Spatial stability** — the *position* of an exercise within the group should be stable for the whole session. Moving things around mid-session breaks the mental map the lifter builds in the first minute.
2. **Single focus** — exactly one card per group is expanded with full editing. The bottom-pinned `LOG SET` always targets it. (No change from today.)
3. **Glanceability** — three sizes communicate *temporal* state ("past / now / next") with zero reading. The bigger the card, the more attention it earns.
4. **Information thrift on the small cards** — previous = identity + done count (you don't need to re-read planned values for a set you just did). Upcoming = identity + planned values + progress (you might want to mentally prep the load).
5. **Sweaty-hands floor** — the small cards still need ≥ 48 dp tap targets. The visual content can be denser than the hitbox.
6. **Live-session continuity** — keep the pinned LOG SET, rest-timer bar, undo affordance, "Up next: <group>" strip, and 3-dot menu where they are. Only the panel stack inside the body changes.

---

## 3. Proposed layout

Panels render in **planned position order**, top to bottom, regardless of which one is active. Each panel takes one of three visual states based on its position relative to the active panel:

```
┌───────────────────────────────────────┐
│ ⓘ Superset · A + B + C · Up next: …   │   strip (unchanged)
├───────────────────────────────────────┤
│ ▢ A1 ─ Bench Press  · 2/3  ✓          │   PREVIOUS  (smallest, ~40 dp)
├───────────────────────────────────────┤
│ ╔═══════════════════════════════════╗ │
│ ║ A2 ─ Bent-over Row                ║ │
│ ║ ● ● ○   Planned 60 kg × 8         ║ │
│ ║ Last  60 kg × 8                   ║ │   CURRENT  (full editor)
│ ║ [ weight ][ reps ] bump rows      ║ │
│ ╚═══════════════════════════════════╝ │
├───────────────────────────────────────┤
│ ▢ A3 ─ Plank · 60 s · 1/3 ● ○ ○       │   UPCOMING  (medium, ~64–72 dp)
├───────────────────────────────────────┤
│ [ LOG SET  ·  Set 2 of 3 ]            │   pinned (unchanged)
└───────────────────────────────────────┘
```

### Three size variants

| State | Vertical size | Content | Typography | Visual treatment |
|---|---|---|---|---|
| **Previous** | ~40 dp content, 48 dp hitbox | Exercise name (single line, ellipsised) · compact set count `2/3` or check icon when fully done | `caption` for count, `labelSmall` for name | Surface alpha 0.18, no accent border, `onSurfaceMuted` text |
| **Current** | Full editor — unchanged from today's `_ActivePanelCard` | Header, set pips, planned/last, numeric panel, 3-dot menu | unchanged | Surface alpha 0.5, `loggableHint` border 1.5 px, soft glow |
| **Upcoming** | ~64–72 dp content, 56 dp+ tap region | Exercise name · planned values (next set) · set pips | `titleSmall` for name, `caption` for values | Surface alpha 0.3, thin `outline` border, normal text colors |

Rationale for "previous smaller than upcoming": once a set is logged, the user has the data — they don't need to re-read the prescription. Upcoming, by contrast, is what they're about to attempt in the next rotation, so showing the planned target there saves a mental round-trip.

### Position-relative state, formally

Given the assembler-picked `activeSessionExerciseId`:
- A panel **before** active's position → **previous** style.
- The active panel → **current** style.
- A panel **after** active's position → **upcoming** style.

A panel that is no longer loggable (fully completed, or marked-done) renders in the style its *position* would dictate — but with a check-circle in place of the progress pips, and tap-to-activate disabled. Completed-and-before-active is the common case; completed-and-after is rare but possible if the user pinned earlier exercises.

This rule produces a **chronological staircase**: as the active rotates A → B → C, the expansion *walks down* the list, with previous cards accumulating above it and upcoming cards shrinking from below.

---

## 4. Interactions

| Action | Result |
|---|---|
| Tap a **previous** card (still loggable) | Pins it as active. Cards animate-resize: it expands, the prior active shrinks to its position-relative state. (Same behaviour as today's "tap to make active", just without the position swap.) |
| Tap an **upcoming** card | Same — pins it active. |
| Tap a **completed** card | No-op (matches today). 3-dot menu still works. |
| Log a set on the active card | Engine recomputes; assembler re-picks the next active; this screen rebuilds with the new active card expanded *in its own position slot*. No card moves. |
| Pinned LOG SET | Always targets the currently-expanded card (no change). |
| 3-dot menu on a partner | Same actions available (replace / skip / mark done / video) — no need to make it active first (no change). |
| Rest timer · stopwatch · undo | Unchanged. |

### Auto-rotation is unaffected

The `FocusModeAssembler._pickActivePanelId` rule stays exactly as it is — min-completed wins, with the rotation tie-breaker. We only change how `panels` are presented in the UI; the engine and bloc see the same view model.

### Manual pin still wins

If the user taps a previous/upcoming card, `FocusModeFocusedPanelSelected` fires (existing event), the bloc re-assembles with `userPinnedPanelId`, and `activeSessionExerciseId` updates. The new active expands in its position-stable slot.

---

## 5. Edge cases

1. **Single exercise (non-superset group).** `panels.length == 1`. Render the current card alone, full editor — same as today. No previous/upcoming styling needed.
2. **2-exercise superset.** Either `[current, upcoming]` (active is first) or `[previous, current]` (active is second). Never two of the same kind. Layout works naturally.
3. **3-exercise superset, first rotation.** `[current, upcoming, upcoming]` — active at top, two upcoming below.
4. **3-exercise superset, mid rotation.** `[previous, current, upcoming]` — staircase.
5. **3-exercise superset, last position.** `[previous, previous, current]`.
6. **Completed partner.** A panel whose `isLoggable == false` renders at its position-relative size but with a check-circle and dimmed colors. Tap-to-activate disabled. Stays in the stack for the rest of the session so the spatial map doesn't change.
7. **4+ exercise giant set.** Allow the partners area to scroll (existing `SingleChildScrollView`). On a small device with all three sizes visible the active card stays in view at the top of the viewport — wrap the active card in a non-scrolling slot so it pins against the strip; only previous/upcoming cards above/below scroll. (See §6.)
8. **Active panel pin no longer loggable** (e.g. user skipped via 3-dot while pinned). Pin drops, assembler picks a new active by auto-rotation. New expanded card sits in its slot; cards don't otherwise reshuffle.
9. **Warmup pill, replaced indicator.** Active card shows them as today. Previous/upcoming cards omit them by default — the active expansion will show them when that panel becomes current.
10. **`plannedRestSeconds` differs across partners.** Rest timer is keyed off the *just-logged* panel as today; nothing changes.

---

## 6. Visual + layout details

### Card geometry

All sizes share the same outer radius (`AppRadius.lg`), the same horizontal padding (`AppSpacing.md`), and stretch full-width. Only the vertical padding and content differ:

- **Previous**: padding `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs)` plus a `constraints: minHeight: AppSpacing.touchMin` so the hitbox is comfortable even though the visible content is small.
- **Upcoming**: padding `EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm)`, two-line content.
- **Current**: today's `EdgeInsets.all(AppSpacing.md)`.

### Tokens (no hard-coded values)

All sizes/colors go through `AppSpacing`, `AppRadius`, `AppTypography.standard`, `Theme.of(context).appColors` — per CLAUDE.md's "UI tokens" rule. The two sweaty-hands modules' 64-dp counter/`numericLarge` floor applies only to the editor surfaces inside the active card; previous/upcoming cards are read-mostly with a single tap action, so 48-dp `touchMin` is the correct floor for them.

### Layout container

Replace the current "active on top + scrollable partners below" structure with a single position-ordered column:

```dart
Column(
  children: [
    SupersetUpNextStrip(group: group),
    Expanded(
      child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        child: Column(
          children: [
            for (var i = 0; i < group.panels.length; i++) ...[
              _PanelSlot(
                state: state,
                panel: group.panels[i],
                role: _roleFor(group.panels[i], group.activeSessionExerciseId),
                canMutate: canMutate,
              ),
              if (i < group.panels.length - 1) SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    ),
    PinnedBottomBar(...),
  ],
)
```

`_PanelSlot` is a switch on the role (`previous` | `current` | `upcoming`) that returns the right card variant. Each variant is its own small `StatelessWidget`.

The whole stack scrolls together; the active card stays naturally near the centre because it's the biggest item. On a 6.5"+ device with up to 3 superset members it never needs to scroll. On smaller devices or 4+ supersets, it scrolls — which is fine because the active card's editor stays inside its own slot and the pinned LOG SET is below the scroll viewport.

> Decision deferred: a more aggressive variant pins the active card and only scrolls the previous/upcoming lists around it. That's more work (split scroll viewports) and only matters at 4+ exercise giant-sets on tiny screens. Recommend deferring until we observe the bigger group sizes in practice.

### Animation

Wrap each `_PanelSlot` in `AnimatedSize(duration: 220ms, curve: Curves.easeOutCubic)` and the inner content in `AnimatedSwitcher` keyed by role. When the active rotates, the old active smoothly shrinks into its new role's height while the new active expands. No card translates — they all stay in place.

This is cheap (no `Hero` or shared-element transitions needed) and gives the staircase a visible "step" each time a set is logged, reinforcing the spatial model.

### Accent treatments

- **Previous**: muted. Border colour `colors.outline.withValues(alpha: 0.35)`. Background `colors.surface.withValues(alpha: 0.18)`. Text `colors.onSurfaceMuted`. Check-circle when completed uses `colors.exerciseCompleted`.
- **Upcoming**: neutral. Border `colors.outline.withValues(alpha: 0.6)`. Background `colors.surface.withValues(alpha: 0.3)`. Name `colors.onSurface`, values `colors.planned`.
- **Current**: today's accent — `colors.loggableHint` border at 1.5 px, surface alpha 0.5. Optional: subtle 2-px left rail (also `loggableHint`) to anchor the eye when scrolling.

---

## 7. View model & assembler changes

The assembler already returns `panels` in position order and exposes `activeSessionExerciseId`. The UI alone can derive each panel's role by comparing positions, so **no domain or view-model changes are required**.

Two small additions worth considering, both UI-side helpers:

- A `FocusPanelRole` enum (`previous | current | upcoming`) inside the screen file — purely a UI computation, no test impact.
- A helper `_roleFor(FocusModeViewModel, String? activeId)` that walks `group.panels` once and assigns roles by index.

If we later want the assembler to express role explicitly on each panel for testability, that's an additive change behind a `@Default(FocusPanelRole.current)` field — safe to defer.

---

## 8. Implementation outline

All edits are inside [mobile/lib/modules/focus_mode/](mobile/lib/modules/focus_mode/) — no changes to domain, persistence, or bloc.

### Files to change

1. **[mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart)** — the meat of the change.
   - Delete `_PartnerPanelList` and `_PartnerPanelCard`.
   - Keep `_ActivePanelCard` as `_CurrentPanelCard` (rename for clarity).
   - Add `_PreviousPanelCard` and `_UpcomingPanelCard`.
   - Refactor `_ReadyBody` to render a single position-ordered column dispatched through a `_PanelSlot` switch.
   - Wrap slots in `AnimatedSize` for the resize transition.
   - Reuse `_PanelHeader`, `_PanelActionsMenu`, `_PlannedAndLast`, `FocusSetProgress` where applicable — the small cards use stripped-down versions of these.

2. **[mobile/lib/modules/focus_mode/widgets/](mobile/lib/modules/focus_mode/widgets/)** — optional: if the three card variants get big, extract `focus_previous_card.dart` and `focus_upcoming_card.dart` siblings of the existing widgets. Keep the file count low; only split if the screen file grows past ~1200 lines.

### Files unchanged (verified)

- [bloc/focus_mode_bloc.dart](mobile/lib/modules/focus_mode/bloc/focus_mode_bloc.dart) — rotation logic unchanged.
- [services/focus_mode_assembler.dart](mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart) — panels already come back in position order with `activeSessionExerciseId` set.
- [models/focus_mode_group_view_model.dart](mobile/lib/modules/focus_mode/models/focus_mode_group_view_model.dart) — sufficient as-is.
- All domain / persistence — none touched.

### Suggested commit slicing

1. **Refactor** — pull the partner rendering out of `_ReadyBody` into a `_PanelSlot` switch, keeping today's "active on top, partners below" output identical. Verifies the seam compiles and renders the same.
2. **Reorder** — change `_PanelSlot` to render in position order, with the active card still in its position slot. Visually noticeable on supersets; singles unchanged.
3. **Re-style** — add the `previous` (small) and `upcoming` (medium) treatments. Delete the old partner card colors.
4. **Animate** — wrap slots in `AnimatedSize`. Smoke-test rotation on a 3-exercise superset.

Each commit is independently shippable.

### Tests

Per CLAUDE.md, focus-mode UI doesn't have widget tests, and assembler/bloc behaviour isn't changing. No new tests needed. If a `_roleFor` helper is extracted to a pure function and lives under `lib/`, a small pure-Dart unit test under `test/` covering "previous / current / upcoming" assignment for a 3-panel group is cheap and worth it.

### Manual verification (CLAUDE.md `verify` flow)

- 1-exercise day: focus screen looks identical to today.
- 2-exercise superset: log a set on A → B expands in place (no top-jump). Log on B → A expands again. No card translates.
- 3-exercise superset: walk through A → B → C → A. Watch the staircase shift; check previous cards stay small, upcoming cards medium.
- Tap a previous card to pin it: it expands in its existing slot; the prior active shrinks to its role.
- Skip via 3-dot on a partner: card stays visible (completed style), pin drops if needed, no reorder.
- Small device (e.g. iPhone SE viewport): partners area scrolls; pinned LOG SET stays put.

---

## 9. Decisions for confirmation

These are the spots where the design has a clear default but the user might prefer a different call:

- **D1 — Active card stays in scroll viewport, not pinned.** Default: the whole stack scrolls together; with ≤3 supersets nothing scrolls in practice. Alternative: split-scroll with the active card pinned in the middle and previous/upcoming lists scrolling above/below. Recommend default; revisit if 4+ exercise giant-sets become common.
- **D2 — Previous cards show `2/3` count, no planned values.** Default as described. Alternative: also show planned values in a muted line. Recommend default — less ink, faster glance.
- **D3 — Upcoming cards show planned values for the *next* set, not the whole `plannedSummary`.** Default: just the upcoming set's target (mirrors what the active card emphasises). Alternative: show the `3×8 @ 60kg` aggregate summary.
- **D4 — Completed partners keep their slot, never disappear.** Default: yes — preserves spatial map. Alternative: drop them from the stack once fully done. Recommend default.
- **D5 — `AnimatedSize` for the size transition, no fade/slide.** Default: 220 ms `easeOutCubic` resize only. Alternative: cross-fade content as well via `AnimatedSwitcher`. Recommend default — resize alone reads as the staircase stepping, fade adds visual noise.

If any of these defaults are wrong, flagging them before commit 3 ("re-style") is the natural checkpoint — the refactor and reorder commits are independent of these calls.
