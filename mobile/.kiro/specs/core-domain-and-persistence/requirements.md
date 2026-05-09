# Requirements Document

## Introduction

Zamaj is an offline-first Flutter workout execution app. This spec defines the
foundational **core domain model and persistence layer** that every subsequent
feature (program management, workout day picker, session flow engine, overview
screen, focus mode, rest timer, export) will build on.

The layer covers:

- Immutable, strongly-typed domain entities (programs, workout days, exercises,
  exercise groups, sets, sessions, executed sets, session exercises, notes,
  extra work) modeled with freezed sealed classes.
- A Drift-backed SQLite persistence layer with migration support.
- Repository contract interfaces that decouple services and BLoCs from the
  concrete database.
- Sync-ready primitives baked in from day one (UUIDv4 identity, monotonic
  timestamps, schema version), even though no network sync is implemented in
  this spec.
- JSON serialization sufficient for export, future cloud sync, and testing.

This spec delivers NO UI, NO BLoCs, NO screens, NO flow engine, NO rest timer,
NO parser, NO export formatter, and NO cloud sync implementation. Those live
in follow-up specs.

Note on future extensibility: workout structure has three orthogonal
dimensions — measurement type (how one set is measured), exercise group kind
(how multiple exercises within a workout day relate), and set group kind (how
multiple sets within one exercise relate). This spec models the first two as
extensible sealed families. Set-level grouping (dropset, pyramid, cluster,
and similar patterns) is explicitly out of scope here; in this spec all sets
are implicit straight sets, and a Set_Group_Kind sealed family will be
introduced in a future spec when it is first needed.

## Glossary

- **Domain_Model**: The pure Dart layer of freezed/sealed value types that
  describe programs, sessions, and their components. Contains no I/O.
- **Persistence_Layer**: The Drift-backed SQLite layer. Holds tables, DAOs,
  migrations, and schema version tracking.
- **Repository_Layer**: The set of abstract interfaces (Dart abstract classes)
  that sit between services/BLoCs and the `Persistence_Layer`. Concrete
  implementations are provided by this spec and backed by Drift.
- **Serialization_Layer**: The freezed + json_serializable generated code that
  converts `Domain_Model` values to and from JSON maps.
- **Program**: A training block (mesocycle) owned by a user, composed of one or
  more `Workout_Day` templates.
- **Workout_Day**: A reusable template such as "Upper A", composed of an
  ordered list of `Exercise_Group` entries.
- **Exercise_Group**: A grouping of one or more planned `Exercise` entries.
  Initially either a single-exercise group or a superset group. The grouping
  kind is represented as a sealed variant of `Exercise_Group_Kind`.
- **Exercise**: A planned movement inside a `Workout_Day` template. Owns a
  `Measurement_Type`, an ordered list of planned `Set` entries, and optional
  `Exercise_Metadata`.
- **Set**: A single planned performance unit attached to an `Exercise`, carrying
  planned values appropriate to the exercise's `Measurement_Type` (for example
  planned weight and reps, or planned duration). Implemented as the Dart type
  `WorkoutSet` to avoid shadowing `dart:core` `Set<T>`.
- **Measurement_Type**: A sealed variant describing how an exercise is measured.
  Initial variants are `RepBased` (weight + reps) and `TimeBased` (duration).
  Additional variants may be added later without changing existing variants.
- **Exercise_Metadata**: Optional descriptive fields attached to an `Exercise`,
  currently notes and an external video URL.
- **Session**: A single execution instance of a `Workout_Day`. Owns a
  `Session_Snapshot`, an ordered list of `Session_Exercise` entries, zero or
  more `Extra_Work` entries, and zero or more `Session_Note` entries.
- **Session_Snapshot**: An immutable copy of the `Workout_Day` template and all
  of its planned structure, captured at the moment a `Session` is started.
- **Session_Exercise**: A runtime execution wrapper around one planned or
  replaced exercise inside a `Session`. Has a state of `Unfinished`,
  `Completed`, `Skipped`, or `Replaced`, an ordered list of `Executed_Set`
  entries, and, when state is `Replaced`, a reference to both the original
  planned exercise in the snapshot and the substitute exercise actually
  performed.
- **Executed_Set**: The actual performed values for a single set, paired with
  the corresponding planned set in the snapshot when one exists.
- **Extra_Work**: Unplanned additional work attached to a `Session`. Initially
  a free-form text note.
- **Session_Note**: A free-form note attached to a `Session`.
- **Exercise_State**: The lifecycle state of a `Session_Exercise`. One of
  `Unfinished`, `Completed`, `Skipped`, `Replaced`.
