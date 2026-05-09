# Implementation Plan: Core Domain and Persistence

## Overview

This plan turns `design.md` into an incremental, test-first Dart/Flutter
implementation. Work proceeds bottom-up: core utilities → leaf sealed
families → domain aggregates → serialization coverage → abstract repository
contracts → Drift schema → mapping layer → concrete repositories →
integration and property tests → CI wiring.

Property-based tests for the ten named properties in `design.md` §9 (P1–P10)
are required. Each property has its own sub-task tied to the requirement
clauses it validates. Golden JSON fixtures for every sealed variant are also
required. All supplementary smoke / edge-case unit tests are likewise
required — nothing in this plan is optional.

Every task leaves the tree compiling and the test suite green. Checkpoints
are inserted at natural integration boundaries.

Conventions used throughout:
- The domain `Set` type is implemented as **`WorkoutSet`**.
- PBT is implemented using **`flutter_test`'s built-in `test` runner** with custom `Random`-based generator functions in `test/support/generators.dart` — no third-party PBT library is used because `glados`, `kiri_check`, and similar packages all conflict with `drift_dev`'s transitive `analyzer` constraint under Flutter 3.38.x / Dart 3.10.4. Each property test runs at least **100 iterations** via a `for` loop.
- Layers under `lib/core/**`, `lib/modules/domain/**`,
  `lib/modules/persistence/**` are forbidden from importing network
  packages (design §2, Req 12).

## Tasks

- [x] 1. Set up project dependencies, lint, and module scaffolding
  - [x] 1.1 Add runtime and dev dependencies to `pubspec.yaml` (`freezed_annotation`, `json_annotation`, `drift`, `drift_flutter`, `path_provider`, `path`, `uuid`, `clock`, `crypto`; dev: `build_runner`, `freezed`, `json_serializable`, `drift_dev`) and run `flutter pub get` to confirm resolution — `drift_flutter` replaces the EOL `sqlite3_flutter_libs` and handles cross-platform SQLite setup; no separate `test` or PBT package is added because `flutter_test` from the SDK provides the test runner and `drift_dev`'s `analyzer` constraint blocks all third-party PBT packages (Reqs 9.1, 11.1; Design §2, §3)
  - [x] 1.2 Skip: `bloc_test` cannot be added as a dev dependency because it conflicts with `drift_dev`'s transitive `analyzer` constraint under Flutter 3.38.x — it will be added in a future spec once the Flutter SDK pins are updated (Design §3)
  - [x] 1.3 Tighten `analysis_options.yaml` with `strict-casts`, `strict-inference`, `strict-raw-types`, and the project style rules from `init.md` (Design §2)
  - [x] 1.4 Add `build.yaml` configuring `freezed`, `json_serializable`, and `drift_dev` builders and confirm `dart run build_runner build` exits cleanly on an empty tree (Reqs 9.1, 11.1; Design §3)
  - [x] 1.5 Create the module scaffolding: `lib/core/`, `lib/modules/domain/models/`, `lib/modules/domain/repositories/`, `lib/modules/persistence/database/`, `lib/modules/persistence/mappers/`, `lib/modules/persistence/repositories/`, `test/support/`, `test/domain/`, `test/serialization/`, `test/repository/`, `test/integration/`, plus empty barrel files `domain.dart` and `persistence.dart` (Design §3)
  - [x] 1.6 Add `tool/check_offline_imports.sh` that greps `lib/core/**`, `lib/modules/domain/**`, `lib/modules/persistence/**` for forbidden imports (`dart:io` network APIs, `package:http`, `package:dio`, `package:web_socket_channel`, `package:grpc`, `package:socket_io_client`) and exits non-zero on any match; document invocation in `README.md` (Reqs 12.1, 12.2, 12.3; Design §2)

