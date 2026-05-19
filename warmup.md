# Warmup exercises — design plan

## Problem

While using the app in the gym, you noticed that the first ~4 exercises of a
plan are warmups and there is no way to distinguish them from main work. You
want a way to mark these so the UI treats them differently (visually grouped,
mentally separable from the "real" sets).

## Goal

Add a first-class concept of **warmup** to a planned exercise so the program
editor, workout overview and focus mode can render it distinctly, without
breaking the snapshot/immutability rules already in place.

---

## Design analysis

The choice has two axes: **where to attach the marker**, and **what shape it
takes**.

### Axis 1 — where to attach it

| Option | Pros | Cons |
|---|---|---|
| **A. Flag on `Exercise`** | Fine-grained: any exercise can be a warmup, even mid-workout. Minimal model change. | Most warmups span a contiguous run of exercises — per-exercise flag duplicates the same value 4× and lets users create logically nonsensical states ("warmup-main-warmup-main"). |
| **B. Flag/role on `ExerciseGroup`** (recommended) | Matches the granularity of `ExerciseGroupKind` (Single/Superset). A warmup superset Just Works — both exercises in the group inherit the role. UI already groups by group. | Slightly coarser; a warmup that is part of a Superset must be the whole superset. In practice this is what users want. |
| **C. New `Section` entity between `WorkoutDay` and `ExerciseGroup`** | Most normalized: `Warmup` / `Main` / `Cooldown` become explicit containers with their own ordering. Easiest place to hang section-level UX later (collapse all, skip-warmup button, headers). | Big refactor: new table, new domain model, snapshot shape changes, migration touches every program. Overkill for the current ask. |
| **D. Extend `ExerciseGroupKind` sealed union with `WarmupKind`** | Reuses an existing extension point. | Conflates two orthogonal concerns: *structure* (single vs superset) and *role* (warmup vs main). A warmup superset would be impossible to express. |

**Recommendation: Option B — attach a role to `ExerciseGroup`.**

It is the smallest change that captures all real use cases (single warmup,
warmup superset, cooldown in the future) and matches how the UI already
chunks the day. Option C is the right shape long-term but is not justified
by the current ask; if section-level affordances pile up later, we can
promote the role to a Section entity behind the same domain types with a
straightforward migration.

### Axis 2 — shape of the marker

A `bool isWarmup` says exactly what you asked for, but the same UI work
will recur the first time you want a "cooldown" or "activation" section.
For one extra enum value of cost, an open-ended role gives us room.

```dart
enum ExerciseGroupRole { warmup, main /*, cooldown, activation — future */ }
```

Stored as a string discriminator (`'warmup'` / `'main'`) on the Drift row —
consistent with the existing `kindDiscriminator` pattern.

**Default value: `main`.** Existing data migrates to `main`; users opt
groups into `warmup`.

---

## Concrete changes

File paths below are repo-relative under `mobile/`.

### 1. Domain model

- **New file** `lib/modules/domain/models/exercise_group_role.dart`
  - Plain Dart enum `ExerciseGroupRole { warmup, main }` with a stable
    `name` used by canonical JSON.
- **Edit** `lib/modules/domain/models/exercise_group.dart`
  - Add `required ExerciseGroupRole role` to the factory.
  - No new invariants (any role allowed regardless of `kind`).
- **Edit** `lib/modules/domain/domain.dart` (barrel) — export the new enum.

Note on Freezed convention (per CLAUDE.md): the existing `._()` /
non-`const` factory pattern is preserved; the new field is just another
`required` parameter.

### 2. Persistence

- **Edit** `lib/modules/persistence/database/tables.dart`
  - Add to `ExerciseGroups`:
    `TextColumn get roleDiscriminator => text().withDefault(const Constant('main'))();`
  - The default lets the migration ALTER without backfilling per row.
- **Edit** `lib/modules/persistence/database/migrations.dart`
  - New branch `if (from < 9) { await m.addColumn(db.exerciseGroups, db.exerciseGroups.roleDiscriminator); }`
- **Edit** the ExerciseGroup repo impl (`lib/modules/persistence/repositories/...`)
  to map the column ↔ enum. Mirror the existing
  `kindDiscriminator`/`kindPayloadJson` pair, but a single discriminator
  column is enough since there's no payload.

### 3. Schema versions

- **Edit** `lib/core/schema_versions.dart`:
  - `drift: 8 → 9`
  - `domain: 6 → 7`

Bump both deliberately, per the rule in CLAUDE.md. The domain bump is
load-bearing because the JSON shape of every `ExerciseGroup` row changes.

### 4. Snapshot & canonical JSON

- The snapshot embeds the full planned tree, so it automatically picks up
  `role` on every group once the field is added — no separate change.
- `lib/core/canonical_json.dart` sorts keys alphabetically, so adding
  `role` to `ExerciseGroup` only changes the byte output for groups that
  exist; we must:
  - **Regenerate JSON goldens**: `dart run tool/generate_aggregate_goldens.dart`.
  - Add a serialization round-trip test for `ExerciseGroup` with each
    role value under `test/serialization/`.

### 5. UI — program editor

`lib/modules/program_management/screens/workout_day_editor_screen.dart`
(and the exercise-group editor surface):

- Add a role toggle on the group editor (segmented control or chip:
  "Warmup" / "Main"). 48 dp tap target (`AppSpacing.touchMin`).
- Group cards in the day editor: show a small "WARMUP" badge when
  `role == warmup`, using the new semantic color (below).

### 6. UI — workout overview

`lib/modules/workout_overview/widgets/exercise_card.dart`:

- Visually de-emphasize warmup cards: muted surface tone, "WARMUP" label,
  reduced typography weight on numerics.
