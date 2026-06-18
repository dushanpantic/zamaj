# Spec: Deload Week (v1, simplest)

## Intent Description

A lifter periodically runs a **deload** — a planned, temporary back-off week to recover before resuming normal progression. In Zamaj this maintainer's deload means **halving the number of working sets**, plus *maybe* a small manual weight cut on the heaviest lifts. Today the app has no way to express this: doing 2 of 4 planned sets reads as **"partial 2/4"** (incomplete work) instead of a complete, deliberately-lighter session, and a reduced-load session would pollute the two history-derived features — it would show as a regression dip in the top-set progress trend and could silently clear a real CAPPED badge.

This feature lets the user **declare a session a deload at start**. Doing so (a) reduces that session's *planned* working-set count so the session reads as **completed**, not partial, and (b) tags the session so it is **excluded** from the progress trend and CAPPED computations and is **visibly marked** as a deload everywhere it appears. The program template is never mutated — the reduction is applied only to the session's frozen snapshot, preserving snapshot immutability and the planned-vs-actual separation. Weight reductions stay **manual and per-lift**, logged in-session as actuals through the existing editor, so the app never prescribes a number (honoring the "no coaching / AI recommendations" non-goal).

"Simplest first": v1 ships the declare-at-start toggle, the set-halving transform, the flag and its exclusions/badges, and current-week retroactive tagging. The week-ahead per-exercise setup editor and the advisory cadence reminder are explicitly deferred (see Non-Goals), but the model is shaped so they can layer on without rework.

## Architecture Specification

