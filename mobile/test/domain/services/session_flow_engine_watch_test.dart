import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';
import 'package:zamaj/modules/domain/services/session_state.dart';

import '../../support/fake_session_repository.dart';

/// Pins the reactive-read contract every screen subscribing to a session
/// depends on: a single `watchSession` call must emit the initial value plus
/// one emission per committed mutation, regardless of which mutation kind.
/// If a future refactor stops notifying for any mutation, every multi-screen
/// stay-in-sync feature silently breaks — that's the bug this test guards.
void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  ({FakeSessionRepository repo, SessionFlowEngine engine}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo);
    return (repo: repo, engine: engine);
  }

  WorkoutDay buildDay() {
    final t = DateTime.utc(2024);
    return WorkoutDay(
      id: 'wd-1',
      programId: 'p-1',
      name: 'Upper',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g1',
          workoutDayId: 'wd-1',
          position: 0,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-a',
              exerciseGroupId: 'g1',
              position: 0,
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                WorkoutSet(
                  id: 'ws-a-0',
                  exerciseId: 'ex-a',
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: const PlannedSetValues.repBased(
                    weightKg: 80,
                    reps: 5,
                  ),
                  createdAt: t,
                  updatedAt: t,
                  schemaVersion: 1,
                ),
              ],
              createdAt: t,
              updatedAt: t,
              schemaVersion: 1,
            ),
          ],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
        ExerciseGroup(
          id: 'g2',
          workoutDayId: 'wd-1',
          position: 1,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-b',
              exerciseGroupId: 'g2',
              position: 0,
              name: 'Squat',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                WorkoutSet(
                  id: 'ws-b-0',
                  exerciseId: 'ex-b',
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: const PlannedSetValues.repBased(
                    weightKg: 100,
                    reps: 5,
                  ),
                  createdAt: t,
                  updatedAt: t,
                  schemaVersion: 1,
                ),
              ],
              createdAt: t,
              updatedAt: t,
              schemaVersion: 1,
            ),
          ],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      ],
      createdAt: t,
      updatedAt: t,
      schemaVersion: 1,
    );
  }

  test('emits null for a session that does not exist', () async {
    final s = setup();
    final emissions = <SessionState?>[];
    final sub = s.engine
        .watchSession(sessionId: 'missing')
        .listen(emissions.add);
    await pumpEventQueue();
    expect(emissions, [null]);
    await sub.cancel();
  });

  test('emits the initial state and one emission per committed mutation '
      'across every mutation kind', () async {
    final s = setup();
    s.repo.seedWorkoutDay(buildDay());

    final started = await s.engine.startSession(workoutDayId: 'wd-1');
    final sessionId = started.session.id;
    final exA = started.session.sessionExercises
        .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-a')
        .id;
    final exB = started.session.sessionExercises
        .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-b')
        .id;

    final emissions = <SessionState?>[];
    final sub = s.engine
        .watchSession(sessionId: sessionId)
        .listen(emissions.add);
    await pumpEventQueue();
    expect(emissions, hasLength(1), reason: 'initial emission');
    expect(emissions.last!.session.id, sessionId);

    // Each closure represents one engine mutation that MUST result in
    // exactly one stream emission. Listed inline so a regression points
    // at the offending mutation.
    final mutations = <Future<void> Function()>[
      () => s.engine.addSessionNote(sessionId: sessionId, body: 'note'),
      () => s.engine.addExtraWork(sessionId: sessionId, body: 'extra'),
      () => s.engine.createSuperset(
        sessionId: sessionId,
        sessionExerciseIds: [exA, exB],
      ),
      () => s.engine.removeSuperset(
        sessionId: sessionId,
        sessionExerciseIds: [exA, exB],
      ),
      () => s.engine.reorderUnfinished(
        sessionId: sessionId,
        orderedUnfinishedIds: [exB, exA],
      ),
      () => s.engine.skipExercise(sessionExerciseId: exB),
      () => s.engine.completeSet(
        sessionExerciseId: exA,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      ),
      () => s.engine.endSession(sessionId: sessionId),
    ];

    var expected = 1;
    for (final mutate in mutations) {
      await mutate();
      await pumpEventQueue();
      expected += 1;
      expect(
        emissions,
        hasLength(expected),
        reason: 'mutation #${expected - 1} should produce one emission',
      );
    }

    // Latest emission reflects the post-end-session state.
    expect(emissions.last!.session.endedAt, isNotNull);

    await sub.cancel();
  });

  test(
    'updateExecutedSet and deleteExecutedSet each trigger an emission',
    () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay());
      final started = await s.engine.startSession(workoutDayId: 'wd-1');
      final sessionId = started.session.id;
      final exA = started.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-a')
          .id;
      final logged = await s.engine.completeSet(
        sessionExerciseId: exA,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      final setId = logged.session.sessionExercises
          .firstWhere((e) => e.id == exA)
          .executedSets
          .single
          .id;

      final emissions = <SessionState?>[];
      final sub = s.engine
          .watchSession(sessionId: sessionId)
          .listen(emissions.add);
      await pumpEventQueue();
      expect(emissions, hasLength(1));

      await s.engine.updateExecutedSet(
        executedSetId: setId,
        actualValues: const ActualSetValues.repBased(weightKg: 82.5, reps: 5),
      );
      await pumpEventQueue();
      expect(emissions, hasLength(2));

      await s.engine.deleteExecutedSet(executedSetId: setId);
      await pumpEventQueue();
      expect(emissions, hasLength(3));

      // After deletion the exercise reverted to unfinished.
      final ex = emissions.last!.session.sessionExercises.firstWhere(
        (e) => e.id == exA,
      );
      expect(ex.state, isA<UnfinishedState>());
      expect(ex.executedSets, isEmpty);

      await sub.cancel();
    },
  );

  test('replaceExercise triggers an emission', () async {
    final s = setup();
    s.repo.seedWorkoutDay(buildDay());
    final started = await s.engine.startSession(workoutDayId: 'wd-1');
    final sessionId = started.session.id;
    final exA = started.session.sessionExercises
        .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-a')
        .id;

    final emissions = <SessionState?>[];
    final sub = s.engine
        .watchSession(sessionId: sessionId)
        .listen(emissions.add);
    await pumpEventQueue();
    expect(emissions, hasLength(1));

    await s.engine.replaceExercise(
      sessionExerciseId: exA,
      substituteName: 'Push-Up',
      substituteMeasurementType: const MeasurementType.repBased(),
      substitutePlannedValues: const PlannedSetValues.repBased(
        weightKg: 0,
        reps: 10,
      ),
      substituteSetCount: 3,
    );
    await pumpEventQueue();
    expect(emissions, hasLength(2));

    final ex = emissions.last!.session.sessionExercises.firstWhere(
      (e) => e.id == exA,
    );
    expect(ex.state, isA<ReplacedState>());

    await sub.cancel();
  });
}
