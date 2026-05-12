# Domain Layer Code Review — `lib/modules/domain`

**Scope.** Every file under `lib/modules/domain/` (models, repositories, services, errors, barrel). Generated `*.freezed.dart` / `*.g.dart` files are excluded.

**Rubric.** Effective Dart, Dart 3 sealed/pattern‑matching idioms, Freezed v3 best practices, Clean‑Architecture domain‑layer guidelines, and the project's own `analysis_options.yaml` (which already enables `strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `avoid_type_to_string`, etc.).

---

## TL;DR

This is an unusually disciplined domain layer for a Flutter codebase: Freezed sealed unions with `unionKey: 'type'`, invariant validation in private constructor bodies, a `DomainError` sealed exception hierarchy, a stateless `SessionFlowEngine` that round‑trips every mutation through a repository, deterministic canonical JSON snapshots with SHA‑256 hashing, and broad property‑based test coverage. The architecture is sound.

The findings below are mostly about **sharp edges, consistency, and one outright fake test**, not about the architecture itself.

Severity legend: 🔴 critical · 🟠 high · 🟡 medium · 🟢 low / nit.

---

## 1. What's done well

These are worth keeping; future modules should imitate them.

1. **Dart 3 sealed unions everywhere they make sense.** `MeasurementType`, `PlannedSetValues`, `ActualSetValues`, `ExerciseGroupKind`, `ExerciseState`, `Cursor`, and `DomainError` are all sealed. Combined with the analyzer's exhaustiveness checking, this gives compile‑time guarantees that every consumer handles every variant. Pattern matching is used idiomatically:

```513:522:lib/modules/domain/services/session_flow_engine.dart
  ActualSetValues _convertPlannedToActual(PlannedSetValues planned) {
    return switch (planned) {
      PlannedRepBased(:final weightKg, :final reps) => ActualSetValues.repBased(
        weightKg: weightKg,
        reps: reps,
      ),
      PlannedTimeBased(:final durationSeconds) => ActualSetValues.timeBased(
        durationSeconds: durationSeconds,
      ),
    };
  }
```

2. **Invariants live in the private constructor body** (`Exercise._()`, `WorkoutSet._()`, `ExecutedSet._()`, `ExerciseGroup._()`, `SessionSnapshot._()`). This is the canonical Freezed idiom for guarded factories and means the type system itself refuses to construct invalid instances — no opportunity for callers to skip validation.

3. **Errors are a sealed hierarchy with structured payloads.** `ValidationError.invariant`, `OrderingError.currentState`, `NotFoundError.entityType`, etc. are perfect for telemetry, UI mapping, and tests. `final class` subtypes correctly prevent further extension. Every error carries enough context for a user‑facing message *and* a programmatic match.

4. **Repository contracts are typed purely in domain terms.** Both `ProgramRepository` and `SessionRepository` mention only Freezed domain models — no Drift `Companion`, `RowClass`, or `DatabaseConnection` leak. The barrel `domain.dart` re‑exports cleanly with no transitive infrastructure dependency.

5. **`SessionFlowEngine` is stateless and explicit.** Every mutation reads → validates → delegates to the repository → recomputes a `SessionState` envelope (`session`, `cursor`, `suggestedValues`). The engine is trivially testable in isolation against a fake repository, which the test suite exploits well.

6. **Deterministic snapshots.** `SessionSnapshot._()` recomputes the canonical JSON *and* the SHA‑256 hash inside the constructor and rejects mismatches. The static `SessionSnapshot.capture` factory is the right ergonomic complement. Excellent forensic property for an audit‑heavy fitness app.

7. **`AppClock` is injected** rather than calling `DateTime.now()` directly, so tests can pin the clock. The test in `session_flow_engine_test.dart` uses `Clock.fixed` cleanly.

8. **Centralised `SchemaVersions`** removes the temptation to sprinkle magic numbers throughout the layer.

