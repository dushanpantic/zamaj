<!-- spec-version: 7.9.0 -->
# Spec: Pre-fill Planned Sets from Recent History

## Intent Description

When a lifter adds a movement from the library to a workout plan, they land in
the exercise editor with a single blank planned set (0 kg × 0 reps) and have to
re-enter everything from scratch — even for a movement they trained last week.
This feature lets them carry the prescription forward instead of retyping it.

The exercise editor already shows a **Recent history** section for any linked
movement: the last 5 completed (non-deload) sessions, each row showing that
session's planned target and the actual weight/reps logged, with a `▲` marker
when the session capped. This feature makes those rows **actionable**: tapping a
row replaces the editor's planned sets with that session's **logged (actual)
values** — the full set structure (count + per-set weight/reps), so a pyramid or
a 3×5 carries over exactly as performed. It is a one-tap recall affordance, not a
recommendation, and it is fully reversible until the editor is saved.

Pre-filling from the *actual* logged sets (not the prior plan) was a deliberate
product choice: it answers "what did I really do last time" at the moment the
lifter sets the next target. Because last session's actuals are often "messy" (a
missed rep, a partial day), the affordance is **opt-in per row** rather than a
silent auto-fill — the lifter sees what each recent session looked like (and
which ones capped) and chooses which to pull in, honoring the app's pillar that
the planned side of the record stays deliberate, never silently overwritten by
actuals. The originating scenario — *adding from the library* — is served because
the add flow already drops the user straight into this editor; the capability
generalizes to any linked exercise opened there. "If any" is handled by the
existing empty/unlinked states: no history, nothing to tap, nothing pre-fills.

## Architecture Specification

### Components affected (4)

- **Domain (pure Dart) — new mapper.** An `ActualSetValues → PlannedSetValues`
  conversion (a static helper / factory, sibling to existing domain services),
  exported via the `domain` barrel:
  - `repBased(weightKg, reps)` → `PlannedSetValues.repBased(weightKg, RepTargetFixed(reps))`
  - `bodyweight(reps)` → `PlannedSetValues.bodyweight(RepTargetFixed(reps))`
  - `timeBased(durationSeconds, weightKg?)` → `PlannedSetValues.timeBased(durationSeconds, weightKg)`
  - Rep *ranges* do not apply — actuals carry only the reps performed, so the
    planned side becomes a **fixed** rep target. Pure Dart, no Flutter/Drift.
