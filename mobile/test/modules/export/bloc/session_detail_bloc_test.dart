import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/session_detail_bloc.dart';
import 'package:zamaj/modules/export/bloc/session_detail_state.dart';

import '../../../support/fake_session_repository.dart';

Session _session({required bool isDeload}) {
  final t = DateTime.utc(2026, 5, 12);
  final day = WorkoutDay(
    id: 'wd',
    programId: 'p',
    name: 'Upper A',
    exerciseGroups: const [],
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
  return Session(
    id: 's1',
    workoutDayId: 'wd',
    snapshot: SessionSnapshot.capture(
      workoutDay: day,
      capturedAt: t,
      schemaVersion: 1,
    ),
    sessionExercises: const [],
    notes: const [],
    extraWork: const [],
    startedAt: t,
    endedAt: t.add(const Duration(hours: 1)),
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
    isDeload: isDeload,
  );
}

SessionDetailBloc _bloc(Session session) {
  final clock = Clock.fixed(DateTime.utc(2026, 5, 12, 12));
  final repo = FakeSessionRepository(clock: clock);
  return SessionDetailBloc(
    session: session,
    sessionRepository: repo,
    engine: SessionFlowEngine(repository: repo),
    clock: clock,
  );
}

void main() {
  group('SessionDetailLoaded.isDeload', () {
    test('reports true for a deload session', () {
      final bloc = _bloc(_session(isDeload: true));
      addTearDown(bloc.close);
      expect((bloc.state as SessionDetailLoaded).isDeload, isTrue);
    });

    test('reports false for a normal session', () {
      final bloc = _bloc(_session(isDeload: false));
      addTearDown(bloc.close);
      expect((bloc.state as SessionDetailLoaded).isDeload, isFalse);
    });
  });
}
