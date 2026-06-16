# Spec: Set History with Progression Hints

## Intent Description

The solo lifter progresses each movement manually with a double-progression scheme — start a weight at a fixed rep target, widen to rep ranges, then bump the load and reset reps. The app deliberately never tells them what to lift, but today it gives them nothing at the moment they set next session's target. So they over-shoot (bump too soon, then fall a few reps short) or — more often — stall (keep capping a rep range and forget to tighten it or add weight). A real example: an elbow-rehab block where the lifter deliberately holds a reduced weight and hits every set, with no intent to progress.

This feature surfaces the planned-vs-actual record the lifter already logs, at the two moments the progression decision is actually made:

1. **In the exercise editor — a recent set-history table.** The last 5 completed sessions of the movement, each showing the planned target and the actual reps per set, with a marker when a session "capped" (all working sets met or exceeded the target ceiling).
2. **In the workout-day editor — a "needs attention" badge.** Flags any exercise whose recent history at the current prescription has been capped — i.e. a lift already maxed at its current weight + target that hasn't been advanced.

Everything is strictly descriptive: it shows what happened against the plan; the lifter still decides whether and how to advance (honoring the no-coaching non-goal). v1 is read-only — it derives entirely from existing session history and the program template, adding **no persisted state**.

## Architecture Specification

### Domain (pure Dart) — new

- **`CapHistory` / `CapHistoryEntry` models.** Newest-first list of recent session entries. Each entry carries: session date (`startedAt`), source program id + workout-day name, an ordered list of per-set `(PlannedSetValues, ActualSetValues)` pairs, and a derived `isCapped` flag. Measurement-type agnostic via the existing `PlannedSetValues` / `ActualSetValues` sealed types.
- **`ExerciseCapHistoryAggregator`** (pure-Dart service in `domain/services`, sibling of `ExerciseProgressAggregator`):
  - `computeHistory({required String libraryExerciseId, required List<Session> sessions, int limit = 5})` → `CapHistory`. Filters to ended sessions, attributes sets by the snapshot planned exercise's `libraryExerciseId` (same attribution path as `ExerciseProgressAggregator`), orders newest-first, takes `limit`.
  - `computeBadge({required List<WorkoutSet> currentPlannedSets, required String libraryExerciseId, required List<Session> sessions})` → `bool`. True iff, among ended sessions of the library entry whose snapshot planned sets equal `currentPlannedSets` (by planned value — weight + target, set-for-set, same count), **the most recent one capped**.
  - **Shared cap predicate.** Per working set, `actual ≥ ceiling`, where ceiling = `RepTargetFixed.reps` / `RepTargetRange.maxReps` (rep-based + bodyweight) or planned `durationSeconds` (time-based). A session caps iff **every** working set passes. Vary-by-set is judged per set against each set's own ceiling (no special-casing).

### Persistence

None. Reuses `SessionRepository.listCompletedSessions()`. **No schema-version change, no migration.**

### UI — exercise editor (`program_management/bloc/exercise_editor`, `screens/exercise_editor_screen.dart`)

- `ExerciseEditorBloc` gains a `SessionRepository` dependency (a **domain contract** — satisfies the UI-layer import rule), loads completed sessions, runs `computeHistory`, and exposes the resulting `CapHistory` plus the empty / unlinked-nudge / warmup states in `ExerciseEditorState`.
- The screen renders a "Recent history" section: ≤5 rows (absolute date, weight, planned target, per-set actuals, `▲` cap marker), an empty state, an unlinked nudge, and nothing for warmup-group exercises. Standard 48 dp targets (this is not a sweaty-hands surface). Theme tokens only.

### UI — workout-day editor (`program_management/bloc/workout_day_editor`, `screens/workout_day_editor_screen.dart`)

- `WorkoutDayEditorBloc` gains a `SessionRepository` dependency, loads completed sessions, computes `computeBadge` per exercise in the day — excluding warmup-group exercises (`warmupExerciseIdsIn`) and unlinked exercises — and exposes the badged exercise ids in state.
- The screen renders a token-based "needs attention" badge chip on each flagged exercise row (tap target ≥ 48 dp). Purely visual — **no tap action in v1**.

