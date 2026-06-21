/// **Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5**
///
/// Property 6: Position stability invariant.
///
/// After the set-order redesign, positions assigned at `startSession` are
/// stable. State transitions (`completeSet`, `skipExercise`,
/// `replaceExercise`, `deleteExecutedSet`) never modify
/// any exercise's `position`. Only `reorderUnfinished` can change positions,
/// and it can only permute slots already held by unfinished exercises.
///
///   P6-a  All session exercise positions within a session are distinct.
///   P6-b  Locked exercises (completed / skipped / replaced) never change
///         position after the operation that locked them.
///   P6-c  When no `reorderUnfinished` was applied, every exercise — locked
///         or not — keeps its initial `startSession` position.
///   P6-d  `reorderUnfinished` targeting a locked id raises `OrderingError`
///         and leaves the session unchanged.
library;

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session.dart' as domain;
import 'package:zamaj/modules/domain/models/session_exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/workout_set.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart'
    hide Session, SessionExercise;
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

void main() {
  group('P6 – Position stability invariant', () {
    test(
      'P6-a: all session exercise positions are distinct after any op sequence',
      () async {
        final rng = Random(42);
        for (var iteration = 0; iteration < 100; iteration++) {
          final db = AppDatabase(NativeDatabase.memory());
          try {
            final programRepo = DriftProgramRepository(db: db);
            final sessionRepo = DriftSessionRepository(
              db: db,
              programRepository: programRepo,
            );

            final session = await _seedSession(rng, programRepo, sessionRepo);
            final sessionId = session.id;
            final seIds = session.sessionExercises.map((e) => e.id).toList();

            final ops = anySessionRepoOpSequence(rng);
            await _applyOps(
              ops: ops,
              sessionId: sessionId,
              seIds: seIds,
              sessionRepo: sessionRepo,
              rng: rng,
            );

            final result = await sessionRepo.getSession(sessionId);
            expect(result, isNotNull);
            final positions = result!.sessionExercises
                .map((e) => e.position)
                .toList();
            final uniquePositions = positions.toSet();
            expect(
              uniquePositions.length,
              equals(positions.length),
              reason:
                  'Iteration $iteration: duplicate positions found: $positions',
            );
          } finally {
            await db.close();
          }
        }
      },
    );

    test(
      'P6-b: locked exercise positions never change after locking',
      () async {
        final rng = Random(271);
        for (var iteration = 0; iteration < 100; iteration++) {
          final db = AppDatabase(NativeDatabase.memory());
          try {
            final programRepo = DriftProgramRepository(db: db);
            final sessionRepo = DriftSessionRepository(
              db: db,
              programRepository: programRepo,
            );

            final session = await _seedSession(rng, programRepo, sessionRepo);
            final sessionId = session.id;
            final seIds = session.sessionExercises.map((e) => e.id).toList();

            final lockedPositions = <String, int>{};

            final ops = anySessionRepoOpSequence(rng);
            for (final op in ops) {
              domain.Session? afterOp;
              try {
                afterOp = await _applySingleOp(
                  op: op,
                  sessionId: sessionId,
                  seIds: seIds,
                  sessionRepo: sessionRepo,
                  rng: rng,
                );
              } on DomainError {
                continue;
              }

              for (final se in afterOp.sessionExercises) {
                if (!_isLocked(se)) continue;
                if (lockedPositions.containsKey(se.id)) {
                  expect(
                    se.position,
                    equals(lockedPositions[se.id]),
                    reason:
                        'Iteration $iteration: locked exercise ${se.id} '
                        'changed position from ${lockedPositions[se.id]} '
                        'to ${se.position}',
                  );
                } else {
                  lockedPositions[se.id] = se.position;
                }
              }
            }
          } finally {
            await db.close();
          }
        }
      },
    );

    test(
      'P6-c: with no reorderUnfinished, every position equals its startSession value',
      () async {
        final rng = Random(137);
        for (var iteration = 0; iteration < 100; iteration++) {
          final db = AppDatabase(NativeDatabase.memory());
          try {
            final programRepo = DriftProgramRepository(db: db);
            final sessionRepo = DriftSessionRepository(
              db: db,
              programRepository: programRepo,
            );

            final session = await _seedSession(rng, programRepo, sessionRepo);
            final sessionId = session.id;
            final seIds = session.sessionExercises.map((e) => e.id).toList();
            final initialPositions = {
              for (final se in session.sessionExercises) se.id: se.position,
            };

            final ops = anySessionRepoOpSequence(
              rng,
            ).where((op) => op is! ReorderUnfinishedOp).toList();
            await _applyOps(
              ops: ops,
              sessionId: sessionId,
              seIds: seIds,
              sessionRepo: sessionRepo,
              rng: rng,
            );

            final result = await sessionRepo.getSession(sessionId);
            expect(result, isNotNull);
            for (final se in result!.sessionExercises) {
              // Exercises added mid-session (via addExercise / composed replace)
              // are new rows appended at maxPosition + gap; they have no
              // startSession position. The invariant is that originally-seeded
              // exercises never drift.
              if (!initialPositions.containsKey(se.id)) continue;
              expect(
                se.position,
                equals(initialPositions[se.id]),
                reason:
                    'Iteration $iteration: ${se.id} drifted from initial '
                    'position ${initialPositions[se.id]} to ${se.position}',
              );
            }
          } finally {
            await db.close();
          }
        }
      },
    );

    test(
      'P6-d: reorderUnfinished targeting a locked id raises OrderingError and leaves session unchanged',
      () async {
        final rng = Random(314);
        var testedAtLeastOnce = false;

        for (var iteration = 0; iteration < 100; iteration++) {
          final db = AppDatabase(NativeDatabase.memory());
          try {
            final programRepo = DriftProgramRepository(db: db);
            final sessionRepo = DriftSessionRepository(
              db: db,
              programRepository: programRepo,
            );

            final session = await _seedSession(rng, programRepo, sessionRepo);
            final sessionId = session.id;
            final seIds = session.sessionExercises.map((e) => e.id).toList();

            final ops = anySessionRepoOpSequence(rng);
            await _applyOps(
              ops: ops,
              sessionId: sessionId,
              seIds: seIds,
              sessionRepo: sessionRepo,
              rng: rng,
            );

            final beforeReorder = await sessionRepo.getSession(sessionId);
            expect(beforeReorder, isNotNull);

            final lockedIds = beforeReorder!.sessionExercises
                .where(_isLocked)
                .map((e) => e.id)
                .toList();

            if (lockedIds.isEmpty) continue;

            testedAtLeastOnce = true;
            final lockedId = lockedIds[rng.nextInt(lockedIds.length)];

            Object? caughtError;
            try {
              await sessionRepo.reorderUnfinished(
                sessionId: sessionId,
                orderedUnfinishedIds: [lockedId],
              );
            } catch (e) {
              caughtError = e;
            }

            expect(
              caughtError,
              isA<OrderingError>(),
              reason:
                  'Iteration $iteration: expected OrderingError when targeting '
                  'locked id $lockedId',
            );

            final orderingError = caughtError as OrderingError;
            expect(
              orderingError.sessionExerciseId,
              equals(lockedId),
              reason:
                  'Iteration $iteration: OrderingError.sessionExerciseId should '
                  'name the offending id',
            );

            final afterReorder = await sessionRepo.getSession(sessionId);
            expect(afterReorder, isNotNull);
            expect(
              afterReorder!.sessionExercises.length,
              equals(beforeReorder.sessionExercises.length),
              reason:
                  'Iteration $iteration: session changed after failed reorder',
            );
            for (final before in beforeReorder.sessionExercises) {
              final after = afterReorder.sessionExercises.firstWhere(
                (e) => e.id == before.id,
              );
              expect(
                after.position,
                equals(before.position),
                reason:
                    'Iteration $iteration: position of ${before.id} changed '
                    'after failed reorder',
              );
            }
          } finally {
            await db.close();
          }
        }

        expect(
          testedAtLeastOnce,
          isTrue,
          reason: 'P6-d never found a locked exercise to test against',
        );
      },
    );
  });

  group('reorderUnfinished — UNIQUE(session_id, position) safety', () {
    test(
      'swapping two unfinished exercises does not trip the UNIQUE constraint',
      () async {
        // Regression: prior implementation wrote new positions row-by-row,
        // which collides with SQLite's per-statement UNIQUE check whenever
        // two rows trade slots (e.g. moving the second exercise to first).
        final rng = Random(101);
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db);
          final sessionRepo = DriftSessionRepository(
            db: db,
            programRepository: programRepo,
          );

          final session = await _seedSession(rng, programRepo, sessionRepo);
          final originalById = {
            for (final se in session.sessionExercises) se.id: se,
          };
          final ids = session.sessionExercises.map((e) => e.id).toList();
          final swapped = [ids[1], ids[0], ...ids.skip(2)];

          final after = await sessionRepo.reorderUnfinished(
            sessionId: session.id,
            orderedUnfinishedIds: swapped,
          );

          // The two swapped ids exchange positions; everyone else holds.
          final byId = {for (final se in after.sessionExercises) se.id: se};
          expect(
            byId[ids[0]]!.position,
            equals(originalById[ids[1]]!.position),
          );
          expect(
            byId[ids[1]]!.position,
            equals(originalById[ids[0]]!.position),
          );
          final positions = after.sessionExercises
              .map((e) => e.position)
              .toList();
          expect(
            positions.toSet().length,
            equals(positions.length),
            reason: 'positions must remain distinct after swap',
          );
        } finally {
          await db.close();
        }
      },
    );

    test(
      'reversing all unfinished exercises does not trip the UNIQUE constraint',
      () async {
        final rng = Random(102);
        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db);
          final sessionRepo = DriftSessionRepository(
            db: db,
            programRepository: programRepo,
          );

          final session = await _seedSession(rng, programRepo, sessionRepo);
          final originalSlots =
              session.sessionExercises.map((e) => e.position).toList()..sort();
          final ids = session.sessionExercises.map((e) => e.id).toList();
          final reversed = ids.reversed.toList();

          final after = await sessionRepo.reorderUnfinished(
            sessionId: session.id,
            orderedUnfinishedIds: reversed,
          );

          // The slot occupied by reversed[i] should be the i-th slot in
          // ascending order — i.e. the order in `reversed` matches the
          // ascending position sort.
          final byId = {for (final se in after.sessionExercises) se.id: se};
          for (var i = 0; i < reversed.length; i++) {
            expect(
              byId[reversed[i]]!.position,
              equals(originalSlots[i]),
              reason: 'Reversed id at index $i should occupy ascending slot $i',
            );
          }
          final positions = after.sessionExercises
              .map((e) => e.position)
              .toList();
          expect(
            positions.toSet().length,
            equals(positions.length),
            reason: 'positions must remain distinct after reverse',
          );
        } finally {
          await db.close();
        }
      },
    );
  });
}

