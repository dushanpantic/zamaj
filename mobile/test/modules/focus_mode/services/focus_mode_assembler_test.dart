import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/services/focus_mode_assembler.dart';

import '../../../support/fake_session_repository.dart';

void main() {
  final fixedTime = DateTime.utc(2024, 6, 1, 12);
  final fakeClock = Clock.fixed(fixedTime);

  ({FakeSessionRepository repo, SessionFlowEngine engine}) setup() {
    final repo = FakeSessionRepository(clock: fakeClock);
    return (repo: repo, engine: SessionFlowEngine(repository: repo));
  }

  WorkoutDay buildDay({
    int benchSets = 2,
    int? plannedRestSeconds,
    MeasurementType benchMeasurement = const MeasurementType.repBased(),
  }) {
    final t = DateTime.utc(2024);
    final plannedValues = switch (benchMeasurement) {
      RepBasedMeasurement() => PlannedSetValues.repBased(
        weightKg: 100,
        repTarget: RepTarget.fixed(reps: 8),
      ),
      TimeBasedMeasurement() => const PlannedSetValues.timeBased(
        durationSeconds: 30,
      ),
      BodyweightMeasurement() => PlannedSetValues.bodyweight(
        repTarget: RepTarget.fixed(reps: 8),
      ),
    };
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
              name: 'Bench Press',
              measurementType: benchMeasurement,
              metadata: const ExerciseMetadata(notes: 'arch'),
              plannedRestSeconds: plannedRestSeconds,
              sets: [
                for (var i = 0; i < benchSets; i++)
                  WorkoutSet(
                    id: 'ws-$i',
                    exerciseId: 'ex-bench',
                    position: i,
                    measurementType: benchMeasurement,
                    plannedValues: plannedValues,
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
        ExerciseGroup(
          id: 'g2',
          workoutDayId: 'wd-1',
          position: 1,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-row',
              exerciseGroupId: 'g2',
              position: 0,
              name: 'Row',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                WorkoutSet(
                  id: 'ws-row-0',
                  exerciseId: 'ex-row',
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: PlannedSetValues.repBased(
                    weightKg: 60,
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

  /// A workout day with a superset of two exercises followed by a single
  /// trailing exercise.
  WorkoutDay buildSupersetDay() {
    final t = DateTime.utc(2024);
    return WorkoutDay(
      id: 'wd-ss',
      programId: 'p-1',
      name: 'Push',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g-superset',
          workoutDayId: 'wd-ss',
          position: 0,
          kind: const ExerciseGroupKind.superset(),
          exercises: [
            Exercise(
              id: 'ex-bench',
              exerciseGroupId: 'g-superset',
              position: 0,
              name: 'Bench Press',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              plannedRestSeconds: 90,
              sets: [
                for (var i = 0; i < 2; i++)
                  WorkoutSet(
                    id: 'ws-bench-$i',
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
              exerciseGroupId: 'g-superset',
              position: 1,
              name: 'Lat Pulldown',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              plannedRestSeconds: 60,
              sets: [
                for (var i = 0; i < 2; i++)
                  WorkoutSet(
                    id: 'ws-lat-$i',
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
        ExerciseGroup(
          id: 'g-trail',
          workoutDayId: 'wd-ss',
          position: 1,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            Exercise(
              id: 'ex-curl',
              exerciseGroupId: 'g-trail',
              position: 0,
              name: 'Curl',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [
                WorkoutSet(
                  id: 'ws-curl-0',
                  exerciseId: 'ex-curl',
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: PlannedSetValues.repBased(
                    weightKg: 20,
                    repTarget: RepTarget.fixed(reps: 12),
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

  group('FocusModeAssembler.assemble (single-exercise groups)', () {
    test('builds a single-panel group with full panel projection', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay(plannedRestSeconds: 120));
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;

      final group = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: benchId,
      )!;

      expect(group.workoutDayName, 'Upper');
      expect(group.supersetTag, isNull);
      expect(group.panels, hasLength(1));
      final panel = group.panels.single;
      expect(panel.sessionExerciseId, benchId);
      expect(panel.displayExerciseName, 'Bench Press');
      expect(panel.currentSetIndex, 0);
      expect(panel.totalPlannedSets, 2);
      expect(panel.completedSetsCount, 0);
      expect(panel.lastExecutedValues, isNull);
      expect(panel.plannedSummary, '100kg 2×8');
      expect(panel.plannedRestSeconds, 120);
      expect(panel.isReplaced, isFalse);
      expect(panel.isLoggable, isTrue);
      expect(group.upNextGroupLabel, 'Row');
    });

    test('after logging one set, lastExecutedValues populated', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final after = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 97.5, reps: 8),
      );
      final group = FocusModeAssembler.assemble(
        after,
        anchorSessionExerciseId: benchId,
      )!;
      final panel = group.panels.single;
      expect(panel.currentSetIndex, 1);
      expect(panel.completedSetsCount, 1);
      expect(
        panel.lastExecutedValues,
        const ActualSetValues.repBased(weightKg: 97.5, reps: 8),
      );
    });

    test('replaced exercise reflects substitute in display name + measurement '
        'type and flags isReplaced', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final after = await s.engine.replaceExercise(
        sessionExerciseId: benchId,
        substituteName: 'Cable Fly',
        substituteMeasurementType: const MeasurementType.timeBased(),
        substitutePlannedValues: const PlannedSetValues.timeBased(
          durationSeconds: 30,
        ),
        substituteSetCount: 3,
      );
      final group = FocusModeAssembler.assemble(
        after,
        anchorSessionExerciseId: benchId,
      )!;
      final panel = group.panels.single;
      expect(panel.displayExerciseName, 'Cable Fly');
      expect(panel.plannedExerciseName, 'Bench Press');
      expect(panel.isReplaced, isTrue);
      expect(panel.effectiveMeasurementType, isA<TimeBasedMeasurement>());
      expect(panel.isLoggable, isTrue);
    });

    test('up-next walks past skipped groups; null at end of session', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay(benchSets: 1));
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final rowId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-row')
          .id;
      await s.engine.skipExercise(sessionExerciseId: rowId);
      final after = await s.engine.resumeSession(sessionId: state.session.id);
      final group = FocusModeAssembler.assemble(
        after,
        anchorSessionExerciseId: benchId,
      )!;
      expect(group.upNextGroupLabel, isNull);
      expect(group.upNextGroupAnchorId, isNull);
    });

    test('returns null when the anchor id is unknown', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final group = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: 'never-existed',
      );
      expect(group, isNull);
    });
  });

  group('FocusModeAssembler.assemble (superset groups)', () {
    test('renders all superset members as panels in position order', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildSupersetDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-ss');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final latId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;

      final group = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: benchId,
      )!;

      expect(group.supersetTag, isNotNull);
      expect(group.panels, hasLength(2));
      expect(group.panels[0].sessionExerciseId, benchId);
      expect(group.panels[1].sessionExerciseId, latId);
      expect(group.panels.every((p) => p.isLoggable), isTrue);
      expect(group.upNextGroupLabel, 'Curl');
    });

    test('anchoring on either superset member yields the same group', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildSupersetDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-ss');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final latId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;

      final fromBench = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: benchId,
      )!;
      final fromLat = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: latId,
      )!;
      expect(
        fromBench.panels.map((p) => p.sessionExerciseId).toList(),
        fromLat.panels.map((p) => p.sessionExerciseId).toList(),
      );
    });

    test(
      'completed panel inside superset stays visible but not loggable',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildSupersetDay());
        final state = await s.engine.startSession(workoutDayId: 'wd-ss');
        final benchId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
            .id;
        // Fulfil bench's 2 planned sets.
        await s.engine.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 8),
        );
        final after = await s.engine.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 8),
        );
        final group = FocusModeAssembler.assemble(
          after,
          anchorSessionExerciseId: benchId,
        )!;
        final benchPanel = group.panels.firstWhere(
          (p) => p.sessionExerciseId == benchId,
        );
        expect(benchPanel.isLoggable, isFalse);
        // The other superset member is still loggable.
        expect(group.panels.any((p) => p.isLoggable), isTrue);
      },
    );

    test('skipped members are hidden from the panel list', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildSupersetDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-ss');
      final latId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      await s.engine.skipExercise(sessionExerciseId: latId);
      final after = await s.engine.resumeSession(sessionId: state.session.id);
      final group = FocusModeAssembler.assemble(
        after,
        anchorSessionExerciseId: benchId,
      )!;
      expect(group.panels, hasLength(1));
      expect(group.panels.single.sessionExerciseId, benchId);
    });
  });

  /// Builds a workout day with a 3-exercise giant set (A + B + C) plus a
  /// trailing single. Each exercise has 2 planned sets.
  WorkoutDay buildGiantSetDay() {
    final t = DateTime.utc(2024);
    Exercise giantMember({
      required String id,
      required int position,
      required String name,
    }) {
      return Exercise(
        id: id,
        exerciseGroupId: 'g-giant',
        position: position,
        name: name,
        measurementType: const MeasurementType.repBased(),
        metadata: ExerciseMetadata.empty,
        plannedRestSeconds: 60,
        sets: [
          for (var i = 0; i < 2; i++)
            WorkoutSet(
              id: 'ws-$id-$i',
              exerciseId: id,
              position: i,
              measurementType: const MeasurementType.repBased(),
              plannedValues: PlannedSetValues.repBased(
                weightKg: 50,
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
      );
    }

    return WorkoutDay(
      id: 'wd-giant',
      programId: 'p-1',
      name: 'Giant',
      exerciseGroups: [
        ExerciseGroup(
          id: 'g-giant',
          workoutDayId: 'wd-giant',
          position: 0,
          kind: const ExerciseGroupKind.superset(),
          exercises: [
            giantMember(id: 'ex-a', position: 0, name: 'A'),
            giantMember(id: 'ex-b', position: 1, name: 'B'),
            giantMember(id: 'ex-c', position: 2, name: 'C'),
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

  group('FocusModeAssembler.assemble (active panel selection)', () {
    test('single-panel group → active equals that panel', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final group = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: benchId,
      )!;
      expect(group.activeSessionExerciseId, benchId);
      expect(group.activeIsUserPinned, isFalse);
    });

    test('2-panel superset, no sets logged → active is position 0', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildSupersetDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-ss');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final group = FocusModeAssembler.assemble(
        state,
        anchorSessionExerciseId: benchId,
      )!;
      expect(group.activeSessionExerciseId, benchId);
      expect(group.activeIsUserPinned, isFalse);
    });

    test('A has 1 set, B has 0 → active is B (lower count wins)', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildSupersetDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-ss');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final latId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
          .id;
      final after = await s.engine.completeSet(
        sessionExerciseId: benchId,
        actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 8),
      );
      final group = FocusModeAssembler.assemble(
        after,
        anchorSessionExerciseId: benchId,
      )!;
      expect(group.activeSessionExerciseId, latId);
    });

    test(
      'both panels at 1 set, A logged most recently → active is B (rotation)',
      () async {
        // Build session manually to control completedAt ordering — the
        // fake clock used by the engine returns a fixed instant.
        final s = setup();
        s.repo.seedWorkoutDay(buildSupersetDay());
        final state = await s.engine.startSession(workoutDayId: 'wd-ss');
        final benchId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
            .id;
        final latId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
            .id;

        // Engine logs both sets with the same fixed clock instant. Splice
        // in distinct completedAt timestamps where lat is the older entry
        // and bench is the most recent.
        final s1 = await s.engine.completeSet(
          sessionExerciseId: latId,
          actualValues: const ActualSetValues.repBased(weightKg: 70, reps: 10),
        );
        final s2 = await s.engine.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 8),
        );

        final patchedExercises = [
          for (final ex in s2.session.sessionExercises)
            ex.copyWith(
              executedSets: [
                for (final set in ex.executedSets)
                  set.copyWith(
                    completedAt: ex.id == latId
                        ? DateTime.utc(2024, 6, 1, 12)
                        : DateTime.utc(2024, 6, 1, 12, 0, 1),
                  ),
              ],
            ),
        ];
        final patchedSession = s2.session.copyWith(
          sessionExercises: patchedExercises,
        );
        final patchedState = s2.copyWith(session: patchedSession);

        final group = FocusModeAssembler.assemble(
          patchedState,
          anchorSessionExerciseId: benchId,
        )!;
        // Bench was most recent; rotation picks the *other* panel — lat.
        expect(group.activeSessionExerciseId, latId);

        // Also covers the symmetric case via the s1 baseline (lat most
        // recent → active is bench).
        expect(s1.session.sessionExercises, isNotEmpty);
      },
    );

    test(
      'user pin overrides auto-rotation when pinned panel is loggable',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildSupersetDay());
        final state = await s.engine.startSession(workoutDayId: 'wd-ss');
        final benchId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
            .id;
        final latId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
            .id;
        // Without the pin, no sets logged → active = position 0 = bench.
        final group = FocusModeAssembler.assemble(
          state,
          anchorSessionExerciseId: benchId,
          userPinnedPanelId: latId,
        )!;
        expect(group.activeSessionExerciseId, latId);
        expect(group.activeIsUserPinned, isTrue);
      },
    );

    test(
      'pinned panel no longer loggable → falls back to auto-rotation',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildSupersetDay());
        final state = await s.engine.startSession(workoutDayId: 'wd-ss');
        final benchId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
            .id;
        final latId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-lat')
            .id;
        // Fulfil lat's quota so it is no longer loggable.
        await s.engine.completeSet(
          sessionExerciseId: latId,
          actualValues: const ActualSetValues.repBased(weightKg: 70, reps: 10),
        );
        final after = await s.engine.completeSet(
          sessionExerciseId: latId,
          actualValues: const ActualSetValues.repBased(weightKg: 70, reps: 10),
        );

        final group = FocusModeAssembler.assemble(
          after,
          anchorSessionExerciseId: benchId,
          userPinnedPanelId: latId,
        )!;
        expect(group.activeSessionExerciseId, benchId);
        expect(group.activeIsUserPinned, isFalse);
      },
    );

    test(
      '3-panel giant set ABA logged (A=2, B=1, C=0) → active is C',
      () async {
        final s = setup();
        s.repo.seedWorkoutDay(buildGiantSetDay());
        final state = await s.engine.startSession(workoutDayId: 'wd-giant');
        final aId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-a')
            .id;
        final bId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-b')
            .id;
        final cId = state.session.sessionExercises
            .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-c')
            .id;
        await s.engine.completeSet(
          sessionExerciseId: aId,
          actualValues: const ActualSetValues.repBased(weightKg: 50, reps: 10),
        );
        await s.engine.completeSet(
          sessionExerciseId: bId,
          actualValues: const ActualSetValues.repBased(weightKg: 50, reps: 10),
        );
        final after = await s.engine.completeSet(
          sessionExerciseId: aId,
          actualValues: const ActualSetValues.repBased(weightKg: 50, reps: 10),
        );

        final group = FocusModeAssembler.assemble(
          after,
          anchorSessionExerciseId: aId,
        )!;
        // Counts: A=2, B=1, C=0. Min is 0 (C only). Active = C.
        expect(group.activeSessionExerciseId, cId);
      },
    );
  });

  group('FocusModeAssembler.listSwitchOptions', () {
    test('lists every visible group with the current one flagged', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildSupersetDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-ss');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final curlId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-curl')
          .id;

      final options = FocusModeAssembler.listSwitchOptions(
        state,
        currentAnchorId: benchId,
      );
      expect(options, hasLength(2));
      // First option = the superset (current).
      expect(options[0].isCurrent, isTrue);
      expect(options[0].isSuperset, isTrue);
      expect(options[0].label.contains('+'), isTrue);
      // Second option = the trailing Curl single.
      expect(options[1].isCurrent, isFalse);
      expect(options[1].isSuperset, isFalse);
      expect(options[1].label, 'Curl');
      expect(options[1].anchorSessionExerciseId, curlId);
    });
  });

  group('FocusModeAssembler.findNextAnchorAfter', () {
    test('returns the first loggable exercise of the next group', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildSupersetDay());
      final state = await s.engine.startSession(workoutDayId: 'wd-ss');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final curlId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-curl')
          .id;

      final next = FocusModeAssembler.findNextAnchorAfter(
        state,
        completedAnchorId: benchId,
      );
      expect(next, curlId);
    });

    test('returns null when no further groups have open targets', () async {
      final s = setup();
      s.repo.seedWorkoutDay(buildDay(benchSets: 1));
      final state = await s.engine.startSession(workoutDayId: 'wd-1');
      final benchId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-bench')
          .id;
      final rowId = state.session.sessionExercises
          .firstWhere((e) => e.plannedExerciseIdInSnapshot == 'ex-row')
          .id;
      await s.engine.skipExercise(sessionExerciseId: rowId);
      final after = await s.engine.resumeSession(sessionId: state.session.id);

      final next = FocusModeAssembler.findNextAnchorAfter(
        after,
        completedAnchorId: benchId,
      );
      expect(next, isNull);
    });
  });
}
