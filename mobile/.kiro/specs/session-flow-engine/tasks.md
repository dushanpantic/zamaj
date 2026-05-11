# Implementation Plan: Session Flow Engine

## Overview

Implement the pure-Dart `SessionFlowEngine` service with cursor-based navigation, session lifecycle management, and all in-session mutation operations. The implementation proceeds bottom-up: value objects first, then model modifications, repository contract extensions, the engine itself, and finally comprehensive property-based and unit tests.

## Tasks

- [x] 1. Create value objects and modify existing models
  - [x] 1.1 Create the `Cursor` sealed class
    - Create `lib/modules/domain/services/cursor.dart` with a Freezed sealed class: `Cursor.active(sessionExerciseId, setIndex)` and `Cursor.completed()`
    - Use `@Freezed(unionKey: 'type')` matching existing sealed class patterns
    - Include `part` directives for `.freezed.dart` and `.g.dart`
    - _Requirements: 4.1, 4.2, 4.4_

  - [x] 1.2 Create the `SessionState` value object
    - Create `lib/modules/domain/services/session_state.dart` with a Freezed class bundling `Session`, `Cursor`, and nullable `ActualSetValues? suggestedValues`
    - _Requirements: 4.5, 15.1_

  - [x] 1.3 Add `supersetTag` field to `SessionExercise`
    - Add `String? supersetTag` to the `SessionExercise` Freezed model in `lib/modules/domain/models/session_exercise.dart`
    - _Requirements: 10.1, 11.1_

  - [x] 1.4 Add `supersetTag` column to `SessionExercises` Drift table
    - Add `TextColumn get supersetTag => text().nullable()();` to the `SessionExercises` table in `lib/modules/persistence/database/tables.dart`
    - _Requirements: 10.1, 10.4_

  - [x] 1.5 Update `SessionMapper` to handle `supersetTag`
    - Map the `supersetTag` field in both `_exerciseToDomain` and `sessionExerciseToRow` methods in `lib/modules/persistence/mappers/session_mapper.dart`
    - _Requirements: 10.4, 11.4_

- [x] 2. Extend the SessionRepository contract
  - [x] 2.1 Add `createSuperset` and `removeSuperset` to `SessionRepository`
    - Add two new abstract methods to `lib/modules/domain/repositories/session_repository.dart`:
      - `Future<Session> createSuperset({required String sessionId, required List<String> sessionExerciseIds})`
      - `Future<Session> removeSuperset({required String sessionId, required List<String> sessionExerciseIds})`
    - _Requirements: 10.4, 11.4_

- [x] 3. Run code generation and verify compilation
  - Ensure all tests pass, ask the user if questions arise.

- [x] 4. Implement the SessionFlowEngine
  - [x] 4.1 Create the engine class with constructor and helper methods
    - Create `lib/modules/domain/services/session_flow_engine.dart`
    - Constructor accepts `SessionRepository` and `Clock` (from `package:clock`)
    - Implement `computeCursor(Session)`: iterate exercises by position, find first unfinished/replaced with sets remaining
    - Implement `suggestValues(Session, Cursor)`: return last actual values or converted planned values
    - Implement `isSessionComplete(Session)`: check all exercises in terminal state with sets fulfilled
    - Implement private helper `_buildState(Session)` that bundles session + cursor + suggestion
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 14.1, 14.2, 14.3, 15.1, 15.2, 15.3, 15.4, 18.1, 18.2_

  - [x] 4.2 Implement session lifecycle methods
    - `startSession({required String workoutDayId})`: delegate to repo, compute cursor, return SessionState
    - `resumeSession({required String sessionId})`: load from repo, compute cursor, return SessionState
    - `endSession({required String sessionId})`: validate not already ended, delegate to repo, return SessionState
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 2.1, 2.2, 2.3, 2.4, 3.1, 3.2, 3.3, 3.4, 3.5_

  - [x] 4.3 Implement set completion and editing
    - `completeSet(...)`: validate session not ended, cursor not terminal, measurement type match; delegate to repo; return SessionState
    - `updateExecutedSet(...)`: validate measurement type match; delegate to repo; return SessionState
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6, 6.1, 6.2, 6.3, 6.4_

  - [x] 4.4 Implement skip, replace, and reorder
    - `skipExercise(...)`: validate exercise is unfinished; delegate to repo; return SessionState
    - `replaceExercise(...)`: validate exercise is unfinished; delegate to repo; return SessionState
    - `reorderUnfinished(...)`: validate all IDs are unfinished and list is exact permutation; delegate to repo; return SessionState
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 8.1, 8.2, 8.3, 8.4, 8.5, 9.1, 9.2, 9.3, 9.4_

  - [x] 4.5 Implement superset creation and removal
    - `createSuperset(...)`: validate ≥2 IDs, all unfinished; delegate to repo; return SessionState
    - `removeSuperset(...)`: validate all share same supersetTag, all unfinished; delegate to repo; return SessionState
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 11.1, 11.2, 11.3, 11.4, 11.5_

  - [x] 4.6 Implement extra work and notes
    - `addExtraWork(...)`: validate body is non-whitespace; delegate to repo; return SessionState
    - `addSessionNote(...)`: validate body is non-whitespace and ≤5000 chars; delegate to repo; return SessionState
    - _Requirements: 12.1, 12.2, 12.3, 13.1, 13.2, 13.3_

