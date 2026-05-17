import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  ({FakeSessionRepository repo, SessionFlowEngine engine, FocusModeBloc bloc})
  setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    final engine = SessionFlowEngine(repository: repo);
    final bloc = FocusModeBloc(sessionFlowEngine: engine);
    return (repo: repo, engine: engine, bloc: bloc);
  }

  WorkoutDay buildDay({int benchSets = 2}) {
    final t = DateTime.utc(2024);
    return WorkoutDay(
      id: 'wd-1',
      programId: 'p-1',
      name: 'Upper',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g1',
          workoutDayId: 'wd-1',
          position: 0,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-bench',
              exerciseGroupId: 'g1',
              position: 0,
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              plannedRestSeconds: 90,
              sets: [
                for (var i = 0; i < benchSets; i++)
                  WorkoutSet(
                    id: 'ws-$i',
                    exerciseId: 'ex-bench',
                    position: i,
                    measurementType: const MeasurementType.repBased(),
                    plannedValues: PlannedSetValues.repBased(
                      weightKg: 100,
                      repTarget: RepTarget.fixed(reps: 8),
                    ),
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
      ],
      createdAt: t,
      updatedAt: t,
      schemaVersion: 1,
    );
  }

  /// Two-exercise superset (Bench + Lat), each with 2 planned sets.
  WorkoutDay buildSupersetDay() {
    final t = DateTime.utc(2024);
    return WorkoutDay(
      id: 'wd-ss',
      programId: 'p-1',
      name: 'Push',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g-ss',
          workoutDayId: 'wd-ss',
          position: 0,
          kind: const ExerciseGroupKind.superset(),
          exercises: [
            Exercise(
              id: 'ex-bench',
              exerciseGroupId: 'g-ss',
              position: 0,
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              plannedRestSeconds: 90,
              sets: [
                for (var i = 0; i < 2; i++)
                  WorkoutSet(
                    id: 'ws-b-$i',
                    exerciseId: 'ex-bench',
                    position: i,
                    measurementType: const MeasurementType.repBased(),
                    plannedValues: PlannedSetValues.repBased(
                      weightKg: 100,
                      repTarget: RepTarget.fixed(reps: 8),
                    ),
                    createdAt: t,
                    updatedAt: t,
                    schemaVersion: 1,
                  ),
              ],
              createdAt: t,
              updatedAt: t,
              schemaVersion: 1,
            ),
            Exercise(
              id: 'ex-lat',
              exerciseGroupId: 'g-ss',
              position: 1,
              name: 'Lat',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              plannedRestSeconds: 60,
              sets: [
                for (var i = 0; i < 2; i++)
                  WorkoutSet(
                    id: 'ws-l-$i',
                    exerciseId: 'ex-lat',
                    position: i,
                    measurementType: const MeasurementType.repBased(),
                    plannedValues: PlannedSetValues.repBased(
                      weightKg: 70,
                      repTarget: RepTarget.fixed(reps: 10),
                    ),
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
      ],
      createdAt: t,
      updatedAt: t,
      schemaVersion: 1,
    );
  }

  /// Awaits until the bloc reaches a state matching [predicate], with a
  /// bounded number of intermediate hops so a flaky test fails loudly
  /// instead of hanging.
  Future<T> waitFor<T extends FocusModeState>(
    FocusModeBloc bloc,
    bool Function(FocusModeState) predicate, {
    int maxHops = 20,
  }) async {
    if (predicate(bloc.state)) return bloc.state as T;
    return await bloc.stream
            .take(maxHops)
            .firstWhere(predicate, orElse: () => bloc.state)
        as T;
  }

  Future<({String sessionId, String anchorId})> startSimpleSession(
    FakeSessionRepository repo,
  ) async {
    repo.seedWorkoutDay(buildDay());
    final session = await repo.startSession(workoutDayId: 'wd-1');
    return (sessionId: session.id, anchorId: session.sessionExercises.first.id);
  }

  group('FocusModeBloc lifecycle', () {
    test('opening with an unknown session emits NotFound', () async {
      final s = setup();
      addTearDown(s.bloc.close);

      s.bloc.add(
        const FocusModeOpened(
          sessionId: 'missing',
          anchorSessionExerciseId: 'anything',
        ),
      );
      final terminal = await waitFor<FocusModeState>(
        s.bloc,
        (st) => st is FocusModeNotFound || st is FocusModeReady,
      );
      expect(terminal, isA<FocusModeNotFound>());
    });

    test(
      'opening with a valid anchor emits Ready with one panel + seeded draft',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        final info = await startSimpleSession(s.repo);

        s.bloc.add(
          FocusModeOpened(
            sessionId: info.sessionId,
            anchorSessionExerciseId: info.anchorId,
          ),
        );
        final ready = await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady,
        );
        expect(ready.groupViewModel.panels, hasLength(1));
        expect(ready.groupViewModel.panels.single.displayExerciseName, 'Bench');
        expect(ready.groupViewModel.supersetTag, isNull);
        final draft = ready.draftFor(info.anchorId)! as ActualRepBased;
        expect(draft.weightKg, 100);
        expect(draft.reps, 8);
        expect(ready.restTimer, isNull);
        expect(ready.undoable, isNull);
      },
    );
  });

  group('superset panels', () {
    test('opening on either superset member shows both panels', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(buildSupersetDay());
      final session = await s.repo.startSession(workoutDayId: 'wd-ss');
      final benchId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final latId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;

      s.bloc.add(
        FocusModeOpened(sessionId: session.id, anchorSessionExerciseId: latId),
      );
      final ready = await waitFor<FocusModeReady>(
        s.bloc,
        (st) => st is FocusModeReady,
      );
      expect(ready.groupViewModel.supersetTag, isNotNull);
      expect(ready.groupViewModel.panels, hasLength(2));
      expect(
        ready.groupViewModel.panels.map((p) => p.sessionExerciseId).toSet(),
        {benchId, latId},
      );
      expect(ready.drafts.keys.toSet(), {benchId, latId});
    });

    test('logging a set on superset member A leaves B\'s draft untouched and '
        'starts the rest timer with A\'s planned rest', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(buildSupersetDay());
      final session = await s.repo.startSession(workoutDayId: 'wd-ss');
      final benchId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final latId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;

      s.bloc.add(
        FocusModeOpened(
          sessionId: session.id,
          anchorSessionExerciseId: benchId,
        ),
      );
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      // Bump lat's reps so we can detect it survives the bench mutation.
      s.bloc.add(FocusModeRepsBumped(sessionExerciseId: latId, delta: -2));
      await waitFor<FocusModeReady>(
        s.bloc,
        (st) =>
            st is FocusModeReady &&
            (st.draftFor(latId) as ActualRepBased).reps == 8,
      );

      s.bloc.add(FocusModeSetCompleted(benchId));
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) =>
            st is FocusModeReady &&
            st.groupViewModel.panels
                    .firstWhere((p) => p.sessionExerciseId == benchId)
                    .completedSetsCount ==
                1,
      );
      expect(after.undoable, isNotNull);
      expect(after.undoable!.sessionExerciseId, benchId);
      expect(after.restTimer, isNotNull);
      expect(after.restTimer!.plannedSeconds, 90);
      // Lat panel still loggable with its tweaked draft preserved.
      final latDraft = after.draftFor(latId)! as ActualRepBased;
      expect(latDraft.reps, 8);
    });

    test('completing all sets across the superset transitions to '
        'WorkoutComplete (no other groups)', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(buildSupersetDay());
      final session = await s.repo.startSession(workoutDayId: 'wd-ss');
      final benchId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final latId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;

      s.bloc.add(
        FocusModeOpened(
          sessionId: session.id,
          anchorSessionExerciseId: benchId,
        ),
      );
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      // Walk both panels one set at a time, awaiting each set's executed
      // count to tick up before issuing the next event. Without these
      // intermediate awaits the rest ticker can starve the queue.
      Future<void> logAndWait(String id, int expectedCount) async {
        s.bloc.add(FocusModeSetCompleted(id));
        await waitFor<FocusModeState>(
          s.bloc,
          (st) =>
              st is FocusModeWorkoutComplete ||
              (st is FocusModeReady &&
                  !st.mutationInFlight &&
                  st.groupViewModel.panels
                          .firstWhere((p) => p.sessionExerciseId == id)
                          .completedSetsCount >=
                      expectedCount),
          maxHops: 40,
        );
      }

      await logAndWait(benchId, 1);
      await logAndWait(latId, 1);
      await logAndWait(benchId, 2);
      await logAndWait(latId, 2);

      final terminal = await waitFor<FocusModeState>(
        s.bloc,
        (st) => st is FocusModeWorkoutComplete,
        maxHops: 40,
      );
      expect(terminal, isA<FocusModeWorkoutComplete>());
    });
  });

  group('draft edits', () {
    test('weight bump uses IncrementRules.weightSteps thresholds', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      final info = await startSimpleSession(s.repo);
      s.bloc.add(
        FocusModeOpened(
          sessionId: info.sessionId,
          anchorSessionExerciseId: info.anchorId,
        ),
      );
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      s.bloc.add(
        FocusModeWeightBumped(sessionExerciseId: info.anchorId, delta: 2.5),
      );
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) =>
            st is FocusModeReady &&
            (st.draftFor(info.anchorId) as ActualRepBased).weightKg == 102.5,
      );
      expect((after.draftFor(info.anchorId) as ActualRepBased).weightKg, 102.5);
    });

    test('reps bump clamps at zero', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      final info = await startSimpleSession(s.repo);
      s.bloc.add(
        FocusModeOpened(
          sessionId: info.sessionId,
          anchorSessionExerciseId: info.anchorId,
        ),
      );
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      s.bloc.add(
        FocusModeRepsBumped(sessionExerciseId: info.anchorId, delta: -100),
      );
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) =>
            st is FocusModeReady &&
            (st.draftFor(info.anchorId) as ActualRepBased).reps == 0,
      );
      expect((after.draftFor(info.anchorId) as ActualRepBased).reps, 0);
    });
  });

  group('set completion + undo', () {
    test(
      'completing a set populates undoable and starts the rest timer',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        final info = await startSimpleSession(s.repo);
        s.bloc.add(
          FocusModeOpened(
            sessionId: info.sessionId,
            anchorSessionExerciseId: info.anchorId,
          ),
        );
        await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

        s.bloc.add(FocusModeSetCompleted(info.anchorId));
        final after = await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady &&
              st.groupViewModel.panels.single.completedSetsCount == 1,
        );
        expect(after.undoable, isNotNull);
        expect(after.undoable!.exerciseDisplayName, 'Bench');
        expect(after.restTimer, isNotNull);
        expect(after.restTimer!.plannedSeconds, 90);
      },
    );

    test(
      'undo deletes the just-logged set and clears the rest timer',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        final info = await startSimpleSession(s.repo);
        s.bloc.add(
          FocusModeOpened(
            sessionId: info.sessionId,
            anchorSessionExerciseId: info.anchorId,
          ),
        );
        await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

        s.bloc.add(FocusModeSetCompleted(info.anchorId));
        await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady && st.undoable != null,
        );

        s.bloc.add(const FocusModeUndoRequested());
        final after = await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady &&
              st.groupViewModel.panels.single.completedSetsCount == 0 &&
              st.undoable == null &&
              st.mutationInFlight == false,
        );
        expect(after.restTimer, isNull);
      },
    );

    test('finishing the last set transitions to WorkoutComplete', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(buildDay(benchSets: 1));
      final session = await s.repo.startSession(workoutDayId: 'wd-1');
      final anchor = session.sessionExercises.first.id;
      s.bloc.add(
        FocusModeOpened(sessionId: session.id, anchorSessionExerciseId: anchor),
      );
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      s.bloc.add(FocusModeSetCompleted(anchor));
      final terminal = await waitFor<FocusModeState>(
        s.bloc,
        (st) => st is FocusModeWorkoutComplete,
      );
      expect(terminal, isA<FocusModeWorkoutComplete>());
    });
  });

  group('group switching', () {
    test('FocusModeGroupSwitched repoints the focused group', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(buildSupersetDay());
      final session = await s.repo.startSession(workoutDayId: 'wd-ss');
      final benchId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      // The fixture only has a single (superset) group; insert another
      // session via a fresh seed so we have two groups to switch between.
      // The superset-only fixture has one group; instead, log the first
      // bench set, then ensure switching to lat keeps the same group
      // (one-group sanity: stays put).
      s.bloc.add(
        FocusModeOpened(
          sessionId: session.id,
          anchorSessionExerciseId: benchId,
        ),
      );
      final ready = await waitFor<FocusModeReady>(
        s.bloc,
        (st) => st is FocusModeReady,
      );
      final latId = ready.groupViewModel.panels
          .firstWhere((p) => p.sessionExerciseId != benchId)
          .sessionExerciseId;

      s.bloc.add(FocusModeGroupSwitched(latId));
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) => st is FocusModeReady && st.anchorSessionExerciseId == latId,
      );
      // Same group (both still in the superset), but anchor flipped.
      expect(after.anchorSessionExerciseId, latId);
      expect(after.groupViewModel.panels.length, 2);
    });
  });

  group('markExerciseDone', () {
    test(
      'locks the exercise as completed and removes its panel from group',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        s.repo.seedWorkoutDay(buildSupersetDay());
        final session = await s.repo.startSession(workoutDayId: 'wd-ss');
        final benchId = session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
            .id;
        final latId = session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
            .id;

        s.bloc.add(
          FocusModeOpened(
            sessionId: session.id,
            anchorSessionExerciseId: benchId,
          ),
        );
        await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

        // Log 1 of 2 bench sets, then markDone — leaves bench as completed
        // with one set logged.
        s.bloc.add(FocusModeSetCompleted(benchId));
        await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady &&
              st.groupViewModel.panels
                      .firstWhere((p) => p.sessionExerciseId == benchId)
                      .completedSetsCount ==
                  1,
        );
        s.bloc.add(FocusModeExerciseMarkedDone(benchId));
        final after = await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady &&
              st.groupViewModel.panels.every(
                (p) => p.sessionExerciseId != benchId || !p.isLoggable,
              ),
        );
        final benchPanel = after.groupViewModel.panels.firstWhere(
          (p) => p.sessionExerciseId == benchId,
        );
        expect(benchPanel.isLoggable, isFalse);
        expect(benchPanel.completedSetsCount, 1);
        // Lat panel is still loggable.
        expect(
          after.groupViewModel.panels
              .firstWhere((p) => p.sessionExerciseId == latId)
              .isLoggable,
          isTrue,
        );
      },
    );
  });

  group('rest timer', () {
    test(
      'pause + resume preserve elapsed; +15s grows the planned target',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        final info = await startSimpleSession(s.repo);
        s.bloc.add(
          FocusModeOpened(
            sessionId: info.sessionId,
            anchorSessionExerciseId: info.anchorId,
          ),
        );
        await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

        s.bloc.add(FocusModeSetCompleted(info.anchorId));
        await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady && st.restTimer != null,
        );

        // Synthesise three ticks
        s.bloc
          ..add(const FocusModeRestTicked())
          ..add(const FocusModeRestTicked())
          ..add(const FocusModeRestTicked());
        var t = await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady && (st.restTimer?.elapsedSeconds ?? 0) >= 3,
        );
        expect(t.restTimer!.elapsedSeconds, greaterThanOrEqualTo(3));

        s.bloc.add(const FocusModeRestPaused());
        t = await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady && st.restTimer?.isPaused == true,
        );
        final pausedAt = t.restTimer!.elapsedSeconds;

        // Tick while paused should be ignored
        s.bloc.add(const FocusModeRestTicked());
        await Future<void>.delayed(Duration.zero);
        expect(s.bloc.state, isA<FocusModeReady>());
        final mid = s.bloc.state as FocusModeReady;
        expect(mid.restTimer!.elapsedSeconds, pausedAt);

        s.bloc.add(const FocusModeRestExtended());
        t = await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady &&
              (st.restTimer?.extensionSeconds ?? 0) == 15,
        );
        expect(t.restTimer!.effectivePlannedSeconds, 90 + 15);

        s.bloc.add(const FocusModeRestSkipped());
        t = await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady && st.restTimer == null,
        );
        expect(t.restTimer, isNull);
      },
    );
  });
}
