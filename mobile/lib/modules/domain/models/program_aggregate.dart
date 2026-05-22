import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';

part 'program_aggregate.freezed.dart';

@freezed
abstract class ProgramAggregate with _$ProgramAggregate {
  const factory ProgramAggregate({
    required String id,
    required String name,
    required DateTime createdAt,
    required DateTime updatedAt,
    required int schemaVersion,
    required List<WorkoutDayAggregate> workoutDays,
  }) = _ProgramAggregate;
}

@freezed
abstract class WorkoutDayAggregate with _$WorkoutDayAggregate {
  const factory WorkoutDayAggregate({
    required String id,
    required String programId,
    required String name,
    required int position,
    required List<ExerciseGroupAggregate> groups,
  }) = _WorkoutDayAggregate;
}

@freezed
abstract class ExerciseGroupAggregate with _$ExerciseGroupAggregate {
  const factory ExerciseGroupAggregate({
    required String id,
    required String workoutDayId,
    required ExerciseGroupKind kind,
    required int position,
    required List<ExerciseAggregate> exercises,
    @Default(ExerciseGroupRole.main) ExerciseGroupRole role,
  }) = _ExerciseGroupAggregate;
}

@freezed
abstract class ExerciseAggregate with _$ExerciseAggregate {
  const factory ExerciseAggregate({
    required String id,
    required String groupId,
    required String name,
    required MeasurementType measurementType,
    required ExerciseMetadata metadata,
    required int? plannedRestSeconds,
    required String? libraryExerciseId,
    required int position,
    required List<WorkoutSetAggregate> sets,
  }) = _ExerciseAggregate;
}

@freezed
abstract class WorkoutSetAggregate with _$WorkoutSetAggregate {
  const factory WorkoutSetAggregate({
    required String id,
    required String exerciseId,
    required PlannedSetValues values,
    required int position,
  }) = _WorkoutSetAggregate;
}
