# `lib/modules/persistence` — Code Review

Scope: every file under `lib/modules/persistence/` (excluding the generated
`app_database.g.dart`). Evaluated against current Dart 3 / Flutter / Drift
best practices and the project's own `analysis_options.yaml`.

The module's architectural shape is solid (clean hexagonal split between
domain contracts and a Drift-backed adapter, deterministic JSON snapshots,
sealed errors, injected `Clock`). The findings below are mostly about
robustness, performance and small idiomatic improvements — not a redesign.

---

## Verdict & disposition (after second-pass verification)

The review was independently verified against the codebase. Most findings are
correct, a handful were pushed back on. The "High-impact + indexes + N+1 +
batch reorder" scope was applied.

### Fixed

| # | Item | What was done |
|---|------|---------------|
| 1 | Position bug (`existing.length` UNIQUE collision) | Replaced with `MAX(position) + 1` helpers in `createWorkoutDay`, `createExerciseGroup`, `createExercise`, `createSet` |
| 2 | Missing indexes | Added `@TableIndex` on `WorkoutDays.programId`, `Sessions.workoutDayId`, `SessionExercises(sessionId, stateDiscriminator)`, `SessionNotes.sessionId`; bumped `SchemaVersions.drift` 2→3 with migration step |
| 3 | N+1 reads | Rewrote `listPrograms`, `listWorkoutDaysForProgram`, `listSessionsForWorkoutDay` to a fixed handful of queries each with in-memory grouping |
| 4 | Reorder 2×N round-trips | All four `reorder*` methods wrapped in `_db.batch(...)`. Replaced the `+1000` parking offset with negative temporary positions |
| 5 | `DriftSessionRepository` depends on concrete program repo | Typed parameter as `ProgramRepository` (the abstract interface) |
| 8 | `_nextUpdatedAt` duplication | Extracted to `TimestampOracle` in `database/timestamp_oracle.dart`; both repos use it |
| 10 | Barrel missing `drift_session_repository.dart` | Added export |
| 12 | `endSession` non-idempotent | Throws `ImmutabilityError` if `endedAtMs != null` |

Regression tests added:

- `test/repository/create_after_delete_test.dart` (4 cases — one per create method).
- `test/repository/end_session_idempotency_test.dart`.

The v1→v2 migration test fixture (`test/integration/exercise_planned_rest_migration_test.dart`) was extended to include all v1 tables — the previous fixture was incomplete and would have masked any cross-table v3 migration step.

### Deferred (correct, lower priority)

| # | Item |
|---|------|
| 6 | Snapshot hashed up to 3× per read |
| 11 | `as Map<String, dynamic>` throws `TypeError`, not `DeserializationError` |
| 14 | O(N·M) `.where()` filters in mappers |

### Pushed back on (declined)

| # | Item | Reason |
|---|------|--------|
| 7 | "Drop discriminator + JSON-payload duplication" | Intentional design. The session repo's `stateDiscriminator.isNotIn(['unfinished'])` filter and the new composite index `(sessionId, stateDiscriminator)` both rely on it. Removing it would degrade query performance and remove the discriminator-only fast path in `_reconstructState` |
| 9 | "Migrate `…AtMs` → Drift native `DateTime`" | Invasive cross-cutting refactor with real data-migration risk for shipped users. Lots of churn for a readability win |
| 13 | "Move `_validateActualValues` to domain" | The reviewer assumes a coupling between `ActualSetValues` and `MeasurementType` that doesn't exist in the domain today. Adding it is itself a domain change, not a repository cleanup |
| — | "Remove `tables.dart`/`migrations.dart` from barrel" | Tests legitimately consume them; "leaks internals" framing is overstated for a single-app codebase |
| — | "`WorkoutDays.programId` is redundant" | Used by `WorkoutDayMapper.toDomain`. Removing requires a domain-shape change, not just a column drop |
| — | "Class is static-only namespace; consider `abstract final class`" on `AppMigrations` | Applied as a small ride-along |

### Verification

- `flutter analyze` — no issues
- `flutter test` — 412 tests pass
- `tool/check_offline_imports.sh` — OK

---

## TL;DR — Top items, in order of impact

| # | Item | Severity |
|---|------|----------|
| 1 | `position = existing.length` collides with the `UNIQUE(parent, position)` index after any delete | **Bug** |
| 2 | No SQL indexes on heavily-filtered foreign-key columns | High |
| 3 | N+1 queries in `listPrograms`, `listWorkoutDaysForProgram`, `listSessionsForWorkoutDay` | High |
| 4 | Reorder primitives do 2×N round-trips, not batched | High |
| 5 | `DriftSessionRepository` depends on the concrete `DriftProgramRepository`, not the interface | Medium |
| 6 | Snapshot is canonicalised + hashed up to **3×** per read | Medium |
| 7 | Discriminator + JSON-payload columns store the discriminator twice | Medium |
| 8 | `_nextUpdatedAt` accumulates artificial future drift; logic is duplicated across repos | Medium |
| 9 | Top-level `msToUtc` / `utcToMs` utilities — Drift natively supports `DateTime` columns | Medium |
| 10 | `persistence.dart` barrel: leaks internals, missing `drift_session_repository.dart`, unused by callers | Low |
| 11 | `as Map<String, dynamic>` casts in mappers throw `TypeError`, not `DeserializationError` | Low |
| 12 | `endSession` is non-idempotent and doesn't reject already-ended sessions | Low |
| 13 | `_validateActualValues` is domain logic living in the repository | Low |
| 14 | Inner-loop `.where(...)` filters in mappers are O(N·M) | Low |

The rest of the document walks through each file, then expands on these items.

---

## File-by-file notes

### `persistence.dart` (barrel)