- [x] 2. Build core infrastructure primitives
  - [x] 2.1 Implement `lib/core/clock.dart` wrapping `package:clock` with a thin `AppClock` abstraction that exposes `DateTime nowUtc()` (Design §6.5)
  - [x] 2.2 Implement `lib/core/schema_versions.dart` with `SchemaVersions.drift = 1` and `SchemaVersions.domain = 1` as the single source of truth and a private constructor that prevents instantiation (Reqs 8.5, 9.3; Design §5.4)
  - [x] 2.3 Implement `lib/core/canonical_json.dart` exposing `CanonicalJson.encode(Object?)` with sorted keys, RFC 8259 escaping, deterministic number formatting, and rejection of `NaN`/`±Infinity`, plus `CanonicalJson.sha256Hex(String)` using `package:crypto` (Reqs 6.1, 6.3, 11.1; Design §5.3, §7.4)
  - [x] 2.4 Write PBT in `test/core/canonical_json_property_test.dart` covering **determinism**, **round-trip compatibility**, and **idempotence** per Design §5.3 with at least 100 iterations using custom `Random`-based generators (Reqs 6.3; Design §5.3, §10.1)
  - [x] 2.5 Add example-based unit tests for `CanonicalJson` covering NaN/Infinity rejection, deeply nested maps, Unicode strings, and empty containers (Design §5.3)
  - [x] 2.6 Implement `lib/core/app_error.dart` exposing a top-level `AppError` marker interface (cross-cutting; BLoCs and future features will extend it) (Design §2, §8)

- [ ] 3. Define the `DomainError` hierarchy
  - [ ] 3.1 Implement `lib/modules/domain/errors.dart` with a sealed `DomainError implements Exception` base and the final subclasses `ValidationError`, `ImmutabilityError`, `OrderingError`, `VersionMismatchError`, `DeserializationError`, `NotFoundError`, matching field shapes in Design §8 (Reqs 2.5, 3.4, 6.5, 7.3, 9.5, 11.4, 13.4; Design §8)
  - [ ] 3.2 Add unit tests that instantiate each error subclass and verify its `message` composition and typed fields (Design §8)

- [ ] 4. Implement leaf sealed families with JSON round-trip
  - [ ] 4.1 Implement `lib/modules/domain/models/measurement_type.dart` as `@Freezed(unionKey: 'type')` with `repBased` and `timeBased` variants and generated `fromJson`/`toJson`; regenerate with `build_runner` (Reqs 2.1, 2.4, 11.1, 11.3; Design §4.2, §7.2)
  - [ ] 4.2 Implement `lib/modules/domain/models/exercise_group_kind.dart` as `@Freezed(unionKey: 'type')` with `single` and `superset` variants (Reqs 3.1, 3.5, 11.1, 11.3; Design §4.3, §7.2)
  - [ ] 4.3 Implement `lib/modules/domain/models/substitute_exercise.dart` carrying `name`, `measurementType`, optional `metadata`, then `lib/modules/domain/models/exercise_state.dart` as `@Freezed(unionKey: 'type')` with `unfinished`, `completed`, `skipped`, and `replaced({ required SubstituteExercise substitute })` variants (Reqs 4.4, 5.1, 5.2, 5.4, 11.3; Design §4.9)
  - [ ] 4.4 Implement `lib/modules/domain/models/planned_set_values.dart` and `lib/modules/domain/models/actual_set_values.dart` as parallel `@Freezed(unionKey: 'type')` families with `repBased({weightKg, reps})` and `timeBased({durationSeconds})` variants, enforcing Req 4.7 hard separation (Reqs 2.2, 2.3, 4.7, 11.3; Design §4.6)
  - [ ] 4.5 Add `test/support/generators.dart` with plain Dart generator functions (using `dart:math` `Random`) for `anyUuidV4`, `anyUtcDateTime`, `anyMeasurementType`, `anyExerciseGroupKind`, `anyExerciseState`, `anyPlannedSetValues`, `anyActualSetValues`, `anySubstituteExercise` — no third-party PBT library; each generator returns a single random value and is called in a loop of ≥100 iterations inside standard `test()` blocks (Design §10.4)
  - [ ] 4.6 Write PBT in `test/serialization/leaf_families_round_trip_test.dart` — one test per sealed family — asserting `T.fromJson(v.toJson()) == v` for at least 100 iterations using the generators from `test/support/generators.dart`. **Property 9: JSON round-trip.** **Validates: Reqs 11.2, 11.5** (Reqs 11.2, 11.5; Design §7.1, §9 P9)
  - [ ] 4.7 Write PBT in `test/serialization/leaf_families_corruption_test.dart` using a custom `anyCorruption` generator function (dropping any required field or rewriting any discriminator to a non-whitelisted string) and assert `DeserializationError` with the offending field/discriminator named, run for at least 100 iterations. **Property 10: Typed deserialization error naming.** **Validates: Reqs 2.5, 11.4** (Reqs 2.5, 3.5, 11.4; Design §7.2, §9 P10)
  - [ ] 4.8 Commit golden JSON fixtures under `test/serialization/golden/` — one per variant of `MeasurementType`, `ExerciseGroupKind`, `ExerciseState`, `PlannedSetValues`, `ActualSetValues` — and a test that byte-compares `toJson` output against each fixture to lock the wire format (Reqs 2.4, 3.5, 11.3; Design §10.3)

