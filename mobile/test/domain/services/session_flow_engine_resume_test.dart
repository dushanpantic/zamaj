import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

import '../../support/fake_session_repository.dart';

final _t = DateTime.utc(2025);

Exercise _exercise(String id, {int sets = 1}) => Exercise(
  id: id,
  exerciseGroupId: 'g-$id',
  position: 0,
  name: 'Ex $id',
  measurementType: const MeasurementType.repBased(),
  metadata: const ExerciseMetadata(),
  sets: [
    for (var i = 0; i < sets; i++)
      WorkoutSet(
        id: 'ws-$id-$i',
        exerciseId: id,
        position: i,
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 100,
          repTarget: RepTarget.fixed(reps: 5),
        ),
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
  ],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

WorkoutDay _singleDay({int sets = 1}) => WorkoutDay(
  id: 'wd-1',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g-real',
      workoutDayId: 'wd-1',
      position: 0,
      kind: const ExerciseGroupKind.single(),
      exercises: [_exercise('planned-real', sets: sets)],
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    ),
  ],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

WorkoutDay _supersetDay() => WorkoutDay(
  id: 'wd-1',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g-ss',
      workoutDayId: 'wd-1',
      position: 0,
      kind: const ExerciseGroupKind.superset(),
      exercises: [_exercise('a', sets: 2), _exercise('b', sets: 2)],
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    ),
  ],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

({FakeSessionRepository repo, SessionFlowEngine engine}) _setup() {
  final repo = FakeSessionRepository(clock: Clock.fixed(_t));
  return (repo: repo, engine: SessionFlowEngine(repository: repo));
}

void main() {
  group('SessionFlowEngine.resumeExercise', () {
    test('reverts a true-skip (0 sets) to unfinished, loggable from set 1, '
        'snapshot unchanged', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_singleDay(sets: 3));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final seId = started.sessionExercises.single.id;
      final hashBefore = started.snapshot.sha256Hash;
      await s.repo.skipExercise(seId);

      final state = await s.engine.resumeExercise(sessionExerciseId: seId);

      final resumed = state.session.sessionExercises.single;
      expect(resumed.state, isA<UnfinishedState>());
      expect(resumed.executedSets, isEmpty);
      expect(state.session.snapshot.sha256Hash, hashBefore);
      // Loggable from its first set.
      final target = state.openTargets.firstWhere(
        (t) => t.sessionExerciseId == seId,
      );
      expect(target.plannedSetIndex, 0);
    });

    test('reverts an ended-early (2/4) exercise, retains its 2 sets, loggable '
        'from set 3', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_singleDay(sets: 4));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final seId = started.sessionExercises.single.id;
      for (var i = 0; i < 2; i++) {
        await s.engine.completeSet(
          sessionExerciseId: seId,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
      }
      await s.engine.skipExercise(sessionExerciseId: seId);

      final state = await s.engine.resumeExercise(sessionExerciseId: seId);

      final resumed = state.session.sessionExercises.single;
      expect(resumed.state, isA<UnfinishedState>());
      expect(resumed.executedSets, hasLength(2));
      final target = state.openTargets.firstWhere(
        (t) => t.sessionExerciseId == seId,
      );
      expect(target.plannedSetIndex, 2);
    });

    test('resuming a non-skipped (unfinished) exercise throws OrderingError '
        'and leaves state unchanged', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_singleDay(sets: 3));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final seId = started.sessionExercises.single.id;

      await expectLater(
        s.engine.resumeExercise(sessionExerciseId: seId),
        throwsA(isA<OrderingError>()),
      );
      final after = await s.repo.getSession(started.id);
      expect(after!.sessionExercises.single.state, isA<UnfinishedState>());
    });

    test('resuming a completed exercise throws OrderingError', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_singleDay(sets: 1));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final seId = started.sessionExercises.single.id;
      await s.engine.completeSet(
        sessionExerciseId: seId,
        actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
      );

      await expectLater(
        s.engine.resumeExercise(sessionExerciseId: seId),
        throwsA(isA<OrderingError>()),
      );
    });

    test('resuming a skipped superset member keeps its supersetTag', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_supersetDay());
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final member = started.sessionExercises.first;
      final tag = member.supersetTag;
      expect(tag, isNotNull);
      await s.repo.skipExercise(member.id);

      final state = await s.engine.resumeExercise(
        sessionExerciseId: member.id,
      );

      final resumed = state.session.sessionExercises.firstWhere(
        (e) => e.id == member.id,
      );
      expect(resumed.state, isA<UnfinishedState>());
      expect(resumed.supersetTag, tag);
    });
  });
}
