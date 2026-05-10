import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

/// **Property 5: Snapshot fidelity and byte-stability.**
/// **Validates: Requirements 6.1, 6.3**
///
/// After `startSession` captures a snapshot, any sequence of program-template
/// mutations against the source `WorkoutDay` and its descendants must leave
/// the snapshot's `canonicalJson`, `sha256Hash`, and the bytes returned by
/// subsequent `getSession` calls completely unchanged.
void main() {
  group('Property 5: Snapshot fidelity and byte-stability', () {
    test('snapshot canonicalJson and sha256Hash are unchanged after arbitrary '
        'program repo op sequences (100 iterations)', () async {
      final rng = Random(42);

      for (var iteration = 0; iteration < 100; iteration++) {
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db);
          final sessionRepo = DriftSessionRepository(
            db: db,
            programRepository: programRepo,
          );

          final program = await programRepo.createProgram(
            name: 'Prog-$iteration',
          );

          final kind = const ExerciseGroupKind.single();
          final mt = const MeasurementType.repBased();
          final workoutDay = await programRepo.createWorkoutDay(
            programId: program.id,
            name: 'Day-$iteration',
          );
          await programRepo.createExerciseGroup(
            workoutDayId: workoutDay.id,
            kind: kind,
            exercises: [
              domain.Exercise(
                id: anyUuidV4(rng),
                exerciseGroupId: '',
                position: 0,
                name: 'Exercise-$iteration',
                measurementType: mt,
                metadata: ExerciseMetadata.empty,
                sets: [],
                createdAt: DateTime.utc(2024),
                updatedAt: DateTime.utc(2024),
                schemaVersion: 1,
              ),
            ],
          );

          final initialWorkoutDay = await programRepo.getWorkoutDay(
            workoutDay.id,
          );
          expect(initialWorkoutDay, isNotNull);

          final session = await sessionRepo.startSession(
            workoutDayId: workoutDay.id,
          );

          final snapshotCanonicalJson = session.snapshot.canonicalJson;
          final snapshotSha256Hash = session.snapshot.sha256Hash;
          final expectedCanonicalJson = CanonicalJson.encode(
            initialWorkoutDay!.toJson(),
          );

          expect(
            snapshotCanonicalJson,
            equals(expectedCanonicalJson),
            reason:
                'Iteration $iteration: snapshot.canonicalJson must equal '
                'CanonicalJson.encode(initialWorkoutDay.toJson()) at session start',
          );
          expect(
            snapshotSha256Hash,
            equals(CanonicalJson.sha256Hex(expectedCanonicalJson)),
            reason:
                'Iteration $iteration: snapshot.sha256Hash must match the '
                'hash of the initial canonicalJson at session start',
          );

          final ops = anyProgramRepoOpSequence(rng);
          for (final op in ops) {
            try {
              await _applyOp(op, programRepo, workoutDay.id, program.id);
            } catch (_) {
              // Ops that target non-existent ids (e.g. from the generator
              // using random ids) are expected to fail; we ignore those
              // errors and continue — the snapshot must remain stable
              // regardless.
            }
          }

          final sessionAfterMutations = await sessionRepo.getSession(
            session.id,
          );
          expect(
            sessionAfterMutations,
            isNotNull,
            reason: 'Iteration $iteration: getSession must return the session',
          );

          expect(
            sessionAfterMutations!.snapshot.canonicalJson,
            equals(snapshotCanonicalJson),
            reason:
                'Iteration $iteration: snapshot.canonicalJson must be '
                'unchanged after template mutations',
          );

          expect(
            sessionAfterMutations.snapshot.sha256Hash,
            equals(snapshotSha256Hash),
            reason:
                'Iteration $iteration: snapshot.sha256Hash must be '
                'unchanged after template mutations',
          );

          expect(
            sessionAfterMutations.snapshot.canonicalJson,
            equals(expectedCanonicalJson),
            reason:
                'Iteration $iteration: snapshot.canonicalJson must still '
                'equal CanonicalJson.encode(initialWorkoutDay.toJson()) '
                'after template mutations',
          );
        } finally {
          await db.close();
        }
      }
    });
  });
}

Future<void> _applyOp(
  ProgramRepoOp op,
  DriftProgramRepository repo,
  String sourceWorkoutDayId,
  String sourceProgramId,
) async {
  switch (op) {
    case CreateProgramOp(:final name):
      await repo.createProgram(name: name);

    case UpdateProgramNameOp(:final programId, :final newName):
      final program = await repo.getProgram(programId);
      if (program != null) {
        await repo.updateProgram(program.copyWith(name: newName));
      }

    case DeleteProgramOp(:final programId):
      if (programId != sourceProgramId) {
        await repo.deleteProgram(programId);
      }

    case CreateWorkoutDayOp(:final programId, :final name):
      final program = await repo.getProgram(programId);
      if (program != null) {
        await repo.createWorkoutDay(programId: programId, name: name);
      }

    case ReorderWorkoutDaysOp(:final programId, :final orderedWorkoutDayIds):
      final program = await repo.getProgram(programId);
      if (program != null) {
        final validIds = orderedWorkoutDayIds
            .where((id) => program.workoutDayIds.contains(id))
            .toList();
        if (validIds.isNotEmpty) {
          await repo.reorderWorkoutDays(programId, validIds);
        }
      }

    case CreateExerciseGroupOp(
      :final workoutDayId,
      :final kind,
      :final exercises,
    ):
      final day = await repo.getWorkoutDay(workoutDayId);
      if (day != null) {
        await repo.createExerciseGroup(
          workoutDayId: workoutDayId,
          kind: kind,
          exercises: exercises,
        );
      }

    case ReorderExerciseGroupsOp(:final workoutDayId, :final orderedGroupIds):
      final day = await repo.getWorkoutDay(workoutDayId);
      if (day != null) {
        final existingIds = day.exerciseGroups.map((g) => g.id).toSet();
        final validIds = orderedGroupIds
            .where((id) => existingIds.contains(id))
            .toList();
        if (validIds.isNotEmpty) {
          await repo.reorderExerciseGroups(workoutDayId, validIds);
        }
      }

    case CreateExerciseOp(
      :final exerciseGroupId,
      :final name,
      :final measurementType,
    ):
      await repo.createExercise(
        exerciseGroupId: exerciseGroupId,
        name: name,
        measurementType: measurementType,
      );

    case ReorderExercisesOp(:final exerciseGroupId, :final orderedExerciseIds):
      await repo.reorderExercises(exerciseGroupId, orderedExerciseIds);

    case CreateSetOp(:final exerciseId, :final plannedValues):
      await repo.createSet(
        exerciseId: exerciseId,
        plannedValues: plannedValues,
      );

    case ReorderSetsOp(:final exerciseId, :final orderedSetIds):
      await repo.reorderSets(exerciseId, orderedSetIds);
  }
}