- [ ] 5. Implement template-side domain aggregates with invariants
  - [ ] 5.1 Implement `lib/modules/domain/models/exercise_metadata.dart` with nullable `notes` and `videoUrl` plus `ExerciseMetadata.empty` constant (Req 1.6; Design §4.5)
  - [ ] 5.2 Implement `lib/modules/domain/models/workout_set.dart` (`WorkoutSet`) with the factory that invokes a private `WorkoutSetInvariants.validate` enforcing: variant of `plannedValues` matches `measurementType`; non-negative fields; `weightKg` multiple of `0.5` verified by integer-scaled check; throwing `ValidationError` on failure (Reqs 1.5, 2.2, 2.3, 13.3, 13.4; Design §4.5, §4.11)
  - [ ] 5.3 Implement `lib/modules/domain/models/exercise.dart` with a factory that validates every nested `WorkoutSet.measurementType` equals the exercise's `measurementType`, throwing `ValidationError` on mismatch (Reqs 1.4, 4.7, 13.3; Design §4.5, §4.11)
  - [ ] 5.4 Implement `lib/modules/domain/models/exercise_group.dart` with an `ExerciseGroupInvariants.validate` that enforces `single ⇒ exercises.length == 1` and `superset ⇒ exercises.length ≥ 2`, throwing `ValidationError` naming the violated rule (Reqs 1.3, 3.2, 3.3, 3.4, 13.1, 13.4; Design §4.5, §4.11)
  - [ ] 5.5 Implement `lib/modules/domain/models/workout_day.dart` carrying its ordered `List<ExerciseGroup>` (Reqs 1.2; Design §4.4)
  - [ ] 5.6 Implement `lib/modules/domain/models/program.dart` carrying ordered `workoutDayIds` and the `assert(id.length == 36)` UUID shape check (Reqs 1.1, 8.1; Design §4.4)
  - [ ] 5.7 Extend `test/support/generators.dart` with `anyExerciseMetadata`, `anyWorkoutSet(measurementType)`, `anyExercise`, `anyExerciseGroup`, `anyWorkoutDay`, `anyProgram`, plus an adversarial `anyInconsistentExercise` generator used by negative tests — all plain Dart functions using `dart:math` `Random` (Design §10.4)
  - [ ] 5.8 Write PBT in `test/domain/workout_set_construction_test.dart` — succeeds iff variant matches and values are valid; every failure raises `ValidationError` with `entityId` = set id and a machine-readable `invariant` code. **Property 1: WorkoutSet / ExecutedSet value consistency.** **Validates: Reqs 1.5, 2.2, 2.3, 4.3, 4.7, 13.3, 13.4** (Reqs 1.5, 2.2, 2.3, 4.3, 4.7, 13.3, 13.4; Design §9 P1)
  - [ ] 5.9 Write PBT in `test/domain/exercise_group_construction_test.dart` covering both cardinality branches and asserting the `ValidationError.invariant` code names the violated rule. **Property 2: ExerciseGroup cardinality.** **Validates: Reqs 3.2, 3.3, 3.4, 13.1, 13.4** (Reqs 3.2, 3.3, 3.4, 13.1, 13.4; Design §9 P2)
  - [ ] 5.10 Add example-based unit tests for `Exercise.measurementType` ↔ set consistency and `Program` UUID length assertion (Reqs 1.4, 1.1; Design §4.5, §4.4)

