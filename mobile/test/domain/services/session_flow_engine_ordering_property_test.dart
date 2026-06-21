// Feature: session-flow-engine, Property 12: Non-unfinished exercises reject structural mutations
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  // **Validates: Requirements 7.3, 8.4, 9.2, 10.2, 11.2, 16.1, 16.2, 16.3**
  group(
    'Property 12: Non-unfinished exercises reject structural mutations',
    () {
      test(
        'skipExercise on non-unfinished exercise throws OrderingError',
        () async {
          const iterations = 100;
          final masterSeed = Random().nextInt(1 << 32);

          for (var i = 0; i < iterations; i++) {
            final rng = Random(masterSeed + i);
            final session = _anySessionWithNonUnfinishedExercise(rng);
            final fakeClock = Clock.fixed(anyUtcDateTime(rng));
            final repo = FakeSessionRepository(clock: fakeClock);
            repo.seedSession(session);

            final engine = SessionFlowEngine(repository: repo);

            final target = _pickNonUnfinishedExercise(rng, session);

            expect(
              () => engine.skipExercise(sessionExerciseId: target.id),
              throwsA(
                isA<OrderingError>().having(
                  (e) => e.sessionExerciseId,
                  'sessionExerciseId',
                  equals(target.id),
                ),
              ),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'skipExercise on ${target.state.runtimeType} must throw '
                  'OrderingError with correct sessionExerciseId',
            );
          }
        },
      );

      test(
        'replaceExercise on non-unfinished exercise throws OrderingError',
        () async {
          const iterations = 100;
          final masterSeed = Random().nextInt(1 << 32);

          for (var i = 0; i < iterations; i++) {
            final rng = Random(masterSeed + i);
            final session = _anySessionWithNonUnfinishedExercise(rng);
            final fakeClock = Clock.fixed(anyUtcDateTime(rng));
            final repo = FakeSessionRepository(clock: fakeClock);
            repo.seedSession(session);

            final engine = SessionFlowEngine(repository: repo);

            final target = _pickNonUnfinishedExercise(rng, session);

            expect(
              () => engine.replaceExercise(
                sessionExerciseId: target.id,
                plan: anyAddedExercisePlan(rng, libraryLinked: false),
              ),
              throwsA(
                isA<OrderingError>().having(
                  (e) => e.sessionExerciseId,
                  'sessionExerciseId',
                  equals(target.id),
                ),
              ),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'replaceExercise on ${target.state.runtimeType} must throw '
                  'OrderingError with correct sessionExerciseId',
            );
          }
        },
      );

      test(
        'reorderUnfinished with non-unfinished exercise throws OrderingError',
        () async {
          const iterations = 100;
          final masterSeed = Random().nextInt(1 << 32);

          for (var i = 0; i < iterations; i++) {
            final rng = Random(masterSeed + i);
            final session = _anySessionWithMixedStates(rng);
            final fakeClock = Clock.fixed(anyUtcDateTime(rng));
            final repo = FakeSessionRepository(clock: fakeClock);
            repo.seedSession(session);

            final engine = SessionFlowEngine(repository: repo);

            final nonUnfinished = session.sessionExercises
                .where((e) => e.state is! UnfinishedState)
                .toList();
            if (nonUnfinished.isEmpty) continue;

            final target = nonUnfinished[rng.nextInt(nonUnfinished.length)];

            final unfinishedIds = session.sessionExercises
                .where((e) => e.state is UnfinishedState)
                .map((e) => e.id)
                .toList();

            final idsWithNonUnfinished = [...unfinishedIds, target.id];
            idsWithNonUnfinished.shuffle(rng);

            expect(
              () => engine.reorderUnfinished(
                sessionId: session.id,
                orderedUnfinishedIds: idsWithNonUnfinished,
              ),
              throwsA(
                isA<OrderingError>().having(
                  (e) => e.sessionExerciseId,
                  'sessionExerciseId',
                  equals(target.id),
                ),
              ),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'reorderUnfinished including ${target.state.runtimeType} '
                  'must throw OrderingError with correct sessionExerciseId',
            );
          }
        },
      );

      test(
        'createSuperset with non-unfinished exercise throws OrderingError',
        () async {
          const iterations = 100;
          final masterSeed = Random().nextInt(1 << 32);

          for (var i = 0; i < iterations; i++) {
            final rng = Random(masterSeed + i);
            final session = _anySessionWithMixedStates(rng);
            final fakeClock = Clock.fixed(anyUtcDateTime(rng));
            final repo = FakeSessionRepository(clock: fakeClock);
            repo.seedSession(session);

            final engine = SessionFlowEngine(repository: repo);

            final nonUnfinished = session.sessionExercises
                .where((e) => e.state is! UnfinishedState)
                .toList();
            if (nonUnfinished.isEmpty) continue;

            final target = nonUnfinished[rng.nextInt(nonUnfinished.length)];

            final unfinished = session.sessionExercises
                .where((e) => e.state is UnfinishedState)
                .toList();

            final List<String> supersetIds;
            if (unfinished.isNotEmpty) {
              supersetIds = [
                unfinished[rng.nextInt(unfinished.length)].id,
                target.id,
              ];
            } else {
              supersetIds = [target.id, target.id];
            }

            expect(
              () => engine.createSuperset(
                sessionId: session.id,
                sessionExerciseIds: supersetIds,
              ),
              throwsA(
                isA<OrderingError>().having(
                  (e) => e.sessionExerciseId,
                  'sessionExerciseId',
                  equals(target.id),
                ),
              ),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'createSuperset including ${target.state.runtimeType} '
                  'must throw OrderingError with correct sessionExerciseId',
            );
          }
        },
      );

      test(
        'removeSuperset with non-unfinished exercise throws OrderingError',
        () async {
          const iterations = 100;
          final masterSeed = Random().nextInt(1 << 32);

          for (var i = 0; i < iterations; i++) {
            final rng = Random(masterSeed + i);
            final session = _anySessionWithNonUnfinishedInSuperset(rng);
            final fakeClock = Clock.fixed(anyUtcDateTime(rng));
            final repo = FakeSessionRepository(clock: fakeClock);
            repo.seedSession(session);

            final engine = SessionFlowEngine(repository: repo);

            final target = session.sessionExercises.firstWhere(
              (e) => e.state is! UnfinishedState && e.supersetTag != null,
            );

            final sameTagIds = session.sessionExercises
                .where((e) => e.supersetTag == target.supersetTag)
                .map((e) => e.id)
                .toList();

            expect(
              () => engine.removeSuperset(
                sessionId: session.id,
                sessionExerciseIds: sameTagIds,
              ),
              throwsA(
                isA<OrderingError>().having(
                  (e) => e.sessionExerciseId,
                  'sessionExerciseId',
                  equals(target.id),
                ),
              ),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'removeSuperset including ${target.state.runtimeType} '
                  'must throw OrderingError with correct sessionExerciseId',
            );
          }
        },
      );
    },
  );
}

