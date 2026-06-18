import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session.dart' as domain;
import 'package:zamaj/modules/domain/models/workout_set.dart' as domain;
import 'package:zamaj/modules/domain/services/exercise_outcome.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

final _t = DateTime.utc(2024);

domain.Exercise _exercise(int setCount) => domain.Exercise(
  id: '',
  exerciseGroupId: '',
  position: 0,
  name: 'Squat',
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: List.generate(
    setCount,
    (i) => domain.WorkoutSet(
      id: '',
      exerciseId: '',
      position: i,
      measurementType: const MeasurementType.repBased(),
      plannedValues: PlannedSetValues.repBased(
        weightKg: 20,
        repTarget: RepTarget.fixed(reps: 5),
      ),
      createdAt: _t,
      updatedAt: _t,
      schemaVersion: 1,
    ),
  ),
  createdAt: _t,
  updatedAt: _t,
  schemaVersion: 1,
);

domain.Exercise _snapshotExercise(domain.Session s) =>
    s.snapshot.workoutDay.exerciseGroups.single.exercises.single;

Future<
  ({
    DriftSessionRepository session,
    DriftProgramRepository program,
    String dayId,
  })
>
_setup(AppDatabase db, {int setCount = 4}) async {
  final programRepo = DriftProgramRepository(db: db);
  final sessionRepo = DriftSessionRepository(
    db: db,
    programRepository: programRepo,
  );
  final program = await programRepo.createProgram(name: 'P');
  final day = await programRepo.createWorkoutDay(
    programId: program.id,
    name: 'D',
  );
  await programRepo.createExerciseGroup(
    workoutDayId: day.id,
    kind: const ExerciseGroupKind.single(),
    exercises: [_exercise(setCount)],
  );
  return (session: sessionRepo, program: programRepo, dayId: day.id);
}

void main() {
  group('DriftSessionRepository.startSession deload', () {
    test('a deload start halves working sets and tags the session', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final s = await _setup(db);
        final session = await s.session.startSession(
          workoutDayId: s.dayId,
          isDeload: true,
        );
        expect(_snapshotExercise(session).sets.length, 2);
        expect(session.isDeload, isTrue);
      } finally {
        await db.close();
      }
    });

    test('a normal start changes nothing', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final s = await _setup(db);
        final session = await s.session.startSession(workoutDayId: s.dayId);
        expect(_snapshotExercise(session).sets.length, 4);
        expect(session.isDeload, isFalse);
      } finally {
        await db.close();
      }
    });

    test('the program template is never mutated by a deload start', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final s = await _setup(db);
        await s.session.startSession(workoutDayId: s.dayId, isDeload: true);
        final day = (await s.program.getWorkoutDay(s.dayId))!;
        expect(day.exerciseGroups.single.exercises.single.sets.length, 4);
      } finally {
        await db.close();
      }
    });

    test('a deload exercise reads completed at its halved quota', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final s = await _setup(db);
        final session = await s.session.startSession(
          workoutDayId: s.dayId,
          isDeload: true,
        );
        final se = session.sessionExercises.single;
        final snapshotSets = _snapshotExercise(session).sets;
        expect(snapshotSets.length, 2);

        var updated = session;
        for (final set in snapshotSets) {
          updated = await s.session.completeSet(
            sessionExerciseId: se.id,
            actualValues: const ActualSetValues.repBased(weightKg: 20, reps: 5),
            plannedSetIdInSnapshot: set.id,
          );
        }

        final reloaded = updated.sessionExercises.single;
        final outcome = ExerciseOutcomes.of(
          state: reloaded.state,
          executedSetCount: reloaded.executedSets.length,
          plannedSetCount: _snapshotExercise(updated).sets.length,
        );
        expect(outcome, ExerciseOutcome.completed);
      } finally {
        await db.close();
      }
    });

    test('a deload snapshot is internally consistent on reload', () async {
      final db = AppDatabase(NativeDatabase.memory());
      try {
        final s = await _setup(db);
        final session = await s.session.startSession(
          workoutDayId: s.dayId,
          isDeload: true,
        );
        // getSession reconstructs the snapshot, which re-validates its
        // canonical-JSON/hash invariant; a non-null result means it held.
        final reloaded = await s.session.getSession(session.id);
        expect(reloaded, isNotNull);
        expect(reloaded!.isDeload, isTrue);
        expect(_snapshotExercise(reloaded).sets.length, 2);
      } finally {
        await db.close();
      }
    });
  });
}