### Constraints

- `domain` stays pure Dart; aggregator exported via the `domain` barrel. UI accesses data only through `SessionRepository`; no Drift / `AppDatabase` / networking imports. Cross-module imports via barrels using `package:zamaj/...`.
- Copy is **descriptive only** — no imperative / recommendation language (no-coaching non-goal).
- Read-only derivation, recomputed live: a deleted session simply stops appearing (same property `ExerciseProgressAggregator` relies on).
- Performance: `listCompletedSessions()` loads all completed sessions; aggregation is O(sessions × exercises × sets), acceptable at single-user scale. A targeted repo query is a deferred optimization, not v1.
- Tests: domain aggregator + cap predicate fully unit-tested (project test scope: domain + persistence + module unit tests; no widget tests, no `bloc_test` package).

### Out of scope (deferred by decision)

- **Dismiss / hold suppression** of the badge → follow-up PR. v1 badge is always-on and cannot be silenced (accepted consequence: a deliberately-held rehab lift badges persistently).
- **Per-set warmup sets** — no per-set warmup axis exists today; when added, the cap predicate must consume the same warmup-set filter (extension point already noted in `nonWarmupCountsIn`).
- **Tap-a-row to open the session review**; **expand beyond 5 sessions**.

## Acceptance Criteria

### Cap predicate
- **AC1** — Rep-range target (e.g. 10–12): capped iff every working set's reps ≥ 12. `12·12·12` caps; `12·12·11` does not.
- **AC2** — Fixed rep target (e.g. 12): capped iff every working set's reps ≥ 12.
- **AC3** — Time-based target: capped iff every working set's duration ≥ the planned seconds.
- **AC4** — Reps/duration that exceed the ceiling still count as capped.
- **AC5** — Bodyweight targets use the same rep-ceiling rule as rep-based.
- **AC6** — Vary-by-set / descending (drop set) plans are judged per set against each set's own ceiling — no special-casing (so a descending drop set generally does not cap).

### History table (exercise editor)
- **AC7** — Shows up to the 5 most recent ended sessions of the movement (matched by `libraryExerciseId`), newest first.
- **AC8** — Aggregates across every program the movement appears in.
- **AC9** — Each row shows absolute date, weight, planned target, and per-set actuals; a capped session shows the `▲` marker (`top of range` / `hit target` / `hit time`).
- **AC10** — A linked exercise with no ended sessions shows the "No history yet" empty state.
- **AC11** — An unlinked exercise shows the "link to a library entry to see history" nudge and no rows.
- **AC12** — A warmup-group exercise shows no history section and no cap markers.

### Attention badge (workout-day editor)
- **AC13** — An exercise is badged iff, among ended sessions of its library entry whose snapshot planned sets equal the exercise's current planned sets (weight + target, set-for-set, same count), the most recent one capped.
- **AC14** — The badge fires after a single capped session.
- **AC15** — The badge clears when the plan advances — target tightened (10–12 → 12), weight increased, or any change making current planned sets ≠ the capped session's — because no matching capped session remains.
- **AC16** — A warmup-group exercise is never badged.
- **AC17** — An unlinked exercise is never badged.
- **AC18** — Each program/day badges against its own weight + target; the same movement done at a different load in another program does not cross-trigger.

### Non-functional / constraints
- **AC19** — No schema-version change and no migration are introduced.
- **AC20** — No networking or Drift / `AppDatabase` imports in `domain` or UI; UI accesses session data only via `SessionRepository`.
- **AC21** — All new UI uses theme tokens (no hard-coded px / color literals); badge tap target ≥ 48 dp.
- **AC22** — All copy is descriptive; no recommendation / imperative text.
- **AC23** — The domain aggregator and cap predicate have unit tests covering the derivation logic behind AC1–AC18.
- **AC24** — `product-context.md` is updated to reflect the new capability on the exercise-editor and workout-day-editor screens.

## Consistency Gate
- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts
- [x] No contradictions between artifacts
