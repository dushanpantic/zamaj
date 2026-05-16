import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';

void main() {
  group('WeekExportFormatter.format', () {
    test('empty week renders explicit placeholder', () {
      final out = WeekExportFormatter.format(
        weekStart: DateTime.utc(2026, 5, 11),
        sessions: const [],
      );
      expect(out, contains('Week of '));
      expect(out, contains('(No completed sessions this week)'));
    });

    test('in-progress sessions are filtered out', () {
      final out = WeekExportFormatter.format(
        weekStart: DateTime.utc(2026, 5, 11),
        sessions: [_session(id: 's1', endedAt: null, name: 'Upper A')],
      );
      expect(out, contains('(No completed sessions this week)'));
      expect(out, isNot(contains('Upper A')));
    });

    test('sessions are emitted in chronological order with divider', () {
      final earlier = _session(
        id: 's-early',
        endedAt: DateTime.utc(2026, 5, 12, 10),
        name: 'Lower A',
      );
      final later = _session(
        id: 's-late',
        endedAt: DateTime.utc(2026, 5, 14, 18),
        name: 'Upper B',
      );
      final out = WeekExportFormatter.format(
        weekStart: DateTime.utc(2026, 5, 11),
        sessions: [later, earlier], // intentionally unsorted
      );
      final lowerIdx = out.indexOf('Lower A');
      final upperIdx = out.indexOf('Upper B');
      expect(lowerIdx, greaterThan(-1));
      expect(upperIdx, greaterThan(lowerIdx));
      // Divider between sessions
      expect(out, contains('─' * 15));
    });

    test('ties on endedAt break deterministically by session id', () {
      final t = DateTime.utc(2026, 5, 12, 10);
      final a = _session(id: 's-a', endedAt: t, name: 'A');
      final b = _session(id: 's-b', endedAt: t, name: 'B');
      final out = WeekExportFormatter.format(
        weekStart: DateTime.utc(2026, 5, 11),
        sessions: [b, a],
      );
      expect(out.indexOf('A'), lessThan(out.indexOf('B')));
    });
  });
}

Session _session({
  required String id,
  required DateTime? endedAt,
  required String name,
}) {
  final t = DateTime.utc(2026, 5, 12);
  final workoutDay = WorkoutDay(
    id: 'wd-$id',
    programId: 'p-1',
    name: name,
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
    sessionExercises: const [],
    notes: const [],
    extraWork: const [],
    startedAt: t,
    endedAt: endedAt,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}
