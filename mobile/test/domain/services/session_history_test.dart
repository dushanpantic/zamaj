import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  final week = TrainingWeek.compute(DateTime.utc(2026, 5, 15, 12));

  group('SessionHistory.completedNewestFirst', () {
    test('drops in-progress sessions', () {
      final result = SessionHistory.completedNewestFirst([
        _session(id: 'open', endedAt: null),
        _session(id: 'done', endedAt: DateTime.utc(2026, 5, 12, 18)),
      ]);
      expect(result.map((s) => s.id).toList(), ['done']);
    });

    test('orders newest-first by endedAt, breaking ties by id descending', () {
      final t = DateTime.utc(2026, 5, 12, 18);
      final result = SessionHistory.completedNewestFirst([
        _session(id: 's-a', endedAt: t),
        _session(id: 's-b', endedAt: t),
        _session(id: 's-c', endedAt: t.add(const Duration(hours: 1))),
      ]);
      expect(result.map((s) => s.id).toList(), ['s-c', 's-b', 's-a']);
    });

    test('is independent of input order', () {
      final t = DateTime.utc(2026, 5, 12, 18);
      final a = _session(id: 's-a', endedAt: t);
      final c = _session(id: 's-c', endedAt: t.add(const Duration(hours: 1)));
      expect(
        SessionHistory.completedNewestFirst([a, c]).map((s) => s.id).toList(),
        ['s-c', 's-a'],
      );
      expect(
        SessionHistory.completedNewestFirst([c, a]).map((s) => s.id).toList(),
        ['s-c', 's-a'],
      );
    });
  });

  group('SessionHistory.completedExerciseCount', () {
    test('counts only exercises whose logged sets meet the planned quota', () {
      // 4 of 6 met their planned sets; 1 was ended at 2 of 4; 1 was skipped
      // with no sets — derived count is 4, regardless of stored discriminators.
      final session = _sessionWithExerciseSpecs(
        id: 's1',
        endedAt: DateTime.utc(2026, 5, 12, 18),
        specs: const [
          (state: ExerciseState.completed(), executed: 4, planned: 4),
          (state: ExerciseState.completed(), executed: 4, planned: 4),
          (state: ExerciseState.completed(), executed: 4, planned: 4),
          (state: ExerciseState.completed(), executed: 4, planned: 4),
          (state: ExerciseState.skipped(), executed: 2, planned: 4),
          (state: ExerciseState.skipped(), executed: 0, planned: 4),
        ],
      );
      expect(SessionHistory.completedExerciseCount(session), 4);
    });

    test('legacy marked-done-early and skipped-with-sets rows do not count', () {
      final session = _sessionWithExerciseSpecs(
        id: 's1',
        endedAt: DateTime.utc(2026, 5, 12, 18),
        specs: const [
          // Quota met → counted.
          (state: ExerciseState.completed(), executed: 4, planned: 4),
          // Legacy "mark done" shape: stored completed but only 2/4 logged →
          // derives to partial, not counted.
          (state: ExerciseState.completed(), executed: 2, planned: 4),
          // Skipped but with sets → partial, not counted.
          (state: ExerciseState.skipped(), executed: 2, planned: 4),
          // Zero-set skip → skipped, not counted.
          (state: ExerciseState.skipped(), executed: 0, planned: 4),
        ],
      );
      expect(SessionHistory.completedExerciseCount(session), 1);
    });

    test('is zero when no exercise meets its planned quota', () {
      final session = _sessionWithExerciseSpecs(
        id: 's1',
        endedAt: DateTime.utc(2026, 5, 12, 18),
        specs: const [
          (state: ExerciseState.skipped(), executed: 0, planned: 4),
          (state: ExerciseState.unfinished(), executed: 1, planned: 4),
        ],
      );
      expect(SessionHistory.completedExerciseCount(session), 0);
    });
  });

  group('SessionHistory.completedCount', () {
    test('ignores in-progress sessions', () {
      final result = SessionHistory.completedCount([
        _session(id: 'open', endedAt: null),
        _session(id: 'd1', endedAt: DateTime.utc(2026, 5, 12)),
        _session(id: 'd2', endedAt: DateTime.utc(2026, 4, 1)),
      ]);
      expect(result, 2);
    });
  });

  group('SessionHistory.completedCountInWeek', () {
    test('counts only completed sessions whose end falls inside the week', () {
      final result = SessionHistory.completedCountInWeek([
        _session(id: 'in', endedAt: DateTime.utc(2026, 5, 13, 18)),
        _session(id: 'out', endedAt: DateTime.utc(2026, 4, 20, 18)),
        _session(id: 'open', endedAt: null),
      ], week);
      expect(result, 1);
    });

    test('end == week.start is inside; end == week.end is outside', () {
      final result = SessionHistory.completedCountInWeek([
        _session(id: 'start', endedAt: week.start),
        _session(id: 'end', endedAt: week.end),
      ], week);
      expect(result, 1);
    });
  });

  group('SessionHistory.lastCompletedAt', () {
    test('is the latest end among completed sessions', () {
      final result = SessionHistory.lastCompletedAt([
        _session(id: 's1', endedAt: DateTime.utc(2026, 5, 10)),
        _session(id: 's2', endedAt: DateTime.utc(2026, 5, 14)),
        _session(id: 's3', endedAt: DateTime.utc(2026, 5, 12)),
        _session(id: 'open', endedAt: null),
      ]);
      expect(result, DateTime.utc(2026, 5, 14));
    });

    test('is null when there are no completed sessions', () {
      expect(
        SessionHistory.lastCompletedAt([_session(id: 'open', endedAt: null)]),
        isNull,
      );
      expect(SessionHistory.lastCompletedAt([]), isNull);
    });
  });
}

