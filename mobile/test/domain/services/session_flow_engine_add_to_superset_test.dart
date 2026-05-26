// Validates engine method `addToSuperset` introduced for plan item P2.3:
// appending an unfinished, ungrouped exercise to an existing unfinished
// superset, atomically, without rotating the group's tag.

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
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
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';

import '../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  group('SessionFlowEngine.addToSuperset', () {
    test('appends an unfinished, ungrouped exercise to an existing '
        'unfinished superset, preserves the tag, and lands the new member '
        'immediately after the existing group', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final engine = SessionFlowEngine(repository: repo);
      final workoutDay = _buildWorkoutDay(id: 'wd-1', exerciseCount: 4);
      repo.seedWorkoutDay(workoutDay);
      final started = await engine.startSession(workoutDayId: 'wd-1');
      final ids = started.session.sessionExercises.map((e) => e.id).toList();

      // Group ids[0] and ids[1] into a superset.
      final afterCreate = await engine.createSuperset(
        sessionId: started.session.id,
        sessionExerciseIds: [ids[0], ids[1]],
      );
      final tag = afterCreate.session.sessionExercises
          .firstWhere((e) => e.id == ids[0])
          .supersetTag!;

      // Append ids[3] to the existing group.
      final result = await engine.addToSuperset(
        sessionId: started.session.id,
        supersetTag: tag,
        sessionExerciseId: ids[3],
      );

      // Tag is preserved across appends.
      final taggedTags = result.session.sessionExercises
          .where((e) => e.supersetTag != null)
          .map((e) => e.supersetTag)
          .toSet();
      expect(taggedTags, equals({tag}));

      // The dragged exercise carries the tag and is still unfinished.
      final dragged = result.session.sessionExercises.firstWhere(
        (e) => e.id == ids[3],
      );
      expect(dragged.supersetTag, equals(tag));
      expect(dragged.state, isA<UnfinishedState>());

      // Members now form a contiguous run of length 3, dragged at the end.
      final sorted = List<SessionExercise>.of(result.session.sessionExercises)
        ..sort((a, b) => a.position.compareTo(b.position));
      final members = sorted.where((e) => e.supersetTag == tag).toList();
      expect(members.length, equals(3));
      for (var i = 1; i < members.length; i++) {
        expect(
          members[i].position,
          equals(members[i - 1].position + 1),
          reason: 'members must occupy consecutive positions',
        );
      }
      expect(members.last.id, equals(ids[3]));
    });

    test(
      'throws OrderingError when any existing member is not unfinished',
      () async {
        final repo = FakeSessionRepository(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo);
        final workoutDay = _buildWorkoutDay(id: 'wd-1', exerciseCount: 3);
        repo.seedWorkoutDay(workoutDay);
        final started = await engine.startSession(workoutDayId: 'wd-1');
        final ids = started.session.sessionExercises.map((e) => e.id).toList();
        final afterCreate = await engine.createSuperset(
          sessionId: started.session.id,
          sessionExerciseIds: [ids[0], ids[1]],
        );
        final tag = afterCreate.session.sessionExercises
            .firstWhere((e) => e.id == ids[0])
            .supersetTag!;

        // Skip one of the existing group members so the group is mixed-state.
        await engine.skipExercise(sessionExerciseId: ids[0]);

        expect(
          () => engine.addToSuperset(
            sessionId: started.session.id,
            supersetTag: tag,
            sessionExerciseId: ids[2],
          ),
          throwsA(isA<OrderingError>()),
        );
      },
    );

    test(
      'throws ValidationError when the dragged is already in a superset',
      () async {
        final repo = FakeSessionRepository(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo);
        final workoutDay = _buildWorkoutDay(id: 'wd-1', exerciseCount: 4);
        repo.seedWorkoutDay(workoutDay);
        final started = await engine.startSession(workoutDayId: 'wd-1');
        final ids = started.session.sessionExercises.map((e) => e.id).toList();
        final afterFirst = await engine.createSuperset(
          sessionId: started.session.id,
          sessionExerciseIds: [ids[0], ids[1]],
        );
        final firstTag = afterFirst.session.sessionExercises
            .firstWhere((e) => e.id == ids[0])
            .supersetTag!;
        await engine.createSuperset(
          sessionId: started.session.id,
          sessionExerciseIds: [ids[2], ids[3]],
        );

        expect(
          () => engine.addToSuperset(
            sessionId: started.session.id,
            supersetTag: firstTag,
            sessionExerciseId: ids[2],
          ),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.invariant,
              'invariant',
              'append_to_superset_dragged_already_grouped',
            ),
          ),
        );
      },
    );

    test('throws OrderingError when the dragged is not unfinished', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final engine = SessionFlowEngine(repository: repo);
      final workoutDay = _buildWorkoutDay(id: 'wd-1', exerciseCount: 3);
      repo.seedWorkoutDay(workoutDay);
      final started = await engine.startSession(workoutDayId: 'wd-1');
      final ids = started.session.sessionExercises.map((e) => e.id).toList();
      final afterCreate = await engine.createSuperset(
        sessionId: started.session.id,
        sessionExerciseIds: [ids[0], ids[1]],
      );
      final tag = afterCreate.session.sessionExercises
          .firstWhere((e) => e.id == ids[0])
          .supersetTag!;
      await engine.skipExercise(sessionExerciseId: ids[2]);

      expect(
        () => engine.addToSuperset(
          sessionId: started.session.id,
          supersetTag: tag,
          sessionExerciseId: ids[2],
        ),
        throwsA(isA<OrderingError>()),
      );
    });

    test('throws NotFoundError when the superset tag does not exist', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final engine = SessionFlowEngine(repository: repo);
      final workoutDay = _buildWorkoutDay(id: 'wd-1', exerciseCount: 3);
      repo.seedWorkoutDay(workoutDay);
      final started = await engine.startSession(workoutDayId: 'wd-1');
      final ids = started.session.sessionExercises.map((e) => e.id).toList();

      expect(
        () => engine.addToSuperset(
          sessionId: started.session.id,
          supersetTag: 'tag-nonexistent',
          sessionExerciseId: ids[0],
        ),
        throwsA(isA<NotFoundError>()),
      );
    });
  });
}

WorkoutDay _buildWorkoutDay({required String id, required int exerciseCount}) {
  final time = DateTime.utc(2024);
  final groups = <ExerciseGroup>[];
  for (var i = 0; i < exerciseCount; i++) {
    final groupId = 'group-$id-$i';
    final exerciseId = 'exercise-$id-$i';
    final sets = [
      WorkoutSet(
        id: 'set-$id-$i-0',
        exerciseId: exerciseId,
        position: 0,
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 50,
          repTarget: RepTarget.fixed(reps: 5),
        ),
        createdAt: time,
        updatedAt: time,
        schemaVersion: 1,
      ),
    ];
    final exercise = Exercise(
      id: exerciseId,
      exerciseGroupId: groupId,
      position: 0,
      name: 'Exercise $i',
      measurementType: const MeasurementType.repBased(),
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
