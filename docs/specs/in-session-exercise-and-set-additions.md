# Spec: In-Session Exercise & Set Additions (and Replace)

> Status: spec approved (consistency gate passed). Behavior scenarios are authored per slice in `/plan`.

## Intent Description

A lifter mid-session frequently deviates from the frozen plan: the rack is taken so they swap a movement, they tack on a movement that isn't in today's day, or they grind out an extra set beyond what was planned. Today the live session is structurally closed — you can log, skip/end, reorder, and superset what the snapshot seeded, but you cannot introduce a movement the snapshot didn't contain, and there is no first-class way to record work beyond the planned set quota. This feature opens the live session to three structural additions while keeping the plan snapshot frozen:

1. **Add an exercise to an ongoing session.** The user picks a library movement (or enters a one-off) and it appears as a new, loggable exercise card appended to the session. Because it was never in the plan snapshot, an added exercise carries its own *inline planned data* (name, measurement type, planned set values, set count, and — when picked from the library — its library link and metadata). It is unplanned *actual* work, the structured cousin of free-text "extra work." The add flow refuses any library movement that is **already in the session in any state** — "do more of a movement that's already here" is served on its existing card (**Resume** if it was skipped or ended early, **Add set** if it was completed), not by a duplicate. (A movement the plan itself lists more than once still starts as its planned cards — the guard only blocks adding a *further* ad-hoc copy; re-doing acts on whichever existing card the user chooses. One-offs have no durable identity, so they're never deduped.)

2. **Add an extra set beyond plan.** On any exercise that has met its planned quota (or is still in progress), the user can explicitly log one more set. Extra sets are *actual* work logged on top of the plan; they never change the planned quota and never make a completed exercise read as anything but completed. The domain already permits logging past the quota — this surfaces it as a deliberate affordance.

3. **Replace an exercise.** Replace is no longer its own state machine. It is a composition of the two operations above: the original exercise is terminated (it ends as *partial* if some sets were logged, *skipped* if none — the existing single end/skip action), and a new exercise is added in its place via operation (1). There is no "Replaced" badge and no card-morphing; the user sees the original card finish in its terminal state and a fresh added-exercise card take its place. The previously dormant `ReplacedState` / `SubstituteExercise` domain concept is retired, because composition makes it redundant.

The animating principle is unchanged: **the frozen plan snapshot is never mutated.** Added exercises and extra sets are recorded as actual work alongside the snapshot, never folded into it. Planned-vs-actual stays first-class — an added exercise's "planned" side is the inline data the user supplied at add-time; everything beyond the planned quota reads as extra.

## Architecture Specification

### Components affected

| Layer | Component | Change |
|---|---|---|
| `domain/models` | `SessionExercise` | Carry optional **inline planned data** for added exercises (a movement with no entry in the snapshot). `plannedExerciseIdInSnapshot` becomes optional/ignored when inline data is present. |
| `domain/models` | New `AddedExercisePlan` (carrier) | Inline plan for an added exercise: `name`, `measurementType`, `plannedValues`, `setCount`, optional `libraryExerciseId`, optional `metadata`. Same shape as the retired `SubstituteExercise`; validation rules carry over (setCount ≥ 1, measurementType↔plannedValues match, libraryExerciseId is UUIDv4). |
| `domain/models` | `ExerciseState` | Remove the `replaced` union member and `SubstituteExercise`. (Read-only legacy compatibility for historical `replaced` rows is handled at the persistence layer — see Migration.) |
| `domain/services` | `EffectiveExercises` | When a session-exercise carries inline planned data, source measurement type / set count / display name / planned values from it instead of the snapshot; **do not** require a snapshot entry. Added exercises resolve `plannedGroupRole == main` (the only non-warmup role); deload halving is a start-time snapshot transform and never applies to mid-session additions. |
| `domain/services` | `SessionFlowEngine` | New `addExercise(...)` (inline plan + dedup guard). New `resumeExercise(...)` — reverts a `SkippedState` exercise (true-skip or ended-partial) back to `UnfinishedState`, retaining any logged sets, so a movement abandoned earlier continues on its own card. `replaceExercise(...)` repurposed to a **composed** op (terminate original via existing skip + add new) returning one fresh `SessionState`. Extra set reuses existing `completeSet` on a completed exercise — `completeSet` already permits this; the engine change is at most a thin convenience. Remove the old substitute-parameter `replaceExercise` signature and `ReplacedState` branches in `computeOpenTargets` / `isSessionComplete`. |
| `domain/services` | `exercise_outcome.dart` | Remove `ExerciseOutcome.replaced` and the `ReplacedState`-precedence branch. |
| `domain/repositories` | `SessionRepository` | Add `addExercise(...)` and `resumeExercise(...)`; change `replaceExercise(...)` to the composed contract (terminate original + insert added exercise in **one transaction**); drop the substitute parameters. |
| `persistence` | `tables.dart`, `migrations.dart`, `drift_session_repository.dart`, `session_mapper.dart` | Add a **new nullable `added_plan_json` column** carrying the inline added-exercise plan, read **unconditionally** (independent of the state discriminator). The legacy `substitutePayloadJson` keeps its state-gated read until the replaced machinery is retired. Added exercises store a synthetic UUIDv4 in `plannedExerciseIdInSnapshot` (satisfies the existing non-null/36-char/unique constraints; never resolved because `EffectiveExercises` branches on the inline plan first) — so no nullability migration. Append added exercises at `maxPosition + gap`. Bump `schema_versions.dart` and add a migration. |
| `core` | `schema_versions.dart` | Bump both Drift `schemaVersion` and the stamped `domain` version. |
| UI `workout_overview` | bloc, events, assembler, `exercise_card`, screen | Primary surface: "Add exercise" entry point (library picker + one-off); per-card "Add set" (on completed), "Resume" (on skipped/ended), and "Replace" actions. Remove dead `ReplacedState` render branches. Optimistic-mutation + transient-error handling reuses the existing `_runMutation` path. |
| UI `exercise_library` | picker | Reuse the existing library picker (as used by the workout-day editor) for the "add exercise" flow, with **every movement already in the session excluded** (dedup is any-state). |

### Key constraints & invariants

- **Snapshot immutability.** `SessionSnapshot` and its `sha256Hash` are never recomputed or changed by any operation here. Added exercises live as `SessionExercise` rows, not as snapshot entries.
- **No new networking / layer violations.** All new code respects `tool/check_offline_imports.sh`: domain stays pure Dart; UI talks only through `SessionFlowEngine` / repository contracts.
- **Every mutation round-trips the repo and returns a fresh `SessionState`** via the engine, per the existing `SessionFlowEngine` orchestration rule.
- **Replace is atomic at the repository layer.** Terminating the original and inserting the added exercise happen in a single Drift transaction so a half-applied replace can never be observed.
- **Dedup guard (any-state).** `addExercise` (and therefore the picker) rejects a movement whose `libraryExerciseId` matches **any** session exercise, regardless of state — including a movement the plan already seeded once *or more than once* (any match blocks the add). Re-doing a movement already present is handled on its existing card (Resume / Add set), never by a new ad-hoc copy. One-off exercises (no `libraryExerciseId`) are never deduped. The dedup resolves each session-exercise's `libraryExerciseId` through the inline-aware `EffectiveExercises` (so it reads an added exercise's id from its `addedPlan` and a snapshot-backed exercise's from its planned exercise, without crashing on the snapshot-less added rows). The guard is a domain-level check in `addExercise` (throws a `ValidationError`/`DomainError`); the picker filters proactively, so the error path is a defensive backstop for a race.
- **Resume is a small state revert.** `resumeExercise` flips a `SkippedState` exercise back to `UnfinishedState`, retaining its logged sets and its position/superset membership; no snapshot or plan change. It is the inverse of `skipExercise`.
- **Added exercises resolve `main` group role and are standalone** (`supersetTag == null`, their own single group). Existing superset operations can later group them; no new superset code is required.
- **Progress & export pass-through.** Added exercises with a `libraryExerciseId` flow into cross-session top-set progress aggregation like any logged work. Plain-text export and session review must render added exercises (inline planned + actual) and extra sets.

### Migration (legacy `replaced` rows)

Retiring `ReplacedState` means historical rows stored as `stateDiscriminator == 'replaced'` with a `substitutePayloadJson` must not crash on read. The risk is low in practice: the v6→v7 migration already **wiped all domain tables** (RepTarget rollout — single-install, no-compat-layer culture), so no `replaced` row predating v7 survives, and the Replace write path has been absent since. Sequencing keeps the risk contained: the inline-plan / add-exercise / composed-replace work lands first while `ReplacedState` stays dormant-but-readable; retirement is the **last** slice and is the only place the read path stops understanding the `replaced` discriminator. At that point a defensive Drift migration converts any residual `replaced` row into **(original → skipped) + (a new added exercise from the payload)** — realistically a no-op, but authored and tested. Validate via `test/integration/`.

### Out of scope

- Adding an exercise from `focus_mode` (focus is between-set; the add/replace structural surface is `workout_overview`). Logging an extra set may be surfaced in focus mode if cheap, but the committed surface is the overview.
- Editing an added exercise's inline plan after creation (beyond logging sets / end-skip / the normal in-session edits). Treat it like a snapshot exercise once created.
- Any change to how the program template or its snapshot capture works.

## Acceptance Criteria

### Add exercise
- **AC1** From the live overview the user can add a library-linked exercise; it appears as a new, loggable card appended after the existing exercises, in `UnfinishedState`, with planned set rows derived from the inline plan the user supplied.
- **AC2** From the live overview the user can add a one-off (no library link) exercise the same way; it is loggable and never blocked by the dedup guard.
- **AC3** Logging sets on an added exercise behaves identically to a planned exercise: it auto-completes at its inline planned quota and derives completed/partial/skipped from logged-vs-planned counts.
- **AC4 (dedup, pass/fail).** `addExercise` with a `libraryExerciseId` matching **any** session exercise — regardless of state (unfinished, completed, skipped, or ended) — is rejected with a domain error and produces no row; the picker excludes that movement. A one-off add (no `libraryExerciseId`) is always allowed.
- **AC4b (resume).** A skipped or ended-early exercise can be resumed back to `UnfinishedState`, retaining any logged sets, so the user continues the movement on its existing card instead of adding a duplicate. A completed exercise exposes **Add set** (AC6) rather than resume. Resume does not change the snapshot.
- **AC5** Adding an exercise does **not** change `session.snapshot.sha256Hash` (verified before/after).

### Add extra set
- **AC6** On an exercise that has met its planned quota (`completed`), the user can log one additional ("extra") set; the exercise remains read as **completed**, and the extra set appears as an additional logged row beyond the planned rows.
- **AC7** Extra sets never alter the planned quota or the snapshot, and are rendered in session review and plain-text export as logged work beyond plan.

### Replace
- **AC8** Replacing an exercise terminates the original via the existing end/skip action — it reads **partial** if it had logged sets, **skipped** if none — and adds a new exercise (AC1/AC2 flow) in one user action.
- **AC9** Replace is atomic: a failure in either half leaves the session unchanged (no terminated-without-replacement and no orphan added exercise).
- **AC10** The dedup guard (AC4) applies to the replacement movement, except the original being replaced is excluded from its own block-set (it is about to be terminated, so re-picking its own movement as the replacement is allowed).
- **AC11** No "Replaced" badge/outcome appears anywhere (live card, session review, history tile, export); the original simply reads partial/skipped.

### Retirement & regression
- **AC12** `ReplacedState`, `SubstituteExercise`, and `ExerciseOutcome.replaced` are removed from the domain; the project compiles, `tool/check_offline_imports.sh` passes, and `tool/ci.sh` is green.
- **AC13** Historical sessions that contained a `replaced` exercise still load and render without error (migration-handled), and completed sessions' recorded outcomes do not change retroactively in a way that misrepresents what was logged.
- **AC14** `schema_versions.dart` is bumped and a migration is present; `test/integration/` covers start → add exercise → add extra set → replace → end, plus the legacy-`replaced` migration path.

## Consistency Gate
- [x] Intent is unambiguous — two developers would interpret it the same way.
- [x] Every behavior/goal maps to an acceptance criterion (add → AC1–AC5; resume → AC4b; extra set → AC6–AC7; replace → AC8–AC11; retirement/migration → AC12–AC14).
- [x] Architecture constrains without over-engineering — reuses inline-plan carrier, existing skip/end op (resume is its inverse), existing append/superset machinery, and the engine round-trip rule; adds only what's needed.
- [x] Terminology consistent across artifacts — "added exercise", "inline planned data / AddedExercisePlan", "extra set", "replace = terminate + add", "any-state dedup", "resume".
- [x] No contradictions between artifacts — snapshot immutability and "no Replaced badge" hold across intent, architecture, and ACs.
