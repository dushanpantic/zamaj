import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

final _t = DateTime.utc(2025);

AddedExercisePlan _plan() => AddedExercisePlan(
  name: 'Added Curl',
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 60,
    repTarget: RepTarget.fixed(reps: 12),
  ),
  setCount: 2,
);

/// An ended session whose only exercise is an added one (snapshot-less),
/// completed with [executed] logged sets.
Session _endedSessionWithAdded({required int executed}) {
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
  return Session(
    id: 'session-1',
    workoutDayId: 'wd-empty',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: 'se-added',
        sessionId: 'session-1',
        position: 0,
        plannedExerciseIdInSnapshot: 'synthetic-added-0000-0000-000000000000',
        state: executed >= 2
            ? const ExerciseState.completed()
            : const ExerciseState.unfinished(),
        executedSets: [
          for (var i = 0; i < executed; i++)
            ExecutedSet(
              id: 'es-$i',
              sessionExerciseId: 'se-added',
              position: i,
              measurementType: const MeasurementType.repBased(),
              actualValues: const ActualSetValues.repBased(
                weightKg: 60,
                reps: 12,
              ),
              completedAt: _t,
              createdAt: _t,
              updatedAt: _t,
              schemaVersion: 1,
            ),
        ],
        addedPlan: _plan(),
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: _t,
    endedAt: _t,
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
}

void main() {
  group('SessionHistory.completedExerciseCount with an added exercise', () {
    test('counts a fully-logged added exercise as completed', () {
      final session = _endedSessionWithAdded(executed: 2);
      expect(SessionHistory.completedExerciseCount(session), 1);
    });

    test('a partially-logged added exercise does not count', () {
      final session = _endedSessionWithAdded(executed: 1);
      expect(SessionHistory.completedExerciseCount(session), 0);
    });
  });
}