```1:11:lib/modules/persistence/persistence.dart
library;

export 'database/app_database.dart';
export 'database/datetime_utils.dart';
export 'database/migrations.dart';
export 'database/tables.dart';
export 'mappers/program_mapper.dart';
export 'mappers/session_mapper.dart';
export 'mappers/workout_day_mapper.dart';
export 'repositories/drift_program_repository.dart';
```

- **Missing export**: `drift_session_repository.dart` is not exported, but
  `drift_program_repository.dart` is. Either both or neither.
- **Leaks internals**: `tables.dart` and `migrations.dart` are pure Drift
  implementation details. Public clients of the module should only need
  `AppDatabase` and the repository implementations (plus mappers if they
  write tests). Exporting tables/migrations widens the public surface and
  invites callers to pass `Programs`-the-table around.
- **Unused**: `rg "package:zamaj/modules/persistence/persistence.dart"`
  returns no hits. `bootstrap.dart` and tests import the leaf files
  directly. Decide: either make this barrel the canonical entry-point and
  forbid direct deep imports (`directives_ordering` won't catch that;
  consider a `dart_code_metrics` rule or a custom CI check), or delete it.
- `library;` (the bare directive) is allowed in Dart 3 but only useful
  when you want to attach a dartdoc comment to the library. Since there
  is none, drop it.

### `database/app_database.dart`

```9:44:lib/modules/persistence/database/app_database.dart
@DriftDatabase(
  tables: [
    Programs,
    ProgramWorkoutDays,
    ...
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  @override
  int get schemaVersion => SchemaVersions.drift;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onUpgrade: AppMigrations.onUpgrade,
    beforeOpen: (details) async {
      if (details.versionBefore != null &&
          details.versionBefore! > schemaVersion) {
        throw VersionMismatchError(
          persisted: details.versionBefore!,
          expected: schemaVersion,
        );
      }
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
```

What's good:

- Downgrade protection (`VersionMismatchError`) is rare and appreciated.
- `PRAGMA foreign_keys = ON` in `beforeOpen` — the right hook.
- Clean single source of truth for `schemaVersion` via `SchemaVersions`.

What I'd change:

- **Add `onCreate`** explicitly. Drift's default (`m.createAll()`) is
  fine but being explicit pairs nicely with future code that needs to
  seed defaults atomically.
- **Schema verification in tests**: enable `drift_dev`'s
  `verify_database_schema` (or `drift_dev schema dump`/`generate-steps`)
  to assert that the live schema matches a checked-in JSON
  snapshot. Right now `SchemaVersions.drift = 2` could be incremented
  without the migration covering every table change and you'd only find
  out at runtime.
- **Consider isolate execution.** On mobile, `driftDatabase(name:'zamaj')`
  (in `bootstrap.dart`) currently runs the database on the UI isolate.
  For larger snapshots / list-views, prefer the
  `LazyDatabase`/`DriftIsolate` pattern (or
  `driftDatabase(name, isolateSetup: …)` if `drift_flutter >= 0.4`).

### `database/tables.dart`

The schema is well thought-out: 36-char UUID checks, `KeyAction.cascade`
on every parent reference, composite `(parent, position)` unique keys
to prevent gaps/duplicates, schema-version stamped on every row.

Concrete improvements:

1. **Missing indexes**. Drift only auto-indexes primary keys and unique
   keys. Every foreign-key column you filter on at runtime should be
   indexed. Concrete additions, in roughly query-frequency order:

   - `ProgramWorkoutDays.programId` (already implicit via the
     composite PK, OK).
   - `WorkoutDays.programId`
   - `ExerciseGroups.workoutDayId`  *(covered by the unique key
     `{workoutDayId, position}` — OK)*
   - `Exercises.exerciseGroupId`  *(covered by unique key — OK)*
   - `WorkoutSets.exerciseId`  *(covered by unique key — OK)*
   - `Sessions.workoutDayId`  ← **filtered in `listSessionsForWorkoutDay`,
     no index**
   - `SessionExercises.sessionId`  *(partly covered; but you also filter
     by `stateDiscriminator` — a composite index helps)*
   - `ExecutedSets.sessionExerciseId`  *(covered by unique key)*
   - `SessionNotes.sessionId`  ← no index
   - `ExtraWorkItems.sessionId`  *(covered by unique key)*

   Use the modern annotation form:

   ```dart
   @TableIndex(name: 'sessions_workout_day_id', columns: {#workoutDayId})
   @TableIndex(
     name: 'session_exercises_session_state',
     columns: {#sessionId, #stateDiscriminator},
   )
   class Sessions extends Table { ... }
   ```

   Add a migration step (bump `SchemaVersions.drift` to 3 and create the
   indexes in `AppMigrations.onUpgrade`). On a 50-session 200-set local
   DB it's negligible; once a user has 12 months of history the
   `_maxLockedPositionExcluding` / `_renumberUnfinishedAfterLock`
   queries do a full-scan per call.

2. **`WorkoutDays.programId` lacks the unique-position constraint** the
   sibling `ProgramWorkoutDays.{programId, position}` enforces.
   `ProgramWorkoutDays` is the source of truth for order, which is fine,
   but then `WorkoutDays.programId` is denormalised — it could go away
   entirely if you always join through `ProgramWorkoutDays`. Today it's
   a duplicate FK that can theoretically disagree with the join table.

3. **`Sessions.workoutDayId` deliberately has no FK** (soft-ref so
   sessions survive workout-day deletion). Add an inline comment so
   the next reader doesn't "fix" it; the integration test
   `soft_ref_survives_workout_day_delete_test.dart` documents intent
   but the table doesn't.

