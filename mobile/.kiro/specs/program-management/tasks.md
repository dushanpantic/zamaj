# Implementation Plan: Program Management

## Overview

This plan turns the `program-management` design into an incremental
Dart/Flutter implementation. Work proceeds bottom-up so every task unblocks
the next: dependencies → domain+Drift extension for
`Exercise.plannedRestSeconds` → repository contract extensions → pure-Dart
services → text-plan parser/printer → editor drafts → BLoCs → screens →
bootstrap/app wiring → concrete `url_launcher` boundary → CI gate.

**Not duplicated here (already done in prior specs):**

- `lib/core/app_colors.dart`, `lib/core/app_spacing.dart`,
  `lib/core/app_typography.dart`, `lib/core/app_theme.dart` — widgets read
  tokens via `Theme.of(context).appColors` and `AppSpacing.*`.
- `.kiro/steering/ui-tokens.md` steering file.

**Testing scope:** Only domain-layer tests are written (unit, integration,
property-based, serialization). BLoC tests, widget tests, and screen tests
are out of scope for now. Property-based tests (R10, design §12) appear
alongside the parser/service implementation they validate.

Conventions:
- Module lives under `lib/modules/program_management/` with barrel
  `program_management.dart` (R14 AC1).
- Property tests use plain-Dart generators in
  `test/support/program_management_generators.dart` and run ≥100 iterations
  inside standard `test()` blocks (matching the existing PBT convention).

## Tasks

- [x] 1. Add dependencies and extend the offline-import guard
  - [x] 1.1 Add runtime dependencies `flutter_bloc: ^9.1.1`, `equatable: ^2.0.7`, `url_launcher: ^6.3.1` to `pubspec.yaml`; run `flutter pub get` to confirm resolution; verify no networking package is introduced transitively
    - _Requirements: R13 AC1, R14 AC3_
    - _Design: §13.3_

  - [x] 1.2 Extend `tool/check_offline_imports.sh` to additionally scan `lib/modules/program_management/` against a superset-forbidden list: existing networking imports plus `package:drift/*`, `package:drift_flutter/*`, `package:sqlite3/*`, any `*.g.dart` under `lib/modules/persistence/`, and the symbols `AppDatabase`, `NativeDatabase`, `driftDatabase`, `GeneratedDatabase`; emit `<file>:<line>:<offending symbol>` on violations and exit non-zero
    - _Requirements: R12 AC1, R12 AC2, R12 AC4, R12 AC5, R13 AC1, R13 AC2, R13 AC3_
    - _Design: §13.1, §13.2_

  - [x] 1.3 Create the module folder scaffolding: `lib/modules/program_management/{bloc,screens,widgets,services,models,navigation}/`, the text-plan sub-tree `services/text_plan/`, and an empty barrel file `lib/modules/program_management/program_management.dart`
    - _Requirements: R14 AC1, R14 AC2_
    - _Design: §1.2_

