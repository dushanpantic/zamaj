// Feature: session-flow-engine, Property 4, 5, 9: Lifecycle and immutability
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/services/cursor.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  const iterations = 100;

  // Feature: session-flow-engine, Property 4: End session on active session
  // **Validates: Requirements 3.1, 3.2, 3.3**
  group('Property 4: End session on active session', () {
    test('endSession succeeds on any active session regardless of exercise '
        'states and sets endedAt to clock time', () async {
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final fixedTime = anyUtcDateTime(rng);
        final fakeClock = Clock.fixed(fixedTime);
        final repo = FakeSessionRepository(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);

        final exerciseCount = 1 + rng.nextInt(5);
        final states = List.generate(exerciseCount, (_) {
          switch (rng.nextInt(4)) {
            case 0:
              return const ExerciseState.unfinished();
            case 1:
              return const ExerciseState.completed();
            case 2:
              return const ExerciseState.skipped();
            default:
              return ExerciseState.replaced(
                substitute: anySubstituteExercise(rng),
              );
          }
        });

        final session = anySessionWithStates(rng, states: states);
        repo.seedSession(session);

        final result = await engine.endSession(sessionId: session.id);

        expect(
          result.session.endedAt,
          equals(fixedTime),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'endedAt should equal the injected clock time',
        );

        expect(
          result.session.id,
          equals(session.id),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'returned session should have the same id',
        );
      }
    });

    test('endSession succeeds with any mix of unfinished exercises '
        '(no terminal state requirement)', () async {
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final fixedTime = anyUtcDateTime(rng);
        final fakeClock = Clock.fixed(fixedTime);
        final repo = FakeSessionRepository(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);

        final exerciseCount = 1 + rng.nextInt(5);
        final states = List.generate(
          exerciseCount,
          (_) => const ExerciseState.unfinished(),
        );

        final session = anySessionWithStates(rng, states: states);
        repo.seedSession(session);

        final result = await engine.endSession(sessionId: session.id);

        expect(
          result.session.endedAt,
          equals(fixedTime),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'endSession must succeed even when all exercises are unfinished',
        );
      }
    });
  });

  // Feature: session-flow-engine, Property 5: Double-end immutability
  // **Validates: Requirements 3.4, 16.4**
  group('Property 5: Double-end immutability', () {
    test(
      'endSession throws ImmutabilityError on already-ended session',
      () async {
        final masterSeed = Random().nextInt(1 << 32);

        for (var i = 0; i < iterations; i++) {
          final rng = Random(masterSeed + i);
          final session = anyEndedSession(rng);
          final fakeClock = Clock.fixed(anyUtcDateTime(rng));
          final repo = FakeSessionRepository(clock: fakeClock);
          repo.seedSession(session);

          final engine = SessionFlowEngine(repository: repo, clock: fakeClock);

          expect(
            () => engine.endSession(sessionId: session.id),
            throwsA(
              isA<ImmutabilityError>().having(
                (e) => e.sessionId,
                'sessionId',
                session.id,
              ),
            ),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'endSession on ended session must throw ImmutabilityError '
                'carrying the session id',
          );
        }
      },
    );
  });

  // Feature: session-flow-engine, Property 9: Ended session immutability
  // **Validates: Requirements 2.4, 5.5, 5.6, 16.5**
  group('Property 9: Ended session immutability', () {
    test('completeSet throws ImmutabilityError on ended session', () async {
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = anyEndedSession(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);

        final exercise = session.sessionExercises.first;
        final planned = _lookupPlannedExercise(exercise, session);
        final effectiveMt = switch (exercise.state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => planned.measurementType,
        };
        final values = anyActualSetValuesForMeasurement(rng, effectiveMt);

        expect(
          () => engine.completeSet(
            sessionExerciseId: exercise.id,
            actualValues: values,
          ),
          throwsA(isA<ImmutabilityError>()),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'completeSet on ended session must throw ImmutabilityError',
        );
      }
    });

    test(
      'completeSet throws ValidationError when cursor is completed',
      () async {
        final masterSeed = Random().nextInt(1 << 32);

        for (var i = 0; i < iterations; i++) {
          final rng = Random(masterSeed + i);
          final session = _anyAllTerminalSession(rng);
          final activeSession = session.copyWith(endedAt: null);

          final fakeClock = Clock.fixed(anyUtcDateTime(rng));
          final repo = FakeSessionRepository(clock: fakeClock);
          repo.seedSession(activeSession);

          final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
          final cursor = engine.computeCursor(activeSession);

          expect(
            cursor,
            equals(const Cursor.completed()),
            reason: 'iteration $i: precondition — cursor must be completed',
          );

          final exercise = activeSession.sessionExercises.first;
          final planned = _lookupPlannedExercise(exercise, activeSession);
          final effectiveMt = switch (exercise.state) {
            ReplacedState(:final substitute) => substitute.measurementType,
            _ => planned.measurementType,
          };
          final values = anyActualSetValuesForMeasurement(rng, effectiveMt);

          expect(
            () => engine.completeSet(
              sessionExerciseId: exercise.id,
              actualValues: values,
            ),
            throwsA(isA<ValidationError>()),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'completeSet with terminal cursor must throw ValidationError',
          );
        }
      },
    );
  });
}

Exercise _lookupPlannedExercise(
  SessionExercise sessionExercise,
  Session session,
) {
  for (final group in session.snapshot.workoutDay.exerciseGroups) {
    for (final exercise in group.exercises) {
      if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
        return exercise;
      }
    }
  }
  throw StateError('Planned exercise not found');
}

Session _anyAllTerminalSession(Random rng) {
  final exerciseCount = 1 + rng.nextInt(5);
  final states = List.generate(exerciseCount, (_) {
    switch (rng.nextInt(3)) {
      case 0:
        return const ExerciseState.completed();
      case 1:
        return const ExerciseState.skipped();
      default:
        return ExerciseState.replaced(substitute: anySubstituteExercise(rng));
    }
  });

  final session = anySessionWithStates(rng, states: states);

  final fixedExercises = session.sessionExercises.map((exercise) {
    final planned = _lookupPlannedExercise(exercise, session);
    final plannedSetCount = planned.sets.length;

    if (exercise.state is ReplacedState &&
        exercise.executedSets.length < plannedSetCount) {
      final ReplacedState replacedState = exercise.state as ReplacedState;
      final mt = replacedState.substitute.measurementType;
      final sets = List.generate(plannedSetCount, (j) {
        if (j < exercise.executedSets.length) return exercise.executedSets[j];
        return ExecutedSet(
          id: anyUuidV4(rng),
          sessionExerciseId: exercise.id,
          position: j,
          measurementType: mt,
          actualValues: anyActualSetValuesForMeasurement(rng, mt),
          plannedSetIdInSnapshot: j < planned.sets.length
              ? planned.sets[j].id
              : null,
          completedAt: anyUtcDateTime(rng),
          createdAt: anyUtcDateTime(rng),
          updatedAt: anyUtcDateTime(rng),
          schemaVersion: 1,
        );
      });
      return exercise.copyWith(executedSets: sets);
    }
    return exercise;
  }).toList();

  return session.copyWith(sessionExercises: fixedExercises, endedAt: null);
}