4. **`WorkoutSets` uses `tableName = 'sets'`** but the Dart class is
   `WorkoutSets`. This is fine, but it bites in two ways:
   - Drift exposes the row class as `WorkoutSet` (not `Set`, fortunately)
     because Drift singularises the table name when there's no explicit
     `@DataClassName`. The companion is `WorkoutSetsCompanion`. Just
     keep the rename or use `@DataClassName('WorkoutSetRow')` for total
     clarity.
   - SQL inspection (`sqlite3 ... .schema`) shows a bare `sets` table,
     which is a reserved-ish word in some contexts. A small docstring
     explaining the rename will save a future migration.

5. **Length checks only on `id` columns**. `Sessions.snapshotHash`
   correctly requires `withLength(min: 64, max: 64)`. Consider
   `withLength(max: ...)` on user-supplied text (`Programs.name`,
   `WorkoutDays.name`, `Exercises.name`, `SessionNotes.body`,
   `ExtraWorkItems.body`) so an over-large value fails at insertion
   rather than at sync/serialisation time.

6. **Discriminator + JSON payload duplication.** Several tables store
   both `xxxDiscriminator` and `xxxPayloadJson`, but the payload itself
   contains `"type": "<discriminator>"`. You're paying the cost of
   storing the type tag twice — minor disk bloat, more importantly the
   two columns can disagree if anyone bypasses the mapper. Two options:

   - Store **only** the JSON payload and derive the discriminator at
     read time (less robust if you ever want to `WHERE discriminator =
     ...`).
   - Or keep both columns but add a `CHECK` constraint via
     `customConstraint('CHECK (json_extract(... '$.type') = ...))` so
     the database itself enforces agreement.

   For "marker" cases where the variant has no payload (e.g.
   `MeasurementType.repBased()` / `.timeBased()`), the
   `measurementTypePayloadJson` column stores literally
   `{"type":"repBased"}` and could be dropped entirely.

### `database/migrations.dart`

```1:11:lib/modules/persistence/database/migrations.dart
import 'package:drift/drift.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';

class AppMigrations {
  static Future<void> onUpgrade(Migrator m, int from, int to) async {
    final db = m.database as AppDatabase;
    if (from < 2) {
      await m.addColumn(db.exercises, db.exercises.plannedRestSeconds);
    }
  }
}
```

- The class is a static-only namespace. Make it `abstract final class`
  (or just a top-level function `Future<void> onUpgrade(...)`); both
  match `SchemaVersions` and prevent accidental instantiation.
- **No `onCreate` step-by-step verification.** Once you add indexes
  (above), use Drift's `stepByStep` helper / `generate-steps` so the
  migration tracker is the single source of truth and `onCreate`
  produces exactly the same schema as `onUpgrade` from v0 → vN.
- The `m.database as AppDatabase` cast works because the migration runs
  with `AppDatabase` attached, but if Drift ever exposed a generic
  migrator it would silently throw. Use `m.database as
  GeneratedDatabase` and access tables via the generated property; or,
  cleaner, pass the typed `AppDatabase` into the static.

### `database/datetime_utils.dart`

```1:4:lib/modules/persistence/database/datetime_utils.dart
DateTime msToUtc(int ms) =>
    DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);
int utcToMs(DateTime dt) => dt.millisecondsSinceEpoch;
int? utcToMsNullable(DateTime? dt) => dt?.millisecondsSinceEpoch;
```

- These globals are imported from many places. Dart 3 idiom: put them
  on extensions to make call-sites readable, e.g.
  `dt.toEpochMs()` / `ms.toUtcDateTime()`.
- More fundamentally, **Drift natively understands `DateTime` columns**
  and stores them as Unix-seconds-since-epoch (default) or ISO-8601.
  If you migrated to `DateTimeColumn`, every mapper would lose ~30
  lines of `DateTime.fromMillisecondsSinceEpoch(row.x, isUtc: true)`.
  Trade-off: a one-shot data migration (`UPDATE ... SET col = col /
  1000`) and a possible regression risk for already-shipped users.
  Worth it for the readability win.
- `millisecondsSinceEpoch` truncates the microsecond half of any
  `DateTime`. Consider `microsecondsSinceEpoch` if your event ordering
  ever needs sub-millisecond resolution (the
  `_nextUpdatedAt(+1ms)` hack below is essentially a workaround for
  this).
- `utcToMsNullable` exists but isn't actually used in the module
  (everywhere it would be needed callers do `dt?.millisecondsSinceEpoch`
  inline). Either use it everywhere or delete it.

### `mappers/program_mapper.dart`

```5:32:lib/modules/persistence/mappers/program_mapper.dart
class ProgramMapper {
  domain.Program toDomain(Program row, List<String> workoutDayIds) {
    return domain.Program(
      id: row.id,
      ...
    );
  }

  ProgramsCompanion toRow(domain.Program domain) {
    return ProgramsCompanion(
      id: Value(domain.id),
      ...
    );
  }
}
```

- The parameter name `domain` shadows the `as domain` import prefix.
  Rename to `program` to keep the prefix usable inside the body.
- The class is stateless; make the methods `static` (or top-level
  functions), avoiding the per-repository allocation. Same applies to
  `WorkoutDayMapper` and `SessionMapper`.
- `toRow` uses `Value(...)` everywhere, which gives "if unset, leave
  alone" semantics on update — but `toRow` here is only used for full
  inserts (the repo's own `ProgramsCompanion.insert(...)` is preferred
  on the hot path). Add a docstring clarifying that this companion is
  intended for `replace`/`upsert`, not partial updates, so a future
  caller doesn't accidentally null-out `createdAtMs` by re-using it on
  `update`.

### `mappers/workout_day_mapper.dart`

```22:43:lib/modules/persistence/mappers/workout_day_mapper.dart
final exerciseGroups =
    groupRows.where((g) => g.workoutDayId == row.id).toList()
      ..sort((a, b) => a.position.compareTo(b.position));
```

