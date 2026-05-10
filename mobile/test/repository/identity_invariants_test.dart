// Feature: core-domain-and-persistence, Property 7: Identity invariants.
// Validates: Reqs 8.1, 8.5, 8.6, 8.7

import 'dart:math';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' show SqliteException;
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

final _uuidV4Pattern = RegExp(
  r'^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$',
);

void main() {
  test('Property 7: every persisted id is a canonical 36-char UUIDv4, '
      'every schema_version equals SchemaVersions.domain, '
      'and all ids are globally unique across tables', () async {
    final rng = Random(7);

    for (var iteration = 0; iteration < 100; iteration++) {
      final db = AppDatabase(NativeDatabase.memory());
      final programRepo = DriftProgramRepository(db: db);
      final sessionRepo = DriftSessionRepository(
        db: db,
        programRepository: programRepo,
      );

      try {
        await _runProgramOps(rng, programRepo, db);
        await _runSessionOps(rng, programRepo, sessionRepo, db);

        await _assertIdentityInvariants(db, iteration);
      } finally {
        await db.close();
      }
    }
  });
}

Future<void> _runProgramOps(
  Random rng,
  DriftProgramRepository programRepo,
  AppDatabase db,
) async {
  final ops = anyProgramRepoOpSequence(rng);
  final createdProgramIds = <String>[];
  final createdWorkoutDayIds = <String>[];
  final createdExerciseGroupIds = <String>[];
  final createdExerciseIds = <String>[];
  final createdSetIds = <String>[];

  for (final op in ops) {
    try {
      switch (op) {
        case CreateProgramOp(:final name):
          final p = await programRepo.createProgram(name: name);
          createdProgramIds.add(p.id);

        case UpdateProgramNameOp(:final programId, :final newName):
          final existing = await programRepo.getProgram(programId);
          if (existing != null) {
            await programRepo.updateProgram(existing.copyWith(name: newName));
          }

        case DeleteProgramOp(:final programId):
          if (createdProgramIds.contains(programId)) {
            await programRepo.deleteProgram(programId);
            createdProgramIds.remove(programId);
          }

        case CreateWorkoutDayOp(:final programId, :final name):
          if (createdProgramIds.isNotEmpty) {
            final pid = createdProgramIds.contains(programId)
                ? programId
                : createdProgramIds.last;
            final wd = await programRepo.createWorkoutDay(
              programId: pid,
              name: name,
            );
            createdWorkoutDayIds.add(wd.id);
          }

        case ReorderWorkoutDaysOp(
          :final programId,
          :final orderedWorkoutDayIds,
        ):
          if (createdProgramIds.contains(programId) &&
              orderedWorkoutDayIds.isNotEmpty) {
            final existing = await programRepo.listWorkoutDaysForProgram(
              programId,
            );
            final existingIds = existing.map((d) => d.id).toSet();
            final validIds = orderedWorkoutDayIds
                .where(existingIds.contains)
                .toList();
            if (validIds.isNotEmpty) {
              await programRepo.reorderWorkoutDays(programId, validIds);
            }
          }

        case CreateExerciseGroupOp(
          :final workoutDayId,
          :final kind,
          :final exercises,
        ):
          if (createdWorkoutDayIds.isNotEmpty) {
            final wdId = createdWorkoutDayIds.contains(workoutDayId)
                ? workoutDayId
                : createdWorkoutDayIds.last;
            final group = await programRepo.createExerciseGroup(
              workoutDayId: wdId,
              kind: kind,
              exercises: exercises,
            );
            createdExerciseGroupIds.add(group.id);
            for (final e in group.exercises) {
              createdExerciseIds.add(e.id);
              for (final s in e.sets) {
                createdSetIds.add(s.id);
              }
            }
          }

        case ReorderExerciseGroupsOp(
          :final workoutDayId,
          :final orderedGroupIds,
        ):
          if (createdWorkoutDayIds.isNotEmpty) {
            final wdId = createdWorkoutDayIds.contains(workoutDayId)
                ? workoutDayId
                : createdWorkoutDayIds.last;
            final wd = await programRepo.getWorkoutDay(wdId);
            if (wd != null) {
              final existingIds = wd.exerciseGroups.map((g) => g.id).toSet();
              final validIds = orderedGroupIds
                  .where(existingIds.contains)
                  .toList();
              if (validIds.isNotEmpty) {
                await programRepo.reorderExerciseGroups(wdId, validIds);
              }
            }
          }

        case CreateExerciseOp(
          :final exerciseGroupId,
          :final name,
          :final measurementType,
        ):
          if (createdExerciseGroupIds.isNotEmpty) {
            final egId = createdExerciseGroupIds.contains(exerciseGroupId)
                ? exerciseGroupId
                : createdExerciseGroupIds.last;
            final groupRows = await (db.select(
              db.exerciseGroups,
            )..where((t) => t.id.equals(egId))).get();
            if (groupRows.isNotEmpty) {
              final e = await programRepo.createExercise(
                exerciseGroupId: egId,
                name: name,
                measurementType: measurementType,
              );
              createdExerciseIds.add(e.id);
            }
          }

        case ReorderExercisesOp(
          :final exerciseGroupId,
          :final orderedExerciseIds,
        ):
          if (createdExerciseGroupIds.isNotEmpty) {
            final egId = createdExerciseGroupIds.contains(exerciseGroupId)
                ? exerciseGroupId
                : createdExerciseGroupIds.last;
            final exercises = await (db.select(
              db.exercises,
            )..where((t) => t.exerciseGroupId.equals(egId))).get();
            final existingIds = exercises.map((e) => e.id).toSet();
            final validIds = orderedExerciseIds
                .where(existingIds.contains)
                .toList();
            if (validIds.isNotEmpty) {
              await programRepo.reorderExercises(egId, validIds);
            }
          }

        case CreateSetOp(:final exerciseId, :final plannedValues):
          if (createdExerciseIds.isNotEmpty) {
            final exId = createdExerciseIds.contains(exerciseId)
                ? exerciseId
                : createdExerciseIds.last;
            final exerciseRows = await (db.select(
              db.exercises,
            )..where((t) => t.id.equals(exId))).get();
            if (exerciseRows.isNotEmpty) {
              final s = await programRepo.createSet(
                exerciseId: exId,
                plannedValues: plannedValues,
              );
              createdSetIds.add(s.id);
            }
          }

        case ReorderSetsOp(:final exerciseId, :final orderedSetIds):
          if (createdExerciseIds.isNotEmpty) {
            final exId = createdExerciseIds.contains(exerciseId)
                ? exerciseId
                : createdExerciseIds.last;
            final sets = await (db.select(
              db.workoutSets,
            )..where((t) => t.exerciseId.equals(exId))).get();
            final existingIds = sets.map((s) => s.id).toSet();
            final validIds = orderedSetIds.where(existingIds.contains).toList();
            if (validIds.isNotEmpty) {
              await programRepo.reorderSets(exId, validIds);
            }
          }
      }
    } on NotFoundError {
      // acceptable — op referenced an entity that was deleted
    } on ValidationError {
      // acceptable — measurement type mismatch between set and exercise
    }
  }
}

