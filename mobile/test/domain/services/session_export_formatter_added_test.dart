import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

final _t = DateTime.utc(2026, 5, 12);

/// A one-exercise snapshot session (the planned `Bench Press`) plus an **added**
/// exercise that is NOT in the frozen snapshot: its `plannedExerciseIdInSnapshot`
/// is a synthetic id absent from the snapshot, and its plan lives inline on
/// `addedPlan`. The added exercise here is planned for three sets but only one is
/// logged, so a correct outcome reads `partial`.
Session _sessionWithAdded() {
  final plannedSet = WorkoutSet(
    id: 'ws-0',
    exerciseId: 'ex-0',
    position: 0,
    measurementType: const MeasurementType.repBased(),
    plannedValues: PlannedSetValues.repBased(
      weightKg: 100,
      repTarget: RepTarget.fixed(reps: 5),
    ),
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
  final plannedExercise = Exercise(
    id: 'ex-0',
    exerciseGroupId: 'g-0',
    position: 0,
    name: 'Bench Press',
    measurementType: const MeasurementType.repBased(),
    metadata: const ExerciseMetadata(),
    sets: [plannedSet],
    createdAt: _t,
    updatedAt: _t,
    schemaVersion: 1,
  );
  final workoutDay = WorkoutDay(
    id: 'wd-1',
    programId: 'p-1',
    name: 'Upper A',
    exerciseGroups: [
      ExerciseGroup(
        id: 'g-0',
        workoutDayId: 'wd-1',
        position: 0,
        kind: const ExerciseGroupKind.single(),
        exercises: [plannedExercise],
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

  final addedPlan = AddedExercisePlan(
    name: 'Sled Push',
    measurementType: const MeasurementType.repBased(),
    plannedValues: PlannedSetValues.repBased(
      weightKg: 60,
      repTarget: RepTarget.fixed(reps: 12),
    ),
    setCount: 3,
  );

  return Session(
    id: 'session-1',
    workoutDayId: 'wd-1',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: 'sx-0',
        sessionId: 'session-1',
        position: 0,
        plannedExerciseIdInSnapshot: 'ex-0',
        state: const ExerciseState.completed(),
        executedSets: [
          ExecutedSet(
            id: 'es-0',
            sessionExerciseId: 'sx-0',
            position: 0,
            measurementType: const MeasurementType.repBased(),
            actualValues: const ActualSetValues.repBased(
              weightKg: 100,
              reps: 5,
            ),
            plannedSetIdInSnapshot: 'ws-0',
            completedAt: _t,
            createdAt: _t,
            updatedAt: _t,
            schemaVersion: 1,
          ),
        ],
        createdAt: _t,
        updatedAt: _t,
        schemaVersion: 1,
      ),
      // Added exercise: synthetic snapshot id (absent from the snapshot),
      // inline plan, one of three planned sets logged.
      SessionExercise(
        id: 'sx-added',
        sessionId: 'session-1',
        position: 1,
        plannedExerciseIdInSnapshot: 'synthetic-added-00000000000000000000',
        state: const ExerciseState.completed(),
        executedSets: [
          ExecutedSet(
            id: 'es-added-0',
            sessionExerciseId: 'sx-added',
            position: 0,
            measurementType: const MeasurementType.repBased(),
            actualValues: const ActualSetValues.repBased(
              weightKg: 60,
              reps: 12,
            ),
            plannedSetIdInSnapshot: null,
            completedAt: _t,
            createdAt: _t,
            updatedAt: _t,
            schemaVersion: 1,
          ),
        ],
        addedPlan: addedPlan,
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
  group('SessionExportFormatter with an added exercise', () {
    test('renders the added exercise real name, inline plan line, and a '
        'correctly derived outcome', () {
      final out = SessionExportFormatter.format(_sessionWithAdded());

      // Real name, not the "(unknown)" snapshot-miss degradation.
      expect(out, contains('Sled Push'));
      expect(out, isNot(contains('(unknown)')));

      // Plan line comes from the inline plan (60kg, 3 sets, 12 reps).
      expect(out, contains('Plan: 60kg 3 × 12'));

      // Outcome derives from the inline plan's set count (3), so 1-of-3 logged
      // reads partial — a regression that dropped plannedCount to 0 would read
      // this as completed (no suffix).
      final addedHeader = out
          .split('\n')
          .firstWhere((l) => l.contains('Sled Push'));
      expect(addedHeader, contains('(1/3 sets)'));

      // The single logged set is rendered (uniform → compact Done line).
      expect(out, contains('Done: 60kg 1 × 12'));
    });
  });
}