9. **Strict analyzer settings.** `strict-casts`, `strict-inference`, `strict-raw-types`, `avoid_dynamic_calls`, `unawaited_futures`, `avoid_type_to_string`, `prefer_const_constructors`, etc. are all on. `dart analyze lib/modules/domain` is clean.

10. **Property‑based tests** for `WorkoutSet`, `ExerciseGroup`, and most engine behaviours (`session_flow_engine_*_property_test.dart`). The fact that you have separate property tests for cursor, completion, mutation, ordering, superset, immutability, and suggestions is exemplary.

---

## 2. Critical findings

### 🔴 2.1  `repository_contract_purity_test.dart` is a no‑op

```1:30:test/domain/repository_contract_purity_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/repositories/program_repository.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';

void main() {
  test('ProgramRepository is an abstract class', () {
    expect(ProgramRepository, isNotNull);
  });
  ...
  test('repository files import no Drift types', () {
    expect(
      _programRepositorySourceImportsDrift,
      isFalse,
      reason: 'ProgramRepository must not import package:drift',
    );
    ...
  });
}

const bool _programRepositorySourceImportsDrift = false;
const bool _sessionRepositorySourceImportsDrift = false;
```

The "purity" test asserts that two **hardcoded compile‑time `false` constants** are `false`. It cannot fail. The test name actively misleads readers into believing the boundary is enforced.

The repositories *are* currently pure (verified manually), but nothing prevents a future commit from adding `import 'package:drift/drift.dart';` to either contract and the suite would still pass.

**Fix.** Read the repository source files at test time and assert the import lines don't contain `package:drift` (or any banned package). Sketch:

```dart
test('repository contracts import no infrastructure packages', () async {
  for (final path in [
    'lib/modules/domain/repositories/program_repository.dart',
    'lib/modules/domain/repositories/session_repository.dart',
  ]) {
    final src = await File(path).readAsString();
    expect(src, isNot(contains('package:drift')), reason: path);
    expect(src, isNot(contains('package:sqlite')), reason: path);
    expect(src, isNot(contains('package:http')), reason: path);
  }
});
```

(Use `package:path` to make it CWD‑independent.) Better still, write a small `analyzer`‑package‑based check that walks the file's `ImportDirective`s — that way it can't be fooled by strings in comments.

---

## 3. High‑priority improvements

### 🟠 3.1  `SessionRepository` is doing the engine's job

`SessionRepository` exposes 14 methods, most of which are **domain operations**, not persistence operations: `startSession` (which "captures an immutable snapshot"), `completeSet`, `skipExercise`, `replaceExercise`, `reorderUnfinished`, `createSuperset`, `removeSuperset`. The engine merely re‑validates a subset of preconditions and forwards. This puts business logic in two places — at minimum it duplicates ordering/state checks, and at worst the engine and repository can disagree.

```16:50:lib/modules/domain/repositories/session_repository.dart
  Future<Session> startSession({required String workoutDayId});
  ...
  Future<Session> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  });
  ...
  Future<Session> reorderUnfinished({...});
  Future<Session> createSuperset({...});
  Future<Session> removeSuperset({...});
```

**Symptoms already in the code.**

