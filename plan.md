# Plan — Easier exercise reordering on the Workout Overview screen

> **Status: ✅ Done (2026-06-06).** All four change sets (A–D) implemented;
> `tool/ci.sh` green (imports → codegen → format → analyze → 642 tests).
> On-device feel of the handle size / press delay is the user's validation pass.
>
> Implemented:
> - **A** — `DragHandle` is now a 64 dp, full-height target with a drawn
>   `surfaceVariant` resting fill and a `Listener`-driven "grab forming" pressed
>   state (primary tint + slight scale). Shared `kExerciseLeadingSlotWidth`
>   constant keeps the handle and the finished-card placeholder in lockstep so
>   titles never shift.
> - **B** — long-press delay shortened to `AppDuration.dragHold` (150 ms).
> - **C** — tap-only **Move up / Move down** kebab entries + `Semantics` custom
>   actions, backed by the pure `ReorderMoveResolver` (standalones jump whole
>   groups; superset members stay within their group). New unit test:
>   `reorder_move_resolver_test.dart`.
> - **D** — coach-mark copy updated; screen-reader custom actions added.

## Problem

Reordering exercises on the workout overview is hard to *initiate*: the area you
press to engage the drag is small and easy to miss, especially with sweaty
fingers mid-session.

## Where reordering lives today