- [x] 2. Extend the domain + Drift layer with `Exercise.plannedRestSeconds`
  - [x] 2.1 Add the nullable `plannedRestSeconds` field to `lib/modules/domain/models/exercise.dart` (freezed redirecting factory) and add the range invariant in the `Exercise._()` body that throws `ValidationError(invariant: 'plannedRestSeconds_out_of_range')` when non-null and outside `[0, 3600]`; regenerate with `dart run build_runner build --force-jit`
    - _Requirements: R6 AC2, R6 AC3, R6 AC5, R6 AC6_
    - _Design: §7.1_

  - [ ]* 2.2 Extend `test/domain/exercise_group_construction_test.dart` (or add `test/domain/exercise_planned_rest_test.dart`) with example-based tests that construction accepts `null`, `0`, `3600`, and rejects `-1`, `3601` with the documented `invariant` code
    - _Requirements: R6 AC2, R6 AC3_
    - _Design: §7.1_

  - [x] 2.3 Add the `plannedRestSeconds` nullable integer column to `Exercises` in `lib/modules/persistence/database/tables.dart`
    - _Requirements: R6 AC5, R6 AC6_
    - _Design: §7.2_

  - [x] 2.4 Bump both `SchemaVersions.drift` and `SchemaVersions.domain` to `2` in `lib/core/schema_versions.dart`
    - _Requirements: R6 AC6_
    - _Design: §7.3, §15 decision 6_

  - [x] 2.5 Implement the v1→v2 migration branch in `lib/modules/persistence/database/migrations.dart` that calls `m.addColumn(m.database.exercises, m.database.exercises.plannedRestSeconds)` and regenerate Drift sources
    - _Requirements: R6 AC6_
    - _Design: §7.3_

  - [x] 2.6 Update `lib/modules/persistence/mappers/program_mapper.dart` (or the exercise mapper) to carry `plannedRestSeconds` between domain and Drift rows in both directions
    - _Requirements: R6 AC5, R6 AC6_
    - _Design: §7.2_

  - [ ]* 2.7 Write `test/integration/exercise_planned_rest_migration_test.dart` seeding a v1 schema with an exercise row, running the upgrade, and asserting every pre-existing row is preserved and `planned_rest_seconds` is `NULL` on each migrated row
    - _Requirements: R6 AC6_
    - _Design: §7.3, §14.4_

  - [ ]* 2.8 Extend `test/serialization/leaf_families_round_trip_test.dart` / aggregate round-trip test to cover `Exercise` with and without `plannedRestSeconds`; regenerate the `Exercise` golden and add a second golden with a non-null rest
    - _Requirements: R6 AC5, R11 AC3, R11 AC4_
    - _Design: §7.5, §7.6_

  - [ ]* 2.9 Extend mapper round-trip unit tests so `toRow(toDomain(row)) == row` holds with `plannedRestSeconds = NULL` and with `plannedRestSeconds = 90`
    - _Requirements: R6 AC5, R6 AC6_
    - _Design: §7.2_

- [x] 3. Extend the `ProgramRepository` contract
  - [x] 3.1 Add the optional `plannedRestSeconds` named parameter to `ProgramRepository.createExercise` in `lib/modules/domain/repositories/program_repository.dart`; implement the new parameter in `DriftProgramRepository`
    - _Requirements: R6 AC5, R10 AC1 (applies via §6.2), R12 AC1_
    - _Design: §7.4_

  - [x] 3.2 Define `ProgramAggregate` and its nested freezed value types (`WorkoutDayAggregate`, `ExerciseGroupAggregate`, `ExerciseAggregate`, `WorkoutSetAggregate`) in `lib/modules/program_management/models/program_aggregate.dart`; expose them via the module barrel
    - _Requirements: R9 AC3, R9 AC7_
    - _Design: §8_

  - [x] 3.3 Add the abstract method `Future<Program> saveProgramAggregate(ProgramAggregate aggregate)` to `ProgramRepository`; implement it in `DriftProgramRepository` inside a single `transaction` block that inserts rows in dependency order (Program → WorkoutDay → ExerciseGroup → Exercise → WorkoutSet) and rolls back on any exception; the implementation must never touch any `Sessions*` table
    - _Requirements: R9 AC3, R9 AC7, R11 AC1, R11 AC2_
    - _Design: §8_

  - [ ]* 3.4 Write `test/repository/save_program_aggregate_transactional_test.dart` covering: (a) happy path persists the full tree with assigned UUIDs and `schemaVersion=2`; (b) a mid-insert failure via a mocked subclass rolls back every row; (c) no `sessions`, `session_exercises`, `executed_sets`, `session_notes`, or `extra_work_items` row is ever written
    - _Requirements: R9 AC3, R9 AC7, R11 AC1, R11 AC2_
    - _Design: §8_

  - [ ]* 3.5 Extend `DriftProgramRepository` unit tests to cover `createExercise(plannedRestSeconds: 0)`, `createExercise(plannedRestSeconds: 3600)`, `createExercise(plannedRestSeconds: null)`, and confirm the persisted row round-trips via `getWorkoutDay`
    - _Requirements: R6 AC2, R6 AC3, R6 AC5_
    - _Design: §7.4_

