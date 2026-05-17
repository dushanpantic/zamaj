// Feature: session-flow-engine, Property 2: openTargets projection correctness
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/services/log_target.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  const iterations = 100;

  // **Validates: Requirements 2.2, 4.1, 4.2, 4.3, 4.4** (re-expressed against
  // openTargets after the cursor removal in the set-order redesign).
  test('openTargets lists every loggable exercise in position order with '
      'plannedSetIndex == executedSets.length', () {
    final rng = Random(7742);
    final clock = Clock.fixed(DateTime.utc(2024));
    final repo = FakeSessionRepository(clock: clock);
    final engine = SessionFlowEngine(repository: repo);

    for (var i = 0; i < iterations; i++) {
      final session = anySessionForEngine(rng);
      final targets = engine.computeOpenTargets(session);
      final expected = _expectedOpenTargets(session);

      expect(
        targets,
        equals(expected),
        reason: 'iteration $i: session ${session.id}',
      );
    }
  });

  test('openTargets is empty when all exercises are terminal', () {
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
        final targets = engine.computeOpenTargets(session);
        expect(
          targets,
          isEmpty,
          reason: 'iteration $i: all terminal but openTargets is not empty',
        );
      }
    }
  });

  test('each LogTarget.plannedSetIndex equals executedSets.length of its '
      'exercise', () {
    final rng = Random(3319);
    final clock = Clock.fixed(DateTime.utc(2024));
    final repo = FakeSessionRepository(clock: clock);
    final engine = SessionFlowEngine(repository: repo);

    for (var i = 0; i < iterations; i++) {
      final session = anySessionWithLoggableTargets(rng);
      final targets = engine.computeOpenTargets(session);

      expect(
        targets,
        isNotEmpty,
        reason:
            'iteration $i: anySessionWithLoggableTargets should produce targets',
      );

      for (final target in targets) {
        final exercise = session.sessionExercises.firstWhere(
          (e) => e.id == target.sessionExerciseId,
        );
        expect(
          target.plannedSetIndex,
          equals(exercise.executedSets.length),
          reason:
              'iteration $i: plannedSetIndex should equal '
              'executedSets.length for ${target.sessionExerciseId}',
        );
      }
    }
  });

  test('openTargets order matches exercise position order', () {
    final rng = Random(5501);
    final clock = Clock.fixed(DateTime.utc(2024));
    final repo = FakeSessionRepository(clock: clock);
    final engine = SessionFlowEngine(repository: repo);

    for (var i = 0; i < iterations; i++) {
      final session = anySessionWithLoggableTargets(rng);
      final targets = engine.computeOpenTargets(session);
      final positions = targets
          .map(
            (t) => session.sessionExercises
                .firstWhere((e) => e.id == t.sessionExerciseId)
                .position,
          )
          .toList();
      final sortedPositions = List<int>.of(positions)..sort();

      expect(
        positions,
        equals(sortedPositions),
        reason:
            'iteration $i: openTargets must be in ascending exercise '
            'position order',
      );
    }
  });
}

List<LogTarget> _expectedOpenTargets(Session session) {
  final sorted = List<SessionExercise>.of(session.sessionExercises)
    ..sort((a, b) => a.position.compareTo(b.position));

  final out = <LogTarget>[];
  for (final exercise in sorted) {
    if (_isLoggable(exercise, session)) {
      out.add(
        LogTarget(
          sessionExerciseId: exercise.id,
          plannedSetIndex: exercise.executedSets.length,
        ),
      );
    }
  }
  return out;
}

bool _isLoggable(SessionExercise exercise, Session session) {
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