- **`ExerciseEditorBloc`** (`program_management/bloc/exercise_editor`) — gains an
  event `RecentHistoryEntryApplied` (identifying the chosen `CapHistoryEntry`).
  The handler maps that entry's `actualSets` through the domain mapper, converts
  to the editor's draft set type (reusing the existing `PlannedSetValues →
  PlannedSetDraft` path), **replaces** `draft.sets`, recomputes validation, and
  emits an editing state (which flips `isDirty`). It consumes the `CapHistory`
  **already loaded** into state by `_loadRecentHistory` — **no new repository
  call**. No new persisted state.
- **`RecentSetHistorySection`** (`program_management/widgets`) — each row that has
  ≥ 1 logged actual set becomes tappable (dispatches `RecentHistoryEntryApplied`);
  rows showing zero logged actuals ("—") are non-interactive. A confirmation
  gates the replace **only** when the draft already holds user-entered sets (not
  the just-added blank default). A one-time, per-app-process coach-mark explains
  the tap (existing `static bool` pattern; no `shared_preferences`).
- **`PRODUCT.md`** — exercise-editor description updated (user-facing capability).

### Persistence

None. No schema-version change, no migration. Reuses
`SessionRepository.listCompletedSessions()` — already called to build the
recent-history section; this feature adds **no** further repository reads.

### Constraints

- `domain` stays pure Dart; mapper exported via the `domain` barrel. UI reads
  session data only through `SessionRepository`; no Drift / `AppDatabase` /
  networking imports anywhere.
- Cross-module imports via barrels using `package:zamaj/...`.
- The editor is a **normal-ergonomics** surface (not a sweaty-hands one): the row
  tap target is ≥ `AppSpacing.touchMin` (48 dp). Theme tokens only — no
  hard-coded px / color literals; numeric readouts keep the tabular `numericSm`
  style they already use.
- Apply is a **draft mutation only** — non-destructive and reversible via the
  editor's existing discard-changes guard; nothing is written until save.
- Copy stays descriptive (no-coaching non-goal): the affordance recalls what was
  logged; it never recommends a target.

### Out of scope (deferred)

- Applying the prior **planned** target (vs. actual) — source is fixed to actual
  by decision.
- Auto-fill at add-time without a tap (silent pre-fill) — rejected by decision.
- Pre-fill into a superset member at add-time, or for quick (one-off, unlinked)
  exercises — no library identity, so no history to draw from.
- Once-ever (cross-cold-start) suppression of the coach-mark — deferred with all
  other coach-marks to the future shared-preferences refactor.

## Acceptance Criteria

### Apply behavior
- **AC1** — In the exercise editor for a **linked** exercise that has ≥ 1
  completed (non-deload) session logging the movement, each recent-history row
  with ≥ 1 logged actual set is tappable; tapping it **replaces** the planned
  sets with that session's logged sets (full structure).
- **AC2** — Mapping is per-set: rep-based weight+reps → planned weight + **fixed**
  rep target (reps); bodyweight reps → planned fixed rep target (reps);
  time-based duration (+ optional weight) → planned duration (+ weight). Rep
  ranges never result (actuals are fixed).
- **AC3** — The resulting planned set **count** equals the number of logged actual
  sets in the chosen row: a session with extra sets fills more; a partial session
  (fewer logged than planned) fills fewer.
- **AC4** — A row whose session logged **zero** sets of the movement (rendered as
  "—") is not tappable; applying it is a no-op.
- **AC5** — When applying would discard planned sets the user has already entered
  (the draft differs from the just-added single blank default), a confirmation
  gates the replace: confirm applies, cancel leaves the draft unchanged. When the
  draft is still the blank default, apply proceeds without a prompt.
- **AC6** — Apply mutates the editor draft only and flips the dirty flag; it is
  persisted through the editor's existing save path and reversible via the
  existing discard-changes guard. No write occurs until the user saves.

### "If any" / exclusions
- **AC7** — An **unlinked** exercise (quick one-off) shows the existing link
  nudge and nothing applyable; a linked exercise with **no** completed history
  shows the existing "No history yet" empty state — in both cases nothing
  pre-fills.
- **AC8** — Deload sessions are never offered as applyable rows (already excluded
  from recent history), so a plan is never seeded from a deliberately-light week.
- **AC9** *(defensive)* — If a row's logged actuals are of a different measurement
  type than the exercise's current (locked) type, those sets are not applied and
  nothing crashes. (Locked measurement types make this effectively unreachable.)

### Originating scenario & discoverability
- **AC10** — After adding an exercise **from the library**, the user lands in the
  exercise editor where (for a movement with history) recent-history rows are
  immediately tappable to pre-fill. The add event/path itself is unchanged — sets
  start blank until a row is tapped.
- **AC11** — A one-time, per-app-process coach-mark explains that rows can be
  tapped to pre-fill; it does not re-appear within the same process. (Per-cold-
  start re-appearance is accepted, matching existing coach-marks.)

### Non-functional / constraints
- **AC12** — No schema-version change and no migration; no repository call is
  added beyond the `listCompletedSessions()` already used for recent history.
- **AC13** — The `ActualSetValues → PlannedSetValues` mapper is pure Dart,
  exported via the `domain` barrel, and unit-tested across rep-based, bodyweight,
  and time-based (with and without weight). The bloc apply handler is unit-tested
  for: replace + correct count (AC1–AC3), zero-actuals no-op (AC4), blank-default
  vs. edited overwrite gate (AC5), and the dirty/reversible contract (AC6) —
  plain `flutter_test` + `FakeSessionRepository`, no `bloc_test`, no widget tests.
- **AC14** — All new/changed UI uses theme tokens (no hard-coded px / color
  literals); the row tap target is ≥ 48 dp; numeric readouts keep `numericSm`.
- **AC15** — `PRODUCT.md`'s exercise-editor description is updated to note that
  recent-history rows can be tapped to pre-fill the planned sets from that
  session's logged values.

## Ambiguity Log

| Decision | Classification | Resolved By | Rationale / Answer |
|----------|---------------|-------------|-------------------|
| Source of the pre-filled value: prior **planned** target vs. **actual** logged vs. current template prescription | `requires-stakeholder-input` | human | **Last actual performance** — what was logged in the most recent (chosen) session. |
| Carry the full set structure vs. a single representative value | `requires-stakeholder-input` | human (delegated → agent) | **Full structure** (count + per-set), via the chosen recent row. |
| UX: silent auto-fill vs. opt-in "use last session" banner vs. tappable recent-history rows | `requires-stakeholder-input` | human (delegated → agent) | **Tap any recent-history row.** Reuses the already-rendered list; no redundant UI; lets the lifter pick a *clean* (e.g. capped `▲`) session rather than only the possibly-messy latest; deloads already filtered out. |
| Rep *ranges* on the planned side when sourcing from actuals | `inferable` | inference | Actuals have no range concept → planned becomes a **fixed** rep target. |
| Planned set count when applying | `inferable` | inference | Equals the number of logged actual sets in the chosen row (full-structure copy). |
| Rows with zero logged actuals ("skipped that day") | `inferable` | inference | Non-applyable / no-op — nothing to copy; list already renders these as "—". |
| Deload sessions | `inferable` | inference | Already excluded from recent history (`_excludedFromCap`); no extra handling, and never a pre-fill source. |
| Overwrite of already-entered planned sets | `inferable` | inference | Confirm only when discarding non-blank edits; the blank just-added default applies silently. Matches the editor's existing discard-changes safety. |
| Measurement-type mismatch between a historical row and the locked type | `inferable` | inference | Defensively skip non-matching variants; locked measurement type makes this unreachable in practice. |
| Where the change lives (day-editor add-time vs. exercise editor) | `inferable` | inference | Exercise editor — the recent-history data is already loaded and rendered there, and the add flow navigates straight into it. Keeps it a non-destructive draft mutation. |
| Scope: only freshly-added-from-library vs. any linked exercise in the editor | `inferable` | inference | Any linked exercise — same surface, no "just added" flag needed; quick/unlinked exercises naturally excluded (no history). |
| Persistence timing | `inferable` | inference | Draft mutation only; persisted via the editor's existing save path; reversible before save. |

## Consistency Gate
- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering (reuses already-loaded data; no schema/migration; one new pure-Dart mapper + one bloc event)
- [x] Terminology consistent across artifacts (recent history, capped `▲`, planned vs. actual, draft, linked/unlinked)
- [x] No contradictions between artifacts
- [x] Every gap/ambiguity finding is logged — three resolved by the human, the rest inferable with explicit rationale

**Verdict: PASS.**
