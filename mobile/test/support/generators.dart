import 'dart:math';

import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/clock.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_note.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/log_target.dart';
import 'package:zamaj/modules/domain/services/session_state.dart';

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
  return switch (rng.nextInt(3)) {
    0 => const MeasurementType.repBased(),
    1 => const MeasurementType.timeBased(),
    _ => const MeasurementType.bodyweight(),
  };
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
    plannedValues: anyPlannedSetValuesForMeasurement(rng, mt),
    setCount: 1 + rng.nextInt(5),
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

RepTarget anyRepTarget(Random rng) {
  if (rng.nextBool()) {
    return RepTarget.fixed(reps: rng.nextInt(30));
  }
  final min = rng.nextInt(25);
  // +1 ensures max > min so we always land in valid range territory.
  final max = min + 1 + rng.nextInt(30 - min);
  return RepTarget.range(minReps: min, maxReps: max);
}

PlannedSetValues anyPlannedSetValues(Random rng) {
  return switch (rng.nextInt(3)) {
    0 => PlannedSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      repTarget: anyRepTarget(rng),
    ),
    1 => PlannedSetValues.timeBased(
      durationSeconds: rng.nextInt(300),
      weightKg: _maybeOptionalWeightKg(rng),
    ),
    _ => PlannedSetValues.bodyweight(repTarget: anyRepTarget(rng)),
  };
}

PlannedSetValues anyPlannedSetValuesForMeasurement(
  Random rng,
  MeasurementType mt,
) {
  return mt.when(
    repBased: () => PlannedSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      repTarget: anyRepTarget(rng),
    ),
    timeBased: () => PlannedSetValues.timeBased(
      durationSeconds: rng.nextInt(300),
      weightKg: _maybeOptionalWeightKg(rng),
    ),
    bodyweight: () => PlannedSetValues.bodyweight(repTarget: anyRepTarget(rng)),
  );
}

ActualSetValues anyActualSetValues(Random rng) {
  return switch (rng.nextInt(3)) {
    0 => ActualSetValues.repBased(
      weightKg: _anyWeightKg(rng),
      reps: rng.nextInt(30),
    ),
    1 => ActualSetValues.timeBased(
      durationSeconds: rng.nextInt(300),
      weightKg: _maybeOptionalWeightKg(rng),
    ),
    _ => ActualSetValues.bodyweight(reps: rng.nextInt(30)),
  };
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
    timeBased: () => ActualSetValues.timeBased(
      durationSeconds: rng.nextInt(300),
      weightKg: _maybeOptionalWeightKg(rng),
    ),
    bodyweight: () => ActualSetValues.bodyweight(reps: rng.nextInt(30)),
  );
}

