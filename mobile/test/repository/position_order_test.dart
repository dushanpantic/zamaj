/// **Validates: Requirements 7.1, 7.2, 7.3, 7.4, 7.5**
///
/// Property 6: Position total-order invariant.
///
/// After any sequence of session repository operations the following four
/// clauses must hold simultaneously:
///
///   P6-a  All session exercise positions within a session are distinct.
///   P6-b  Locked exercises (completed / skipped / replaced) have positions
///         strictly below every unfinished exercise.
///   P6-c  Once an exercise transitions to a locked state its position never
///         changes again.
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
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/workout_set.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart'
    hide Session, SessionExercise;
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

void main() {
  group('P6 – Position total-order invariant', () {
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
      'P6-b: locked exercises have positions strictly below all unfinished exercises',
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
            _assertLockedBelowUnfinished(result!, iteration);
          } finally {
            await db.close();
          }
        }
      },
    );

    test(
      'P6-c: locked positions are frozen – they never change after locking',
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
                if (_isLocked(se)) {
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
}

bool _isLocked(domain.SessionExercise se) {
  return switch (se.state) {
    UnfinishedState() => false,
    CompletedState() => true,
    SkippedState() => true,
    ReplacedState() => true,
  };
}

void _assertLockedBelowUnfinished(domain.Session session, int iteration) {
  final locked = session.sessionExercises.where(_isLocked).toList();
  final unfinished = session.sessionExercises
      .where((e) => !_isLocked(e))
      .toList();

  if (locked.isEmpty || unfinished.isEmpty) return;

  final maxLockedPos = locked.map((e) => e.position).reduce(max);
  final minUnfinishedPos = unfinished.map((e) => e.position).reduce(min);

  expect(
    maxLockedPos,
    lessThan(minUnfinishedPos),
    reason:
        'Iteration $iteration: max locked position ($maxLockedPos) is not '
        'strictly below min unfinished position ($minUnfinishedPos)',
  );
}

Future<domain.Session> _seedSession(
  Random rng,
  DriftProgramRepository programRepo,
  DriftSessionRepository sessionRepo,
) async {
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
      sets: [_makePlannedSet(rng, mt, anyUuidV4(rng))],
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
      substituteName: op.substituteName,
      substituteMeasurementType: op.substituteMeasurementType,
      substituteMetadata: op.substituteMetadata,
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
