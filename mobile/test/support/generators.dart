import 'dart:math';

import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

String anyUuidV4(Random rng) {
  final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
  bytes[6] = (bytes[6] & 0x0f) | 0x40;
  bytes[8] = (bytes[8] & 0x3f) | 0x80;

  String hex(int b) => b.toRadixString(16).padLeft(2, '0');
  final b = bytes.map(hex).toList();
  return '${b[0]}${b[1]}${b[2]}${b[3]}'
      '-${b[4]}${b[5]}'
      '-${b[6]}${b[7]}'
      '-${b[8]}${b[9]}'
      '-${b[10]}${b[11]}${b[12]}${b[13]}${b[14]}${b[15]}';
}

DateTime anyUtcDateTime(Random rng) {
  final base = DateTime.utc(2020).millisecondsSinceEpoch;
  final offsetMs = rng.nextInt(4000000000);
  return DateTime.fromMillisecondsSinceEpoch(base + offsetMs, isUtc: true);
}

MeasurementType anyMeasurementType(Random rng) {
  return rng.nextBool()
      ? const MeasurementType.repBased()
      : const MeasurementType.timeBased();
}

ExerciseGroupKind anyExerciseGroupKind(Random rng) {
  return rng.nextBool()
      ? const ExerciseGroupKind.single()
      : const ExerciseGroupKind.superset();
}

ExerciseMetadata anyExerciseMetadata(Random rng) {
  final hasNotes = rng.nextBool();
  final hasVideo = rng.nextBool();
  return ExerciseMetadata(
    notes: hasNotes ? _anyString(rng, maxLen: 80) : null,
    videoUrl: hasVideo ? 'https://example.com/${anyUuidV4(rng)}' : null,
  );
}

SubstituteExercise anySubstituteExercise(Random rng) {
  final mt = anyMeasurementType(rng);
  return SubstituteExercise(
    name: _anyString(rng, maxLen: 40),
    measurementType: mt,
    metadata: rng.nextBool() ? anyExerciseMetadata(rng) : null,
  );
}

ExerciseState anyExerciseState(Random rng) {
  switch (rng.nextInt(4)) {
    case 0:
      return const ExerciseState.unfinished();
    case 1:
      return const ExerciseState.completed();
    case 2:
      return const ExerciseState.skipped();
    default:
      return ExerciseState.replaced(substitute: anySubstituteExercise(rng));
  }
}

PlannedSetValues anyPlannedSetValues(Random rng) {
  if (rng.nextBool()) {
    return PlannedSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    );
  }
  return PlannedSetValues.timeBased(durationSeconds: rng.nextInt(300));
}

PlannedSetValues anyPlannedSetValuesForMeasurement(
  Random rng,
  MeasurementType mt,
) {
  return mt.when(
    repBased: () => PlannedSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    ),
    timeBased: () =>
        PlannedSetValues.timeBased(durationSeconds: rng.nextInt(300)),
  );
}

ActualSetValues anyActualSetValues(Random rng) {
  if (rng.nextBool()) {
    return ActualSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    );
  }
  return ActualSetValues.timeBased(durationSeconds: rng.nextInt(300));
}

ActualSetValues anyActualSetValuesForMeasurement(
  Random rng,
  MeasurementType mt,
) {
  return mt.when(
    repBased: () => ActualSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    ),
    timeBased: () =>
        ActualSetValues.timeBased(durationSeconds: rng.nextInt(300)),
  );
}

double _anyWeightKg(Random rng) {
  final halfKgs = rng.nextInt(401);
  return halfKgs * 0.5;
}

String _anyString(Random rng, {required int maxLen}) {
  const chars =
      'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789 ';
  final len = 1 + rng.nextInt(maxLen);
  return String.fromCharCodes(
    List.generate(len, (_) => chars.codeUnitAt(rng.nextInt(chars.length))),
  );
}

