// Validates: Requirements R1 AC2, R2 AC5, R2 AC6, R3 AC2, R5 AC1, R13 AC4

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/exercise_view_model_assembler.dart';

void main() {
  group('ExerciseViewModelAssembler.assemble', () {
    test('one standalone unfinished exercise → cursor target on set 0', () {
      final session = _sessionFromGroups([
        _standalone(
          'ex-1',
          state: const ExerciseState.unfinished(),
          plannedSetCount: 3,
          executedSetCount: 0,
        ),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.active(sessionExerciseId: 'se-ex-1', setIndex: 0),
      );

      final groups = ExerciseViewModelAssembler.assemble(state);

      expect(groups, hasLength(1));
      expect(groups.single, isA<SingleGroupViewModel>());
      final vm = groups.single.allExercises.single;
      expect(vm.isCursorTarget, isTrue);
      expect(vm.cursorSetIndex, 0);
      expect(vm.setRows, hasLength(3));
      expect(vm.setRows[0].isNextLogTarget, isTrue);
      expect(vm.setRows[1].isNextLogTarget, isFalse);
      expect(vm.setRows[2].isNextLogTarget, isFalse);
    });

    test('mixed standalone + superset preserved in position order', () {
      final session = _sessionFromGroups([
        _standalone(
          'a',
          state: const ExerciseState.unfinished(),
          plannedSetCount: 2,
        ),
        _standalone(
          'b',
          state: const ExerciseState.unfinished(),
          plannedSetCount: 2,
          supersetTag: 'tag-x',
        ),
        _standalone(
          'c',
          state: const ExerciseState.unfinished(),
          plannedSetCount: 2,
          supersetTag: 'tag-x',
        ),
        _standalone(
          'd',
          state: const ExerciseState.unfinished(),
          plannedSetCount: 2,
        ),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.active(sessionExerciseId: 'se-a', setIndex: 0),
      );

      final groups = ExerciseViewModelAssembler.assemble(state);

      expect(groups, hasLength(3));
      expect(groups[0], isA<SingleGroupViewModel>());
      expect(
        groups[0].allExercises.map(
          (ExerciseViewModel e) => e.sessionExercise.id,
        ),
        ['se-a'],
      );
      expect(groups[1], isA<SupersetGroup>());
      expect((groups[1] as SupersetGroup).tag, 'tag-x');
      expect(
        groups[1].allExercises.map(
          (ExerciseViewModel e) => e.sessionExercise.id,
        ),
        ['se-b', 'se-c'],
      );
      expect(groups[2], isA<SingleGroupViewModel>());
      expect(
        groups[2].allExercises.map(
          (ExerciseViewModel e) => e.sessionExercise.id,
        ),
        ['se-d'],
      );
    });

    test('replaced exercise → effectiveMeasurementType = substitute\'s', () {
      final session = _sessionFromGroups([
        _standalone(
          'a',
          plannedMeasurement: const MeasurementType.repBased(),
          state: ExerciseState.replaced(
            substitute: SubstituteExercise(
              name: 'Cable Fly',
              measurementType: const MeasurementType.timeBased(),
              plannedValues: const PlannedSetValues.timeBased(
                durationSeconds: 30,
              ),
              setCount: 3,
              metadata: const ExerciseMetadata(),
            ),
          ),
          plannedSetCount: 3,
          executedSetCount: 0,
        ),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.active(sessionExerciseId: 'se-a', setIndex: 0),
      );

      final groups = ExerciseViewModelAssembler.assemble(state);

      expect(
        groups.single.allExercises.single.effectiveMeasurementType,
        const MeasurementType.timeBased(),
      );
      expect(
        groups.single.allExercises.single.plannedMeasurementType,
        const MeasurementType.repBased(),
      );
    });

    test('completed exercise → no cursor target', () {
      final session = _sessionFromGroups([
        _standalone(
          'a',
          state: const ExerciseState.completed(),
          plannedSetCount: 2,
          executedSetCount: 2,
        ),
        _standalone(
          'b',
          state: const ExerciseState.unfinished(),
          plannedSetCount: 2,
        ),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.active(sessionExerciseId: 'se-b', setIndex: 0),
      );

      final groups = ExerciseViewModelAssembler.assemble(state);
      expect(groups[0].allExercises.single.isCursorTarget, isFalse);
      expect(groups[0].allExercises.single.cursorSetIndex, isNull);
      expect(groups[1].allExercises.single.isCursorTarget, isTrue);
    });

    test('cursor.completed → no isCursorTarget anywhere', () {
      final session = _sessionFromGroups([
        _standalone(
          'a',
          state: const ExerciseState.completed(),
          plannedSetCount: 2,
          executedSetCount: 2,
        ),
        _standalone(
          'b',
          state: const ExerciseState.skipped(),
          plannedSetCount: 2,
        ),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.completed(),
      );

      final groups = ExerciseViewModelAssembler.assemble(state);
      for (final g in groups) {
        for (final ex in g.allExercises) {
          expect(ex.isCursorTarget, isFalse);
          expect(ex.cursorSetIndex, isNull);
          for (final r in ex.setRows) {
            expect(r.isNextLogTarget, isFalse);
          }
        }
      }
    });

    test('extra executed sets beyond planned count produce trailing rows '
        'with null plannedValues', () {
      final session = _sessionFromGroups([
        _standalone(
          'a',
          state: const ExerciseState.completed(),
          plannedSetCount: 2,
          executedSetCount: 4,
        ),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.completed(),
      );

      final groups = ExerciseViewModelAssembler.assemble(state);
      final rows = groups.single.allExercises.single.setRows;

      expect(rows, hasLength(4));
      expect(rows[0].plannedValues, isNotNull);
      expect(rows[1].plannedValues, isNotNull);
      expect(rows[2].plannedValues, isNull);
      expect(rows[3].plannedValues, isNull);
      expect(rows[2].executedSet, isNotNull);
      expect(rows[3].executedSet, isNotNull);
    });

    test('non-consecutive same supersetTag exercises end up in separate '
        'groups (defensive)', () {
      final session = _sessionFromGroups([
        _standalone('a', plannedSetCount: 2, supersetTag: 'tag-x'),
        _standalone('b', plannedSetCount: 2),
        _standalone('c', plannedSetCount: 2, supersetTag: 'tag-x'),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.active(sessionExerciseId: 'se-a', setIndex: 0),
      );

      final groups = ExerciseViewModelAssembler.assemble(state);
      expect(groups, hasLength(3));
      // Non-adjacent same-tag exercises degrade to single groups: the
      // assembler intentionally does not pair non-contiguous tag matches.
      expect(groups[0], isA<SingleGroupViewModel>());
      expect(groups[1], isA<SingleGroupViewModel>());
      expect(groups[2], isA<SingleGroupViewModel>());
    });

    test('plannedSummary equals PlannedSummaryFormatter.summarize output', () {
      final session = _sessionFromGroups([
        _standalone('a', plannedSetCount: 4, weightKg: 100, reps: 8),
      ]);
      final state = SessionState(
        session: session,
        cursor: const Cursor.active(sessionExerciseId: 'se-a', setIndex: 0),
      );

      final vm = ExerciseViewModelAssembler.assemble(
        state,
      ).single.allExercises.single;
      expect(vm.plannedSummary, '100kg 4×8');
    });
  });
}

class _ExerciseSpec {
  _ExerciseSpec({
    required this.id,
    required this.state,
    required this.plannedSetCount,
    required this.executedSetCount,
    required this.plannedMeasurement,
    required this.weightKg,
    required this.reps,
    required this.supersetTag,
  });
  final String id;
  final ExerciseState state;
  final int plannedSetCount;
  final int executedSetCount;
  final MeasurementType plannedMeasurement;
  final double weightKg;
  final int reps;
  final String? supersetTag;
}

_ExerciseSpec _standalone(
  String id, {
  ExerciseState state = const ExerciseState.unfinished(),
  int plannedSetCount = 1,
  int executedSetCount = 0,
  MeasurementType plannedMeasurement = const MeasurementType.repBased(),
  double weightKg = 100,
  int reps = 8,
  String? supersetTag,
}) => _ExerciseSpec(
  id: id,
  state: state,
  plannedSetCount: plannedSetCount,
  executedSetCount: executedSetCount,
  plannedMeasurement: plannedMeasurement,
  weightKg: weightKg,
  reps: reps,
  supersetTag: supersetTag,
);

Session _sessionFromGroups(List<_ExerciseSpec> specs) {
  final now = DateTime.utc(2025);
  const sessionId = 'session-1';
  const workoutDayId = 'wd-1';

  final exerciseGroups = <ExerciseGroup>[];
  for (var i = 0; i < specs.length; i++) {
    final spec = specs[i];
    final exerciseId = 'ex-${spec.id}';
    final groupId = 'grp-$i';
    final exercise = Exercise(
      id: exerciseId,
      exerciseGroupId: groupId,
      position: 0,
      name: 'Ex ${spec.id}',
      measurementType: spec.plannedMeasurement,
      metadata: const ExerciseMetadata(),
      sets: List.generate(spec.plannedSetCount, (j) {
        return WorkoutSet(
          id: 'ws-${spec.id}-$j',
          exerciseId: exerciseId,
          position: j,
          measurementType: spec.plannedMeasurement,
          plannedValues: switch (spec.plannedMeasurement) {
            RepBasedMeasurement() => PlannedSetValues.repBased(
              weightKg: spec.weightKg,
              repTarget: RepTarget.fixed(reps: spec.reps),
            ),
            TimeBasedMeasurement() => const PlannedSetValues.timeBased(
              durationSeconds: 30,
            ),
          },
          createdAt: now,
          updatedAt: now,
          schemaVersion: 1,
        );
      }),
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );
    exerciseGroups.add(
      ExerciseGroup(
        id: groupId,
        workoutDayId: workoutDayId,
        position: i,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercise],
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      ),
    );
  }

  final workoutDay = WorkoutDay(
    id: workoutDayId,
    programId: 'prog-1',
    name: 'Upper A',
    exerciseGroups: exerciseGroups,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );

  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: now,
    schemaVersion: 1,
  );

  final sessionExercises = <SessionExercise>[];
  for (var i = 0; i < specs.length; i++) {
    final spec = specs[i];
    final effectiveMt = switch (spec.state) {
      ReplacedState(:final substitute) => substitute.measurementType,
      _ => spec.plannedMeasurement,
    };
    sessionExercises.add(
      SessionExercise(
        id: 'se-${spec.id}',
        sessionId: sessionId,
        position: i,
        plannedExerciseIdInSnapshot: 'ex-${spec.id}',
        state: spec.state,
        executedSets: List.generate(spec.executedSetCount, (j) {
          return ExecutedSet(
            id: 'esrec-${spec.id}-$j',
            sessionExerciseId: 'se-${spec.id}',
            position: j,
            measurementType: effectiveMt,
            actualValues: switch (effectiveMt) {
              RepBasedMeasurement() => PlannedSetValues.repBased(
                weightKg: spec.weightKg,
                repTarget: RepTarget.fixed(reps: spec.reps),
              ).toActual(),
              TimeBasedMeasurement() => const ActualSetValues.timeBased(
                durationSeconds: 30,
              ),
            },
            plannedSetIdInSnapshot: j < spec.plannedSetCount
                ? 'ws-${spec.id}-$j'
                : null,
            completedAt: now,
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          );
        }),
        supersetTag: spec.supersetTag,
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      ),
    );
  }

  return Session(
    id: sessionId,
    workoutDayId: workoutDayId,
    snapshot: snapshot,
    sessionExercises: sessionExercises,
    notes: const [],
    extraWork: const [],
    startedAt: now,
    createdAt: now,
    updatedAt: now,
    schemaVersion: 1,
  );
}

extension on PlannedSetValues {
  ActualSetValues toActual() => switch (this) {
    PlannedRepBased(:final weightKg, :final repTarget) =>
      ActualSetValues.repBased(
        weightKg: weightKg,
        reps: switch (repTarget) {
          RepTargetFixed(:final reps) => reps,
          RepTargetRange(:final maxReps) => maxReps,
        },
      ),
    PlannedTimeBased(:final durationSeconds) => ActualSetValues.timeBased(
      durationSeconds: durationSeconds,
    ),
  };
}
