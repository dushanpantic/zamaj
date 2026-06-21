import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

final _t = DateTime.utc(2025);

/// A session containing only an added (snapshot-less) exercise. The snapshot's
/// workout day is empty, so a regression to snapshot resolution would throw.
SessionState _stateWithAdded(AddedExercisePlan plan) {
  final workoutDay = WorkoutDay(
    id: 'wd',
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
    id: 'session-1',
    workoutDayId: 'wd',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: 'se-added',
        sessionId: 'session-1',
        position: 0,
        plannedExerciseIdInSnapshot: 'synthetic-added-00000000000000000000',
        state: const ExerciseState.unfinished(),
        executedSets: const [],
        addedPlan: plan,
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
  return SessionState(
    session: session,
    openTargets: const [
      LogTarget(sessionExerciseId: 'se-added', plannedSetIndex: 0),
    ],
    isComplete: false,
  );
}

void main() {
  test('assembles an added exercise from its inline plan as a single group, '
      'no crash from the missing snapshot entry', () {
    final plan = AddedExercisePlan(
      name: 'Added Curl',
      measurementType: const MeasurementType.repBased(),
      plannedValues: PlannedSetValues.repBased(
        weightKg: 60,
        repTarget: RepTarget.fixed(reps: 12),
      ),
      setCount: 3,
    );

    final groups = ExerciseViewModelAssembler.assemble(_stateWithAdded(plan));

    expect(groups, hasLength(1));
    expect(groups.single, isA<SingleGroupViewModel>());
    final vm = groups.single.allExercises.single;
    expect(vm.displayName, 'Added Curl');
    expect(vm.plannedMeasurementType, const MeasurementType.repBased());
    expect(vm.effectiveMeasurementType, const MeasurementType.repBased());
    expect(vm.setRows, hasLength(3));
    for (final row in vm.setRows) {
      expect(
        row.plannedValues,
        PlannedSetValues.repBased(
          weightKg: 60,
          repTarget: RepTarget.fixed(reps: 12),
        ),
      );
    }
    // Planned summary derives from the same formatter the snapshot path uses,
    // rendering the inline plan's concrete values (60kg, 3 sets, 12 reps).
    expect(vm.plannedSummary, '60kg 3×12');
  });
}