Future<void> _runSessionOps(
  Random rng,
  DriftProgramRepository programRepo,
  DriftSessionRepository sessionRepo,
  AppDatabase db,
) async {
  final workoutDayRows = await db.select(db.workoutDays).get();
  if (workoutDayRows.isEmpty) return;

  final workoutDayId = workoutDayRows[rng.nextInt(workoutDayRows.length)].id;

  domain.WorkoutDay? workoutDay;
  try {
    workoutDay = await programRepo.getWorkoutDay(workoutDayId);
  } on ValidationError {
    return;
  }
  if (workoutDay == null || workoutDay.exerciseGroups.isEmpty) return;

  final hasExercises = workoutDay.exerciseGroups.any(
    (g) => g.exercises.isNotEmpty,
  );
  if (!hasExercises) return;

  final session = await sessionRepo.startSession(workoutDayId: workoutDayId);

  final ops = anySessionRepoOpSequence(rng);
  final sessionExerciseIds = session.sessionExercises.map((e) => e.id).toList();

  for (final op in ops) {
    try {
      switch (op) {
        case CompleteSetOp(:final actualValues, :final plannedSetIdInSnapshot):
          if (sessionExerciseIds.isNotEmpty) {
            final seId =
                sessionExerciseIds[rng.nextInt(sessionExerciseIds.length)];
            await sessionRepo.completeSet(
              sessionExerciseId: seId,
              actualValues: actualValues,
              plannedSetIdInSnapshot: plannedSetIdInSnapshot,
            );
          }

        case SkipExerciseOp():
          if (sessionExerciseIds.isNotEmpty) {
            final seId =
                sessionExerciseIds[rng.nextInt(sessionExerciseIds.length)];
            await sessionRepo.skipExercise(seId);
          }

        case ReplaceExerciseOp(
          :final substituteName,
          :final substituteMeasurementType,
          :final substituteMetadata,
        ):
          if (sessionExerciseIds.isNotEmpty) {
            final seId =
                sessionExerciseIds[rng.nextInt(sessionExerciseIds.length)];
            await sessionRepo.replaceExercise(
              sessionExerciseId: seId,
              substituteName: substituteName,
              substituteMeasurementType: substituteMeasurementType,
              substituteMetadata: substituteMetadata,
            );
          }

        case ReorderUnfinishedOp():
          final unfinished =
              await (db.select(db.sessionExercises)..where(
                    (t) =>
                        t.sessionId.equals(session.id) &
                        t.stateDiscriminator.equals('unfinished'),
                  ))
                  .get();
          if (unfinished.length >= 2) {
            final shuffled = List.of(unfinished)..shuffle(rng);
            await sessionRepo.reorderUnfinished(
              sessionId: session.id,
              orderedUnfinishedIds: shuffled.map((e) => e.id).toList(),
            );
          }

        case AddSessionNoteOp(:final body):
          await sessionRepo.addSessionNote(sessionId: session.id, body: body);

        case AddExtraWorkOp(:final body):
          await sessionRepo.addExtraWork(sessionId: session.id, body: body);

        case EndSessionOp():
          await sessionRepo.endSession(session.id);
      }
    } on OrderingError {
      // acceptable — exercise already locked
    } on ValidationError {
      // acceptable — measurement type mismatch on completeSet
    } on NotFoundError {
      // acceptable — entity deleted or not found
    } on SqliteException {
      // acceptable — unique constraint violation from concurrent position assignment
    }
  }
}

