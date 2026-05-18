# Bodyweight exercise support — design & plan

## Problem

Pushups, pull-ups, dips, bodyweight squats etc. are first-class strength exercises but the data model can only express them as rep-based with `weightKg = 0`. The UI then surfaces them as `0kg × 10`, which is semantically wrong and visually confusing — `0kg` reads like "I forgot to enter a weight," not "this exercise has no external load."

## Options considered

### A. New `MeasurementType.bodyweight` variant *(recommended)*

Extend the sealed `MeasurementType` union with a third case, and mirror it on `PlannedSetValues` / `ActualSetValues`. Bodyweight variants carry **only `reps`** (no `weightKg` field).

- **Pros**
  - Domain says what it means: "this exercise has no weight field" rather than "this exercise has weight = 0."
  - Matches the existing pattern. Sealed unions already model *shapes* that differ in fields (rep-based has `weightKg + repTarget`, time-based has `durationSeconds + weightKg?`). Bodyweight differs the same way.
  - Dart exhaustive switches mechanically surface every site that needs updating — exactly the safety net the architecture is built for.
  - Renders correctly with zero special-case formatter logic: there is no `weightKg` to display.
  - Leaves the door open for **weighted bodyweight** (pull-ups +20kg, dips with belt) as a follow-up by adding an optional `addedWeightKg` to the new variant.
- **Cons**
  - Touches every switch over `MeasurementType` / `PlannedSetValues` / `ActualSetValues`. Surface area is broad but mechanical — the compiler points at each site.
  - Editor gets a third measurement-type chip.

### B. Render `weightKg == 0` as "Bodyweight"

Pure UI fix; no domain change.

- **Pros**
  - Smallest possible change. Zero schema, zero migration, zero new switch arms.
- **Cons**
  - Conflates two genuinely different things: "0 kg empty barbell" and "bodyweight pushups." For a strength-tracking app these are not the same — bodyweight squats at 70 kg user mass apply ~70 kg of load; a 0 kg empty bar applies 0 kg.
  - Forecloses **weighted bodyweight**: to express pull-ups +20 kg you'd need an extra flag *anyway*, at which point you've reinvented option A with worse ergonomics.
  - Lies in the export: WhatsApp text to a coach would say "Pushups: Done: 0 × 10" or "Bodyweight × 10" depending on the formatter — neither matches what was actually stored.

### C. Add `isBodyweight` flag to the existing rep-based variant

- **Pros:** less invasive than A.
- **Cons:** introduces an illegal state (`isBodyweight=true` with `weightKg=5`) that has to be excluded by validation rather than by the type system. Fights the codebase's preference for sealed unions over flags.

**Recommendation: A.** It's the on-pattern move, the only one that's semantically honest, and the only one that doesn't paint us into a corner on weighted-bodyweight later. The cost is fan-out across switch sites, which Dart's exhaustiveness analysis makes safe and locates for us.

## Open questions (resolve before implementing)