- `toDomain(WorkoutDay row, List<ExerciseGroup> groupRows, ...)`
  already takes only the rows relevant to one day, but the body
  re-filters with `.where(g => g.workoutDayId == row.id)`. Either drop
  the filter and document the precondition, or rename the parameter to
  `allGroupRows` and keep it.
- `groupRows / exerciseRows / setRows` filtering is O(N·M):
  `_groupToDomain` walks all exerciseRows once per group;
  `_exerciseToDomain` walks all setRows once per exercise; etc. For the
  current usage (one day at a time) this is small, but the same shape
  is used in `SessionMapper` where the lists can be larger. Bucket
  once:

  ```dart
  final exercisesByGroup = <String, List<Exercise>>{};
  for (final e in exerciseRows) {
    (exercisesByGroup[e.exerciseGroupId] ??= []).add(e);
  }
  ```

  Then `_groupToDomain` does an O(1) lookup. Same for sets-by-exercise.

- Each `_exerciseToDomain` call does
  `jsonDecode(row.measurementTypePayloadJson)` and immediately the
  `MeasurementType.fromJson` boxes into a small enum-like
  variant. For exercises whose `measurementType` is a marker variant
  (`repBased`/`timeBased`), the discriminator column is enough — you
  could short-circuit the JSON decode entirely:

  ```dart
  final measurementType = switch (row.measurementTypeDiscriminator) {
    'repBased' => const MeasurementType.repBased(),
    'timeBased' => const MeasurementType.timeBased(),
    final d => throw DeserializationError(...),
  };
  ```

  This is also more robust: a row with a corrupt JSON payload but a
  valid discriminator would still load. (Same observation applies to
  the `actualValuesPayloadJson` in `SessionMapper`.)

- The `jsonDecode(...) as Map<String, dynamic>` casts throw `TypeError`
  on malformed data. Wrap each in a `try`/`on TypeError` →
  `DeserializationError`, or extract a helper:

  ```dart
  Map<String, dynamic> _decodeMap(String json, String field, String? disc) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } on FormatException catch (e) {
      throw DeserializationError(field: field, discriminator: disc, message: e.message);
    } on TypeError {
      throw DeserializationError(
        field: field, discriminator: disc, message: 'expected JSON object',
      );
    }
  }
  ```

### `mappers/session_mapper.dart`

```104:129:lib/modules/persistence/mappers/session_mapper.dart
SessionSnapshot _reconstructSnapshot(Session row) {
  final recomputedHash = CanonicalJson.sha256Hex(row.snapshotJson);
  if (recomputedHash != row.snapshotHash) {
    throw DeserializationError( ... );
  }

  final workoutDay = domain.WorkoutDay.fromJson(
    jsonDecode(row.snapshotJson) as Map<String, dynamic>,
  );

  return SessionSnapshot(
    workoutDay: workoutDay,
    canonicalJson: row.snapshotJson,
    sha256Hash: row.snapshotHash,
    capturedAt: ...
    schemaVersion: row.schemaVersion,
  );
}
```

- **Triple-work on snapshot reads.** Look at the call chain for every
  `getSession`:
  1. `_reconstructSnapshot` computes SHA-256 of `snapshotJson`
     (full pass over the bytes).
  2. The `SessionSnapshot._()` constructor re-encodes the workout day
     via `CanonicalJson.encode(workoutDay.toJson())` (rebuilds the
     entire string), then `CanonicalJson.sha256Hex(canonicalJson)` —
     **another** SHA pass.

  For a workout day with 8 exercises × 4 sets, that's a few kilobytes
  hashed three times per read. Acceptable on app launch; expensive in a
  history list view.

  Options:
  - Add a `SessionSnapshot.trusted({...})` factory used by the mapper
    that skips the invariants (since the mapper just verified the hash).
  - Or guard the invariants with `assert(...)` so they only run in
    debug builds.
  - Or skip `_reconstructSnapshot`'s explicit hash check (the
    `SessionSnapshot` constructor will catch the mismatch anyway), and
    only verify the hash on a dedicated "import" path.

- **`_exerciseToDomain` filters `setRows` per call** (O(N·M)). Bucket
  once by `sessionExerciseId` in `toDomain` and pass the bucket down.

- The discriminator-or-JSON pattern in `_reconstructState` is exactly
  the kind of place where Dart 3 sealed classes shine. If you make
  `ExerciseState` a sealed Freezed union (it already is), the switch
  is exhaustively checked. Currently the
  `final d => throw DeserializationError(...)` arm is reached only on a
  corrupt DB or a missed migration; the discriminator string lives in
  exactly one place — extract a private const map or, better, define
  `ExerciseState` with a `.discriminator` getter and a static
  `fromDiscriminator` to eliminate the magic-string list:

  ```dart
  static const _byDiscriminator = <String, ExerciseState Function(String?)>{
    'unfinished': _unfinished,
    'completed':  _completed,
    'skipped':    _skipped,
    'replaced':   _replaced,
  };
  ```

  Then a mapper that drifts ahead of the domain (new state added) fails
  in only one switch, not three.

- `sessionToRow`, `sessionExerciseToRow`, etc. build the discriminator
  string inline (e.g. `(discriminator, substituteJson) = switch (state)
  { ... }`). The discriminator string is also computed in
  `drift_session_repository.dart` (`'unfinished'`, `'completed'`,
  `'skipped'`, `'replaced'`). The literals **must** stay in sync. Pull
  them onto the sealed union as a `String get discriminator` getter and
  reference everywhere.

### `repositories/drift_program_repository.dart`

This is the largest and most issue-rich file. Detailed findings below.