- **UUIDv4**: A version 4 universally unique identifier, encoded as its
  canonical 36-character string form.
- **Schema_Version**: A monotonically increasing integer that identifies the
  current shape of the persisted database and of serialized payloads.

## Requirements

### Requirement 1: Program and Workout Day Domain Model

**User Story:** As a developer building the program-management spec, I want
strongly-typed program and workout day value objects, so that coaches' planned
structures can be represented without ambiguity and without conflating planned
and actual data.

#### Acceptance Criteria

1. THE Domain_Model SHALL expose an immutable `Program` type that carries an id
   of type UUIDv4, a name, a list of `Workout_Day` ids in their intended order,
   and the timestamp and schema_version fields required by Requirement 8.
2. THE Domain_Model SHALL expose an immutable `Workout_Day` type that carries
   an id of type UUIDv4, a name, a reference to its owning `Program` id, an
   ordered list of `Exercise_Group` entries, and the timestamp and
   schema_version fields required by Requirement 8.
3. THE Domain_Model SHALL expose an immutable `Exercise_Group` type that
   carries an id of type UUIDv4, a reference to its owning `Workout_Day` id, a
   zero-based position integer, an `Exercise_Group_Kind` value, and an ordered
   list of `Exercise` entries.
4. THE Domain_Model SHALL expose an immutable `Exercise` type that carries an
   id of type UUIDv4, a reference to its owning `Exercise_Group` id, a
   zero-based position integer within the group, a name, a `Measurement_Type`
   value, an `Exercise_Metadata` value, and an ordered list of planned `Set`
   entries.
5. THE Domain_Model SHALL expose an immutable `Set` type that carries an id of
   type UUIDv4, a reference to its owning `Exercise` id, a zero-based position
   integer within the exercise, and planned values whose fields are determined
   by the owning exercise's `Measurement_Type`.
6. THE Domain_Model SHALL expose an immutable `Exercise_Metadata` type that
   carries an optional notes string and an optional external video URL string.

### Requirement 2: Extensible Measurement Type

**User Story:** As a developer, I want measurement types modeled as an
extensible sealed family, so that future measurement variants (RPE/RIR-anchored,
distance-based, and so on) can be added without breaking existing stored data
or client code.

#### Acceptance Criteria

1. THE Domain_Model SHALL represent `Measurement_Type` as a sealed Dart class
   hierarchy whose initial variants are `RepBased` and `TimeBased`.
2. THE `RepBased` variant SHALL carry planned weight in kilograms as a
   non-negative decimal with a resolution of 0.5 kilograms and planned
   repetitions as a non-negative integer.
3. THE `TimeBased` variant SHALL carry planned duration as a non-negative
   integer number of seconds.
4. WHEN a new `Measurement_Type` variant is added in a future spec, THE
   Serialization_Layer SHALL continue to deserialize previously serialized
   payloads of existing variants without data loss.
5. IF the Serialization_Layer encounters a `Measurement_Type` discriminator
   that is not recognized by the current build, THEN THE Serialization_Layer
   SHALL return a typed deserialization error that names the unknown
   discriminator.
6. THE Persistence_Layer SHALL store the `Measurement_Type` variant and its
   variant-specific fields in a form that does not require altering existing
   columns when a new variant is added, for example by persisting the
   discriminator and a typed payload rather than a fixed per-variant column
   layout.

### Requirement 3: Extensible Exercise Group Kind

**User Story:** As a developer, I want exercise group kinds modeled as an
extensible sealed family, so that future group kinds (Circuit, Giant set) can
be added later without migrating every existing row.

#### Acceptance Criteria

1. THE Domain_Model SHALL represent `Exercise_Group_Kind` as a sealed Dart
   class hierarchy whose initial variants are `Single` and `Superset`.
2. THE `Single` variant SHALL require the owning `Exercise_Group` to contain
   exactly one `Exercise`.
3. THE `Superset` variant SHALL require the owning `Exercise_Group` to contain
   two or more `Exercise` entries.
4. IF an `Exercise_Group` is constructed whose `Exercise_Group_Kind` cardinality
   constraint is violated, THEN THE Domain_Model SHALL reject the construction
   with a typed validation error that names the violated constraint.
5. WHEN a new `Exercise_Group_Kind` variant is added in a future spec, THE
   Serialization_Layer SHALL continue to deserialize previously serialized
   payloads of existing variants without data loss.