- Optional but recommended: insert a divider/header between the last
  warmup group and the first main group ("Main work" subtitle). Header
  is purely presentational, computed from the group list — does not
  require a new domain entity.

### 7. UI — focus mode

`lib/modules/focus_mode/screens/focus_mode_screen.dart` and
`lib/modules/focus_mode/widgets/focus_up_next.dart`:

- Add a "Warmup" pill at the top of the focused panel when current group
  is a warmup.
- Progress counter: split into "Warmup 2/4" vs "Main 1/5" rather than a
  single "3/9".
- Up-next preview: show role label next to each upcoming exercise.

### 8. Tokens / theming

Per the convention in CLAUDE.md (semantic colors live in `AppColors`,
both palettes):

- **Edit** `lib/core/app_theme.dart` (or wherever `AppColors` lives) to
  add `warmup` (foreground) and optionally `warmupBg`. Add to both
  `dark` and `light` palettes.
- Name the token `warmup`, **not** `exerciseGroupWarmup` — the same
  token will be reused at the set level when warmup sets land (see
  "Forward compatibility" below).
- No new spacing/radius tokens needed.

### 9. Session layer — what does NOT change

- `SessionExercise` does **not** get a `role` field. The role is part of
  the planned tree, captured in the snapshot, and reachable from
  `plannedExerciseIdInSnapshot`. Duplicating it on the session row
  would invite drift.
- Session-flow rules (skip, complete, replace) stay identical for
  warmup groups. The engine treats role as a presentation hint.

---

## Tests

Scope per CLAUDE.md: domain + persistence only.

- `test/domain/models/exercise_group_test.dart` — construct with each role,
  validation does not regress.
- `test/serialization/exercise_group_role_test.dart` — fromJson/toJson
  round-trip for each role + missing-field deserialization (defaults to
  `main`) for forward-compat reading of legacy snapshots.
- `test/serialization/golden/` — regenerate aggregate goldens.
- `test/persistence/exercise_group_repository_test.dart` — column ↔ enum
  mapping; default `'main'` reads correctly.
- `test/integration/migration_v8_to_v9_test.dart` — open a v8 DB, run
  migration, assert every existing group has `role = main`.

---

## Forward compatibility — warmup *sets* (future feature)

A separate, future need: **warmup sets within a single exercise** (e.g.,
bench press at 60% × 5 before working sets at 85% × 5). That is a
different axis from this plan:

| Concept | Granularity | Lives on |
|---|---|---|
| Warmup exercise/group (this plan) | Whole exercise(s) | `ExerciseGroup.role` |
| Warmup sets (future) | Sets within one exercise | `WorkoutSet.role` (new) |

The two concepts are orthogonal. Adding warmup sets later will not require
revisiting any of the v9 work above. Three forward-compat decisions to
honor *now* so the future fits cleanly:

1. **Reusable color token.** Name the new semantic color `warmup` (not
   `exerciseGroupWarmup`). Same chip / tint will mark warmup sets at the
   row level inside an exercise card.
2. **Single "is warmup?" predicate.** Define one helper somewhere in
   `domain/` (e.g., `isWarmupContext({group, set})`) that returns true
   if **either** the group role is `warmup` **or** the set role is
   `warmup`. Stats, PR detection and export must call this — not
   reimplement the OR-rule per call site.
3. **UI suppression rule.** When the group is `warmup`, do **not**
   render per-set warmup chips — every set in a warmup group is
   implicitly a warmup ramp. Prevents double-labelling and disallows
   nonsensical "working set inside warmup group" displays.

Sketch of the v10 change (informational, not in scope here):

- `WorkoutSet` gains `role: WorkoutSetRole { warmup, working }`, default
  `working`.
- New Drift column `workout_sets.role_discriminator` with default
  `'working'`. Migration is a single `addColumn`.
- Schema bumps: drift 9→10, domain 7→8.
- Reuses the `warmup` color token from this plan.
- Open question for the v10 design: do warmup sets store an explicit
  planned weight (60 kg) or a percentage of the working set (60%)?
  That's a measurement-type concern, independent of the role marker.

---

## Migration of your existing plan

Once shipped, your existing plan's groups will all be `main`. You open the
program editor, toggle the first 4 groups to `warmup`, done. No data is
lost; nothing destructive.

If you want, we can also seed the toggle from an env-time script that flips
the first N groups of a specific program — but the in-app toggle is
probably faster than wiring that.

---

## Open questions (decide before implementing)

1. **Group-level vs exercise-level.** This plan assumes group-level. If
   any of your warmups today are part of a Superset, this is correct. If
   you ever want a *single exercise inside a superset* to be a warmup
   while its partner is main, we'd need to move to exercise-level. Worth
   confirming.
2. **Cooldown now or later.** Adding `cooldown` to the enum at the same
   time is free if you want it; otherwise we ship `warmup` and `main` and
   add `cooldown` when needed (no migration required to add an enum case
   later — the column is just text).
3. **Stats / PR detection.** If/when stats land, warmup sets must be
   excluded from PR computation. Not in scope here, but flag it as a
   known follow-up so the role is consumed correctly downstream.
4. **Reorder rule.** Should the editor enforce that warmup groups come
   before main groups (sort by `(role, position)`), or allow arbitrary
   interleaving? Soft enforcement (warning, not error) is the friendly
   default.

---

## Effort estimate

- Domain + persistence + migration + schema bump: ~half a day.
- UI in three surfaces (editor, overview, focus): ~half to a full day,
  most of it in token-correct visual treatment.
- Tests + golden regen: ~2 hours.

Total: 1–2 focused sessions.