```23:33:lib/modules/persistence/repositories/drift_program_repository.dart
class DriftProgramRepository implements ProgramRepository {
  DriftProgramRepository({required AppDatabase db, Clock clock = const Clock()})
    : _db = db,
      _clock = clock;

  final AppDatabase _db;
  final Clock _clock;
  final _uuid = const Uuid();
  final _programMapper = ProgramMapper();
  final _workoutDayMapper = WorkoutDayMapper();
```

- **Inject the UUID strategy.** `Uuid()` is non-deterministic and makes
  property-based tests harder. You already inject `Clock`; do the same
  for an `IdGenerator`-like interface that defaults to `() => const
  Uuid().v4()`. The existing `drift_program_repository_test.dart`
  hard-codes UUIDs in fixtures; an injectable generator makes round-trip
  tests easier.
- `_uuid` is `final` and not `const Uuid()` style — it actually is
  `const Uuid()`. Fine.
- `_programMapper` / `_workoutDayMapper` are stateless; promote to
  `static const` or `static final` to share across repositories.

#### `_nextUpdatedAt` is duplicated and slightly off

```34:46:lib/modules/persistence/repositories/drift_program_repository.dart
DateTime _nextUpdatedAt({
  required DateTime? previousUpdatedAt,
  required DateTime createdAt,
}) {
  final now = _clock.now().toUtc();
  final flooredByPrevious = previousUpdatedAt == null
      ? now
      : (now.isAfter(previousUpdatedAt)
            ? now
            : previousUpdatedAt.add(const Duration(milliseconds: 1)));
  return flooredByPrevious.isAfter(createdAt) ? flooredByPrevious : createdAt;
}
```

Issues:

- **Duplicated** verbatim in `drift_session_repository.dart`. Extract
  to a small `TimestampOracle` / `MonotonicClock` class that takes a
  `Clock` and exposes `nextAfter(DateTime previous, DateTime created)`.
- The `+1 ms` floor is a workaround for the ms-precision storage. With
  many fast updates (e.g. property tests that mutate 1k times), the
  timestamps walk forward indefinitely — and **those drifted timestamps
  become user-visible** when reading the domain object back. A cleaner
  primitive is a logical version counter (monotonic `int` stored on the
  row) for ordering, plus an honest `updatedAt` recording when the
  clock actually said. The current logic conflates "monotonic ordering"
  with "wall-clock time", which makes both unreliable.
- `now.isAfter(previousUpdatedAt)` returns `false` if `now ==
  previousUpdatedAt` to the millisecond, forcing the `+1`. Use
  `>=`-style comparison or move to microseconds.

#### Position assignment via `existing.length` is buggy in the presence of deletes

```154:165:lib/modules/persistence/repositories/drift_program_repository.dart
final existingDayIds = await _getWorkoutDayIdsForProgram(programId);
final newPosition = existingDayIds.length;
await _db
    .into(_db.programWorkoutDays)
    .insert(
      ProgramWorkoutDaysCompanion.insert(
        programId: programId,
        workoutDayId: id,
        position: newPosition,
      ),
    );
```

Same pattern occurs in `createExerciseGroup` (line 296), `createExercise`
(line 452), `createSet` (line 652).

Reproduction:

1. Create days A, B, C → positions 0, 1, 2.
2. `deleteWorkoutDay(B)` — `B`'s row is dropped but `C` keeps position
   2 (no compaction). `ProgramWorkoutDays` now has `(A,0)` and `(C,2)`.
3. `createWorkoutDay()` → `existingDayIds.length == 2` → tries to
   insert at position 2 → **`UNIQUE(programId, position)` violation**.

Fixes (pick one):

- Replace with `MAX(position) + 1`:

  ```dart
  final maxPos = await (_db.selectOnly(_db.programWorkoutDays)
        ..addColumns([_db.programWorkoutDays.position.max()])
        ..where(_db.programWorkoutDays.programId.equals(programId)))
      .map((r) => r.read(_db.programWorkoutDays.position.max()))
      .getSingleOrNull();
  final newPosition = (maxPos ?? -1) + 1;
  ```

- Adopt the gap-based positioning you already use in
  `DriftSessionRepository` (`_gap = 1024`), and renumber occasionally.
- Compact on `deleteWorkoutDay` etc. so `length` is always
  authoritative. Pick *one* invariant and stick to it across all four
  entities.

There is no test that exercises "create after delete" specifically —
`position_order_test.dart` does not cover it. Add one as part of the
fix.

#### `listPrograms` / `listWorkoutDaysForProgram` are N+1

```81:89:lib/modules/persistence/repositories/drift_program_repository.dart
Future<List<domain.Program>> listPrograms() async {
  final rows = await _db.select(_db.programs).get();
  final result = <domain.Program>[];
  for (final row in rows) {
    final dayIds = await _getWorkoutDayIdsForProgram(row.id);
    result.add(_programMapper.toDomain(row, dayIds));
  }
  return result;
}
```

For N programs you issue N+1 SQL statements. Replace with a single
join-like query:

```dart
final allLinks = await (_db.select(_db.programWorkoutDays)
      ..orderBy([
        (t) => OrderingTerm.asc(t.programId),
        (t) => OrderingTerm.asc(t.position),
      ]))
    .get();
final dayIdsByProgram = <String, List<String>>{};
for (final l in allLinks) {
  (dayIdsByProgram[l.programId] ??= []).add(l.workoutDayId);
}
```

Same pattern in `listWorkoutDaysForProgram` — it does N
`_loadWorkoutDay` calls, each of which itself fires 4 statements →
4N+1 round-trips. Drift's `select().join(...)` or
`customSelect` with a `WITH` clause is the right tool here.

In Flutter, also consider returning a `Stream<List<Program>>` via
`.watch()`: today every list view will need imperative
re-fetch-on-write, but Drift already gives you `Stream` for free with
`select(...).watch()`.

#### Reorder operations: 2×N writes, no `batch()`

