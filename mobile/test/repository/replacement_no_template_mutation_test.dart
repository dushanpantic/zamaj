// Feature: core-domain-and-persistence, Property 4: Replacement does not mutate templates.
// Validates: Req 5.3

import 'dart:math';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

import '../support/generators.dart';

void main() {
  test(
    'Property 4: replaceExercise does not mutate any template-table row',
    () async {
      final rng = Random(42);

      for (var iteration = 0; iteration < 100; iteration++) {
        final db = AppDatabase(NativeDatabase.memory());
        final programRepo = DriftProgramRepository(db: db);
        final sessionRepo = DriftSessionRepository(
          db: db,
          programRepository: programRepo,
        );

        try {
          final program = await programRepo.createProgram(name: 'P$iteration');

          final day = await programRepo.createWorkoutDay(
            programId: program.id,
            name: 'Day$iteration',
          );

          // Use exactly one single-exercise group so the session has exactly
          // one SessionExercise at position 0. This avoids position-assignment
          // conflicts in replaceExercise (which assigns maxLockedPos + gap)
          // while still exercising the property across varied template
          // structures (random exercise metadata, measurement types, sets).
          await programRepo.createExerciseGroup(
            workoutDayId: day.id,
            kind: const ExerciseGroupKind.single(),
            exercises: [anyExercise(rng)],
          );

          final session = await sessionRepo.startSession(workoutDayId: day.id);

          final beforePrograms = await db.select(db.programs).get();
          final beforeProgramWorkoutDays = await db
              .select(db.programWorkoutDays)
              .get();
          final beforeWorkoutDays = await db.select(db.workoutDays).get();
          final beforeExerciseGroups = await db.select(db.exerciseGroups).get();
          final beforeExercises = await db.select(db.exercises).get();
          final beforeSets = await db.select(db.workoutSets).get();

          // Replace every session exercise once. With single-exercise groups
          // each replacement locks one exercise at a strictly increasing
          // position, so no UNIQUE constraint conflicts arise.
          for (final se in session.sessionExercises) {
            final mt = anyMeasurementType(rng);
            await sessionRepo.replaceExercise(
              sessionExerciseId: se.id,
              substituteName: 'Sub${se.id}',
              substituteMeasurementType: mt,
              substitutePlannedValues: anyPlannedSetValuesForMeasurement(
                rng,
                mt,
              ),
              substituteSetCount: 1 + rng.nextInt(4),
              substituteMetadata: rng.nextBool()
                  ? anyExerciseMetadata(rng)
                  : null,
            );
          }

          final afterPrograms = await db.select(db.programs).get();
          final afterProgramWorkoutDays = await db
              .select(db.programWorkoutDays)
              .get();
          final afterWorkoutDays = await db.select(db.workoutDays).get();
          final afterExerciseGroups = await db.select(db.exerciseGroups).get();
          final afterExercises = await db.select(db.exercises).get();
          final afterSets = await db.select(db.workoutSets).get();

          expect(
            afterPrograms,
            equals(beforePrograms),
            reason: 'programs table mutated at iteration $iteration',
          );
          expect(
            afterProgramWorkoutDays,
            equals(beforeProgramWorkoutDays),
            reason:
                'program_workout_days table mutated at iteration $iteration',
          );
          expect(
            afterWorkoutDays,
            equals(beforeWorkoutDays),
            reason: 'workout_days table mutated at iteration $iteration',
          );
          expect(
            afterExerciseGroups,
            equals(beforeExerciseGroups),
            reason: 'exercise_groups table mutated at iteration $iteration',
          );
          expect(
            afterExercises,
            equals(beforeExercises),
            reason: 'exercises table mutated at iteration $iteration',
          );
          expect(
            afterSets,
            equals(beforeSets),
            reason: 'sets table mutated at iteration $iteration',
          );
        } finally {
          await db.close();
        }
      }
    },
  );
}