bool _isLocked(domain.SessionExercise se) {
  return switch (se.state) {
    UnfinishedState() => false,
    CompletedState() => true,
    SkippedState() => true,
  };
}

Future<domain.Session> _seedSession(
  Random rng,
  DriftProgramRepository programRepo,
  DriftSessionRepository sessionRepo, {
  int setsPerExercise = 1,
}) async {
  final program = await programRepo.createProgram(name: 'Test Program');
  final exerciseCount = 3 + rng.nextInt(3);
  final exercises = List.generate(exerciseCount, (i) {
    final mt = anyMeasurementType(rng);
    return domain.Exercise(
      id: anyUuidV4(rng),
      exerciseGroupId: '',
      position: i,
      name: 'Exercise $i',
      measurementType: mt,
      metadata: ExerciseMetadata.empty,
      sets: List.generate(
        setsPerExercise,
        (_) => _makePlannedSet(rng, mt, anyUuidV4(rng)),
      ),
      createdAt: DateTime.utc(2024),
      updatedAt: DateTime.utc(2024),
      schemaVersion: 1,
    );
  });

  final day = await programRepo.createWorkoutDay(
    programId: program.id,
    name: 'Day A',
  );

  await programRepo.createExerciseGroup(
    workoutDayId: day.id,
    kind: const ExerciseGroupKind.single(),
    exercises: [exercises.first],
  );

  if (exercises.length > 1) {
    for (var i = 1; i < exercises.length; i++) {
      await programRepo.createExerciseGroup(
        workoutDayId: day.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [exercises[i]],
      );
    }
  }

  return sessionRepo.startSession(workoutDayId: day.id);
}

