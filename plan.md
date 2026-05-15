# Feature 1 — Substitute exercise carries its own planned values

## Goal

When the user replaces an exercise mid-session, the substitute should carry its
**own** planned weight/reps (or duration) and set count, instead of inheriting
them from the original snapshot exercise. This fixes the "shoulder press 15 kg
→ nordic shoulder, but the app pre-fills 15 kg" problem.

Out of scope: mid-set replacement (Feature 2). The substitute is still created
only when the original is `Unfinished`. Feature 2 will build on top of the data
model introduced here.

## Design decisions

1. **Single planned-set template, not per-set values.** A substitute carries
   one `PlannedSetValues` plus a `setCount`. All sets of the substitute share
   that template. Reasoning: substitutes are almost always a different load
   pattern from the original, so inheriting pyramid variation makes no sense;
   and asking the user to type values per set in a mid-workout dialog is hostile
   UX. The user can still adjust each actual set as they go.

2. **`setCount` is required, not an override-of-original.** When the dialog
   opens, default it to the original's set count and let the user change it. We
   never need to "fall back to original" at read time — the substitute payload
   is self-contained. This keeps the engine free of conditional snapshot lookups
   for replaced exercises.

3. **Reuse `PlannedSetValues`** for the substitute's template values. Same
   union, same validation, same JSON shape — no new model needed.

4. **Schema bump: both Drift and domain.** No table shape changes, but the JSON
   contents of `substitute_payload_json` change. Bump `SchemaVersions.drift`
   (4 → 5) so a migration can rewrite legacy rows, and bump
   `SchemaVersions.domain` (2 → 3) for the row stamp.

5. **Migrate legacy rows in place.** For every existing `replaced` session
   exercise, parse the v2 payload, fill in `plannedValues` from the original
   snapshot exercise's first set, and `setCount` from the snapshot exercise's
   set count. Write the v3 payload back. After this, the engine never branches
   on payload version.

## Data model changes

### `lib/modules/domain/models/substitute_exercise.dart`

```dart
@freezed
abstract class SubstituteExercise with _$SubstituteExercise {
  SubstituteExercise._() {
    if (setCount < 1) {
      throw ValidationError(
        entityId: name,
        invariant: 'setCount_positive',
        message: 'setCount must be >= 1, got $setCount',
      );
    }
    // Cross-field invariant: measurementType matches plannedValues variant.
    final mismatch = switch ((measurementType, plannedValues)) {
      (RepBasedMeasurement(), PlannedRepBased()) => false,
      (TimeBasedMeasurement(), PlannedTimeBased()) => false,
      _ => true,
    };
    if (mismatch) {
      throw ValidationError(
        entityId: name,
        invariant: 'measurementType_plannedValues_mismatch',
        message: 'measurementType does not match plannedValues variant',
      );
    }
  }

  factory SubstituteExercise({
    required String name,
    required MeasurementType measurementType,
    required PlannedSetValues plannedValues,
    required int setCount,
    ExerciseMetadata? metadata,
  }) = _SubstituteExercise;

  factory SubstituteExercise.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(
        () => _$SubstituteExerciseFromJson(json),
        json,
        'SubstituteExercise',
      );
}
```

Follows the freezed pattern from CLAUDE.md (`._()` constructor with body +
non-`const` factory).

### `lib/core/schema_versions.dart`

```dart
static const int drift = 5;
static const int domain = 3;
```

## Engine changes

### `lib/modules/domain/services/session_flow_engine.dart`

- **`replaceExercise`** — extend signature:
  ```dart
  Future<SessionState> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    required PlannedSetValues substitutePlannedValues,
    required int substituteSetCount,
    ExerciseMetadata? substituteMetadata,
  })
  ```
  Validation: `substituteSetCount >= 1`; `substitutePlannedValues` variant
  matches `substituteMeasurementType`. (The same invariants live on
  `SubstituteExercise`, so the engine just constructs one and lets the
  constructor throw `ValidationError`.)