WorkoutSet anyWorkoutSet(Random rng, MeasurementType measurementType) {
  return WorkoutSet(
    id: anyUuidV4(rng),
    exerciseId: anyUuidV4(rng),
    position: rng.nextInt(10),
    measurementType: measurementType,
    plannedValues: anyPlannedSetValuesForMeasurement(rng, measurementType),
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

Exercise anyExercise(Random rng) {
  final mt = anyMeasurementType(rng);
  final setCount = 1 + rng.nextInt(5);
  return Exercise(
    id: anyUuidV4(rng),
    exerciseGroupId: anyUuidV4(rng),
    position: rng.nextInt(10),
    name: _anyString(rng, maxLen: 40),
    measurementType: mt,
    metadata: anyExerciseMetadata(rng),
    sets: List.generate(setCount, (i) {
      final s = anyWorkoutSet(rng, mt);
      return WorkoutSet(
        id: s.id,
        exerciseId: s.exerciseId,
        position: i,
        measurementType: mt,
        plannedValues: s.plannedValues,
        createdAt: s.createdAt,
        updatedAt: s.updatedAt,
        schemaVersion: s.schemaVersion,
      );
    }),
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

ExerciseGroup anyExerciseGroup(Random rng) {
  final kind = anyExerciseGroupKind(rng);
  final exerciseCount = kind.when(
    single: () => 1,
    superset: () => 2 + rng.nextInt(3),
  );
  final exercises = List.generate(exerciseCount, (i) {
    final e = anyExercise(rng);
    return Exercise(
      id: e.id,
      exerciseGroupId: e.exerciseGroupId,
      position: i,
      name: e.name,
      measurementType: e.measurementType,
      metadata: e.metadata,
      sets: e.sets,
      createdAt: e.createdAt,
      updatedAt: e.updatedAt,
      schemaVersion: e.schemaVersion,
    );
  });
  return ExerciseGroup(
    id: anyUuidV4(rng),
    workoutDayId: anyUuidV4(rng),
    position: rng.nextInt(10),
    kind: kind,
    exercises: exercises,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

WorkoutDay anyWorkoutDay(Random rng) {
  final groupCount = 1 + rng.nextInt(4);
  final groups = List.generate(groupCount, (i) {
    final g = anyExerciseGroup(rng);
    return ExerciseGroup(
      id: g.id,
      workoutDayId: g.workoutDayId,
      position: i,
      kind: g.kind,
      exercises: g.exercises,
      createdAt: g.createdAt,
      updatedAt: g.updatedAt,
      schemaVersion: g.schemaVersion,
    );
  });
  return WorkoutDay(
    id: anyUuidV4(rng),
    programId: anyUuidV4(rng),
    name: _anyString(rng, maxLen: 40),
    exerciseGroups: groups,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

Program anyProgram(Random rng) {
  final dayCount = 1 + rng.nextInt(6);
  return Program(
    id: anyUuidV4(rng),
    name: _anyString(rng, maxLen: 40),
    workoutDayIds: List.generate(dayCount, (_) => anyUuidV4(rng)),
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

/// Returns the constructor arguments for an [Exercise] where at least one
/// [WorkoutSet] has a [MeasurementType] that does not match the exercise's own.
/// Callers are expected to pass these to [Exercise()] and assert [ValidationError].
({
  String id,
  String exerciseGroupId,
  MeasurementType measurementType,
  List<WorkoutSet> sets,
})
anyInconsistentExercise(Random rng) {
  final exerciseMt = anyMeasurementType(rng);
  final mismatchedMt = exerciseMt.when(
    repBased: () => const MeasurementType.timeBased(),
    timeBased: () => const MeasurementType.repBased(),
  );
  final goodSet = anyWorkoutSet(rng, exerciseMt);
  final badSet = anyWorkoutSet(rng, mismatchedMt);
  return (
    id: anyUuidV4(rng),
    exerciseGroupId: anyUuidV4(rng),
    measurementType: exerciseMt,
    sets: [goodSet, badSet],
  );
}