domain.WorkoutSet _makePlannedSet(Random rng, MeasurementType mt, String id) {
  return domain.WorkoutSet(
    id: id,
    exerciseId: anyUuidV4(rng),
    position: 0,
    measurementType: mt,
    plannedValues: anyPlannedSetValuesForMeasurement(rng, mt),
    createdAt: DateTime.utc(2024),
    updatedAt: DateTime.utc(2024),
    schemaVersion: 1,
  );
}

Future<void> _applyOps({
  required List<SessionRepoOp> ops,
  required String sessionId,
  required List<String> seIds,
  required DriftSessionRepository sessionRepo,
  required Random rng,
}) async {
  for (final op in ops) {
    try {
      await _applySingleOp(
        op: op,
        sessionId: sessionId,
        seIds: seIds,
        sessionRepo: sessionRepo,
        rng: rng,
      );
    } on DomainError {
      // Expected: some ops will fail (e.g. locking an already-locked exercise).
    }
  }
}

Future<domain.Session> _applySingleOp({
  required SessionRepoOp op,
  required String sessionId,
  required List<String> seIds,
  required DriftSessionRepository sessionRepo,
  required Random rng,
}) async {
  final seId = seIds[rng.nextInt(seIds.length)];

  return switch (op) {
    CompleteSetOp() => sessionRepo.completeSet(
      sessionExerciseId: seId,
      actualValues: anyActualSetValuesForMeasurement(
        rng,
        anyMeasurementType(rng),
      ),
      plannedSetIdInSnapshot: op.plannedSetIdInSnapshot,
    ),
    SkipExerciseOp() => sessionRepo.skipExercise(seId),
    ReplaceExerciseOp() => sessionRepo.replaceExercise(
      sessionExerciseId: seId,
      plan: op.plan,
    ),
    ReorderUnfinishedOp() => sessionRepo.reorderUnfinished(
      sessionId: sessionId,
      orderedUnfinishedIds: op.orderedUnfinishedIds
          .where((id) => seIds.contains(id))
          .toList(),
    ),
    AddSessionNoteOp() => sessionRepo.addSessionNote(
      sessionId: sessionId,
      body: op.body,
    ),
    AddExtraWorkOp() => sessionRepo.addExtraWork(
      sessionId: sessionId,
      body: op.body,
    ),
    EndSessionOp() => sessionRepo.endSession(sessionId),
  };
}
