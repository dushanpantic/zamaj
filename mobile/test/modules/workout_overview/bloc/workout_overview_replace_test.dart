import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

final _t = DateTime.utc(2024);
const _libA = '11111111-1111-4111-8111-111111111111';
const _libB = '22222222-2222-4222-8222-222222222222';

Exercise _exercise(String id, {String? libraryExerciseId}) => Exercise(
  id: id,
  exerciseGroupId: 'g-$id',
  position: 0,
  name: 'Ex $id',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  libraryExerciseId: libraryExerciseId,
  sets: [
    WorkoutSet(
      id: 'ws-$id-0',
      exerciseId: id,
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

WorkoutDay _day(List<Exercise> exercises) => WorkoutDay(
  id: 'wd-valid',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    for (var i = 0; i < exercises.length; i++)
      ExerciseGroup(
        id: 'g-$i',
        workoutDayId: 'wd-valid',
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

AddedExercisePlan _plan({String? libraryExerciseId, String name = 'Replacement'}) =>
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

  group('WorkoutOverviewBloc replace', () {
    test('replaces an exercise: original terminated + new card via the engine',
        () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_day([_exercise('a')]));
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');
      final originalId = session.sessionExercises.single.id;

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

      s.bloc.add(
        WorkoutOverviewReplaceRequested(
          sessionExerciseId: originalId,
          plan: _plan(name: 'Goblet Squat'),
        ),
      );

      final loaded = await s.bloc.stream.firstWhere(
        (st) =>
            st is WorkoutOverviewLoaded &&
            st.sessionState.session.sessionExercises.length == 2,
      ) as WorkoutOverviewLoaded;

      final exercises = loaded.sessionState.session.sessionExercises;
      expect(
        exercises.firstWhere((e) => e.id == originalId).state,
        isA<SkippedState>(),
      );
      expect(exercises.last.addedPlan?.name, 'Goblet Squat');
    });

    test('a duplicate-movement guard error surfaces transiently and leaves the '
        'original unchanged', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_day([
        _exercise('a', libraryExerciseId: _libA),
        _exercise('b', libraryExerciseId: _libB),
      ]));
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');
      final aId = session.sessionExercises[0].id;

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

      // Replacing A with B's movement collides with the still-present B.
      s.bloc.add(
        WorkoutOverviewReplaceRequested(
          sessionExerciseId: aId,
          plan: _plan(libraryExerciseId: _libB),
        ),
      );

      final loaded = await s.bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.lastTransientError != null,
      ) as WorkoutOverviewLoaded;

      expect(loaded.lastTransientError, isA<ValidationError>());
      final exercises = loaded.sessionState.session.sessionExercises;
      expect(exercises, hasLength(2));
      expect(
        exercises.firstWhere((e) => e.id == aId).state,
        isA<UnfinishedState>(),
      );
    });

    test('no-ops when the session has ended', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_day([_exercise('a')]));
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');
      final aId = session.sessionExercises.single.id;

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);
      s.bloc.add(const WorkoutOverviewSessionEnded());
      await s.bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.isEnded,
      );

      s.bloc.add(
        WorkoutOverviewReplaceRequested(sessionExerciseId: aId, plan: _plan()),
      );
      await pumpEventQueue();

      final loaded = s.bloc.state as WorkoutOverviewLoaded;
      expect(loaded.sessionState.session.sessionExercises, hasLength(1));
      expect(loaded.lastTransientError, isNull);
    });
  });
}
