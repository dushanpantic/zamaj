// Feature: session-flow-engine, Property 2: Cursor computation correctness
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/services/cursor.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  const iterations = 100;

  // **Validates: Requirements 2.2, 4.1, 4.2, 4.3, 4.4**
  test(
    'cursor points to first unfinished/replaced exercise with sets remaining',
    () {
      final rng = Random(7742);
      final clock = Clock.fixed(DateTime.utc(2024));
      final repo = FakeSessionRepository(clock: clock);
      final engine = SessionFlowEngine(repository: repo);

      for (var i = 0; i < iterations; i++) {
        final session = anySessionForEngine(rng);
        final cursor = engine.computeCursor(session);
        final expected = _expectedCursor(session);

        expect(
          cursor,
          equals(expected),
          reason: 'iteration $i: session ${session.id}',
        );
      }
    },
  );

  test('cursor is completed when all exercises are terminal', () {
    final rng = Random(8853);
    final clock = Clock.fixed(DateTime.utc(2024));
    final repo = FakeSessionRepository(clock: clock);
    final engine = SessionFlowEngine(repository: repo);

    for (var i = 0; i < iterations; i++) {
      final exerciseCount = 1 + rng.nextInt(5);
      final states = List.generate(exerciseCount, (_) {
        switch (rng.nextInt(3)) {
          case 0:
            return const ExerciseState.completed();
          case 1:
            return const ExerciseState.skipped();
          default:
            return ExerciseState.replaced(
              substitute: anySubstituteExercise(rng),
            );
        }
      });

      final session = anySessionWithStates(rng, states: states);
      final allTerminal = _allExercisesTerminal(session);

      if (allTerminal) {
        final cursor = engine.computeCursor(session);
        expect(
          cursor,
          equals(const Cursor.completed()),
          reason: 'iteration $i: all terminal but cursor not completed',
        );
      }
    }
  });

  test('cursor setIndex equals executedSets.length of target exercise', () {
    final rng = Random(3319);
    final clock = Clock.fixed(DateTime.utc(2024));
    final repo = FakeSessionRepository(clock: clock);
    final engine = SessionFlowEngine(repository: repo);

    for (var i = 0; i < iterations; i++) {
      final session = anyCursorableSession(rng);
      final cursor = engine.computeCursor(session);

      switch (cursor) {
        case ActiveCursor(:final sessionExerciseId, :final setIndex):
          final exercise = session.sessionExercises.firstWhere(
            (e) => e.id == sessionExerciseId,
          );
          expect(
            setIndex,
            equals(exercise.executedSets.length),
            reason: 'iteration $i: setIndex should equal executedSets.length',
          );
        case CompletedCursor():
          fail(
            'iteration $i: expected active cursor from anyCursorableSession',
          );
      }
    }
  });

  test(
    'cursor targets exercise in position order (no earlier unfinished exists)',
    () {
      final rng = Random(5501);
      final clock = Clock.fixed(DateTime.utc(2024));
      final repo = FakeSessionRepository(clock: clock);
      final engine = SessionFlowEngine(repository: repo);

      for (var i = 0; i < iterations; i++) {
        final session = anyCursorableSession(rng);
        final cursor = engine.computeCursor(session);

        switch (cursor) {
          case ActiveCursor(:final sessionExerciseId):
            final sorted = List<SessionExercise>.of(session.sessionExercises)
              ..sort((a, b) => a.position.compareTo(b.position));

            final targetExercise = sorted.firstWhere(
              (e) => e.id == sessionExerciseId,
            );

            for (final exercise in sorted) {
              if (exercise.position >= targetExercise.position) break;
              final isCandidate = _isCursorCandidate(exercise, session);
              expect(
                isCandidate,
                isFalse,
                reason:
                    'iteration $i: exercise at position ${exercise.position} '
                    'is a cursor candidate but cursor points to position '
                    '${targetExercise.position}',
              );
            }
          case CompletedCursor():
            fail(
              'iteration $i: expected active cursor from anyCursorableSession',
            );
        }
      }
    },
  );
}

Cursor _expectedCursor(Session session) {
  final sorted = List<SessionExercise>.of(session.sessionExercises)
    ..sort((a, b) => a.position.compareTo(b.position));

  for (final exercise in sorted) {
    if (_isCursorCandidate(exercise, session)) {
      return Cursor.active(
        sessionExerciseId: exercise.id,
        setIndex: exercise.executedSets.length,
      );
    }
  }

  return const Cursor.completed();
}

bool _isCursorCandidate(SessionExercise exercise, Session session) {
  switch (exercise.state) {
    case UnfinishedState():
      final plannedSetCount = _lookupPlannedSetCount(exercise, session);
      return exercise.executedSets.length < plannedSetCount;
    case ReplacedState(:final substitute):
      return exercise.executedSets.length < substitute.setCount;
    case CompletedState():
    case SkippedState():
      return false;
  }
}

int _lookupPlannedSetCount(SessionExercise exercise, Session session) {
  final workoutDay = session.snapshot.workoutDay;
  for (final group in workoutDay.exerciseGroups) {
    for (final ex in group.exercises) {
      if (ex.id == exercise.plannedExerciseIdInSnapshot) {
        return ex.sets.length;
      }
    }
  }
  return 0;
}

bool _allExercisesTerminal(Session session) {
  for (final exercise in session.sessionExercises) {
    switch (exercise.state) {
      case CompletedState():
      case SkippedState():
        continue;
      case ReplacedState(:final substitute):
        if (exercise.executedSets.length < substitute.setCount) return false;
      case UnfinishedState():
        return false;
    }
  }
  return true;
}