```260:275:lib/modules/persistence/repositories/drift_program_repository.dart
final offset = orderedWorkoutDayIds.length + 1000;
for (var i = 0; i < orderedWorkoutDayIds.length; i++) {
  await (_db.update(_db.programWorkoutDays)..where( ... ))
      .write(ProgramWorkoutDaysCompanion(position: Value(offset + i)));
}
for (var i = 0; i < orderedWorkoutDayIds.length; i++) {
  await (_db.update(_db.programWorkoutDays)..where( ... ))
      .write(ProgramWorkoutDaysCompanion(position: Value(i)));
}
```

The "park then settle" dance exists because of the
`UNIQUE(programId, position)` constraint. Problems:

- 2N statements, each its own `UPDATE` over a single row.
  `_db.batch((b) => ...)` issues all writes in one transaction round-trip.
- The magic number `length + 1000` invites an undetected bug if the
  caller reorders >1000 items in some future place.
- `_reconcileExerciseSets` mixes "park new sets at `offset + i`" with
  "park then settle on existing sets", which interleaves writes and is
  hard to reason about.

Idiomatic alternatives, in order of effort:

1. Wrap the existing two-pass loop in `_db.batch((b) => b.update(...))`
   — single round-trip, smallest diff.
2. Use temporary negative positions during reorder:
   ```dart
   await _db.batch((b) {
     for (var i = 0; i < ids.length; i++) {
       b.update(_db.programWorkoutDays,
         ProgramWorkoutDaysCompanion(position: Value(-(i + 1))),
         where: (t) => t.programId.equals(programId) & t.workoutDayId.equals(ids[i]));
     }
     for (var i = 0; i < ids.length; i++) {
       b.update(_db.programWorkoutDays,
         ProgramWorkoutDaysCompanion(position: Value(i)),
         where: (t) => t.programId.equals(programId) & t.workoutDayId.equals(ids[i]));
     }
   });
   ```
   Add a `CHECK (position >= 0)` constraint only after the migration to
   ensure the temporary state never escapes a transaction.
3. Drop the UNIQUE on `(parent, position)` and rely entirely on
   `ORDER BY position`. Allows duplicates (which the application then
   has to prevent), but reorders become a single batch of N writes with
   no parking dance. Trade-off: you lose a real DB-level integrity
   check, which has been useful as a circuit-breaker (see the buggy
   `existing.length` above — that bug is caught loudly today because
   the UNIQUE fires).

For consistency: the **same** reorder code is copy-pasted four times
with different table types. Either parametrise (Drift makes that
awkward with strong typing — perhaps an extension method per table) or
accept the duplication but at least extract the magic number.

#### `_reconcileExerciseSets` is hard to follow and has two subtle issues

```528:595:lib/modules/persistence/repositories/drift_program_repository.dart
Future<void> _reconcileExerciseSets( ... ) async {
  final existingRows = await (_db.select( ... )).get();
  final existingById = {for (final r in existingRows) r.id: r};
  final desiredIds = exercise.sets.map((s) => s.id).toSet();

  for (final existing in existingRows) {
    if (!desiredIds.contains(existing.id)) {
      await (_db.delete( ... )).go();
    }
  }
  ...
}
```

- The delete loop issues one statement per removed set. `_db.delete(_db.workoutSets)..where((t) => t.id.isIn(toRemove))` is one statement.
- The final "settle" loop runs an unconditional update of `position`
  for every set, even if the position didn't change. Skipping the
  no-op writes both removes spurious `updated_at` bumps elsewhere and
  saves I/O. (Currently `_reconcileExerciseSets` doesn't update
  `updatedAt` in the settle loop, which is good — but it also means
  the parked timestamps and the settled positions are written under
  different `updatedAt` policies than the rest of the codebase. That's
  a smell to call out.)
- Identity is by `set.id`: a domain caller that mints a fresh id for a
  set that was just edited will silently delete-and-reinsert it.
  Worth a comment near the method to clarify the contract.

#### `saveProgramAggregate` doesn't validate input

```740:847:lib/modules/persistence/repositories/drift_program_repository.dart
Future<domain.Program> saveProgramAggregate(
  ProgramAggregate aggregate,
) async {
  return _db.transaction(() async {
    await _db.into(_db.programs).insert( ... );
    for (final day in aggregate.workoutDays) { ... }
    final program = await getProgram(aggregate.id);
    return program!;
  });
}
```

- No upsert: if `aggregate.id` already exists, you get a UNIQUE
  violation from SQLite (raw `SqliteException`). Either document the
  contract ("aggregate id must be new") or use
  `insertOnConflictUpdate` / `InsertMode.replace`.
- No structural validation. Today the aggregate is built by the
  program-management module which is presumably trusted, but a domain
  invariant violation (e.g. `day.programId != aggregate.id`) silently
  cascades — the row goes in with `programId` from the day, not from
  the aggregate. Add `assert(day.programId == aggregate.id)` (cheap)
  and a real check that throws `ValidationError` in production.
- `final program = await getProgram(aggregate.id); return program!;`
  — the `!` is safe (we just inserted) but a `getProgram` here means
  the whole listing N+1 you fixed earlier comes back. Better:
  reconstruct the `Program` from the aggregate directly.

#### Inconsistent error semantics

- `deleteProgram`, `deleteWorkoutDay`, `deleteExerciseGroup`,
  `deleteExercise`, `deleteSet` never raise `NotFoundError`; deleting
  a non-existent row is a silent no-op.
- `updateProgram`, `updateExercise`, etc. do raise `NotFoundError`.
- `getProgram`, `getExercise`, `getWorkoutDay` return `null` (good
  Dart idiom, but inconsistent with `getSessionByExerciseId` /
  `getSessionByExecutedSetId` in the session repository, which throw).