- [x] 4. Implement pure-Dart services
  - [x] 4.1 Implement `lib/modules/program_management/services/program_validation.dart` with static validators (`validateProgramName` 1..100 for edit / 1..120 for create, `validateExerciseName` 1..80, `validateWorkoutDayName` 1..100, `validateRepBasedSet` weight 0..1000 at 0.5 kg, reps 0..999, `validateTimeBasedSet` 0..3600, `validatePlannedRest` 0..3600 nullable, `validateVideoUrl` http/https only 0..2048, `validateNotes` 0..2000, `validateSetCount` 1..20) returning sealed freezed `Valid` / `Invalid(reason)` unions
    - _Requirements: R2 AC2, R3 AC4, R3 AC5, R4 AC2, R5 AC3, R5 AC4, R5 AC8, R5 AC10, R6 AC2, R6 AC3, R7 AC1, R7 AC2, R7 AC3, R7 AC4, R15 AC3, R15 AC4, R15 AC5, R15 AC6_
    - _Design: §10, §10.1_

  - [ ]* 4.2 Write `test/modules/program_management/services/program_validation_test.dart` covering every validator at its boundary values (0, 0.5, 1, 999, 1000, 1000.5, 3600, 3601, empty, whitespace, 81 chars, 101 chars, 121 chars, 2001 chars, 2049 chars, non-http URL, ftp URL, malformed URL) and asserting the exact `Invalid` reason code for each
    - _Requirements: R2 AC2, R3 AC5, R5 AC10, R6 AC3, R7 AC4, R15 AC3, R15 AC4, R15 AC5, R15 AC6_
    - _Design: §10.1_

  - [x] 4.3 Implement `lib/modules/program_management/services/domain_error_presenter.dart` as an `abstract final` class with a single `present(DomainError)` returning `PresentedMessage(title, body)`; every branch embeds `invariant` / `field` / `entityId` verbatim as required by R15 AC1
    - _Requirements: R15 AC1_
    - _Design: §11_

  - [ ]* 4.4 Write `test/modules/program_management/services/domain_error_presenter_test.dart` covering `ValidationError`, `NotFoundError`, `ImmutabilityError`, `OrderingError`, `VersionMismatchError`, `DeserializationError`, asserting the produced `body` string contains `invariant` / `field` / `entityId` / `id` verbatim
    - _Requirements: R15 AC1_
    - _Design: §11_

  - [x] 4.5 Implement `lib/modules/program_management/services/external_link_launcher.dart` declaring the `abstract interface class ExternalLinkLauncher` with `Future<ExternalLinkResult> launch(Uri url)` and the sealed `ExternalLinkResult { ExternalLinkOpened, ExternalLinkFailure(reason) }` family; the file must not import `package:url_launcher/...`
    - _Requirements: R7 AC5, R7 AC6, R7 AC8, R12 AC3, R13 AC4_
    - _Design: §9, §13.1_

- [x] 5. Checkpoint — foundation is green
  - [x] 5.1 Run `bash tool/check_offline_imports.sh`, `dart run build_runner build --force-jit`, `flutter analyze`, and `flutter test`; confirm every existing suite plus the new domain / repository / service tests pass. Ensure all tests pass, ask the user if questions arise.
    - _Requirements: R14 AC6_
    - _Design: §14.5_

