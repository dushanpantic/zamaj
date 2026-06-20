import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/exercise_outcome.dart';
import 'package:zamaj/modules/domain/services/log_target.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  ({FakeSessionRepository repo, SessionFlowEngine engine}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo);
    return (repo: repo, engine: engine);
  }

  group('startSession edge cases', () {
    test('empty workout day produces a session with no exercises and '
        'no open targets', () async {
      final s = setup();
      final workoutDay = WorkoutDay(
        id: 'wd-empty',
        programId: 'prog-1',
        name: 'Empty Day',
        exerciseGroups: const [],
        createdAt: fixedTime,
        updatedAt: fixedTime,
        schemaVersion: 1,
      );
      s.repo.seedWorkoutDay(workoutDay);

      final result = await s.engine.startSession(workoutDayId: workoutDay.id);

      expect(result.session.sessionExercises, isEmpty);
      expect(result.openTargets, isEmpty);
      expect(result.isComplete, isTrue);
      expect(s.engine.isSessionComplete(result.session), isTrue);
    });

    test('single exercise with one planned set transitions to completed '
        'after the only set is recorded', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-1',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Bench Press',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);

      final started = await s.engine.startSession(workoutDayId: workoutDay.id);

      expect(started.session.sessionExercises, hasLength(1));
      expect(
        started.session.sessionExercises.single.state,
        isA<UnfinishedState>(),
      );
      expect(
        started.openTargets,
        equals([
          LogTarget(
            sessionExerciseId: started.session.sessionExercises.single.id,
            plannedSetIndex: 0,
          ),
        ]),
      );

      final completed = await s.engine.completeSet(
        sessionExerciseId: started.session.sessionExercises.single.id,
        actualValues: const ActualSetValues.repBased(weightKg: 60, reps: 5),
      );

      final updatedExercise = completed.session.sessionExercises.single;
      expect(updatedExercise.state, equals(const ExerciseState.completed()));
      expect(updatedExercise.executedSets, hasLength(1));
      expect(
        updatedExercise.executedSets.single.actualValues,
        equals(const ActualSetValues.repBased(weightKg: 60, reps: 5)),
      );
      expect(completed.openTargets, isEmpty);
      expect(completed.isComplete, isTrue);
      expect(s.engine.isSessionComplete(completed.session), isTrue);
    });

    test(
      'forwards isDeload to the repository; defaults to a normal start',
      () async {
        final s = setup();
        final workoutDay = _buildWorkoutDay(
          id: 'wd-deload',
          exerciseSpecs: [
            _ExerciseSpec(
              name: 'Squat',
              measurementType: const MeasurementType.repBased(),
              setCount: 4,
            ),
          ],
        );
        s.repo.seedWorkoutDay(workoutDay);

        final deload = await s.engine.startSession(
          workoutDayId: workoutDay.id,
          isDeload: true,
        );
        expect(deload.session.isDeload, isTrue);

        final normal = await s.engine.startSession(workoutDayId: workoutDay.id);
        expect(normal.session.isDeload, isFalse);
      },
    );
  });

  group('NotFoundError for missing entities', () {
    test('startSession with unknown workoutDayId throws NotFoundError', () {
      final s = setup();
      expect(
        () => s.engine.startSession(workoutDayId: 'missing-wd'),
        throwsA(
          isA<NotFoundError>()
              .having((e) => e.entityType, 'entityType', 'WorkoutDay')
              .having((e) => e.id, 'id', 'missing-wd'),
        ),
      );
    });

    test('resumeSession with unknown sessionId throws NotFoundError', () {
      final s = setup();
      expect(
        () => s.engine.resumeSession(sessionId: 'missing-session'),
        throwsA(
          isA<NotFoundError>()
              .having((e) => e.entityType, 'entityType', 'Session')
              .having((e) => e.id, 'id', 'missing-session'),
        ),
      );
    });

    test('endSession with unknown sessionId throws NotFoundError', () {
      final s = setup();
      expect(
        () => s.engine.endSession(sessionId: 'missing-session'),
        throwsA(isA<NotFoundError>()),
      );
    });

    test(
      'skipExercise with unknown sessionExerciseId throws NotFoundError',
      () {
        final s = setup();
        expect(
          () => s.engine.skipExercise(sessionExerciseId: 'missing-ex'),
          throwsA(
            isA<NotFoundError>().having(
              (e) => e.entityType,
              'entityType',
              'SessionExercise',
            ),
          ),
        );
      },
    );

    test(
      'replaceExercise with unknown sessionExerciseId throws NotFoundError',
      () {
        final s = setup();
        expect(
          () => s.engine.replaceExercise(
            sessionExerciseId: 'missing-ex',
            plan: AddedExercisePlan(
              name: 'sub',
              measurementType: const MeasurementType.repBased(),
              plannedValues: PlannedSetValues.repBased(
                weightKg: 20,
                repTarget: RepTarget.fixed(reps: 8),
              ),
              setCount: 3,
            ),
          ),
          throwsA(isA<NotFoundError>()),
        );
      },
    );

    test('completeSet with unknown sessionExerciseId throws NotFoundError', () {
      final s = setup();
      expect(
        () => s.engine.completeSet(
          sessionExerciseId: 'missing-ex',
          actualValues: const ActualSetValues.repBased(weightKg: 0, reps: 1),
        ),
        throwsA(isA<NotFoundError>()),
      );
    });

    test(
      'updateExecutedSet with unknown executedSetId throws NotFoundError',
      () {
        final s = setup();
        expect(
          () => s.engine.updateExecutedSet(
            executedSetId: 'missing-set',
            actualValues: const ActualSetValues.repBased(weightKg: 0, reps: 1),
          ),
          throwsA(
            isA<NotFoundError>().having(
              (e) => e.entityType,
              'entityType',
              'ExecutedSet',
            ),
          ),
        );
      },
    );

    test('addSessionNote with unknown sessionId throws NotFoundError', () {
      final s = setup();
      expect(
        () =>
            s.engine.addSessionNote(sessionId: 'missing-session', body: 'note'),
        throwsA(isA<NotFoundError>()),
      );
    });

    test('addExtraWork with unknown sessionId throws NotFoundError', () {
      final s = setup();
      expect(
        () =>
            s.engine.addExtraWork(sessionId: 'missing-session', body: 'extra'),
        throwsA(isA<NotFoundError>()),
      );
    });

    test('reorderUnfinished with unknown sessionId throws NotFoundError', () {
      final s = setup();
      expect(
        () => s.engine.reorderUnfinished(
          sessionId: 'missing-session',
          orderedUnfinishedIds: const [],
        ),
        throwsA(isA<NotFoundError>()),
      );
    });

    test('createSuperset with unknown sessionId throws NotFoundError', () {
      final s = setup();
      expect(
        () => s.engine.createSuperset(
          sessionId: 'missing-session',
          sessionExerciseIds: const ['a', 'b'],
        ),
        throwsA(isA<NotFoundError>()),
      );
    });

    test('removeSuperset with unknown sessionId throws NotFoundError', () {
      final s = setup();
      expect(
        () => s.engine.removeSuperset(
          sessionId: 'missing-session',
          sessionExerciseIds: const ['a', 'b'],
        ),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  group('addSessionNote length validation', () {
    test('note body exceeding 5000 characters is rejected', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-1',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Squat',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);

      final tooLong = 'a' * 5001;

      expect(
        () => s.engine.addSessionNote(
          sessionId: started.session.id,
          body: tooLong,
        ),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'session_note_body_max_length',
          ),
        ),
      );

      final reloaded = await s.repo.getSession(started.session.id);
      expect(reloaded!.notes, isEmpty);
    });

    test('note body of exactly 5000 characters is accepted', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-1',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Squat',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);

      final boundary = 'a' * 5000;

      final result = await s.engine.addSessionNote(
        sessionId: started.session.id,
        body: boundary,
      );

      expect(result.session.notes, hasLength(1));
      expect(result.session.notes.single.body, equals(boundary));
    });
  });

  group('createSuperset minimum size', () {
    test('createSuperset with 0 exercise ids throws ValidationError', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-1',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'A',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
          _ExerciseSpec(
            name: 'B',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);

      expect(
        () => s.engine.createSuperset(
          sessionId: started.session.id,
          sessionExerciseIds: const [],
        ),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'superset_min_exercises',
          ),
        ),
      );
    });

    test('createSuperset with 1 exercise id throws ValidationError', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-1',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'A',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
          _ExerciseSpec(
            name: 'B',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);
      final firstId = started.session.sessionExercises.first.id;

      expect(
        () => s.engine.createSuperset(
          sessionId: started.session.id,
          sessionExerciseIds: [firstId],
        ),
        throwsA(
          isA<ValidationError>().having(
            (e) => e.invariant,
            'invariant',
            'superset_min_exercises',
          ),
        ),
      );
    });
  });

  group('three-exercise session walkthrough', () {
    test('complete, skip, replace — session reaches completion', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-three',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Bench Press',
            measurementType: const MeasurementType.repBased(),
            setCount: 2,
          ),
          _ExerciseSpec(
            name: 'Overhead Press',
            measurementType: const MeasurementType.repBased(),
            setCount: 3,
          ),
          _ExerciseSpec(
            name: 'Plank',
            measurementType: const MeasurementType.timeBased(),
            setCount: 2,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);

      final started = await s.engine.startSession(workoutDayId: workoutDay.id);
      final benchId = started.session.sessionExercises[0].id;
      final ohpId = started.session.sessionExercises[1].id;
      final plankId = started.session.sessionExercises[2].id;

      expect(
        started.openTargets.first,
        equals(LogTarget(sessionExerciseId: benchId, plannedSetIndex: 0)),
      );
      expect(
        started.openTargets.map((t) => t.sessionExerciseId).toList(),
        equals([benchId, ohpId, plankId]),
      );

      var state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      expect(
        state.openTargets.first,
        equals(LogTarget(sessionExerciseId: benchId, plannedSetIndex: 1)),
      );

      state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 4),
      );
      expect(
        _findExercise(state.session.sessionExercises, benchId).state,
        equals(const ExerciseState.completed()),
      );
      expect(
        state.openTargets.first,
        equals(LogTarget(sessionExerciseId: ohpId, plannedSetIndex: 0)),
      );

      state = await s.engine.skipExercise(sessionExerciseId: ohpId);
      expect(
        _findExercise(state.session.sessionExercises, ohpId).state,
        equals(const ExerciseState.skipped()),
      );
      expect(
        state.openTargets.map((t) => t.sessionExerciseId).toList(),
        equals([plankId]),
      );

      // Composed replace: the original (plank) is terminated (skipped, no sets)
      // and a fresh added exercise takes its place — no Replaced state.
      state = await s.engine.replaceExercise(
        sessionExerciseId: plankId,
        plan: AddedExercisePlan(
          name: 'Wall Sit',
          measurementType: const MeasurementType.timeBased(),
          plannedValues: const PlannedSetValues.timeBased(durationSeconds: 45),
          setCount: 2,
        ),
      );
      expect(
        _findExercise(state.session.sessionExercises, plankId).state,
        equals(const ExerciseState.skipped()),
      );
      final wallSit = state.session.sessionExercises.last;
      expect(wallSit.addedPlan?.name, equals('Wall Sit'));
      expect(wallSit.state, isA<UnfinishedState>());
      expect(
        state.openTargets,
        equals([LogTarget(sessionExerciseId: wallSit.id, plannedSetIndex: 0)]),
      );

      state = await s.engine.completeSet(
        sessionExerciseId: wallSit.id,
        actualValues: const ActualSetValues.timeBased(durationSeconds: 45),
      );
      state = await s.engine.completeSet(
        sessionExerciseId: wallSit.id,
        actualValues: const ActualSetValues.timeBased(durationSeconds: 40),
      );

      expect(state.openTargets, isEmpty);
      expect(state.isComplete, isTrue);
      expect(s.engine.isSessionComplete(state.session), isTrue);

      final finalExercises = state.session.sessionExercises;
      expect(
        _findExercise(finalExercises, benchId).state,
        equals(const ExerciseState.completed()),
      );
      expect(
        _findExercise(finalExercises, ohpId).state,
        equals(const ExerciseState.skipped()),
      );
      expect(
        _findExercise(finalExercises, plankId).state,
        equals(const ExerciseState.skipped()),
      );
      expect(
        _findExercise(finalExercises, wallSit.id).executedSets,
        hasLength(2),
      );
    });
  });

  group('per-exercise completeSet semantics', () {
    test('cross-exercise out-of-order: alternating logs append correctly to '
        'each exercise', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-alt',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            setCount: 3,
          ),
          _ExerciseSpec(
            name: 'Lat Pulldown',
            measurementType: const MeasurementType.repBased(),
            setCount: 3,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);
      final benchId = started.session.sessionExercises[0].id;
      final latId = started.session.sessionExercises[1].id;

      // bench, lat, bench, bench, lat, lat — the motivating scenario.
      var state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      state = await s.engine.completeSet(
        sessionExerciseId: latId,
        actualValues: const ActualSetValues.repBased(weightKg: 50, reps: 10),
      );
      state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 4),
      );
      state = await s.engine.completeSet(
        sessionExerciseId: latId,
        actualValues: const ActualSetValues.repBased(weightKg: 50, reps: 10),
      );
      state = await s.engine.completeSet(
        sessionExerciseId: latId,
        actualValues: const ActualSetValues.repBased(weightKg: 50, reps: 8),
      );

      final bench = _findExercise(state.session.sessionExercises, benchId);
      final lat = _findExercise(state.session.sessionExercises, latId);
      expect(bench.executedSets, hasLength(3));
      expect(lat.executedSets, hasLength(3));
      // ExecutedSet.position is dense chronological per exercise.
      expect(
        bench.executedSets.map((e) => e.position).toList(),
        equals([0, 1, 2]),
      );
      expect(
        lat.executedSets.map((e) => e.position).toList(),
        equals([0, 1, 2]),
      );
      expect(bench.state, equals(const ExerciseState.completed()));
      expect(lat.state, equals(const ExerciseState.completed()));
      expect(state.isComplete, isTrue);
    });

    test('completeSet on a completed exercise appends an extra set without '
        'changing state', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-extra',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
          _ExerciseSpec(
            name: 'Row',
            measurementType: const MeasurementType.repBased(),
            setCount: 1,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);
      final benchId = started.session.sessionExercises[0].id;

      var state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      expect(
        _findExercise(state.session.sessionExercises, benchId).state,
        equals(const ExerciseState.completed()),
      );

      state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 85, reps: 3),
      );
      final bench = _findExercise(state.session.sessionExercises, benchId);
      expect(bench.state, equals(const ExerciseState.completed()));
      expect(bench.executedSets, hasLength(2));
      expect(
        bench.executedSets.last.actualValues,
        equals(const ActualSetValues.repBased(weightKg: 85, reps: 3)),
      );
      // openTargets reflects only loggable (non-terminal) exercises; the
      // completed-with-extras case is a UI affordance, not a default target.
      expect(
        state.openTargets.map((t) => t.sessionExerciseId),
        isNot(contains(benchId)),
      );
    });

    test('completeSet on a skipped exercise throws OrderingError', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-skip',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            setCount: 2,
          ),
          _ExerciseSpec(
            name: 'Row',
            measurementType: const MeasurementType.repBased(),
            setCount: 2,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);
      final benchId = started.session.sessionExercises[0].id;

      await s.engine.skipExercise(sessionExerciseId: benchId);

      expect(
        () => s.engine.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
        ),
        throwsA(
          isA<OrderingError>()
              .having((e) => e.sessionExerciseId, 'sessionExerciseId', benchId)
              .having((e) => e.currentState, 'currentState', 'skipped'),
        ),
      );
    });
  });

  group('ending an exercise early never records it as completed', () {
    // Ending an exercise mid-quota routes through skipExercise (there is no
    // markExerciseDone). The stored discriminator is `skipped`, but the read
    // surfaces derive `partial` from the logged-set count, never `completed`.
    test(
      'ending an exercise with 2 of 4 sets logged lands on a non-completed '
      'record whose derived outcome is partial, and the session completes',
      () async {
        final s = setup();
        final workoutDay = _buildWorkoutDay(
          id: 'wd-end-early',
          exerciseSpecs: [
            _ExerciseSpec(
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              setCount: 4,
            ),
          ],
        );
        s.repo.seedWorkoutDay(workoutDay);
        final started = await s.engine.startSession(
          workoutDayId: workoutDay.id,
        );
        final benchId = started.session.sessionExercises[0].id;

        for (var i = 0; i < 2; i++) {
          await s.engine.completeSet(
            sessionExerciseId: benchId,
            actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
          );
        }

        final ended = await s.engine.skipExercise(sessionExerciseId: benchId);
        final exercise = _findExercise(ended.session.sessionExercises, benchId);
        final plannedSetCount = started
            .session
            .snapshot
            .workoutDay
            .exerciseGroups
            .expand((g) => g.exercises)
            .firstWhere((e) => e.id == exercise.plannedExerciseIdInSnapshot)
            .sets
            .length;

        // Pins the stored discriminator: ending short lands on `skipped`,
        // never `completed`.
        expect(exercise.state, equals(const ExerciseState.skipped()));
        expect(exercise.executedSets, hasLength(2));
        expect(
          ExerciseOutcomes.of(
            state: exercise.state,
            executedSetCount: exercise.executedSets.length,
            plannedSetCount: plannedSetCount,
          ),
          equals(ExerciseOutcome.partial),
        );
        expect(ended.isComplete, isTrue);
      },
    );
  });

  group('corrupt snapshot', () {
    test('computeOpenTargets throws NotFoundError when an unfinished exercise '
        'references a planned id absent from the snapshot', () async {
      final s = setup();
      final workoutDay = _buildWorkoutDay(
        id: 'wd-corrupt',
        exerciseSpecs: [
          _ExerciseSpec(
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            setCount: 2,
          ),
        ],
      );
      s.repo.seedWorkoutDay(workoutDay);
      final started = await s.engine.startSession(workoutDayId: workoutDay.id);

      // Re-point the unfinished exercise at a planned id that is not in the
      // immutable snapshot. There is no silent fallback — the projection must
      // surface this as NotFoundError.
      final corrupt = started.session.copyWith(
        sessionExercises: [
          for (final e in started.session.sessionExercises)
            e.copyWith(plannedExerciseIdInSnapshot: 'ghost'),
        ],
      );

      expect(
        () => s.engine.computeOpenTargets(corrupt),
        throwsA(isA<NotFoundError>().having((e) => e.id, 'id', 'ghost')),
      );
    });
  });
}

