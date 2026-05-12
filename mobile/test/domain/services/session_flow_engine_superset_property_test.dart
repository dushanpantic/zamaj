// Feature: session-flow-engine, Property 16: Superset creation assigns shared tag and consecutive positions
// Feature: session-flow-engine, Property 17: Superset removal clears tags preserving relative order
// Feature: session-flow-engine, Property 18: Superset removal requires same group
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  // **Validates: Requirements 10.1, 10.5**
  group(
    'Property 16: Superset creation assigns shared tag and consecutive positions',
    () {
      test(
        'createSuperset assigns the same non-null supersetTag to all '
        'provided exercises and places them at consecutive positions',
        () async {
          const iterations = 100;
          final masterSeed = Random().nextInt(1 << 32);

          for (var i = 0; i < iterations; i++) {
            final rng = Random(masterSeed + i);
            final session = _anySessionForSupersetCreation(rng);
            final fakeClock = Clock.fixed(anyUtcDateTime(rng));
            final repo = FakeSessionRepository(clock: fakeClock);
            repo.seedSession(session);

            final engine = SessionFlowEngine(repository: repo);

            final unfinished = session.sessionExercises
                .where((e) => e.state is UnfinishedState)
                .toList();

            final supersetSize = 2 + rng.nextInt(unfinished.length - 1);
            final shuffledUnfinished = [...unfinished]..shuffle(rng);
            final supersetIds = shuffledUnfinished
                .take(supersetSize)
                .map((e) => e.id)
                .toList();

            final result = await engine.createSuperset(
              sessionId: session.id,
              sessionExerciseIds: supersetIds,
            );

            final supersetIdSet = supersetIds.toSet();
            final supersetExercises = result.session.sessionExercises
                .where((e) => supersetIdSet.contains(e.id))
                .toList();

            expect(
              supersetExercises.length,
              equals(supersetIds.length),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'every requested id must be present in the result',
            );

            final tags = supersetExercises.map((e) => e.supersetTag).toSet();
            expect(
              tags.length,
              equals(1),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'all superset exercises must share a single supersetTag',
            );
            expect(
              tags.single,
              isNotNull,
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'the shared supersetTag must be non-null',
            );

            final supersetPositions =
                supersetExercises.map((e) => e.position).toList()..sort();
            for (var j = 1; j < supersetPositions.length; j++) {
              expect(
                supersetPositions[j],
                equals(supersetPositions[j - 1] + 1),
                reason:
                    'iteration $i (seed ${masterSeed + i}): '
                    'superset exercises must occupy consecutive positions, '
                    'got $supersetPositions',
              );
            }

            final allPositions =
                result.session.sessionExercises.map((e) => e.position).toList()
                  ..sort();
            expect(
              allPositions,
              equals(
                List.generate(result.session.sessionExercises.length, (k) => k),
              ),
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'positions must be a dense 0..n-1 sequence',
            );
          }
        },
      );
    },
  );

  // **Validates: Requirements 11.1, 11.5**
  group(
    'Property 17: Superset removal clears tags preserving relative order',
    () {
      test('removeSuperset sets supersetTag to null on all provided exercises '
          'and preserves their relative position order', () async {
        const iterations = 100;
        final masterSeed = Random().nextInt(1 << 32);

        for (var i = 0; i < iterations; i++) {
          final rng = Random(masterSeed + i);
          final session = _anySessionWithUnfinishedSuperset(rng);
          final fakeClock = Clock.fixed(anyUtcDateTime(rng));
          final repo = FakeSessionRepository(clock: fakeClock);
          repo.seedSession(session);

          final engine = SessionFlowEngine(repository: repo);

          final taggedExercises = session.sessionExercises
              .where((e) => e.supersetTag != null)
              .toList();
          final tag = taggedExercises.first.supersetTag;
          final sameTagExercises =
              session.sessionExercises
                  .where((e) => e.supersetTag == tag)
                  .toList()
                ..sort((a, b) => a.position.compareTo(b.position));

          final originalRelativeOrder = sameTagExercises
              .map((e) => e.id)
              .toList();

          final result = await engine.removeSuperset(
            sessionId: session.id,
            sessionExerciseIds: originalRelativeOrder,
          );

          final updatedExercises = {
            for (final e in result.session.sessionExercises) e.id: e,
          };

          for (final id in originalRelativeOrder) {
            expect(
              updatedExercises[id]!.supersetTag,
              isNull,
              reason:
                  'iteration $i (seed ${masterSeed + i}): '
                  'exercise $id must have supersetTag cleared to null',
            );
          }

          final resultRelativeOrder =
              originalRelativeOrder.map((id) => updatedExercises[id]!).toList()
                ..sort((a, b) => a.position.compareTo(b.position));

          expect(
            resultRelativeOrder.map((e) => e.id).toList(),
            equals(originalRelativeOrder),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'relative position order of the previously-grouped '
                'exercises must be preserved',
          );
        }
      });
    },
  );

  // **Validates: Requirements 11.3**
  group('Property 18: Superset removal requires same group', () {
    test('removeSuperset with exercises from different supersetTags throws '
        'ValidationError', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = _anySessionWithTwoUnfinishedSupersets(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo);

        final tagsToIds = <String, List<String>>{};
        for (final e in session.sessionExercises) {
          final tag = e.supersetTag;
          if (tag == null) continue;
          (tagsToIds[tag] ??= []).add(e.id);
        }

        final tagList = tagsToIds.keys.toList();
        final firstTag = tagList[0];
        final secondTag = tagList[1];
        final mixedIds = [
          tagsToIds[firstTag]!.first,
          tagsToIds[secondTag]!.first,
        ]..shuffle(rng);

        expect(
          () => engine.removeSuperset(
            sessionId: session.id,
            sessionExerciseIds: mixedIds,
          ),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.invariant,
              'invariant',
              'superset_same_group',
            ),
          ),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'removeSuperset with ids spanning two different supersetTags '
              'must throw ValidationError(superset_same_group)',
        );
      }
    });
  });
}

