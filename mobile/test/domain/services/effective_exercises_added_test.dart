import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/services/focus_mode_assembler.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

import '../../support/fake_session_repository.dart';

final _t = DateTime.utc(2025);

/// One snapshot-backed planned exercise (rep-based, [sets] planned sets).
Exercise _planned(String id, {int sets = 3}) => Exercise(
  id: id,
  exerciseGroupId: 'g-$id',
  position: 0,
  name: 'Planned $id',
  measurementType: const MeasurementType.repBased(),
  metadata: const ExerciseMetadata(),
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

AddedExercisePlan _curlPlan() => AddedExercisePlan(
  name: 'Added Curl',
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 60,
    repTarget: RepTarget.fixed(reps: 12),
  ),
  setCount: 2,
);

SessionExercise _addedExercise({
  String id = 'se-added',
  ExerciseState state = const ExerciseState.unfinished(),
  int executed = 0,
}) => SessionExercise(
  id: id,
  sessionId: 'session-1',
  position: 1,
  // A synthetic id deliberately absent from the snapshot.
  plannedExerciseIdInSnapshot: 'synthetic-added-0000-0000-000000000000',
  state: state,
  executedSets: [
    for (var i = 0; i < executed; i++)
      ExecutedSet(
        id: 'es-added-$i',
        sessionExerciseId: id,
        position: i,
        measurementType: const MeasurementType.repBased(),
        actualValues: const ActualSetValues.repBased(weightKg: 60, reps: 12),
        completedAt: _t,
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
  ],
  addedPlan: _curlPlan(),
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

/// A session with one snapshot-backed exercise plus [extra] session exercises
/// (added / replaced) appended after it.
Session _session({List<SessionExercise> extra = const []}) {
  final workoutDay = WorkoutDay(
    id: 'wd-1',
    programId: 'p',
    name: 'Upper',
    exerciseGroups: [
      ExerciseGroup(
        id: 'g-planned-real',
        workoutDayId: 'wd-1',
        position: 0,
        kind: const ExerciseGroupKind.single(),
        exercises: [_planned('planned-real')],
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
    id: 'session-1',
    workoutDayId: 'wd-1',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: 'se-snap',
        sessionId: 'session-1',
        position: 0,
        plannedExerciseIdInSnapshot: 'planned-real',
        state: const ExerciseState.unfinished(),
        executedSets: const [],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
      ...extra,
    ],
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

SessionFlowEngine _engine() =>
    SessionFlowEngine(repository: FakeSessionRepository(clock: Clock.fixed(_t)));

void main() {
  group('EffectiveExercises resolves an added (snapshot-less) exercise', () {
    test('resolves name/measurementType/setCount/plannedValues/role from the '
        'inline plan, with no NotFoundError', () {
      final session = _session(extra: [_addedExercise()]);
      final effective = EffectiveExercises.of(session);

      final added = session.sessionExercises.firstWhere(
        (e) => e.id == 'se-added',
      );
      final resolved = effective.forSessionExercise(added);

      expect(resolved.displayName, 'Added Curl');
      expect(resolved.effectiveMeasurementType, const MeasurementType.repBased());
      expect(resolved.plannedSetCount, 2);
      expect(resolved.plannedGroupRole, ExerciseGroupRole.main);
      expect(
        resolved.plannedValuesAt(0),
        PlannedSetValues.repBased(
          weightKg: 60,
          repTarget: RepTarget.fixed(reps: 12),
        ),
      );
    });

    test('a snapshot-backed exercise still resolves from the snapshot', () {
      final session = _session();
      final snap = session.sessionExercises.firstWhere((e) => e.id == 'se-snap');
      final resolved = EffectiveExercises.of(session).forSessionExercise(snap);
      expect(resolved.displayName, 'Planned planned-real');
      expect(resolved.plannedSetCount, 3);
    });

  });

  group('EffectiveExercises consumers tolerate an added exercise', () {
    test('engine.computeOpenTargets includes the added unfinished exercise', () {
      final session = _session(extra: [_addedExercise()]);
      final targets = _engine().computeOpenTargets(session);
      expect(
        targets.map((t) => t.sessionExerciseId),
        containsAll(<String>['se-snap', 'se-added']),
      );
    });

    test('engine.suggestValuesFor on the added exercise seeds from its plan', () {
      final session = _session(extra: [_addedExercise()]);
      final suggested = _engine().suggestValuesFor(
        session: session,
        sessionExerciseId: 'se-added',
      );
      expect(suggested, const ActualSetValues.repBased(weightKg: 60, reps: 12));
    });

    test('engine.isSessionComplete handles a completed added exercise', () {
      // Single completed added exercise → session reads complete.
      final workoutDay = WorkoutDay(
        id: 'wd-empty',
        programId: 'p',
        name: 'D',
        exerciseGroups: const [],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      );
      final snapshot = SessionSnapshot.capture(
        workoutDay: workoutDay,
        capturedAt: _t,
        schemaVersion: 1,
      );
      final session = Session(
        id: 'session-2',
        workoutDayId: 'wd-empty',
        snapshot: snapshot,
        sessionExercises: [
          _addedExercise(
            id: 'se-added-done',
            state: const ExerciseState.completed(),
            executed: 2,
          ),
        ],
        notes: const [],
        extraWork: const [],
        startedAt: _t,
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      );
      expect(_engine().isSessionComplete(session), isTrue);
    });

    test('the overview assembler builds a view model for the added exercise', () {
      final session = _session(extra: [_addedExercise()]);
      final state = SessionState(
        session: session,
        openTargets: _engine().computeOpenTargets(session),
        isComplete: false,
      );
      final groups = ExerciseViewModelAssembler.assemble(state);
      final addedVm = groups
          .expand((g) => g.allExercises)
          .firstWhere((vm) => vm.sessionExercise.id == 'se-added');
      expect(addedVm.displayName, 'Added Curl');
      expect(addedVm.setRows, hasLength(2));
    });

    test('the focus assembler builds a panel anchored on the added exercise', () {
      final session = _session(extra: [_addedExercise()]);
      final state = SessionState(
        session: session,
        openTargets: _engine().computeOpenTargets(session),
        isComplete: false,
      );
      final group = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: 'se-added',
      );
      expect(group, isNotNull);
      final panel = group!.panels.firstWhere(
        (p) => p.sessionExerciseId == 'se-added',
      );
      expect(panel.displayExerciseName, 'Added Curl');
      expect(panel.totalPlannedSets, 2);
    });
  });
}
