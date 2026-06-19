import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

final _t = DateTime.utc(2025);

/// A single-exercise session in a chosen [state], with [planned] planned sets
/// and [executed] logged sets. [ended] stamps `endedAt` so the assembler sees a
/// finished (read-only) session.
Session _session({
  required ExerciseState state,
  int planned = 2,
  int executed = 0,
  bool ended = false,
}) {
  const exId = 'ex-a';
  const seId = 'se-a';
  final sets = List.generate(
    planned,
    (j) => WorkoutSet(
      id: 'ws-$j',
      exerciseId: exId,
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
  );
  final exercise = Exercise(
    id: exId,
    exerciseGroupId: 'grp',
    position: 0,
    name: 'Bench',
    measurementType: const MeasurementType.repBased(),
    metadata: const ExerciseMetadata(),
    sets: sets,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
  final workoutDay = WorkoutDay(
    id: 'wd',
    programId: 'p',
    name: 'D',
    exerciseGroups: [
      ExerciseGroup(
        id: 'grp',
        workoutDayId: 'wd',
        position: 0,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercise],
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
    workoutDayId: 'wd',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: seId,
        sessionId: 'session-1',
        position: 0,
        plannedExerciseIdInSnapshot: exId,
        state: state,
        executedSets: List.generate(
          executed,
          (j) => ExecutedSet(
            id: 'es-$j',
            sessionExerciseId: seId,
            position: j,
            measurementType: const MeasurementType.repBased(),
            actualValues: const ActualSetValues.repBased(
              weightKg: 100,
              reps: 5,
            ),
            plannedSetIdInSnapshot: j < planned ? 'ws-$j' : null,
            completedAt: _t,
            createdAt: _t,
            updatedAt: _t,
            schemaVersion: 1,
          ),
        ),
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    endedAt: ended ? _t : null,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

void main() {
  group('ExerciseViewModelAssembler canAddSet (extra-set affordance)', () {
    test('a completed exercise on a live session offers Add set', () {
      final session = _session(
        state: const ExerciseState.completed(),
        executed: 2,
      );
      final state = SessionState(
        session: session,
        openTargets: const [],
        isComplete: true,
      );

      final vm = ExerciseViewModelAssembler.assemble(
        state,
      ).single.allExercises.single;
      expect(vm.canAddSet, isTrue);
    });

    test('a skipped exercise never offers Add set', () {
      final session = _session(state: const ExerciseState.skipped());
      final state = SessionState(
        session: session,
        openTargets: const [],
        isComplete: false,
      );

      final vm = ExerciseViewModelAssembler.assemble(
        state,
      ).single.allExercises.single;
      expect(vm.canAddSet, isFalse);
    });

    test('an unfinished exercise does not offer Add set (it logs normally)', () {
      final session = _session(state: const ExerciseState.unfinished());
      final state = SessionState(
        session: session,
        openTargets: const [
          LogTarget(sessionExerciseId: 'se-a', plannedSetIndex: 0),
        ],
        isComplete: false,
      );

      final vm = ExerciseViewModelAssembler.assemble(
        state,
      ).single.allExercises.single;
      expect(vm.canAddSet, isFalse);
    });

    test('a completed exercise on an ended session does not offer Add set', () {
      final session = _session(
        state: const ExerciseState.completed(),
        executed: 2,
        ended: true,
      );
      final state = SessionState(
        session: session,
        openTargets: const [],
        isComplete: true,
      );

      final vm = ExerciseViewModelAssembler.assemble(
        state,
      ).single.allExercises.single;
      expect(vm.canAddSet, isFalse);
    });
  });
}