Session _session({required String id, required DateTime? endedAt}) {
  return _sessionWithStates(id: id, endedAt: endedAt, states: const []);
}

/// Builds an ended session whose snapshot carries a real planned exercise per
/// spec (rep-based, [_ExSpec.planned] sets) and whose session exercise logs
/// [_ExSpec.executed] sets — so derived-outcome counting has the planned counts
/// it needs.
typedef _ExSpec = ({ExerciseState state, int executed, int planned});

Session _sessionWithExerciseSpecs({
  required String id,
  required DateTime? endedAt,
  required List<_ExSpec> specs,
}) {
  final t = DateTime.utc(2026, 5, 12);
  const mt = MeasurementType.repBased();
  final plannedValues = PlannedSetValues.repBased(
    weightKg: 100,
    repTarget: RepTarget.fixed(reps: 5),
  );
  const actualValues = ActualSetValues.repBased(weightKg: 100, reps: 5);

  final groups = <ExerciseGroup>[
    for (var i = 0; i < specs.length; i++)
      ExerciseGroup(
        id: 'g-$id-$i',
        workoutDayId: 'wd-$id',
        position: i,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          Exercise(
            id: 'ex-$i',
            exerciseGroupId: 'g-$id-$i',
            position: 0,
            name: 'Ex $i',
            measurementType: mt,
            metadata: ExerciseMetadata.empty,
            sets: [
              for (var j = 0; j < specs[i].planned; j++)
                WorkoutSet(
                  id: 'ws-$id-$i-$j',
                  exerciseId: 'ex-$i',
                  position: j,
                  measurementType: mt,
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
  ];

  final workoutDay = WorkoutDay(
    id: 'wd-$id',
    programId: 'p-1',
    name: 'Upper A',
    exerciseGroups: groups,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );

  return Session(
    id: id,
    workoutDayId: workoutDay.id,
    snapshot: SessionSnapshot.capture(
      workoutDay: workoutDay,
      capturedAt: t,
      schemaVersion: 1,
    ),
    sessionExercises: [
      for (var i = 0; i < specs.length; i++)
        SessionExercise(
          id: 'sx-$id-$i',
          sessionId: id,
          position: i,
          plannedExerciseIdInSnapshot: 'ex-$i',
          state: specs[i].state,
          executedSets: [
            for (var j = 0; j < specs[i].executed; j++)
              ExecutedSet(
                id: 'es-$id-$i-$j',
                sessionExerciseId: 'sx-$id-$i',
                position: j,
                measurementType: mt,
                actualValues: actualValues,
                plannedSetIdInSnapshot: null,
                completedAt: t,
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
    notes: const [],
    extraWork: const [],
    startedAt: t,
    endedAt: endedAt,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}

Session _sessionWithStates({
  required String id,
  required DateTime? endedAt,
  required List<ExerciseState> states,
}) {
  final t = DateTime.utc(2026, 5, 12);
  final workoutDay = WorkoutDay(
    id: 'wd-$id',
    programId: 'p-1',
    name: 'Upper A',
    exerciseGroups: const [],
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
  return Session(
    id: id,
    workoutDayId: workoutDay.id,
    snapshot: SessionSnapshot.capture(
      workoutDay: workoutDay,
      capturedAt: t,
      schemaVersion: 1,
    ),
    sessionExercises: [
      for (var i = 0; i < states.length; i++)
        SessionExercise(
          id: 'sx-$id-$i',
          sessionId: id,
          position: i,
          plannedExerciseIdInSnapshot: 'ex-$i',
          state: states[i],
          executedSets: const [],
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
    ],
    notes: const [],
    extraWork: const [],
    startedAt: t,
    endedAt: endedAt,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}
