import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/services/session_history_assembler.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';

void main() {
  group('SessionHistoryAssembler.assemble', () {
    final referenceNow = DateTime.utc(2026, 5, 15, 12);
    final window = CurrentWeekWindow.compute(referenceNow);

    test('filters out in-progress sessions', () {
      final items = SessionHistoryAssembler.assemble(
        sessions: [
          _session(id: 's1', endedAt: null),
          _session(id: 's2', endedAt: DateTime.utc(2026, 5, 12, 18)),
        ],
        window: window,
      );
      expect(items, hasLength(1));
      expect(items.single.sessionId, 's2');
    });

    test('orders newest-first by endedAt with id tiebreaker', () {
      final t = DateTime.utc(2026, 5, 12, 18);
      final items = SessionHistoryAssembler.assemble(
        sessions: [
          _session(id: 's-a', endedAt: t),
          _session(id: 's-b', endedAt: t),
          _session(id: 's-c', endedAt: t.add(const Duration(hours: 1))),
        ],
        window: window,
      );
      expect(items.map((i) => i.sessionId).toList(), ['s-c', 's-b', 's-a']);
    });

    test('flags isInThisWeek based on window membership', () {
      final inWeek = DateTime.utc(2026, 5, 13, 18);
      final earlier = DateTime.utc(2026, 4, 20, 18);
      final items = SessionHistoryAssembler.assemble(
        sessions: [
          _session(id: 'in', endedAt: inWeek),
          _session(id: 'out', endedAt: earlier),
        ],
        window: window,
      );
      final inItem = items.firstWhere((i) => i.sessionId == 'in');
      final outItem = items.firstWhere((i) => i.sessionId == 'out');
      expect(inItem.isInThisWeek, isTrue);
      expect(outItem.isInThisWeek, isFalse);
    });

    test('counts completed exercises only', () {
      final t = DateTime.utc(2026, 5, 12, 18);
      final session = _sessionWithStates(
        id: 's1',
        endedAt: t,
        states: const [
          ExerciseState.completed(),
          ExerciseState.completed(),
          ExerciseState.skipped(),
          ExerciseState.unfinished(),
        ],
      );
      final items = SessionHistoryAssembler.assemble(
        sessions: [session],
        window: window,
      );
      expect(items.single.completedExerciseCount, 2);
      expect(items.single.totalExerciseCount, 4);
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
