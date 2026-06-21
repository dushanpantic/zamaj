import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

import '../../support/fake_session_repository.dart';

final _t = DateTime.utc(2025);
const _libA = '11111111-1111-4111-8111-111111111111';
const _libB = '22222222-2222-4222-8222-222222222222';

WorkoutSet _set(String exId, int i) => WorkoutSet(
  id: 'ws-$exId-$i',
  exerciseId: exId,
  position: i,
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 100,
    repTarget: RepTarget.fixed(reps: 5),
  ),
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

Exercise _exercise(String id, {int sets = 3, String? libraryExerciseId}) =>
    Exercise(
      id: id,
      exerciseGroupId: 'g-$id',
      position: 0,
      name: 'Ex $id',
      measurementType: const MeasurementType.repBased(),
      metadata: const ExerciseMetadata(),
      libraryExerciseId: libraryExerciseId,
      sets: [for (var i = 0; i < sets; i++) _set(id, i)],
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    );

/// A day with one single-exercise group per spec in [specs].
WorkoutDay _day(List<Exercise> exercises) => WorkoutDay(
  id: 'wd-1',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    for (var i = 0; i < exercises.length; i++)
      ExerciseGroup(
        id: 'g-$i',
        workoutDayId: 'wd-1',
        position: i,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercises[i]],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
  ],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

AddedExercisePlan _plan({
  String? libraryExerciseId,
  String name = 'Replacement',
}) => AddedExercisePlan(
  name: name,
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 60,
    repTarget: RepTarget.fixed(reps: 12),
  ),
  setCount: 2,
  libraryExerciseId: libraryExerciseId,
);

({FakeSessionRepository repo, SessionFlowEngine engine}) _setup() {
  final repo = FakeSessionRepository(clock: Clock.fixed(_t));
  return (repo: repo, engine: SessionFlowEngine(repository: repo));
}

void main() {
  group('SessionFlowEngine.replaceExercise (composed terminate + add)', () {
    test('replacing an exercise with no logged sets skips the original and '
        'appends a loggable replacement; snapshot hash unchanged', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_day([_exercise('a', libraryExerciseId: _libA)]));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final hashBefore = started.snapshot.sha256Hash;
      final originalId = started.sessionExercises.single.id;

      final state = await s.engine.replaceExercise(
        sessionExerciseId: originalId,
        plan: _plan(name: 'Goblet Squat'),
      );

      final original = state.session.sessionExercises.firstWhere(
        (e) => e.id == originalId,
      );
      expect(original.state, isA<SkippedState>());
      expect(original.executedSets, isEmpty);

      expect(state.session.sessionExercises, hasLength(2));
      final added = state.session.sessionExercises.last;
      expect(added.addedPlan?.name, 'Goblet Squat');
      expect(added.state, isA<UnfinishedState>());
      expect(
        state.openTargets.map((t) => t.sessionExerciseId),
        contains(added.id),
      );
      expect(
        state.openTargets.map((t) => t.sessionExerciseId),
        isNot(contains(originalId)),
      );
      expect(state.session.snapshot.sha256Hash, hashBefore);
    });

    test('replacing an exercise that had some logged sets terminates the '
        'original (partial outcome) but keeps its logged sets', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_day([_exercise('a')]));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final originalId = started.sessionExercises.single.id;
      await s.repo.completeSet(
        sessionExerciseId: originalId,
        actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
      );

      final state = await s.engine.replaceExercise(
        sessionExerciseId: originalId,
        plan: _plan(),
      );

      final original = state.session.sessionExercises.firstWhere(
        (e) => e.id == originalId,
      );
      expect(original.state, isA<SkippedState>());
      expect(original.executedSets, hasLength(1));
      // The derived outcome of a terminated exercise with logged sets is partial.
      expect(
        ExerciseOutcomes.of(
          state: original.state,
          executedSetCount: original.executedSets.length,
          plannedSetCount: 3,
        ),
        ExerciseOutcome.partial,
      );
    });

    test(
      'rejects a replacement duplicating another exercise already in the '
      'session; the original is left unchanged and nothing is written',
      () async {
        final s = _setup();
        s.repo.seedWorkoutDay(
          _day([
            _exercise('a', libraryExerciseId: _libA),
            _exercise('b', libraryExerciseId: _libB),
          ]),
        );
        final started = await s.repo.startSession(workoutDayId: 'wd-1');
        final aId = started.sessionExercises[0].id;
        final countBefore = started.sessionExercises.length;

        // Replacing A with B's movement collides with the still-present B.
        await expectLater(
          s.engine.replaceExercise(
            sessionExerciseId: aId,
            plan: _plan(libraryExerciseId: _libB),
          ),
          throwsA(isA<ValidationError>()),
        );

        final after = await s.repo.getSession(started.id);
        expect(after!.sessionExercises.length, countBefore);
        expect(
          after.sessionExercises.firstWhere((e) => e.id == aId).state,
          isA<UnfinishedState>(),
        );
      },
    );

    test('replacing an exercise with its own movement is allowed (the original '
        'is excluded from its own dedup block-set)', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_day([_exercise('a', libraryExerciseId: _libA)]));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final aId = started.sessionExercises.single.id;

      final state = await s.engine.replaceExercise(
        sessionExerciseId: aId,
        plan: _plan(libraryExerciseId: _libA, name: 'Fresh A'),
      );

      expect(
        state.session.sessionExercises.firstWhere((e) => e.id == aId).state,
        isA<SkippedState>(),
      );
      expect(state.session.sessionExercises.last.addedPlan?.name, 'Fresh A');
    });

    test('throws OrderingError when the target is not unfinished', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_day([_exercise('a')]));
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final aId = started.sessionExercises.single.id;
      await s.repo.skipExercise(aId);

      await expectLater(
        s.engine.replaceExercise(sessionExerciseId: aId, plan: _plan()),
        throwsA(isA<OrderingError>()),
      );
    });
  });
}