- [x] 5. Checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

- [x] 6. Create test infrastructure
  - [x] 6.1 Create `FakeSessionRepository` for engine tests
    - Create `test/support/fake_session_repository.dart` implementing `SessionRepository` with in-memory storage
    - Must correctly apply mutations (completeSet, skip, replace, reorder, createSuperset, removeSuperset, addExtraWork, addSessionNote, endSession)
    - Must return fully hydrated `Session` after each mutation
    - _Requirements: 17.1, 17.2, 17.3_

  - [x] 6.2 Extend `test/support/generators.dart` with engine-specific generators
    - `anySessionForEngine(Random rng)`: generates a Session with consistent snapshot ↔ exercise mapping (exercises reference real planned exercises in the snapshot)
    - `anySessionWithStates(Random rng, {required List<ExerciseState> states})`: generates a session with exercises in specified states, consistent with snapshot
    - `anyCursorableSession(Random rng)`: generates a session with at least one unfinished exercise with sets remaining
    - `anyEndedSession(Random rng)`: generates a session with non-null endedAt
    - `anyWhitespaceString(Random rng)`: generates strings of only whitespace characters
    - _Requirements: 18.4_

- [x] 7. Property-based tests: cursor and completion
  - [x] 7.1 Write property test for fresh session structure
    - **Property 1: Fresh session structure**
    - **Validates: Requirements 1.2, 1.3**

  - [x] 7.2 Write property test for cursor computation correctness
    - **Property 2: Cursor computation correctness**
    - **Validates: Requirements 2.2, 4.1, 4.2, 4.3, 4.4**

  - [x] 7.3 Write property test for cursor consistency after mutations
    - **Property 3: Cursor consistency after mutations**
    - **Validates: Requirements 4.5, 8.5**

  - [x] 7.4 Write property test for session completion query
    - **Property 21: Session completion query**
    - **Validates: Requirements 14.1, 14.2, 14.3**

- [x] 8. Property-based tests: lifecycle and immutability
  - [x] 8.1 Write property test for end session on active session
    - **Property 4: End session on active session**
    - **Validates: Requirements 3.1, 3.2, 3.3**

  - [x] 8.2 Write property test for double-end immutability
    - **Property 5: Double-end immutability**
    - **Validates: Requirements 3.4, 16.4**

  - [x] 8.3 Write property test for ended session immutability
    - **Property 9: Ended session immutability**
    - **Validates: Requirements 2.4, 5.5, 5.6, 16.5**

- [x] 9. Property-based tests: set completion and editing
  - [x] 9.1 Write property test for set completion records correct values and timestamp
    - **Property 6: Set completion records correct values and timestamp**
    - **Validates: Requirements 5.1, 18.2, 18.3, 18.4**

  - [x] 9.2 Write property test for last set transitions exercise to completed
    - **Property 7: Last set transitions exercise to completed**
    - **Validates: Requirements 5.3**

  - [x] 9.3 Write property test for measurement type validation
    - **Property 8: Measurement type validation**
    - **Validates: Requirements 5.4, 6.3, 8.3**

  - [ ]* 9.4 Write property test for editing works regardless of exercise state
    - **Property 10: Editing works regardless of exercise state**
    - **Validates: Requirements 6.2**

- [x] 10. Property-based tests: skip, replace, reorder
  - [x] 10.1 Write property test for skip transitions to skipped
    - **Property 11: Skip transitions to skipped**
    - **Validates: Requirements 7.1, 7.2, 7.4**

  - [x] 10.2 Write property test for non-unfinished exercises reject structural mutations
    - **Property 12: Non-unfinished exercises reject structural mutations**
    - **Validates: Requirements 7.3, 8.4, 9.2, 10.2, 11.2, 16.1, 16.2, 16.3**

  - [x] 10.3 Write property test for replace sets correct state and preserves snapshot reference
    - **Property 13: Replace sets correct state and preserves snapshot reference**
    - **Validates: Requirements 8.1, 8.2**

  - [x] 10.4 Write property test for reorder preserves completed positions and applies new order
    - **Property 14: Reorder preserves completed positions and applies new order**
    - **Validates: Requirements 9.1, 9.4**

  - [ ]* 10.5 Write property test for reorder requires exact permutation
    - **Property 15: Reorder requires exact permutation of all unfinished IDs**
    - **Validates: Requirements 9.3**

