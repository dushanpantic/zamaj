# Plan — Post-session review screen (read-only session detail)

**Status**: implemented

## Context

Zamaj's whole reason for tracking **planned vs. actual** as first-class data
(product-context.md pillar 1: "enables honest retros, deload decisions…") is
invisible once a session ends. Today, tapping a completed session in *Recent
sessions* opens a plain-text **export sheet** — there is no in-app view of what
you actually lifted, set by set, against the plan. The domain/persistence layers
already capture everything (`Session` → `SessionExercise` → `ExecutedSet`, plus
notes and extra work); the gap is purely UI.

This change adds a **read-only session detail screen** that renders the frozen
snapshot's planned values beside the logged actual values, so the lifter can
review a finished workout. It is the smallest change that makes pillar 1 visible
end-to-end, and it becomes the natural host for the deferred post-session
*editing* feature (product-context.md line 18) — out of scope here.

## Decisions (from interrogation)

1. **Read-only only.** No mutations. Editing recently-completed sets is a
   separate follow-on built on this screen.
2. **Entry point:** tapping a session tile opens the detail screen. Per-session
   text export/share **moves into** the detail screen's app bar (share icon).
   The list's "export this week" action is unchanged.
3. **Content:** show everything — skipped/replaced exercises (marked, not
   hidden), session notes, extra work, and warmup sets.
4. **Module:** lives in the existing `mobile/lib/modules/export/` module.

## Approach

Reuse, don't reinvent. The non-trivial planned-vs-actual pairing already exists
in `ExerciseViewModelAssembler`; the per-set value formatting already exists
(privately) in `set_row.dart`. We extract the formatter once, add a read-only
entry point to the assembler, and build a thin read-only screen + display
widgets in `export/`.

### Reuse map (existing code to lean on)

- **Pairing + superset grouping:** `ExerciseViewModelAssembler.assemble(SessionState)`
  — `mobile/lib/modules/workout_overview/services/exercise_view_model_assembler.dart`.
  Already exported from the `workout_overview` barrel. For a completed session,
  `SessionState(session:, openTargets: const [], isComplete: true)` yields fully
  read-only view models (`isLoggable == false` everywhere).
- **View models:** `SupersetGroupViewModel` / `ExerciseViewModel` /
  `SetRowViewModel` (+ `displayName` extension for replaced exercises) — already
  barrel-exported from `workout_overview`.
- **Share sheet:** `ExportPreviewSheet.show(...)` — static, reads `ShareService`
  from the provider tree; pair with `SessionExportFormatter.format(session, includeWarmups:)`.
- **List data:** `RecentSessionsLoaded.sessionsById` already holds fully
  hydrated `Session` objects — no refetch, no new bloc needed.
- **Tokens/building blocks:** `SectionHeader`, `AppStateView`, `appColors`
  (semantic `planned`/`actual`/`exerciseCompleted|Skipped|Replaced`),
  `AppSpacing`/`AppRadius`/`AppTypography`. Standard 48 dp targets (this screen
  is **outside** the two sweaty-hands modules).

### Step 1 — Extract a shared per-set value formatter (DRY, pure, tested)

New `mobile/lib/modules/domain/services/set_value_formatter.dart` — a pure
service alongside `session_export_formatter.dart`:

- `formatPlanned(PlannedSetValues?, MeasurementType) → String`
- `formatActual(ActualSetValues) → String`

Port the exact logic from `set_row.dart`'s private `_plannedLabel` /
`_formatActual` (lines 439-464). Export from the `domain` barrel.

Then **refactor** `set_row.dart` to call the shared formatter (behavior-
preserving; removes the private duplication). Tests:
`test/domain/services/set_value_formatter_test.dart` covering all three
measurement types (rep-based, time-based ± weight, bodyweight) and the null/`—`
planned case.

### Step 2 — Read-only assembler entry point

Add to `ExerciseViewModelAssembler`:

```dart
static List<SupersetGroupViewModel> assembleReadOnly(Session session) =>
    assemble(SessionState(session: session, openTargets: const [], isComplete: true));
```

Test in `test/modules/workout_overview/services/exercise_view_model_assembler_test.dart`
(mirror existing cases): a completed session with completed/skipped/replaced
exercises + a superset produces grouped view models with every row
`isLoggable == false`.

### Step 3 — Route + args

- `mobile/lib/modules/export/navigation/export_routes.dart`: add
  `static const sessionDetail = '/export/session-detail';`
- New `mobile/lib/modules/export/models/session_detail_args.dart`: small class
  carrying `final Session session;` (no json; mirrors `RecentSessionsArgs` shape).
- `export_router.dart`: handle `ExportRoutes.sessionDetail`, cast args to
  `SessionDetailArgs`, build `SessionDetailScreen(session:)` in a
  `MaterialPageRoute`. No bloc (read-only, data passed in).

### Step 4 — Detail screen + read-only widgets

