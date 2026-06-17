# Spec: Repair Snapshot Library Links (one-shot)

> **Temporary maintenance feature.** This is a throwaway, single-use repair action the
> maintainer runs once on their own device, then removes. It deliberately violates the
> "completed sessions never change retroactively" invariant in a narrow, documented way
> (it rewrites only the `libraryExerciseId` of exercises frozen inside historical session
> snapshots). It is **not** a permanent product feature and is intentionally **not** added
> to `product-context.md`. All code added for it must be marked
> `// TEMP: snapshot link repair — remove after one-time run` so removal is a clean revert.

## Intent Description

A while ago the exercise library and all program→library links were cleared and rebuilt:
every program exercise was re-linked to a freshly-named canonical library entry. Two
later features — the **Recent history** section in the exercise editor and the
**Exercise progress (top-set trend)** screen — aggregate logged work *across programs* by
joining each historical session to a library entry through the `libraryExerciseId` that
was **frozen inside that session's snapshot** at the moment the session started. Sessions
recorded before the clear carry a stale value in their snapshot (either `null` or a
now-deleted library id), so they never match the current library entries and silently
drop out of history and the progress trend. The result: the maintainer can no longer see
their full lifting history.

This feature adds a temporary, maintainer-triggered action on the **workout-day picker**
screen for the program being viewed. When run, it walks every session of every workout
day in that program and, for each exercise frozen in the session's snapshot, rewrites that
exercise's `libraryExerciseId` to the value the **current** program template exercise now
carries. The matching/rewrite is computed first and shown as a **preview** (counts of what
would change, plus what cannot be matched); the maintainer confirms, and only then are the
snapshots written. The operation is idempotent — re-running it changes nothing further —
and after the maintainer runs it once on their device, the action and its supporting code
are deleted. No schema migration is introduced.

The success condition is observable: after running the repair, the maintainer's full
historical work for re-linked movements reappears in the exercise editor's Recent history
section and in the per-exercise progress trend.

## Architecture Specification

### Where the change fits

| Layer | Component | Change |
|---|---|---|
| `domain/services/` | **`SnapshotLinkBackfill`** (new, pure Dart) | Computes the repair plan and the rewritten snapshots from already-hydrated `WorkoutDay` templates + `Session`s. No I/O. Unit-testable. |
| `domain/repositories/` | **`SessionRepository`** (existing contract) | Add one temporary method to persist a rewritten snapshot for a session. Typed purely in domain terms. |
| `persistence/repositories/` | **`DriftSessionRepository`** | Implement the new method: serialize the rewritten `WorkoutDay` to canonical JSON, recompute the SHA-256, and write the `snapshotJson` + `snapshotHash` columns only. |
| `workout_day_picker/bloc/` | **`WorkoutDayPickerBloc`** | Add temporary events/states: request preview, confirm apply, dismiss. Orchestrates `ProgramRepository` (current templates) + `SessionRepository` (read sessions, persist rewrites) + `SnapshotLinkBackfill`. |
| `workout_day_picker/screens/` + `widgets/` | **`WorkoutDayPickerScreen`** | Add a temporary trigger (AppBar overflow menu item) + a preview/confirm dialog + a result summary. |

### Key data facts (verified)

- A session's frozen plan is stored as a **canonical-JSON blob** in `sessions.snapshotJson`
  with a content hash in `sessions.snapshotHash`. There is no structured snapshot table.
- The history aggregator
  ([`ExerciseCapHistoryAggregator`](../../mobile/lib/modules/domain/services/exercise_cap_history_aggregator.dart))
  and the progress aggregator
  ([`ExerciseProgressAggregator`](../../mobile/lib/modules/domain/services/exercise_progress_aggregator.dart))
  both attribute a session to a library entry **only** via
  `snapshot.workoutDay → group → exercise.libraryExerciseId`, matched to a
  `SessionExercise` by `plannedExerciseIdInSnapshot`. Both consider **ended sessions only**.
- Snapshot exercise IDs equal the live template exercise IDs at capture time, and program
  edits/re-links update exercises **in place** (`updateExercise` preserves the id). So for
  any exercise that still exists in the template, snapshot-exercise-id == template-exercise-id.