Session _anySessionWithNonUnfinishedExercise(Random rng) {
  final nonUnfinishedCount = 1 + rng.nextInt(3);
  final unfinishedCount = rng.nextInt(3);

  final states = <ExerciseState>[
    ...List.generate(nonUnfinishedCount, (_) => _anyNonUnfinishedState(rng)),
    ...List.generate(unfinishedCount, (_) => const ExerciseState.unfinished()),
  ];
  states.shuffle(rng);

  return anySessionWithStates(rng, states: states);
}

Session _anySessionWithMixedStates(Random rng) {
  final nonUnfinishedCount = 1 + rng.nextInt(3);
  final unfinishedCount = 1 + rng.nextInt(3);

  final states = <ExerciseState>[
    ...List.generate(nonUnfinishedCount, (_) => _anyNonUnfinishedState(rng)),
    ...List.generate(unfinishedCount, (_) => const ExerciseState.unfinished()),
  ];
  states.shuffle(rng);

  return anySessionWithStates(rng, states: states);
}

Session _anySessionWithNonUnfinishedInSuperset(Random rng) {
  final states = <ExerciseState>[
    _anyNonUnfinishedState(rng),
    const ExerciseState.unfinished(),
    const ExerciseState.unfinished(),
  ];

  final session = anySessionWithStates(rng, states: states);
  final tag = anyUuidV4(rng);

  final updatedExercises = session.sessionExercises.map((e) {
    return e.copyWith(supersetTag: tag);
  }).toList();

  return session.copyWith(sessionExercises: updatedExercises);
}

ExerciseState _anyNonUnfinishedState(Random rng) {
  return rng.nextBool()
      ? const ExerciseState.completed()
      : const ExerciseState.skipped();
}

SessionExercise _pickNonUnfinishedExercise(Random rng, Session session) {
  final nonUnfinished = session.sessionExercises
      .where((e) => e.state is! UnfinishedState)
      .toList();
  return nonUnfinished[rng.nextInt(nonUnfinished.length)];
}