Session _anySessionForSupersetCreation(Random rng) {
  final unfinishedCount = 2 + rng.nextInt(4);
  final otherCount = rng.nextInt(3);

  final states = <ExerciseState>[
    ...List.generate(unfinishedCount, (_) => const ExerciseState.unfinished()),
    ...List.generate(otherCount, (_) {
      switch (rng.nextInt(3)) {
        case 0:
          return const ExerciseState.completed();
        case 1:
          return const ExerciseState.skipped();
        default:
          return ExerciseState.replaced(substitute: anySubstituteExercise(rng));
      }
    }),
  ];
  states.shuffle(rng);

  return anySessionWithStates(rng, states: states);
}

Session _anySessionWithUnfinishedSuperset(Random rng) {
  final supersetSize = 2 + rng.nextInt(3);
  final otherUnfinished = rng.nextInt(3);
  final locked = rng.nextInt(3);

  final states = <ExerciseState>[
    ...List.generate(
      supersetSize + otherUnfinished,
      (_) => const ExerciseState.unfinished(),
    ),
    ...List.generate(locked, (_) {
      switch (rng.nextInt(3)) {
        case 0:
          return const ExerciseState.completed();
        case 1:
          return const ExerciseState.skipped();
        default:
          return ExerciseState.replaced(substitute: anySubstituteExercise(rng));
      }
    }),
  ];
  states.shuffle(rng);

  final session = anySessionWithStates(rng, states: states);

  final unfinishedExercises =
      session.sessionExercises.where((e) => e.state is UnfinishedState).toList()
        ..shuffle(rng);
  final taggedIds = unfinishedExercises
      .take(supersetSize)
      .map((e) => e.id)
      .toSet();
  final tag = anyUuidV4(rng);

  final updatedExercises = session.sessionExercises.map((e) {
    if (taggedIds.contains(e.id)) {
      return e.copyWith(supersetTag: tag);
    }
    return e;
  }).toList();

  return session.copyWith(sessionExercises: updatedExercises);
}

Session _anySessionWithTwoUnfinishedSupersets(Random rng) {
  final firstGroupSize = 2 + rng.nextInt(2);
  final secondGroupSize = 2 + rng.nextInt(2);
  final extraUnfinished = rng.nextInt(2);

  final states = List.generate(
    firstGroupSize + secondGroupSize + extraUnfinished,
    (_) => const ExerciseState.unfinished(),
  );

  final session = anySessionWithStates(rng, states: states);

  final unfinished =
      session.sessionExercises.where((e) => e.state is UnfinishedState).toList()
        ..shuffle(rng);

  final firstTag = anyUuidV4(rng);
  String secondTag;
  do {
    secondTag = anyUuidV4(rng);
  } while (secondTag == firstTag);

  final firstGroupIds = unfinished
      .take(firstGroupSize)
      .map((e) => e.id)
      .toSet();
  final secondGroupIds = unfinished
      .skip(firstGroupSize)
      .take(secondGroupSize)
      .map((e) => e.id)
      .toSet();

  final updatedExercises = session.sessionExercises.map((e) {
    if (firstGroupIds.contains(e.id)) {
      return e.copyWith(supersetTag: firstTag);
    }
    if (secondGroupIds.contains(e.id)) {
      return e.copyWith(supersetTag: secondTag);
    }
    return e;
  }).toList();

  return session.copyWith(sessionExercises: updatedExercises);
}
