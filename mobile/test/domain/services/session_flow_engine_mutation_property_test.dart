// Feature: session-flow-engine, Property 3: Cursor consistency after mutations
// Feature: session-flow-engine, Property 6: Set completion records correct values and timestamp
// Feature: session-flow-engine, Property 7: Last set transitions exercise to completed
// Feature: session-flow-engine, Property 8: Measurement type validation
import 'dart:math';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
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

  // **Validates: Requirements 5.1, 18.2, 18.3, 18.4**
  group('Property 6: Set completion records correct values and timestamp', () {
    test('completeSet persists an ExecutedSet with the provided values '
        'and the clock timestamp', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = anyCursorableSession(rng);
        final fixedTime = anyUtcDateTime(rng);
        final fakeClock = Clock.fixed(fixedTime);
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
        final cursor = engine.computeCursor(session);

        if (cursor is! ActiveCursor) continue;

        final activeExercise = session.sessionExercises.firstWhere(
          (SessionExercise e) => e.id == cursor.sessionExerciseId,
        );

        final planned = _lookupPlannedExercise(activeExercise, session);
        final effectiveMt = switch (activeExercise.state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => planned.measurementType,
        };

        final values = anyActualSetValuesForMeasurement(rng, effectiveMt);

        final result = await engine.completeSet(
          sessionExerciseId: activeExercise.id,
          actualValues: values,
        );

        final updatedExercise = result.session.sessionExercises.firstWhere(
          (SessionExercise e) => e.id == activeExercise.id,
        );

        expect(
          updatedExercise.executedSets.length,
          equals(activeExercise.executedSets.length + 1),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'should have one more executed set',
        );

        final newSet = updatedExercise.executedSets.last;

        expect(
          newSet.actualValues,
          equals(values),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'actualValues must equal the provided values',
        );

        expect(
          newSet.completedAt,
          equals(fixedTime),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'completedAt must equal the injected clock time',
        );
      }
    });
  });

  // **Validates: Requirements 5.3**
  group('Property 7: Last set transitions exercise to completed', () {
    test(
      'completing the final set transitions exercise state to completed',
      () async {
        const iterations = 100;
        final masterSeed = Random().nextInt(1 << 32);

        for (var i = 0; i < iterations; i++) {
          final rng = Random(masterSeed + i);
          final session = _anySessionOneSetFromCompletion(rng);
          final fixedTime = anyUtcDateTime(rng);
          final fakeClock = Clock.fixed(fixedTime);
          final repo = FakeSessionRepository(clock: fakeClock);
          repo.seedSession(session);

          final engine = SessionFlowEngine(repository: repo, clock: fakeClock);

          final targetExercise = session.sessionExercises.firstWhere(
            (e) => e.state is UnfinishedState,
          );
          final planned = _lookupPlannedExercise(targetExercise, session);
          final plannedSetCount = planned.sets.length;
          final values = anyActualSetValuesForMeasurement(
            rng,
            planned.measurementType,
          );

          final result = await engine.completeSet(
            sessionExerciseId: targetExercise.id,
            actualValues: values,
          );

          final updatedExercise = result.session.sessionExercises.firstWhere(
            (e) => e.id == targetExercise.id,
          );

          expect(
            updatedExercise.state,
            equals(const ExerciseState.completed()),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'exercise should transition to completed after final set',
          );

          expect(
            updatedExercise.executedSets.length,
            equals(plannedSetCount),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'executedSets.length should equal plannedSetCount',
          );
        }
      },
    );
  });

  // **Validates: Requirements 5.4, 6.3, 8.3**
  group('Property 8: Measurement type validation', () {
    test('completeSet with mismatched type throws ValidationError', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = anyCursorableSession(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
        final cursor = engine.computeCursor(session);

        if (cursor is! ActiveCursor) continue;

        final activeExercise = session.sessionExercises.firstWhere(
          (SessionExercise e) => e.id == cursor.sessionExerciseId,
        );

        final planned = _lookupPlannedExercise(activeExercise, session);
        final effectiveMt = switch (activeExercise.state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => planned.measurementType,
        };

        final wrongMt = _oppositeMeasurementType(effectiveMt);
        final wrongValues = anyActualSetValuesForMeasurement(rng, wrongMt);

        expect(
          () => engine.completeSet(
            sessionExerciseId: activeExercise.id,
            actualValues: wrongValues,
          ),
          throwsA(isA<ValidationError>()),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'completeSet with mismatched type must throw ValidationError',
        );
      }
    });

    test(
      'updateExecutedSet with mismatched type throws ValidationError',
      () async {
        const iterations = 100;
        final masterSeed = Random().nextInt(1 << 32);

        for (var i = 0; i < iterations; i++) {
          final rng = Random(masterSeed + i);
          final session = _anySessionWithExecutedSets(rng);
          final fakeClock = Clock.fixed(anyUtcDateTime(rng));
          final repo = FakeSessionRepository(clock: fakeClock);
          repo.seedSession(session);

          final engine = SessionFlowEngine(repository: repo, clock: fakeClock);

          final exerciseWithSets = session.sessionExercises
              .where((e) => e.executedSets.isNotEmpty)
              .toList();
          if (exerciseWithSets.isEmpty) continue;

          final targetExercise =
              exerciseWithSets[rng.nextInt(exerciseWithSets.length)];
          final targetSet = targetExercise
              .executedSets[rng.nextInt(targetExercise.executedSets.length)];

          final planned = _lookupPlannedExercise(targetExercise, session);
          final effectiveMt = switch (targetExercise.state) {
            ReplacedState(:final substitute) => substitute.measurementType,
            _ => planned.measurementType,
          };

          final wrongMt = _oppositeMeasurementType(effectiveMt);
          final wrongValues = anyActualSetValuesForMeasurement(rng, wrongMt);

          expect(
            () => engine.updateExecutedSet(
              executedSetId: targetSet.id,
              actualValues: wrongValues,
            ),
            throwsA(isA<ValidationError>()),
            reason:
                'iteration $i (seed ${masterSeed + i}): '
                'updateExecutedSet with mismatched type must throw '
                'ValidationError',
          );
        }
      },
    );

    test('completeSet on replaced exercise with original type throws '
        'ValidationError', () async {
      const iterations = 100;
      final masterSeed = Random().nextInt(1 << 32);

      for (var i = 0; i < iterations; i++) {
        final rng = Random(masterSeed + i);
        final session = _anySessionWithReplacedDifferentType(rng);
        final fakeClock = Clock.fixed(anyUtcDateTime(rng));
        final repo = FakeSessionRepository(clock: fakeClock);
        repo.seedSession(session);

        final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
        final cursor = engine.computeCursor(session);

        if (cursor is! ActiveCursor) continue;

        final activeExercise = session.sessionExercises.firstWhere(
          (SessionExercise e) => e.id == cursor.sessionExerciseId,
        );

        if (activeExercise.state is! ReplacedState) continue;

        final planned = _lookupPlannedExercise(activeExercise, session);
        final originalMt = planned.measurementType;
        final wrongValues = anyActualSetValuesForMeasurement(rng, originalMt);

        expect(
          () => engine.completeSet(
            sessionExerciseId: activeExercise.id,
            actualValues: wrongValues,
          ),
          throwsA(isA<ValidationError>()),
          reason:
              'iteration $i (seed ${masterSeed + i}): '
              'completeSet on replaced exercise with original type '
              'must throw ValidationError',
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

Session _anySessionOneSetFromCompletion(Random rng) {
  final exerciseCount = 1 + rng.nextInt(4);
  final targetIndex = rng.nextInt(exerciseCount);
  final workoutDayId = anyUuidV4(rng);
  final groups = <ExerciseGroup>[];
  var remaining = exerciseCount;
  var groupPosition = 0;

  while (remaining > 0) {
    final groupId = anyUuidV4(rng);
    final exerciseId = anyUuidV4(rng);
    final mt = anyMeasurementType(rng);
    final setCount = 1 + rng.nextInt(5);

    final exercises = [
      Exercise(
        id: exerciseId,
        exerciseGroupId: groupId,
        position: 0,
        name: 'exercise_$groupPosition',
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
      ),
    ];

    groups.add(
      ExerciseGroup(
        id: groupId,
        workoutDayId: workoutDayId,
        position: groupPosition,
        kind: const ExerciseGroupKind.single(),
        exercises: exercises,
        createdAt: anyUtcDateTime(rng),
        updatedAt: anyUtcDateTime(rng),
        schemaVersion: 1,
      ),
    );

    remaining--;
    groupPosition++;
  }

  final workoutDay = WorkoutDay(
    id: workoutDayId,
    programId: anyUuidV4(rng),
    name: 'workout_day',
    exerciseGroups: groups,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );

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

    if (i == targetIndex) {
      final executedSetCount = plannedSetCount - 1;
      return SessionExercise(
        id: anyUuidV4(rng),
        sessionId: sessionId,
        position: i,
        plannedExerciseIdInSnapshot: planned.id,
        state: const ExerciseState.unfinished(),
        executedSets: List.generate(executedSetCount, (j) {
          return ExecutedSet(
            id: anyUuidV4(rng),
            sessionExerciseId: anyUuidV4(rng),
            position: j,
            measurementType: mt,
            actualValues: anyActualSetValuesForMeasurement(rng, mt),
            plannedSetIdInSnapshot: planned.sets[j].id,
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
    }

    if (i < targetIndex) {
      return SessionExercise(
        id: anyUuidV4(rng),
        sessionId: sessionId,
        position: i,
        plannedExerciseIdInSnapshot: planned.id,
        state: const ExerciseState.completed(),
        executedSets: List.generate(plannedSetCount, (j) {
          return ExecutedSet(
            id: anyUuidV4(rng),
            sessionExerciseId: anyUuidV4(rng),
            position: j,
            measurementType: mt,
            actualValues: anyActualSetValuesForMeasurement(rng, mt),
            plannedSetIdInSnapshot: planned.sets[j].id,
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
    }

    return SessionExercise(
      id: anyUuidV4(rng),
      sessionId: sessionId,
      position: i,
      plannedExerciseIdInSnapshot: planned.id,
      state: const ExerciseState.unfinished(),
      executedSets: List.generate(rng.nextInt(plannedSetCount), (j) {
        return ExecutedSet(
          id: anyUuidV4(rng),
          sessionExerciseId: anyUuidV4(rng),
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

MeasurementType _oppositeMeasurementType(MeasurementType mt) {
  return switch (mt) {
    RepBasedMeasurement() => const MeasurementType.timeBased(),
    TimeBasedMeasurement() => const MeasurementType.repBased(),
  };
}

Session _anySessionWithExecutedSets(Random rng) {
  final exerciseCount = 1 + rng.nextInt(4);
  final workoutDayId = anyUuidV4(rng);
  final groups = <ExerciseGroup>[];
  var groupPosition = 0;

  for (var i = 0; i < exerciseCount; i++) {
    final groupId = anyUuidV4(rng);
    final exerciseId = anyUuidV4(rng);
    final mt = anyMeasurementType(rng);
    final setCount = 2 + rng.nextInt(4);

    groups.add(
      ExerciseGroup(
        id: groupId,
        workoutDayId: workoutDayId,
        position: groupPosition++,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          Exercise(
            id: exerciseId,
            exerciseGroupId: groupId,
            position: 0,
            name: 'exercise_$i',
            measurementType: mt,
            metadata: anyExerciseMetadata(rng),
            plannedRestSeconds: null,
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
          ),
        ],
        createdAt: anyUtcDateTime(rng),
        updatedAt: anyUtcDateTime(rng),
        schemaVersion: 1,
      ),
    );
  }

  final workoutDay = WorkoutDay(
    id: workoutDayId,
    programId: anyUuidV4(rng),
    name: 'workout_day',
    exerciseGroups: groups,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );

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

    final ExerciseState state;
    final int executedSetCount;
    switch (rng.nextInt(3)) {
      case 0:
        state = const ExerciseState.completed();
        executedSetCount = plannedSetCount;
      case 1:
        state = const ExerciseState.skipped();
        executedSetCount = 1 + rng.nextInt(plannedSetCount);
      default:
        final sub = SubstituteExercise(
          name: 'sub_$i',
          measurementType: mt,
          metadata: null,
        );
        state = ExerciseState.replaced(substitute: sub);
        executedSetCount = 1 + rng.nextInt(plannedSetCount);
    }

    return SessionExercise(
      id: anyUuidV4(rng),
      sessionId: sessionId,
      position: i,
      plannedExerciseIdInSnapshot: planned.id,
      state: state,
      executedSets: List.generate(executedSetCount, (j) {
        final effectiveMt = switch (state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => mt,
        };
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

Session _anySessionWithReplacedDifferentType(Random rng) {
  final exerciseCount = 1 + rng.nextInt(3);
  final replacedIndex = rng.nextInt(exerciseCount);
  final workoutDayId = anyUuidV4(rng);
  final groups = <ExerciseGroup>[];
  var groupPosition = 0;

  for (var i = 0; i < exerciseCount; i++) {
    final groupId = anyUuidV4(rng);
    final exerciseId = anyUuidV4(rng);
    final MeasurementType mt;
    if (i == replacedIndex) {
      mt = const MeasurementType.repBased();
    } else {
      mt = anyMeasurementType(rng);
    }
    final setCount = 1 + rng.nextInt(5);

    groups.add(
      ExerciseGroup(
        id: groupId,
        workoutDayId: workoutDayId,
        position: groupPosition++,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          Exercise(
            id: exerciseId,
            exerciseGroupId: groupId,
            position: 0,
            name: 'exercise_$i',
            measurementType: mt,
            metadata: anyExerciseMetadata(rng),
            plannedRestSeconds: null,
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
          ),
        ],
        createdAt: anyUtcDateTime(rng),
        updatedAt: anyUtcDateTime(rng),
        schemaVersion: 1,
      ),
    );
  }

  final workoutDay = WorkoutDay(
    id: workoutDayId,
    programId: anyUuidV4(rng),
    name: 'workout_day',
    exerciseGroups: groups,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );

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

    if (i == replacedIndex) {
      final substituteMt = _oppositeMeasurementType(mt);
      final sub = SubstituteExercise(
        name: 'substitute_$i',
        measurementType: substituteMt,
        metadata: null,
      );
      final executedSetCount = rng.nextInt(plannedSetCount);
      return SessionExercise(
        id: anyUuidV4(rng),
        sessionId: sessionId,
        position: i,
        plannedExerciseIdInSnapshot: planned.id,
        state: ExerciseState.replaced(substitute: sub),
        executedSets: List.generate(executedSetCount, (j) {
          return ExecutedSet(
            id: anyUuidV4(rng),
            sessionExerciseId: anyUuidV4(rng),
            position: j,
            measurementType: substituteMt,
            actualValues: anyActualSetValuesForMeasurement(rng, substituteMt),
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
    }

    return SessionExercise(
      id: anyUuidV4(rng),
      sessionId: sessionId,
      position: i,
      plannedExerciseIdInSnapshot: planned.id,
      state: const ExerciseState.completed(),
      executedSets: List.generate(plannedSetCount, (j) {
        return ExecutedSet(
          id: anyUuidV4(rng),
          sessionExerciseId: anyUuidV4(rng),
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