- [ ] 6. Implement session-side domain aggregates with invariants
  - [ ] 6.1 Implement `lib/modules/domain/models/executed_set.dart` with factory validation mirroring `WorkoutSet` (variant match, non-negativity, 0.5 kg resolution) and throwing `ValidationError` (Reqs 4.3, 4.7, 13.3, 13.4; Design §4.9, §4.11)
  - [ ] 6.2 Implement `lib/modules/domain/models/session_exercise.dart` with non-nullable `plannedExerciseIdInSnapshot` and `List<ExecutedSet> executedSets`; rely on `ExerciseState.replaced` to carry the substitute payload at the type level (Reqs 4.2, 5.1, 5.2, 5.4, 13.2; Design §4.9)
  - [ ] 6.3 Implement `lib/modules/domain/models/session_note.dart` (Req 4.5; Design §4.10)
  - [ ] 6.4 Implement `lib/modules/domain/models/extra_work.dart` with a freeform `body` string and a `// TODO(extra-work-typing):` comment documenting the future typed variants (Req 4.6; Design §4.10, §12 resolved decision 10)
  - [ ] 6.5 Implement `lib/modules/domain/models/session_snapshot.dart` with `workoutDay`, `canonicalJson`, `sha256Hash`, `capturedAt`, `schemaVersion`, and a construction invariant that recomputes `sha256(canonicalJson)` and re-encodes `workoutDay.toJson()` through `CanonicalJson.encode`, raising `ValidationError` on mismatch (Reqs 6.1, 6.3, 6.5; Design §4.8, §4.11)
  - [ ] 6.6 Implement `lib/modules/domain/models/session.dart` carrying the snapshot, ordered `sessionExercises`, notes, extra work, `startedAt`, optional `endedAt`, and standard timestamp/schemaVersion fields (Req 4.1; Design §4.7)
  - [ ] 6.7 Add `lib/modules/domain/domain.dart` barrel export for all domain models and errors (Design §3)
  - [ ] 6.8 Extend `test/support/generators.dart` with `anyExecutedSet`, `anySessionExercise`, `anySessionNote`, `anyExtraWork`, `anySessionSnapshot`, `anySession` — all plain Dart functions using `dart:math` `Random` (Design §10.4)
  - [ ] 6.9 Write PBT in `test/domain/replacement_invariant_test.dart` covering both the sealed-encoding construction level and the JSON boundary (round-trip a `replaced` variant and verify substitute survives; corrupt a non-`replaced` payload to include a substitute and assert `DeserializationError`). **Property 3: Replacement invariant.** **Validates: Reqs 4.2, 5.1, 5.2, 5.4, 5.5, 13.2** (Reqs 4.2, 5.1, 5.2, 5.4, 5.5, 13.2; Design §4.9, §9 P3)
  - [ ] 6.10 Extend `test/serialization/leaf_families_round_trip_test.dart` (or add `aggregate_round_trip_test.dart`) so that Property 9 covers `Program`, `WorkoutDay`, `ExerciseGroup`, `Exercise`, `WorkoutSet`, `ExerciseMetadata`, `Session`, `SessionSnapshot`, `SessionExercise`, `ExecutedSet`, `SessionNote`, `ExtraWork`, `SubstituteExercise` (Reqs 11.2, 11.5; Design §9 P9)
  - [ ] 6.11 Extend the corruption PBT (or add `aggregate_corruption_test.dart`) so that Property 10 covers aggregate-level `DeserializationError` naming for every aggregate type above (Reqs 2.5, 11.4; Design §9 P10)
  - [ ] 6.12 Commit golden JSON fixtures for one canonical instance of each aggregate type and byte-compare against `toJson` output (Design §10.3)

