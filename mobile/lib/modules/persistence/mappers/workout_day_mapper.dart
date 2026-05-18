import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/domain/models/workout_set.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart';

class WorkoutDayMapper {
  domain.WorkoutDay toDomain(
    WorkoutDay row,
    List<ExerciseGroup> groupRows,
    List<Exercise> exerciseRows,
    List<WorkoutSet> setRows,
  ) {
    final exerciseGroups =
        groupRows.where((g) => g.workoutDayId == row.id).toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    return domain.WorkoutDay(
      id: row.id,
      programId: row.programId,
      name: row.name,
      exerciseGroups: exerciseGroups
          .map((g) => _groupToDomain(g, exerciseRows, setRows))
          .toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  domain.ExerciseGroup _groupToDomain(
    ExerciseGroup row,
    List<Exercise> exerciseRows,
    List<WorkoutSet> setRows,
  ) {
    final exercises =
        exerciseRows.where((e) => e.exerciseGroupId == row.id).toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    final kind = ExerciseGroupKind.fromJson(
      jsonDecode(row.kindPayloadJson) as Map<String, dynamic>,
    );

    return domain.ExerciseGroup(
      id: row.id,
      workoutDayId: row.workoutDayId,
      position: row.position,
      kind: kind,
      exercises: exercises.map((e) => _exerciseToDomain(e, setRows)).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  domain.Exercise exerciseToDomain(Exercise row, List<WorkoutSet> setRows) =>
      _exerciseToDomain(row, setRows);

  domain.Exercise _exerciseToDomain(Exercise row, List<WorkoutSet> setRows) {
    final sets = setRows.where((s) => s.exerciseId == row.id).toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    final measurementType = MeasurementType.fromJson(
      jsonDecode(row.measurementTypePayloadJson) as Map<String, dynamic>,
    );

    return domain.Exercise(
      id: row.id,
      exerciseGroupId: row.exerciseGroupId,
      position: row.position,
      name: row.name,
      measurementType: measurementType,
      metadata: ExerciseMetadata(notes: row.notes, videoUrl: row.videoUrl),
      plannedRestSeconds: row.plannedRestSeconds,
      sets: sets.map(_setToDomain).toList(),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  domain.WorkoutSet setToDomain(WorkoutSet row) => _setToDomain(row);

  domain.WorkoutSet _setToDomain(WorkoutSet row) {
    final plannedValues = PlannedSetValues.fromJson(
      jsonDecode(row.plannedValuesPayloadJson) as Map<String, dynamic>,
    );

    final measurementType = switch (plannedValues) {
      PlannedRepBased() => const MeasurementType.repBased(),
      PlannedTimeBased() => const MeasurementType.timeBased(),
      PlannedBodyweight() => const MeasurementType.bodyweight(),
    };

    return domain.WorkoutSet(
      id: row.id,
      exerciseId: row.exerciseId,
      position: row.position,
      measurementType: measurementType,
      plannedValues: plannedValues,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        row.createdAtMs,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        row.updatedAtMs,
        isUtc: true,
      ),
      schemaVersion: row.schemaVersion,
    );
  }

  WorkoutDaysCompanion workoutDayToRow(domain.WorkoutDay domain) {
    return WorkoutDaysCompanion(
      id: Value(domain.id),
      programId: Value(domain.programId),
      name: Value(domain.name),
      createdAtMs: Value(domain.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(domain.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(domain.schemaVersion),
    );
  }

  ExerciseGroupsCompanion exerciseGroupToRow(domain.ExerciseGroup group) {
    final kindJson = group.kind.toJson();
    return ExerciseGroupsCompanion(
      id: Value(group.id),
      workoutDayId: Value(group.workoutDayId),
      position: Value(group.position),
      kindDiscriminator: Value(kindJson['type'] as String),
      kindPayloadJson: Value(CanonicalJson.encode(kindJson)),
      createdAtMs: Value(group.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(group.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(group.schemaVersion),
    );
  }

  ExercisesCompanion exerciseToRow(domain.Exercise exercise) {
    final measurementJson = exercise.measurementType.toJson();
    return ExercisesCompanion(
      id: Value(exercise.id),
      exerciseGroupId: Value(exercise.exerciseGroupId),
      position: Value(exercise.position),
      name: Value(exercise.name),
      measurementTypeDiscriminator: Value(measurementJson['type'] as String),
      measurementTypePayloadJson: Value(CanonicalJson.encode(measurementJson)),
      notes: Value(exercise.metadata.notes),
      videoUrl: Value(exercise.metadata.videoUrl),
      plannedRestSeconds: Value(exercise.plannedRestSeconds),
      createdAtMs: Value(exercise.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(exercise.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(exercise.schemaVersion),
    );
  }

  WorkoutSetsCompanion setToRow(domain.WorkoutSet set) {
    final plannedJson = set.plannedValues.toJson();
    return WorkoutSetsCompanion(
      id: Value(set.id),
      exerciseId: Value(set.exerciseId),
      position: Value(set.position),
      plannedValuesDiscriminator: Value(plannedJson['type'] as String),
      plannedValuesPayloadJson: Value(CanonicalJson.encode(plannedJson)),
      createdAtMs: Value(set.createdAt.millisecondsSinceEpoch),
      updatedAtMs: Value(set.updatedAt.millisecondsSinceEpoch),
      schemaVersion: Value(set.schemaVersion),
    );
  }
}
