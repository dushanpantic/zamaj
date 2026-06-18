import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/services/session_history_assembler.dart';
import 'package:zamaj/modules/workout_overview/workout_overview.dart';

/// Mirrors how the session-review card (`session_detail_exercise_card.dart`)
/// derives the badge for one exercise: from the read-only view model's logged
/// vs planned set-row counts. Kept in lockstep with that widget — no widget
/// tests by project rule, so this is the badge's input-shape contract.
ExerciseOutcome _reviewBadgeOutcome(ExerciseViewModel vm) {
  final executed = vm.setRows.where((r) => r.executedSet != null).length;
  final planned = vm.setRows.where((r) => r.plannedValues != null).length;
  return ExerciseOutcomes.of(
    state: vm.sessionExercise.state,
    executedSetCount: executed,
    plannedSetCount: planned,
  );
}

void main() {
  group('SessionHistoryAssembler.assemble', () {
    final referenceNow = DateTime.utc(2026, 5, 15, 12);
    final window = TrainingWeek.compute(referenceNow);

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

    test('counts only exercises that met their planned quota', () {
      final t = DateTime.utc(2026, 5, 12, 18);
      final session = _sessionWithSpecs(
        id: 's1',
        endedAt: t,
        specs: const [
          (state: ExerciseState.completed(), executed: 4, planned: 4),
          (state: ExerciseState.completed(), executed: 4, planned: 4),
          (state: ExerciseState.skipped(), executed: 2, planned: 4),
          (state: ExerciseState.unfinished(), executed: 0, planned: 4),
        ],
      );
      final items = SessionHistoryAssembler.assemble(
        sessions: [session],
        window: window,
      );
      expect(items.single.completedExerciseCount, 2);
      expect(items.single.totalExerciseCount, 4);
    });

    test(
      'marks the item as a deload for a deload session, not a normal one',
      () {
        final items = SessionHistoryAssembler.assemble(
          sessions: [
            _session(id: 'normal', endedAt: DateTime.utc(2026, 5, 12, 18)),
            _session(
              id: 'deload',
              endedAt: DateTime.utc(2026, 5, 13, 18),
            ).copyWith(isDeload: true),
          ],
          window: window,
        );

        final normal = items.firstWhere((i) => i.sessionId == 'normal');
        final deload = items.firstWhere((i) => i.sessionId == 'deload');
        expect(deload.isDeload, isTrue);
        expect(normal.isDeload, isFalse);
      },
    );
  });

  group('session-review badge outcome (derived input shape)', () {
    // Verifies the outcome the review card feeds its badge for each record
    // shape, assembled through the very view model the card consumes.
    ExerciseOutcome outcomeFor(
      ({ExerciseState state, int executed, int planned}) spec,
    ) {
      final session = _sessionWithSpecs(
        id: 'rev',
        endedAt: DateTime.utc(2026, 5, 12, 18),
        specs: [spec],
      );
      final group = ExerciseViewModelAssembler.assembleReadOnly(session).single;
      final vm = (group as SingleGroupViewModel).exercise;
      return _reviewBadgeOutcome(vm);
    }

    test('full quota → completed (✓ Done)', () {
      expect(
        outcomeFor((
          state: const ExerciseState.completed(),
          executed: 4,
          planned: 4,
        )),
        ExerciseOutcome.completed,
      );
    });

    test('legacy completed-at-2/4 → partial', () {
      expect(
        outcomeFor((
          state: const ExerciseState.completed(),
          executed: 2,
          planned: 4,
        )),
        ExerciseOutcome.partial,
      );
    });

    test('skipped-with-sets → partial', () {
      expect(
        outcomeFor((
          state: const ExerciseState.skipped(),
          executed: 2,
          planned: 4,
        )),
        ExerciseOutcome.partial,
      );
    });

    test('zero-set skip → skipped', () {
      expect(
        outcomeFor((
          state: const ExerciseState.skipped(),
          executed: 0,
          planned: 4,
        )),
        ExerciseOutcome.skipped,
      );
    });

    test('replaced → replaced regardless of logged sets', () {
      final session = _sessionWithReplaced(executed: 1, substituteSetCount: 3);
      final group = ExerciseViewModelAssembler.assembleReadOnly(session).single;
      final vm = (group as SingleGroupViewModel).exercise;
      expect(_reviewBadgeOutcome(vm), ExerciseOutcome.replaced);
    });
  });
}

