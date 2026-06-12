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
    test('counts only exercises in the completed state', () {
      final session = _sessionWithStates(
        id: 's1',
        endedAt: DateTime.utc(2026, 5, 12, 18),
        states: const [
          ExerciseState.completed(),
          ExerciseState.completed(),
          ExerciseState.skipped(),
          ExerciseState.unfinished(),
        ],
      );
      expect(SessionHistory.completedExerciseCount(session), 2);
    });

    test('is zero when no exercises are completed', () {
      final session = _sessionWithStates(
        id: 's1',
        endedAt: DateTime.utc(2026, 5, 12, 18),
        states: const [ExerciseState.skipped(), ExerciseState.unfinished()],
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
