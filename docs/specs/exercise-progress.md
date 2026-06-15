# Spec: Exercise Progress (Top-Set Trend)

## Intent Description

Zamaj records planned-vs-actual for every set but never reflects that history back to the lifter. The app can't answer the central question of strength training — *"am I getting stronger on this lift?"* This feature adds a per-exercise **Progress view** that plots the **top set** (heaviest weighted set) logged for an exercise over time, aggregated across **every program** the exercise has appeared in.

It is reachable from two places: the **Library exercise editor** (program-agnostic, always has a library identity) and a **finished session's exercise cards** (in-context, right after logging). It reads only local data, computed live from session rows — so it stays correct when test sessions are deleted and needs no network.

v1 deliberately covers **weighted exercises only**; bodyweight and timed exercises show a clear "not supported yet" state rather than a misleading chart. **Cross-plan is the default** because strength progression spans program changes; an **optional per-program filter** lets the lifter narrow to one program to compare like-for-like rep contexts.

## Architecture Specification

**New UI feature module — `lib/modules/exercise_progress/`** (bloc + screen + widgets + view models), mirroring existing module structure. Talks to data only through the `SessionRepository` domain contract — no Drift, no `AppDatabase` (layer rule).

**New domain service — `ExerciseProgressAggregator`** (pure Dart, in `domain/`):
- Input: completed sessions for a `libraryExerciseId` (+ optional `programId` filter).
- For each session: decode `SessionSnapshot.workoutDay`, map `SessionExercise.plannedExerciseIdInSnapshot` → snapshot exercise → confirm it carries the target `libraryExerciseId` and is **weighted**; from its `ExecutedSet`s, pick the **top set** = max `weightKg` (tiebreak: higher reps).
- Output: ordered `List<ProgressPoint>` (`date`, `topSetWeightKg`, `reps`, `programId`).

**New domain models** (freezed, validated `._()` per conventions): `ProgressPoint`, `ExerciseProgressSeries`.

**New `SessionRepository` read method** — returns completed sessions containing a given `libraryExerciseId`. v1 implementation may scan snapshots Dart-side (acceptable for solo data volume); a denormalized index is a deferred optimization, **not** v1. **No schema-version bump, no migration.**

**New dependency** — `fl_chart` in `mobile/pubspec.yaml`. All chart config (colors, spacing, axis label typography) is wrapped to pull from `appColors` / `AppSpacing` / `AppTypography.standard.numeric` — no hard-coded pixels or color literals (token rule).

**Navigation** — add a route in `lib/navigation/` to `ExerciseProgressScreen(libraryExerciseId, [programId])`; wire entry actions from the Library exercise editor and the session-detail exercise card (`export/` module).

**Docs** — add the Exercise Progress screen to `product-context.md` (new user-facing screen).

## Acceptance Criteria

1. **Top-set trend, cross-plan:** For a weighted exercise with ≥2 completed sessions across any programs, the screen shows a line chart of top-set weight (kg) over time, one point per session, chronologically ordered, including sessions from different programs.
2. **Top-set definition:** Each point is the session's heaviest `weightKg` set for that exercise; ties broken by higher reps. The point shows weight × reps and the session date.
3. **Per-program filter:** A control lets the user narrow the series to a single program; clearing it returns to all-programs. Default state is all-programs.
4. **Weighted-only:** A non-weighted exercise (bodyweight-reps or timed) shows a "Progress charts support weighted exercises only" empty state, no chart.
5. **Unlinked exercise (session-review entry):** Tapping an exercise that has no `libraryExerciseId` shows a "not linked to your library — can't track across sessions" empty state. (Not reachable from the Library editor, where identity always exists.)
6. **Sparse data:** 0 sessions → "no sessions logged yet" state. Exactly 1 session → the top-set value shown as a single labeled stat with a "keep training to see your trend" hint, no trend line.
7. **Live consistency:** Deleting a session removes its point from the trend on next load (no stale cache / no precomputed aggregate).
8. **Entry points:** Reachable from the Library exercise editor and from a finished session's exercise card; both route to the same view for that library exercise.
9. **Token/layout compliance:** No hard-coded pixels or color literals; numeric readouts use `AppTypography` numeric styles; passes `tool/check_offline_imports.sh` (UI module imports no Drift).
10. **Tests:** Domain aggregator covered by unit tests (cross-plan aggregation, top-set tiebreak, weighted filter, empty/single-point, program filter); repository read method covered by a persistence test.
11. **Docs:** `product-context.md` lists the new screen.

## Consistency Gate

- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering (no schema bump, scan-based read for v1)
- [x] Terminology consistent across artifacts (*library exercise*, *top set*, *progress point*, *weighted*, *cross-plan*)
- [x] No contradictions between artifacts

**Verdict: PASS**
