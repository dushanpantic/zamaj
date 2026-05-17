/// Regression tests for the create-after-delete position assignment bug.
///
/// Before the fix, `createWorkoutDay` (and its siblings on groups, exercises,
/// sets) assigned `position = existing.length`. Because deletes do not compact
/// remaining positions, the next create could collide with the
/// `UNIQUE(parent, position)` constraint.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';

import '../support/in_memory_app_database.dart';

domain.Exercise _placeholderExercise(int index) => domain.Exercise(
  id: '00000000-0000-0000-0000-${index.toString().padLeft(12, '0')}',
  exerciseGroupId: '',
  position: 0,
  name: 'Ex$index',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: const [],
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  schemaVersion: 1,
);

void main() {
  group('create-after-delete position assignment', () {
    test('createWorkoutDay succeeds after deleting a middle day', () async {
      final helper = InMemoryDatabaseHelper();
      await helper.setUp();
      try {
        final repo = DriftProgramRepository(db: helper.db);
        final program = await repo.createProgram(name: 'P');

        final a = await repo.createWorkoutDay(programId: program.id, name: 'A');
        final b = await repo.createWorkoutDay(programId: program.id, name: 'B');
        final c = await repo.createWorkoutDay(programId: program.id, name: 'C');

        await repo.deleteWorkoutDay(b.id);

        final d = await repo.createWorkoutDay(programId: program.id, name: 'D');
        final days = await repo.listWorkoutDaysForProgram(program.id);
        expect(days.map((x) => x.id), containsAll([a.id, c.id, d.id]));
      } finally {
        await helper.tearDown();
      }
    });

    test(
      'createExerciseGroup succeeds after deleting a middle group',
      () async {
        final helper = InMemoryDatabaseHelper();
        await helper.setUp();
        try {
          final repo = DriftProgramRepository(db: helper.db);
          final program = await repo.createProgram(name: 'P');
          final day = await repo.createWorkoutDay(
            programId: program.id,
            name: 'Day',
          );

          final g1 = await repo.createExerciseGroup(
            workoutDayId: day.id,
            kind: const ExerciseGroupKind.single(),
            exercises: [_placeholderExercise(1)],
          );
          final g2 = await repo.createExerciseGroup(
            workoutDayId: day.id,
            kind: const ExerciseGroupKind.single(),
            exercises: [_placeholderExercise(2)],
          );
          await repo.createExerciseGroup(
            workoutDayId: day.id,
            kind: const ExerciseGroupKind.single(),
            exercises: [_placeholderExercise(3)],
          );

          await repo.deleteExerciseGroup(g2.id);

          final g4 = await repo.createExerciseGroup(
            workoutDayId: day.id,
            kind: const ExerciseGroupKind.single(),
            exercises: [_placeholderExercise(4)],
          );

          final reloaded = await repo.getWorkoutDay(day.id);
          final ids = reloaded!.exerciseGroups.map((g) => g.id).toSet();
          expect(ids, contains(g1.id));
          expect(ids, contains(g4.id));
          expect(ids, isNot(contains(g2.id)));
        } finally {
          await helper.tearDown();
        }
      },
    );

    test('createExercise succeeds after deleting a middle exercise', () async {
      final helper = InMemoryDatabaseHelper();
      await helper.setUp();
      try {
        final repo = DriftProgramRepository(db: helper.db);
        final program = await repo.createProgram(name: 'P');
        final day = await repo.createWorkoutDay(
          programId: program.id,
          name: 'Day',
        );
        final group = await repo.createExerciseGroup(
          workoutDayId: day.id,
          kind: const ExerciseGroupKind.superset(),
          exercises: [_placeholderExercise(1), _placeholderExercise(2)],
        );

        final ex3 = await repo.createExercise(
          exerciseGroupId: group.id,
          name: 'C',
          measurementType: const MeasurementType.repBased(),
        );

        await repo.deleteExercise(ex3.id);

        final ex4 = await repo.createExercise(
          exerciseGroupId: group.id,
          name: 'D',
          measurementType: const MeasurementType.repBased(),
        );
        expect(ex4.id, isNotNull);
      } finally {
        await helper.tearDown();
      }
    });

    test('createSet succeeds after deleting a middle set', () async {
      final helper = InMemoryDatabaseHelper();
      await helper.setUp();
      try {
        final repo = DriftProgramRepository(db: helper.db);
        final program = await repo.createProgram(name: 'P');
        final day = await repo.createWorkoutDay(
          programId: program.id,
          name: 'Day',
        );
        final group = await repo.createExerciseGroup(
          workoutDayId: day.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [_placeholderExercise(0)],
        );
        final exercise = await repo.createExercise(
          exerciseGroupId: group.id,
          name: 'Squat',
          measurementType: const MeasurementType.repBased(),
        );

        await repo.createSet(
          exerciseId: exercise.id,
          plannedValues: PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.fixed(reps: 5),
          ),
        );
        final s2 = await repo.createSet(
          exerciseId: exercise.id,
          plannedValues: PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.fixed(reps: 5),
          ),
        );
        await repo.createSet(
          exerciseId: exercise.id,
          plannedValues: PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.fixed(reps: 5),
          ),
        );

        await repo.deleteSet(s2.id);

        final s4 = await repo.createSet(
          exerciseId: exercise.id,
          plannedValues: PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.fixed(reps: 5),
          ),
        );
        expect(s4.id, isNotNull);
      } finally {
        await helper.tearDown();
      }
    });
  });
}
