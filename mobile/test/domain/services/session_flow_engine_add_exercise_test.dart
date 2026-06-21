import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

import '../../support/fake_session_repository.dart';

final _t = DateTime.utc(2025);
const _libraryId = '11111111-1111-4111-8111-111111111111';

Exercise _exercise(String id, {int sets = 1, String? libraryExerciseId}) =>
    Exercise(
      id: id,
      exerciseGroupId: 'g-$id',
      position: 0,
      name: 'Ex $id',
      measurementType: const MeasurementType.repBased(),
      metadata: const ExerciseMetadata(),
      libraryExerciseId: libraryExerciseId,
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

WorkoutDay _day({int sets = 1, String? libraryExerciseId}) => WorkoutDay(
  id: 'wd-1',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g-real',
      workoutDayId: 'wd-1',
      position: 0,
      kind: const ExerciseGroupKind.single(),
      exercises: [
        _exercise(
          'planned-real',
          sets: sets,
          libraryExerciseId: libraryExerciseId,
        ),
      ],
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    ),
  ],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

AddedExercisePlan _plan({String? libraryExerciseId, String name = 'Added'}) =>
    AddedExercisePlan(
      name: name,
      measurementType: const MeasurementType.repBased(),
      plannedValues: PlannedSetValues.repBased(
        weightKg: 60,
        repTarget: RepTarget.fixed(reps: 12),
      ),
      setCount: 3,
      libraryExerciseId: libraryExerciseId,
    );

({FakeSessionRepository repo, SessionFlowEngine engine}) _setup() {
  final repo = FakeSessionRepository(clock: Clock.fixed(_t));
  return (repo: repo, engine: SessionFlowEngine(repository: repo));
}

void main() {
  group('SessionFlowEngine.addExercise', () {
    test('appends a library-linked exercise carrying its inline plan, '
        'unfinished, snapshot hash unchanged', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_day());
      final started = await s.repo.startSession(workoutDayId: 'wd-1');
      final hashBefore = started.snapshot.sha256Hash;

      final state = await s.engine.addExercise(
        sessionId: started.id,
        plan: _plan(libraryExerciseId: _libraryId, name: 'Added Curl'),
      );

      final exercises = state.session.sessionExercises;
      expect(exercises, hasLength(2));
      final added = exercises.last;
      expect(added.state, isA<UnfinishedState>());
      expect(added.addedPlan?.name, 'Added Curl');
      expect(added.addedPlan?.libraryExerciseId, _libraryId);
      // Appended after the seeded exercise.
      expect(added.position, greaterThan(exercises.first.position));
      // The frozen snapshot is untouched.
      expect(state.session.snapshot.sha256Hash, hashBefore);
      // The added exercise is loggable from its first set.
      expect(
        state.openTargets.map((t) => t.sessionExerciseId),
        contains(added.id),
      );
    });

    test(
      'appends a one-off (unlinked) exercise, snapshot hash unchanged',
      () async {
        final s = _setup();
        s.repo.seedWorkoutDay(_day());
        final started = await s.repo.startSession(workoutDayId: 'wd-1');
        final hashBefore = started.snapshot.sha256Hash;

        final state = await s.engine.addExercise(
          sessionId: started.id,
          plan: _plan(name: 'Cable Thing'),
        );

        expect(state.session.sessionExercises, hasLength(2));
        expect(
          state.session.sessionExercises.last.addedPlan?.libraryExerciseId,
          isNull,
        );
        // The frozen snapshot is untouched on the one-off path too.
        expect(state.session.snapshot.sha256Hash, hashBefore);
      },
    );

    test('two one-off adds with the same name are both accepted (never '
        'deduped)', () async {
      final s = _setup();
      s.repo.seedWorkoutDay(_day());
      final started = await s.repo.startSession(workoutDayId: 'wd-1');

      await s.engine.addExercise(
        sessionId: started.id,
        plan: _plan(name: 'Cable Thing'),
      );
      final state = await s.engine.addExercise(
        sessionId: started.id,
        plan: _plan(name: 'Cable Thing'),
      );

      expect(state.session.sessionExercises, hasLength(3));
    });

    group('rejects a duplicate library movement in any state', () {
      Future<void> expectRejected(
        Future<void> Function(FakeSessionRepository repo, String seId)
        transition,
      ) async {
        final s = _setup();
        s.repo.seedWorkoutDay(_day(libraryExerciseId: _libraryId));
        final started = await s.repo.startSession(workoutDayId: 'wd-1');
        final seId = started.sessionExercises.single.id;
        await transition(s.repo, seId);
        final countBefore = (await s.repo.getSession(
          started.id,
        ))!.sessionExercises.length;

        await expectLater(
          s.engine.addExercise(
            sessionId: started.id,
            plan: _plan(libraryExerciseId: _libraryId),
          ),
          throwsA(isA<ValidationError>()),
        );

        // Nothing was written.
        final after = await s.repo.getSession(started.id);
        expect(after!.sessionExercises.length, countBefore);
      }

      test('unfinished', () async {
        await expectRejected((repo, seId) async {});
      });

      test('completed', () async {
        await expectRejected((repo, seId) async {
          await repo.completeSet(
            sessionExerciseId: seId,
            actualValues: const ActualSetValues.repBased(
              weightKg: 100,
              reps: 5,
            ),
          );
        });
      });

      test('skipped', () async {
        await expectRejected((repo, seId) async {
          await repo.skipExercise(seId);
        });
      });
    });

    test(
      'excludeSessionExerciseId drops one exercise from the dedup block-set',
      () async {
        final s = _setup();
        s.repo.seedWorkoutDay(_day(libraryExerciseId: _libraryId));
        final started = await s.repo.startSession(workoutDayId: 'wd-1');
        final originalId = started.sessionExercises.single.id;

        // Re-adding the same movement is allowed when the only holder of that
        // movement is the excluded exercise (the replace path).
        final state = await s.engine.addExercise(
          sessionId: started.id,
          plan: _plan(libraryExerciseId: _libraryId, name: 'Replacement'),
          excludeSessionExerciseId: originalId,
        );

        expect(state.session.sessionExercises, hasLength(2));
        expect(
          state.session.sessionExercises.last.addedPlan?.name,
          'Replacement',
        );
      },
    );
  });
}
