# Rep-range Support — Implementation Plan

## 1. Problem statement

Today a rep-based **planned** set carries a single `reps: int`. In practice, a coach often prescribes a *range* — "barbell bench 6–8" — so the lifter can probe their working weight and stop within a target window. We need to:

- Let the user define a planned rep target as either a fixed value (`8`) **or** a range (`6–8`).
- Display ranges everywhere planned reps are shown (workout overview, focus mode, plan preview, session export, summaries).
- Keep `ExecutedSet` / `ActualSetValues` as a **single integer** — the lifter still records an exact count when they finish the set.
- Preserve immutability of past session snapshots: ranges must round-trip through `SessionSnapshot` and survive migrations.

Non-goals:

- No range support on **time-based** sets (durations remain a single integer).
- No range support on the **actual** side. The lifter logs what they did, not a range.
- No analytics / 1RM math changes — out of scope.

## 2. Model — the chosen shape

Replace `PlannedRepBased.reps: int` with a small value object that can express both shapes, while keeping the JSON discriminator-aware so old snapshots still deserialize.

### 2.1 New domain model: `RepTarget`

New file: [mobile/lib/modules/domain/models/rep_target.dart](mobile/lib/modules/domain/models/rep_target.dart)

```dart
@Freezed(unionKey: 'type')
sealed class RepTarget with _$RepTarget {
  RepTarget._() {
    switch (this) {
      case RepTargetFixed(:final reps):
        if (reps < 0) throw ValidationError(...);   // reps_non_negative
      case RepTargetRange(:final minReps, :final maxReps):
        if (minReps < 0) throw ValidationError(...);
        if (maxReps < minReps) throw ValidationError(...);  // range_min_le_max
        if (minReps == maxReps) throw ValidationError(...); // range_distinct (use Fixed instead)
    }
  }

  factory RepTarget.fixed({required int reps}) = RepTargetFixed;
  factory RepTarget.range({required int minReps, required int maxReps}) = RepTargetRange;

  factory RepTarget.fromJson(Map<String, dynamic> json) =>
      wrapDeserializationErrors(() => _$RepTargetFromJson(json), json, 'RepTarget');
}
```

`unionKey: 'type'` matches the rest of the codebase. The `range_distinct` invariant prevents `6–6` from existing alongside `6` — only one canonical form.

Export the new type from [mobile/lib/modules/domain/domain.dart](mobile/lib/modules/domain/domain.dart).

### 2.2 `PlannedSetValues.repBased` becomes range-aware

Edit [mobile/lib/modules/domain/models/planned_set_values.dart](mobile/lib/modules/domain/models/planned_set_values.dart):

```dart
const factory PlannedSetValues.repBased({
  required double weightKg,
  required RepTarget repTarget,
}) = PlannedRepBased;
```

`ActualSetValues.repBased` stays as `{double weightKg, int reps}` — actual is always a single number.

Update validation in [workout_set.dart](mobile/lib/modules/domain/models/workout_set.dart) to delegate rep validation to `RepTarget`'s own constructor (just deconstruct & validate weight; reps validation already happens inside `RepTarget._`).

Update [substitute_exercise.dart](mobile/lib/modules/domain/models/substitute_exercise.dart) — its `plannedValues: PlannedSetValues` carries `RepTarget` transparently; no field changes needed.

### 2.3 Schema-version bump

Edit [mobile/lib/core/schema_versions.dart](mobile/lib/core/schema_versions.dart): bump `domain` from `4` to `5`. Leave `drift` at `6` unless a backfill migration requires it (see §4.2 — likely not; the change is JSON-shape-only inside `planned_values_payload_json` and the session snapshot blob).

## 3. JSON shape — single canonical form