double? _maybeOptionalWeightKg(Random rng) {
  return rng.nextBool() ? _anyWeightKg(rng) : null;
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
    plannedRestSeconds: rng.nextBool() ? rng.nextInt(3601) : null,
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
    timeBased: () => const MeasurementType.bodyweight(),
    bodyweight: () => const MeasurementType.repBased(),
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

ExecutedSet anyExecutedSet(Random rng, MeasurementType measurementType) {
  return ExecutedSet(
    id: anyUuidV4(rng),
    sessionExerciseId: anyUuidV4(rng),
    position: rng.nextInt(10),
    measurementType: measurementType,
    actualValues: anyActualSetValuesForMeasurement(rng, measurementType),
    plannedSetIdInSnapshot: rng.nextBool() ? anyUuidV4(rng) : null,
    completedAt: anyUtcDateTime(rng),
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

SessionExercise anySessionExercise(Random rng) {
  final mt = anyMeasurementType(rng);
  final setCount = rng.nextInt(5);
  return SessionExercise(
    id: anyUuidV4(rng),
    sessionId: anyUuidV4(rng),
    position: rng.nextInt(20),
    plannedExerciseIdInSnapshot: anyUuidV4(rng),
    state: anyExerciseState(rng),
    executedSets: List.generate(setCount, (i) {
      final s = anyExecutedSet(rng, mt);
      return ExecutedSet(
        id: s.id,
        sessionExerciseId: s.sessionExerciseId,
        position: i,
        measurementType: mt,
        actualValues: s.actualValues,
        plannedSetIdInSnapshot: s.plannedSetIdInSnapshot,
        completedAt: s.completedAt,
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

SessionNote anySessionNote(Random rng) {
  return SessionNote(
    id: anyUuidV4(rng),
    sessionId: anyUuidV4(rng),
    body: _anyString(rng, maxLen: 200),
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

ExtraWork anyExtraWork(Random rng) {
  return ExtraWork(
    id: anyUuidV4(rng),
    sessionId: anyUuidV4(rng),
    position: rng.nextInt(10),
    body: _anyString(rng, maxLen: 200),
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

SessionSnapshot anySessionSnapshot(Random rng) {
  final workoutDay = anyWorkoutDay(rng);
  final json = CanonicalJson.encode(workoutDay.toJson());
  final hash = CanonicalJson.sha256Hex(json);
  return SessionSnapshot(
    workoutDay: workoutDay,
    canonicalJson: json,
    sha256Hash: hash,
    capturedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

Session anySession(Random rng) {
  final snapshot = anySessionSnapshot(rng);
  final exerciseCount = 1 + rng.nextInt(5);
  final noteCount = rng.nextInt(3);
  final extraWorkCount = rng.nextInt(3);
  return Session(
    id: anyUuidV4(rng),
    workoutDayId: anyUuidV4(rng),
    snapshot: snapshot,
    sessionExercises: List.generate(exerciseCount, (i) {
      final se = anySessionExercise(rng);
      return SessionExercise(
        id: se.id,
        sessionId: se.sessionId,
        position: i,
        plannedExerciseIdInSnapshot: se.plannedExerciseIdInSnapshot,
        state: se.state,
        executedSets: se.executedSets,
        createdAt: se.createdAt,
        updatedAt: se.updatedAt,
        schemaVersion: se.schemaVersion,
      );
    }),
    notes: List.generate(noteCount, (_) => anySessionNote(rng)),
    extraWork: List.generate(extraWorkCount, (i) {
      final ew = anyExtraWork(rng);
      return ExtraWork(
        id: ew.id,
        sessionId: ew.sessionId,
        position: i,
        body: ew.body,
        createdAt: ew.createdAt,
        updatedAt: ew.updatedAt,
        schemaVersion: ew.schemaVersion,
      );
    }),
    startedAt: anyUtcDateTime(rng),
    endedAt: rng.nextBool() ? anyUtcDateTime(rng) : null,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

// ---------------------------------------------------------------------------
// Program repository operation sequence
// ---------------------------------------------------------------------------

sealed class ProgramRepoOp {}

final class CreateProgramOp extends ProgramRepoOp {
  CreateProgramOp({required this.name});
  final String name;
}

final class UpdateProgramNameOp extends ProgramRepoOp {
  UpdateProgramNameOp({required this.programId, required this.newName});
  final String programId;
  final String newName;
}

final class DeleteProgramOp extends ProgramRepoOp {
  DeleteProgramOp({required this.programId});
  final String programId;
}

final class CreateWorkoutDayOp extends ProgramRepoOp {
  CreateWorkoutDayOp({required this.programId, required this.name});
  final String programId;
  final String name;
}

final class ReorderWorkoutDaysOp extends ProgramRepoOp {
  ReorderWorkoutDaysOp({
    required this.programId,
    required this.orderedWorkoutDayIds,
  });
  final String programId;
  final List<String> orderedWorkoutDayIds;
}

final class CreateExerciseGroupOp extends ProgramRepoOp {
  CreateExerciseGroupOp({
    required this.workoutDayId,
    required this.kind,
    required this.exercises,
  });
  final String workoutDayId;
  final ExerciseGroupKind kind;
  final List<Exercise> exercises;
}

final class ReorderExerciseGroupsOp extends ProgramRepoOp {
  ReorderExerciseGroupsOp({
    required this.workoutDayId,
    required this.orderedGroupIds,
  });
  final String workoutDayId;
  final List<String> orderedGroupIds;
}

final class CreateExerciseOp extends ProgramRepoOp {
  CreateExerciseOp({
    required this.exerciseGroupId,
    required this.name,
    required this.measurementType,
  });
  final String exerciseGroupId;
  final String name;
  final MeasurementType measurementType;
}

final class ReorderExercisesOp extends ProgramRepoOp {
  ReorderExercisesOp({
    required this.exerciseGroupId,
    required this.orderedExerciseIds,
  });
  final String exerciseGroupId;
  final List<String> orderedExerciseIds;
}

final class CreateSetOp extends ProgramRepoOp {
  CreateSetOp({required this.exerciseId, required this.plannedValues});
  final String exerciseId;
  final PlannedSetValues plannedValues;
}

final class ReorderSetsOp extends ProgramRepoOp {
  ReorderSetsOp({required this.exerciseId, required this.orderedSetIds});
  final String exerciseId;
  final List<String> orderedSetIds;
}

List<ProgramRepoOp> anyProgramRepoOpSequence(Random rng) {
  final count = 3 + rng.nextInt(8);
  final ops = <ProgramRepoOp>[];
  final programIds = <String>[];
  final workoutDayIds = <String>[];
  final exerciseGroupIds = <String>[];
  final exerciseIds = <String>[];
  final setIds = <String>[];

  for (var i = 0; i < count; i++) {
    final choice = rng.nextInt(11);
    switch (choice) {
      case 0:
        final id = anyUuidV4(rng);
        programIds.add(id);
        ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
      case 1:
        if (programIds.isEmpty) {
          final id = anyUuidV4(rng);
          programIds.add(id);
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        } else {
          final id = programIds[rng.nextInt(programIds.length)];
          ops.add(
            UpdateProgramNameOp(
              programId: id,
              newName: _anyString(rng, maxLen: 30),
            ),
          );
        }
      case 2:
        if (programIds.isEmpty) {
          final id = anyUuidV4(rng);
          programIds.add(id);
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        } else {
          final idx = rng.nextInt(programIds.length);
          ops.add(DeleteProgramOp(programId: programIds.removeAt(idx)));
        }
      case 3:
        if (programIds.isEmpty) {
          final id = anyUuidV4(rng);
          programIds.add(id);
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        }
        final programId = programIds[rng.nextInt(programIds.length)];
        final wdId = anyUuidV4(rng);
        workoutDayIds.add(wdId);
        ops.add(
          CreateWorkoutDayOp(
            programId: programId,
            name: _anyString(rng, maxLen: 30),
          ),
        );
      case 4:
        if (workoutDayIds.length >= 2) {
          final programId = programIds.isEmpty ? anyUuidV4(rng) : programIds[0];
          final shuffled = List<String>.from(workoutDayIds)..shuffle(rng);
          ops.add(
            ReorderWorkoutDaysOp(
              programId: programId,
              orderedWorkoutDayIds: shuffled,
            ),
          );
        } else {
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        }
      case 5:
        if (workoutDayIds.isEmpty) {
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        } else {
          final wdId = workoutDayIds[rng.nextInt(workoutDayIds.length)];
          final kind = anyExerciseGroupKind(rng);
          final exerciseCount = kind.when(
            single: () => 1,
            superset: () => 2 + rng.nextInt(2),
          );
          final exercises = List.generate(
            exerciseCount,
            (j) => anyExercise(rng),
          );
          final egId = anyUuidV4(rng);
          exerciseGroupIds.add(egId);
          ops.add(
            CreateExerciseGroupOp(
              workoutDayId: wdId,
              kind: kind,
              exercises: exercises,
            ),
          );
        }
      case 6:
        if (exerciseGroupIds.length >= 2) {
          final wdId = workoutDayIds.isEmpty
              ? anyUuidV4(rng)
              : workoutDayIds[0];
          final shuffled = List<String>.from(exerciseGroupIds)..shuffle(rng);
          ops.add(
            ReorderExerciseGroupsOp(
              workoutDayId: wdId,
              orderedGroupIds: shuffled,
            ),
          );
        } else {
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        }
      case 7:
        if (exerciseGroupIds.isEmpty) {
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        } else {
          final egId = exerciseGroupIds[rng.nextInt(exerciseGroupIds.length)];
          final exId = anyUuidV4(rng);
          exerciseIds.add(exId);
          ops.add(
            CreateExerciseOp(
              exerciseGroupId: egId,
              name: _anyString(rng, maxLen: 30),
              measurementType: anyMeasurementType(rng),
            ),
          );
        }
      case 8:
        if (exerciseIds.length >= 2) {
          final egId = exerciseGroupIds.isEmpty
              ? anyUuidV4(rng)
              : exerciseGroupIds[0];
          final shuffled = List<String>.from(exerciseIds)..shuffle(rng);
          ops.add(
            ReorderExercisesOp(
              exerciseGroupId: egId,
              orderedExerciseIds: shuffled,
            ),
          );
        } else {
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        }
      case 9:
        if (exerciseIds.isEmpty) {
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        } else {
          final exId = exerciseIds[rng.nextInt(exerciseIds.length)];
          final mt = anyMeasurementType(rng);
          final sId = anyUuidV4(rng);
          setIds.add(sId);
          ops.add(
            CreateSetOp(
              exerciseId: exId,
              plannedValues: anyPlannedSetValuesForMeasurement(rng, mt),
            ),
          );
        }
      default:
        if (setIds.length >= 2) {
          final exId = exerciseIds.isEmpty ? anyUuidV4(rng) : exerciseIds[0];
          final shuffled = List<String>.from(setIds)..shuffle(rng);
          ops.add(ReorderSetsOp(exerciseId: exId, orderedSetIds: shuffled));
        } else {
          ops.add(CreateProgramOp(name: _anyString(rng, maxLen: 30)));
        }
    }
  }
  return ops;
}

// ---------------------------------------------------------------------------
// Session repository operation sequence
// ---------------------------------------------------------------------------

sealed class SessionRepoOp {}

final class CompleteSetOp extends SessionRepoOp {
  CompleteSetOp({
    required this.sessionExerciseId,
    required this.actualValues,
    this.plannedSetIdInSnapshot,
  });
  final String sessionExerciseId;
  final ActualSetValues actualValues;
  final String? plannedSetIdInSnapshot;
}

final class SkipExerciseOp extends SessionRepoOp {
  SkipExerciseOp({required this.sessionExerciseId});
  final String sessionExerciseId;
}

final class MarkExerciseDoneOp extends SessionRepoOp {
  MarkExerciseDoneOp({required this.sessionExerciseId});
  final String sessionExerciseId;
}

final class ReplaceExerciseOp extends SessionRepoOp {
  ReplaceExerciseOp({
    required this.sessionExerciseId,
    required this.substituteName,
    required this.substituteMeasurementType,
    required this.substitutePlannedValues,
    required this.substituteSetCount,
    this.substituteMetadata,
  });
  final String sessionExerciseId;
  final String substituteName;
  final MeasurementType substituteMeasurementType;
  final PlannedSetValues substitutePlannedValues;
  final int substituteSetCount;
  final ExerciseMetadata? substituteMetadata;
}

final class ReorderUnfinishedOp extends SessionRepoOp {
  ReorderUnfinishedOp({
    required this.sessionId,
    required this.orderedUnfinishedIds,
  });
  final String sessionId;
  final List<String> orderedUnfinishedIds;
}

final class AddSessionNoteOp extends SessionRepoOp {
  AddSessionNoteOp({required this.sessionId, required this.body});
  final String sessionId;
  final String body;
}

final class AddExtraWorkOp extends SessionRepoOp {
  AddExtraWorkOp({required this.sessionId, required this.body});
  final String sessionId;
  final String body;
}

final class EndSessionOp extends SessionRepoOp {
  EndSessionOp({required this.sessionId});
  final String sessionId;
}

List<SessionRepoOp> anySessionRepoOpSequence(Random rng) {
  final count = 3 + rng.nextInt(6);
  final ops = <SessionRepoOp>[];
  final sessionIds = [anyUuidV4(rng)];
  final sessionExerciseIds = List.generate(4, (_) => anyUuidV4(rng));

  for (var i = 0; i < count; i++) {
    final sessionId = sessionIds[rng.nextInt(sessionIds.length)];
    final seId = sessionExerciseIds[rng.nextInt(sessionExerciseIds.length)];

    // Bias: 60% state transitions, 40% structural ops
    final roll = rng.nextInt(11);
    if (roll < 3) {
      final mt = anyMeasurementType(rng);
      ops.add(
        CompleteSetOp(
          sessionExerciseId: seId,
          actualValues: anyActualSetValuesForMeasurement(rng, mt),
          plannedSetIdInSnapshot: rng.nextBool() ? anyUuidV4(rng) : null,
        ),
      );
    } else if (roll < 5) {
      ops.add(SkipExerciseOp(sessionExerciseId: seId));
    } else if (roll == 5) {
      ops.add(MarkExerciseDoneOp(sessionExerciseId: seId));
    } else if (roll < 7) {
      final substituteMt = anyMeasurementType(rng);
      ops.add(
        ReplaceExerciseOp(
          sessionExerciseId: seId,
          substituteName: _anyString(rng, maxLen: 30),
          substituteMeasurementType: substituteMt,
          substitutePlannedValues: anyPlannedSetValuesForMeasurement(
            rng,
            substituteMt,
          ),
          substituteSetCount: 1 + rng.nextInt(5),
          substituteMetadata: rng.nextBool() ? anyExerciseMetadata(rng) : null,
        ),
      );
    } else if (roll == 7) {
      final shuffled = List<String>.from(sessionExerciseIds)..shuffle(rng);
      ops.add(
        ReorderUnfinishedOp(
          sessionId: sessionId,
          orderedUnfinishedIds: shuffled,
        ),
      );
    } else if (roll == 8) {
      ops.add(
        AddSessionNoteOp(
          sessionId: sessionId,
          body: _anyString(rng, maxLen: 100),
        ),
      );
    } else {
      ops.add(EndSessionOp(sessionId: sessionId));
    }
  }
  return ops;
}

// ---------------------------------------------------------------------------
// Corruption generator
// ---------------------------------------------------------------------------

Map<String, dynamic> anyCorruption(Map<String, dynamic> original, Random rng) {
  final copy = _deepCopyMap(original);
  final allPaths = _collectLeafPaths(copy);
  if (allPaths.isEmpty) return copy;

  final path = allPaths[rng.nextInt(allPaths.length)];
  final corruptionKind = rng.nextBool();

  if (corruptionKind) {
    _dropAtPath(copy, path);
  } else {
    _replaceAtPath(copy, path, '__unknown__');
  }
  return copy;
}

Map<String, dynamic> _deepCopyMap(Map<String, dynamic> source) {
  return source.map((k, v) {
    if (v is Map<String, dynamic>) return MapEntry(k, _deepCopyMap(v));
    if (v is List) return MapEntry(k, _deepCopyList(v));
    return MapEntry(k, v);
  });
}

List<dynamic> _deepCopyList(List<dynamic> source) {
  return source.map((v) {
    if (v is Map<String, dynamic>) return _deepCopyMap(v);
    if (v is List) return _deepCopyList(v);
    return v;
  }).toList();
}

List<List<String>> _collectLeafPaths(Map<String, dynamic> map) {
  final paths = <List<String>>[];
  for (final entry in map.entries) {
    final v = entry.value;
    if (v is Map<String, dynamic>) {
      for (final sub in _collectLeafPaths(v)) {
        paths.add([entry.key, ...sub]);
      }
    } else {
      paths.add([entry.key]);
    }
  }
  return paths;
}

void _dropAtPath(Map<String, dynamic> map, List<String> path) {
  if (path.length == 1) {
    map.remove(path.first);
    return;
  }
  final child = map[path.first];
  if (child is Map<String, dynamic>) {
    _dropAtPath(child, path.sublist(1));
  }
}

void _replaceAtPath(
  Map<String, dynamic> map,
  List<String> path,
  String replacement,
) {
  if (path.length == 1) {
    map[path.first] = replacement;
    return;
  }
  final child = map[path.first];
  if (child is Map<String, dynamic>) {
    _replaceAtPath(child, path.sublist(1), replacement);
  }
}

// ---------------------------------------------------------------------------
// RegressingClock — fake AppClock that returns non-monotonic times
// ---------------------------------------------------------------------------

class RegressingClock extends AppClock {
  RegressingClock(this._times) : assert(_times.isNotEmpty);

  final List<DateTime> _times;
  int _index = 0;

  @override
  DateTime nowUtc() {
    final t = _times[_index % _times.length];
    _index++;
    return t.isUtc ? t : t.toUtc();
  }
}

// ---------------------------------------------------------------------------
// Engine-specific generators — consistent snapshot ↔ exercise mapping
// ---------------------------------------------------------------------------

Session anySessionForEngine(Random rng) {
  final workoutDay = _anyWorkoutDayForEngine(rng);
  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );

  final allExercises = _flattenExercises(workoutDay);
  final sessionId = anyUuidV4(rng);

  final sessionExercises = List.generate(allExercises.length, (i) {
    final planned = allExercises[i];
    final mt = planned.measurementType;
    final plannedSetCount = planned.sets.length;
    final state = anyExerciseState(rng);
    final executedSetCount = _executedSetCountForState(
      rng,
      state,
      plannedSetCount,
    );

    return SessionExercise(
      id: anyUuidV4(rng),
      sessionId: sessionId,
      position: i,
      plannedExerciseIdInSnapshot: planned.id,
      state: state,
      executedSets: List.generate(executedSetCount, (j) {
        final effectiveMt = switch (state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => mt,
        };
        return ExecutedSet(
          id: anyUuidV4(rng),
          sessionExerciseId: anyUuidV4(rng),
          position: j,
          measurementType: effectiveMt,
          actualValues: anyActualSetValuesForMeasurement(rng, effectiveMt),
          plannedSetIdInSnapshot: j < planned.sets.length
              ? planned.sets[j].id
              : null,
          completedAt: anyUtcDateTime(rng),
          createdAt: anyUtcDateTime(rng),
          updatedAt: anyUtcDateTime(rng),
          schemaVersion: 1,
        );
      }),
      createdAt: anyUtcDateTime(rng),
      updatedAt: anyUtcDateTime(rng),
      schemaVersion: 1,
    );
  });

  return Session(
    id: sessionId,
    workoutDayId: workoutDay.id,
    snapshot: snapshot,
    sessionExercises: sessionExercises,
    notes: [],
    extraWork: [],
    startedAt: anyUtcDateTime(rng),
    endedAt: null,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

Session anySessionWithStates(
  Random rng, {
  required List<ExerciseState> states,
}) {
  assert(states.isNotEmpty);
  final exerciseCount = states.length;
  final workoutDay = _anyWorkoutDayWithExerciseCount(rng, exerciseCount);
  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );

  final allExercises = _flattenExercises(workoutDay);
  final sessionId = anyUuidV4(rng);

  final sessionExercises = List.generate(exerciseCount, (i) {
    final planned = allExercises[i];
    final mt = planned.measurementType;
    final plannedSetCount = planned.sets.length;
    final state = states[i];
    final executedSetCount = _executedSetCountForState(
      rng,
      state,
      plannedSetCount,
    );

    return SessionExercise(
      id: anyUuidV4(rng),
      sessionId: sessionId,
      position: i,
      plannedExerciseIdInSnapshot: planned.id,
      state: state,
      executedSets: List.generate(executedSetCount, (j) {
        final effectiveMt = switch (state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => mt,
        };
        return ExecutedSet(
          id: anyUuidV4(rng),
          sessionExerciseId: anyUuidV4(rng),
          position: j,
          measurementType: effectiveMt,
          actualValues: anyActualSetValuesForMeasurement(rng, effectiveMt),
          plannedSetIdInSnapshot: j < planned.sets.length
              ? planned.sets[j].id
              : null,
          completedAt: anyUtcDateTime(rng),
          createdAt: anyUtcDateTime(rng),
          updatedAt: anyUtcDateTime(rng),
          schemaVersion: 1,
        );
      }),
      createdAt: anyUtcDateTime(rng),
      updatedAt: anyUtcDateTime(rng),
      schemaVersion: 1,
    );
  });

  return Session(
    id: sessionId,
    workoutDayId: workoutDay.id,
    snapshot: snapshot,
    sessionExercises: sessionExercises,
    notes: [],
    extraWork: [],
    startedAt: anyUtcDateTime(rng),
    endedAt: null,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

Session anySessionWithLoggableTargets(Random rng) {
  final exerciseCount = 1 + rng.nextInt(5);
  final unfinishedIndex = rng.nextInt(exerciseCount);

  final states = List.generate(exerciseCount, (i) {
    if (i == unfinishedIndex) return const ExerciseState.unfinished();
    if (i < unfinishedIndex) {
      switch (rng.nextInt(3)) {
        case 0:
          return const ExerciseState.completed();
        case 1:
          return const ExerciseState.skipped();
        default:
          return ExerciseState.replaced(substitute: anySubstituteExercise(rng));
      }
    }
    return anyExerciseState(rng);
  });

  final workoutDay = _anyWorkoutDayWithExerciseCount(rng, exerciseCount);
  final snapshot = SessionSnapshot.capture(
    workoutDay: workoutDay,
    capturedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );

  final allExercises = _flattenExercises(workoutDay);
  final sessionId = anyUuidV4(rng);

  final sessionExercises = List.generate(exerciseCount, (i) {
    final planned = allExercises[i];
    final mt = planned.measurementType;
    final plannedSetCount = planned.sets.length;
    final state = states[i];

    final int executedSetCount;
    if (i == unfinishedIndex) {
      executedSetCount = rng.nextInt(plannedSetCount);
    } else {
      executedSetCount = _executedSetCountForState(rng, state, plannedSetCount);
    }

    return SessionExercise(
      id: anyUuidV4(rng),
      sessionId: sessionId,
      position: i,
      plannedExerciseIdInSnapshot: planned.id,
      state: state,
      executedSets: List.generate(executedSetCount, (j) {
        final effectiveMt = switch (state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => mt,
        };
        return ExecutedSet(
          id: anyUuidV4(rng),
          sessionExerciseId: anyUuidV4(rng),
          position: j,
          measurementType: effectiveMt,
          actualValues: anyActualSetValuesForMeasurement(rng, effectiveMt),
          plannedSetIdInSnapshot: j < planned.sets.length
              ? planned.sets[j].id
              : null,
          completedAt: anyUtcDateTime(rng),
          createdAt: anyUtcDateTime(rng),
          updatedAt: anyUtcDateTime(rng),
          schemaVersion: 1,
        );
      }),
      createdAt: anyUtcDateTime(rng),
      updatedAt: anyUtcDateTime(rng),
      schemaVersion: 1,
    );
  });

  return Session(
    id: sessionId,
    workoutDayId: workoutDay.id,
    snapshot: snapshot,
    sessionExercises: sessionExercises,
    notes: [],
    extraWork: [],
    startedAt: anyUtcDateTime(rng),
    endedAt: null,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

Session anyEndedSession(Random rng) {
  final session = anySessionForEngine(rng);
  return session.copyWith(endedAt: anyUtcDateTime(rng));
}

SessionState anySessionStateForOverview(Random rng) {
  final session = anySessionForEngine(rng);
  return SessionState(
    session: session,
    openTargets: _openTargetsForSession(session),
    isComplete: _isSessionComplete(session),
  );
}

List<LogTarget> _openTargetsForSession(Session session) {
  final sorted = List<SessionExercise>.of(session.sessionExercises)
    ..sort((a, b) => a.position.compareTo(b.position));
  final targets = <LogTarget>[];
  for (final ex in sorted) {
    final state = ex.state;
    if (state is UnfinishedState) {
      final planned = _findPlannedExerciseInSnapshot(ex, session);
      if (ex.executedSets.length < planned.sets.length) {
        targets.add(
          LogTarget(
            sessionExerciseId: ex.id,
            plannedSetIndex: ex.executedSets.length,
          ),
        );
      }
    } else if (state is ReplacedState) {
      if (ex.executedSets.length < state.substitute.setCount) {
        targets.add(
          LogTarget(
            sessionExerciseId: ex.id,
            plannedSetIndex: ex.executedSets.length,
          ),
        );
      }
    }
  }
  return targets;
}

bool _isSessionComplete(Session session) {
  for (final ex in session.sessionExercises) {
    switch (ex.state) {
      case CompletedState():
      case SkippedState():
        continue;
      case ReplacedState(:final substitute):
        if (ex.executedSets.length < substitute.setCount) return false;
      case UnfinishedState():
        return false;
    }
  }
  return true;
}

Exercise _findPlannedExerciseInSnapshot(
  SessionExercise sessionExercise,
  Session session,
) {
  for (final group in session.snapshot.workoutDay.exerciseGroups) {
    for (final exercise in group.exercises) {
      if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
        return exercise;
      }
    }
  }
  throw StateError(
    'Planned exercise ${sessionExercise.plannedExerciseIdInSnapshot} '
    'not found in session ${session.id}',
  );
}

String anyWhitespaceString(Random rng) {
  const whitespace = [0x20, 0x09, 0x0A, 0x0D, 0x0B, 0x0C];
  final len = 1 + rng.nextInt(20);
  return String.fromCharCodes(
    List.generate(len, (_) => whitespace[rng.nextInt(whitespace.length)]),
  );
}

// ---------------------------------------------------------------------------
// Engine generator helpers
// ---------------------------------------------------------------------------

WorkoutDay _anyWorkoutDayForEngine(Random rng) {
  final exerciseCount = 1 + rng.nextInt(5);
  return _anyWorkoutDayWithExerciseCount(rng, exerciseCount);
}

WorkoutDay _anyWorkoutDayWithExerciseCount(Random rng, int exerciseCount) {
  assert(exerciseCount >= 1);
  final workoutDayId = anyUuidV4(rng);
  final groups = <ExerciseGroup>[];
  var remaining = exerciseCount;
  var groupPosition = 0;

  while (remaining > 0) {
    final ExerciseGroupKind kind;
    final int groupExerciseCount;

    if (remaining >= 2 && rng.nextInt(3) == 0) {
      kind = const ExerciseGroupKind.superset();
      groupExerciseCount = min(2 + rng.nextInt(2), remaining);
    } else {
      kind = const ExerciseGroupKind.single();
      groupExerciseCount = 1;
    }

    final groupId = anyUuidV4(rng);
    final exercises = List.generate(groupExerciseCount, (i) {
      final mt = anyMeasurementType(rng);
      final setCount = 1 + rng.nextInt(5);
      final exerciseId = anyUuidV4(rng);
      return Exercise(
        id: exerciseId,
        exerciseGroupId: groupId,
        position: i,
        name: _anyString(rng, maxLen: 40),
        measurementType: mt,
        metadata: anyExerciseMetadata(rng),
        plannedRestSeconds: rng.nextBool() ? rng.nextInt(301) : null,
        sets: List.generate(setCount, (j) {
          return WorkoutSet(
            id: anyUuidV4(rng),
            exerciseId: exerciseId,
            position: j,
            measurementType: mt,
            plannedValues: anyPlannedSetValuesForMeasurement(rng, mt),
            createdAt: anyUtcDateTime(rng),
            updatedAt: anyUtcDateTime(rng),
            schemaVersion: 1,
          );
        }),
        createdAt: anyUtcDateTime(rng),
        updatedAt: anyUtcDateTime(rng),
        schemaVersion: 1,
      );
    });

    groups.add(
      ExerciseGroup(
        id: groupId,
        workoutDayId: workoutDayId,
        position: groupPosition,
        kind: kind,
        exercises: exercises,
        createdAt: anyUtcDateTime(rng),
        updatedAt: anyUtcDateTime(rng),
        schemaVersion: 1,
      ),
    );

    remaining -= groupExerciseCount;
    groupPosition++;
  }

  return WorkoutDay(
    id: workoutDayId,
    programId: anyUuidV4(rng),
    name: _anyString(rng, maxLen: 40),
    exerciseGroups: groups,
    createdAt: anyUtcDateTime(rng),
    updatedAt: anyUtcDateTime(rng),
    schemaVersion: 1,
  );
}

List<Exercise> _flattenExercises(WorkoutDay workoutDay) {
  return [for (final group in workoutDay.exerciseGroups) ...group.exercises];
}

int _executedSetCountForState(
  Random rng,
  ExerciseState state,
  int plannedSetCount,
) {
  return switch (state) {
    CompletedState() => plannedSetCount,
    SkippedState() => rng.nextInt(plannedSetCount + 1),
    ReplacedState(:final substitute) => rng.nextInt(substitute.setCount + 1),
    UnfinishedState() => rng.nextInt(plannedSetCount),
  };
}
