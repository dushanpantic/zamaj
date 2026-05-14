import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/services/focus_mode_assembler.dart';

import '../../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  ({FakeSessionRepository repo, SessionFlowEngine engine}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    return (repo: repo, engine: SessionFlowEngine(repository: repo));
  }

  WorkoutDay buildDay({
    int benchSets = 2,
    int? plannedRestSeconds,
    MeasurementType benchMeasurement = const MeasurementType.repBased(),
  }) {
    final t = DateTime.utc(2024);
    final plannedValues = switch (benchMeasurement) {
      RepBasedMeasurement() => const PlannedSetValues.repBased(
        weightKg: 100,
        reps: 8,
      ),
      TimeBasedMeasurement() => const PlannedSetValues.timeBased(
        durationSeconds: 30,
      ),
    };
    return WorkoutDay(
      id: 'wd-1',
      programId: 'p-1',
      name: 'Upper',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g1',
          workoutDayId: 'wd-1',
          position: 0,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-bench',
              exerciseGroupId: 'g1',
              position: 0,
              name: 'Bench Press',
              measurementType: benchMeasurement,
              metadata: const ExerciseMetadata(notes: 'arch'),
              plannedRestSeconds: plannedRestSeconds,
              sets: [
                for (var i = 0; i < benchSets; i++)
                  WorkoutSet(
                    id: 'ws-$i',
                    exerciseId: 'ex-bench',
                    position: i,
                    measurementType: benchMeasurement,
                    plannedValues: plannedValues,
                    createdAt: t,
                    updatedAt: t,
                    schemaVersion: 1,
                  ),
              ],
              createdAt: t,
              updatedAt: t,
              schemaVersion: 1,
            ),
          ],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
        ExerciseGroup(
          id: 'g2',
          workoutDayId: 'wd-1',
          position: 1,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-row',
              exerciseGroupId: 'g2',
              position: 0,
              name: 'Row',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                WorkoutSet(
                  id: 'ws-row-0',
                  exerciseId: 'ex-row',
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: const PlannedSetValues.repBased(
                    weightKg: 60,
                    reps: 10,
                  ),
                  createdAt: t,
                  updatedAt: t,
                  schemaVersion: 1,
                ),
              ],
              createdAt: t,
              updatedAt: t,
              schemaVersion: 1,
            ),
          ],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      ],
      createdAt: t,
      updatedAt: t,
      schemaVersion: 1,
    );
  }

  group('FocusModeAssembler.assemble', () {
    test('returns null when cursor is completed', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay(benchSets: 1));
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises[0].id;
      final rowId = state.session.sessionExercises[1].id;
      await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 8),
      );
      final after = await s.engine.completeSet(
        sessionExerciseId: rowId,
        actualValues: const ActualSetValues.repBased(weightKg: 60, reps: 10),
      );

      expect(after.cursor, const Cursor.completed());
      expect(FocusModeAssembler.assemble(after), isNull);
    });

    test(
      'first-set view: planned/exec counts, no last-executed, up-next set',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildDay(plannedRestSeconds: 120));
        final state = await s.engine.startSession(workoutDayId: 'wd-1');

        final vm = FocusModeAssembler.assemble(state)!;

        expect(vm.displayExerciseName, 'Bench Press');
        expect(vm.workoutDayName, 'Upper');
        expect(vm.currentSetIndex, 0);
        expect(vm.totalPlannedSets, 2);
        expect(vm.completedSetsCount, 0);
        expect(vm.lastExecutedValues, isNull);
        expect(vm.currentPlannedValues, isA<PlannedRepBased>());
        expect(vm.currentPlannedSetIdInSnapshot, 'ws-0');
        expect(vm.plannedSummary, '100kg 2×8');
        expect(vm.plannedRestSeconds, 120);
        expect(vm.upNextExerciseName, 'Row');
        expect(vm.isReplaced, isFalse);
      },
    );

    test(
      'after one logged set: lastExecutedValues populated and cursor advances',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildDay());
        final state = await s.engine.startSession(workoutDayId: 'wd-1');
        final benchId = state.session.sessionExercises[0].id;
        final after = await s.engine.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 97.5, reps: 8),
        );
        final vm = FocusModeAssembler.assemble(after)!;
        expect(vm.currentSetIndex, 1);
        expect(vm.completedSetsCount, 1);
        expect(
          vm.lastExecutedValues,
          const ActualSetValues.repBased(weightKg: 97.5, reps: 8),
        );
      },
    );

    test('replaced exercise: display name & measurement type follow the '
        'substitute; isReplaced is true', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises[0].id;
      final after = await s.engine.replaceExercise(
        sessionExerciseId: benchId,
        substituteName: 'Cable Fly',
        substituteMeasurementType: const MeasurementType.timeBased(),
      );
      final vm = FocusModeAssembler.assemble(after)!;
      expect(vm.displayExerciseName, 'Cable Fly');
      expect(vm.plannedExerciseName, 'Bench Press');
      expect(vm.isReplaced, isTrue);
      expect(vm.effectiveMeasurementType, isA<TimeBasedMeasurement>());
    });

    test(
      'up-next skips terminal exercises and returns null at end of list',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildDay(benchSets: 1));
        final state = await s.engine.startSession(workoutDayId: 'wd-1');
        final rowId = state.session.sessionExercises[1].id;
        await s.engine.skipExercise(sessionExerciseId: rowId);
        final after = await s.engine.resumeSession(sessionId: state.session.id);
        final vm = FocusModeAssembler.assemble(after)!;
        // bench is the cursor target; row is the only other exercise but it's
        // skipped, so up-next should be null
        expect(vm.upNextExerciseName, isNull);
      },
    );
  });
}