- `SessionFlowEngine.createSuperset` checks state preconditions; the repository will presumably re‑check them (or silently corrupt state if it doesn't).
- `SessionFlowEngine.reorderUnfinished` does the same exact‑permutation check that `SessionRepository.reorderUnfinished`'s doc claims it does (Req 7 AC 3).
- `SessionFlowEngine.completeSet` checks `session.endedAt != null` and throws `ImmutabilityError`; either the repository does too (duplication) or it doesn't (engine‑only enforcement, which loses guarantees on any non‑engine caller).

**Recommendation.** Slim `SessionRepository` to **CRUD‑ish primitives** the engine composes:

```dart
abstract class SessionRepository {
  Future<Session?> getSession(String id);
  Future<Session> getSessionByExerciseId(String sessionExerciseId);
  Future<Session> getSessionByExecutedSetId(String executedSetId);
  Future<List<Session>> listSessionsForWorkoutDay(String workoutDayId);

  /// Persists the full session state computed by the engine. The repository
  /// is responsible only for atomic write + relational integrity, not for
  /// domain invariants.
  Future<Session> save(Session session);
}
```

The engine then becomes the *single* place that owns invariants and the repository becomes purely about Drift atomicity, indexing, and JSON columns. This also kills the duplicate "ordering" checks and shrinks the test surface dramatically.

If full‑object saves are too expensive (likely true for `Session`, which embeds `sessionExercises`, `notes`, `extraWork`, and `snapshot`), a middle ground is to keep a small set of *fine‑grained mutators* (`appendExecutedSet`, `setExerciseState`, `updateUnfinishedOrder`, etc.) that take primitive arguments and **explicitly do not validate** — the engine has already validated. Document that contract on the interface.

### 🟠 3.2  `SessionFlowEngine` mixes four responsibilities (576 lines, growing)

The class currently does:

1. Reads + state derivation (`computeCursor`, `isSessionComplete`, `suggestValues`, `_buildState`).
2. Lookups across the embedded snapshot (`_lookupPlannedExercise`, `_lookupPlannedSet`, `_lookupPlannedSetCount`).
3. Validation (`_assertUnfinished`, `_validateMeasurementTypeMatch`, body‑length / superset‑size / permutation checks inline in mutators).
4. Mutation orchestration (10 `Future<SessionState>` methods).

A clean split:

- `CursorComputer` — pure, takes a `Session`, returns a `Cursor` and the next suggested values. No I/O.
- `SessionValidator` — pure preconditions: `assertUnfinished`, `assertNotEnded`, `assertMeasurementTypeMatches`, `assertExactPermutation`, etc. Each method documents which invariant code it enforces.
- `SessionSnapshotLookups` — pure lookups against the snapshot, memoized on first access (see §3.3).
- `SessionFlowEngine` — orchestration only: load → validate → mutate → recompute → return.

That makes each responsibility unit‑testable in isolation and lets you keep `SessionFlowEngine` under ~200 lines.

### 🟠 3.3  `_lookupPlannedExercise` is O(n) per call → quadratic per cursor recompute

`computeCursor` iterates every `SessionExercise`, and for each one calls `_lookupPlannedSetCount` → `_lookupPlannedExercise`, which does a nested linear scan through `workoutDay.exerciseGroups` and `exercises`:

```472:493:lib/modules/domain/services/session_flow_engine.dart
  Exercise _lookupPlannedExercise(
    SessionExercise sessionExercise,
    Session session,
  ) {
    final workoutDay = session.snapshot.workoutDay;
    for (final group in workoutDay.exerciseGroups) {
      for (final exercise in group.exercises) {
        if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
          return exercise;
        }
      }
    }
    throw NotFoundError(...);
  }

  int _lookupPlannedSetCount(SessionExercise sessionExercise, Session session) {
    final exercise = _lookupPlannedExercise(sessionExercise, session);
    return exercise.sets.length;
  }
```

For a session with E exercises across G groups, `computeCursor` is O(E · E·G). On every mutation we recompute the cursor, suggest values (which re‑sorts and re‑scans), and round‑trip through the repo. Today's workouts are tiny, so it doesn't matter; but the *shape* of the code makes it easy to accidentally make this hot.

**Fix.** Either:

1. Add a memoized `Map<String, Exercise>` on `Session` (or compute one inside `_buildState` and pass it through), keyed by `plannedExerciseIdInSnapshot`.
2. Or, simpler: build the index once at the top of `computeCursor` / `_buildState` and pass it into the helpers.

```dart
SessionState _buildState(Session session) {
  final index = _indexPlannedExercises(session.snapshot.workoutDay);
  final cursor = computeCursor(session, index);
  return SessionState(
    session: session,
    cursor: cursor,
    suggestedValues: suggestValues(session: session, cursor: cursor, index: index),
  );
}
```

Bonus: the engine becomes pure (`Session → SessionState`) for everything other than I/O.

### 🟠 3.4  `runtimeType.toString()` for state names is fragile

```111:117:lib/modules/domain/services/session_flow_engine.dart
        throw OrderingError(
          sessionExerciseId: id,
          currentState: exercise.state.runtimeType.toString(),
          message:
              'Cannot reorder exercise $id: state is ${exercise.state.runtimeType}',
        );
```

Four call sites use the same pattern: `session_flow_engine.dart:113, 376, 410, 570`.

**Problems.**

1. `analysis_options.yaml` enables `avoid_type_to_string`, which is intended to catch this exact pattern (it currently doesn't fire because the rule keys on `.toString()` of `Type` *expressions* the analyzer can prove; via getter it sometimes slips). Either way, this style is what the lint is trying to prevent.
2. Under Flutter release builds with `--obfuscate`, `Type.toString()` returns mangled names. `OrderingError.currentState` would carry `Symbol(...)` or `minified123` strings, breaking any UI/telemetry consumer.
3. Freezed generates concrete classes like `_$UnfinishedStateImpl`, so even *today* the values are noisy implementation details. Tests that compare against `'UnfinishedState'` would tie themselves to the generated naming.

**Fix.** Add an `extension` (or a getter on `ExerciseState`) that returns a stable string discriminator — the same one Freezed already uses for the union key:

```dart
extension ExerciseStateDescribe on ExerciseState {
  String get discriminator => switch (this) {
    UnfinishedState() => 'unfinished',
    CompletedState() => 'completed',
    SkippedState() => 'skipped',
    ReplacedState() => 'replaced',
  };
}
```

…then replace every `state.runtimeType.toString()` with `state.discriminator`. Now the `OrderingError.currentState` field is part of the *contract* and survives obfuscation, refactors, and Freezed regenerations.

### 🟠 3.5  Repository contract bleeds defaults that the model rejects

`ProgramRepository.createExercise` declares `metadata = ExerciseMetadata.empty`:

```50:56:lib/modules/domain/repositories/program_repository.dart
  Future<Exercise> createExercise({
    required String exerciseGroupId,
    required String name,
    required MeasurementType measurementType,
    ExerciseMetadata metadata = ExerciseMetadata.empty,
    int? plannedRestSeconds,
  });
```

But the `Exercise` model requires `metadata`:

```36:48:lib/modules/domain/models/exercise.dart
  factory Exercise({
    ...
    required ExerciseMetadata metadata,
    ...
  }) = _Exercise;
```

…and `SubstituteExercise` makes it **nullable**:

```12:16:lib/modules/domain/models/substitute_exercise.dart
  const factory SubstituteExercise({
    required String name,
    required MeasurementType measurementType,
    ExerciseMetadata? metadata,
  }) = _SubstituteExercise;
```

Pick one rule. Recommendation: **make `ExerciseMetadata` always non‑nullable with `ExerciseMetadata.empty` as the zero‑value**, both for `Exercise` and `SubstituteExercise`. Nullability for what is effectively a record of optional strings just pushes null‑checks into every consumer.

---

## 4. Medium‑priority improvements

### 🟡 4.1  Inconsistent import style inside `lib/modules/domain/`

Some files use absolute imports:

```1:6:lib/modules/domain/models/exercise.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
```

Others mix in relative imports:

```1:5:lib/modules/domain/models/exercise_state.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/core/deserialization.dart';

import 'substitute_exercise.dart';
```

`avoid_relative_lib_imports` (enabled) only forbids relative imports that cross `lib/` boundaries; sibling‑file relative imports stay legal. But the inconsistency hurts readability and grep‑ability.

**Pick one style.** The dominant convention in this codebase is `package:zamaj/...` — make it the only convention and remove the relative imports in `exercise_state.dart` and `substitute_exercise.dart`.

### 🟡 4.2  `directives_ordering` is on but not always followed

The lint is enabled, and `dart analyze` is clean today, but a few files split imports with a blank line between Freezed/core and intra‑module imports (`exercise_state.dart`, `substitute_exercise.dart`). With one canonical style (§4.1) you can keep a single sorted block per `directives_ordering`'s grouping rules: `dart:` → `package:` → relative.

### 🟡 4.3  `ExerciseGroupInvariants.validate` exists; the other entities don't expose equivalents

`ExerciseGroup` is the only model that lifts its invariants into a named public class:

```35:64:lib/modules/domain/models/exercise_group.dart
abstract final class ExerciseGroupInvariants {
  static void validate({
    required String id,
    required ExerciseGroupKind kind,
    required List<Exercise> exercises,
  }) { ... }
}
```

This is useful: callers (e.g. a form's `onChange`) can pre‑validate without actually trying to construct the entity. Consider doing the same for `WorkoutSet`, `Exercise`, and `ExecutedSet`. It also de‑duplicates the constructor body so the body becomes `_Invariants.validate(this)`.

### 🟡 4.4  Validation is non‑exhaustively duplicated between models and engine

`ExecutedSet._()` and `WorkoutSet._()` already validate `measurementType` ↔ values shape. `SessionFlowEngine._validateMeasurementTypeMatch` re‑validates the same thing for `completeSet` / `updateExecutedSet`. The engine's check is needed earlier (before constructing the `ExecutedSet`) — but the messaging diverges:

- Model raises `ValidationError(invariant: 'actualValues_variant_mismatch')`.
- Engine raises `ValidationError(invariant: 'measurementType_actualValues_mismatch')`.

Same problem, different code. Standardise on one invariant identifier and route both call sites through the same helper (a static on `ActualSetValues`, e.g. `ActualSetValues.assertMatches(MeasurementType, {required String entityId})`). Tests can then match a single invariant key.

### 🟡 4.5  `Cursor` and `SessionState` live in `services/` but are value objects

```26:28:lib/modules/domain/domain.dart
export 'services/cursor.dart';
export 'services/session_flow_engine.dart';
export 'services/session_state.dart';
```

`Cursor` is a Freezed sealed union with `fromJson`; it has no behaviour. `SessionState` is a Freezed record. Both are domain values, not services. The engine is the only true service in this folder. Moving `cursor.dart` and `session_state.dart` to `lib/modules/domain/models/` would make the folder taxonomy match the file shape and is a one‑line export change.

### 🟡 4.6  `Duration` instead of `int seconds` would be more idiomatic

`plannedRestSeconds`, `durationSeconds`, `PlannedSetValues.timeBased(durationSeconds:)`, `ActualSetValues.timeBased(durationSeconds:)` all use `int` seconds. Dart has a first‑class `Duration` type that:

- Encodes the unit in the type system (no chance of confusing seconds with milliseconds at a call site).
- Plays nicely with `DateTime.add`, animations, and stopwatches.
- Survives JSON round‑trip via a one‑line converter (`@JsonKey(fromJson: _durFromMicros, toJson: _durToMicros)`).

This is a one‑off migration that improves every downstream consumer (UI countdowns, charts, exports). Worth doing now while the schema is still v2.

### 🟡 4.7  `DateTime` fields aren't asserted to be UTC

`AppClock.nowUtc()` enforces UTC at the source, but nothing prevents a fromJson, a test, or a future caller from constructing a `Session(startedAt: DateTime(2024, 1, 1) /* local */)`. The bug surfaces only when canonical JSON is hashed and compared, hours later.

Add `assert(startedAt.isUtc)` (and equivalent) inside the private constructors. They compile out in release mode (debug‑only check), but catch the entire class of timezone bugs in tests and dev.

### 🟡 4.8  `schemaVersion` on every model is error‑prone

Every entity requires a `schemaVersion: int` at construction. Callers either hard‑code `1` (lots of test fixtures do this) or import `SchemaVersions.domain`. A future migration to v3 silently leaves test data on v1 and there's no compile‑time alarm.

Two options:

1. **Default it** in the factory (`int schemaVersion = SchemaVersions.domain`). Tests no longer need to pass `1`. Repository code that *writes* still gets the constant via the default.
2. **Strip it from the model entirely** and stamp it only at the persistence boundary. The domain model is the in‑memory shape; the schema version is a row attribute. This is the cleaner answer but a bigger refactor.

Either is better than the current state.

### 🟡 4.9  `CanonicalJson._formatDouble` doesn't normalise

```85:88:lib/core/canonical_json.dart
  static String _formatDouble(double value) {
    final s = value.toString();
    return s;
  }
```

`double.toString()` is platform‑defined and *generally* round‑trippable, but `1.0.toString() == '1.0'` and `60.5.toString() == '60.5'` — fine — while `0.1 + 0.2` gives `0.30000000000000004`. The domain already constrains `weightKg` to half‑kg multiples, so this won't bite in practice, but if any new schema ever lets through arbitrary doubles the canonical hash becomes platform‑dependent.

Either (a) keep the half‑kg invariant universally and document that `CanonicalJson` only accepts representable‑in‑half‑step doubles, or (b) format with a fixed precision and reject doubles outside it.

---

## 5. Style and documentation nits

### 🟢 5.1  Many models have no class‑level doc comment

`Session`, `SessionExercise`, `SessionNote`, `WorkoutDay`, `ExerciseGroup`, `Program`, `MeasurementType`, `ActualSetValues`, `PlannedSetValues`, `ExerciseState`, `Cursor`, `SessionState`, `ExtraWork`, `SubstituteExercise`, and `ExerciseMetadata` are entirely undocumented at the type level. Even one line saying "what is a `SessionExercise`?" pays for itself the first time someone joins the project.

`SessionFlowEngine` is documented at the type level, plus most public methods — set that as the standard.

### 🟢 5.2  Bang‑operator on Freezed getters is unavoidable but worth a comment

```13:22:lib/modules/domain/models/exercise.dart
  Exercise._() {
    if (plannedRestSeconds != null &&
        (plannedRestSeconds! < 0 || plannedRestSeconds! > 3600)) {
      throw ValidationError(...);
    }
```

Dart flow analysis can't promote nullable *getters* across `&&`, so the `!` is required here. Future readers will reach for "just refactor it" — a one‑line comment ("Freezed getters can't be promoted, hence `!`") would save the same review next time. Alternatively, copy to a local: `final rest = plannedRestSeconds; if (rest != null && (rest < 0 || rest > 3600)) ...`.

### 🟢 5.3  `errors.dart` lacks a library directive / doc comment

Every other file has either `library;` with a doc comment (`domain.dart`, `program_repository.dart`, `session_repository.dart`) or a clear top‑of‑file doc. `errors.dart` jumps straight into `sealed class DomainError`. Add a one‑paragraph header explaining the discrimination strategy and the `final class` subtype convention.

### 🟢 5.4  `@Assert('id.length == 36', ...)` is enforced on `Program` only

```11:19:lib/modules/domain/models/program.dart
  @Assert('id.length == 36', 'id must be canonical UUIDv4 (36 chars)')
  const factory Program({
    required String id,
```

Every other entity also takes a UUID `id` but doesn't assert it. Either enforce uniformly via a shared `@Assert` on every model, or — better — introduce an `extension type Uuid(String value)` and require it everywhere (`Uuid id`). The extension type adds zero runtime cost and removes the assertion duplication.

### 🟢 5.5  `extra_work.dart` has a stale `TODO`

```7:9:lib/modules/domain/models/extra_work.dart
// TODO(extra-work-typing): replace freeform body with a typed sealed family
// (e.g. cardio, accessory, mobility) once the session flow spec defines the
// variants. See design §12 resolved decision 10.
```

Make sure the `TODO` carries an issue/ticket reference, not a doc section that may move. (`TODO(#123)`.)

### 🟢 5.6  Some sealed unions don't expose `when`/`map` callers

The `ExerciseGroup` test does `group.kind.when(single: ..., superset: ...)` — that works because Freezed 3 still generates `.when` for `@Freezed` (not `@freezed`). Some other consumers use `switch`. Both work; either pick one or document that both are encouraged. (Pattern matching is the modern choice and is what's used in the engine.)

---

## 6. Quick wins (≤30 minutes each)

In priority order:

1. **Replace `repository_contract_purity_test.dart`** with an actual file‑scan test. (§2.1)
2. **Add `ExerciseStateDescribe.discriminator`** and remove four `runtimeType.toString()` call sites. (§3.4)
3. **Move `cursor.dart` and `session_state.dart`** to `models/` and update the barrel. (§4.5)
4. **Standardise imports** to `package:zamaj/...`. (§4.1)
5. **Make `ExerciseMetadata` non‑nullable everywhere**, default to `ExerciseMetadata.empty`. (§3.5)
6. **Add UTC assertions** in the four entities that carry `DateTime`. (§4.7)
7. **Default `schemaVersion`** to `SchemaVersions.domain` in every factory. (§4.8)
8. **Add class‑level doc comments** to the 14 undocumented models. (§5.1)

---

## 7. Bigger refactors (separate PRs)

In priority order:

1. **Shrink `SessionRepository` to CRUD primitives**; move `completeSet` / `reorderUnfinished` / `createSuperset` / `removeSuperset` logic entirely into the engine. (§3.1)
2. **Split `SessionFlowEngine`** into `CursorComputer`, `SessionValidator`, `SnapshotIndex`, and a thin orchestrator. (§3.2)
3. **Memoize snapshot lookups** (one map per `_buildState`). (§3.3)
4. **Migrate `int *Seconds` → `Duration`** with JSON converters. (§4.6)
5. **Introduce `extension type Uuid(String)`** and replace every `String id` field. (§5.4)

---

## 8. Appendix — best‑practice rubric used

These are the standards the review is measured against. Items already met are marked ✓; items partially met are △; missed are ✗.

**Effective Dart — Style.** lowercase_with_underscores file/dir names ✓, UpperCamelCase types ✓, `///` doc comments △ (only a subset of files), `[brackets]` in doc comments to link symbols △.

**Effective Dart — Usage.** `prefer_const_constructors` enforced ✓, `prefer_final_fields` / `_locals` ✓, `prefer_single_quotes` ✓, no `dynamic` (the only `Map<String, dynamic>` is on Freezed‑generated `fromJson` — unavoidable) ✓, `cascades` where they help — not used much but not required.

**Effective Dart — Design.** Avoid leaking implementation details across layers ✓ (no Drift in domain), prefer named parameters for booleans ✓, prefer typed callbacks ✓, avoid breaking encapsulation — *partial* because `SessionRepository` exposes domain operations (§3.1).

**Dart 3 — Patterns & Sealed Classes.** Exhaustive `switch` over sealed unions ✓, destructuring in patterns ✓, sealed exception hierarchies ✓.

**Freezed v3.** `abstract class … with _$X` for product types ✓, `sealed class` with `unionKey` for sum types ✓, validation in `X._()` private constructor body ✓, `@Assert` for cheap invariants △ (used once, on `Program`).

**Clean Architecture / DDD.** Domain layer pure of infrastructure ✓, value objects immutable ✓, aggregates expose factories ✓, repositories CRUD‑focused ✗ (mixed with use‑case ops, §3.1), invariants enforced at the entity boundary ✓.

**Testing.** Property‑based tests for invariants ✓, fakes over mocks ✓, time pinned via `Clock.fixed` ✓, boundary‑clamp tests ✓, no flaky/hardcoded "purity" tests ✗ (§2.1).

**Analyzer.** `strict-casts` / `strict-inference` / `strict-raw-types` ✓, `avoid_dynamic_calls` ✓, `unawaited_futures` ✓, `avoid_type_to_string` enabled but pattern still used in source (§3.4), `directives_ordering` mostly followed (§4.2).

---

*End of review.*
