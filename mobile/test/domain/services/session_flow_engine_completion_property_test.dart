// Feature: session-flow-engine, Property 21: Session completion query
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';
import '../../support/generators.dart';

void main() {
  // **Validates: Requirements 14.1, 14.2, 14.3**
  group('Property 21: Session completion query', () {
    late SessionFlowEngine engine;

    setUp(() {
      final fakeClock = Clock.fixed(DateTime.utc(2024));
      final repo = FakeSessionRepository(clock: fakeClock);
      engine = SessionFlowEngine(repository: repo);
    });

    test(
      'isSessionComplete matches independent oracle for random sessions',
      () {
        const iterations = 100;
        final masterSeed = Random().nextInt(1 << 32);

        for (var i = 0; i < iterations; i++) {
          final rng = Random(masterSeed + i);
          final session = anySessionForEngine(rng);

          final actual = engine.isSessionComplete(session);
          final expected = _oracleIsComplete(session);

          expect(
            actual,
            equals(expected),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'engine returned $actual but oracle expected $expected',
          );
        }
      },
    );

    test('sessions with all exercises in terminal states return true', () {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final exerciseCount = 1 + rng.nextInt(5);
        final states = List.generate(exerciseCount, (_) {
          return rng.nextBool()
              ? const ExerciseState.completed()
              : const ExerciseState.skipped();
        });

        final session = _sessionWithFullSets(rng, states: states);
        final actual = engine.isSessionComplete(session);

        expect(
          actual,
          isTrue,
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'all terminal states should be complete',
        );
      }
    });

    test('sessions with at least one unfinished exercise return false', () {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final exerciseCount = 1 + rng.nextInt(5);
        final unfinishedIndex = rng.nextInt(exerciseCount);
        final states = List.generate(exerciseCount, (j) {
          if (j == unfinishedIndex) {
            return const ExerciseState.unfinished();
          }
          return rng.nextBool()
              ? const ExerciseState.completed()
              : const ExerciseState.skipped();
        });

        final session = anySessionWithStates(rng, states: states);
        final actual = engine.isSessionComplete(session);

        expect(
          actual,
          isFalse,
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'session with unfinished exercise should be incomplete',
        );
      }
    });

  });
}

bool _oracleIsComplete(Session session) {
  for (final exercise in session.sessionExercises) {
    switch (exercise.state) {
      case CompletedState():
      case SkippedState():
        continue;
      case UnfinishedState():
        return false;
    }
  }
  return true;
}

Session _sessionWithFullSets(
  Random rng, {
  required List<ExerciseState> states,
}) {
  final exerciseCount = states.length;
  final workoutDay = _anyWorkoutDayWithExerciseCount(rng, exerciseCount);
  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );

  final allExercises = [
    for (final group in workoutDay.exerciseGroups) ...group.exercises,
  ];
  final sessionId = anyUuidV4(rng);

  final sessionExercises = List.generate(exerciseCount, (i) {
    final planned = allExercises[i];
    final mt = planned.measurementType;
    final plannedSetCount = planned.sets.length;
    final state = states[i];

    final executedSetCount = switch (state) {
      CompletedState() => plannedSetCount,
      SkippedState() => rng.nextInt(plannedSetCount + 1),
      UnfinishedState() => rng.nextInt(plannedSetCount),
    };

    return SessionExercise(
      id: anyUuidV4(rng),
      sessionId: sessionId,
      position: i,
      plannedExerciseIdInSnapshot: planned.id,
      state: state,
      executedSets: List.generate(executedSetCount, (j) {
        final effectiveMt = mt;
        return ExecutedSet(
          id: anyUuidV4(rng),
          sessionExerciseId: anyUuidV4(rng),
          position: j,
          measurementType: effectiveMt,
          actualValues: anyActualSetValuesForMeasurement(rng, effectiveMt),
          plannedSetIdInSnapshot: j < planned.sets.length
              ? planned.sets[j].id
              : null,
          completedAt: anyUtcDateTime(rng),
          createdAt: anyUtcDateTime(rng),
          updatedAt: anyUtcDateTime(rng),
          schemaVersion: 1,
        );
      }),
      createdAt: anyUtcDateTime(rng),
      updatedAt: anyUtcDateTime(rng),
      schemaVersion: 1,
    );
  });

  return Session(
    id: sessionId,
    workoutDayId: workoutDay.id,
    snapshot: snapshot,
    sessionExercises: sessionExercises,
    notes: const [],
    extraWork: const [],
    startedAt: anyUtcDateTime(rng),
    endedAt: null,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

WorkoutDay _anyWorkoutDayWithExerciseCount(Random rng, int exerciseCount) {
  assert(exerciseCount >= 1);
  final workoutDayId = anyUuidV4(rng);
  final groups = <ExerciseGroup>[];
  var remaining = exerciseCount;
  var groupPosition = 0;

  while (remaining > 0) {
    final ExerciseGroupKind kind;
    final int groupExerciseCount;

    if (remaining >= 2 && rng.nextInt(3) == 0) {
      kind = const ExerciseGroupKind.superset();
      groupExerciseCount = min(2 + rng.nextInt(2), remaining);
    } else {
      kind = const ExerciseGroupKind.single();
      groupExerciseCount = 1;
    }

    final groupId = anyUuidV4(rng);
    final exercises = List.generate(groupExerciseCount, (i) {
      final mt = anyMeasurementType(rng);
      final setCount = 1 + rng.nextInt(5);
      final exerciseId = anyUuidV4(rng);
      return Exercise(
        id: exerciseId,
        exerciseGroupId: groupId,
        position: i,
        name: 'exercise_${groupPosition}_$i',
        measurementType: mt,
        metadata: anyExerciseMetadata(rng),
        plannedRestSeconds: rng.nextBool() ? rng.nextInt(301) : null,
        sets: List.generate(setCount, (j) {
          return WorkoutSet(
            id: anyUuidV4(rng),
            exerciseId: exerciseId,
            position: j,
            measurementType: mt,
            plannedValues: anyPlannedSetValuesForMeasurement(rng, mt),
            createdAt: anyUtcDateTime(rng),
            updatedAt: anyUtcDateTime(rng),
            schemaVersion: 1,
          );
        }),
        createdAt: anyUtcDateTime(rng),
        updatedAt: anyUtcDateTime(rng),
        schemaVersion: 1,
      );
    });

    groups.add(
      ExerciseGroup(
        id: groupId,
        workoutDayId: workoutDayId,
        position: groupPosition,
        kind: kind,
        exercises: exercises,
        createdAt: anyUtcDateTime(rng),
        updatedAt: anyUtcDateTime(rng),
        schemaVersion: 1,
      ),
    );

    remaining -= groupExerciseCount;
    groupPosition++;
  }

  return WorkoutDay(
    id: workoutDayId,
    programId: anyUuidV4(rng),
    name: 'workout_day',
    exerciseGroups: groups,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}
