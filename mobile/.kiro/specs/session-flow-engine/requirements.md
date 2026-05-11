# Requirements Document

## Introduction

The Session Flow Engine is a pure-Dart service layer that orchestrates workout session execution in Zamaj. It sits between the `SessionRepository` (persistence) and the future UI/BLoC layer, providing cursor-based navigation, session lifecycle management, and all in-session mutation operations. This spec covers no UI — only the stateless service logic and the cursor state it exposes.

## Glossary

- **Engine**: The `SessionFlowEngine` service class that coordinates session operations
- **Session**: A runtime execution instance of a WorkoutDay, containing exercises, sets, notes, and extra work
- **Cursor**: A value object representing the current position in the session — the next unfinished exercise and set to perform
- **SessionExercise**: A single exercise within a session, tracking state and executed sets
- **ExecutedSet**: One logged performance unit with actual values and a completion timestamp
- **ExerciseState**: The sealed state of a SessionExercise: unfinished, completed, skipped, or replaced
- **Snapshot**: An immutable capture of the WorkoutDay at session start, preserving planned values
- **SubstituteExercise**: A replacement exercise chosen during session execution
- **ExtraWork**: Freeform additional unplanned work added to a session
- **SessionNote**: Freeform text note attached to a session
- **Clock**: An injectable time source used for deterministic timestamp generation

## Requirements

### Requirement 1: Session Creation

**User Story:** As a user, I want to start a new session from a workout day, so that I can begin executing my planned workout.

#### Acceptance Criteria

1. WHEN a workout day identifier is provided, THE Engine SHALL delegate to the SessionRepository.startSession to create a new Session with an immutable snapshot of the WorkoutDay captured at the current Clock time
2. WHEN a session is created, THE Engine SHALL return the new Session with all SessionExercises in the unfinished state, one per Exercise in the snapshot
3. WHEN a session is created, THE Engine SHALL compute an initial Cursor pointing to the first SessionExercise (position 0) at set index zero
4. IF the workout day identifier does not correspond to an existing WorkoutDay, THEN THE Engine SHALL signal a NotFoundError

### Requirement 2: Session Resumption

**User Story:** As a user, I want to resume an in-progress session, so that I can continue my workout after an interruption.

#### Acceptance Criteria

1. WHEN a valid session identifier is provided, THE Engine SHALL load the fully hydrated Session from the SessionRepository including all SessionExercises and ExecutedSets
2. WHEN a session is resumed, THE Engine SHALL compute the Cursor pointing to the next unfinished set of the first unfinished SessionExercise in position order
3. IF the session identifier does not correspond to an existing session, THEN THE Engine SHALL signal a NotFoundError
4. IF the session has already ended (endedAt is non-null), THE Engine SHALL still allow resumption for read-only queries and value editing but SHALL prevent new set completions

### Requirement 3: Session Ending

**User Story:** As a user, I want to end my session at any time, so that it is marked as complete even if I did not finish all exercises.

#### Acceptance Criteria

1. WHEN the user ends a session, THE Engine SHALL delegate to the SessionRepository to record the endedAt timestamp obtained from the injected Clock, regardless of whether all SessionExercises have been completed, skipped, or replaced
2. WHEN a session is ended, THE Engine SHALL return the updated Session with the endedAt field populated
3. THE Engine SHALL NOT require all exercises to be in a terminal state (completed, skipped, or replaced) before allowing end-session — exercises may remain in the unfinished state
4. IF the session already has a non-null endedAt value, THEN THE Engine SHALL signal an ImmutabilityError carrying the session identifier
5. IF the session identifier does not correspond to an existing session, THEN THE Engine SHALL signal a NotFoundError

### Requirement 4: Cursor Computation

**User Story:** As a user, I want to know which exercise and set is next, so that Focus Mode can guide me to the right place.

#### Acceptance Criteria

1. THE Engine SHALL compute the Cursor by iterating SessionExercises in ascending position order and selecting the first whose state is unfinished and whose executedSets.length is less than the planned set count for that exercise in the snapshot
2. THE Cursor SHALL expose the sessionExerciseId and the next set index (executedSets.length) for the identified exercise
3. WHEN all sets of the current exercise are completed (executedSets.length equals planned set count), THE Engine SHALL advance the Cursor to the next unfinished exercise in position order
4. WHEN all SessionExercises have state completed, skipped, or replaced-with-all-sets-done, THE Engine SHALL produce a terminal Cursor indicating session completion
5. THE Engine SHALL recompute the Cursor after every mutation operation that changes exercise state or set count, and expose the updated Cursor to callers

### Requirement 5: Set Completion

**User Story:** As a user, I want to log actual values for my current set, so that my performance is recorded.

#### Acceptance Criteria