6. THE Persistence_Layer SHALL store `Exercise_Group_Kind` using a
   discriminator-plus-payload encoding so that adding a new variant does not
   require altering columns that store existing variants.

### Requirement 4: Session and Execution Domain Model

**User Story:** As a developer building the session flow engine, I want a
session model that tracks execution state independently from the planning
structure, so that real gym behavior (skips, replacements, extra work, notes)
is captured without corrupting the planned program.

#### Acceptance Criteria

1. THE Domain_Model SHALL expose an immutable `Session` type that carries an
   id of type UUIDv4, a reference to the source `Workout_Day` id, a
   `Session_Snapshot`, an ordered list of `Session_Exercise` entries, a list
   of `Extra_Work` entries, a list of `Session_Note` entries, a started_at
   timestamp, an optional ended_at timestamp, and the timestamp and
   schema_version fields required by Requirement 8.
2. THE Domain_Model SHALL expose an immutable `Session_Exercise` type that
   carries an id of type UUIDv4, a reference to its owning `Session` id, a
   zero-based position integer within the session, an `Exercise_State`, an
   ordered list of `Executed_Set` entries, a reference to the planned exercise
   id within the snapshot that this session exercise corresponds to, and,
   when `Exercise_State` is `Replaced`, an additional replacement exercise
   payload as described in Requirement 5.
3. THE Domain_Model SHALL expose an immutable `Executed_Set` type that carries
   an id of type UUIDv4, a reference to its owning `Session_Exercise` id, a
   zero-based position integer, the actual performed values, an optional
   reference to the planned set id within the snapshot that this executed set
   corresponds to, and a completed_at timestamp.
4. THE Domain_Model SHALL represent `Exercise_State` as a sealed Dart
   enumeration whose values are `Unfinished`, `Completed`, `Skipped`, and
   `Replaced`.
5. THE Domain_Model SHALL expose an immutable `Session_Note` type that carries
   an id of type UUIDv4, a reference to its owning `Session` id, a free-form
   body string, and a created_at timestamp.
6. THE Domain_Model SHALL expose an immutable `Extra_Work` type that carries
   an id of type UUIDv4, a reference to its owning `Session` id, a zero-based
   position integer, and a free-form body string.
7. THE Domain_Model SHALL never store planned values and actual values in the
   same field; planned values SHALL be reachable only through the
   `Session_Snapshot` and actual values SHALL be reachable only through
   `Session_Exercise` and `Executed_Set`.

### Requirement 5: Exercise Replacement Preserves Planned Reference

**User Story:** As an athlete who swapped out an exercise mid-session due to
pain or equipment, I want the session to record both what was planned and what
I actually did, so that my coach can review the substitution without the
underlying program being modified.

#### Acceptance Criteria

1. WHEN a `Session_Exercise` has an `Exercise_State` of `Replaced`, THE
   Domain_Model SHALL require that the `Session_Exercise` carry a non-null
   reference to the original planned exercise id within the `Session_Snapshot`.
2. WHEN a `Session_Exercise` has an `Exercise_State` of `Replaced`, THE
   Domain_Model SHALL require that the `Session_Exercise` carry a non-null
   substitute exercise payload consisting of a name, a `Measurement_Type`,
   and optional `Exercise_Metadata`.
3. WHEN a replacement is recorded on a `Session_Exercise`, THE Repository_Layer
   SHALL NOT modify any row belonging to the source `Workout_Day`, `Program`,
   `Exercise_Group`, `Exercise`, or `Set` template tables.
4. IF a `Session_Exercise` has an `Exercise_State` other than `Replaced`, THEN
   THE Domain_Model SHALL require that the substitute exercise payload defined
   in Acceptance Criterion 2 is null.
5. WHEN application code reads a `Session_Exercise` whose `Exercise_State` is
   `Replaced`, THE Repository_Layer SHALL return both the original planned
   exercise from the snapshot and the substitute exercise payload in the
   returned value.

### Requirement 6: Session Snapshot Immutability

**User Story:** As a coach reviewing historical sessions, I want each session
to preserve exactly what was planned at the moment of execution, so that later
edits to the program do not rewrite history.

#### Acceptance Criteria

1. WHEN a new `Session` is created for a given `Workout_Day`, THE
   Repository_Layer SHALL capture a `Session_Snapshot` containing a deep copy
   of that `Workout_Day` and of every `Exercise_Group`, `Exercise`, `Set`, and
   `Exercise_Metadata` reachable from it at the moment of creation.
