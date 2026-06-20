import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

final _t = DateTime.utc(2024);

Exercise _exercise({int sets = 3}) => Exercise(
  id: 'planned-real',
  exerciseGroupId: 'g-real',
  position: 0,
  name: 'Squat',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: [
    for (var i = 0; i < sets; i++)
      WorkoutSet(
        id: 'ws-$i',
        exerciseId: 'planned-real',
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

WorkoutDay _day() => WorkoutDay(
  id: 'wd-valid',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g-real',
      workoutDayId: 'wd-valid',
      position: 0,
      kind: const ExerciseGroupKind.single(),
      exercises: [_exercise()],
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
    return (repo: repo, bloc: WorkoutOverviewBloc(sessionFlowEngine: engine));
  }

  group('WorkoutOverviewBloc resume', () {
    test(
      'resumes a skipped exercise back to loggable via the engine',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        s.repo.seedWorkoutDay(_day());
        final session = await s.repo.startSession(workoutDayId: 'wd-valid');
        final seId = session.sessionExercises.single.id;
        await s.repo.skipExercise(seId);

        s.bloc.add(WorkoutOverviewOpened(session.id));
        await s.bloc.stream.firstWhere(
          (st) =>
              st is WorkoutOverviewLoaded &&
              st.sessionState.session.sessionExercises.single.state
                  is SkippedState,
        );

        s.bloc.add(WorkoutOverviewResumeRequested(seId));

        final loaded =
            await s.bloc.stream.firstWhere(
                  (st) =>
                      st is WorkoutOverviewLoaded &&
                      st.sessionState.session.sessionExercises.single.state
                          is UnfinishedState,
                )
                as WorkoutOverviewLoaded;

        expect(
          loaded.sessionState.openTargets.map((t) => t.sessionExerciseId),
          contains(seId),
        );
      },
    );

    test('no-ops when the session has ended', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_day());
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');
      final seId = session.sessionExercises.single.id;
      await s.repo.skipExercise(seId);

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);
      s.bloc.add(const WorkoutOverviewSessionEnded());
      await s.bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.isEnded,
      );

      s.bloc.add(WorkoutOverviewResumeRequested(seId));
      await pumpEventQueue();

      final loaded = s.bloc.state as WorkoutOverviewLoaded;
      expect(
        loaded.sessionState.session.sessionExercises.single.state,
        isA<SkippedState>(),
      );
      expect(loaded.lastTransientError, isNull);
    });
  });
}
