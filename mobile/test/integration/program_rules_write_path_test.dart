// Pins AC7 / R3: program-authoring bounds are enforced at the write path
// (saveProgramAggregate rejects out-of-range values) while reads stay
// unguarded so legacy out-of-bounds rows still load.

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';

const _programId = '00000000-0000-4000-8000-000000000001';
const _dayId = '00000000-0000-4000-8000-000000000002';
const _groupId = '00000000-0000-4000-8000-000000000003';
const _exerciseId = '00000000-0000-4000-8000-000000000004';
const _setId = '00000000-0000-4000-8000-000000000005';

ProgramAggregate _aggregate({required double weightKg}) {
  final t = DateTime.utc(2024);
  return ProgramAggregate(
    id: _programId,
    name: 'P',
    createdAt: t,
    updatedAt: t,
    schemaVersion: 1,
    workoutDays: [
      WorkoutDayAggregate(
        id: _dayId,
        programId: _programId,
        name: 'D',
        position: 0,
        groups: [
          ExerciseGroupAggregate(
            id: _groupId,
            workoutDayId: _dayId,
            kind: const ExerciseGroupKind.single(),
            position: 0,
            exercises: [
              ExerciseAggregate(
                id: _exerciseId,
                groupId: _groupId,
                name: 'Bench',
                measurementType: const MeasurementType.repBased(),
                metadata: ExerciseMetadata.empty,
                plannedRestSeconds: null,
                libraryExerciseId: null,
                position: 0,
                sets: [
                  WorkoutSetAggregate(
                    id: _setId,
                    exerciseId: _exerciseId,
                    position: 0,
                    values: PlannedSetValues.repBased(
                      weightKg: weightKg,
                      repTarget: RepTarget.fixed(reps: 5),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

void main() {
  group('ProgramRules write-path enforcement', () {
    test('saving an out-of-bounds aggregate is rejected with a '
        'ValidationError', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repo = DriftProgramRepository(db: db);
        await expectLater(
          repo.saveProgramAggregate(_aggregate(weightKg: 2000)),
          throwsA(
            isA<ValidationError>().having(
              (e) => e.invariant,
              'invariant',
              'weight_out_of_range',
            ),
          ),
        );
      } finally {
        await db.close();
      }
    });

    test('a pre-existing out-of-bounds row still loads on read', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final repo = DriftProgramRepository(db: db);
        final program = await repo.saveProgramAggregate(
          _aggregate(weightKg: 100),
        );

        // Simulate a legacy row written before the bound existed: overwrite the
        // persisted set values with an out-of-bounds weight directly.
        final legacy = PlannedSetValues.repBased(
          weightKg: 2000,
          repTarget: RepTarget.fixed(reps: 5),
        );
        await (db.update(
          db.workoutSets,
        )..where((t) => t.id.equals(_setId))).write(
          WorkoutSetsCompanion(
            plannedValuesPayloadJson: Value(
              CanonicalJson.encode(legacy.toJson()),
            ),
          ),
        );

        final days = await repo.listWorkoutDaysForProgram(program.id);
        final set =
            days.single.exerciseGroups.single.exercises.single.sets.single;
        expect((set.plannedValues as PlannedRepBased).weightKg, 2000);
      } finally {
        await db.close();
      }
    });
  });
}