- [x] 6. Implement the text-plan parser, pretty-printer, and their tests
  - [x] 6.1 Implement the parser output shape in `lib/modules/program_management/services/text_plan/plan_draft.dart` (`PlanDraft`, `PlanDraftWorkoutDay`, `PlanDraftGroup`, `PlanDraftExercise`, `PlanDraftSet`) as freezed value types per design §6
    - _Requirements: R8 AC11, R9 AC1_
    - _Design: §6_

  - [x] 6.2 Implement `lib/modules/program_management/services/text_plan/plan_parse_error.dart` and `plan_parse_warning.dart` as freezed value types with the enums `PlanParseErrorCode` (`empty_input`, `unknown_line`, `missing_program_name`, `missing_workout_day`, `orphan_set_line`, `orphan_superset_marker`, `input_too_large`) and `PlanParseWarningCode` (`invalid_rest_token`, `unrecognized_trailing_token`)
    - _Requirements: R8 AC3, R8 AC7, R8 AC8, R8 AC9, R15 AC2_
    - _Design: §5.6_

  - [x] 6.3 Implement `lib/modules/program_management/services/text_plan/parse_result.dart` as a freezed sealed `ParseResult` with `success(PlanDraft draft, List<PlanParseWarning> warnings)` and `failure(PlanParseError error)` variants
    - _Requirements: R8 AC2, R8 AC8, R8 AC9_
    - _Design: §5.1_

  - [x] 6.4 Implement `lib/modules/program_management/services/text_plan/text_plan_parser.dart` exposing `TextPlanParser.parse(String input) → ParseResult` implementing the classifier (day header, superset marker, sets-by-reps, exercise name, blank separator) with 1-based line/column error positions, empty-input check, size cap `[1, 100_000]`, whitespace/line-ending/case tolerance per §5.5, and rest-token extraction (1..3600, suffix `s` or `m`); file imports only `dart:core`, `package:freezed_annotation`, and `package:zamaj/modules/domain/domain.dart`
    - _Requirements: R8 AC1, R8 AC2, R8 AC3, R8 AC4, R8 AC5, R8 AC6, R8 AC7, R8 AC8, R8 AC9, R8 AC10, R8 AC11, R13 AC2_
    - _Design: §5.2, §5.3, §5.4, §5.5, §5.6, §5.8_

  - [x] 6.5 Implement `lib/modules/program_management/services/text_plan/plan_pretty_printer.dart` exposing `PlanPrettyPrinter.print(PlanDraft draft) → String` that emits the canonical format defined in §5.7 (program name, day headers, superset markers, rep-based `<reps>x<count> <weight>kg`, time-based `<count>x<duration>s`, trailing `<rest>s`), deterministic, never referencing warnings; file imports only `dart:core` and the domain barrel
    - _Requirements: R10 AC1, R13 AC3_
    - _Design: §5.7, §5.8_

  - [x] 6.6 Write example-based parser tests in `test/modules/program_management/text_plan/text_plan_parser_test.dart` covering a rep-based plan, a time-based plan, a superset plan, a mixed plan with `4x8 100kg 2m`, an orphan set line, an unknown line, an empty input, a whitespace-only input, the `100_001` code-unit cap, and both `\n` / `\r\n` / bare-tail line endings; commit matching input fixtures under `test/modules/program_management/text_plan/golden/`
    - _Requirements: R8 AC1, R8 AC3, R8 AC4, R8 AC6, R8 AC8, R8 AC9_
    - _Design: §5.4, §14.3_

  - [x] 6.7 Write PBT `test/modules/program_management/text_plan/parse_print_roundtrip_property_test.dart`. **Property 1: parse → print → parse = parse.** Generate a `PlanDraft` via `anyPlanDraft(rng)`, pretty-print, re-parse, assert the re-parsed draft is `==` the original (warnings excluded). ≥100 iterations. **Validates: Requirement R10 AC1.**
    - _Requirements: R10 AC1_
    - _Design: §12.1, §12.2_

  - [x] 6.8 Write PBT `test/modules/program_management/text_plan/parser_determinism_property_test.dart`. **Property 2: parser determinism.** Generate a `Plan_Text`, invoke the parser twice in the same isolate, assert the returned `ParseResult` values compare equal (including warning list order in success case, error fields in failure case). ≥100 iterations. **Validates: Requirement R10 AC2.**
    - _Requirements: R10 AC2_
    - _Design: §12.1_

  - [x] 6.9 Write PBT `test/modules/program_management/text_plan/parser_tolerance_property_test.dart`. **Property 3: tolerance invariants.** Generate a `Plan_Text` P, derive P' by applying random combinations of whitespace collapse/expand, leading/trailing whitespace, `\n` / `\r\n` / `\r` swap, and case changes on keywords / unit suffixes / multiplication signs; assert `parse(P) == parse(P')`. ≥100 iterations. **Validates: Requirement R10 AC3.**
    - _Requirements: R10 AC3_
    - _Design: §12.1_

  - [x] 6.10 Write PBT `test/modules/program_management/text_plan/parser_error_determinism_property_test.dart`. **Property 5: error determinism.** Generate unparseable `Plan_Text` via `anyUnparseablePlanText(rng)`; invoke the parser multiple times; assert the returned `PlanParseError` has the same `line`, `column`, and `code` every time. ≥100 iterations. **Validates: Requirement R10 AC5.**
    - _Requirements: R10 AC5_
    - _Design: §12.1_

- [x] 7. Implement editor draft models, aggregate conversion, and save orchestrator
  - [x] 7.1 Implement `lib/modules/program_management/models/program_editor_draft.dart` with freezed `ProgramDraft`, `WorkoutDayDraft`, `ExerciseGroupDraft` (kind derived from `exercises.length`), `ExerciseDraft`, `PlannedSetDraft`, and sealed `PlannedSetDraftValues { repBased(weightInput, repsInput), timeBased(durationInput) }` holding raw-text inputs per design §4
    - _Requirements: R2 AC1, R2 AC6, R3 AC1, R4 AC2, R5 AC1, R5 AC3, R5 AC4, R5 AC8, R6 AC1, R7 AC1, R15 AC3, R15 AC4, R15 AC5, R15 AC6_
    - _Design: §4_

  - [x] 7.2 Implement `lib/modules/program_management/services/plan_draft_to_aggregate.dart` exposing `PlanDraftToAggregate.convert(PlanDraft draft, {required Uuid idGenerator, required AppClock clock}) → ProgramDraft` assigning fresh UUIDs to every draft identifier; pure, no I/O
    - _Requirements: R9 AC1, R9 AC2_
    - _Design: §6_

  - [x] 7.3 Implement `lib/modules/program_management/services/aggregate_saver.dart` exposing `AggregateSaver` that takes a `ProgramRepository`, turns a `ProgramDraft` into a `ProgramAggregate` via a pure helper on `ProgramDraft` (e.g. `ProgramDraft.toAggregate()`), and calls `programRepository.saveProgramAggregate(aggregate)`; on `DomainError` it surfaces the error without partial writes
    - _Requirements: R2 AC3, R2 AC4, R2 AC5, R2 AC6, R9 AC3, R9 AC5, R9 AC7_
    - _Design: §3.2, §8_

  - [x] 7.4 Write `test/modules/program_management/services/aggregate_saver_test.dart` covering happy-path save, `DomainError` propagation, and that the source `ProgramDraft` is not mutated after save
    - _Requirements: R2 AC4, R9 AC3, R9 AC5, R9 AC7_
    - _Design: §8_

  - [x] 7.5 Write PBT `test/modules/program_management/services/aggregate_saver_idempotence_property_test.dart`. **Property 7: AggregateSaver idempotence.** Generate a `ProgramAggregate`, save it twice against an in-memory `AppDatabase`, assert the two persisted `Program` aggregates are equal under freezed `==` except for `id`, `createdAt`, `updatedAt`, and `schemaVersion`. ≥100 iterations. **Validates: Design §12.3.**
    - _Requirements: R9 AC3_
    - _Design: §12.3_

  - [x] 7.6 Write PBT `test/modules/program_management/text_plan/save_load_roundtrip_property_test.dart`. **Property 4: save → load → print → parse = parse.** Generate a `PlanDraft`, convert to `ProgramDraft`, save via `AggregateSaver` on an in-memory `AppDatabase`, load via `ProgramRepository`, strip persistence ids to rebuild a `PlanDraft`, pretty-print, re-parse, assert `==`. ≥100 iterations. **Validates: Requirement R10 AC4.**
    - _Requirements: R10 AC4_
    - _Design: §12.1_

- [x] 8. Implement BLoCs in dependency order
  - [x] 8.1 Implement `ProgramListBloc` under `lib/modules/program_management/bloc/program_list/` with sealed `ProgramListEvent` / `ProgramListState` families, the deterministic tie-break sort in §3.1, and delete-with-confirmation flow; receive `ProgramRepository` and `SessionRepository` via constructor injection
    - _Requirements: R1 AC1, R1 AC2, R1 AC4, R1 AC5, R1 AC6, R1 AC7, R1 AC9, R1 AC10, R11 AC1, R11 AC5, R11 AC6, R12 AC3_
    - _Design: §3.1, §3.7_

  - [x] 8.2 Implement `ProgramEditorBloc` under `lib/modules/program_management/bloc/program_editor/` with create-mode and edit-mode flows: in-memory `ProgramDraft`, workout-day add/rename/delete/reorder, diff-based save on edit, single-shot atomic save on create via `AggregateSaver`, and typed validation states
    - _Requirements: R2 AC1, R2 AC2, R2 AC3, R2 AC4, R2 AC5, R2 AC6, R3 AC1, R3 AC2, R3 AC3, R3 AC4, R3 AC5, R3 AC6, R3 AC7, R3 AC8, R3 AC9, R3 AC10, R11 AC1, R11 AC2, R15 AC1_
    - _Design: §3.2, §3.7_

  - [x] 8.3 Implement `WorkoutDayEditorBloc` under `lib/modules/program_management/bloc/workout_day_editor/` with explicit group-save, cardinality-invariant handling (`single` requires 1 exercise, `superset` requires ≥2), exercise add/remove/reorder, and typed `GroupValidationError` state for cardinality violations
    - _Requirements: R4 AC1, R4 AC2, R4 AC3, R4 AC4, R4 AC5, R4 AC6, R4 AC7, R4 AC8, R11 AC1, R15 AC1_
    - _Design: §3.3, §3.7_

  - [x] 8.4 Implement `ExerciseEditorBloc` under `lib/modules/program_management/bloc/exercise_editor/` with measurement-type confirmation flow (reinitialize sets to zero-valued variant on confirm; preserve on cancel), planned-set count limit 1..20, planned-set field edits retaining raw text, planned-rest field, video-URL launch via `ExternalLinkLauncher`, and typed states for validation and launcher failure
    - _Requirements: R5 AC1, R5 AC2, R5 AC3, R5 AC4, R5 AC5, R5 AC6, R5 AC7, R5 AC8, R5 AC9, R5 AC10, R5 AC11, R6 AC1, R6 AC2, R6 AC3, R6 AC4, R6 AC5, R7 AC1, R7 AC2, R7 AC3, R7 AC4, R7 AC5, R7 AC6, R7 AC7, R7 AC8, R15 AC3, R15 AC4, R15 AC5, R15 AC6_
    - _Design: §3.4, §3.7_

  - [x] 8.5 Implement `PlanImportBloc` under `lib/modules/program_management/bloc/plan_import/` wrapping `TextPlanParser.parse`, emitting `Idle` / `Parsing` / `Failure(PlanParseError)` / `Success(PlanDraft, warnings)`, and retaining the user's raw text in every state
    - _Requirements: R8 AC1, R8 AC2, R8 AC3, R15 AC2_
    - _Design: §3.5, §3.7_

  - [x] 8.6 Implement `PlanPreviewBloc` under `lib/modules/program_management/bloc/plan_preview/` owning a `ProgramDraft` produced by `PlanDraftToAggregate`, delegating save to `AggregateSaver`, and emitting transactional failure states that preserve the user's edits
    - _Requirements: R9 AC1, R9 AC2, R9 AC3, R9 AC4, R9 AC5, R9 AC6, R9 AC7, R11 AC1, R11 AC2_
    - _Design: §3.6, §3.7_

- [ ] 9. Implement screens and navigation wiring
  - [ ] 9.1 Implement `lib/modules/program_management/navigation/program_management_routes.dart` with the six route-name constants, and `program_management_router.dart` exposing `ProgramManagementRouter.onGenerateRoute` that instantiates each screen with its `BlocProvider`; each provider pulls `ProgramRepository` / `SessionRepository` / `ExternalLinkLauncher` from `context.read<...>()`
    - _Requirements: R12 AC3, R14 AC2_
    - _Design: §1.3, §2.1, §2.3_

  - [ ] 9.2 Implement `lib/modules/program_management/screens/program_list_screen.dart` consuming `ProgramListBloc`, rendering `ProgramListTile`, zero-state with "create empty" and "import from text" CTAs, delete confirmation dialog, error-with-retry surface; all colors/spacing/typography via `Theme.of(context).appColors` and `AppSpacing.*`
    - _Requirements: R1 AC1, R1 AC3, R1 AC4, R1 AC5, R1 AC7, R1 AC8, R1 AC9_
    - _Design: §2.2_

  - [ ] 9.3 Implement `lib/modules/program_management/screens/program_editor_screen.dart` covering create-mode and edit-mode, `AppBar` inline-editable program name, `ReorderableListView` of workout days, add/rename/delete/reorder gestures, save button gated by validation
    - _Requirements: R2 AC1, R2 AC2, R2 AC6, R3 AC1, R3 AC3, R3 AC4, R3 AC5, R3 AC6, R3 AC7, R3 AC8, R3 AC9, R3 AC10_
    - _Design: §2.2, §15 decision 2_

  - [ ] 9.4 Implement `lib/modules/program_management/screens/workout_day_editor_screen.dart` with group cards (Single / Superset), add-group / add-exercise-to-group / delete / reorder affordances, inline cardinality error banner, and navigation to `ExerciseEditorScreen`
    - _Requirements: R4 AC1, R4 AC2, R4 AC3, R4 AC4, R4 AC5, R4 AC6, R4 AC7_
    - _Design: §2.2_

  - [ ] 9.5 Implement `lib/modules/program_management/screens/exercise_editor_screen.dart` with name field, `MeasurementTypeSelector`, `PlannedSetRow` list (rep-based fields or time-based field depending on measurement type), planned-rest field, notes / video-URL fields, video-URL tap that invokes `ExternalLinkLauncher.launch`, and a measurement-type-change confirmation dialog
    - _Requirements: R5 AC1, R5 AC2, R5 AC3, R5 AC4, R5 AC5, R5 AC6, R5 AC7, R5 AC8, R5 AC9, R5 AC10, R5 AC11, R6 AC1, R6 AC2, R6 AC3, R6 AC4, R7 AC1, R7 AC2, R7 AC3, R7 AC4, R7 AC5, R7 AC6, R7 AC7_
    - _Design: §2.2_

  - [ ] 9.6 Implement `lib/modules/program_management/screens/plan_import_screen.dart` with a multi-line `PlanTextInput` capped at 100 000 code units, a parse button enabled only at length ≥ 1, and a `PlanParseErrorBanner` that highlights the offending line based on 1-based line/column while preserving the user's raw text
    - _Requirements: R8 AC1, R8 AC2, R8 AC3, R15 AC2_
    - _Design: §2.2, §11_

  - [ ] 9.7 Implement `lib/modules/program_management/screens/plan_preview_screen.dart` rendering the same structure as `ProgramEditorScreen` over a `PlanPreviewBloc`, inlining warnings beside the affected element, exposing save and discard actions, and routing save success to `ProgramListScreen`
    - _Requirements: R9 AC1, R9 AC2, R9 AC3, R9 AC4, R9 AC5, R9 AC6, R9 AC7_
    - _Design: §2.2_

- [ ] 10. Wire bootstrap and app composition root
  - [ ] 10.1 Create `lib/bootstrap.dart` that calls `WidgetsFlutterBinding.ensureInitialized()`, opens `AppDatabase`, constructs `DriftProgramRepository` and `DriftSessionRepository` with an `AppClock`, and runs `MainApp`; create `lib/app.dart` that wires `MultiRepositoryProvider` with `ProgramRepository`, `SessionRepository`, `ExternalLinkLauncher`, a `MaterialApp` using `AppTheme.light()` / `AppTheme.dark()` / `ThemeMode.dark`, and `ProgramManagementRouter.onGenerateRoute` with `initialRoute: ProgramManagementRoutes.programList`; update `lib/main.dart` to call `bootstrap()`
    - _Requirements: R12 AC3, R13 AC4, R14 AC1_
    - _Design: §1.3, §2.1_

- [ ] 11. Implement the `url_launcher`-backed `ExternalLinkLauncher`
  - [ ] 11.1 Implement `lib/modules/program_management/services/url_launcher_external_link_launcher.dart` as the concrete `UrlLauncherExternalLinkLauncher implements ExternalLinkLauncher`, routing `youtube.com` / `youtu.be` / `m.youtube.com` / `www.youtube.com` through `LaunchMode.externalApplication` with fallback to the default browser, returning `ExternalLinkOpened` on success and `ExternalLinkFailure(reason)` on any failure; verify `check_offline_imports.sh` still passes (url_launcher is platform-channel-only)
    - _Requirements: R7 AC5, R7 AC8, R13 AC4_
    - _Design: §9, §13.3_

- [ ] 12. Final CI integration
  - [ ] 12.1 Re-verify `tool/check_offline_imports.sh` exits 0 on the full tree (including the new module and the `url_launcher` concrete impl); confirm the allowlist scan emits `<file>:<line>:<offending symbol>` for any hand-injected violation used as a smoke test
    - _Requirements: R12 AC5, R13 AC1, R13 AC2, R13 AC3_
    - _Design: §13.2_

  - [ ] 12.2 Run `flutter analyze`; fix every error, warning, and lint violation in `lib/modules/program_management/` until the analyzer reports zero issues across the new module
    - _Requirements: R14 AC4, R14 AC5, R14 AC6_
    - _Design: §14.5_

  - [ ] 12.3 Run `flutter test`; confirm every suite (existing domain / persistence / repository / serialization / integration plus the new module suites and property tests) passes green
    - _Requirements: R11 AC3, R11 AC4, R14 AC6_
    - _Design: §14.5_

- [ ] 13. Final checkpoint — program-management spec complete
  - [ ] 13.1 Run the full CI sequence locally (`bash tool/check_offline_imports.sh`, `dart run build_runner build --force-jit`, `flutter analyze`, `flutter test`) and confirm every task above is checked off. Ensure all tests pass, ask the user if questions arise.
    - _Requirements: R14 AC6_
    - _Design: §14.5_

## Notes

- Tasks marked with `*` are optional test tasks; they are still expected to
  land alongside the implementation they validate, per the project's PBT /
  unit-test conventions.
- **Testing scope:** Only domain-layer tests are in scope (unit, integration,
  property-based, serialization). BLoC tests, widget tests, and screen tests
  are not written.
- Core UI tokens (`lib/core/app_colors.dart`, `app_spacing.dart`,
  `app_typography.dart`, `app_theme.dart`) and the `ui-tokens.md` steering
  file are already in place. Every widget in tasks 9.x consumes them via
  `Theme.of(context).appColors`, `AppSpacing.*`, and
  `AppTypography.standard.*`; no task recreates them.
- `saveProgramAggregate` is an additive extension to the already-complete
  `core-domain-and-persistence` spec's public repository API (design §8,
  §15 decision 7). Tasks 3.1 / 3.3 own that extension.
- `plannedRestSeconds` is the only schema change in this spec. Tasks 2.1
  through 2.9 perform the extension, the migration, and the goldens /
  mapper coverage.
- The concrete `url_launcher` impl in task 11 is the only outbound boundary
  in the whole module; it is deliberately landed after screens so every
  other BLoC / screen depends only on the abstract `ExternalLinkLauncher`
  interface.

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3"] },
    { "id": 1, "tasks": ["2.1", "2.3", "2.4"] },
    { "id": 2, "tasks": ["2.2", "2.5", "2.6"] },
    { "id": 3, "tasks": ["2.7", "2.8", "2.9", "3.1", "3.2", "4.1", "4.3", "4.5"] },
    { "id": 4, "tasks": ["3.3", "4.2", "4.4", "6.1", "6.2", "6.3"] },
    { "id": 5, "tasks": ["3.4", "3.5", "6.4", "6.5", "7.1"] },
    { "id": 6, "tasks": ["6.6", "6.7", "6.8", "6.9", "6.10", "7.2", "7.3"] },
    { "id": 7, "tasks": ["7.4", "7.5", "7.6", "8.1", "8.2", "8.3", "8.4", "8.5", "8.6"] },
    { "id": 8, "tasks": ["9.1"] },
    { "id": 9, "tasks": ["9.2", "9.3", "9.4", "9.5", "9.6", "9.7"] },
    { "id": 10, "tasks": ["10.1"] },
    { "id": 11, "tasks": ["11.1"] },
    { "id": 12, "tasks": ["12.1"] },
    { "id": 13, "tasks": ["12.2"] },
    { "id": 14, "tasks": ["12.3"] }
  ]
}
```

## Workflow Completion

This workflow only creates planning artifacts. Implementation of the tasks
above is out of scope for this workflow. To begin execution, open this
`tasks.md` file and click **Start task** next to any item.
