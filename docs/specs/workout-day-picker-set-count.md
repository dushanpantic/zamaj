# Spec: Non-warmup set count on workout day picker

## Intent Description

Each tile on the workout-day picker currently shows a muted caption with the
count of non-warmup exercises (e.g. `5 exercises`). When planning a session, a
user also wants to gauge the day's *volume* at a glance — how many sets it
involves — without opening the day.

This adds the total planned set count across those same non-warmup exercises to
the existing caption, rendered as `5 exercises · 18 sets`. It is a read-only
display change on the program template (the picker shows the plan, not a live
session). It computes and shows a number that already exists in the data —
nothing more.

## Architecture Specification

- **Component touched:** `mobile/lib/modules/workout_day_picker/widgets/day_tile.dart`
  (the inline count at lines 48–53 and the caption `Text`).
- **Counting logic:** extract to a pure domain helper alongside
  `mobile/lib/modules/domain/services/warmup_exercises.dart`, the existing
  single source of truth for warmup exclusion. Both the exercise count and the
  new set count derive from one "non-warmup group" filter so they always count
  over the **same** set of exercises.
- **Definition of "set":** a `WorkoutSet` in `exercise.sets`. There is no
  warmup-set axis today (warmup is a group-level role), so the non-warmup set
  count = sum of `exercise.sets.length` over exercises in non-warmup groups.
- **Constraints:**
  - UI-token rules apply — the caption stays a single muted `typography.caption`
    line on `onSurfaceMuted`; no new colors or hard-coded pixels.
  - Domain helper is pure Dart, unit-tested under `test/domain/services/`.
  - No persistence, schema, migration, or repository changes.
  - Display tweak to an existing screen, not a new screen/feature — no
    `product-context.md` edit required.
- **Naming:** "non-warmup exercises" and "non-warmup sets" used consistently.

## Acceptance Criteria

1. Each loaded day tile's caption reads `<N> exercises · <M> sets`, where `N` is
   the non-warmup exercise count (unchanged from today) and `M` is the total
   planned sets across those non-warmup exercises.
2. Pluralization mirrors the existing pattern: `1 exercise` / `N exercises`, and
   `1 set` / `M sets`.
3. Warmup-group exercises and their sets are excluded from both `N` and `M`.
4. A day with no non-warmup exercises reads `0 exercises · 0 sets`.
5. The two counts always range over the identical set of exercises (no
   divergence between numerator populations).
6. Tile loading / error / in-progress states, layout, and tap behavior are
   unchanged; only the caption text gains the ` · <M> sets` suffix.
7. The set-count helper is covered by domain unit tests (warmup excluded,
   superset multi-exercise summed, zero case).

## Consistency Gate
- [x] Intent is unambiguous
- [x] Every behavior/goal maps to an acceptance criterion
- [x] Architecture constrains without over-engineering
- [x] Terminology consistent across artifacts
- [x] No contradictions between artifacts
