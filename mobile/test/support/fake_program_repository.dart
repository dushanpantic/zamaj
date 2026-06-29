import 'package:uuid/uuid.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// In-memory [ProgramRepository] test double.
///
/// Implements just enough for the program-list/create tests — `createProgram`,
/// `listPrograms`, and `getProgram` are backed by an in-memory list; every other
/// method throws [UnimplementedError] so a test that depends on it fails loudly
/// rather than silently no-op'ing. Set [createProgramError] to make the next
/// `createProgram` throw.
class FakeProgramRepository implements ProgramRepository {
  FakeProgramRepository();

  final _uuid = const Uuid();

  /// Programs currently "persisted", in insertion order.
  final List<Program> programs = [];

  /// Names passed to [createProgram], in call order — lets a test assert the
  /// number of inserts (exactly one per create).
  final List<String> createProgramCalls = [];

  /// When non-null, the next [createProgram] throws this instead of inserting.
  Object? createProgramError;

  @override
  Future<Program> createProgram({required String name}) async {
    createProgramCalls.add(name);
    final error = createProgramError;
    if (error != null) throw error;
    final now = DateTime.now().toUtc();
    final program = Program(
      id: _uuid.v4(),
      name: name,
      workoutDayIds: const [],
      createdAt: now,
      updatedAt: now,
      schemaVersion: SchemaVersions.domain,
    );
    programs.add(program);
    return program;
  }

  @override
  Future<List<Program>> listPrograms() async => List.of(programs);

  @override
  Future<Program?> getProgram(String programId) async {
    for (final program in programs) {
      if (program.id == programId) return program;
    }
    return null;
  }

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
  Future<WorkoutDay> duplicateWorkoutDay(String workoutDayId) =>
      throw UnimplementedError();

  @override
  Future<ExerciseGroup> createExerciseGroup({
    required String workoutDayId,
    required ExerciseGroupKind kind,
    required List<Exercise> exercises,
    ExerciseGroupRole role = ExerciseGroupRole.main,
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
    String? libraryExerciseId,
  }) => throw UnimplementedError();

  @override
  Future<Exercise?> getExercise(String exerciseId) =>
      throw UnimplementedError();

  @override
  Future<Exercise> updateExercise(Exercise exercise) =>
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

  @override
  Future<Program> saveProgramAggregate(ProgramAggregate aggregate) =>
      throw UnimplementedError();
}
