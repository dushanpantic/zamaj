// Validates engine method `removeFromSuperset` (Slice 1 of the
// remove-exercise-from-superset feature): the exact inverse of `addToSuperset`.
// Extracting an unfinished member from a fully-unfinished superset clears its
// tag, repositions it immediately after the group's last remaining member, and
// keeps the remaining members one contiguous run — atomically. Refused for an
// ungrouped exercise, a not-unfinished target, any not-unfinished group member,
// and an ended session.

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
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';
import 'package:zamaj/modules/domain/services/session_state.dart';

import '../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  // Builds a started session with a 3-member superset (ids[1..3]) flanked by
  // standalone ids[0] and ids[4]; returns the engine, session id, ids and tag.
  Future<
    ({SessionFlowEngine engine, String sessionId, List<String> ids, String tag})
  >
  withSuperset(FakeSessionRepository repo) async {
    final engine = SessionFlowEngine(repository: repo);
    repo.seedWorkoutDay(_buildWorkoutDay(id: 'wd-1', exerciseCount: 5));
    final started = await engine.startSession(workoutDayId: 'wd-1');
    final ids = started.session.sessionExercises.map((e) => e.id).toList();
    final afterCreate = await engine.createSuperset(
      sessionId: started.session.id,
      sessionExerciseIds: [ids[1], ids[2], ids[3]],
    );
    final tag = afterCreate.session.sessionExercises
        .firstWhere((e) => e.id == ids[1])
        .supersetTag!;
    return (engine: engine, sessionId: started.session.id, ids: ids, tag: tag);
  }

  List<SessionExercise> sortedByPosition(SessionState state) =>
      List<SessionExercise>.of(state.session.sessionExercises)
        ..sort((a, b) => a.position.compareTo(b.position));

  group('SessionFlowEngine.removeFromSuperset', () {
    test('extracts the middle member: clears its tag, lands it right under the '
        'group, and keeps the remaining members one contiguous run', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final s = await withSuperset(repo);

      final result = await s.engine.removeFromSuperset(
        sessionId: s.sessionId,
        sessionExerciseId: s.ids[2],
      );

      final extracted = result.session.sessionExercises.firstWhere(
        (e) => e.id == s.ids[2],
      );
      expect(extracted.supersetTag, isNull);
      expect(extracted.state, isA<UnfinishedState>());

      // Remaining members keep the tag.
      final remaining = result.session.sessionExercises
          .where((e) => e.supersetTag == s.tag)
          .map((e) => e.id)
          .toSet();
      expect(remaining, {s.ids[1], s.ids[3]});

      // Order: standalone, [member, member], extracted, standalone.
      final order = sortedByPosition(result).map((e) => e.id).toList();
      expect(order, [s.ids[0], s.ids[1], s.ids[3], s.ids[2], s.ids[4]]);

      // The remaining members occupy consecutive slots (one contiguous run).
      final memberPositions =
          result.session.sessionExercises
              .where((e) => e.supersetTag == s.tag)
              .map((e) => e.position)
              .toList()
            ..sort();
      expect(memberPositions[1], memberPositions[0] + 1);
    });

    test(
      'extracting the first member keeps the rest contiguous below',
      () async {
        final repo = FakeSessionRepository(clock: fakeClock);
        final s = await withSuperset(repo);

        final result = await s.engine.removeFromSuperset(
          sessionId: s.sessionId,
          sessionExerciseId: s.ids[1],
        );

        final order = sortedByPosition(result).map((e) => e.id).toList();
        expect(order, [s.ids[0], s.ids[2], s.ids[3], s.ids[1], s.ids[4]]);
        expect(
          result.session.sessionExercises
              .where((e) => e.supersetTag == s.tag)
              .map((e) => e.id)
              .toSet(),
          {s.ids[2], s.ids[3]},
        );
      },
    );

    test('the extracted exercise keeps its logged sets and state', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final s = await withSuperset(repo);
      await s.engine.completeSet(
        sessionExerciseId: s.ids[2],
        actualValues: const ActualSetValues.repBased(weightKg: 50, reps: 5),
      );

      final result = await s.engine.removeFromSuperset(
        sessionId: s.sessionId,
        sessionExerciseId: s.ids[2],
      );

      final extracted = result.session.sessionExercises.firstWhere(
        (e) => e.id == s.ids[2],
      );
      expect(extracted.executedSets, hasLength(1));
      expect(extracted.supersetTag, isNull);
    });

    test('refuses an exercise that is not in a superset', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final s = await withSuperset(repo);

      await expectLater(
        s.engine.removeFromSuperset(
          sessionId: s.sessionId,
          sessionExerciseId: s.ids[0],
        ),
        throwsA(isA<ValidationError>()),
      );
    });

    test('refuses extracting a member that is itself finished', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final s = await withSuperset(repo);
      await s.engine.skipExercise(sessionExerciseId: s.ids[2]);

      await expectLater(
        s.engine.removeFromSuperset(
          sessionId: s.sessionId,
          sessionExerciseId: s.ids[2],
        ),
        throwsA(isA<OrderingError>()),
      );
    });

    test(
      'refuses extraction when any other group member is finished',
      () async {
        final repo = FakeSessionRepository(clock: fakeClock);
        final s = await withSuperset(repo);
        await s.engine.skipExercise(sessionExerciseId: s.ids[1]);

        await expectLater(
          s.engine.removeFromSuperset(
            sessionId: s.sessionId,
            sessionExerciseId: s.ids[2],
          ),
          throwsA(isA<OrderingError>()),
        );

        // Order and grouping are unchanged by the refused attempt.
        final after = (await repo.getSession(s.sessionId))!;
        final stillGrouped = after.sessionExercises
            .where((e) => e.supersetTag == s.tag)
            .map((e) => e.id)
            .toSet();
        expect(stillGrouped, {s.ids[1], s.ids[2], s.ids[3]});
      },
    );

    test('refuses extraction once the session has ended', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final s = await withSuperset(repo);
      await s.engine.endSession(sessionId: s.sessionId);

      await expectLater(
        s.engine.removeFromSuperset(
          sessionId: s.sessionId,
          sessionExerciseId: s.ids[2],
        ),
        throwsA(isA<ImmutabilityError>()),
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
    // Two planned sets so a single logged set leaves the exercise unfinished —
    // the data-preservation case extracts a member that has logged one set.
    final sets = [
      for (var j = 0; j < 2; j++)
        WorkoutSet(
          id: 'set-$id-$i-$j',
          exerciseId: exerciseId,
          position: j,
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