### New domain state
- **`Session.isDeload : bool`** (default `false`) — the single source of truth that a session was a deload. Set once at start; whole-session granularity (no per-exercise deload flag). Lives on `Session` ([session.dart](../../mobile/lib/modules/domain/models/session.dart)), **not** inside `SessionSnapshot` (the snapshot's hash invariant must stay a pure function of `workoutDay`).

### Set-reduction transform (applied at start, before snapshot capture)
- A pure transform over `WorkoutDay`: for each `ExerciseGroup` whose `role == main`, reduce every `Exercise.sets` to its **first `ceil(n/2)`** entries (round up, floor 1): 1→1, 2→1, 3→2, 4→2, 5→3. Groups with `role == warmup` are **left untouched** ([exercise_group_role.dart](../../mobile/lib/modules/domain/models/exercise_group_role.dart)).
- The transform runs in `SessionRepository.startSession` *before* `SessionSnapshot.capture` ([session_snapshot.dart:51](../../mobile/lib/modules/domain/models/session_snapshot.dart#L51)). `capture` hashes the transformed day, so the snapshot stays internally consistent; no template row is modified. Downstream, `EffectiveExercises.plannedSetCount` reads the halved count from the snapshot, so completion/partial derivation, open-target computation, and session-complete checks all flow through unchanged.

### Wiring (start path)
- `SessionRepository.startSession({required String workoutDayId, bool isDeload = false})` — applies the transform when `isDeload`, persists `Session.isDeload = true`.
- `SessionFlowEngine.startSession` ([session_flow_engine.dart:27](../../mobile/lib/modules/domain/services/session_flow_engine.dart#L27)) gains the `isDeload` pass-through; the workout_day_picker bloc supplies it from the toggle.

### History-derivation exclusions
- `ExerciseProgressAggregator.compute` — extend the ended-session filter ([exercise_progress_aggregator.dart:36](../../mobile/lib/modules/domain/services/exercise_progress_aggregator.dart#L36)) to also drop `s.isDeload`.
- `ExerciseCapHistoryAggregator.computeHistory` **and** `computeBadge` — skip `isDeload` sessions ([exercise_cap_history_aggregator.dart](../../mobile/lib/modules/domain/services/exercise_cap_history_aggregator.dart)).
- **Do not** filter in `SessionHistory.completedNewestFirst` ([session_history.dart:15](../../mobile/lib/modules/domain/services/session_history.dart#L15)) — it is shared with the Recent Sessions list, which must still show deload sessions (tagged). Exclusion is local to the two aggregators.

### Persistence & schema
- New `isDeload` boolean column on the sessions table; Drift migration defaulting existing rows to `false`.
- Bump `SchemaVersions.domain` 8→9 and `SchemaVersions.drift` 12→13 ([schema_versions.dart](../../mobile/lib/core/schema_versions.dart)); add a migration step in [migrations.dart](../../mobile/lib/modules/persistence/database/migrations.dart).

### UI surfaces (read the deload flag; no new in-session controls)
- **Workout-day picker** ([workout_day_picker_screen.dart](../../mobile/lib/modules/workout_day_picker/screens/workout_day_picker_screen.dart)): a **"Deload week"** affordance alongside Start. Once any session in the current `TrainingWeek` ([training_week.dart](../../mobile/lib/modules/domain/models/training_week.dart)) is a deload, the affordance pre-selects deload for further starts that week (derived default, overridable; no new persisted state).
- **DELOAD badge** on: workout_overview session header, Recent Sessions tile, Session Detail review. Session review shows the **deload plan only** (the halved count); no dual "normally N" display.
- **Plain-text export**: a deload marker in the session header line.

### Retroactive tagging
- `Session.isDeload` is editable **only within the current `TrainingWeek`**, folded into the existing current-week "correct a mis-logged actual" softening of immutability. Older sessions stay frozen.

### Weight reduction
- No new mechanism. Planned weight is unchanged by the transform; the user logs lower actuals in-session via the existing ± editor / inline log path. The planned-vs-actual gap on a deload session is acceptable and expected.

### Constraints / invariants preserved
- Program template never mutated; snapshot frozen at start; snapshot hash invariant intact (transform precedes capture).
- Planned-vs-actual stays first-class. Domain layer stays pure Dart. Picker toggle obeys standard 48 dp targets (not an in-session sweaty-hands surface).
- No prescription of weights/numbers (no-coaching non-goal).

### Non-Goals (deferred, design leaves room)
- Advisory cadence reminder ("N weeks since last deload").
- Week-ahead per-exercise setup/preview editor.
- Per-lift planned-weight reduction at start (and the "show both / normally N" dual display).
- A reusable "Deload day" template variant.

## Acceptance Criteria

1. **Declare at start** — Starting a session via the "Deload week" affordance produces a `Session` with `isDeload == true`; starting normally produces `isDeload == false`. *(pass: flag set per path)*
2. **Working sets halved, round up, floor 1** — In a deload session's snapshot, each `main`-group exercise has `ceil(n/2)` planned sets (1→1, 2→1, 3→2, 4→2, 5→3), preserving the first sets in order. *(pass: per-count assertions, including a vary-by-set exercise keeping its first sets)*
3. **Warmups untouched** — `warmup`-role groups retain their full planned set count in a deload snapshot. *(pass: warmup set count unchanged)*
4. **Reads completed, not partial** — Logging the halved quota in a deload session makes the exercise derive as **completed** (not "partial X/Y"). *(pass: ExerciseOutcome == completed at halved quota)*
5. **Template untouched** — The program's `WorkoutDay` planned set counts are identical before and after starting a deload session. *(pass: template equality)*
6. **Snapshot integrity** — A deload session's snapshot passes its canonical-JSON/hash invariant. *(pass: no ValidationError on capture)*
7. **Excluded from progress trend** — `ExerciseProgressAggregator.compute` yields no point for a deload session even when it logged the movement. *(pass: deload session absent from series)*
8. **Excluded from CAPPED** — Neither `computeBadge` nor `computeHistory` counts a deload session (a deload session never sets the badge and never appears in the recent set-history table). *(pass: badge unaffected; history omits it)*
9. **Still in Recent Sessions, tagged** — A deload session appears in `SessionHistory.completedNewestFirst` and renders with a DELOAD badge on the tile, the overview header, and the Session Detail review. *(pass: present in list; badge shown on all three)*
10. **Export marked** — Plain-text export of a deload session includes a deload marker in its header. *(pass: marker present)*
11. **Week-derived default** — On the picker, after a deload session exists in the current `TrainingWeek`, further starts that week default to deload and remain overridable. *(pass: default on; can be turned off)*
12. **Retroactive within week only** — `isDeload` can be toggled on a current-week session; attempting it on an out-of-week (older) session is rejected. *(pass: in-week allowed, older rejected)*
13. **Migration safe** — Existing persisted sessions load post-migration with `isDeload == false`. *(pass: legacy rows default false)*

## Consistency Gate
- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts ("deload", `isDeload`, "working sets", "warmup groups", "snapshot", "planned-vs-actual")
- [x] No contradictions between artifacts