2. THE Repository_Layer SHALL store every `Session_Snapshot` in a location
   independent from the live template tables defined by Requirement 1, so that
   later writes to template tables do not alter any stored `Session_Snapshot`.
3. WHEN any template row reachable from a given `Workout_Day` is updated,
   inserted, or deleted after a `Session` referencing that `Workout_Day` has
   been created, THE Repository_Layer SHALL return the same bytes for that
   `Session`'s `Session_Snapshot` on every subsequent read as it would have
   returned immediately after session creation.
4. THE Repository_Layer SHALL NOT expose any write method that mutates an
   existing `Session_Snapshot`.
5. IF application code attempts to persist a modified `Session_Snapshot` for an
   existing `Session`, THEN THE Repository_Layer SHALL reject the write with a
   typed immutability error that names the session id.

### Requirement 7: Completed Exercise Ordering Is Locked

**User Story:** As an athlete mid-workout, I want exercises I have already
finished to stay pinned in the order I did them, while the rest of the workout
remains free to be reordered, so that my session history reflects reality.

#### Acceptance Criteria

1. THE Domain_Model SHALL treat the position integer of any `Session_Exercise`
   whose `Exercise_State` is `Completed`, `Skipped`, or `Replaced` as locked.
2. THE Domain_Model SHALL permit updating the position integer of any
   `Session_Exercise` whose `Exercise_State` is `Unfinished`.
3. IF a repository write attempts to change the position integer of a
   `Session_Exercise` whose `Exercise_State` is not `Unfinished`, THEN THE
   Repository_Layer SHALL reject the write with a typed ordering error that
   names the session exercise id and its current state.
4. WHEN a `Session_Exercise` transitions from `Unfinished` to any other
   `Exercise_State`, THE Repository_Layer SHALL assign that `Session_Exercise`
   a position integer greater than or equal to the position integer of every
   already-locked `Session_Exercise` in the same `Session`.
5. THE Repository_Layer SHALL preserve a total ordering over all
   `Session_Exercise` entries within a `Session`, with no two entries sharing
   the same position integer.

### Requirement 8: Sync-Ready Identity and Timestamp Primitives

**User Story:** As a product owner planning for future cloud sync, I want
every persisted entity to carry stable identifiers, timestamp metadata, and a
schema version from day one, so that sync and export can be added later
without a disruptive migration.

#### Acceptance Criteria

1. THE Persistence_Layer SHALL assign every persisted row an id encoded as the
   canonical 36-character string form of a UUIDv4.
2. THE Repository_Layer SHALL require every entity type exposed by
   Requirements 1 and 4 to expose a `created_at`, `updated_at`, and
   `schema_version` field in its persisted representation.
3. THE Repository_Layer SHALL populate `created_at` when a row is first
   inserted and SHALL NOT modify `created_at` on any subsequent write.
4. WHEN a row is updated, THE Repository_Layer SHALL set `updated_at` to a
   monotonically non-decreasing timestamp that is greater than or equal to the
   row's previous `updated_at` value and greater than or equal to the row's
   `created_at` value.
5. THE Persistence_Layer SHALL maintain a single `Schema_Version` integer
   associated with the database as a whole and SHALL stamp every written row
   with the `Schema_Version` value in effect at the time of the write.
6. IF two rows belonging to the same entity type are inserted, THEN THE
   Repository_Layer SHALL guarantee that their assigned ids are distinct.
7. THE Repository_Layer SHALL guarantee that no two rows across any entity
   types exposed by Requirements 1 and 4 share the same UUIDv4 id value.

### Requirement 9: Drift Persistence and Migrations

**User Story:** As a developer, I want a typed Drift-based SQLite persistence
layer with first-class migration support, so that the schema can evolve in
lock-step with domain changes while preserving stored sessions and programs.

#### Acceptance Criteria

1. THE Persistence_Layer SHALL use the Drift library to define every table
   required to persist the entities exposed by Requirements 1 and 4.
2. THE Persistence_Layer SHALL expose a single opened database instance to the
   Repository_Layer and SHALL NOT perform any network I/O.
3. THE Persistence_Layer SHALL declare an integer `schemaVersion` matching the
   `Schema_Version` value used by Requirement 8.
4. WHEN the app opens a database whose persisted `schemaVersion` is less than
   the current `schemaVersion`, THE Persistence_Layer SHALL run the registered
   migration callbacks in increasing version order until the database is at
   the current `schemaVersion` before any repository method returns.
5. IF the app opens a database whose persisted `schemaVersion` is greater than
   the current `schemaVersion`, THEN THE Persistence_Layer SHALL refuse to
   open the database and SHALL return a typed version-mismatch error that
   names both the persisted and the expected versions.
