# Focus Screen Redesign — Superset / Scroll Fix

## 1. Problem

In a superset group, the focus screen renders one full **panel** per participating exercise stacked vertically. Each panel currently owns:

- Title + 3-dot menu
- Set-progress pips
- Planned / Last summary
- Full editor (big numeric field + bump rows)
- Its own 64 dp `LOG SET` button

For a 2-exercise superset this is ~660 px of body content + app bar (56) + bottom bar (rest timer 56–80 + optional undo) + safe areas. On most phones that overflows, so the body wraps in a `SingleChildScrollView`.

This breaks the screen's contract:

1. **Two `LOG SET` buttons** → two primary actions on one screen. The user has to decide *which* one to tap; that decision shouldn't exist mid-set.
2. **Scrolling** → the editor for the set you're about to log can be partially off-screen. With sweaty hands, you don't want to scroll to find the bump buttons.
3. **Visual equality of the two panels** masks the fact that, at any given moment, only **one** of them is the set the user is actually doing.

## 2. UI/UX principles applied

- **One primary action per screen.** Whatever the screen's single job is, one button does it. (Material 3 — "one primary action"; Apple HIG — "make the primary action obvious".)
- **Focus = subtraction.** The focused panel earns the editor; the partner is *context*, not a co-equal task. (Tognazzini "Focus and emphasis"; Nielsen #8 aesthetic / minimalist.)
- **Spatial stability for muscle memory.** A control that lives in a fixed pixel position on screen across iterations is faster to hit than one that moves — especially mid-set, mid-glance. (Fitts's law + sticky-target research.)
- **Recognition over recall.** Both exercises stay visible (progress + planned + last) so the user never wonders "what's the other one doing?" — they just glance. (Nielsen #6.)
- **State the system already knows shouldn't be a question.** Superset rotation order is derivable from `completedSetsCount` + `ExecutedSet.completedAt`. Auto-rotate; let manual override be the exception.
- **Sweaty-hands ergonomics (per CLAUDE.md).** The active editor keeps `numericHero` field + 48 dp bump rows; the pinned `LOG SET` stays ≥ 56 dp tall. Partner cards stay ≥ 56 dp tall as one big tap target.

## 3. Design

### 3.1 Layout (2-exercise superset, no rest)

```
┌─ AppBar ──────────────────────────────────────┐
│ Push Day A                    ⇅      ⋮       │
├───────────────────────────────────────────────┤
│  🔗  Superset · Bench + Row · Up next: Pull A │  ← compact superset/up-next bar
├───────────────────────────────────────────────┤
│                                               │
│  ┌─ ACTIVE ▸ Bench Press ──────────────────┐ │
│  │ ● ● ○ ○      Set 3 of 4              ⋮ │ │
│  │ Planned  100kg × 8                     │ │
│  │ Last     97.5kg × 8                    │ │
│  │                                        │ │
│  │  ┌──────┐         ┌──────┐             │ │
│  │  │ 100  │   ×     │  8   │             │ │
│  │  │  kg  │         │ reps │             │ │
│  │  └──────┘         └──────┘             │ │
│  │  [-2.5][-1.25][+1.25][+2.5]  [-1][+1]  │ │
│  └────────────────────────────────────────┘ │
│                                               │
│  ┌─ Row ──────────────────────────────── ⋮ ─┐│
│  │ ● ● ○ ○ Set 3/4  ·  80kg × 8 · last 80×8 ││
│  └──────────────────────────────────────────┘│  ← tappable partner card
│                                               │
├───────────────────────────────────────────────┤
│ [        LOG SET — Bench Press            ]   │  ← pinned bottom bar
│  Set 3 of 4                                   │     (single primary action)
└───────────────────────────────────────────────┘
```

When resting, the rest-timer bar inserts itself **below** the `LOG SET` button (same pinned region). When `undoable` exists, the undo affordance sits between the bottom of the partner card area and the pinned button.

### 3.2 Roles

- **Active card**: full editor, identical to today's editor. Has the 3-dot menu (replace / skip / mark done / open video). Visually distinguished with brighter border (`colors.outline`) and slightly higher elevation/tint.
- **Partner card** (one per other superset member): compact, ≥ 56 dp tall.
  - Row 1: `[name]            [● ● ○ ○]   ⋮`
  - Row 2: `Planned: 80kg × 8   ·   Last: 80kg × 8`
  - The whole row 1 + row 2 is a tap target → makes that exercise active (manual override).
  - 3-dot menu still works on partners (replace / skip / mark done / open video) so the user doesn't have to switch first just to skip something.
  - Completed partner: same compact layout but no tap-to-activate, with a small ✓ instead of pips on the right.
- **Pinned bottom region** (replaces today's `_PinnedBottomBar`):
  - Always shows the LOG SET button when there's a loggable active panel.
  - Label: `LOG SET — <active exercise name>` with `Set N of M` subtitle (the per-exercise context that today lives in the per-card button's `subLabel`).
  - Rest-timer bar appears **below** LOG SET when `state.restTimer != null`.
  - Undo button appears below the rest timer when `state.undoable != null`.
  - When no panel is loggable (all completed) the region collapses to just the rest timer / undo, matching today's behavior.

### 3.3 Auto-rotation rule (used to pick the active panel)

Pure function over the group's panels + the session's executed sets, evaluated by the assembler:

1. Filter `panels` to `isLoggable == true`. If 0 → no active panel (group is terminal; bloc transitions away as it does today). If 1 → that one is active.
2. Otherwise, among loggable panels, find the **minimum** `completedSetsCount`. That set of panels is the candidate pool.
3. Tie-breaker: among the candidate pool, pick the panel that comes **next in position order after** the panel containing the **most recent** `ExecutedSet.completedAt` in this group. If no executed set exists in the group, pick the panel at the lowest position.
4. **Manual override** wins over (2)–(3) when `state.userPinnedPanelId` is set AND that panel is in the candidate pool of (1). Override is cleared automatically when a set is logged on it (auto-rotation resumes) OR when the user switches to a different group.

This algorithm matches what athletes naturally do in supersets (alternate, behind-one-catches-up after a missed beat) and never asks the user to make a decision the system can answer.

### 3.4 "Up next" relocation

Today "Up next: <group label>" sits at the bottom of the scroll. With a non-scrolling layout, vertical space is precious. Move it into the **superset/up-next strip** directly below the app bar (see ASCII above). For singles (no superset tag), the strip shows only the up-next label; for supersets it shows the link icon + "Superset · A + B" + the up-next label, ellipsis-truncated.

This also means the "Last group in this session" caption moves to the same strip (or is suppressed and implied by the absence of "Up next").

### 3.5 Vertical budget (sanity check, iPhone 14-class screen ~750 usable pt)

| Region                                | Height (pt) |
|---------------------------------------|-------------|
| AppBar + status bar                   | 56 + ~50    |
| Superset / up-next strip              | ~36         |
| Top padding                           | ~12         |
| Active card (rep-based)               | ~310        |
| Gap                                   | 12          |
| 1 partner card                        | ~72         |
| Gap                                   | 12          |
| Pinned LOG SET (64) + subtitle pad    | ~76         |
| Rest timer (optional)                 | +56         |
| Bottom safe area                      | ~34         |
| **Total (no rest)**                   | **~670**    |
| **Total (resting)**                   | **~726**    |

→ Fits without scroll on standard phones for a 2-exercise superset. A 3-exercise giant set adds ~84 pt; still typically fits, and we accept a *short* scroll there (rare in practice). Singles are well under budget.

## 4. Concrete code changes

### 4.1 View-model additions (`focus_mode_group_view_model.dart`)

Add to `FocusModeGroupViewModel`:

- `required String activeSessionExerciseId` — id of the panel that should render as ACTIVE.
- `required bool activeIsUserPinned` — true when chosen by the user, false when chosen by auto-rotation. Used only for analytics/diagnostics; UI doesn't need to differentiate.

No new model file; extend the existing freezed class. Regenerate (`build_runner build --force-jit`).

### 4.2 Assembler (`focus_mode_assembler.dart`)

- New private helper `_pickActivePanelId(...)` implementing §3.3 (1)–(3).
- `assemble(...)` gains an optional `userPinnedPanelId` parameter (passed through from bloc state).
- `assemble(...)` populates `activeSessionExerciseId` (honoring override per §3.3 (4)) and `activeIsUserPinned`.

### 4.3 Bloc / state

In `FocusModeReady`:

- Add `String? userPinnedPanelId`.
- Default null. Set by new event `FocusModeFocusedPanelSelected(sessionExerciseId)`. Cleared by the reducer immediately after a `FocusModeSetCompleted` whose `sessionExerciseId` matches the pinned id, and on `FocusModeGroupSwitched`.
- Pass `userPinnedPanelId` into `FocusModeAssembler.assemble(...)`.

New event:

```dart
sealed class FocusModeEvent { ... }
class FocusModeFocusedPanelSelected extends FocusModeEvent {
  const FocusModeFocusedPanelSelected(this.sessionExerciseId);
  final String sessionExerciseId;
}
```

`FocusModeSetCompleted` keeps its current `sessionExerciseId` argument. The screen will pass `group.activeSessionExerciseId` when the pinned LOG SET button is tapped.

### 4.4 Screen (`focus_mode_screen.dart`)

Rewrite `_ReadyBody`:

- Replace the scrolling `Column` with a non-scrolling `Column` containing:
  1. `_SupersetUpNextStrip` (new tiny widget — replaces today's `_SupersetHeader` + the trailing "Up next" text).
  2. `Expanded` wrapping a `Column` of:
     - `_ActivePanelCard` (the current `_PanelCard` minus the LOG SET button — extracted).
     - For each non-active panel: `_PartnerPanelCard` (new compact widget).
     - `_PartnerPanelCard` rows are tappable → dispatch `FocusModeFocusedPanelSelected`.
  3. `_PinnedBottomBar` — extended to include the LOG SET button at top, rest timer middle, undo bottom.
- Remove `SingleChildScrollView`. If on a phone too small to fit a 3-exercise giant set, the partner cards row becomes a `ListView` (still non-scrolling for 2-ex; scrollable region constrained to the partner list area only — the active card and bottom bar stay pinned).
- `_TransientErrorBanner` moves out of the scroll body — render as an overlay (`Positioned`) above the active card, or convert to a `SnackBar`. Recommend overlay so the banner doesn't autodismiss; user dismisses explicitly.

Widget extractions:

- `_PanelCard` → split into `_ActivePanelCard` (full editor, no button) and `_PartnerPanelCard` (compact).
- `_PanelCompleteButton` deleted (now lives only in `_PinnedBottomBar`).
- `FocusCompleteButton` is reused as-is for the pinned button.

### 4.5 Tests (per CLAUDE.md scope: services only, no widget/bloc tests)

Extend `test/modules/focus_mode/services/focus_mode_assembler_test.dart` with:

- Single-panel group → active equals that panel.
- 2-panel superset, no sets logged → active is position 0.
- 2-panel superset, A has 1 set, B has 0 → active is B (lower count wins).
- 2-panel superset, both have 1 set, A logged most recently → active is B (rotation).
- 2-panel superset, all loggable, user pinned B → active is B regardless of counts.
- User pinned panel is no longer loggable → fall back to auto-rotation.
- 3-panel giant set: ABA logged (A=2, B=1, C=0) → active is C.

No `bloc_test` changes (project doesn't carry the dep). Bloc reducer changes for `userPinnedPanelId` are simple state transitions; the existing `focus_mode_bloc_test.dart` already covers the surrounding flow and won't break.

### 4.6 Things that stay the same

- All editor widgets (`FocusRepBasedPanel`, `FocusTimeBasedPanel`, `FocusBodyweightPanel`) — unchanged.
- `FocusRestTimerBar` — unchanged; just lives below LOG SET now.
- `FocusSetProgress` — reused in both active and partner cards.
- `_SwitchExerciseButton` in app bar — unchanged.
- Replace / skip / mark-done flows — unchanged; the menu just appears on both active and partner cards.
- The bloc events for logging, bumping, editing, replacing, skipping, marking done — unchanged signatures.

## 5. Rollout

One PR, sequenced commits so review is digestible:

1. Assembler + view-model: add `activeSessionExerciseId`, `activeIsUserPinned`, auto-rotation function, optional `userPinnedPanelId` param. Tests in same commit. Codegen.
2. Bloc: add `userPinnedPanelId`, new event, reducer wiring, clear-on-log / clear-on-group-switch.
3. Screen rewrite: split `_PanelCard`, build `_PartnerPanelCard`, move LOG SET into `_PinnedBottomBar`, drop scroll, move "Up next" to top strip, move error banner to overlay.
4. Polish: empty/edge states (no loggable panel, replace dialog from partner card, video link on partner card), visual finish (active border, partner row hover/press states, haptic on partner tap).

Each commit keeps the app runnable. `tool/ci.sh` should stay green throughout.

## 6. Risks / open items

- **Auto-rotation surprise.** If a user logs A twice in a row intentionally (e.g. B is unavailable for a moment), the rule will keep promoting B. The manual-pin override solves this, but it requires the user to know they can tap B. Mitigation: subtle "tap to switch" hint on partner card the first time per session (deferred — not required for the redesign to ship).
- **3-exercise giant sets** still flirt with the height budget on small devices (SE-class). The plan accepts a *limited* scroll in the partner-cards strip only; LOG SET stays pinned. Acceptable until/unless real users complain.
- **Editor draft preservation when switching active.** Drafts are already keyed by `sessionExerciseId` in the bloc, so swapping active doesn't reset values — no change needed. Verify in QA.
- **Keyboard up + pinned button.** With `resizeToAvoidBottomInset: true` (Scaffold default), the pinned bottom bar lifts above the keyboard, which is what we want. No change.
- **"Up next" demoted to a single line** may feel hidden compared to today. If users miss it, an alternative is making it a chip in the app-bar subtitle. Punt until feedback.
