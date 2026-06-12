import 'dart:async';

import 'package:clock/clock.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';

import '../../../support/fake_session_repository.dart';

/// Repo whose [completeSet] blocks on a test-controlled gate so a test can
/// interleave another event (a concurrent draft edit) while the mutation is
/// in flight.
class _GatedCompleteSetRepo extends FakeSessionRepository {
  _GatedCompleteSetRepo({required super.clock});

  Completer<void>? completeSetGate;

  @override
  Future<Session> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  }) async {
    final gate = completeSetGate;
    if (gate != null) await gate.future;
    return super.completeSet(
      sessionExerciseId: sessionExerciseId,
      actualValues: actualValues,
      plannedSetIdInSnapshot: plannedSetIdInSnapshot,
    );
  }
}

/// Repo whose [deleteExecutedSet] always fails with a transient domain error,
/// so a test can exercise the failed-undo path.
class _ThrowingDeleteRepo extends FakeSessionRepository {
  _ThrowingDeleteRepo({required super.clock});

  @override
  Future<Session> deleteExecutedSet({required String executedSetId}) async {
    throw const ValidationError(
      entityId: 'x',
      invariant: 'transient',
      message: 'transient failure',
    );
  }
}

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

  WorkoutDay buildDay({int benchSets = 2, int? plannedRestSeconds = 90}) {
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
              plannedRestSeconds: plannedRestSeconds,
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

  /// Superset of a rep-based Bench (no planned rest) and a time-based Plank,
  /// so a countdown can run on one member while a set is logged on the other.
  /// Bench has no planned rest so logging it starts no rest ticker — the only
  /// periodic timer in play is the stopwatch ticker under test.
  WorkoutDay buildTimeSupersetDay() {
    final t = DateTime.utc(2024);
    return WorkoutDay(
      id: 'wd-tss',
      programId: 'p-1',
      name: 'Mixed',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g-tss',
          workoutDayId: 'wd-tss',
          position: 0,
          kind: const ExerciseGroupKind.superset(),
          exercises: [
            Exercise(
              id: 'ex-bench',
              exerciseGroupId: 'g-tss',
              position: 0,
              name: 'Bench',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              plannedRestSeconds: null,
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
              id: 'ex-plank',
              exerciseGroupId: 'g-tss',
              position: 1,
              name: 'Plank',
              measurementType: const MeasurementType.timeBased(),
              metadata: ExerciseMetadata.empty,
              plannedRestSeconds: null,
              sets: [
                for (var i = 0; i < 2; i++)
                  WorkoutSet(
                    id: 'ws-p-$i',
                    exerciseId: 'ex-plank',
                    position: i,
                    measurementType: const MeasurementType.timeBased(),
                    plannedValues: const PlannedSetValues.timeBased(
                      durationSeconds: 60,
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

  group('single adaptive end/skip action', () {
    test(
      'ending the focused exercise with logged sets keeps the sets, lands '
      'terminal, and advances focus to the next unfinished exercise',
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

        // Log 1 of 2 bench sets, then "End exercise" — the single adaptive
        // action fires the skip event and must keep the logged set.
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
        s.bloc.add(FocusModeExerciseSkipped(benchId));
        final after = await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady &&
              st.groupViewModel.panels.every(
                (p) => p.sessionExerciseId != benchId,
              ),
        );
        // The stored bench record is terminal but keeps its one logged set —
        // its derived outcome is "partial", not a discarded skip.
        final benchEx = after.sessionState.session.sessionExercises.firstWhere(
          (e) => e.id == benchId,
        );
        expect(benchEx.state, isA<SkippedState>());
        expect(benchEx.executedSets.length, 1);
        // Focus advances to the next unfinished exercise.
        final latPanel = after.groupViewModel.panels.firstWhere(
          (p) => p.sessionExerciseId == latId,
        );
        expect(latPanel.isLoggable, isTrue);
      },
    );
  });

  group('rest timer', () {
    test(
      'ticks accumulate then auto-dismiss when elapsed reaches planned',
      () async {
        final s = setup();
        addTearDown(s.bloc.close);
        s.repo.seedWorkoutDay(buildDay(plannedRestSeconds: 3));
        final session = await s.repo.startSession(workoutDayId: 'wd-1');
        final anchorId = session.sessionExercises.first.id;

        s.bloc.add(
          FocusModeOpened(
            sessionId: session.id,
            anchorSessionExerciseId: anchorId,
          ),
        );
        await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

        s.bloc.add(FocusModeSetCompleted(anchorId));
        var t = await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady && st.restTimer != null,
        );
        expect(t.restTimer!.plannedSeconds, 3);
        expect(t.restTimer!.elapsedSeconds, 0);

        s.bloc.add(const FocusModeRestTicked());
        t = await waitFor<FocusModeReady>(
          s.bloc,
          (st) =>
              st is FocusModeReady && (st.restTimer?.elapsedSeconds ?? 0) == 1,
        );
        expect(t.restTimer!.remainingSeconds, 2);

        // Two more ticks should drive the timer to dismissal — the final tick
        // is the one that "catches up" to plannedSeconds, so the bloc emits
        // restTimer: null instead of an overtime state.
        s.bloc
          ..add(const FocusModeRestTicked())
          ..add(const FocusModeRestTicked());
        t = await waitFor<FocusModeReady>(
          s.bloc,
          (st) => st is FocusModeReady && st.restTimer == null,
        );
        expect(t.restTimer, isNull);
      },
    );

    test('skip clears the timer immediately', () async {
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

      s.bloc.add(const FocusModeRestSkipped());
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) => st is FocusModeReady && st.restTimer == null,
      );
      expect(after.restTimer, isNull);
    });

    test('no timer started when the panel has no planned rest', () async {
      final s = setup();
      addTearDown(s.bloc.close);
      s.repo.seedWorkoutDay(buildDay(plannedRestSeconds: null));
      final session = await s.repo.startSession(workoutDayId: 'wd-1');
      final anchorId = session.sessionExercises.first.id;

      s.bloc.add(
        FocusModeOpened(
          sessionId: session.id,
          anchorSessionExerciseId: anchorId,
        ),
      );
      await waitFor<FocusModeReady>(s.bloc, (st) => st is FocusModeReady);

      s.bloc.add(FocusModeSetCompleted(anchorId));
      final after = await waitFor<FocusModeReady>(
        s.bloc,
        (st) =>
            st is FocusModeReady &&
            st.groupViewModel.panels.single.completedSetsCount == 1,
      );
      expect(after.restTimer, isNull);
    });
  });

  group('mutation correctness', () {
    test('a concurrent draft edit survives a mutation landing', () async {
      final repo = _GatedCompleteSetRepo(clock: fakeClock);
      final engine = SessionFlowEngine(repository: repo);
      final bloc = FocusModeBloc(sessionFlowEngine: engine);
      addTearDown(bloc.close);
      repo.seedWorkoutDay(buildSupersetDay());
      final session = await repo.startSession(workoutDayId: 'wd-ss');
      final benchId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final latId = session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;

      bloc.add(
        FocusModeOpened(
          sessionId: session.id,
          anchorSessionExerciseId: benchId,
        ),
      );
      await waitFor<FocusModeReady>(bloc, (st) => st is FocusModeReady);

      // Hold bench's completeSet so the lat draft edit lands while bench's
      // mutation is still in flight.
      final gate = Completer<void>();
      repo.completeSetGate = gate;

      bloc.add(FocusModeSetCompleted(benchId));
      await waitFor<FocusModeReady>(
        bloc,
        (st) => st is FocusModeReady && st.mutationInFlight,
      );

      // Concurrent edit on the OTHER panel while bench's set is in flight.
      bloc.add(FocusModeWeightEdited(sessionExerciseId: latId, weightKg: 72.5));
      await waitFor<FocusModeReady>(
        bloc,
        (st) =>
            st is FocusModeReady &&
            (st.draftFor(latId) as ActualRepBased).weightKg == 72.5,
      );

      // Let bench's mutation land; lat's concurrent edit must not be reverted.
      gate.complete();
      final settled = await waitFor<FocusModeReady>(
        bloc,
        (st) =>
            st is FocusModeReady &&
            !st.mutationInFlight &&
            st.groupViewModel.panels
                    .firstWhere((p) => p.sessionExerciseId == benchId)
                    .completedSetsCount ==
                1,
      );
      expect((settled.draftFor(latId)! as ActualRepBased).weightKg, 72.5);
    });

    test('logging a set cancels a countdown ticker on another panel', () {
      fakeAsync((async) {
        final repo = FakeSessionRepository(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo);
        final bloc = FocusModeBloc(sessionFlowEngine: engine);
        repo.seedWorkoutDay(buildTimeSupersetDay());

        late String benchId;
        late String plankId;
        late String sessionId;
        repo.startSession(workoutDayId: 'wd-tss').then((session) {
          sessionId = session.id;
          benchId = session.sessionExercises
              .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
              .id;
          plankId = session.sessionExercises
              .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-plank')
              .id;
        });
        async.flushMicrotasks();

        bloc.add(
          FocusModeOpened(
            sessionId: sessionId,
            anchorSessionExerciseId: benchId,
          ),
        );
        async.flushMicrotasks();
        expect(bloc.state, isA<FocusModeReady>());

        // Start a countdown on the plank panel and let it tick once.
        bloc.add(FocusModeStopwatchStarted(plankId));
        async.flushMicrotasks();
        bloc.add(const FocusModeStopwatchTicked());
        async.flushMicrotasks();
        final running = bloc.state as FocusModeReady;
        expect(running.stopwatch.isRunning, isTrue);
        expect(running.activeStopwatchExerciseId, plankId);
        expect(async.periodicTimerCount, 1);

        // Log a set on the OTHER (bench) panel.
        bloc.add(FocusModeSetCompleted(benchId));
        async.flushMicrotasks();

        final after = bloc.state as FocusModeReady;
        expect(after.stopwatch.isRunning, isFalse);
        expect(after.activeStopwatchExerciseId, isNull);
        // The orphaned countdown ticker must be cancelled: ticker runs iff the
        // emitted stopwatch is running.
        expect(async.periodicTimerCount, 0);

        bloc.close();
        async.flushMicrotasks();
      });
    });

    test(
      'a failed undo keeps the undo affordance and surfaces the error',
      () async {
        final repo = _ThrowingDeleteRepo(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo);
        final bloc = FocusModeBloc(sessionFlowEngine: engine);
        addTearDown(bloc.close);
        repo.seedWorkoutDay(buildDay(benchSets: 2, plannedRestSeconds: null));
        final session = await repo.startSession(workoutDayId: 'wd-1');
        final anchor = session.sessionExercises.first.id;

        bloc.add(
          FocusModeOpened(
            sessionId: session.id,
            anchorSessionExerciseId: anchor,
          ),
        );
        await waitFor<FocusModeReady>(bloc, (st) => st is FocusModeReady);

        bloc.add(FocusModeSetCompleted(anchor));
        await waitFor<FocusModeReady>(
          bloc,
          (st) => st is FocusModeReady && st.undoable != null,
        );

        bloc.add(const FocusModeUndoRequested());
        final after = await waitFor<FocusModeReady>(
          bloc,
          (st) =>
              st is FocusModeReady &&
              !st.mutationInFlight &&
              st.lastTransientError != null,
        );
        expect(after.undoable, isNotNull);
        expect(after.lastTransientError, isNotNull);
      },
    );
  });

  group('stopwatch start guards', () {
    test('does not start a countdown while a mutation is in flight', () {
      fakeAsync((async) {
        final repo = _GatedCompleteSetRepo(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo);
        final bloc = FocusModeBloc(sessionFlowEngine: engine);
        repo.seedWorkoutDay(buildTimeSupersetDay());

        late String benchId;
        late String plankId;
        late String sessionId;
        repo.startSession(workoutDayId: 'wd-tss').then((session) {
          sessionId = session.id;
          benchId = session.sessionExercises
              .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
              .id;
          plankId = session.sessionExercises
              .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-plank')
              .id;
        });
        async.flushMicrotasks();

        bloc.add(
          FocusModeOpened(
            sessionId: sessionId,
            anchorSessionExerciseId: benchId,
          ),
        );
        async.flushMicrotasks();
        expect(bloc.state, isA<FocusModeReady>());

        // Hold a mutation in flight on the bench panel via the gated repo.
        repo.completeSetGate = Completer<void>();
        bloc.add(FocusModeSetCompleted(benchId));
        async.flushMicrotasks();
        expect((bloc.state as FocusModeReady).mutationInFlight, isTrue);

        // Attempt to start the plank countdown mid-mutation.
        bloc.add(FocusModeStopwatchStarted(plankId));
        async.flushMicrotasks();

        final blocked = bloc.state as FocusModeReady;
        expect(blocked.stopwatch.isRunning, isFalse);
        expect(blocked.activeStopwatchExerciseId, isNull);
        expect(async.periodicTimerCount, 0);

        // Release the gate and settle, then clean up.
        repo.completeSetGate!.complete();
        async.flushMicrotasks();
        bloc.close();
        async.flushMicrotasks();
      });
    });

    test('does not start a countdown on a non-loggable panel', () {
      fakeAsync((async) {
        final repo = FakeSessionRepository(clock: fakeClock);
        final engine = SessionFlowEngine(repository: repo);
        final bloc = FocusModeBloc(sessionFlowEngine: engine);
        repo.seedWorkoutDay(buildTimeSupersetDay());

        late String benchId;
        late String plankId;
        late String sessionId;
        repo.startSession(workoutDayId: 'wd-tss').then((session) {
          sessionId = session.id;
          benchId = session.sessionExercises
              .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
              .id;
          plankId = session.sessionExercises
              .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-plank')
              .id;
        });
        async.flushMicrotasks();

        bloc.add(
          FocusModeOpened(
            sessionId: sessionId,
            anchorSessionExerciseId: benchId,
          ),
        );
        async.flushMicrotasks();

        // Fill the plank's set quota so its panel is no longer loggable, while
        // the bench keeps the group active.
        bloc.add(FocusModeSetCompleted(plankId));
        async.flushMicrotasks();
        bloc.add(FocusModeSetCompleted(plankId));
        async.flushMicrotasks();

        final ready = bloc.state as FocusModeReady;
        final plankPanel = ready.groupViewModel.panels.firstWhere(
          (p) => p.sessionExerciseId == plankId,
        );
        expect(plankPanel.isLoggable, isFalse);

        // Attempt to start the (now non-loggable) plank countdown.
        bloc.add(FocusModeStopwatchStarted(plankId));
        async.flushMicrotasks();

        final after = bloc.state as FocusModeReady;
        expect(after.stopwatch.isRunning, isFalse);
        expect(after.activeStopwatchExerciseId, isNull);
        expect(async.periodicTimerCount, 0);

        bloc.close();
        async.flushMicrotasks();
      });
    });
  });

  group('FocusModeBloc corrupt-snapshot crash safety', () {
    test('a corrupt snapshot on the load path surfaces LoadFailure, '
        'not an unhandled crash', () async {
      final s = setup();
      addTearDown(s.bloc.close);

      final t = DateTime.utc(2024);
      WorkoutSet ws(String id) => WorkoutSet(
        id: 'ws-$id',
        exerciseId: id,
        position: 0,
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 100,
          repTarget: RepTarget.fixed(reps: 5),
        ),
        createdAt: t,
        updatedAt: t,
        schemaVersion: 1,
      );
      Exercise ex(String id) => Exercise(
        id: id,
        exerciseGroupId: 'g',
        position: 0,
        name: 'Ex $id',
        measurementType: const MeasurementType.repBased(),
        metadata: ExerciseMetadata.empty,
        sets: [ws(id)],
        createdAt: t,
        updatedAt: t,
        schemaVersion: 1,
      );
      // Superset snapshot with two real exercises; the session references the
      // first correctly (unfinished) but points its second, *completed* member
      // at a missing id. The engine resolves only unfinished/replaced
      // exercises, so it emits a state; the focus assembler builds a panel for
      // every non-skipped member of the anchor group, so it throws on the
      // corrupt completed member — the gap Step 1.6 wraps.
      final workoutDay = WorkoutDay(
        id: 'wd',
        programId: 'p',
        name: 'D',
        exerciseGroups: [
          ExerciseGroup(
            id: 'g',
            workoutDayId: 'wd',
            position: 0,
            kind: const ExerciseGroupKind.superset(),
            exercises: [ex('planned-a'), ex('planned-b')],
            createdAt: t,
            updatedAt: t,
            schemaVersion: 1,
          ),
        ],
        createdAt: t,
        updatedAt: t,
        schemaVersion: 1,
      );
      final snapshot = SessionSnapshot.capture(
        workoutDay: workoutDay,
        capturedAt: t,
        schemaVersion: 1,
      );
      SessionExercise se(
        String id,
        String plannedId,
        ExerciseState st,
        int p,
      ) => SessionExercise(
        id: id,
        sessionId: 's-corrupt',
        position: p,
        plannedExerciseIdInSnapshot: plannedId,
        state: st,
        executedSets: const [],
        supersetTag: 'g',
        createdAt: t,
        updatedAt: t,
        schemaVersion: 1,
      );
      s.repo.seedSession(
        Session(
          id: 's-corrupt',
          workoutDayId: 'wd',
          snapshot: snapshot,
          sessionExercises: [
            se('se-a', 'planned-a', const ExerciseState.unfinished(), 0),
            se('se-b', 'ghost-missing', const ExerciseState.completed(), 1),
          ],
          notes: const [],
          extraWork: const [],
          startedAt: t,
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
      );

      s.bloc.add(
        const FocusModeOpened(
          sessionId: 's-corrupt',
          anchorSessionExerciseId: 'se-a',
        ),
      );

      final terminal = await waitFor<FocusModeState>(
        s.bloc,
        (st) =>
            st is FocusModeLoadFailure ||
            st is FocusModeReady ||
            st is FocusModeWorkoutComplete,
      );
      expect(terminal, isA<FocusModeLoadFailure>());
      expect((terminal as FocusModeLoadFailure).error, isA<NotFoundError>());
    });
  });
}
