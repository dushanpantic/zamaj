// Feature: session-flow-engine, Property 4, 5, 9: Lifecycle and immutability
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
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
        final engine = SessionFlowEngine(repository: repo);

        final exerciseCount = 1 + rng.nextInt(5);
        final states = List.generate(exerciseCount, (_) {
          switch (rng.nextInt(3)) {
            case 0:
              return const ExerciseState.unfinished();
            case 1:
              return const ExerciseState.completed();
            default:
              return const ExerciseState.skipped();
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
        final engine = SessionFlowEngine(repository: repo);

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

          final engine = SessionFlowEngine(repository: repo);

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

        final engine = SessionFlowEngine(repository: repo);

        final exercise = session.sessionExercises.first;
        final planned = _lookupPlannedExercise(exercise, session);
        final effectiveMt = planned.measurementType;
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

    test('completeSet on a skipped exercise throws OrderingError', () async {
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = _anyAllTerminalSession(rng);
        final activeSession = session.copyWith(endedAt: null);

        final skipped = activeSession.sessionExercises
            .where((e) => e.state is SkippedState)
            .toList();
        if (skipped.isEmpty) continue;

        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(activeSession);

        final engine = SessionFlowEngine(repository: repo);

        final target = skipped[rng.nextInt(skipped.length)];
        final planned = _lookupPlannedExercise(target, activeSession);
        final values = anyActualSetValuesForMeasurement(
          rng,
          planned.measurementType,
        );

        expect(
          () => engine.completeSet(
            sessionExerciseId: target.id,
            actualValues: values,
          ),
          throwsA(
            isA<OrderingError>()
                .having(
                  (e) => e.sessionExerciseId,
                  'sessionExerciseId',
                  target.id,
                )
                .having((e) => e.currentState, 'currentState', 'skipped'),
          ),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'completeSet on a skipped exercise must throw OrderingError',
        );
      }
    });
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
    return rng.nextBool()
        ? const ExerciseState.completed()
        : const ExerciseState.skipped();
  });

  final session = anySessionWithStates(rng, states: states);
  return session.copyWith(endedAt: null);
}