1. **Naming.** `bodyweight` vs `calisthenic` vs `unweighted`. Recommendation: `bodyweight` — clearest to users, matches industry vocabulary (Strong, Hevy).
2. **Added-load support now or later?** Recommendation: **later**. Ship the simple case first (`reps` only). When a real need appears, add an optional `addedWeightKg` to the bodyweight variant — additive, no migration.
3. **Text-plan syntax for bodyweight.** The current parser already silently defaults to `weightKg: 0.0` when no `kg` token is present ([text_plan_parser.dart:432-453](mobile/lib/modules/program_management/services/text_plan/text_plan_parser.dart#L432-L453)). Options:
   - `3x10` (no kg token) → bodyweight (changes existing parser semantics — was "0 kg," now means "bodyweight")
   - `3x10 bw` → bodyweight, `3x10` keeps current 0-kg-rep-based behavior (backwards compatible, more explicit)
   - Recommendation: **`3x10 bw` explicit token**, and either (a) preserve current `3x10` → 0 kg rep-based, or (b) treat `3x10` as a parse warning prompting the user to disambiguate. Lean toward (a) for backwards compatibility on any plans the user has already authored.
4. **Existing programs with `weightKg == 0` rep-based sets.** Do nothing. They remain rep-based-zero. The user can edit them to bodyweight if desired. Auto-migration is not safe (intent is ambiguous).

## Implementation plan

Order matters: domain first, then persistence, then UI per feature. Each step compiles and tests independently.

### 1. Domain models

**Files:**
- [mobile/lib/modules/domain/models/measurement_type.dart](mobile/lib/modules/domain/models/measurement_type.dart) — add `MeasurementType.bodyweight()` → `BodyweightMeasurement`.
- [mobile/lib/modules/domain/models/planned_set_values.dart](mobile/lib/modules/domain/models/planned_set_values.dart) — add `PlannedSetValues.bodyweight({ required RepTarget repTarget })` → `PlannedBodyweight`.
- [mobile/lib/modules/domain/models/actual_set_values.dart](mobile/lib/modules/domain/models/actual_set_values.dart) — add `ActualSetValues.bodyweight({ required int reps })` → `ActualBodyweight`.
- [mobile/lib/modules/domain/models/workout_set.dart](mobile/lib/modules/domain/models/workout_set.dart) — extend the validation switch with a `(BodyweightMeasurement, PlannedBodyweight)` arm; add mismatch arms.
- [mobile/lib/modules/domain/models/executed_set.dart](mobile/lib/modules/domain/models/executed_set.dart) — same validation extension for actual values.

**Then:** `dart run build_runner build --force-jit` to regenerate `*.freezed.dart` / `*.g.dart`.

### 2. Schema version bump

[mobile/lib/core/schema_versions.dart](mobile/lib/core/schema_versions.dart): `domain: 5 → 6`. **No Drift `schemaVersion` bump needed** — we add no columns or tables. New variant is purely additive in the JSON payload (`"type": "bodyweight"`); old rows still deserialize because they have no such payload.

No SQL migration entry needed in [migrations.dart](mobile/lib/modules/persistence/database/migrations.dart) (no schema change). Confirm by running `tool/ci.sh` after codegen.

### 3. Mappers / persistence

- [mobile/lib/modules/persistence/mappers/workout_day_mapper.dart](mobile/lib/modules/persistence/mappers/workout_day_mapper.dart)
- [mobile/lib/modules/persistence/mappers/session_mapper.dart](mobile/lib/modules/persistence/mappers/session_mapper.dart)
- [mobile/lib/modules/persistence/repositories/drift_program_repository.dart](mobile/lib/modules/persistence/repositories/drift_program_repository.dart)
- [mobile/lib/modules/persistence/repositories/drift_session_repository.dart](mobile/lib/modules/persistence/repositories/drift_session_repository.dart)

Audit every switch on `MeasurementType` / `PlannedSetValues` / `ActualSetValues` and add the bodyweight arm. Most should be trivial — the discriminator-based JSON layer just stores `"type": "bodyweight"` and round-trips through freezed-generated `fromJson` / `toJson`.

### 4. Program editor (compose path)

- [mobile/lib/modules/program_management/models/program_editor_draft.dart](mobile/lib/modules/program_management/models/program_editor_draft.dart) — add `PlannedSetDraftValues.bodyweight({ required String repsInput })`; extend `_toPlannedSetValues` switch.
- [mobile/lib/modules/program_management/widgets/measurement_type_selector.dart](mobile/lib/modules/program_management/widgets/measurement_type_selector.dart) — add a `Bodyweight` chip.
- [mobile/lib/modules/program_management/widgets/planned_set_row.dart](mobile/lib/modules/program_management/widgets/planned_set_row.dart) — render reps-only editor for the bodyweight case (no kg field, no kg label).
- [mobile/lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart](mobile/lib/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart) — switch-on measurement type when seeding a new set and when handling `ExerciseMeasurementTypeConfirmed`.
- [mobile/lib/modules/program_management/services/program_validation.dart](mobile/lib/modules/program_management/services/program_validation.dart) — extend validation switches.

### 5. Text plan (compose path)

- [mobile/lib/modules/program_management/services/text_plan/plan_draft.dart](mobile/lib/modules/program_management/services/text_plan/plan_draft.dart) — add `PlanDraftSet.bodyweight({ required int count, required RepTarget repTarget })`.
- [mobile/lib/modules/program_management/services/text_plan/text_plan_parser.dart](mobile/lib/modules/program_management/services/text_plan/text_plan_parser.dart) — recognize a trailing `bw` token (per Q3 above); emit the new variant.
- [mobile/lib/modules/program_management/services/text_plan/plan_pretty_printer.dart](mobile/lib/modules/program_management/services/text_plan/plan_pretty_printer.dart) — emit `3x8 bw` form.
- [mobile/lib/modules/program_management/services/plan_draft_to_aggregate.dart](mobile/lib/modules/program_management/services/plan_draft_to_aggregate.dart) — map new draft variant to the new aggregate variant.

### 6. Workout overview (execute path)

- [mobile/lib/modules/workout_overview/widgets/set_row.dart](mobile/lib/modules/workout_overview/widgets/set_row.dart) — `_plannedLabel`, `_actualLabel`, `_seedFromViewModel`, `_readValues`, `_plannedAsActual`, `_Editor` build, `_RepBasedFields` analogue (`_BodyweightFields` with only a reps field).
- [mobile/lib/modules/workout_overview/services/planned_summary_formatter.dart](mobile/lib/modules/workout_overview/services/planned_summary_formatter.dart) — `bodyweight` arm renders e.g. `4×8` or `4×6-10` (no `kg`).
- [mobile/lib/modules/workout_overview/services/exercise_view_model_assembler.dart](mobile/lib/modules/workout_overview/services/exercise_view_model_assembler.dart) — any measurement-type or values switches.

### 7. Focus mode (execute path)

- New widget [mobile/lib/modules/focus_mode/widgets/focus_bodyweight_panel.dart](mobile/lib/modules/focus_mode/widgets/focus_bodyweight_panel.dart) — mirrors `FocusRepBasedPanel` but drops the weight column and its bump row. Layout: a single big reps field centred with bump buttons.
- [mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart](mobile/lib/modules/focus_mode/screens/focus_mode_screen.dart) — extend the `switch (measurementType)` that picks the panel.
- [mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart](mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart) — `_summarizePlanned` / `_summarizeSubstitute` get bodyweight arms.
- [mobile/lib/modules/focus_mode/bloc/focus_mode_bloc.dart](mobile/lib/modules/focus_mode/bloc/focus_mode_bloc.dart), [mobile/lib/modules/focus_mode/bloc/focus_mode_event.dart](mobile/lib/modules/focus_mode/bloc/focus_mode_event.dart) — any handler that reads `weightKg` from `currentPlannedValues` / `lastExecutedValues` switches over the new variant. Bodyweight has no weight to bump or edit, so the related events should never fire on a bodyweight panel.
- [mobile/lib/modules/focus_mode/services/increment_rules.dart](mobile/lib/modules/focus_mode/services/increment_rules.dart) — no change (weight steps are unused for bodyweight panels).

### 8. Export

[mobile/lib/modules/domain/services/session_export_formatter.dart](mobile/lib/modules/domain/services/session_export_formatter.dart) — `_renderExecutedSet`, `_plannedSummary`, `_renderPlannedValues`, `_substitutePlanSummary`. Bodyweight rows render as e.g. `8 reps` or `4 × 8` (no `kg`).

### 9. Substitute exercises

`SubstituteExercise.plannedValues` is a `PlannedSetValues`, so it composes for free. The replace-exercise flow already lets the substitute carry its own `measurementType`, so swapping a weighted exercise for a bodyweight one (or the reverse) is well-defined. Verify the substitute editor exposes the new measurement type.

### 10. Tests

Layout mirrors `lib/` under `test/{core,domain,persistence,repository,serialization}` — extend, don't add new directories.

- `test/domain/` — `WorkoutSet` / `ExecutedSet` validation: new variant accepts non-negative reps and rejects mismatched `measurementType` + `plannedValues` pairs. RepTarget interaction (fixed + range) for bodyweight.
- `test/serialization/` — canonical JSON round-trip for the new variant. Regenerate goldens with `dart run tool/generate_aggregate_goldens.dart` and review the diff.
- `test/persistence/` — save / load a program with a bodyweight exercise; complete a session set on a bodyweight exercise; verify `ActualBodyweight` survives the round trip.
- `test/support/generators.dart` — extend the property-test generator to emit `bodyweight` variants so the property suite covers them.
- Text-plan parser tests for the new syntax (success cases, idempotency under pretty-print → parse).

### 11. Theme / token compliance

No new tokens needed — the bodyweight panel uses existing typography, spacing, and color semantics. UI changes are constrained to lib/modules/**/screens|widgets and lib/building_blocks; use `Theme.of(context).appColors`, `AppSpacing.*`, `AppRadius.*`, `AppTypography.standard.numeric` for the reps readout (tabular figures matter on the big focus-mode hero number).

### 12. Verify

```
cd mobile
dart run build_runner build --force-jit
tool/check_offline_imports.sh
tool/ci.sh
dart run tool/generate_aggregate_goldens.dart   # if any aggregate JSON shapes changed
```

Then manual: edit a program → add a bodyweight pushup exercise → start a session → log via overview screen *and* via focus mode → end session → share to coach → confirm export reads "Pushups / Plan: 4 × 8 / Done: 8, 8, 7, 6" with no stray `kg` anywhere.

## Risk & rollback

- **Risk:** sealed-union widening misses a switch site. **Mitigation:** Dart's exhaustiveness check is enforced; analyzer errors will list them.
- **Risk:** a third-party JSON payload (hand-edited file, debug export) doesn't have a discriminator the new freezed deserializer accepts. **Mitigation:** existing rows use `"type": "repBased"` / `"type": "timeBased"` — the new `"bodyweight"` literal doesn't collide. Verified by inspection of [planned_set_values.dart:8](mobile/lib/modules/domain/models/planned_set_values.dart#L8) `@Freezed(unionKey: 'type')`.
- **Rollback:** revert the commit. Old rows are unchanged. New bodyweight rows would fail to deserialize after revert — but those only exist if the user has already used the feature post-rollout, which is the cost of any user-facing rollback. Acceptable.