class _ExerciseSpec {
  _ExerciseSpec({
    required this.name,
    required this.measurementType,
    required this.setCount,
  });
  final String name;
  final MeasurementType measurementType;
  final int setCount;
}

WorkoutDay _buildWorkoutDay({
  required String id,
  required List<_ExerciseSpec> exerciseSpecs,
}) {
  final time = DateTime.utc(2024);
  final groups = <ExerciseGroup>[];

  for (var i = 0; i < exerciseSpecs.length; i++) {
    final spec = exerciseSpecs[i];
    final groupId = 'group-$id-$i';
    final exerciseId = 'exercise-$id-$i';

    final planned = spec.measurementType is RepBasedMeasurement
        ? PlannedSetValues.repBased(
            weightKg: 50,
            repTarget: RepTarget.fixed(reps: 5),
          )
        : const PlannedSetValues.timeBased(durationSeconds: 30);

    final sets = List.generate(spec.setCount, (j) {
      return WorkoutSet(
        id: 'set-$id-$i-$j',
        exerciseId: exerciseId,
        position: j,
        measurementType: spec.measurementType,
        plannedValues: planned,
        createdAt: time,
        updatedAt: time,
        schemaVersion: 1,
      );
    });

    final exercise = Exercise(
      id: exerciseId,
      exerciseGroupId: groupId,
      position: 0,
      name: spec.name,
      measurementType: spec.measurementType,
      metadata: ExerciseMetadata.empty,
      sets: sets,
      createdAt: time,
      updatedAt: time,
      schemaVersion: 1,
    );

    groups.add(
      ExerciseGroup(
        id: groupId,
        workoutDayId: id,
        position: i,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercise],
        createdAt: time,
        updatedAt: time,
        schemaVersion: 1,
      ),
    );
  }

  return WorkoutDay(
    id: id,
    programId: 'prog-$id',
    name: 'Day $id',
    exerciseGroups: groups,
    createdAt: time,
    updatedAt: time,
    schemaVersion: 1,
  );
}

SessionExercise _findExercise(List<SessionExercise> exercises, String id) {
  return exercises.firstWhere((e) => e.id == id);
}