- [ ] 7. Define the abstract repository contracts
  - [ ] 7.1 Implement `lib/modules/domain/repositories/program_repository.dart` as an `abstract class ProgramRepository` exposing the methods listed in Design §6.2, typed solely in domain terms (Reqs 10.1, 10.3, 10.6; Design §6.2)
  - [ ] 7.2 Implement `lib/modules/domain/repositories/session_repository.dart` as an `abstract class SessionRepository` exposing the methods listed in Design §6.3, typed solely in domain terms (Reqs 10.2, 10.4, 10.6; Design §6.3)
  - [ ] 7.3 Add `test/domain/repository_contract_purity_test.dart` that imports both abstract repositories and statically asserts the barrel imports no Drift types — the test file itself must not import `package:drift/drift.dart` nor reference any generated Drift table (Reqs 10.1, 10.2; Design §10.3)

- [ ] 8. Checkpoint — domain layer complete
  - [ ] 8.1 Run `dart run build_runner build --delete-conflicting-outputs`, run `flutter analyze`, and run `flutter test` to confirm every domain and serialization test passes. Ensure all tests pass, ask the user if questions arise. (Reqs 11.1, 11.2, 11.4, 13.4; Design §10.1)

- [ ] 9. Build the Drift schema and database
  - [ ] 9.1 Implement `lib/modules/persistence/database/tables.dart` declaring `Programs`, `ProgramWorkoutDays`, `WorkoutDays`, `ExerciseGroups`, `Exercises`, `Sets`, `Sessions`, `SessionExercises`, `ExecutedSets`, `SessionNotes`, `ExtraWorkItems` with primary keys, unique `(parent_id, position)` constraints, `onDelete: KeyAction.cascade` on every template FK, and `sessions.workoutDayId` as a plain column with **no FK** (Reqs 9.1, 9.6; Design §5.1, §12 resolved decision 8)
  - [ ] 9.2 Implement `lib/modules/persistence/database/app_database.dart` with `@DriftDatabase(tables: [...])`, `schemaVersion = SchemaVersions.drift`, and a `MigrationStrategy` whose `beforeOpen` enables `PRAGMA foreign_keys = ON` and raises `VersionMismatchError(persisted, expected)` when `details.versionBefore > schemaVersion` (Reqs 9.2, 9.3, 9.4, 9.5, 9.6; Design §5.5)
  - [ ] 9.3 Implement `lib/modules/persistence/database/migrations.dart` with an empty v1 `onUpgrade` body plus the documented pattern for future `if (from < N)` branches (Req 9.4; Design §5.5)
  - [ ] 9.4 Run `dart run build_runner build --delete-conflicting-outputs` to generate `app_database.g.dart`; commit the generated file per project convention and verify it compiles (Reqs 9.1; Design §5.1)
  - [ ] 9.5 Add a unit test that opens an in-memory `AppDatabase` and asserts `PRAGMA foreign_keys` returns `1` (Req 9.6; Design §5.5)