typedef _ExSpec = ({ExerciseState state, int executed, int planned});

Session _sessionWithSpecs({
  required String id,
  required DateTime? endedAt,
  required List<_ExSpec> specs,
}) {
  final t = DateTime.utc(2026, 5, 12);
  const mt = MeasurementType.repBased();
  final plannedValues = PlannedSetValues.repBased(
    weightKg: 100,
    repTarget: RepTarget.fixed(reps: 5),
  );
  const actualValues = ActualSetValues.repBased(weightKg: 100, reps: 5);

  final groups = <ExerciseGroup>[
    for (var i = 0; i < specs.length; i++)
      ExerciseGroup(
        id: 'g-$id-$i',
        workoutDayId: 'wd-$id',
        position: i,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          Exercise(
            id: 'ex-$i',
            exerciseGroupId: 'g-$id-$i',
            position: 0,
            name: 'Ex $i',
            measurementType: mt,
            metadata: ExerciseMetadata.empty,
            sets: [
              for (var j = 0; j < specs[i].planned; j++)
                WorkoutSet(
                  id: 'ws-$id-$i-$j',
                  exerciseId: 'ex-$i',
                  position: j,
                  measurementType: mt,
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
  ];
  final workoutDay = WorkoutDay(
    id: 'wd-$id',
    programId: 'p-1',
    name: 'Upper A',
    exerciseGroups: groups,
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
      for (var i = 0; i < specs.length; i++)
        SessionExercise(
          id: 'sx-$id-$i',
          sessionId: id,
          position: i,
          plannedExerciseIdInSnapshot: 'ex-$i',
          state: specs[i].state,
          executedSets: [
            for (var j = 0; j < specs[i].executed; j++)
              ExecutedSet(
                id: 'es-$id-$i-$j',
                sessionExerciseId: 'sx-$id-$i',
                position: j,
                measurementType: mt,
                actualValues: actualValues,
                completedAt: t,
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
    notes: const [],
    extraWork: const [],
    startedAt: t,
    endedAt: endedAt,
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
  );
}

Session _sessionWithReplaced({
  required int executed,
  required int substituteSetCount,
}) {
  final t = DateTime.utc(2026, 5, 12);
  const mt = MeasurementType.repBased();
  final session = _sessionWithSpecs(
    id: 'rep',
    endedAt: DateTime.utc(2026, 5, 12, 18),
    specs: const [(state: ExerciseState.unfinished(), executed: 0, planned: 4)],
  );
  final substitute = SubstituteExercise(
    name: 'Cable Fly',
    measurementType: mt,
    plannedValues: PlannedSetValues.repBased(
      weightKg: 20,
      repTarget: RepTarget.fixed(reps: 12),
    ),
    setCount: substituteSetCount,
  );
  final ex = session.sessionExercises.single.copyWith(
    state: ExerciseState.replaced(substitute: substitute),
    executedSets: [
      for (var j = 0; j < executed; j++)
        ExecutedSet(
          id: 'es-rep-$j',
          sessionExerciseId: session.sessionExercises.single.id,
          position: j,
          measurementType: mt,
          actualValues: const ActualSetValues.repBased(weightKg: 20, reps: 12),
          completedAt: t,
          createdAt: t,
          updatedAt: t,
          schemaVersion: 1,
        ),
    ],
  );
  return session.copyWith(sessionExercises: [ex]);
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
