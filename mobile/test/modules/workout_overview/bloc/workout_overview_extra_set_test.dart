import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

final _t = DateTime.utc(2024);

Exercise _exercise(String id, {int sets = 1}) => Exercise(
  id: id,
  exerciseGroupId: 'g-$id',
  position: 0,
  name: 'Ex $id',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
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

WorkoutDay _dayWithSets(int sets) => WorkoutDay(
  id: 'wd-valid',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g-real',
      workoutDayId: 'wd-valid',
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

void main() {
  final fakeClock = Clock.fixed(_t);

  ({FakeSessionRepository repo, WorkoutOverviewBloc bloc}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo);
    final bloc = WorkoutOverviewBloc(sessionFlowEngine: engine);
    return (repo: repo, bloc: bloc);
  }

  /// Starts a session with a single planned set and logs it, leaving the lone
  /// exercise auto-completed. Returns the loaded bloc + the exercise id.
  Future<({WorkoutOverviewBloc bloc, FakeSessionRepository repo, String seId})>
  completedExercise() async {
    final s = setup();
    s.repo.seedWorkoutDay(_dayWithSets(1));
    final session = await s.repo.startSession(workoutDayId: 'wd-valid');
    final seId = session.sessionExercises.single.id;

    s.bloc.add(WorkoutOverviewOpened(session.id));
    await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

    s.bloc.add(
      WorkoutOverviewSetLogged(
        sessionExerciseId: seId,
        actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
      ),
    );
    await s.bloc.stream.firstWhere(
      (st) =>
          st is WorkoutOverviewLoaded &&
          st.sessionState.session.sessionExercises.single.state
              is CompletedState,
    );
    return (bloc: s.bloc, repo: s.repo, seId: seId);
  }

  group('WorkoutOverviewBloc extra-set', () {
    test('adds a set beyond plan on a completed exercise; stays completed, '
        'seeds the new set from the last logged set', () async {
      final c = await completedExercise();
      addTearDown(c.bloc.close);

      c.bloc.add(WorkoutOverviewExtraSetRequested(c.seId));

      final loaded = await c.bloc.stream.firstWhere(
        (st) =>
            st is WorkoutOverviewLoaded &&
            st.sessionState.session.sessionExercises.single.executedSets.length ==
                2,
      ) as WorkoutOverviewLoaded;

      final exercise = loaded.sessionState.session.sessionExercises.single;
      // Still completed — an extra set never demotes a completed exercise.
      expect(exercise.state, isA<CompletedState>());
      // The 2nd (beyond-plan) set is seeded from the last logged set's values.
      expect(
        exercise.executedSets.last.actualValues,
        const ActualSetValues.repBased(weightKg: 100, reps: 5),
      );
      // One planned set, two executed: a row beyond the planned count exists.
      expect(exercise.executedSets.length, 2);
    });

    test('no-ops when the session has ended', () async {
      final c = await completedExercise();
      addTearDown(c.bloc.close);

      c.bloc.add(const WorkoutOverviewSessionEnded());
      await c.bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.isEnded,
      );

      c.bloc.add(WorkoutOverviewExtraSetRequested(c.seId));
      await pumpEventQueue();

      final loaded = c.bloc.state as WorkoutOverviewLoaded;
      // No new set was logged and no error surfaced — the handler returned
      // before touching the engine.
      expect(
        loaded.sessionState.session.sessionExercises.single.executedSets.length,
        1,
      );
      expect(loaded.lastTransientError, isNull);
    });
  });
}
