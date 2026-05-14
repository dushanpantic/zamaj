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
                    plannedValues: const PlannedSetValues.repBased(
                      weightKg: 100,
                      reps: 8,
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

  Future<String> startAndGetSessionId(FakeSessionRepository repo) async {
    repo.seedWorkoutDay(buildDay());
    final session = await repo.startSession(workoutDayId: 'wd-1');
    return session.id;
  }

  group('FocusModeBloc lifecycle', () {
    test('opening with an unknown session emits NotFound', () async {
      final s = setup();
      addTearDown(s.bloc.close);

      s.bloc.add(const FocusModeOpened('missing'));
      final terminal = await waitFor<FocusModeState>(
        s.bloc,
        (st) => st is FocusModeNotFound || st is FocusModeReady,
      );
      expect(terminal, isA<FocusModeNotFound>());
    });

    test(
      'opening with a valid session emits Ready at the first cursor',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        final sessionId = await startAndGetSessionId(s.repo);

        s.bloc.add(FocusModeOpened(sessionId));
        final ready = await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady,
        );
        expect(ready.viewModel.displayExerciseName, 'Bench');
        expect(ready.viewModel.currentSetIndex, 0);
        expect(ready.draft, isA<ActualRepBased>());
        expect((ready.draft as ActualRepBased).weightKg, 100);
        expect((ready.draft as ActualRepBased).reps, 8);
        expect(ready.restTimer, isNull);
        expect(ready.undoable, isNull);
      },
    );
  });

  group('draft edits', () {
    test('weight bump uses IncrementRules.weightSteps thresholds', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      final sessionId = await startAndGetSessionId(s.repo);
      s.bloc.add(FocusModeOpened(sessionId));
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      s.bloc.add(const FocusModeWeightBumped(2.5));
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) =>
            st is FocusModeReady &&
            (st.draft as ActualRepBased).weightKg == 102.5,
      );
      expect((after.draft as ActualRepBased).weightKg, 102.5);
    });

    test('reps bump clamps at zero', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      final sessionId = await startAndGetSessionId(s.repo);
      s.bloc.add(FocusModeOpened(sessionId));
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      // Seed reps from the planned value (8), then drop below zero
      s.bloc.add(const FocusModeRepsBumped(-100));
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) => st is FocusModeReady && (st.draft as ActualRepBased).reps == 0,
      );
      expect((after.draft as ActualRepBased).reps, 0);
    });
  });

  group('set completion + undo', () {
    test(
      'completing a set advances the cursor and populates undoable',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        final sessionId = await startAndGetSessionId(s.repo);
        s.bloc.add(FocusModeOpened(sessionId));
        await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

        s.bloc.add(const FocusModeSetCompleted());
        final after = await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady && st.viewModel.currentSetIndex == 1,
        );
        expect(after.undoable, isNotNull);
        expect(after.undoable!.exerciseDisplayName, 'Bench');
        expect(after.viewModel.completedSetsCount, 1);
        expect(after.restTimer, isNotNull);
        expect(after.restTimer!.plannedSeconds, 90);
      },
    );

    test('undo deletes the just-logged set, the cursor goes back, and the '
        'rest timer clears', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      final sessionId = await startAndGetSessionId(s.repo);
      s.bloc.add(FocusModeOpened(sessionId));
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      s.bloc.add(const FocusModeSetCompleted());
      await waitFor<FocusModeReady>(
        s.bloc,
        (st) => st is FocusModeReady && st.undoable != null,
      );

      s.bloc.add(const FocusModeUndoRequested());
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) =>
            st is FocusModeReady &&
            st.viewModel.currentSetIndex == 0 &&
            st.undoable == null &&
            st.mutationInFlight == false,
      );
      expect(after.viewModel.completedSetsCount, 0);
      expect(after.restTimer, isNull);
    });

    test('finishing the last set transitions to WorkoutComplete', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(buildDay(benchSets: 1));
      final session = await s.repo.startSession(workoutDayId: 'wd-1');
      s.bloc.add(FocusModeOpened(session.id));
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      s.bloc.add(const FocusModeSetCompleted());
      final terminal = await waitFor<FocusModeState>(
        s.bloc,
        (st) => st is FocusModeWorkoutComplete,
      );
      expect(terminal, isA<FocusModeWorkoutComplete>());
    });
  });

  group('rest timer', () {
    test(
      'pause + resume preserve elapsed; +15s grows the planned target',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        final sessionId = await startAndGetSessionId(s.repo);
        s.bloc.add(FocusModeOpened(sessionId));
        await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

        s.bloc.add(const FocusModeSetCompleted());
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
