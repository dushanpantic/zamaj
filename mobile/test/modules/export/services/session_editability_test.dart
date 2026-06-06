import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/services/session_editability.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';

void main() {
  group('SessionEditability.canEditValues', () {
    final referenceNow = DateTime.utc(2026, 5, 15, 12);
    final window = CurrentWeekWindow.compute(referenceNow);

    test('is true for a session that ended inside the current week', () {
      final session = _session(endedAt: DateTime.utc(2026, 5, 13, 18));
      expect(SessionEditability.canEditValues(session, window), isTrue);
    });

    test('is false for a session that ended in a previous week', () {
      final session = _session(endedAt: DateTime.utc(2026, 4, 20, 18));
      expect(SessionEditability.canEditValues(session, window), isFalse);
    });

    test('is false for an in-progress session (null endedAt)', () {
      final session = _session(endedAt: null);
      expect(SessionEditability.canEditValues(session, window), isFalse);
    });
  });
}

Session _session({required DateTime? endedAt}) {
  final t = DateTime.utc(2026, 5, 12);
  final workoutDay = WorkoutDay(
    id: 'wd-1',
    programId: 'p-1',
    name: 'Upper A',
    exerciseGroups: const [],
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
  return Session(
    id: 's1',
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