The app is single-install (user's phone only), so backward compatibility for existing on-disk data is **not required**. We pick one wire shape and ship it.

New shape for `PlannedRepBased`:

```json
{"weightKg":60.0,"repTarget":{"reps":10,"type":"fixed"},"type":"repBased"}
```

or, for a range:

```json
{"weightKg":60.0,"repTarget":{"minReps":6,"maxReps":8,"type":"range"},"type":"repBased"}
```

No `fromJson` shim, no legacy fixture. The old `reps:N` shape disappears entirely.

## 4. Persistence — nuke-on-upgrade

Bump `SchemaVersions.drift` from `6` to `7` and use a **destructive** migration: drop and recreate every domain table. Existing programs and session history are wiped on first launch after the upgrade — acceptable because the install base is one device and the user is in control of the timing.

Edit [mobile/lib/modules/persistence/database/migrations.dart](mobile/lib/modules/persistence/database/migrations.dart):

```dart
if (from < 7) {
  // Rep-target rollout: rewrite of planned_set JSON shape. Existing data
  // dropped — single-install app, no compat layer.
  await _wipeAllDomainTables(db);
}
```

`_wipeAllDomainTables` deletes from `sets`, `exercises`, `exercise_groups`, `workout_days`, `programs`, `session_notes`, `extra_work_items`, `executed_sets`, `session_exercises`, `sessions` (cascade order honored by FKs but explicit deletes are safer).

Bump `SchemaVersions.domain` from `4` to `5`. No mapper, snapshot-hash, or read-shim logic needed.

### 4.1 Mappers

[workout_day_mapper.dart](mobile/lib/modules/persistence/mappers/workout_day_mapper.dart) and [session_mapper.dart](mobile/lib/modules/persistence/mappers/session_mapper.dart) round-trip through `PlannedSetValues.fromJson` / `.toJson()` and pick up the new shape automatically. No structural mapper edits required.

## 5. Program editor (creating / editing ranges)

### 5.1 Draft layer

Edit [mobile/lib/modules/program_management/models/program_editor_draft.dart](mobile/lib/modules/program_management/models/program_editor_draft.dart):

```dart
const factory PlannedSetDraftValues.repBased({
  required String weightInput,
  required String repsInput,        // single value OR "6-8" / "6–8"
}) = PlannedSetDraftRepBased;
```

We keep `repsInput` as a single string field that accepts both `"8"` and `"6-8"`. This is the simplest UI: one text box, range delimited by `-` (ASCII) or `–` (en dash). Parsing lives in `ProgramValidation`.

`_toPlannedSetValues` (same file, used by import path) and `_setToDraft` / `_draftToPlannedValues` in the editor bloc map between `RepTarget` and the string form.

### 5.2 Validation

Edit [mobile/lib/modules/program_management/services/program_validation.dart](mobile/lib/modules/program_management/services/program_validation.dart):

Add a small `parseRepTarget(String) -> RepTarget?` helper, and change `validateRepBasedSet`'s return to carry `RepTarget` instead of `int reps`:

```dart
ValidationResult<({double weightKg, RepTarget repTarget})> validateRepBasedSet(...)
```

Parsing rules:

- `"8"` → `RepTarget.fixed(reps: 8)`.
- `"6-8"`, `"6 - 8"`, `"6–8"` → `RepTarget.range(min: 6, max: 8)`. Reject if `min == max` (treat as fixed) or `min > max`.
- Reps still bounded to `[0, 999]` per side. `range_invalid` for malformed.

Update [exercise_editor_state.dart](mobile/lib/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart)'s `_isSetValid` to use the new validation result.

### 5.3 UI

Edit [planned_set_row.dart](mobile/lib/modules/program_management/widgets/planned_set_row.dart) — only the **label** and **input formatters** change for `_RepBasedFields`:

- Label: `"Reps (or range, e.g. 6-8)"`.
- `inputFormatters`: allow digits + `-` (ASCII) + `–`. Filter regex: `r'[0-9\-–]'`.

The existing `onRepsChanged: (String)` signature is unchanged; the bloc keeps the raw input.

Edit the editor screen (no functional change — width may need a small tweak so "6-8" doesn't truncate).

### 5.4 Text plan parser & pretty printer

Edit [text_plan_parser.dart](mobile/lib/modules/program_management/services/text_plan/text_plan_parser.dart):

The existing set-line regex is `^\d+[xX×]\d+$` (e.g. `4x8`). Extend the right-hand side to optionally accept `\d+-\d+`:

```dart
final _setsByRepsPattern = RegExp(r'^\d+[xX×](\d+(?:[-–]\d+)?)$');
```

In `_attachPlannedSet`, parse the rhs group: if it contains `-`/`–`, split to a range; otherwise fixed. Emit `PlanDraftSet.repBased(..., repTarget: ...)`.

Edit [plan_draft.dart](mobile/lib/modules/program_management/services/text_plan/plan_draft.dart): change `PlanDraftSet.repBased`'s `reps: int` field to `repTarget: RepTarget` (or to a draft mirror `({int min, int? max})` if we want plan_draft to remain freezed-only without domain deps — check current deps; if `plan_draft.dart` already imports domain types, use `RepTarget` directly).

Edit [plan_pretty_printer.dart](mobile/lib/modules/program_management/services/text_plan/plan_pretty_printer.dart): print `${count}x6-8 ...` when range, else `${count}x8 ...`. Use ASCII `-` for output stability.

Update the golden file [test/modules/program_management/text_plan/golden/rep_based_plan.txt](mobile/test/modules/program_management/text_plan/golden/rep_based_plan.txt) — add at least one range line.

## 6. Display (read-only formatting)

Anywhere a planned `reps: int` is rendered today, replace with a small helper.

New helper (single source of truth) in [mobile/lib/core/rep_target_formatter.dart](mobile/lib/core/rep_target_formatter.dart):

```dart
abstract final class RepTargetFormatter {
  static String format(RepTarget t) => switch (t) {
    RepTargetFixed(:final reps) => reps.toString(),
    RepTargetRange(:final minReps, :final maxReps) => '$minReps-$maxReps',
  };
}
```

Update every call site that destructures `PlannedRepBased(:final reps)`:

- [planned_summary_formatter.dart](mobile/lib/modules/workout_overview/services/planned_summary_formatter.dart) — `'... ${sets.length}×${RepTargetFormatter.format(repTarget)}'`.
- [workout_overview widgets/set_row.dart](mobile/lib/modules/workout_overview/widgets/set_row.dart) `_plannedLabel` — same substitution.
- [focus_mode_assembler.dart](mobile/lib/modules/focus_mode/services/focus_mode_assembler.dart) `_summarizePlanned` and `_summarizeSubstitute`.
- [session_export_formatter.dart](mobile/lib/modules/domain/services/session_export_formatter.dart) `_plannedSummary`, `_renderPlannedValues`, `_substitutePlanSummary`.

`ExecutedSet` rendering paths (`_actualLabel`, `_renderExecutedSet`) stay untouched — actual is always a single number.

## 7. Focus mode — seeding & suggestions

When the lifter opens a set with a planned **range**, what do we pre-fill in the editor?

Behavior (decide once, apply consistently):

- **First set** of a rep-range exercise → seed reps with the **range maximum** (the optimistic target).
- **Subsequent sets** → seed from the last executed set's actual reps (existing behavior, unchanged).
- Rep bump buttons still operate on the integer draft; they don't touch the planned range.

Implementation:

- [session_flow_engine.dart](mobile/lib/modules/domain/services/session_flow_engine.dart) `_convertPlannedToActual` — when planned is `PlannedRepBased`, take `repTarget` and emit `ActualSetValues.repBased(weightKg, reps: switch (repTarget) { RepTargetFixed(:reps) => reps, RepTargetRange(:maxReps) => maxReps })`.
- [focus_mode_bloc.dart](mobile/lib/modules/focus_mode/bloc/focus_mode_bloc.dart) `_seedDraft` — relies on `suggestedValues`, so no direct change needed.

For the **planned-vs-actual** indication in `SetRowViewModel` / `SetRow`, also update the row to display the planned range (e.g. `"60kg × 6-8"`). Already covered by §6.

## 8. Test plan

Scope is domain + persistence (per CLAUDE.md — no widget tests).

### 8.1 Unit / domain

- New `test/domain/rep_target_construction_test.dart`:
  - `fixed(reps: -1)` → `ValidationError(reps_non_negative)`.
  - `range(min: 8, max: 6)` → `range_min_le_max`.
  - `range(min: 6, max: 6)` → `range_distinct`.
  - Property: round-trip `fromJson(toJson()) == identity` for both variants.
- Extend `test/domain/workout_set_construction_test.dart`: weight invariants still hold under both variants; mismatched measurementType still errors.

### 8.2 Serialization

- Replace the existing `planned_set_values_rep_based.json` with two goldens — one for `fixed`, one for `range` — under the same directory. The old shape is gone, no legacy fixture.
- Regenerate aggregate goldens: `dart run tool/generate_aggregate_goldens.dart` (per CLAUDE.md).

### 8.3 Generators

Edit [test/support/generators.dart](mobile/test/support/generators.dart):

- New `anyRepTarget(rng)` — 50/50 fixed vs range; range always has `min < max`, both ≤ 30.
- `anyPlannedSetValues` and `anyPlannedSetValuesForMeasurement` use `anyRepTarget`.

### 8.4 Integration

- New `test/integration/rep_target_wipe_migration_test.dart`: seed a `drift=6` database with rows in every domain table, run migrations to `drift=7`, assert all domain tables are empty and the DB still functions for fresh writes.
- Existing `test/integration/version_mismatch_test.dart` and snapshot/hash tests continue to run on freshly written data; no special legacy fixtures needed.

### 8.5 Text plan

- Extend [test/modules/program_management/text_plan/...](mobile/test/modules/program_management/text_plan/) with new fixtures:
  - `4x6-8 60kg` (ASCII dash)
  - `4x6–8 60kg` (en dash)
  - Malformed (`4x8-6`, `4x-8`, `4x8-`) → parse error.
  - Pretty-printer round-trip golden for a range plan.

### 8.6 Engine

Add coverage to existing engine tests:

- `completeSet` on a range exercise: planned `6-8`, executed `7` is valid; suggested-value seeding returns `maxReps` for first set.
- `suggestValues` for cursor `setIndex == 0` over a range → returns `ActualRepBased(reps: maxReps)`.

## 9. Sequencing — recommended commit order

1. **Domain skeleton** — `RepTarget` model + tests + serialization goldens.
2. **Wire into `PlannedSetValues`**. Update workout_set / substitute_exercise validators. Replace `reps` golden with `fixed` + `range` goldens. Run codegen. Bump `SchemaVersions.domain` to 5.
3. **Persistence wipe migration** — bump `drift` to 7, add destructive migration + integration test.
4. **Display call sites** — `RepTargetFormatter` + every consumer in §6. Regenerate aggregate goldens.
5. **Program editor** — draft + validation + UI.
6. **Text plan parser & pretty printer** — incl. golden updates.
7. **Focus-mode seeding** — `_convertPlannedToActual` change + engine tests.
8. **Generators** — update last so property/round-trip suites pick up the new variants automatically.

Each step ends with `tool/ci.sh` green (offline-import check, codegen, format, analyze, test).

## 10. Open questions

- **Range seeding policy** (§7): I propose seeding the first set with `maxReps`. Confirm — alternative is `minReps` (conservative) or midpoint. Easy to flip in `_convertPlannedToActual`.
- **Display separator**: I propose ASCII `-` in all read paths (e.g. `6-8`). Some lifters might prefer the en dash `–`. Stable ASCII is simpler for export-to-WhatsApp.
- **Editor input**: single string box (`"6-8"`) vs two number fields with a toggle (`Fixed` / `Range`). I lean toward single box (less chrome, parser already exists for text plans). Confirm before §5.3.
- **Should range collapse on `min == max`?** Plan says yes — validator rejects, parser normalizes to fixed. Confirm.