- **`_lookupPlannedSetCount`** — branch on state:
  ```dart
  int _lookupPlannedSetCount(SessionExercise se, Session session) =>
      switch (se.state) {
        ReplacedState(:final substitute) => substitute.setCount,
        _ => _lookupPlannedExercise(se, session).sets.length,
      };
  ```

- **`_lookupPlannedSet`** — for `ReplacedState`, synthesize a `WorkoutSet`
  from the substitute's template (or, simpler, inline a helper that returns
  the `PlannedSetValues` directly — callers only consume `.plannedValues`).
  Cleanest refactor: replace the `_lookupPlannedSet(...).plannedValues` call
  in `suggestValues` with a new `_lookupPlannedValuesAtPosition(se, session,
  position: 0)` that handles both branches.

- **`suggestValues`** — the special case for "replaced + different
  measurement type returns zeros" goes away. For `setIndex == 0` it now
  returns `_convertPlannedToActual(substitute.plannedValues)` directly. For
  `setIndex > 0` keep the existing "last executed set" behaviour.

## Repository contract

### `lib/modules/domain/repositories/session_repository.dart`

Update `replaceExercise` to accept the same extended parameters as the engine.

### `lib/modules/persistence/repositories/drift_session_repository.dart`

In `replaceExercise`, construct the `SubstituteExercise` with the new fields
before serialising to `substitutePayloadJson`. No other persistence logic
changes — the canonical-JSON encoder already handles the larger payload.

## Persistence migration

### `lib/modules/persistence/database/migrations.dart`

Add `if (from < 5)` block:

1. Select every `session_exercises` row with `state_discriminator = 'replaced'`
   and a non-null `substitute_payload_json`.
2. For each row:
   - Decode the existing payload (`name`, `measurementType`, `metadata?`).
   - Locate the originating snapshot exercise. The snapshot JSON lives on the
     `sessions` row; resolve via `session_id` then walk `snapshot.workoutDay.
     exerciseGroups[*].exercises` to find the one whose `id` matches the
     session exercise's `plannedExerciseIdInSnapshot`.
   - Fill `plannedValues` from the original's first planned set (position 0).
   - Fill `setCount` from the original's `sets.length`.
   - Re-encode via `CanonicalJson.encode(...)` and write back.
3. Stamp `domainVersion = 3` on each rewritten row (and bump the session row's
   `updatedAtMs` via the existing timestamp service — or skip, since this is
   a structural migration not a user mutation; clarify in tests).

The migration must be deterministic and idempotent (re-running it against an
already-v3 row is a no-op — detect by presence of `plannedValues` key).

## UI changes

### `lib/modules/workout_overview/widgets/replace_exercise_dialog.dart`

Extend the dialog to collect the new fields. Use tokens per CLAUDE.md
(`AppSpacing`, `appColors`, no hard-coded colors/pixels).

- New props on the widget:
  - `MeasurementType defaultMeasurementType` (existing)
  - `PlannedSetValues defaultPlannedValues` (new — initial dialog values)
  - `int defaultSetCount` (new)
- Form fields, switched on the currently selected measurement type:
  - **Rep-based**: weight (kg, 0.5 step), reps, sets.
  - **Time-based**: duration (seconds), sets.
- When the user toggles the segmented `Reps ↔ Time` control, swap the field
  set and reset the planned values to a sensible default (0 kg / 0 reps or
  0 s). Do **not** silently carry over values across types.
- Return type becomes:
  ```dart
  class ReplaceExerciseResult {
    final String name;
    final MeasurementType measurementType;
    final PlannedSetValues plannedValues;
    final int setCount;
    final ExerciseMetadata? metadata;
  }
  ```
- Use `AppTypography.standard.numeric` for the numeric inputs / readouts.
- Disable the `Replace` button unless: name non-empty AND `setCount >= 1` AND
  numeric fields parse (`weight >= 0` half-kg, `reps >= 0`, `duration >= 0`).

