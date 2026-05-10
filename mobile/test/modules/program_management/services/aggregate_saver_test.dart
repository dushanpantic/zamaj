import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/program_management/program_management.dart';

import '../../../support/in_memory_app_database.dart';

class _ThrowingProgramRepository implements ProgramRepository {
  final DomainError error;

  _ThrowingProgramRepository(this.error);

  @override
  Future<Program> saveProgramAggregate(ProgramAggregate aggregate) async {
    throw error;
  }

  @override
  Future<Program> createProgram({required String name}) =>
      throw UnimplementedError();

  @override
  Future<Program?> getProgram(String programId) => throw UnimplementedError();

  @override
  Future<List<Program>> listPrograms() => throw UnimplementedError();

  @override
  Future<Program> updateProgram(Program program) => throw UnimplementedError();

  @override
  Future<void> deleteProgram(String programId) => throw UnimplementedError();

  @override
  Future<WorkoutDay> createWorkoutDay({
    required String programId,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<WorkoutDay?> getWorkoutDay(String workoutDayId) =>
      throw UnimplementedError();

  @override
  Future<List<WorkoutDay>> listWorkoutDaysForProgram(String programId) =>
      throw UnimplementedError();

  @override
  Future<WorkoutDay> updateWorkoutDay(WorkoutDay workoutDay) =>
      throw UnimplementedError();

  @override
  Future<void> deleteWorkoutDay(String workoutDayId) =>
      throw UnimplementedError();

  @override
  Future<void> reorderWorkoutDays(
    String programId,
    List<String> orderedWorkoutDayIds,
  ) => throw UnimplementedError();

  @override
  Future<ExerciseGroup> createExerciseGroup({
    required String workoutDayId,
    required ExerciseGroupKind kind,
    required List<Exercise> exercises,
  }) => throw UnimplementedError();

  @override
  Future<ExerciseGroup> updateExerciseGroup(ExerciseGroup group) =>
      throw UnimplementedError();

  @override
  Future<void> deleteExerciseGroup(String exerciseGroupId) =>
      throw UnimplementedError();

  @override
  Future<void> reorderExerciseGroups(
    String workoutDayId,
    List<String> orderedGroupIds,
  ) => throw UnimplementedError();

  @override
  Future<Exercise> createExercise({
    required String exerciseGroupId,
    required String name,
    required MeasurementType measurementType,
    ExerciseMetadata metadata = ExerciseMetadata.empty,
    int? plannedRestSeconds,
  }) => throw UnimplementedError();

  @override
  Future<Exercise> updateExercise(Exercise exercise) =>
      throw UnimplementedError();

  @override
  Future<Exercise?> getExercise(String exerciseId) =>
      throw UnimplementedError();

  @override
  Future<void> deleteExercise(String exerciseId) => throw UnimplementedError();

  @override
  Future<void> reorderExercises(
    String exerciseGroupId,
    List<String> orderedExerciseIds,
  ) => throw UnimplementedError();

  @override
  Future<WorkoutSet> createSet({
    required String exerciseId,
    required PlannedSetValues plannedValues,
  }) => throw UnimplementedError();

  @override
  Future<WorkoutSet> updateSet(WorkoutSet set) => throw UnimplementedError();

  @override
  Future<void> deleteSet(String setId) => throw UnimplementedError();

  @override
  Future<void> reorderSets(String exerciseId, List<String> orderedSetIds) =>
      throw UnimplementedError();
}

ProgramDraft _buildDraft() {
  return const ProgramDraft(
    programId: null,
    name: 'Test Program',
    schemaVersion: null,
    workoutDays: [
      WorkoutDayDraft(
        draftId: 'day-draft-1',
        persistedId: null,
        name: 'Day A',
        groups: [
          ExerciseGroupDraft(
            draftId: 'group-draft-1',
            persistedId: null,
            exercises: [
              ExerciseDraft(
                draftId: 'exercise-draft-1',
                persistedId: null,
                name: 'Squat',
                measurementType: MeasurementType.repBased(),
                metadata: ExerciseMetadata.empty,
                plannedRestSeconds: 90,
                sets: [
                  PlannedSetDraft(
                    draftId: 'set-draft-1',
                    persistedId: null,
                    values: PlannedSetDraftValues.repBased(
                      weightInput: '100',
                      repsInput: '5',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('AggregateSaver', () {
    group('happy-path save', () {
      late InMemoryDatabaseHelper dbHelper;
      late AggregateSaver saver;

      setUp(() async {
        dbHelper = InMemoryDatabaseHelper();
        await dbHelper.setUp();
        final repo = DriftProgramRepository(db: dbHelper.db);
        saver = AggregateSaver(repo);
      });

      tearDown(() async {
        await dbHelper.tearDown();
      });

      test('returns a Program with a non-null id and matching name', () async {
        final draft = _buildDraft();

        final program = await saver.save(draft);

        expect(program.id, isNotEmpty);
        expect(program.name, equals('Test Program'));
      });

      test('saved program can be loaded back via the repository', () async {
        final draft = _buildDraft();
        final repo = DriftProgramRepository(db: dbHelper.db);

        final saved = await saver.save(draft);
        final loaded = await repo.getProgram(saved.id);

        expect(loaded, isNotNull);
        expect(loaded!.id, equals(saved.id));
        expect(loaded.name, equals('Test Program'));
      });

      test('saved program has the expected workout day count', () async {
        final draft = _buildDraft();

        final saved = await saver.save(draft);

        expect(saved.workoutDayIds, hasLength(1));
      });
    });

    group('DomainError propagation', () {
      test('propagates ValidationError thrown by repository', () async {
        const error = ValidationError(
          entityId: 'some-id',
          invariant: 'test_invariant',
          message: 'test error',
        );
        final repo = _ThrowingProgramRepository(error);
        final saver = AggregateSaver(repo);
        final draft = _buildDraft();

        expect(() => saver.save(draft), throwsA(same(error)));
      });

      test('does not swallow DomainError — error type is preserved', () async {
        const error = ValidationError(
          entityId: 'some-id',
          invariant: 'test_invariant',
          message: 'test error',
        );
        final repo = _ThrowingProgramRepository(error);
        final saver = AggregateSaver(repo);
        final draft = _buildDraft();

        expect(() => saver.save(draft), throwsA(isA<ValidationError>()));
      });
    });

    group('source ProgramDraft not mutated after save', () {
      late InMemoryDatabaseHelper dbHelper;
      late AggregateSaver saver;

      setUp(() async {
        dbHelper = InMemoryDatabaseHelper();
        await dbHelper.setUp();
        final repo = DriftProgramRepository(db: dbHelper.db);
        saver = AggregateSaver(repo);
      });

      tearDown(() async {
        await dbHelper.tearDown();
      });

      test('draft reference equals its original value after save', () async {
        final draft = _buildDraft();
        final originalProgramId = draft.programId;
        final originalName = draft.name;
        final originalWorkoutDays = draft.workoutDays;

        await saver.save(draft);

        expect(draft.programId, equals(originalProgramId));
        expect(draft.name, equals(originalName));
        expect(draft.workoutDays, equals(originalWorkoutDays));
      });

      test('draft is identical to its original value after save', () async {
        final draft = _buildDraft();
        final originalDraft = draft;

        await saver.save(draft);

        expect(draft, equals(originalDraft));
      });
    });
  });
}