1. WHEN actual set values are provided for the current cursor position, THE Engine SHALL delegate to the SessionRepository to persist a new ExecutedSet with the provided ActualSetValues and the current Clock timestamp, and return the updated Session
2. WHEN a set is completed and the exercise's executed set count remains less than the planned set count in the snapshot, THE Engine SHALL advance the Cursor to the next unfinished set of the same exercise
3. WHEN the completed set causes the exercise's executed set count to equal the planned set count in the snapshot, THE Engine SHALL transition the SessionExercise state to completed and advance the Cursor to the next unfinished exercise
4. IF the ActualSetValues variant does not match the exercise MeasurementType, THEN THE Engine SHALL signal a ValidationError
5. IF the session has already ended, THEN THE Engine SHALL signal an ImmutabilityError without persisting the set
6. IF the Cursor is in terminal state indicating all exercises are completed or skipped, THEN THE Engine SHALL signal a ValidationError without persisting the set

### Requirement 6: Executed Set Value Editing

**User Story:** As a user, I want to edit the values of a previously completed set, so that I can correct mistakes.

#### Acceptance Criteria

1. WHEN new ActualSetValues are provided for an existing ExecutedSet identified by its id, THE Engine SHALL delegate to the SessionRepository.updateExecutedSet to update the values
2. THE Engine SHALL allow editing of ExecutedSets regardless of the parent SessionExercise state (completed, skipped, or replaced exercises remain editable)
3. IF the provided ActualSetValues variant does not match the exercise MeasurementType, THEN THE Engine SHALL signal a ValidationError
4. IF the executedSetId does not correspond to an existing ExecutedSet, THEN THE Engine SHALL signal a NotFoundError

### Requirement 7: Exercise Skip

**User Story:** As a user, I want to skip an exercise I cannot perform, so that I can move on without blocking my session.

#### Acceptance Criteria

1. WHEN a skip is requested for a SessionExercise whose state is unfinished, THE Engine SHALL delegate to the SessionRepository.skipExercise to transition the exercise state to skipped
2. WHEN an exercise is skipped, THE Engine SHALL advance the Cursor past the skipped exercise to the next unfinished exercise in position order
3. IF the SessionExercise state is not unfinished (completed, skipped, or replaced), THEN THE Engine SHALL signal an OrderingError with the sessionExerciseId and current state
4. WHEN a skip causes all exercises to be non-unfinished, THE Engine SHALL produce a terminal Cursor

### Requirement 8: Exercise Replacement

**User Story:** As a user, I want to replace an exercise with a substitute, so that I can adapt to equipment availability or physical limitations.

#### Acceptance Criteria

1. WHEN a replacement is requested with a substitute name and MeasurementType for a SessionExercise whose state is unfinished, THE Engine SHALL delegate to the SessionRepository.replaceExercise to transition the exercise state to replaced with the SubstituteExercise
2. WHEN an exercise is replaced, THE Engine SHALL preserve the plannedExerciseIdInSnapshot reference on the SessionExercise unchanged
3. WHEN an exercise is replaced, THE Engine SHALL allow subsequent set completions against the replaced exercise using the substitute's MeasurementType for ActualSetValues validation
4. IF the SessionExercise state is not unfinished, THEN THE Engine SHALL signal an OrderingError with the sessionExerciseId and current state
5. WHEN a replacement is performed, THE Engine SHALL NOT advance the Cursor — the replaced exercise remains the current exercise for set completion

### Requirement 9: Exercise Reordering

**User Story:** As a user, I want to reorder unfinished exercises, so that I can adapt to gym conditions.

#### Acceptance Criteria

1. WHEN a new ordering of unfinished SessionExercise identifiers is provided, THE Engine SHALL delegate to the SessionRepository.reorderUnfinished to update positions while preserving completed exercise positions unchanged
2. THE Engine SHALL reject reordering if any identifier in the list corresponds to a SessionExercise whose state is not unfinished, signaling an OrderingError
3. THE Engine SHALL reject reordering if the provided list does not contain exactly all currently unfinished SessionExercise identifiers, signaling a ValidationError
4. WHEN exercises are reordered, THE Engine SHALL recompute the Cursor based on the new position order

### Requirement 10: Superset Creation

**User Story:** As a user, I want to group unfinished exercises into a superset, so that I can perform them together.

#### Acceptance Criteria

1. WHEN two or more unfinished SessionExercise identifiers are provided, THE Engine SHALL group them into a superset by assigning consecutive positions and marking them as a logical group
2. IF any provided SessionExercise identifier corresponds to a non-unfinished state, THEN THE Engine SHALL signal an OrderingError and leave the session unchanged
3. IF fewer than two exercise identifiers are provided, THEN THE Engine SHALL signal a ValidationError
4. WHEN a superset is created, THE Engine SHALL delegate persistence to the SessionRepository before returning the updated Session
5. WHEN a superset is created, THE Engine SHALL recompute the Cursor based on the updated structure

### Requirement 11: Superset Removal

**User Story:** As a user, I want to ungroup a superset back into individual exercises, so that I can change my mind about grouping.

#### Acceptance Criteria

1. WHEN a superset ungroup is requested for a set of SessionExercise identifiers that currently share a superset grouping, THE Engine SHALL restore each exercise to an independent single-exercise group while preserving their relative position order
2. IF any provided SessionExercise identifier corresponds to a non-unfinished state, THEN THE Engine SHALL signal an OrderingError and leave the session unchanged
3. IF the provided SessionExercise identifiers do not all belong to the same superset group, THEN THE Engine SHALL signal a ValidationError
4. WHEN a superset is removed, THE Engine SHALL delegate persistence to the SessionRepository before returning the updated Session
5. WHEN a superset is removed, THE Engine SHALL recompute the Cursor based on the updated structure