- On read, `SessionMapper._reconstructSnapshot` recomputes the hash and **throws
  `DeserializationError` on mismatch**, and the `SessionSnapshot` constructor re-validates
  `canonicalJson == CanonicalJson.encode(workoutDay.toJson())`. The rewrite therefore MUST
  persist `snapshotJson = CanonicalJson.encode(newWorkoutDay.toJson())` and
  `snapshotHash = CanonicalJson.sha256Hex(snapshotJson)` as a consistent pair.
- `snapshot.capturedAt` and `snapshot.schemaVersion` are derived on read from the session
  **row** (`createdAtMs`, `schemaVersion`), not from the blob. The rewrite leaves those
  columns — and all child rows (executed sets, notes, extra work) — **untouched**.

### Matching algorithm (decided: ID, then unambiguous name fallback)

Scope of matching is **within the same workout day**: each session's snapshot is matched
against the current template of the day identified by `session.workoutDayId`.

For each exercise in each group of a snapshot's `WorkoutDay`:
1. **By ID** — if the current day's template contains an exercise with the same `id`, that
   is the match.
2. **Name fallback** — else, normalize the snapshot exercise's name and look for current
   template exercises in the same day with a matching normalized name. Use it **only when
   exactly one** current exercise matches (unambiguous). 0 or ≥2 matches ⇒ no match.
3. **Apply rule** — if a match is found and its `libraryExerciseId` is **non-null** and
   differs from the snapshot's current value, set the snapshot exercise's `libraryExerciseId`
   to it. Otherwise leave the snapshot exercise unchanged (see edge cases E4–E5).

A session's snapshot is rewritten (and persisted) only if **at least one** exercise changed.

### Constraints

- **Layering:** the UI/bloc must reach data only through `ProgramRepository` /
  `SessionRepository` contracts — no Drift/`AppDatabase` in the UI module. The snapshot
  write therefore lives on the `SessionRepository` contract (marked temporary).
- **No migration, no schema bump:** `SchemaVersions` is untouched. The rewrite preserves
  every other field of the snapshot exactly (round-trips through `WorkoutDay.fromJson` /
  `toJson`); it must **not** stamp `SchemaVersions.domain` onto the rewritten snapshot.
- **Current program only:** the action operates on the program whose picker is open.
- **Ended sessions only:** in-flight (un-ended) sessions are not rewritten — history/progress
  ignore them, and any in-flight session was started after the re-link so already carries
  correct links.
- **Pure domain computation:** all matching/rewrite logic is pure and unit-testable;
  persistence is a thin write.
- **Idempotent:** running twice yields no changes on the second run.

### Edge cases

| # | Case | Behavior |
|---|---|---|
| E1 | Snapshot exercise id still in template | Copy current link (happy path). |
| E2 | Id gone, exactly one current exercise with same normalized name in the day | Copy current link (name fallback). |
| E3 | Id gone, 0 or ≥2 name matches | Leave unchanged; report as **unmatched**. |
| E4 | Matched current exercise is itself unlinked (`libraryExerciseId == null`) | Leave snapshot unchanged (never clear a link); report as **current-unlinked**. |
| E5 | Snapshot already has the current link | No-op (idempotency; e.g. post-relink sessions). |
| E6 | The session's workout day was deleted from the template | Cannot match; skip the whole session; report as **day-missing**. |
| E7 | In-flight (un-ended) session | Not rewritten. |
| E8 | Snapshot JSON fails to parse under current domain models | Skip that session; report as **unparseable**; never abort the batch. |
| E9 | Current link points to a library entry that no longer exists | Still copied as-is; the repair does not validate library-entry existence (out of scope). |
| E10 | Exercises inside superset groups | Handled identically (all groups iterated); group structure untouched. |
| E11 | `SessionExercise` in `replaced` state (dormant feature) | Only the planned snapshot `WorkoutDay` is rewritten — consistent with how the aggregators attribute (by planned snapshot exercise). Substitute payloads are untouched. |
| E12 | Program with no days / no sessions | Nothing to do; summary reports zero. |
| E13 | Re-run after a successful run | Zero further changes (E5 everywhere). |

