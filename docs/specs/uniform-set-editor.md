# Spec: Uniform Set Editor (Solution A)

> Source analysis: [set_adjustment_ux.md](../../set_adjustment_ux.md). Chosen direction: **A — uniform-first, expand to vary**, with ± steppers folding in the relative-bump benefit of B.

## Intent Description

When a coach raises the weight on an exercise, the lifter currently has to edit the same
number once per set — four identical edits for a 4-set exercise — because the Exercise
editor renders every set as a fully independent row. The reported workaround (delete three
sets, edit the survivor, duplicate it three times) is evidence the editor optimizes for the
*rare* case (per-set variation: pyramids, ramps, drop sets) at the expense of the *common*
case (straight sets — every set identical).

This change makes **identical sets the default presentation**. When an exercise's sets all
share the same planned values, the editor shows a single weight control, a single reps
control, and a sets-count control that together drive **all** sets at once. The weight and
reps controls are ± steppers (reusing the app's existing `IncrementRules` step policy), so
"coach added 2.5 kg" is a single tap that moves every set, while direct typing still allows
an absolute new value. Full per-set control is preserved behind a **"Vary by set"**
expander for genuinely varied exercises, which open expanded automatically so no intentional
variation is ever hidden or silently flattened.

This is a presentation-and-affordance change only. Each set still persists its own planned
values; "uniform" is computed from the draft and fanned back out to per-set values on every
edit. No schema, domain, migration, save, or validation change is required.

## Architecture Specification

**Surface:** Exercise editor only — `program_management` UI module.
- [exercise_editor_screen.dart](../../mobile/lib/modules/program_management/screens/exercise_editor_screen.dart)
- [exercise_editor_form.dart](../../mobile/lib/modules/program_management/widgets/exercise_editor_form.dart)
- [planned_set_row.dart](../../mobile/lib/modules/program_management/widgets/planned_set_row.dart) (reused unchanged in expanded mode)
- [exercise_editor_bloc.dart](../../mobile/lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart) + `exercise_editor_event.dart`

**Reused, unchanged:**
- [increment_rules.dart](../../mobile/lib/core/increment_rules.dart) — single source of step policy: weight ±1 ≤10 kg / ±2.5 above, reps ±1, duration ±5 s, `bumpWeight` (half-kg snap, clamp ≥0), `bumpReps`/`bumpDuration` (clamp ≥0).
- Save path (`_onSavePressed`), `ExerciseDraftValidation.compute`, dirty/discard guard, the draft model (`PlannedSetDraft` / `PlannedSetDraftValues`).

**New components**
- A **uniform sets editor** widget: weight stepper, reps stepper, sets-count stepper, a live summary line (`4 × 5 @ 100 kg`), and the "Vary by set" expander control. Presents per measurement type (see below).
- A reusable **stepper field** (editable center value flanked by − / + buttons). May be a `building_blocks` widget or a local widget; steps come from `IncrementRules`. This is **not** an in-session surface, so the 48 dp (`AppSpacing.touchMin`) target applies — the 64 dp sweaty-hands floor does **not**.

**Presentation state (widget-level, derived — not persisted)**
- *Uniform* ⇔ every set in `draft.sets` has equal `values` (blank-but-equal counts as uniform). Computed from the draft.
- *Mode* = collapsed (uniform editor) | expanded (per-row list). Default: collapsed when uniform, **expanded when non-uniform on open**.

**New bloc events (fan-out over `draft.sets`)**
| Event | Effect |
|---|---|
| `PlannedSetCountChanged(count)` | Grow → append sets inheriting the uniform/last value; shrink → drop from the end. Clamp 1–20 (existing bounds). |
| `AllSetsWeightChanged(rawInput)` | Set `weightInput` on every set (absolute typing). |
| `AllSetsWeightBumped(delta)` | `IncrementRules.bumpWeight` applied to every set's parsed weight. |
| `AllSetsRepsChanged(rawInput)` | Set `repsInput` on every set. |
| `AllSetsRepsBumped(delta)` | Apply delta to **every numeric token** of each set's `repsInput` (`5`→`6`, `6-8`→`7-9`), clamp ≥0, preserve range shape; no-op on blank/non-numeric. |
| `AllSetsDurationChanged` / `AllSetsDurationBumped` | Time-based equivalents (±5 s). |
| `AllSetsFlattenedToFirst()` | Collapse-to-uniform: set every set to set 1's values. UI gates this behind a confirm. |

Per-set events (`PlannedSetWeightChanged`, `…RepsChanged`, `…DurationChanged`, `…Added`, `…Deleted`, `…Reordered`) stay for expanded mode.

**Per measurement type** (type is per-exercise, so all sets share one shape):
- Rep-based → weight stepper + reps stepper + count.
- Time-based → duration stepper (±5 s) + optional weight stepper + count.
- Bodyweight → reps stepper + count (no weight control).

**Constraints**
- UI-token mandate: no hard-coded px or color literals under the new widgets; colors via `Theme.of(context).appColors`, spacing/radius via `AppSpacing`/`AppRadius`, numeric readouts via `AppTypography.standard.numeric`.
- Layer rules: stays in the UI module; talks to data only through the existing bloc/draft; no Drift/`AppDatabase` references.
- All ± steps sourced from `IncrementRules` — no new step literals.

## Acceptance Criteria

- **AC1 — Uniform default.** Opening an exercise whose sets are all identical shows the uniform editor (one weight control, one reps control, one sets-count control, a summary line) — not N rows.
- **AC2 — One-tap coach bump.** In uniform mode, tapping weight `+2.5` raises the planned weight of **every** set by 2.5 kg (half-kg snapped, clamped ≥0) in one action; saving persists the new weight on all sets.
- **AC3 — Absolute weight typing.** Typing a value into the uniform weight field sets that exact weight on every set.
- **AC4 — Reps token bump + ranges.** Reps `+1` turns `5`→`6` and `6-8`→`7-9` on every set, clamped ≥0, preserving range shape; the field still accepts a range typed directly.
- **AC5 — Sets count.** `+` appends a set inheriting the uniform value; `−` removes the last set; control is bounded 1–20 and the relevant button is disabled at each bound.
- **AC6 — Varied opens expanded.** Opening an exercise with non-uniform sets shows the per-row list with a visible "sets vary" indicator, and changes no values on open.
- **AC7 — Expand parity.** "Vary by set" reveals the existing per-row editor; per-row weight/reps/duration/add/delete/reorder behave exactly as today.
- **AC8 — Collapse is non-destructive without consent.** Collapsing to uniform while sets differ prompts a confirm and only then flattens all sets to set 1's values; collapsing while already uniform changes no values and shows no prompt.
- **AC9 — All measurement types.** Rep-based, time-based (duration ±5 s + optional weight), and bodyweight (reps only, no weight control) each render the correct uniform controls.
- **AC10 — No model change.** A uniform-edited exercise saves to the same per-set `WorkoutSet` structure with equal planned values across sets; existing save, validation, and dirty-discard behavior are unchanged; domain & persistence test suites remain green without modification.
- **AC11 — Token & layer compliance.** New widgets use only design tokens (no px/color literals), tap targets ≥48 dp, ± steps from `IncrementRules`, and `tool/check_offline_imports.sh` passes.
- **AC12 — Quality gate.** `tool/ci.sh` passes (imports → codegen → format → analyze → test).

**Non-goals**
- Day-editor "progress this exercise" inline action (separate, larger spec).
- Any change to in-session surfaces (`workout_overview`, `focus_mode`) or text-plan import.
- Any schema / domain / migration change, or a persisted "shared weight" concept — uniformity is presentation only.

## Consistency Gate
- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts
- [x] No contradictions between artifacts

**Verdict: PASS** — uniform/varied presentation, ± fan-out via `IncrementRules`, range-safe reps token bump, auto-expand on varied open, and confirm-gated flatten are each covered by an acceptance criterion with no cross-artifact conflict. Cleared to plan.