### Requirement 12: Extra Work

**User Story:** As a user, I want to add freeform extra work entries, so that I can log unplanned exercises.

#### Acceptance Criteria

1. WHEN a body string containing at least one non-whitespace character is provided for an existing session, THE Engine SHALL delegate to the SessionRepository.addExtraWork to persist a new ExtraWork entry and return the updated Session
2. IF the body string is empty or contains only whitespace characters, THEN THE Engine SHALL signal a ValidationError without persisting any data
3. IF the session identifier does not correspond to an existing session, THEN THE Engine SHALL signal a NotFoundError

### Requirement 13: Session Notes

**User Story:** As a user, I want to add notes to my session, so that I can record observations.

#### Acceptance Criteria

1. WHEN a body string containing at least one non-whitespace character and at most 5000 characters is provided for an existing session, THE Engine SHALL delegate to the SessionRepository.addSessionNote to persist a new SessionNote and return the updated Session including the new note
2. IF the body string is empty or contains only whitespace characters, THEN THE Engine SHALL signal a ValidationError without persisting any data
3. IF the specified sessionId does not correspond to an existing session, THEN THE Engine SHALL signal a NotFoundError

### Requirement 14: Session Completion Query

**User Story:** As a user, I want to know if my session is fully complete, so that the UI can prompt me to end it.

#### Acceptance Criteria

1. THE Engine SHALL report the session as complete when every SessionExercise has a state of completed, skipped, or replaced where the replaced exercise's executed set count equals the planned set count in the snapshot
2. THE Engine SHALL report the session as incomplete when at least one SessionExercise remains in the unfinished state, or a replaced exercise has fewer executed sets than planned
3. THE Engine SHALL expose the completion status as a synchronous query on the current session state without requiring a repository call

### Requirement 15: Actual Value Initialization

**User Story:** As a user, I want my next set to be pre-filled with my last actual performance, so that I can log faster.

#### Acceptance Criteria

1. WHEN the Cursor advances to a new set within the same exercise (set index > 0), THE Engine SHALL provide suggested ActualSetValues initialized from the most recently completed ExecutedSet of that exercise (the one with the highest position)
2. WHEN the Cursor points to the first set of an exercise (set index 0) with no prior ExecutedSets, THE Engine SHALL provide suggested ActualSetValues initialized from the PlannedSetValues at position 0 in the snapshot for that exercise
3. WHEN a replaced exercise has a different MeasurementType than the original planned exercise, THE Engine SHALL provide suggested ActualSetValues matching the substitute's MeasurementType with zero/default values
4. THE Engine SHALL ensure the suggested ActualSetValues variant always matches the effective MeasurementType of the exercise (original for unfinished, substitute's for replaced)

### Requirement 16: Immutability Enforcement

**User Story:** As a user, I want the system to prevent illegal mutations, so that my session history remains consistent.

#### Acceptance Criteria

1. IF a reorder operation includes a SessionExercise whose state is completed, skipped, or replaced, THEN THE Engine SHALL signal an OrderingError with the offending sessionExerciseId and its current state
2. IF a superset creation includes a SessionExercise whose state is completed, skipped, or replaced, THEN THE Engine SHALL signal an OrderingError with the offending sessionExerciseId
3. IF a skip or replace is requested on a SessionExercise whose state is not unfinished, THEN THE Engine SHALL signal an OrderingError with the sessionExerciseId and current state
4. IF an end-session is requested on an already-ended session, THEN THE Engine SHALL signal an ImmutabilityError carrying the sessionId
5. IF a set completion is requested on an ended session, THEN THE Engine SHALL signal an ImmutabilityError

### Requirement 17: Persistence on Every Mutation

**User Story:** As a user, I want every change to be persisted immediately, so that my session survives app backgrounding.

#### Acceptance Criteria

1. WHEN any mutation operation (completeSet, skipExercise, replaceExercise, reorderUnfinished, addSessionNote, addExtraWork, endSession) completes successfully, THE Engine SHALL have delegated persistence to the SessionRepository before returning the result
2. THE Engine SHALL return the fully updated Session aggregate from the repository after every mutation, ensuring the caller always has the latest persisted state
3. IF the SessionRepository throws during persistence, THE Engine SHALL propagate the error to the caller without caching stale state

### Requirement 18: Deterministic Timestamps

**User Story:** As a developer, I want timestamps to come from an injectable Clock, so that tests are deterministic.

#### Acceptance Criteria

1. THE Engine SHALL accept a Clock instance as a required constructor parameter with no default value
2. THE Engine SHALL obtain the current time exclusively from the injected Clock instance, never from DateTime.now() or any other time source
3. WHEN the Engine records a set completion timestamp or a session endedAt timestamp, THE Engine SHALL use the value returned by the injected Clock at the moment the operation executes
4. WHEN a test supplies a fake Clock returning a fixed time, THE Engine SHALL produce entities whose timestamp fields equal that fixed time exactly
