import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/repositories/program_repository.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

domain.Exercise _exercise(String name) => domain.Exercise(
  id: '',
  exerciseGroupId: '',
  position: 0,
  name: name,
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: const [],
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  schemaVersion: 1,
);

AddedExercisePlan _plan({String name = 'Goblet Squat'}) => AddedExercisePlan(
  name: name,
  measurementType: const MeasurementType.repBased(),
  plannedValues: PlannedSetValues.repBased(
    weightKg: 60,
    repTarget: RepTarget.fixed(reps: 12),
  ),
  setCount: 3,
);

/// A repo whose add-write faults mid-`replaceExercise` — after the skip-update
/// statement has executed but before the transaction commits — so the rollback
/// behavior (true atomicity) can be asserted.
class _FaultyAddRepo extends DriftSessionRepository {
  _FaultyAddRepo({required super.db, required super.programRepository});

  @override
  Future<void> insertAddedExerciseRow({
    required String sessionId,
    required AddedExercisePlan plan,
  }) async {
    throw StateError('simulated add-write fault');
  }
}

Future<({AppDatabase db, ProgramRepository programRepo, String workoutDayId})>
_seed() async {
  final db = AppDatabase(NativeDatabase.memory());
  final programRepo = DriftProgramRepository(db: db);
  final program = await programRepo.createProgram(name: 'P');
  final workoutDay = await programRepo.createWorkoutDay(
    programId: program.id,
    name: 'D',
  );
  await programRepo.createExerciseGroup(
    workoutDayId: workoutDay.id,
    kind: const ExerciseGroupKind.single(),
    exercises: [_exercise('Bench Press')],
  );
  return (db: db, programRepo: programRepo, workoutDayId: workoutDay.id);
}

void main() {
  group('DriftSessionRepository.replaceExercise (atomic terminate + add)', () {
    test('skips the original and appends the replacement in one transaction; '
        'reloads identically from disk', () async {
      final seed = await _seed();
      final repo = DriftSessionRepository(
        db: seed.db,
        programRepository: seed.programRepo,
      );
      try {
        final started = await repo.startSession(
          workoutDayId: seed.workoutDayId,
        );
        final originalId = started.sessionExercises.single.id;
        final hashBefore = started.snapshot.sha256Hash;

        await repo.replaceExercise(
          sessionExerciseId: originalId,
          plan: _plan(),
        );

        final reloaded = (await repo.getSession(started.id))!;
        expect(reloaded.sessionExercises, hasLength(2));
        expect(
          reloaded.sessionExercises.firstWhere((e) => e.id == originalId).state,
          isA<SkippedState>(),
        );
        final added = reloaded.sessionExercises.last;
        expect(added.addedPlan?.name, 'Goblet Squat');
        expect(added.state, isA<UnfinishedState>());
        // The frozen snapshot is never recomputed.
        expect(reloaded.snapshot.sha256Hash, hashBefore);
      } finally {
        await seed.db.close();
      }
    });

    test('rolls back fully when the add-write faults: the original is not '
        'terminated and no replacement row is written', () async {
      final seed = await _seed();
      final faulty = _FaultyAddRepo(
        db: seed.db,
        programRepository: seed.programRepo,
      );
      try {
        final started = await faulty.startSession(
          workoutDayId: seed.workoutDayId,
        );
        final originalId = started.sessionExercises.single.id;

        await expectLater(
          faulty.replaceExercise(
            sessionExerciseId: originalId,
            plan: _plan(),
          ),
          throwsA(isA<StateError>()),
        );

        // The whole transaction rolled back: the original stays unfinished and
        // no replacement exercise exists.
        final after = (await faulty.getSession(started.id))!;
        expect(after.sessionExercises, hasLength(1));
        expect(
          after.sessionExercises.single.id,
          originalId,
        );
        expect(after.sessionExercises.single.state, isA<UnfinishedState>());
      } finally {
        await seed.db.close();
      }
    });

    test('full flow: start → add exercise → extra set → replace → end', () async {
      final seed = await _seed();
      final repo = DriftSessionRepository(
        db: seed.db,
        programRepository: seed.programRepo,
      );
      try {
        final started = await repo.startSession(
          workoutDayId: seed.workoutDayId,
        );
        final benchId = started.sessionExercises.single.id;

        // Add an exercise that the plan did not include.
        var session = await repo.addExercise(
          sessionId: started.id,
          plan: _plan(name: 'Curl'),
        );
        final curlId = session.sessionExercises.last.id;

        // Complete the bench (1 planned set), then log an extra set beyond plan.
        await repo.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 5),
        );
        session = await repo.completeSet(
          sessionExerciseId: benchId,
          actualValues: const ActualSetValues.repBased(weightKg: 80, reps: 4),
        );
        final bench = session.sessionExercises.firstWhere(
          (e) => e.id == benchId,
        );
        expect(bench.state, isA<CompletedState>());
        expect(bench.executedSets, hasLength(2));

        // Replace the added Curl with a fresh movement.
        session = await repo.replaceExercise(
          sessionExerciseId: curlId,
          plan: _plan(name: 'Hammer Curl'),
        );
        expect(
          session.sessionExercises.firstWhere((e) => e.id == curlId).state,
          isA<SkippedState>(),
        );
        expect(session.sessionExercises.last.addedPlan?.name, 'Hammer Curl');

        final ended = await repo.endSession(started.id);
        expect(ended.endedAt, isNotNull);
      } finally {
        await seed.db.close();
      }
    });
  });
}