- New `mobile/lib/modules/export/screens/session_detail_screen.dart`
  (`StatelessWidget`, takes `Session`):
  - AppBar: title = workout day name (`session.snapshot.workoutDay.name`);
    actions = share `IconButton(Icons.ios_share)` → `ExportPreviewSheet.show`
    with `SessionExportFormatter.format(session, includeWarmups:)`.
  - Body: `assembleReadOnly(session)` → list of group widgets; then a
    **Notes** section (`session.notes`) and an **Extra work** section
    (`session.extraWork`) when non-empty, using `SectionHeader`.
- New `mobile/lib/modules/export/widgets/session_detail_exercise_card.dart`
  (and a small set-row widget, or a private one in the same file): renders one
  `ExerciseViewModel` — `displayName`, planned summary, a per-set list showing
  `Set N · planned (colors.planned) ↔ actual (colors.actual)` via the Step 1
  formatter, with a status icon/badge for completed/skipped/replaced
  (semantic colors). Supersets render grouped (reuse `SupersetGroupViewModel`).
  Lean, stateless — **do not** reuse the heavy stateful `SetRow`.
- Update the `export` barrel (`export.dart`) to export the new screen, args,
  and route additions.

### Step 5 — Rewire tile tap

In `recent_sessions_screen.dart`, change `_onTilePressed` (lines 169-185) to
`Navigator.of(context).pushNamed(ExportRoutes.sessionDetail,
arguments: SessionDetailArgs(session: session))` instead of opening
`ExportPreviewSheet`. (Per-session export now lives behind the detail screen's
share icon.)

### Step 6 — Update product-context.md (required by CLAUDE.md)

Update the **"After a session"** section (lines 42-43) to add the session detail
/ review screen and note that per-session text export now lives inside it.
Current-state only; no roadmap.

## Out of scope

- Editing / correcting logged sets (separate follow-on).
- "Last time" reference in Focus Mode; progress charts.
- Any schema/migration/repository-contract change (none needed).

## Notes / trade-offs

- This introduces the first **UI→UI** barrel import (`export` →
  `workout_overview`) for the assembler + view models. Allowed by
  `tool/check_offline_imports.sh` (which only forbids networking/drift in UI
  modules); chosen over duplicating the pairing logic. If this coupling grows,
  a later refactor can lift the assembler into a shared presentation location.
- Route carries the full `Session` (already in hand) to avoid a refetch/bloc.
  The editing follow-on can switch to a `watchSession`-backed cubit so live
  edits reflect automatically.

## Verification

Run from `mobile/`:

1. `dart run build_runner build --force-jit` (freezed for any new model).
2. `tool/ci.sh` — offline-imports guard, codegen, format, analyze, **test**
   (new `set_value_formatter_test.dart` + extended assembler test must pass).
3. Manual (user-run, per their preference): open *Recent sessions* → tap a
   completed session → confirm the detail screen shows planned↔actual per set,
   skipped/replaced exercises marked, supersets grouped, warmups present, notes
   + extra work at the bottom; tap the share icon → export sheet still works
   (with the Include-warmups toggle).

## Build Progress

- [x] Step 1: Extract a shared per-set value formatter (`SetValueFormatter`) + refactor `set_row.dart`
- [x] Step 2: Read-only assembler entry point (`assembleReadOnly`)
- [x] Step 3: Route + `SessionDetailArgs` + router handling
- [x] Step 4: `SessionDetailScreen` + read-only display widgets + barrel
- [x] Step 5: Rewire recent-sessions tile tap
- [x] Step 6: Update product-context.md

### Acceptance Criteria

- [x] AC1: A pure `SetValueFormatter` in domain exposes `formatPlanned(PlannedSetValues?, MeasurementType)` and `formatActual(ActualSetValues)`, producing output byte-identical to the prior `set_row.dart` private formatters across rep-based, time-based (± weight), bodyweight, and the null/`—` planned case; `set_row.dart` delegates to it (no duplicated logic).
- [x] AC2: `ExerciseViewModelAssembler.assembleReadOnly(Session)` returns grouped view models for a completed session (completed/skipped/replaced + superset) with every set row `isLoggable == false`.
- [x] AC3: `ExportRoutes.sessionDetail` exists; `SessionDetailArgs(session:)` carries the session; `ExportRouter` builds `SessionDetailScreen` for that route.
- [x] AC4: `SessionDetailScreen` renders planned↔actual per set, marks skipped/replaced exercises, groups supersets, includes warmups, and shows Notes + Extra work sections when non-empty; the app-bar share icon opens `ExportPreviewSheet` backed by `SessionExportFormatter.format`.
- [x] AC5: Tapping a session tile in Recent sessions navigates to `SessionDetailScreen` (no longer opens the export sheet directly); the list's "export this week" action is unchanged.
- [x] AC6: product-context.md "After a session" section documents the session detail/review screen and that per-session text export now lives inside it.
