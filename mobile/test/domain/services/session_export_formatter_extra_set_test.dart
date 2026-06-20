import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

final _t = DateTime.utc(2026, 5, 12);

/// A one-exercise, ended session whose lone exercise is planned for [planned]
/// sets but has [actual] logged sets (each `actual[i]` is a (weightKg, reps)
/// pair). Used to exercise the "extra set beyond plan" export path.
Session _sessionWith({
  required int planned,
  required List<(double, int)> actual,
  ExerciseState state = const ExerciseState.completed(),
}) {
  final plannedSets = [
    for (var i = 0; i < planned; i++)
      WorkoutSet(
        id: 'ws-$i',
        exerciseId: 'ex-0',
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
  ];
  final exercise = Exercise(
    id: 'ex-0',
    exerciseGroupId: 'g-0',
    position: 0,
    name: 'Bench Press',
    measurementType: const MeasurementType.repBased(),
    metadata: const ExerciseMetadata(),
    sets: plannedSets,
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
    workoutDayId: 'wd-1',
    snapshot: snapshot,
    sessionExercises: [
      SessionExercise(
        id: 'sx-0',
        sessionId: 'session-1',
        position: 0,
        plannedExerciseIdInSnapshot: 'ex-0',
        state: state,
        executedSets: [
          for (var i = 0; i < actual.length; i++)
            ExecutedSet(
              id: 'es-$i',
              sessionExerciseId: 'sx-0',
              position: i,
              measurementType: const MeasurementType.repBased(),
              actualValues: ActualSetValues.repBased(
                weightKg: actual[i].$1,
                reps: actual[i].$2,
              ),
              plannedSetIdInSnapshot: i < planned ? 'ws-$i' : null,
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
  group('SessionExportFormatter extra sets beyond plan', () {
    test('lists every logged set, including the beyond-plan ones', () {
      // Planned 1 set; logged 2 (one extra). Distinct values force per-set
      // rows so each logged set is independently visible in the export.
      final session = _sessionWith(
        planned: 1,
        actual: const [(100, 5), (102.5, 5)],
      );

      final out = SessionExportFormatter.format(session);

      // The planned summary still reflects the single planned set.
      expect(out, contains('Plan: 100kg 1 × 5'));
      // Both logged sets — planned and beyond-plan — appear under Done.
      expect(out, contains('100kg × 5'));
      expect(out, contains('102.5kg × 5'));
    });

    test('an exercise with extra sets still reads completed (no partial/skip '
        'suffix on the header)', () {
      final session = _sessionWith(
        planned: 1,
        actual: const [(100, 5), (102.5, 5)],
      );

      final out = SessionExportFormatter.format(session);
      final headerLine = out
          .split('\n')
          .firstWhere((l) => l.contains('Bench Press'));

      expect(headerLine.trim(), 'Bench Press');
      expect(out, isNot(contains('(skipped)')));
      expect(out, isNot(contains('sets)')));
    });

    test(
      'uniform extra sets collapse into the count (2 done vs 1 planned)',
      () {
        // Identical values collapse to one Done line whose count includes the
        // extra set — the plan line shows 1, Done shows 2.
        final session = _sessionWith(
          planned: 1,
          actual: const [(100, 5), (100, 5)],
        );

        final out = SessionExportFormatter.format(session);
        expect(out, contains('Plan: 100kg 1 × 5'));
        expect(out, contains('Done: 100kg 2 × 5'));
      },
    );
  });
}
