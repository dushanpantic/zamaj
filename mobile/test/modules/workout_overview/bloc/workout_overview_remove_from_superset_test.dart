import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

final _t = DateTime.utc(2024);

Exercise _exercise(int i) => Exercise(
  id: 'planned-$i',
  exerciseGroupId: 'g-$i',
  position: 0,
  name: 'Exercise $i',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: [
    for (var j = 0; j < 2; j++)
      WorkoutSet(
        id: 'ws-$i-$j',
        exerciseId: 'planned-$i',
        position: j,
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

WorkoutDay _day({int count = 5}) => WorkoutDay(
  id: 'wd-valid',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    for (var i = 0; i < count; i++)
      ExerciseGroup(
        id: 'g-$i',
        workoutDayId: 'wd-valid',
        position: i,
        kind: const ExerciseGroupKind.single(),
        exercises: [_exercise(i)],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
  ],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

/// FakeSessionRepository whose [removeFromSuperset] blocks on [gate] so the
/// in-flight window can be observed deterministically, and counts its calls so
/// a dropped (guarded) dispatch is provable.
class _GatedRepo extends FakeSessionRepository {
  _GatedRepo({required super.clock});

  final Completer<void> gate = Completer<void>();
  int removeCalls = 0;

  @override
  Future<Session> removeFromSuperset({
    required String sessionId,
    required String sessionExerciseId,
  }) async {
    removeCalls++;
    await gate.future;
    return super.removeFromSuperset(
      sessionId: sessionId,
      sessionExerciseId: sessionExerciseId,
    );
  }
}

void main() {
  final fakeClock = Clock.fixed(_t);

  // Seeds a started session with a 3-member superset over the middle three of
  // five exercises; returns the session and member ids.
  Future<({String sessionId, List<String> ids})> seedSuperset(
    FakeSessionRepository repo,
  ) async {
    repo.seedWorkoutDay(_day());
    final session = await repo.startSession(workoutDayId: 'wd-valid');
    final ids = session.sessionExercises.map((e) => e.id).toList();
    await repo.createSuperset(
      sessionId: session.id,
      sessionExerciseIds: [ids[1], ids[2], ids[3]],
    );
    return (sessionId: session.id, ids: ids);
  }

  group('WorkoutOverviewBloc remove-from-superset', () {
    test(
      'extracts the member through the engine and emits the new state',
      () async {
        final repo = FakeSessionRepository(clock: fakeClock);
        final bloc = WorkoutOverviewBloc(
          sessionFlowEngine: SessionFlowEngine(repository: repo),
        );
        addTearDown(bloc.close);
        final s = await seedSuperset(repo);

        bloc.add(WorkoutOverviewOpened(s.sessionId));
        await bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

        bloc.add(WorkoutOverviewSupersetMemberRemoved(s.ids[2]));

        final loaded =
            await bloc.stream.firstWhere(
                  (st) =>
                      st is WorkoutOverviewLoaded &&
                      !st.mutationInFlight &&
                      st.sessionState.session.sessionExercises
                              .firstWhere((e) => e.id == s.ids[2])
                              .supersetTag ==
                          null,
                )
                as WorkoutOverviewLoaded;

        // Remaining members stay grouped; the extracted one sits directly below.
        final order =
            (List.of(loaded.sessionState.session.sessionExercises)
                  ..sort((a, b) => a.position.compareTo(b.position)))
                .map((e) => e.id)
                .toList();
        expect(order, [s.ids[0], s.ids[1], s.ids[3], s.ids[2], s.ids[4]]);
        expect(loaded.mutationInFlight, isFalse);
      },
    );

    test('is ignored once the session has ended', () async {
      final repo = FakeSessionRepository(clock: fakeClock);
      final bloc = WorkoutOverviewBloc(
        sessionFlowEngine: SessionFlowEngine(repository: repo),
      );
      addTearDown(bloc.close);
      final s = await seedSuperset(repo);
      await repo.endSession(s.sessionId);

      bloc.add(WorkoutOverviewOpened(s.sessionId));
      await bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.isEnded,
      );

      bloc.add(WorkoutOverviewSupersetMemberRemoved(s.ids[2]));
      await pumpEventQueue();

      final loaded = bloc.state as WorkoutOverviewLoaded;
      // The member is still grouped — nothing ran.
      expect(
        loaded.sessionState.session.sessionExercises
            .firstWhere((e) => e.id == s.ids[2])
            .supersetTag,
        isNotNull,
      );
      expect(loaded.lastTransientError, isNull);
    });

    test('is dropped while another mutation is in flight', () async {
      final repo = _GatedRepo(clock: fakeClock);
      final bloc = WorkoutOverviewBloc(
        sessionFlowEngine: SessionFlowEngine(repository: repo),
      );
      addTearDown(bloc.close);
      final s = await seedSuperset(repo);

      bloc.add(WorkoutOverviewOpened(s.sessionId));
      await bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

      // First removal blocks in the engine, holding the in-flight flag.
      bloc.add(WorkoutOverviewSupersetMemberRemoved(s.ids[2]));
      await bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.mutationInFlight,
      );

      // Second removal arrives mid-flight and must be dropped by the guard.
      bloc.add(WorkoutOverviewSupersetMemberRemoved(s.ids[3]));
      await pumpEventQueue();
      expect(repo.removeCalls, 1);

      // Release the first; it completes normally.
      repo.gate.complete();
      await bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && !st.mutationInFlight,
      );
      expect(repo.removeCalls, 1);
    });
  });
}
