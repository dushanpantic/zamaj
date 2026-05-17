import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';

void main() {
  late AppDatabase db;
  late DriftProgramRepository repo;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repo = DriftProgramRepository(db: db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<domain.Exercise> makeExercise() async {
    final program = await repo.createProgram(name: 'P');
    final day = await repo.createWorkoutDay(programId: program.id, name: 'D');
    final group = await repo.createExerciseGroup(
      workoutDayId: day.id,
      kind: const ExerciseGroupKind.single(),
      exercises: [
        domain.Exercise(
          id: '00000000-0000-4000-8000-000000000001',
          exerciseGroupId: '',
          position: 0,
          name: 'Placeholder',
          measurementType: const MeasurementType.repBased(),
          metadata: ExerciseMetadata.empty,
          sets: [],
          createdAt: DateTime.utc(2024),
          updatedAt: DateTime.utc(2024),
          schemaVersion: 1,
        ),
      ],
    );
    return group.exercises.first;
  }

  group('cascade delete', () {
    test('deleting a program removes all child rows', () async {
      final program = await repo.createProgram(name: 'Push Pull Legs');
      final day = await repo.createWorkoutDay(
        programId: program.id,
        name: 'Push Day',
      );
      final group = await repo.createExerciseGroup(
        workoutDayId: day.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          domain.Exercise(
            id: '00000000-0000-4000-8000-000000000001',
            exerciseGroupId: '',
            position: 0,
            name: 'Bench Press',
            measurementType: const MeasurementType.repBased(),
            metadata: ExerciseMetadata.empty,
            sets: [],
            createdAt: DateTime.utc(2024),
            updatedAt: DateTime.utc(2024),
            schemaVersion: 1,
          ),
        ],
      );
      await repo.createSet(
        exerciseId: group.exercises.first.id,
        plannedValues: PlannedSetValues.repBased(
          weightKg: 80,
          repTarget: RepTarget.fixed(reps: 5),
        ),
      );

      await repo.deleteProgram(program.id);

      final programRows = await db.select(db.programs).get();
      final dayRows = await db.select(db.workoutDays).get();
      final groupRows = await db.select(db.exerciseGroups).get();
      final exerciseRows = await db.select(db.exercises).get();
      final setRows = await db.select(db.workoutSets).get();
      final pwdRows = await db.select(db.programWorkoutDays).get();

      expect(programRows, isEmpty);
      expect(dayRows, isEmpty);
      expect(groupRows, isEmpty);
      expect(exerciseRows, isEmpty);
      expect(setRows, isEmpty);
      expect(pwdRows, isEmpty);
    });

    test(
      'deleting a workout day cascades to groups, exercises, and sets',
      () async {
        final program = await repo.createProgram(name: 'Program A');
        final day = await repo.createWorkoutDay(
          programId: program.id,
          name: 'Day 1',
        );
        final group = await repo.createExerciseGroup(
          workoutDayId: day.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: '00000000-0000-4000-8000-000000000002',
              exerciseGroupId: '',
              position: 0,
              name: 'Squat',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );
        await repo.createSet(
          exerciseId: group.exercises.first.id,
          plannedValues: PlannedSetValues.repBased(
            weightKg: 100,
            repTarget: RepTarget.fixed(reps: 3),
          ),
        );

        await repo.deleteWorkoutDay(day.id);

        final dayRows = await db.select(db.workoutDays).get();
        final groupRows = await db.select(db.exerciseGroups).get();
        final exerciseRows = await db.select(db.exercises).get();
        final setRows = await db.select(db.workoutSets).get();

        expect(dayRows, isEmpty);
        expect(groupRows, isEmpty);
        expect(exerciseRows, isEmpty);
        expect(setRows, isEmpty);
      },
    );
  });

  group('reorder rejects unknown ids', () {
    test(
      'reorderWorkoutDays throws NotFoundError for unknown day id',
      () async {
        final program = await repo.createProgram(name: 'Program');
        await repo.createWorkoutDay(programId: program.id, name: 'Day 1');

        expect(
          () => repo.reorderWorkoutDays(program.id, [
            '00000000-0000-4000-8000-000000000099',
          ]),
          throwsA(isA<NotFoundError>()),
        );
      },
    );

    test(
      'reorderExerciseGroups throws NotFoundError for unknown group id',
      () async {
        final program = await repo.createProgram(name: 'Program');
        final day = await repo.createWorkoutDay(
          programId: program.id,
          name: 'Day 1',
        );
        await repo.createExerciseGroup(
          workoutDayId: day.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: '00000000-0000-4000-8000-000000000003',
              exerciseGroupId: '',
              position: 0,
              name: 'Deadlift',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );

        expect(
          () => repo.reorderExerciseGroups(day.id, [
            '00000000-0000-4000-8000-000000000099',
          ]),
          throwsA(isA<NotFoundError>()),
        );
      },
    );

    test(
      'reorderExercises throws NotFoundError for unknown exercise id',
      () async {
        final program = await repo.createProgram(name: 'Program');
        final day = await repo.createWorkoutDay(
          programId: program.id,
          name: 'Day 1',
        );
        final group = await repo.createExerciseGroup(
          workoutDayId: day.id,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: '00000000-0000-4000-8000-000000000004',
              exerciseGroupId: '',
              position: 0,
              name: 'Deadlift',
              measurementType: const MeasurementType.repBased(),
              metadata: ExerciseMetadata.empty,
              sets: [],
              createdAt: DateTime.utc(2024),
              updatedAt: DateTime.utc(2024),
              schemaVersion: 1,
            ),
          ],
        );

        expect(
          () => repo.reorderExercises(group.id, [
            '00000000-0000-4000-8000-000000000099',
          ]),
          throwsA(isA<NotFoundError>()),
        );
      },
    );

    test('reorderSets throws NotFoundError for unknown set id', () async {
      final exercise = await makeExercise();
      await repo.createSet(
        exerciseId: exercise.id,
        plannedValues: PlannedSetValues.repBased(
          weightKg: 60,
          repTarget: RepTarget.fixed(reps: 8),
        ),
      );

      expect(
        () => repo.reorderSets(exercise.id, [
          '00000000-0000-4000-8000-000000000099',
        ]),
        throwsA(isA<NotFoundError>()),
      );
    });
  });

  group('basic CRUD', () {
    test(
      'createProgram returns program with correct name and empty day list',
      () async {
        final program = await repo.createProgram(name: 'Strength Block');
        expect(program.name, 'Strength Block');
        expect(program.workoutDayIds, isEmpty);
        expect(program.id.length, 36);
        expect(program.schemaVersion, SchemaVersions.domain);
      },
    );

    test('getProgram returns null for unknown id', () async {
      final result = await repo.getProgram(
        '00000000-0000-4000-8000-000000000000',
      );
      expect(result, isNull);
    });

    test('listPrograms returns all created programs', () async {
      await repo.createProgram(name: 'A');
      await repo.createProgram(name: 'B');
      final programs = await repo.listPrograms();
      expect(programs.length, 2);
    });

    test('updateProgram throws NotFoundError for unknown id', () async {
      final program = await repo.createProgram(name: 'Test');
      final modified = program.copyWith(
        id: '00000000-0000-4000-8000-000000000000',
        name: 'Modified',
      );
      expect(() => repo.updateProgram(modified), throwsA(isA<NotFoundError>()));
    });

    test('createWorkoutDay adds day to program workoutDayIds', () async {
      final program = await repo.createProgram(name: 'Program');
      await repo.createWorkoutDay(programId: program.id, name: 'Day A');
      await repo.createWorkoutDay(programId: program.id, name: 'Day B');

      final updated = await repo.getProgram(program.id);
      expect(updated!.workoutDayIds.length, 2);
    });

    test('getWorkoutDay returns fully hydrated aggregate', () async {
      final program = await repo.createProgram(name: 'Program');
      final day = await repo.createWorkoutDay(
        programId: program.id,
        name: 'Upper',
      );
      final group = await repo.createExerciseGroup(
        workoutDayId: day.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          domain.Exercise(
            id: '00000000-0000-4000-8000-000000000005',
            exerciseGroupId: '',
            position: 0,
            name: 'Pull-up',
            measurementType: const MeasurementType.repBased(),
            metadata: ExerciseMetadata.empty,
            sets: [],
            createdAt: DateTime.utc(2024),
            updatedAt: DateTime.utc(2024),
            schemaVersion: 1,
          ),
        ],
      );
      await repo.createSet(
        exerciseId: group.exercises.first.id,
        plannedValues: PlannedSetValues.repBased(
          weightKg: 0,
          repTarget: RepTarget.fixed(reps: 10),
        ),
      );

      final loaded = await repo.getWorkoutDay(day.id);
      expect(loaded, isNotNull);
      expect(loaded!.exerciseGroups.length, 1);
      expect(loaded.exerciseGroups.first.exercises.length, 1);
      expect(loaded.exerciseGroups.first.exercises.first.sets.length, 1);
    });

    test('reorderWorkoutDays updates positions correctly', () async {
      final program = await repo.createProgram(name: 'Program');
      final day1 = await repo.createWorkoutDay(
        programId: program.id,
        name: 'Day 1',
      );
      final day2 = await repo.createWorkoutDay(
        programId: program.id,
        name: 'Day 2',
      );

      await repo.reorderWorkoutDays(program.id, [day2.id, day1.id]);

      final updated = await repo.getProgram(program.id);
      expect(updated!.workoutDayIds.first, day2.id);
      expect(updated.workoutDayIds.last, day1.id);
    });

    test('reorderExerciseGroups updates positions correctly', () async {
      final program = await repo.createProgram(name: 'Program');
      final day = await repo.createWorkoutDay(
        programId: program.id,
        name: 'Day',
      );
      final g1 = await repo.createExerciseGroup(
        workoutDayId: day.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          domain.Exercise(
            id: '00000000-0000-4000-8000-000000000006',
            exerciseGroupId: '',
            position: 0,
            name: 'Ex1',
            measurementType: const MeasurementType.repBased(),
            metadata: ExerciseMetadata.empty,
            sets: [],
            createdAt: DateTime.utc(2024),
            updatedAt: DateTime.utc(2024),
            schemaVersion: 1,
          ),
        ],
      );
      final g2 = await repo.createExerciseGroup(
        workoutDayId: day.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          domain.Exercise(
            id: '00000000-0000-4000-8000-000000000007',
            exerciseGroupId: '',
            position: 0,
            name: 'Ex2',
            measurementType: const MeasurementType.repBased(),
            metadata: ExerciseMetadata.empty,
            sets: [],
            createdAt: DateTime.utc(2024),
            updatedAt: DateTime.utc(2024),
            schemaVersion: 1,
          ),
        ],
      );

      await repo.reorderExerciseGroups(day.id, [g2.id, g1.id]);

      final loaded = await repo.getWorkoutDay(day.id);
      expect(loaded!.exerciseGroups.first.id, g2.id);
      expect(loaded.exerciseGroups.last.id, g1.id);
    });

    test('reorderSets updates positions correctly', () async {
      final exercise = await makeExercise();
      final s1 = await repo.createSet(
        exerciseId: exercise.id,
        plannedValues: PlannedSetValues.repBased(
          weightKg: 20,
          repTarget: RepTarget.fixed(reps: 10),
        ),
      );
      final s2 = await repo.createSet(
        exerciseId: exercise.id,
        plannedValues: PlannedSetValues.repBased(
          weightKg: 22.5,
          repTarget: RepTarget.fixed(reps: 8),
        ),
      );

      await repo.reorderSets(exercise.id, [s2.id, s1.id]);

      final exerciseRow = await (db.select(
        db.exercises,
      )..where((t) => t.id.equals(exercise.id))).getSingle();
      final groupRow = await (db.select(
        db.exerciseGroups,
      )..where((t) => t.id.equals(exerciseRow.exerciseGroupId))).getSingle();
      final loaded = await repo.getWorkoutDay(groupRow.workoutDayId);
      final sets = loaded!.exerciseGroups.first.exercises.first.sets;
      expect(sets.first.id, s2.id);
      expect(sets.last.id, s1.id);
    });
  });

  group('timestamp monotonicity', () {
    test('updatedAt is non-decreasing across updates', () async {
      final program = await repo.createProgram(name: 'Program');
      final updated1 = await repo.updateProgram(
        program.copyWith(name: 'Program v2'),
      );
      final updated2 = await repo.updateProgram(
        updated1.copyWith(name: 'Program v3'),
      );

      expect(
        updated1.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(program.updatedAt.millisecondsSinceEpoch),
      );
      expect(
        updated2.updatedAt.millisecondsSinceEpoch,
        greaterThanOrEqualTo(updated1.updatedAt.millisecondsSinceEpoch),
      );
    });

    test('createdAt is stable across updates', () async {
      final program = await repo.createProgram(name: 'Program');
      final updated = await repo.updateProgram(
        program.copyWith(name: 'Program v2'),
      );
      expect(
        updated.createdAt.millisecondsSinceEpoch,
        program.createdAt.millisecondsSinceEpoch,
      );
    });
  });
}