### Dialog call sites

- [workout_overview_screen.dart:63](mobile/lib/modules/workout_overview/screens/workout_overview_screen.dart#L63) and
  [focus_mode_screen.dart:427](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart#L427)
  both invoke `ReplaceExerciseDialog.show`. Each must compute and pass the
  original exercise's first `PlannedSetValues` and `sets.length` so the
  dialog can pre-fill defaults. The source is the session snapshot, already
  available via the bloc state.

### Events / blocs

- [workout_overview_event.dart](mobile/lib/modules/workout_overview/bloc/workout_overview_event.dart):
  add `plannedValues` and `setCount` to `WorkoutOverviewExerciseReplaced`.
- [workout_overview_bloc.dart `_onExerciseReplaced`](mobile/lib/modules/workout_overview/bloc/workout_overview_bloc.dart#L184):
  forward the new fields to the engine.
- Same two changes for [focus_mode_event.dart](mobile/lib/modules/focus_mode/bloc/focus_mode_event.dart)
  and [focus_mode_bloc.dart](mobile/lib/modules/focus_mode/bloc/focus_mode_bloc.dart).

## Tests

Add or update:

- **`test/domain/models/`** — validation tests for the new
  `SubstituteExercise` invariants (`setCount >= 1`, measurement/planned-values
  match).
- **`test/serialization/`** — JSON round-trip for the new shape; refresh
  goldens via `dart run tool/generate_aggregate_goldens.dart`.
- **`test/domain/services/session_flow_engine_test.dart`** — replace a
  rep-based exercise with a time-based substitute (and vice versa), assert
  `suggestValues` returns the substitute's planned values for set 0, and
  inherits last actuals from set 1 onward.
- **`test/domain/services/session_flow_engine_test.dart`** — replace with a
  different `setCount` (e.g. original=4, substitute=2). Assert cursor
  advances past the substitute after 2 sets, and `isSessionComplete` is true.
- **`test/domain/replacement_invariant_test.dart`** — extend to cover the new
  payload fields under property generation.
- **`test/repository/`** — migration test: seed a v4 db with a `replaced`
  row using the legacy payload, run the migrator, assert the row's payload
  is upgraded and the row is still queryable. Also assert idempotency on
  re-run.
- **`test/support/generators.dart`** — extend the substitute generator to
  produce `plannedValues` + `setCount`.

Property tests that already exercise replacement
(`session_flow_engine_immutability_property_test`,
`session_flow_engine_ordering_property_test`,
`replacement_no_template_mutation_test`) must keep passing once generators
are updated — no semantic change to their invariants.

## Execution order

1. Bump `SchemaVersions` and extend `SubstituteExercise`. Run codegen:
   `dart run build_runner build --force-jit`.
2. Update engine + repository contract + drift repo.
3. Write the drift migration; add a migration test.
4. Update events + blocs.
5. Update the dialog and both call sites.
6. Run `tool/ci.sh` (imports → codegen → format → analyze → test).
7. Regenerate goldens: `dart run tool/generate_aggregate_goldens.dart`.
8. Manual smoke: start a session, replace a rep-based exercise with a
   time-based substitute, complete one set, replace a rep-based with another
   rep-based using a different weight, complete one set, end session.

## Risk notes

- The migration walks the `snapshot` JSON to backfill defaults. If any
  legacy `replaced` row's `plannedExerciseIdInSnapshot` cannot be resolved
  (corrupt data), fail the migration loudly rather than silently writing
  zeros — surface in logs, surface a `ValidationError` at startup. Better
  to crash than to silently lie about planned values.
- This change is the foundation for Feature 2 (mid-set replace), which will
  reuse `SubstituteExercise.plannedValues` and `.setCount` to seed a new
  `SessionExercise` for the substitute. Do not over-design here; keep this
  PR scoped to "substitute carries its own template."
