// Feature: core-domain-and-persistence
// Property 8: Timestamp monotonicity under arbitrary clocks.
// Validates: Requirements 8.3, 8.4

import 'dart:math';

import 'package:clock/clock.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

/// **Property 8: Timestamp monotonicity under arbitrary clocks.**
/// **Validates: Requirements 8.3, 8.4**
///
/// Even when the injected clock returns non-monotonic (regressing) times,
/// the repository must guarantee:
/// - `createdAt` is stable after the initial insert (never changes on update).
/// - Every subsequent `updatedAt` is ≥ the previous `updatedAt`.
/// - Every `updatedAt` is ≥ `createdAt`.
void main() {
  group('Property 8: Timestamp monotonicity under arbitrary clocks', () {
    test('Program createdAt is stable and updatedAt is non-decreasing under '
        'a regressing clock (100 iterations)', () async {
      final rng = Random(42);

      for (var iteration = 0; iteration < 100; iteration++) {
        final times = _anyNonMonotonicTimes(rng, count: 20);
        final regressingClock = RegressingClock(times);
        final clock = Clock(regressingClock.nowUtc);

        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db, clock: clock);

          final program = await programRepo.createProgram(
            name: 'Prog-$iteration',
          );

          final createdAt = program.createdAt;
          var previousUpdatedAt = program.updatedAt;

          expect(
            program.updatedAt.millisecondsSinceEpoch,
            greaterThanOrEqualTo(program.createdAt.millisecondsSinceEpoch),
            reason:
                'Iteration $iteration: initial updatedAt must be >= createdAt',
          );

          final updateCount = 2 + rng.nextInt(4);
          for (var u = 0; u < updateCount; u++) {
            final updated = await programRepo.updateProgram(
              program.copyWith(name: 'Prog-$iteration-update-$u'),
            );

            expect(
              updated.createdAt,
              equals(createdAt),
              reason:
                  'Iteration $iteration update $u: createdAt must not change',
            );
            expect(
              updated.updatedAt.millisecondsSinceEpoch,
              greaterThanOrEqualTo(previousUpdatedAt.millisecondsSinceEpoch),
              reason:
                  'Iteration $iteration update $u: updatedAt must be >= '
                  'previous updatedAt',
            );
            expect(
              updated.updatedAt.millisecondsSinceEpoch,
              greaterThanOrEqualTo(createdAt.millisecondsSinceEpoch),
              reason:
                  'Iteration $iteration update $u: updatedAt must be >= '
                  'createdAt',
            );

            previousUpdatedAt = updated.updatedAt;
          }
        } finally {
          await db.close();
        }
      }
    });

    test('WorkoutDay createdAt is stable and updatedAt is non-decreasing under '
        'a regressing clock (100 iterations)', () async {
      final rng = Random(99);

      for (var iteration = 0; iteration < 100; iteration++) {
        final times = _anyNonMonotonicTimes(rng, count: 30);
        final regressingClock = RegressingClock(times);
        final clock = Clock(regressingClock.nowUtc);

        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db, clock: clock);

          final program = await programRepo.createProgram(
            name: 'Prog-$iteration',
          );
          final day = await programRepo.createWorkoutDay(
            programId: program.id,
            name: 'Day-$iteration',
          );

          final createdAt = day.createdAt;
          var previousUpdatedAt = day.updatedAt;

          expect(
            day.updatedAt.millisecondsSinceEpoch,
            greaterThanOrEqualTo(day.createdAt.millisecondsSinceEpoch),
            reason:
                'Iteration $iteration: initial updatedAt must be >= createdAt',
          );

          final updateCount = 2 + rng.nextInt(4);
          for (var u = 0; u < updateCount; u++) {
            final updated = await programRepo.updateWorkoutDay(
              day.copyWith(name: 'Day-$iteration-update-$u'),
            );

            expect(
              updated.createdAt,
              equals(createdAt),
              reason:
                  'Iteration $iteration update $u: createdAt must not change',
            );
            expect(
              updated.updatedAt.millisecondsSinceEpoch,
              greaterThanOrEqualTo(previousUpdatedAt.millisecondsSinceEpoch),
              reason:
                  'Iteration $iteration update $u: updatedAt must be >= '
                  'previous updatedAt',
            );
            expect(
              updated.updatedAt.millisecondsSinceEpoch,
              greaterThanOrEqualTo(createdAt.millisecondsSinceEpoch),
              reason:
                  'Iteration $iteration update $u: updatedAt must be >= '
                  'createdAt',
            );

            previousUpdatedAt = updated.updatedAt;
          }
        } finally {
          await db.close();
        }
      }
    });

    test(
      'Session updatedAt is non-decreasing and createdAt is stable under '
      'a regressing clock across completeSet and addSessionNote (100 iterations)',
      () async {
        final rng = Random(7);

        for (var iteration = 0; iteration < 100; iteration++) {
          final times = _anyNonMonotonicTimes(rng, count: 50);
          final regressingClock = RegressingClock(times);
          final clock = Clock(regressingClock.nowUtc);

          final db = AppDatabase(NativeDatabase.memory());
          try {
            final programRepo = DriftProgramRepository(db: db, clock: clock);
            final sessionRepo = DriftSessionRepository(
              db: db,
              programRepository: programRepo,
              clock: clock,
            );

            final program = await programRepo.createProgram(
              name: 'Prog-$iteration',
            );
            final day = await programRepo.createWorkoutDay(
              programId: program.id,
              name: 'Day-$iteration',
            );

            final exercise = anyExercise(rng);
            await programRepo.createExerciseGroup(
              workoutDayId: day.id,
              kind: const ExerciseGroupKind.single(),
              exercises: [exercise],
            );

            final session = await sessionRepo.startSession(
              workoutDayId: day.id,
            );

            // Derive the measurement type from the snapshot so completeSet
            // always receives a matching ActualSetValues variant.
            final snapshotExercise = session
                .snapshot
                .workoutDay
                .exerciseGroups
                .first
                .exercises
                .first;
            final mt = snapshotExercise.measurementType;

            final sessionCreatedAt = session.createdAt;
            var previousSessionUpdatedAt = session.updatedAt;

            expect(
              session.updatedAt.millisecondsSinceEpoch,
              greaterThanOrEqualTo(session.createdAt.millisecondsSinceEpoch),
              reason:
                  'Iteration $iteration: initial session updatedAt must be >= '
                  'createdAt',
            );

            final opCount = 2 + rng.nextInt(5);
            for (var op = 0; op < opCount; op++) {
              try {
                final updated = rng.nextBool()
                    ? await sessionRepo.addSessionNote(
                        sessionId: session.id,
                        body: 'note-$iteration-$op',
                      )
                    : await sessionRepo.completeSet(
                        sessionExerciseId: session.sessionExercises.first.id,
                        actualValues: anyActualSetValuesForMeasurement(rng, mt),
                      );

                expect(
                  updated.createdAt,
                  equals(sessionCreatedAt),
                  reason:
                      'Iteration $iteration op $op: session createdAt must '
                      'not change',
                );
                expect(
                  updated.updatedAt.millisecondsSinceEpoch,
                  greaterThanOrEqualTo(
                    previousSessionUpdatedAt.millisecondsSinceEpoch,
                  ),
                  reason:
                      'Iteration $iteration op $op: session updatedAt must '
                      'be >= previous updatedAt',
                );
                expect(
                  updated.updatedAt.millisecondsSinceEpoch,
                  greaterThanOrEqualTo(sessionCreatedAt.millisecondsSinceEpoch),
                  reason:
                      'Iteration $iteration op $op: session updatedAt must '
                      'be >= createdAt',
                );

                previousSessionUpdatedAt = updated.updatedAt;
              } on OrderingError {
                // exercise already locked — acceptable, skip
              }
            }
          } finally {
            await db.close();
          }
        }
      },
    );

    test('SessionExercise updatedAt is non-decreasing and createdAt is stable '
        'under a regressing clock across skipExercise and replaceExercise '
        '(100 iterations)', () async {
      final rng = Random(13);

      for (var iteration = 0; iteration < 100; iteration++) {
        final times = _anyNonMonotonicTimes(rng, count: 40);
        final regressingClock = RegressingClock(times);
        final clock = Clock(regressingClock.nowUtc);

        final db = AppDatabase(NativeDatabase.memory());
        try {
          final programRepo = DriftProgramRepository(db: db, clock: clock);
          final sessionRepo = DriftSessionRepository(
            db: db,
            programRepository: programRepo,
            clock: clock,
          );

          final program = await programRepo.createProgram(
            name: 'Prog-$iteration',
          );
          final day = await programRepo.createWorkoutDay(
            programId: program.id,
            name: 'Day-$iteration',
          );

          await programRepo.createExerciseGroup(
            workoutDayId: day.id,
            kind: const ExerciseGroupKind.single(),
            exercises: [anyExercise(rng)],
          );

          final session = await sessionRepo.startSession(workoutDayId: day.id);

          final se = session.sessionExercises.first;
          final seCreatedAt = se.createdAt;
          final previousSeUpdatedAt = se.updatedAt;

          expect(
            se.updatedAt.millisecondsSinceEpoch,
            greaterThanOrEqualTo(se.createdAt.millisecondsSinceEpoch),
            reason:
                'Iteration $iteration: initial sessionExercise updatedAt '
                'must be >= createdAt',
          );

          final afterTransition = rng.nextBool()
              ? await sessionRepo.skipExercise(se.id)
              : await sessionRepo.replaceExercise(
                  sessionExerciseId: se.id,
                  plan: anyAddedExercisePlan(rng, libraryLinked: false),
                );

          final updatedSe = afterTransition.sessionExercises.firstWhere(
            (x) => x.id == se.id,
          );

          expect(
            updatedSe.createdAt,
            equals(seCreatedAt),
            reason:
                'Iteration $iteration: sessionExercise createdAt must '
                'not change after state transition',
          );
          expect(
            updatedSe.updatedAt.millisecondsSinceEpoch,
            greaterThanOrEqualTo(previousSeUpdatedAt.millisecondsSinceEpoch),
            reason:
                'Iteration $iteration: sessionExercise updatedAt must '
                'be >= previous updatedAt after state transition',
          );
          expect(
            updatedSe.updatedAt.millisecondsSinceEpoch,
            greaterThanOrEqualTo(seCreatedAt.millisecondsSinceEpoch),
            reason:
                'Iteration $iteration: sessionExercise updatedAt must '
                'be >= createdAt after state transition',
          );
        } finally {
          await db.close();
        }
      }
    });
  });
}

/// Generates a list of [count] UTC [DateTime] values that may go backward
/// (non-monotonic) to stress-test the repository's monotonicity enforcement.
List<DateTime> _anyNonMonotonicTimes(Random rng, {required int count}) {
  final base = DateTime.utc(2020).millisecondsSinceEpoch;
  return List.generate(count, (_) {
    final offsetMs = rng.nextInt(4000000000);
    return DateTime.fromMillisecondsSinceEpoch(base + offsetMs, isUtc: true);
  });
}