Pick a convention and document it on the abstract repository.

#### `getExercise` double-fetches

```481:487:lib/modules/persistence/repositories/drift_program_repository.dart
Future<domain.Exercise?> getExercise(String exerciseId) async {
  final row = await (_db.select(
    _db.exercises,
  )..where((t) => t.id.equals(exerciseId))).getSingleOrNull();
  if (row == null) return null;
  return _loadExercise(exerciseId);
}
```

`_loadExercise` runs another `getSingle()` on `exercises`. Pass the
already-fetched row in, or just check existence inside `_loadExercise`
and return `null`.

### `repositories/drift_session_repository.dart`

```21:35:lib/modules/persistence/repositories/drift_session_repository.dart
class DriftSessionRepository implements SessionRepository {
  DriftSessionRepository({
    required AppDatabase db,
    required DriftProgramRepository programRepository,
    Clock clock = const Clock(),
  }) : _db = db,
       _programRepository = programRepository,
       _clock = clock;

  final AppDatabase _db;
  final DriftProgramRepository _programRepository;
```

- **Concrete dependency.** The constructor demands a
  `DriftProgramRepository`, not the abstract `ProgramRepository`. That
  defeats the purpose of having the interface — tests can't substitute
  the program repo with a fake, and `DriftSessionRepository` is bound
  to the Drift implementation forever. Type the parameter as
  `ProgramRepository`.
- Better still, depend on only the operation you need:

  ```dart
  typedef WorkoutDayLoader = Future<WorkoutDay?> Function(String id);
  DriftSessionRepository({ ..., required WorkoutDayLoader loadWorkoutDay });
  ```

  This drops a class-level dependency to a single function pointer.

#### `_gap`-based positioning, locked vs unfinished

```81:102:lib/modules/persistence/repositories/drift_session_repository.dart
var position = 0;
for (final group in workoutDay.exerciseGroups) {
  for (final exercise in group.exercises) {
    final exerciseId = _uuid.v4();
    await _db.into(_db.sessionExercises).insert(
      SessionExercisesCompanion.insert(
        ...
        position: position * _gap,
        ...
      ),
    );
    position++;
  }
}
```

- Each iteration is an `INSERT`; this should be one
  `_db.batch((b) => b.insertAll(_db.sessionExercises, [...]))`.
- The gap-positioning approach is fine, but the constant `_gap = 1024`
  combined with `lockedPos + i * _gap` in `_renumberUnfinishedAfterLock`
  means a session with >2147483647/1024 ≈ 2M reorder operations could
  overflow `int32` — not a real concern on mobile but worth noting if
  reorders are ever batched.

#### `_maxLockedPositionExcluding` / `_maxLockedPosition` could be `MAX(position)`

```773:801:lib/modules/persistence/repositories/drift_session_repository.dart
Future<int> _maxLockedPosition(String sessionId) async {
  final lockedExercises =
      await (_db.select(_db.sessionExercises)
            ..where(
              (t) =>
                  t.sessionId.equals(sessionId) &
                  t.stateDiscriminator.isNotIn(['unfinished']),
            )
            ..orderBy([(t) => OrderingTerm.desc(t.position)]))
          .get();
  return lockedExercises.isEmpty ? 0 : lockedExercises.first.position;
}
```

Fetches **all** locked exercises, sorts, takes the first. Should be
`SELECT MAX(position) ...` via `selectOnly`/`addColumns(t.position.max())`
— O(1) bytes vs O(N) rows.

#### `completeSet` reparses the snapshot **twice** per call

```234:237:lib/modules/persistence/repositories/drift_session_repository.dart
final plannedSetCount = _plannedSetCountForExercise(
  exerciseRow,
  sessionRow,
);
```

`_plannedSetCountForExercise` and `_measurementTypeForExercise` each do
`jsonDecode(sessionRow.snapshotJson) as Map<String, dynamic>` and walk
the whole tree. For a session with 30 sets across 5 exercises, that's
60 full snapshot deserialisations during a workout — not catastrophic,
but trivially fixable by memoising once per public method:

```dart
final snapshotDay = _parseSnapshotWorkoutDay(sessionRow);
final measurementType = _findInSnapshot(snapshotDay, exerciseRow);
final plannedSetCount = _findInSnapshot(snapshotDay, exerciseRow).sets.length;
```

Or, since the snapshot is immutable, cache the parsed `WorkoutDay`
keyed by `sessionId` for the lifetime of the repository.

#### `endSession` and `startSession` lack invariant checks

- `endSession` doesn't reject calling end on an already-ended session.
  Today the only effect is that `endedAtMs` gets overwritten with a
  later wall-clock — silent state corruption from a UI re-tap.
  Throw `ImmutabilityError` (which exists in your error enum) if
  `row.endedAtMs != null`.
- `startSession` accepts any `workoutDayId` for which a day exists —
  even if the day's program has been deleted. By design? Add a doc
  comment.

#### `_validateActualValues` is domain logic

```876:894:lib/modules/persistence/repositories/drift_session_repository.dart
void _validateActualValues({ ... }) {
  final isValid = switch ((measurementType, actualValues)) {
    (RepBasedMeasurement(), ActualRepBased()) => true,
    (TimeBasedMeasurement(), ActualTimeBased()) => true,
    _ => false,
  };
  if (!isValid) { throw ValidationError(...); }
}
```

This is a pure domain rule. Move it onto `ExecutedSet` (the
constructor body) or `ActualSetValues.assertMatches(MeasurementType)`.
Then any caller — repository or service — gets the same enforcement
for free, and a future GraphQL/REST layer doesn't have to remember to
re-validate.

#### `createSuperset` / `removeSuperset` don't validate that exercises belong to the session