Drag-to-reorder is started **only** from a dedicated drag handle, not the whole
card. This was a deliberate decision — see the comments in
[draggable_exercise.dart:17-21](mobile/lib/modules/workout_overview/widgets/draggable_exercise.dart#L17)
and [exercise_card.dart:84-88](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L84):
a whole-card `LongPressDraggable` competed with taps on LOG SET, the kebab, and
header-tap-to-expand, so the drag *source* was scoped to a handle in the card
header's leading slot.

Flow:

- [DragHandle](mobile/lib/modules/workout_overview/widgets/drag_handle.dart) is a
  `LongPressDraggable<ExerciseDragPayload>` rendered in the header's leading slot.
- Drop targets are the between-group [ReorderGap](mobile/lib/modules/workout_overview/widgets/reorder_gap.dart),
  the intra-superset [SupersetReorderGap](mobile/lib/modules/workout_overview/widgets/superset_reorder_gap.dart),
  the onto-card [DraggableExercise](mobile/lib/modules/workout_overview/widgets/draggable_exercise.dart)
  target (create superset), and [SupersetDropTarget](mobile/lib/modules/workout_overview/widgets/superset_drop_target.dart)
  (append to superset).
- All of it shares [DragSession](mobile/lib/modules/workout_overview/services/drag_session.dart)
  and the auto-scroller, and every drop dispatches `WorkoutOverviewDropResolved`
  ([workout_overview_event.dart:126](mobile/lib/modules/workout_overview/bloc/workout_overview_event.dart#L126)).

## Root cause (why it's hard to engage)

The friction is entirely in the **drag source**, the handle. Four compounding
issues:

1. **The hit target is 48×48 dp** — `AppSpacing.touchMin`, the *floor*
   ([drag_handle.dart:40-48](mobile/lib/modules/workout_overview/widgets/drag_handle.dart#L40)).
   On the live-session surface, CLAUDE.md is explicit that `touchMin` is the
   floor, not the target (steppers are 64 dp). The single hardest gesture on the
   screen is sized at the smallest allowed target.
2. **The target is invisible.** The handle is a 20 px (`AppIconSize.lg`) muted
   `drag_indicator` glyph floating in an undecorated 48 dp box. Users aim at the
   *glyph*, not the box, so a near-miss lands on the header's tap-to-expand
   `InkWell` ([exercise_card.dart:201](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L201))
   and silently toggles expansion instead of grabbing. You can't aim at a target
   you can't see.
3. **There's dead grab space.** The 48 dp box is vertically centered in a header
   that's taller than 48 dp (two text lines + `AppSpacing.md` top/bottom). The
   region above and below the glyph *looks* grabbable but isn't.
4. **The 250 ms long-press is fragile.** It must complete with the finger held
   reasonably still ([drag_handle.dart:54](mobile/lib/modules/workout_overview/widgets/drag_handle.dart#L54)).
   Sweaty-finger micro-drift during the hold can lose the gesture arena to the
   scroll view, and there is **no visual "grab forming" feedback** during the
   delay — `Haptics.grab()` only fires *after* the press succeeds
   ([drag_handle.dart:55-58](mobile/lib/modules/workout_overview/widgets/drag_handle.dart#L55)).
   A user who is a hair off-target or drifts slightly gets zero signal that
   nothing is happening.

## UX principles applied

- **Fitts's law:** make the target bigger and closer to where the thumb already
  is. A bigger, full-height handle is faster and more forgiving to acquire.
- **Visible affordance:** what you can hit should be what you can see. Drawing
  the handle's bounds lets users aim at the whole target, not a 20 px glyph.
- **Immediate feedback:** the press should confirm itself *as it forms*, not only
  on success.
- **Don't make drag the only path (accessibility + robustness):** offer a
  tap-only way to reorder so wet hands — or motor/AT users — are never blocked on
  a precise gesture. This mirrors the existing menu-driven "Group into superset…"
  fallback that already complements drag-to-group.
- **Respect the existing architecture:** keep the dedicated-handle model and the
  shared drop-target / drag-session / auto-scroll machinery. No engine or
  drop-resolver changes are required for the core fix.

## Proposed solution

Four change sets, **all in scope for this round** (decisions below resolved
2026-06-06):

- **A** — bigger, visible, full-height handle (directly addresses "hard to
  engage").
- **B** — 150 ms long-press to make the grab quicker without losing scroll
  affinity.
- **C** — tap-only Move up/down fallback so reordering never *requires* a drag.
- **D** — discoverability + a11y polish.

### Decisions locked in

| Question | Decision |
| --- | --- |
| Drag start mechanic | **150 ms long-press** (not immediate-`Draggable`). Quicker grab, still preserves scroll-flick affinity on the handle. |
| Tap-only Move up/down fallback | **Include now.** |
| Handle resting visual | **Subtle tinted fill** — rounded `surfaceVariant` background behind the grip icon, full header height. |
| Finished-card title alignment | **Reserve matching leading width** so titles never shift horizontally, including the unfinished→done transition. |

### A. Make the handle a big, visible, full-height grab target  *(core)*

In [drag_handle.dart](mobile/lib/modules/workout_overview/widgets/drag_handle.dart):

- Widen the hit area from `AppSpacing.touchMin` (48) to
  `AppInSessionSize.stepButton` (64) — the existing sweaty-hands token
  ([app_spacing.dart:58-68](mobile/lib/core/app_spacing.dart#L58)). No new token
  needed.
- **Make it fill the full header height** so there's no dead grab space. Wrap the
  header `Row` in `IntrinsicHeight` and let the handle stretch
  (`CrossAxisAlignment.stretch`), or give the handle an explicit
  `AppInSessionSize.stepButton` height with the centred icon — the header is
  already ≈64 dp tall, so a 64×64 handle covers almost all of it.
- **Draw the target.** Give the handle a subtle resting background
  (`colors.surfaceVariant`, `AppRadius.md`) behind the `drag_indicator` so the
  grabbable region is legible. Keep `semanticLabel: 'Drag handle'`.
- **Add a "grab forming" pressed state.** Drive a pressed visual (e.g. background
  → `colors.primary` at a subtle alpha, slight `AppDuration.fast` scale) from a
  `Listener`/`onTapDown` so the user sees the press register *during* the
  long-press window, not only after it succeeds. This is the feedback that's
  missing today.

Keep the leading-slot width **stable** so the title doesn't shift horizontally
when an exercise finishes or during the LOG-SET in-flight window (an explicit
existing concern — see [exercise_card.dart:84-88](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L84)
and [workout_group_builder.dart:111-116](mobile/lib/modules/workout_overview/widgets/workout_group_builder.dart#L111)):

- Update the no-handle placeholder in `_Header` from `SizedBox(width: AppSpacing.lg)`
  ([exercise_card.dart:217](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L217))
  to reserve the **same** width as the handle, so a finished/non-draggable card
  keeps the title's left edge aligned with draggable cards. Extract a shared
  leading-slot width constant to keep handle and placeholder in lockstep.

### B. Make engaging the drag less fragile  *(core)*

The 250 ms "hold still" requirement is the other half of the problem. Because the
handle is now a large, dedicated, non-scrolling strip, the press can be quicker.

**Decision: shorten the `LongPressDraggable` delay to ~150 ms** (introduce a
small named interaction-delay constant rather than a raw literal). Still a
long-press, so a finger that grazes the handle during a scroll-flick won't start
an accidental reorder — but the grab forms roughly twice as fast.

Keep `Haptics.grab()` on `onDragStarted` and the existing `childWhenDragging` /
feedback-pill behaviour. Immediate-`Draggable` (no hold) was considered and
**not** chosen — preserving scroll-flick affinity on the handle is worth the
small extra hold. It remains an easy future tweak if 150 ms still feels slow
on-device.

### C. Add a tap-only reorder fallback  *(in scope)*

Make reordering possible **without any drag** — the most reliable fix for wet
hands and an accessibility win. Add **"Move up" / "Move down"** entries to the
per-exercise kebab menu in `_Actions`
([exercise_card.dart:368-483](mobile/lib/modules/workout_overview/widgets/exercise_card.dart#L368)),
mirrored for superset members.

- No engine/resolver change: reuse `WorkoutOverviewDropResolved` with a computed
  `DropTarget.beforeIndex(...)` — the same path the reorder gaps already use
  ([reorder_gap.dart:82-91](mobile/lib/modules/workout_overview/widgets/reorder_gap.dart#L82)).
- The target index is derived from the exercise's current position in the
  unfinished sequence. The builders already compute this:
  `_unfinishedIndexAt` ([workout_overview_loaded_body.dart:262](mobile/lib/modules/workout_overview/widgets/workout_overview_loaded_body.dart#L262))
  for the top level and `unfinishedIndexById`
  ([workout_group_builder.dart:175-183](mobile/lib/modules/workout_overview/widgets/workout_group_builder.dart#L175))
  inside supersets. Plumb the current index (and whether up/down is available at
  the ends) into the card so the menu can disable the no-op direction.
- Scope to match drag: standalone "move up/down" reorders within the top-level
  group sequence; a superset member's "move up/down" reorders within its group —
  exactly what the gaps already allow. Verify the `beforeIndex` math against the
  engine's `reorderUnfinished` contract with a bloc/domain test (below).

### D. Discoverability & a11y polish  *(polish)*

- Update the coach-mark copy ([workout_overview_loaded_body.dart:131-135](mobile/lib/modules/workout_overview/widgets/workout_overview_loaded_body.dart#L131))
  to mention the now-obvious handle and the new Move up/down menu.
- Add `Semantics` custom actions (move up / move down) on the card for screen
  readers, pointing at the same bloc event as C.

## Files touched

| File | Change |
| --- | --- |
| [drag_handle.dart](mobile/lib/modules/workout_overview/widgets/drag_handle.dart) | 64 dp, full-height, visible handle; pressed/forming state; shorter (or immediate) drag start (A, B) |
| [exercise_card.dart](mobile/lib/modules/workout_overview/widgets/exercise_card.dart) | `IntrinsicHeight` header + stretch; matching leading-slot placeholder width; Move up/down menu items + semantics (A, C, D) |
| [superset_card.dart](mobile/lib/modules/workout_overview/widgets/superset_card.dart) | Pass per-member move up/down availability through to member cards (C) |
| [workout_group_builder.dart](mobile/lib/modules/workout_overview/widgets/workout_group_builder.dart) | Compute current/neighbor indices for the Move up/down actions (C) |
| [workout_overview_loaded_body.dart](mobile/lib/modules/workout_overview/widgets/workout_overview_loaded_body.dart) | Coach-mark copy (D) |
| `app_spacing.dart` / `app_motion.dart` | Reuse `AppInSessionSize.stepButton`; add an interaction-delay token only if B chooses the shorter long-press |

No changes to the domain engine, `SessionRepository`, `DropResolver`, or the
drag-session/auto-scroll services.

## Edge cases & risks

- **Handle vs. scroll conflict (B-immediate only):** a 64 dp left strip is large;
  confirm flick-scrolling that *starts* on the handle still feels acceptable, or
  keep the short long-press to preserve scroll affinity there.
- **Layout stability:** the leading slot must stay a fixed width across
  unfinished → done transitions and the LOG-SET in-flight window, or the title
  jitters mid-session (existing, explicitly-guarded concern). Covered by the
  matching-placeholder change in A.
- **Title squeeze:** +16 dp of leading width narrows the title; it's already
  `Expanded` + ellipsised, so this is fine, but eyeball long exercise names.
- **Move up/down index math (C):** off-by-one risk in `beforeIndex` for "move
  down" and at sequence ends; cover with a focused test.
- **Tokens:** no hard-coded pixels — use `AppInSessionSize.stepButton`,
  `AppRadius`, `AppDuration`, `appColors`. Honours the UI-token rule under
  `lib/modules/**/widgets/`.

## Testing

Test scope is domain + persistence (no widget/bloc_test per CLAUDE.md):

- **Move up/down (C):** a bloc/domain test that the computed `beforeIndex`
  produces the expected unfinished ordering via the existing reorder path,
  including the end positions and a superset member. This is the only change with
  real logic; the rest (A, B, D) is presentation/gesture and is verified by your
  on-device pass.
- Run `tool/ci.sh` (imports → codegen → format → analyze → test) from `mobile/`.
- **Visual/gesture validation is yours** — A and B's feel (target size, press
  delay, immediate vs. long-press) is best judged on a real sweaty-hands device.

## Rejected / deferred alternatives

- **Whole-card `LongPressDraggable` again** — explicitly rejected previously
  because it fought LOG SET / kebab / tap-to-expand. Not revisiting.
- **Replace the custom drag stack with `ReorderableListView`/`SliverReorderableList`**
  — would lose drag-to-create-superset, intra-superset gaps, append-to-superset,
  and the bespoke auto-scroll/drag-session. Disproportionate rewrite for an
  initiation-ergonomics problem.
- **`product-context.md` update** — not required: this changes *how* reordering is
  engaged, not which screens/features exist. (The Move up/down menu is a minor
  additive control on an existing screen; mention only if you consider it a
  distinct feature.)

## Suggested sequencing

1. **A** — bigger, visible, full-height handle + pressed state + stable
   placeholder. Biggest single win, lowest risk. Validate on-device.
2. **B** — shorten the long-press to ~150 ms; reassess immediate-drag after the
   on-device pass.
3. **C** — Move up/down menu fallback + its test. Makes reordering bulletproof.
4. **D** — coach-mark copy + semantics.