- [ ] 10. Implement the mapping layer
  - [ ] 10.1 Implement `lib/modules/persistence/mappers/program_mapper.dart` and `workout_day_mapper.dart` converting between Drift `Programs`/`WorkoutDays`/`ExerciseGroups`/`Exercises`/`Sets` rows and their domain counterparts; discriminator+payload columns go through `CanonicalJson.encode` on write and `jsonDecode` + typed `fromJson` on read (Reqs 2.6, 3.6, 11.1; Design §5.1, §7.2)
  - [ ] 10.2 Implement `lib/modules/persistence/mappers/session_mapper.dart` mapping `Sessions`, `SessionExercises`, `ExecutedSets`, `SessionNotes`, `ExtraWorkItems` rows; the session mapper reconstructs the typed `SessionSnapshot` by parsing `snapshotJson` and recomputing the hash, raising `DeserializationError(field: "sessionSnapshot")` on mismatch (Reqs 6.3, 11.1, 11.4; Design §4.8, §7.4)
  - [ ] 10.3 Add `lib/modules/persistence/persistence.dart` barrel export and wire Drift millisecond ↔ UTC `DateTime` conversion utilities (Design §6.6)
  - [ ] 10.4 Add mapper round-trip unit tests (one per mapper) confirming `toRow(toDomain(row)) == row` on representative fixtures (Design §7.1, §10.3)

- [ ] 11. Implement `DriftProgramRepository`
  - [ ] 11.1 Implement `lib/modules/persistence/repositories/drift_program_repository.dart`'s program-level CRUD (`createProgram`, `getProgram`, `listPrograms`, `updateProgram`, `deleteProgram`) with UUIDv4 generation via `package:uuid`, `SchemaVersions.domain` stamping, and transactional writes (Reqs 8.1, 8.2, 8.3, 8.5, 10.3, 10.5; Design §6.1, §6.7)
  - [ ] 11.2 Implement the shared `_nextUpdatedAt` timestamp helper per Design §6.5 (injected `AppClock`, monotonic non-decreasing, bounded below by `createdAt` and previous `updatedAt`) and route every repository write through it (Reqs 8.3, 8.4; Design §6.5)
  - [ ] 11.3 Implement aggregate-load for workout days: `getWorkoutDay`, `listWorkoutDaysForProgram`, using the four-query `IN`-clause fan-out in Design §6.1; never return partial aggregates (Reqs 10.3, 10.6; Design §6.1)
  - [ ] 11.4 Implement exercise-group / exercise / set CRUD and the four `reorder*` methods, assigning positions with the gap-based algorithm from Design §6.4 and re-validating aggregate invariants on the returned value (Reqs 1.3, 1.4, 1.5, 3.4, 13.1, 13.3; Design §6.2, §6.4)
  - [ ] 11.5 Add complementary unit tests for edge cases: deleting a program cascades to every child row; reordering rejects unknown ids (Req 9.6; Design §6.4)

- [ ] 12. Implement `DriftSessionRepository`
  - [ ] 12.1 Implement `startSession`: in one transaction, load the target `WorkoutDay` aggregate, canonicalize `workoutDay.toJson()` via `CanonicalJson.encode`, compute the sha256 hex, insert a `Sessions` row with `snapshotJson` + `snapshotHash`, and pre-seed one `SessionExercises` row per planned `Exercise` in snapshot order — flattening any superset `ExerciseGroup` into one `SessionExercise` per contained `Exercise` (Reqs 4.1, 4.2, 6.1, 6.2, 6.4, 10.4; Design §4.7, §4.8, §6.3, §12 resolved decision 5)
  - [ ] 12.2 Implement `getSession` and `listSessionsForWorkoutDay` as full aggregate loads that rehydrate the snapshot via the session mapper and re-verify the sha256 hash on every read (Reqs 6.3, 10.4, 10.6; Design §6.1, §7.4)
  - [ ] 12.3 Implement `completeSet` and `updateExecutedSet`: both go through `_nextUpdatedAt`, validate `actualValues` against the owning session exercise's `measurementType`, and on the final planned set of a `SessionExercise` transition the exercise to `completed` using the position-locking rules from Design §6.4 (Reqs 4.3, 4.7, 7.1, 7.4, 7.5, 8.3, 8.4, 13.3; Design §6.3, §6.4)
  - [ ] 12.4 Implement `skipExercise` and `replaceExercise`: both lock the target's position per Design §6.4; `replaceExercise` writes the substitute payload into `SessionExercises.substitutePayloadJson` and performs **no writes to any template table** (Reqs 5.1, 5.2, 5.3, 5.4, 7.1, 7.4; Design §6.3, §6.4)
  - [ ] 12.5 Implement `reorderUnfinished` rejecting any id whose persisted state is not `unfinished` with `OrderingError(sessionExerciseId, currentState)`; otherwise renumber as `maxLockedPos + (i + 1) * G` with `G = 1024` inside a transaction (Reqs 7.2, 7.3, 7.5; Design §6.4)
  - [ ] 12.6 Implement `endSession`, `addSessionNote`, `addExtraWork` respecting timestamp monotonicity (Reqs 4.1, 4.5, 4.6, 8.3, 8.4; Design §6.3, §6.5)