6. THE Persistence_Layer SHALL enforce foreign key constraints consistent with
   the ownership relationships described in Requirements 1 and 4.

### Requirement 10: Repository Contracts

**User Story:** As a developer writing services and BLoCs in follow-up specs,
I want narrow, stable repository interfaces, so that the UI and services
depend only on a domain-facing API and not on Drift-specific types.

#### Acceptance Criteria

1. THE Repository_Layer SHALL expose a `ProgramRepository` abstract Dart
   interface whose methods return, accept, and are typed in terms of
   Domain_Model types only, with no Drift-generated types in any public
   signature.
2. THE Repository_Layer SHALL expose a `SessionRepository` abstract Dart
   interface whose methods return, accept, and are typed in terms of
   Domain_Model types only, with no Drift-generated types in any public
   signature.
3. THE `ProgramRepository` SHALL provide methods to create, read, update,
   delete, and list programs, workout days, exercise groups, exercises, and
   sets.
4. THE `SessionRepository` SHALL provide methods to create a session with a
   captured `Session_Snapshot` per Requirement 6, to read a session by id, to
   list sessions for a given workout day, to append and update session
   exercises and executed sets subject to Requirements 5 and 7, and to add
   session notes and extra work entries.
5. THE Repository_Layer SHALL expose concrete Drift-backed implementations of
   both `ProgramRepository` and `SessionRepository` that use the
   Persistence_Layer defined by Requirement 9.
6. THE Repository_Layer SHALL NOT expose any method that returns a partially
   constructed entity; every returned entity SHALL satisfy every domain
   invariant declared in Requirements 1 through 7.

### Requirement 11: Serialization and JSON Round-Trip

**User Story:** As a developer planning for export and future cloud sync, I
want every domain entity to serialize to and from JSON losslessly, so that
session history can be exported today and synced or restored later without
schema-breaking changes.

#### Acceptance Criteria

1. THE Domain_Model SHALL be generated using freezed and json_serializable
   such that every type exposed by Requirements 1, 2, 3, and 4 provides a
   `fromJson` constructor and a `toJson` method.
2. FOR ALL `Domain_Model` values constructed through their public constructors,
   `fromJson(toJson(value))` SHALL produce a value equal to the original
   `value` under freezed-generated equality (round-trip property).
3. THE Serialization_Layer SHALL encode every sealed hierarchy, including
   `Measurement_Type`, `Exercise_Group_Kind`, and `Exercise_State`, using a
   named discriminator field so that future variants can be distinguished
   without ambiguity.
4. IF the Serialization_Layer encounters a required field that is missing or
   a discriminator that is unrecognized, THEN THE Serialization_Layer SHALL
   return a typed deserialization error that names the offending field or
   discriminator.
5. THE Serialization_Layer SHALL include the `schema_version` of each
   entity in its JSON output and SHALL accept the same field on input.

### Requirement 12: Offline-First Isolation

**User Story:** As a user training in a basement gym with no connectivity, I
want the domain and persistence layer to make no network calls at all, so
that the app is fully functional offline.

#### Acceptance Criteria

1. THE Domain_Model SHALL NOT import any package that performs network I/O.
2. THE Persistence_Layer SHALL NOT import any package that performs network
   I/O.
3. THE Repository_Layer SHALL NOT import any package that performs network
   I/O.
4. WHEN any repository method is invoked on a device with no network
   connectivity, THE Repository_Layer SHALL complete the operation using only
   local resources.

### Requirement 13: Domain Validation on Construction

**User Story:** As a developer, I want invalid domain values to be rejected at
construction time rather than at read time, so that bugs surface early and
the persisted data stays consistent.

#### Acceptance Criteria

1. WHEN an `Exercise_Group` is constructed, THE Domain_Model SHALL validate
   the cardinality constraint defined by Requirement 3.
2. WHEN a `Session_Exercise` is constructed with an `Exercise_State` of
   `Replaced`, THE Domain_Model SHALL validate the replacement-payload
   constraints defined by Requirement 5.
3. WHEN any `Set` is constructed, THE Domain_Model SHALL validate that its
   planned values are consistent with the `Measurement_Type` of the owning
   `Exercise`, including non-negativity of weight, repetitions, and duration
   per Requirement 2.
4. IF any construction-time validation fails, THEN THE Domain_Model SHALL
   return a typed validation error whose fields identify the offending entity
   id and the violated invariant, and SHALL NOT produce a partially
   constructed value.