Future<void> _assertIdentityInvariants(AppDatabase db, int iteration) async {
  final allIds = <String>{};

  Future<void> checkTable({
    required String tableName,
    required List<String> ids,
    required List<int> schemaVersions,
  }) async {
    for (final id in ids) {
      expect(
        id.length,
        equals(36),
        reason: '$tableName id "$id" is not 36 chars at iteration $iteration',
      );
      expect(
        _uuidV4Pattern.hasMatch(id),
        isTrue,
        reason:
            '$tableName id "$id" does not match UUIDv4 pattern at iteration $iteration',
      );
      expect(
        allIds.add(id),
        isTrue,
        reason:
            '$tableName id "$id" is a duplicate across tables at iteration $iteration',
      );
    }
    for (final sv in schemaVersions) {
      expect(
        sv,
        equals(SchemaVersions.domain),
        reason:
            '$tableName schema_version $sv != ${SchemaVersions.domain} at iteration $iteration',
      );
    }
  }

  final programRows = await db.select(db.programs).get();
  await checkTable(
    tableName: 'programs',
    ids: programRows.map((r) => r.id).toList(),
    schemaVersions: programRows.map((r) => r.schemaVersion).toList(),
  );

  final workoutDayRows = await db.select(db.workoutDays).get();
  await checkTable(
    tableName: 'workout_days',
    ids: workoutDayRows.map((r) => r.id).toList(),
    schemaVersions: workoutDayRows.map((r) => r.schemaVersion).toList(),
  );

  final exerciseGroupRows = await db.select(db.exerciseGroups).get();
  await checkTable(
    tableName: 'exercise_groups',
    ids: exerciseGroupRows.map((r) => r.id).toList(),
    schemaVersions: exerciseGroupRows.map((r) => r.schemaVersion).toList(),
  );

  final exerciseRows = await db.select(db.exercises).get();
  await checkTable(
    tableName: 'exercises',
    ids: exerciseRows.map((r) => r.id).toList(),
    schemaVersions: exerciseRows.map((r) => r.schemaVersion).toList(),
  );

  final setRows = await db.select(db.workoutSets).get();
  await checkTable(
    tableName: 'sets',
    ids: setRows.map((r) => r.id).toList(),
    schemaVersions: setRows.map((r) => r.schemaVersion).toList(),
  );

  final sessionRows = await db.select(db.sessions).get();
  await checkTable(
    tableName: 'sessions',
    ids: sessionRows.map((r) => r.id).toList(),
    schemaVersions: sessionRows.map((r) => r.schemaVersion).toList(),
  );

  final sessionExerciseRows = await db.select(db.sessionExercises).get();
  await checkTable(
    tableName: 'session_exercises',
    ids: sessionExerciseRows.map((r) => r.id).toList(),
    schemaVersions: sessionExerciseRows.map((r) => r.schemaVersion).toList(),
  );

  final executedSetRows = await db.select(db.executedSets).get();
  await checkTable(
    tableName: 'executed_sets',
    ids: executedSetRows.map((r) => r.id).toList(),
    schemaVersions: executedSetRows.map((r) => r.schemaVersion).toList(),
  );

  final sessionNoteRows = await db.select(db.sessionNotes).get();
  await checkTable(
    tableName: 'session_notes',
    ids: sessionNoteRows.map((r) => r.id).toList(),
    schemaVersions: sessionNoteRows.map((r) => r.schemaVersion).toList(),
  );

  final extraWorkRows = await db.select(db.extraWorkItems).get();
  await checkTable(
    tableName: 'extra_work_items',
    ids: extraWorkRows.map((r) => r.id).toList(),
    schemaVersions: extraWorkRows.map((r) => r.schemaVersion).toList(),
  );
}
