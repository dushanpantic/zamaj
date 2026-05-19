/// Abstract contract for program and workout-day template persistence.
///
/// All method signatures are typed solely in domain terms. No Drift-generated
/// types appear in any public signature (Req 10.1).
library;

import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program.dart';
import 'package:zamaj/modules/domain/models/program_aggregate.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

abstract class ProgramRepository {
  Future<Program> createProgram({required String name});
  Future<Program?> getProgram(String programId);
  Future<List<Program>> listPrograms();
  Future<Program> updateProgram(Program program);
  Future<void> deleteProgram(String programId);

  Future<WorkoutDay> createWorkoutDay({
    required String programId,
    required String name,
  });
  Future<WorkoutDay?> getWorkoutDay(String workoutDayId);
  Future<List<WorkoutDay>> listWorkoutDaysForProgram(String programId);
  Future<WorkoutDay> updateWorkoutDay(WorkoutDay workoutDay);
  Future<void> deleteWorkoutDay(String workoutDayId);
  Future<void> reorderWorkoutDays(
    String programId,
    List<String> orderedWorkoutDayIds,
  );

  Future<ExerciseGroup> createExerciseGroup({
    required String workoutDayId,
    required ExerciseGroupKind kind,
    required List<Exercise> exercises,
    ExerciseGroupRole role = ExerciseGroupRole.main,
  });
  Future<ExerciseGroup?> getExerciseGroup(String exerciseGroupId);
  Future<ExerciseGroup> updateExerciseGroup(ExerciseGroup group);
  Future<void> deleteExerciseGroup(String exerciseGroupId);
  Future<void> reorderExerciseGroups(
    String workoutDayId,
    List<String> orderedGroupIds,
  );

  Future<Exercise> createExercise({
    required String exerciseGroupId,
    required String name,
    required MeasurementType measurementType,
    ExerciseMetadata metadata = ExerciseMetadata.empty,
    int? plannedRestSeconds,
  });
  Future<Exercise?> getExercise(String exerciseId);
  Future<Exercise> updateExercise(Exercise exercise);
  Future<void> deleteExercise(String exerciseId);
  Future<void> reorderExercises(
    String exerciseGroupId,
    List<String> orderedExerciseIds,
  );

  Future<WorkoutSet> createSet({
    required String exerciseId,
    required PlannedSetValues plannedValues,
  });
  Future<WorkoutSet> updateSet(WorkoutSet set);
  Future<void> deleteSet(String setId);
  Future<void> reorderSets(String exerciseId, List<String> orderedSetIds);

  Future<Program> saveProgramAggregate(ProgramAggregate aggregate);
}
