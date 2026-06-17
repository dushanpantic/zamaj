// TEMP: snapshot link repair — remove after one-time run
//
// End-to-end coverage for [DriftSessionRepository.overwriteSnapshotWorkoutDay],
// the thin persistence write behind the one-shot history-link repair. It must
// rewrite only the snapshot blob + hash as a consistent pair (so the session
// re-hydrates), leave every child row and timestamp untouched, and never touch
// a sibling session.

import 'dart:convert';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/domain/services/exercise_cap_history_aggregator.dart';
import 'package:zamaj/modules/domain/services/exercise_progress_aggregator.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

const _libNew = '11111111-1111-4111-8111-111111111111';
const _libCurrent = '22222222-2222-4222-8222-222222222222';

void main() {
  group('DriftSessionRepository.overwriteSnapshotWorkoutDay', () {
    late AppDatabase db;
    late DriftProgramRepository programRepo;
    late DriftSessionRepository sessionRepo;
    late String workoutDayId;

    final clock = Clock.fixed(DateTime.utc(2024, 6, 1, 12));

    setUp(() async {
      db = AppDatabase(NativeDatabase.memory());
      programRepo = DriftProgramRepository(db: db, clock: clock);
      sessionRepo = DriftSessionRepository(
        db: db,
        programRepository: programRepo,
        clock: clock,
      );

      final program = await programRepo.createProgram(name: 'P');
      final day = await programRepo.createWorkoutDay(
        programId: program.id,
        name: 'Upper',
      );
      workoutDayId = day.id;
      // Unlinked template exercise: the captured snapshot carries a null link,
      // exactly the pre-relink state the repair targets.
      await programRepo.createExerciseGroup(
        workoutDayId: day.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [
          domain.Exercise(
            id: 'ex-bench',
            exerciseGroupId: '',
            position: 0,
            name: 'Bench',
            measurementType: const MeasurementType.repBased(),
            metadata: ExerciseMetadata.empty,
            sets: const [],
            createdAt: DateTime.utc(2024),
            updatedAt: DateTime.utc(2024),
            schemaVersion: 1,
          ),
        ],
      );
    });

    tearDown(() async {
      await db.close();
    });

    domain.WorkoutDay relinked(domain.WorkoutDay day, String libraryId) {
      final group = day.exerciseGroups.single;
      final exercise = group.exercises.single;
      return day.copyWith(
        exerciseGroups: [
          group.copyWith(
            exercises: [exercise.copyWith(libraryExerciseId: libraryId)],
          ),
        ],
      );
    }

    Future<String> storedSnapshotJson(String sessionId) async {
      final row = await (db.select(
        db.sessions,
      )..where((t) => t.id.equals(sessionId))).getSingle();
      return row.snapshotJson;
    }

    test(
      'rewrites the link, re-hydrates, preserves all else, sibling untouched',
      () async {
        final started = await sessionRepo.startSession(
          workoutDayId: workoutDayId,
        );
        await sessionRepo.completeSet(
          sessionExerciseId: started.sessionExercises.single.id,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
        await sessionRepo.addSessionNote(
          sessionId: started.id,
          body: 'felt strong',
        );
        await sessionRepo.addExtraWork(
          sessionId: started.id,
          body: '10 min bike',
        );
        final ended = await sessionRepo.endSession(started.id);

        // A sibling ended session that must remain byte-for-byte unchanged.
        final sibling = await sessionRepo.startSession(
          workoutDayId: workoutDayId,
        );
        await sessionRepo.endSession(sibling.id);
        final siblingBefore = await storedSnapshotJson(sibling.id);

        final original = ended.snapshot.workoutDay;
        final originalExercise =
            original.exerciseGroups.single.exercises.single;
        expect(originalExercise.libraryExerciseId, isNull);

        await sessionRepo.overwriteSnapshotWorkoutDay(
          sessionId: ended.id,
          workoutDay: relinked(original, _libNew),
        );

        // Re-reading hydrates through SessionMapper + SessionSnapshot without
        // throwing, which already proves the consistent hash pair (AC7).
        final reread = await sessionRepo.getSession(ended.id);
        expect(reread, isNotNull);
        final rereadExercise =
            reread!.snapshot.workoutDay.exerciseGroups.single.exercises.single;

        // Link updated.
        expect(rereadExercise.libraryExerciseId, _libNew);
        // Consistent persisted pair (AC7), asserted explicitly too.
        expect(
          reread.snapshot.sha256Hash,
          CanonicalJson.sha256Hex(reread.snapshot.canonicalJson),
        );
        expect(
          reread.snapshot.canonicalJson,
          CanonicalJson.encode(
            domain.WorkoutDay.fromJson(
              jsonDecode(reread.snapshot.canonicalJson) as Map<String, dynamic>,
            ).toJson(),
          ),
        );

        // Snapshot identity preserved except the link (AC8).
        expect(rereadExercise.id, originalExercise.id);
        expect(rereadExercise.name, originalExercise.name);
        expect(
          rereadExercise.measurementType,
          originalExercise.measurementType,
        );
        expect(rereadExercise.schemaVersion, originalExercise.schemaVersion);
        expect(reread.snapshot.workoutDay.id, original.id);
        expect(reread.snapshot.schemaVersion, ended.snapshot.schemaVersion);

        // Child rows untouched (AC8).
        expect(
          reread.sessionExercises.single.executedSets.single.actualValues,
          const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
        expect(reread.notes.single.body, 'felt strong');
        expect(reread.extraWork.single.body, '10 min bike');

        // Session row timestamps + schemaVersion untouched (AC8).
        expect(reread.startedAt, ended.startedAt);
        expect(reread.endedAt, ended.endedAt);
        expect(reread.createdAt, ended.createdAt);
        expect(reread.updatedAt, ended.updatedAt);
        expect(reread.schemaVersion, ended.schemaVersion);

        // Sibling session byte-for-byte unchanged (AC14).
        expect(await storedSnapshotJson(sibling.id), siblingBefore);
      },
    );

    test(
      're-linked session reappears in both aggregators for the current id (AC9)',
      () async {
        final started = await sessionRepo.startSession(
          workoutDayId: workoutDayId,
        );
        await sessionRepo.completeSet(
          sessionExerciseId: started.sessionExercises.single.id,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
        final ended = await sessionRepo.endSession(started.id);

        // Before the repair the snapshot link is null, so the current library
        // id sees neither a progress point nor a history entry.
        final before = await sessionRepo.listCompletedSessions();
        expect(
          ExerciseProgressAggregator.compute(
            libraryExerciseId: _libCurrent,
            sessions: before,
          ).points,
          isEmpty,
        );
        expect(
          ExerciseCapHistoryAggregator.computeHistory(
            libraryExerciseId: _libCurrent,
            sessions: before,
          ).entries,
          isEmpty,
        );

        await sessionRepo.overwriteSnapshotWorkoutDay(
          sessionId: ended.id,
          workoutDay: relinked(ended.snapshot.workoutDay, _libCurrent),
        );

        // After the repair both aggregators include the previously-missing
        // session for the current library id.
        final after = await sessionRepo.listCompletedSessions();
        expect(
          ExerciseProgressAggregator.compute(
            libraryExerciseId: _libCurrent,
            sessions: after,
          ).points,
          hasLength(1),
        );
        expect(
          ExerciseCapHistoryAggregator.computeHistory(
            libraryExerciseId: _libCurrent,
            sessions: after,
          ).entries,
          hasLength(1),
        );
      },
    );
  });
}