- [x] 11. Property-based tests: superset operations
  - [x] 11.1 Write property test for superset creation assigns shared tag
    - **Property 16: Superset creation assigns shared tag and consecutive positions**
    - **Validates: Requirements 10.1, 10.5**

  - [x] 11.2 Write property test for superset removal clears tags
    - **Property 17: Superset removal clears tags preserving relative order**
    - **Validates: Requirements 11.1, 11.5**

  - [ ]* 11.3 Write property test for superset removal requires same group
    - **Property 18: Superset removal requires same group**
    - **Validates: Requirements 11.3**

- [ ] 12. Property-based tests: extra work, notes, and value suggestion
  - [ ]* 12.1 Write property test for valid text body persists
    - **Property 19: Valid text body persists**
    - **Validates: Requirements 12.1, 13.1**

  - [ ]* 12.2 Write property test for whitespace-only body rejected
    - **Property 20: Whitespace-only body rejected**
    - **Validates: Requirements 12.2, 13.2**

  - [ ] 12.3 Write property test for value suggestion correctness
    - **Property 22: Value suggestion correctness**
    - **Validates: Requirements 15.1, 15.2, 15.3, 15.4**

- [x] 13. Unit tests for edge cases
  - [x] 13.1 Write unit tests for edge cases and specific examples
    - Test empty workout day (0 exercises) → cursor is immediately completed
    - Test single exercise with 1 planned set → complete it → exercise transitions to completed → cursor completed
    - Test NotFoundError for missing session/exercise/set IDs
    - Test note body exceeding 5000 characters is rejected
    - Test a concrete 3-exercise session walked through step by step (complete, skip, replace)
    - Test superset with fewer than 2 exercises is rejected
    - _Requirements: 1.4, 2.3, 3.5, 5.6, 6.4, 12.3, 13.3_

- [ ] 14. Final checkpoint - Ensure all tests pass
  - Ensure all tests pass, ask the user if questions arise.

## Notes

- Tasks marked with `*` are optional (low-risk, simple validation that's covered by other tests)
- All unmarked tasks are mandatory
- Each task references specific requirements for traceability
- Checkpoints ensure incremental validation
- Property tests validate universal correctness properties from the design document (22 properties total)
- Unit tests validate specific examples and edge cases
- The `FakeSessionRepository` is critical infrastructure — it must correctly simulate all mutations so the engine tests exercise real logic
- Generated files (`*.freezed.dart`, `*.g.dart`) must be regenerated after tasks 1.1–1.5 via `dart run build_runner build --force-jit`
- All test files go under `test/domain/services/` matching the source layout

## Model Selection Guide

**Run with Sonnet** (mechanical scaffolding, boilerplate, simple delegation):
- 1.1, 1.2, 1.3, 1.4, 1.5 — adding fields, columns, mapper lines
- 2.1 — adding abstract methods to a contract
- 3 — running codegen
- 4.6 — extra work and notes (trivial validation + delegation)
- 5 — checkpoint
- 12.1*, 12.2* — trivial validation property tests
- 14 — final checkpoint

**Run with Opus** (complex logic, invariants, state machines, test infrastructure):
- 4.1 — cursor computation, value suggestion, completion query algorithms
- 4.2 — session lifecycle with precondition checks
- 4.3 — set completion with state transitions and type validation
- 4.4 — skip/replace/reorder with ordering invariants
- 4.5 — superset creation/removal with tag logic
- 6.1 — FakeSessionRepository (must faithfully simulate all mutations)
- 6.2 — generators (must produce consistent snapshot↔exercise mappings)
- 7.1–7.4 — cursor and completion property tests
- 8.1–8.3 — lifecycle and immutability property tests
- 9.1–9.3 — set completion property tests
- 10.1–10.4 — skip/replace/reorder property tests
- 11.1–11.2 — superset property tests
- 12.3 — value suggestion property test
- 13.1 — unit tests (concrete walkthrough scenarios)

## Task Dependency Graph

```json
{
  "waves": [
    { "id": 0, "tasks": ["1.1", "1.2", "1.3", "1.4"] },
    { "id": 1, "tasks": ["1.5", "2.1"] },
    { "id": 2, "tasks": ["4.1"] },
    { "id": 3, "tasks": ["4.2", "4.3", "4.4", "4.5", "4.6"] },
    { "id": 4, "tasks": ["6.1", "6.2"] },
    { "id": 5, "tasks": ["7.1", "7.2", "7.3", "7.4", "8.1", "8.2", "8.3"] },
    { "id": 6, "tasks": ["9.1", "9.2", "9.3", "9.4", "10.1", "10.2", "10.3", "10.4", "10.5"] },
    { "id": 7, "tasks": ["11.1", "11.2", "11.3", "12.1", "12.2", "12.3"] },
    { "id": 8, "tasks": ["13.1"] }
  ]
}
```
