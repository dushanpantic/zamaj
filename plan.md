# Workout-day editor — UX deep dive & plan

Target screen: [workout_day_editor_screen.dart](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart).

This screen lists the exercises of one workout day, lets the lifter add/reorder/group/delete them, and edits the day's name. It is *out-of-session* surface (program-management), so the live-session ergonomics rules (64 dp counters, etc.) don't apply, but it must still be scannable and predictable — it's the screen the lifter visits when prepping or revising a program.

---

## 1. The reported bug — rep ranges show as "Rep-based"

### Repro

An exercise with three sets, all "60 kg × 5–8 reps":
- Expected subtitle: `60kg 3×5-8`
- Actual subtitle: `3 sets · Rep-based`

### Root cause

In [workout_day_editor_screen.dart:703-719](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L703-L719), `_uniformSummary` parses the rep input with `int.tryParse`:

```dart
final r = int.tryParse(values.repsInput);
if (w == null || r == null) return null;
```

For range inputs (`"5-8"`, `"5–8"`), `int.tryParse` returns `null`, so `_uniformSummary` returns `null` and `_subtitleFor` falls back to `'${sets.length} sets · $typeLabel'`.

The bodyweight branch in the same function (`_uniformSummary` lines 747–756) accidentally avoids the bug because it compares raw `repsInput` strings — `"5-8" == "5-8"` works for equality, and the string is rendered verbatim. The rep-based and time-based branches use parsed ints.

### Why this is more than a one-line fix

The codebase already has a canonical formatter for this exact case: [rep_target_formatter.dart](mobile/lib/core/rep_target_formatter.dart) — and a parallel summary builder for the *domain* model in [planned_summary_formatter.dart](mobile/lib/modules/workout_overview/services/planned_summary_formatter.dart) which uses it correctly. The editor screen has its own ad-hoc copy that is now out of sync.

