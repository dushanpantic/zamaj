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

WorkoutDay _validDay() => WorkoutDay(
  id: 'wd-valid',
  programId: 'p',
  name: 'D',
  exerciseGroups: [
    ExerciseGroup(
      id: 'g-real',
      workoutDayId: 'wd-valid',
      position: 0,
      kind: const ExerciseGroupKind.single(),
      exercises: [_exercise('planned-real')],
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    ),
  ],
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

/// A session whose single session-exercise is in a terminal (completed) state
/// but references a planned id absent from the snapshot. The engine's
/// `_buildState` resolves only unfinished/replaced exercises, so it succeeds and
/// emits a state; the assembler resolves *every* exercise, so it throws
/// NotFoundError — the exact gap Step 1.6 wraps.
Session _corruptSession(String id) {
  final workoutDay = WorkoutDay(
    id: 'wd-$id',
    programId: 'p',
    name: 'D',
    exerciseGroups: [
      ExerciseGroup(
        id: 'g-real',
        workoutDayId: 'wd-$id',
        position: 0,
        kind: const ExerciseGroupKind.single(),
        exercises: [_exercise('planned-real')],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
    ],
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: _t,
    schemaVersion: 1,
  );
  return Session(
    id: id,
    workoutDayId: 'wd-$id',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: 'se-1',
        sessionId: id,
        position: 0,
        plannedExerciseIdInSnapshot: 'ghost-missing',
        state: const ExerciseState.completed(),
        executedSets: const [],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

void main() {
  final fakeClock = Clock.fixed(_t);

  ({FakeSessionRepository repo, WorkoutOverviewBloc bloc}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo);
    final bloc = WorkoutOverviewBloc(sessionFlowEngine: engine);
    return (repo: repo, bloc: bloc);
  }

  group('WorkoutOverviewBloc corrupt-snapshot crash safety', () {
    test('a corrupt snapshot on the load path surfaces LoadFailure, '
        'not an unhandled crash', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedSession(_corruptSession('s-corrupt'));

      s.bloc.add(const WorkoutOverviewOpened('s-corrupt'));

      final terminal = await s.bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoadFailure || st is WorkoutOverviewLoaded,
      );
      expect(terminal, isA<WorkoutOverviewLoadFailure>());
      expect(
        (terminal as WorkoutOverviewLoadFailure).error,
        isA<NotFoundError>(),
      );
    });

    test('a corrupt snapshot pushed as a live update surfaces a transient '
        'error on the loaded state, not a crash', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(_validDay());
      final session = await s.repo.startSession(workoutDayId: 'wd-valid');

      s.bloc.add(WorkoutOverviewOpened(session.id));
      await s.bloc.stream.firstWhere((st) => st is WorkoutOverviewLoaded);

      // Push a corrupt version of the same session through the watch stream.
      s.repo.seedSession(_corruptSession(session.id));

      final after = await s.bloc.stream.firstWhere(
        (st) => st is WorkoutOverviewLoaded && st.lastTransientError != null,
      );
      expect(
        (after as WorkoutOverviewLoaded).lastTransientError,
        isA<NotFoundError>(),
      );
    });
  });
}
