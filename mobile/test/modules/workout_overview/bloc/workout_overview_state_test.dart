import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

void main() {
  final clock = Clock.fixed(DateTime.utc(2025, 1, 1, 12));

  WorkoutDay buildDay() {
    final t = DateTime.utc(2025);
    return WorkoutDay(
      id: 'wd-1',
      programId: 'p-1',
      name: 'Day',
      exerciseGroups: const [],
      createdAt: t,
      updatedAt: t,
      schemaVersion: 1,
    );
  }

  WorkoutOverviewLoaded loadedFor(Session session) => WorkoutOverviewLoaded(
    sessionState: SessionState(
      session: session,
      openTargets: const [],
      isComplete: false,
    ),
    groups: const [],
    expandedExerciseIds: const {},
  );

  group('WorkoutOverviewLoaded edit gating', () {
    test(
      'an active session permits both logging and editing executed sets',
      () async {
        final repo = FakeSessionRepository(clock: clock);
        repo.seedWorkoutDay(buildDay());
        final session = await repo.startSession(workoutDayId: 'wd-1');

        final loaded = loadedFor(session);

        expect(loaded.isEnded, isFalse);
        expect(loaded.canLog, isTrue);
        expect(loaded.canEditExecuted, isTrue);
      },
    );

    test('an ended session blocks logging but still permits editing executed '
        'sets', () async {
      final repo = FakeSessionRepository(clock: clock);
      repo.seedWorkoutDay(buildDay());
      final started = await repo.startSession(workoutDayId: 'wd-1');
      final ended = await repo.endSession(started.id);

      final loaded = loadedFor(ended);

      expect(loaded.isEnded, isTrue);
      expect(loaded.canLog, isFalse);
      expect(loaded.canEditExecuted, isTrue);
    });
  });
}