We also know the editor already knows how to parse rep-range strings: [program_editor_draft.dart:144-154](mobile/lib/modules/program_management/models/program_editor_draft.dart#L144-L154) (`_parseRepTargetOrZero`). It just isn't reused for display.

### Fix

Introduce `PlannedDraftSummaryFormatter` in `lib/modules/program_management/services/` that mirrors `PlannedSummaryFormatter` but takes `List<PlannedSetDraft>`:

- Parse each set's `repsInput` to a `RepTarget` via the existing draft parser (extract `_parseRepTargetOrZero` out of `ProgramDraft` into a shared `lib/modules/program_management/services/draft_parsing.dart` so both saver and formatter use it — no more drift).
- Compare on the *parsed* `RepTarget` (so `"5-8"` and `"5 – 8"` are treated as equal).
- Render via `RepTargetFormatter.format`, producing e.g. `60kg 3×5-8`, `3×5-8` (bodyweight), `BW 3×5-8` if we want to disambiguate (see §2.3).
- Replace `_subtitleFor` / `_uniformSummary` in [workout_day_editor_screen.dart:689-758](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L689-L758) with one call to the new formatter.

Add a domain-layer test in `test/repository/` covering rep-range, single-rep, mixed-rep, mixed-weight, empty-sets, en-dash vs hyphen.

---

## 2. UX critique — beyond the bug

Going through the screen with fresh eyes turned up a handful of issues that compound the rep-range one: when the screen *can* show useful info it sometimes gives up; when it expects gestures it doesn't teach them; when state changes it under-signals.

Prioritized below — P1 ships with the bug fix; P2/P3 are follow-ups.

### 2.1 (P1) "X sets · Rep-based" is an information dead-end

The subtitle falls back to `${sets.length} sets · ${typeLabel}` whenever sets aren't uniform. For a real strength program this is common — e.g. 5/5/5 then 8/8/8 (back-off sets), or pyramids. The measurement-type label adds nothing the user doesn't already know.

**Proposal:** instead of bailing, degrade gracefully:

| Case | Current | Proposed |
|---|---|---|
| All sets uniform | `60kg 3×5` | `60kg 3×5` (unchanged) |
| All sets uniform, range reps | `3 sets · Rep-based` (BUG) | `60kg 3×5-8` |
| Same weight, varying reps | `4 sets · Rep-based` | `60kg · 5/5/8/8` (up to ~6 sets, then `60kg · 4 sets`) |
| Varying weight, same reps | `4 sets · Rep-based` | `60–80kg · 4×5` |
| Varying both | `4 sets · Rep-based` | `4 sets · 60–80kg` |
| Empty / 0 sets | `Rep-based` | `No sets planned` (subtle warning color — see §2.5) |

The formatter from §1 should produce all of these. Keep it under ~32 chars so it always fits one line; ellipsize as last resort.

### 2.2 (P1) Empty state has the wrong CTA gravity

Today: empty list shows centered `Icons.fitness_center_outlined` + "No exercises yet. Tap + to add one." The `+` is in the AppBar's top-right ([workout_day_editor_screen.dart:222-227](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L222)). Eye-flow from the centered text to a top-right icon is awkward, and the affordance is small (24 px icon button).

**Proposal:** put a primary `FilledButton.icon` ("Add exercise") under the empty-state text. Keep the AppBar `+` as the secondary path once the list is populated. The button respects the standard 48 dp tap target (this is not in-session, so no need for 56 dp).

### 2.3 (P2) Measurement type is invisible when it matters

Once uniform, the subtitle drops the measurement type entirely (`60kg 3×5` doesn't say "rep-based"). That's correct for rep-based — `kg` and `×` tell you everything — but for **bodyweight** it currently shows `3×8` which is indistinguishable from `3×8` reps for a barbell movement that just happens to have 0 kg. Time-based shows `3×30s` which is at least clear.

**Proposal:** prepend a tiny semantic glyph or label for bodyweight: `BW · 3×8` (or use a `_BodyweightChip` mirroring `_WarmupBadge`). For time-based the `s` suffix already disambiguates.

### 2.4 (P2) Gesture overload with zero discoverability

A single tile responds to **five** different inputs:
1. Tap → navigate to exercise editor
2. Swipe left → confirm delete dialog
3. Long-press (anywhere) → start drag for free reorder (`LongPressDraggable`)
4. Press-and-hold on the drag handle → start `ReorderableListView` reorder
5. Drop one tile on another → form a superset (`DragTarget`)

There is no in-app teaching. The `Icons.drag_handle` is the only hint, and it only covers #4. Swipe-to-delete is invisible; superset-via-drop is invisible; the difference between #3 and #4 is invisible.

This is a real problem: a user who never finds drag-onto-superset will think the app can't do supersets at all (it can — only via this gesture, since the menu's `_GroupMenuAction.ungroup` exists but there is no symmetric `group` action).

**Proposal (incremental, not a rewrite):**

- Add an explicit "Group into superset" action to the `PopupMenuButton` on each flat exercise tile. Opens a small chooser ("Group with…") listing other exercises in the day. This keeps the drag-onto gesture as a power-user shortcut but stops hiding the feature.
- On first visit to the screen (once per install — gated by a `SharedPreferences` flag), show a single non-blocking coach-mark Snack: "Swipe left to delete · Long-press to reorder · Use the ⋮ menu for more". One-shot, dismissible.
- The drop-target visual is a 2 px primary border ([workout_day_editor_screen.dart:524](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L524)). Boost to a tinted background fill (`colors.primary.withValues(alpha: 0.10)`) **plus** the border. Cheap, much more visible mid-drag.

### 2.5 (P2) Per-exercise validation is hidden

The bloc emits `WorkoutDayDraftValidation` ([workout_day_editor_screen.dart:107-112](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L107-L112)) but only `validation.isNameValid` is surfaced (on the AppBar name field). If an exercise has 0 sets or a set with `weightInput == ""`, the tile gives no signal — the user discovers this only when they tap in or when save fails (banner at top, but generic).

**Proposal:** add a small inline `Icons.warning_amber_rounded` (colored `colors.error` at 14 px) on tiles whose exercise fails validation, with a tooltip / semantics label ("No planned sets" / "Incomplete sets"). Render to the right of the subtitle, before the rest chip. Requires exposing `validation.invalidGroupIds` (or similar) on the state — small bloc change.

### 2.6 (P3) Auto-save feedback is too quiet

The save spinner is a 16 × 16 indeterminate spinner in the AppBar ([workout_day_editor_screen.dart:213-220](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L213-L220)). On a fast device it flashes for ~50 ms after each edit; on a slow one the user wonders if changes are being kept. The save *error* banner is good; success is invisible.

**Proposal:**

- Replace the spinner with a tri-state "save chip" in the AppBar: idle `"Saved"` (muted), saving `"Saving…"` (with spinner), error `"Save failed — tap to retry"` (error color, tappable to re-emit the last event). Total cost: one small stateless widget driven by `(isSaving, lastSaveError)`. The persistent "Saved" word is the auto-save reassurance that today is missing.
- Make the error banner dismissible (it currently lives until the next state).

### 2.7 (P3) Superset internals could be more legible

Right now both members of a superset look identical inside the card — same chrome, no ordering signal. The conventional notation (`A1`, `A2`) is what users coming from coaches' programs will expect, and our own [text_plan_parser.dart](mobile/lib/modules/program_management/services/text_plan/text_plan_parser.dart) presumably understands it.

**Proposal:** prefix each child tile's title with a small `A1` / `A2` badge (use `_WarmupBadge`-style chip but colored `colors.onSurfaceMuted` on `surfaceVariant`). Optional polish; do not block.

### 2.8 (P3) The name field looks like a title, not a field

The name `TextField` lives in the AppBar with no border, no underline, no label ([workout_day_editor_screen.dart:204-208](mobile/lib/modules/program_management/screens/workout_day_editor_screen.dart#L204-L208)). It looks like the screen title until you tap it. New users won't realise it's editable.

**Proposal:** add a small trailing `Icons.edit` (14 px, `onSurfaceMuted`) as an in-field suffix when not focused; hide it on focus. Two lines of code, large discoverability win.

---

## 3. Out of scope (deliberately not changing)

- The `ReorderableListView` + `LongPressDraggable` combination is gnarly but it works; replacing it would be a much bigger change and is not what this pass is for.
- Cross-day operations (duplicate day, move exercise to another day) — separate workflow.
- Set editing on the tile itself — kept in [exercise_editor_screen.dart](mobile/lib/modules/program_management/screens/exercise_editor_screen.dart) where there is room for proper input rows. Editing sets in-line in a list view fights the offline-first single-source-of-truth pattern (multiple draft scopes).
- Live-session ergonomics rules don't apply here (this is program editing, not in-session).

---

## 4. Suggested shipping order

1. **PR 1 — bug fix + summary upgrade (§1, §2.1):**
   - Extract `_parseRepTargetOrZero` into `program_management/services/draft_parsing.dart`.
   - Add `PlannedDraftSummaryFormatter` and unit tests in `test/repository/`.
   - Replace `_subtitleFor`/`_uniformSummary` with the formatter.
   - Add the "no sets planned" subtle-warning case.
2. **PR 2 — empty state + measurement disambiguation (§2.2, §2.3):**
   - Empty-state CTA button.
   - Bodyweight `BW` prefix.
3. **PR 3 — discoverability (§2.4, §2.5):**
   - "Group into superset" menu action + chooser.
   - One-shot coach-mark snack.
   - Boosted drop-target visual.
   - Per-exercise validation icon + bloc surface.
4. **PR 4 — polish (§2.6, §2.7, §2.8):**
   - Save chip.
   - A1/A2 superset numbering.
   - Edit-icon affordance on the name field.

Each PR is self-contained, reviewable in ~30 minutes, and ships visible improvements. The bug fix doesn't have to wait on the rest.

---

## 5. No product-context.md update needed

None of the above adds, removes, or renames a screen, feature, or pillar. Per [CLAUDE.md](CLAUDE.md#keeping-product-contextmd-current), the rule is "update when the *user-facing surface* shifts" — these are improvements to an existing screen.
