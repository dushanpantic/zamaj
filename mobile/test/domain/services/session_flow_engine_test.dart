import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/cursor.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  ({FakeSessionRepository repo, SessionFlowEngine engine}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo, clock: fakeClock);
    return (repo: repo, engine: engine);
  }

  group('startSession edge cases', () {
    test('empty workout day produces a session with no exercises and '
        'a completed cursor', () async {
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
      expect(result.cursor, equals(const Cursor.completed()));
      expect(result.suggestedValues, isNull);
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
        started.cursor,
        equals(
          Cursor.active(
            sessionExerciseId: started.session.sessionExercises.single.id,
            setIndex: 0,
          ),
        ),
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
      expect(completed.cursor, equals(const Cursor.completed()));
      expect(s.engine.isSessionComplete(completed.session), isTrue);
    });
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
            substituteName: 'sub',
            substituteMeasurementType: const MeasurementType.repBased(),
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
        started.cursor,
        equals(Cursor.active(sessionExerciseId: benchId, setIndex: 0)),
      );

      var state = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
      );
      expect(
        state.cursor,
        equals(Cursor.active(sessionExerciseId: benchId, setIndex: 1)),
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
        state.cursor,
        equals(Cursor.active(sessionExerciseId: ohpId, setIndex: 0)),
      );

      state = await s.engine.skipExercise(sessionExerciseId: ohpId);
      expect(
        _findExercise(state.session.sessionExercises, ohpId).state,
        equals(const ExerciseState.skipped()),
      );
      expect(
        state.cursor,
        equals(Cursor.active(sessionExerciseId: plankId, setIndex: 0)),
      );

      state = await s.engine.replaceExercise(
        sessionExerciseId: plankId,
        substituteName: 'Wall Sit',
        substituteMeasurementType: const MeasurementType.timeBased(),
      );
      final replacedExercise = _findExercise(
        state.session.sessionExercises,
        plankId,
      );
      expect(replacedExercise.state, isA<ReplacedState>());
      expect(
        (replacedExercise.state as ReplacedState).substitute.name,
        equals('Wall Sit'),
      );
      expect(
        state.cursor,
        equals(Cursor.active(sessionExerciseId: plankId, setIndex: 0)),
      );

      state = await s.engine.completeSet(
        sessionExerciseId: plankId,
        actualValues: const ActualSetValues.timeBased(durationSeconds: 45),
      );
      state = await s.engine.completeSet(
        sessionExerciseId: plankId,
        actualValues: const ActualSetValues.timeBased(durationSeconds: 40),
      );

      expect(state.cursor, equals(const Cursor.completed()));
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
      expect(_findExercise(finalExercises, plankId).executedSets, hasLength(2));
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
        ? const PlannedSetValues.repBased(weightKg: 50, reps: 5)
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