- [ ] 13. Checkpoint — repositories complete
  - [ ] 13.1 Run `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, and `flutter test`; confirm the full existing suite is green before moving to repository-level PBT. Ensure all tests pass, ask the user if questions arise. (Design §10.1)

- [ ] 14. Add repository-level test support
  - [ ] 14.1 Extend `test/support/generators.dart` with `anyProgramRepoOpSequence` (mix of create/update/delete/reorder template ops), `anySessionRepoOpSequence` (biased toward state transitions), `anyCorruption(Map<String, dynamic>)`, and `RegressingClock` fake — all plain Dart using `dart:math` `Random`, no third-party PBT library (Design §10.4)
  - [ ] 14.2 Add `test/support/in_memory_app_database.dart` helper that opens a fresh `AppDatabase` backed by `NativeDatabase.memory()` per test with `setUp` / `tearDown` plumbing (Design §10.1)

- [ ] 15. Write repository-level property-based tests
  - [ ] 15.1 Write PBT in `test/repository/replacement_no_template_mutation_test.dart`: snapshot every template-table row before a random `replaceExercise` sequence, run the sequence, diff every row byte-for-byte afterward and assert equality. **Property 4: Replacement does not mutate templates.** **Validates: Req 5.3** (Req 5.3; Design §9 P4)
  - [ ] 15.2 Write PBT in `test/repository/snapshot_immutability_test.dart`: capture a snapshot on `startSession`, run an arbitrary `anyProgramRepoOpSequence` against the source `WorkoutDay` and its descendants, then assert (i) `snapshot.canonicalJson == CanonicalJson.encode(initialWorkoutDay.toJson())`, (ii) subsequent `getSession` reads return the same bytes, (iii) the sha256 hash still matches. **Property 5: Snapshot fidelity and byte-stability.** **Validates: Reqs 6.1, 6.3** (Reqs 6.1, 6.3; Design §9 P5)
  - [ ] 15.3 Write PBT in `test/repository/position_order_test.dart` running `anySessionRepoOpSequence` and checking the four clauses of P6: distinct positions; locked strictly below unfinished; locked positions frozen across transitions; `reorderUnfinished` targeting a locked id raises `OrderingError` and leaves the session unchanged. **Property 6: Position total-order invariant.** **Validates: Reqs 7.1, 7.2, 7.3, 7.4, 7.5** (Reqs 7.1, 7.2, 7.3, 7.4, 7.5; Design §9 P6)
  - [ ] 15.4 Write PBT in `test/repository/identity_invariants_test.dart` running random template and session write sequences and asserting every persisted row's `id` is a canonical 36-char UUIDv4, every `schema_version` column equals `SchemaVersions.domain`, and the union of all id values is globally unique across tables. **Property 7: Identity invariants.** **Validates: Reqs 8.1, 8.5, 8.6, 8.7** (Reqs 8.1, 8.5, 8.6, 8.7; Design §9 P7)
  - [ ] 15.5 Write PBT in `test/repository/timestamp_monotonicity_test.dart` using `RegressingClock` to feed arbitrary non-monotonic times into repository writes, then verify per-row `createdAt` is stable post-insert and every subsequent `updatedAt` is ≥ previous `updatedAt` and ≥ `createdAt`. **Property 8: Timestamp monotonicity under arbitrary clocks.** **Validates: Reqs 8.3, 8.4** (Reqs 8.3, 8.4; Design §9 P8)

- [ ] 16. Write targeted integration tests
  - [ ] 16.1 Write `test/integration/version_mismatch_test.dart` that opens an in-memory DB, forges the persisted `user_version` PRAGMA to `SchemaVersions.drift + 1`, reopens, and asserts `VersionMismatchError(persisted, expected)` with both integers present (Req 9.5; Design §5.5, §10.3)
  - [ ] 16.2 Write `test/integration/foreign_keys_test.dart` covering one insert-without-parent failure and one cascade-delete success for each template FK relationship (`programs→program_workout_days`, `program_workout_days→workout_days`, `workout_days→exercise_groups`, `exercise_groups→exercises`, `exercises→sets`, `sessions→session_exercises`, `session_exercises→executed_sets`, `sessions→session_notes`, `sessions→extra_work_items`) (Req 9.6; Design §5.1, §10.3)
  - [ ] 16.3 Write `test/integration/snapshot_hash_mismatch_test.dart` that opens a session, mutates the stored `snapshotJson` bytes via a raw Drift statement to desync the hash, and asserts `getSession` raises `DeserializationError(field: "sessionSnapshot", discriminator: "sha256Hash")` (Req 6.3; Design §7.4, §10.3)
  - [ ] 16.4 Add `test/integration/soft_ref_survives_workout_day_delete_test.dart` verifying that deleting a source `WorkoutDay` leaves any `Session` referencing it readable (Reqs 6.2, 6.3; Design §4.7, §5.1, §12 resolved decision 8)

- [ ] 17. Wire CI and finalize
  - [ ] 17.1 Add a GitHub-Actions-style workflow file (or equivalent task runner script referenced from `README.md`) that runs, in order, `bash tool/check_offline_imports.sh`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test` (Reqs 9.1, 11.1, 12.1, 12.2, 12.3; Design §2, §10.3)
  - [ ] 17.2 Update `README.md` with a short "Core domain and persistence" section describing the module layout, how to run codegen, how to run the PBT suite, and how to invoke the import-allowlist script (Design §2, §3)

- [ ] 18. Final checkpoint — spec complete
  - [ ] 18.1 Run the full CI sequence locally (`bash tool/check_offline_imports.sh`, `dart run build_runner build --delete-conflicting-outputs`, `flutter analyze`, `flutter test`) and confirm every task above is checked off. Ensure all tests pass, ask the user if questions arise. (Design §10)

## Notes

- Every task in this plan is mandatory. Property-based tests (P1–P10),
  golden JSON fixtures, and supplementary unit tests are all required.
- Each task references the specific requirements and design sections it
  implements for traceability.
- Checkpoints (tasks 8, 13, 18) gate progress at natural integration
  boundaries.
- Property tests P1, P2, P3, P9, P10 depend only on the domain and
  serialization layers and land in tasks 4, 5, 6. Property tests P4, P5, P6,
  P7, P8 depend on the repository layer and land in task 15.
- No task in this spec implements UI, BLoCs, the session flow engine, rest
  timer, parser, export, or cloud sync. Those are follow-up specs that will
  consume the abstract contracts defined in task 7.

## Workflow Completion

This workflow only creates planning artifacts. Implementation of the tasks
above is out of scope for this workflow. To begin execution, open this
`tasks.md` file and click **Start task** next to any item.
