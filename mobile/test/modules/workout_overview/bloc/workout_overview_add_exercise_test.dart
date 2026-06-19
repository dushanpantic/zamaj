import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

final _t = DateTime.utc(2024);
const _libraryId = '11111111-1111-4111-8111-111111111111';

Exercise _exercise({String? libraryExerciseId}) => Exercise(
  id: 'planned-real',
  exerciseGroupId: 'g-real',
  position: 0,
  name: 'Squat',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  libraryExerciseId: libraryExerciseId,
  sets: [
    WorkoutSet(
      id: 'ws-0',
      exerciseId: 'planned-real',
      position: 0,
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

WorkoutDay _day({String? libraryExerciseId}) => WorkoutDay(
  id: 'wd-valid',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g-real',
      workoutDayId: 'wd-valid',
      position: 0,
      kind: const ExerciseGroupKind.single(),
      exercises: [_exercise(libraryExerciseId: libraryExerciseId)],
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

void main() {
  final fakeClock = Clock.fixed(_t);

  ({FakeSessionRepository repo, WorkoutOverviewBloc bloc}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo);
    return (repo: repo, bloc: WorkoutOverviewBloc(sessionFlowEngine: engine));
  }

  group('WorkoutOverviewBloc add-exercise', () {
    test('adds a one-off exercise card via the engine', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_day());
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

      s.bloc.add(WorkoutOverviewAddExerciseRequested(_plan(name: 'Cable Curl')));

      final loaded = await s.bloc.stream.firstWhere(
        (st) =>
            st is WorkoutOverviewLoaded &&
            st.sessionState.session.sessionExercises.length == 2,
      ) as WorkoutOverviewLoaded;

      expect(loaded.groups, hasLength(2));
      expect(
        loaded.sessionState.session.sessionExercises.last.addedPlan?.name,
        'Cable Curl',
      );
    });

    test('a duplicate-movement guard error surfaces transiently with no card '
        'added', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_day(libraryExerciseId: _libraryId));
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

      s.bloc.add(
        WorkoutOverviewAddExerciseRequested(_plan(libraryExerciseId: _libraryId)),
      );

      final loaded = await s.bloc.stream.firstWhere(
        (st) =>
            st is WorkoutOverviewLoaded && st.lastTransientError != null,
      ) as WorkoutOverviewLoaded;

      expect(loaded.lastTransientError, isA<ValidationError>());
      expect(loaded.sessionState.session.sessionExercises, hasLength(1));
    });

    test('no-ops when the session has ended', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_day());
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);
      s.bloc.add(const WorkoutOverviewSessionEnded());
      await s.bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.isEnded,
      );

      s.bloc.add(WorkoutOverviewAddExerciseRequested(_plan()));
      await pumpEventQueue();

      final loaded = s.bloc.state as WorkoutOverviewLoaded;
      expect(loaded.sessionState.session.sessionExercises, hasLength(1));
      expect(loaded.lastTransientError, isNull);
    });
  });
}