## Acceptance Criteria

1. **Trigger present (temporary).** On the workout-day picker for a loaded program, a
   maintainer-visible action ("Repair history links") is available in the AppBar overflow
   menu. PASS: the action is reachable when the picker is in its loaded state. FAIL: no
   reachable trigger, or it appears on unrelated screens.
2. **Preview before write.** Activating the action computes a plan and presents a summary
   **without writing anything**: number of sessions scanned, number of exercises that would
   be re-linked, and the count of exercises that cannot be matched/linked (E3/E4) and
   sessions that will be skipped (E6/E8). PASS: a confirm/cancel surface shows these counts
   and no snapshot is modified until confirmed. FAIL: writes occur before confirmation, or
   counts are absent.
3. **Cancel is a no-op.** Cancelling the preview leaves every `sessions.snapshotJson` /
   `snapshotHash` byte-for-byte unchanged. PASS/FAIL on a stored-blob equality check.
4. **ID match rewrite.** For an ended session whose snapshot exercise id exists in the
   current template with a non-null `libraryExerciseId` differing from the snapshot value,
   after Apply the snapshot exercise's `libraryExerciseId` equals the current template value.
5. **Name-fallback rewrite.** For a snapshot exercise whose id is absent from the template
   but whose normalized name matches exactly one current exercise in the same day, after
   Apply its `libraryExerciseId` equals that exercise's current value. With 0 or ≥2 name
   matches, the snapshot exercise is unchanged and counted as unmatched.
6. **Never clears a link.** When the matched current exercise is unlinked, the snapshot
   exercise's existing `libraryExerciseId` is left exactly as-is (E4).
7. **Consistent persisted pair.** Every rewritten session row satisfies
   `snapshotHash == CanonicalJson.sha256Hex(snapshotJson)` and
   `snapshotJson == CanonicalJson.encode(WorkoutDay.fromJson(snapshotJson).toJson())`, so it
   re-hydrates through `SessionMapper` and the `SessionSnapshot` constructor **without
   throwing**. PASS: a hydrate of every rewritten session succeeds. FAIL: any
   `DeserializationError`/`ValidationError` on read.
8. **Snapshot identity preserved except the link.** For each rewritten session, the
   re-parsed `WorkoutDay` is identical to the original except for the targeted
   `libraryExerciseId` values: same day/group/exercise/set ids, names, positions,
   measurement types, planned values, and the same nested `schemaVersion`s. Session row
   timestamps, `schemaVersion`, and all child rows (executed sets, notes, extra work) are
   unchanged.
9. **History reappears (end-to-end).** Given an ended pre-relink session for a now-re-linked
   movement, before the repair the movement's Recent history / progress series excludes it;
   after Apply, `ExerciseCapHistoryAggregator.computeHistory` and
   `ExerciseProgressAggregator.compute` for the current library id include that session.
   PASS: aggregator output for the library id gains the previously-missing session.
10. **In-flight untouched (E7).** An un-ended session's snapshot is unchanged by the repair.
11. **Resilient batch (E6/E8).** A session whose day was deleted or whose snapshot fails to
    parse is skipped and reported; all other sessions in the program are still processed and
    the operation completes without throwing.
12. **Idempotent (E13).** Running the repair a second time produces zero rewrites (the result
    summary reports zero re-linked exercises).
13. **Result summary.** After Apply, a summary reports counts re-linked, sessions changed,
    and unmatched/skipped — so the maintainer can decide whether to link more exercises in
    the editor and re-run.
14. **Scoped to current program.** Only sessions belonging to the open program's workout days
    are read or written; other programs' sessions are untouched.
15. **No schema migration.** `SchemaVersions` and `migrations.dart` are unchanged; the build
    introduces no new Drift migration.

## Consistency Gate

- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts
- [x] No contradictions between artifacts

**Verdict: PASS.** Single coherent one-shot feature; ~5 components, all required by the
intent. The deliberate immutability exception is documented and bounded to
`libraryExerciseId`. The two open forks (matching strategy; preview-then-apply) are resolved.
Proceeding to `/plan`.
