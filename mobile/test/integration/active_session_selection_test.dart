// Pins AC5: the Drift session repository selects the active session by
// `updatedAt` (most recently worked-on), not by `startedAt`. Two in-progress
// sessions are created so that the one started *earlier* is the one *updated*
// later; getActiveSession/watchActiveSession must return that later-updated
// session, agreeing with the domain ActiveSessionPolicy.

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/services/active_session_policy.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/in_memory_app_database.dart';

void main() {
  group('DriftSessionRepository active-session selection', () {
    test('orders by updatedAt desc, not startedAt, and agrees with '
        'ActiveSessionPolicy', () async {
      final db = makeInMemoryDatabase();
      try {
        final programRepo = DriftProgramRepository(db: db);
        final program = await programRepo.createProgram(name: 'P');
        final workoutDay = await programRepo.createWorkoutDay(
          programId: program.id,
          name: 'D',
        );

        final t1 = DateTime.utc(2025, 1, 1, 10);
        final t2 = DateTime.utc(2025, 1, 1, 11);
        final t3 = DateTime.utc(2025, 1, 1, 12);

        DriftSessionRepository repoAt(DateTime when) => DriftSessionRepository(
          db: db,
          programRepository: programRepo,
          clock: Clock.fixed(when),
        );

        // A starts first (earliest startedAt).
        final sessionA = await repoAt(
          t1,
        ).startSession(workoutDayId: workoutDay.id);
        // B starts later (latest startedAt).
        await repoAt(t2).startSession(workoutDayId: workoutDay.id);
        // Touch A last so it has the latest updatedAt despite the earliest
        // startedAt — this is exactly the case where startedAt ordering and
        // updatedAt ordering disagree.
        final repoT3 = repoAt(t3);
        await repoT3.addSessionNote(sessionId: sessionA.id, body: 'note');

        final active = await repoT3.getActiveSession();
        expect(active?.id, sessionA.id);

        final watched = await repoT3.watchActiveSession().first;
        expect(watched?.id, sessionA.id);

        final all = await repoT3.listSessionsForWorkoutDay(workoutDay.id);
        expect(ActiveSessionPolicy.select(all)?.id, active?.id);
      } finally {
        await db.close();
      }
    });
  });
}
