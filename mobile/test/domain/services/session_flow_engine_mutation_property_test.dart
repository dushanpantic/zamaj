// Feature: session-flow-engine, Property 3: Cursor consistency after mutations
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/services/cursor.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';
import 'package:zamaj/modules/domain/services/session_state.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  // **Validates: Requirements 4.5, 8.5**
  group('Property 3: Cursor consistency after mutations', () {
    test('returned cursor always equals computeCursor(returnedSession) '
        'after any successful mutation', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = anyCursorableSession(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);

        final mutation = _pickMutation(rng, session, engine);
        if (mutation == null) continue;

        final SessionState result;
        try {
          result = await mutation();
        } on Exception {
          continue;
        }

        final expectedCursor = engine.computeCursor(result.session);

        expect(
          result.cursor,
          equals(expectedCursor),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'returned cursor must equal computeCursor(returnedSession)',
        );
      }
    });
  });
}

Future<SessionState> Function()? _pickMutation(
  Random rng,
  Session session,
  SessionFlowEngine engine,
) {
  final unfinished = session.sessionExercises
      .where((SessionExercise e) => e.state is UnfinishedState)
      .toList();

  if (unfinished.isEmpty) return null;

  final mutations = <Future<SessionState> Function()>[];

  final cursor = engine.computeCursor(session);
  if (cursor is ActiveCursor) {
    final activeExercise = session.sessionExercises.firstWhere(
      (SessionExercise e) => e.id == cursor.sessionExerciseId,
    );
    final planned = _lookupPlannedExercise(activeExercise, session);
    final effectiveMt = switch (activeExercise.state) {
      ReplacedState(:final substitute) => substitute.measurementType,
      _ => planned.measurementType,
    };

    mutations.add(
      () => engine.completeSet(
        sessionExerciseId: activeExercise.id,
        actualValues: anyActualSetValuesForMeasurement(rng, effectiveMt),
      ),
    );
  }

  final skipTarget = unfinished[rng.nextInt(unfinished.length)];
  mutations.add(() => engine.skipExercise(sessionExerciseId: skipTarget.id));

  final replaceTarget = unfinished[rng.nextInt(unfinished.length)];
  final substituteMt = anyMeasurementType(rng);
  mutations.add(
    () => engine.replaceExercise(
      sessionExerciseId: replaceTarget.id,
      substituteName: anyUuidV4(rng),
      substituteMeasurementType: substituteMt,
    ),
  );

  if (unfinished.length >= 2) {
    final ids = unfinished.map((SessionExercise e) => e.id).toList()
      ..shuffle(rng);
    mutations.add(
      () => engine.reorderUnfinished(
        sessionId: session.id,
        orderedUnfinishedIds: ids,
      ),
    );
  }

  return mutations[rng.nextInt(mutations.length)];
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