```575:611:lib/modules/persistence/repositories/drift_session_repository.dart
for (final id in sessionExerciseIds) {
  final exerciseRow = await _requireSessionExerciseRow(id);
  ...
}
```

`_requireSessionExerciseRow` only checks that the id exists, not that
its `sessionId == sessionId` (the method's input). A buggy caller
could "create a superset" across two different sessions. Cheap
validation: `if (exerciseRow.sessionId != sessionId) throw …`.

#### Imports

- `import 'dart:convert';` plus `jsonDecode` are pulled into the
  repository for the snapshot parsing. Move that logic into a
  `SessionSnapshot.parse(...)` static on the domain model so the
  repository doesn't depend on `dart:convert`.

---

## Cross-cutting items

### A. Test coverage

Coverage is strong on the obvious paths (cascade deletes, FK pragma,
position ordering, snapshot immutability, timestamp monotonicity,
identity invariants). Gaps I noticed:

- **No test for `create-after-delete`** position collision (issue #1).
- **No test for `endSession` called twice**.
- **No test for `createSuperset` across two sessions**.
- **No N+1 / performance test**. Even a smoke test that asserts the
  number of statements (`db.executor.runSelect`) for `listPrograms`
  with 5 programs is `<= K` would catch regressions.
- **No fuzz / property test for snapshot hash** beyond the canonical
  golden tests in `test/serialization`.

### B. Concurrency & isolates

- Drift runs everything on the calling isolate unless you opt into
  `DriftIsolate`. On a mobile device the UI isolate is also doing
  layout, animations, etc., and the synchronous SQLite calls block it.
  For large lists (years of session history) this will show as
  scroll jank.
- `LazyDatabase(() async => NativeDatabase.createInBackground(...))` is
  the canonical incantation for `drift_flutter` users; consider it
  when sessions are first being persisted in volume.

### C. Streams

You're returning `Future<List<X>>` everywhere. Drift's killer feature
is `Stream<List<X>>` via `.watch()` — your `BLoC`s could subscribe
once and never need to invalidate. For the list-heavy screens (program
list, session list) this is a low-risk, high-reward refactor.

### D. Generated code in version control

`app_database.g.dart` (11k lines) lives in the repo. Two camps on
this: (a) commit, to make IDE/build behaviour reproducible without
running `build_runner`; (b) gitignore, to avoid noisy diffs on every
regen. Whichever you pick, add a CI step that fails if
`dart run build_runner build --delete-conflicting-outputs` produces a
diff against the committed file. Today nothing prevents a drift
between annotations and generated output.

### E. `dart:async` / `unawaited` linting

`unawaited_futures` is enabled in `analysis_options.yaml`. The
repositories `await` everything they should; nothing leaks. Good.

### F. `analysis_options.yaml` could be stricter

You already have `strict-casts`, `strict-inference`, `strict-raw-types`
— excellent. Consider adding (or upgrading to `package:lints/strict`
or `package:very_good_analysis`):

- `prefer_final_in_for_each`
- `prefer_const_literals_to_create_immutables`
- `unnecessary_lambdas`
- `require_trailing_commas` (you already format that way)
- `avoid_returning_this`, `cascade_invocations`
- `unawaited_futures` is on; pair with `discarded_futures` to catch
  the case where someone calls `repo.deleteProgram(id)` without
  `await`ing.

---

## Suggested action list

In priority order, here's what I'd tackle first if I owned this module:

1. **Fix position assignment** (`existing.length` → `MAX(position) + 1`
   or compaction on delete). Add a regression test.
2. **Add indexes** on `Sessions.workoutDayId`, `SessionNotes.sessionId`,
   `SessionExercises.{sessionId, stateDiscriminator}`. Bump
   `SchemaVersions.drift`, write the migration.
3. **De-N+1** `listPrograms`, `listWorkoutDaysForProgram`,
   `listSessionsForWorkoutDay` — one query per call, plus an
   in-memory join.
4. **Batch the reorder loops** with `_db.batch(...)`; extract the
   parking constant. Choose one positioning strategy and apply it
   consistently to all four entities.
5. **Decouple session repo from program repo** — depend on
   `ProgramRepository` or a `WorkoutDayLoader`.
6. **Cache the parsed snapshot** within `completeSet` /
   `updateExecutedSet`; skip recomputing the hash on the read path.
7. **Tighten error semantics**: deletes either throw or no-op,
   consistently across both repositories. Document on the interface.
8. **Extract `_nextUpdatedAt`** to a `MonotonicClock`; consider moving
   to a logical version counter for ordering.
9. **Move `_validateActualValues`** onto the domain. Add the
   "session-membership" check to `createSuperset` / `removeSuperset`.
10. **Clean up the barrel** (`persistence.dart`) or delete it.
11. **Migrate `…AtMs` → Drift's native `DateTime` columns** when you do
    the next schema bump. Lots of cleanup downstream.

---

## Appendix — Tooling recommendations

- **`drift_dev` schema verification** in CI: `dart run drift_dev
  schema dump lib/modules/persistence/database/app_database.dart
  drift_schemas/` and a follow-up `dart run drift_dev schema verify
  drift_schemas/` step. Guarantees that any annotation change without
  a corresponding migration fails the build.
- **`dart_code_metrics`** for cyclomatic complexity. The two repos
  here are around 900 lines each, with several 60-line methods; the
  tool would flag the worst offenders objectively.
- **`coverage` package** with `dart pub global activate coverage` plus
  `dart run coverage:test_with_coverage` — your existing tests are
  thorough, a measured number would make that visible.
- **`integration_test`** for one end-to-end Flutter test that drives
  through `bootstrap()` → BLoC → DB to catch wiring regressions; today
  every test uses `NativeDatabase.memory()` and never exercises
  `drift_flutter`'s `driftDatabase(name: 'zamaj')` factory.
