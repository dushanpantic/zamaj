import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart' as domain;
import 'package:zamaj/modules/domain/services/session_flow_engine.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/repositories/drift_program_repository.dart';
import 'package:zamaj/modules/persistence/repositories/drift_session_repository.dart';

domain.Exercise _exercise(String name, {int sets = 1}) => domain.Exercise(
  id: '',
  exerciseGroupId: '',
  position: 0,
  name: name,
  measurementType: const MeasurementType.repBased(),
  metadata: ExerciseMetadata.empty,
  sets: [
    for (var i = 0; i < sets; i++)
      domain.WorkoutSet(
        id: '',
        exerciseId: '',
        position: i,
        measurementType: const MeasurementType.repBased(),
        plannedValues: PlannedSetValues.repBased(
          weightKg: 100,
          repTarget: RepTarget.fixed(reps: 5),
        ),
        createdAt: DateTime.utc(2024),
        updatedAt: DateTime.utc(2024),
        schemaVersion: 1,
      ),
  ],
  createdAt: DateTime.utc(2024),
  updatedAt: DateTime.utc(2024),
  schemaVersion: 1,
);

void main() {
  test('resumeExercise reverts an ended-early exercise to unfinished, '
      'retaining its logged sets, and re-loggable from the next set', () async {
    final db = AppDatabase(NativeDatabase.memory());
    try {
      final programRepo = DriftProgramRepository(db: db);
      final sessionRepo = DriftSessionRepository(
        db: db,
        programRepository: programRepo,
      );
      final engine = SessionFlowEngine(repository: sessionRepo);

      final program = await programRepo.createProgram(name: 'P');
      final workoutDay = await programRepo.createWorkoutDay(
        programId: program.id,
        name: 'D',
      );
      await programRepo.createExerciseGroup(
        workoutDayId: workoutDay.id,
        kind: const ExerciseGroupKind.single(),
        exercises: [_exercise('Squat', sets: 4)],
      );

      final session = await sessionRepo.startSession(
        workoutDayId: workoutDay.id,
      );
      final seId = session.sessionExercises.single.id;

      // Log 2 of 4, then end early (skip), then resume.
      for (var i = 0; i < 2; i++) {
        await engine.completeSet(
          sessionExerciseId: seId,
          actualValues: const ActualSetValues.repBased(weightKg: 100, reps: 5),
        );
      }
      await engine.skipExercise(sessionExerciseId: seId);

      final resumed = await engine.resumeExercise(sessionExerciseId: seId);

      final exercise = resumed.session.sessionExercises.single;
      expect(exercise.state, isA<UnfinishedState>());
      expect(exercise.executedSets, hasLength(2));
      final target = resumed.openTargets.firstWhere(
        (t) => t.sessionExerciseId == seId,
      );
      expect(target.plannedSetIndex, 2);

      // Persisted: reloading shows unfinished with its 2 sets.
      final reloaded = (await sessionRepo.getSession(session.id))!;
      expect(reloaded.sessionExercises.single.state, isA<UnfinishedState>());
      expect(reloaded.sessionExercises.single.executedSets, hasLength(2));
    } finally {
      await db.close();
    }
  });
}
