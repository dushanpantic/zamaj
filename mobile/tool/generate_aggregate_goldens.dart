import 'dart:convert';
import 'dart:io';

import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_note.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

void writeGolden(String name, Map<String, dynamic> json) {
  final file = File('test/serialization/golden/$name.json');
  file.writeAsStringSync(jsonEncode(json));
  stdout.writeln('Wrote $name.json');
}

void main() {
  final t0 = DateTime.utc(2024, 1, 15, 10, 0, 0);
  final t1 = DateTime.utc(2024, 1, 15, 10, 30, 0);
  final t2 = DateTime.utc(2024, 1, 15, 11, 0, 0);

  const programId = '11111111-1111-4111-8111-111111111111';
  const workoutDayId = '22222222-2222-4222-8222-222222222222';
  const exerciseGroupId = '33333333-3333-4333-8333-333333333333';
  const exerciseId = '44444444-4444-4444-8444-444444444444';
  const setId = '55555555-5555-4555-8555-555555555555';
  const sessionId = '66666666-6666-4666-8666-666666666666';
  const sessionExerciseId = '77777777-7777-4777-8777-777777777777';
  const executedSetId = '88888888-8888-4888-8888-888888888888';
  const sessionNoteId = '99999999-9999-4999-8999-999999999999';
  const extraWorkId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';

  const metadata = ExerciseMetadata(
    notes: 'Squeeze at the top',
    videoUrl: 'https://example.com/bench-press',
  );

  final workoutSet = WorkoutSet(
    id: setId,
    exerciseId: exerciseId,
    position: 0,
    measurementType: const MeasurementType.repBased(),
    plannedValues: const PlannedSetValues.repBased(weightKg: 80.0, reps: 8),
    createdAt: t0,
    updatedAt: t0,
    schemaVersion: 1,
  );

  final exercise = Exercise(
    id: exerciseId,
    exerciseGroupId: exerciseGroupId,
    position: 0,
    name: 'Bench Press',
    measurementType: const MeasurementType.repBased(),
    metadata: metadata,
    sets: [workoutSet],
    createdAt: t0,
    updatedAt: t0,
    schemaVersion: 1,
  );

  final exerciseWithRest = Exercise(
    id: exerciseId,
    exerciseGroupId: exerciseGroupId,
    position: 0,
    name: 'Bench Press',
    measurementType: const MeasurementType.repBased(),
    metadata: metadata,
    plannedRestSeconds: 90,
    sets: [workoutSet],
    createdAt: t0,
    updatedAt: t0,
    schemaVersion: 1,
  );

  final exerciseGroup = ExerciseGroup(
    id: exerciseGroupId,
    workoutDayId: workoutDayId,
    position: 0,
    kind: const ExerciseGroupKind.single(),
    exercises: [exercise],
    createdAt: t0,
    updatedAt: t0,
    schemaVersion: 1,
  );

  final workoutDay = WorkoutDay(
    id: workoutDayId,
    programId: programId,
    name: 'Upper A',
    exerciseGroups: [exerciseGroup],
    createdAt: t0,
    updatedAt: t0,
    schemaVersion: 1,
  );

  final program = Program(
    id: programId,
    name: 'Hypertrophy Block',
    workoutDayIds: [workoutDayId],
    createdAt: t0,
    updatedAt: t0,
    schemaVersion: 1,
  );

  const substitute = SubstituteExercise(
    name: 'Dumbbell Press',
    measurementType: MeasurementType.repBased(),
    metadata: ExerciseMetadata(notes: 'Use 30kg dumbbells'),
  );

  final executedSet = ExecutedSet(
    id: executedSetId,
    sessionExerciseId: sessionExerciseId,
    position: 0,
    measurementType: const MeasurementType.repBased(),
    actualValues: const ActualSetValues.repBased(weightKg: 82.5, reps: 7),
    plannedSetIdInSnapshot: setId,
    completedAt: t1,
    createdAt: t1,
    updatedAt: t1,
    schemaVersion: 1,
  );

  final sessionExercise = SessionExercise(
    id: sessionExerciseId,
    sessionId: sessionId,
    position: 0,
    plannedExerciseIdInSnapshot: exerciseId,
    state: const ExerciseState.completed(),
    executedSets: [executedSet],
    createdAt: t1,
    updatedAt: t1,
    schemaVersion: 1,
  );

  final sessionNote = SessionNote(
    id: sessionNoteId,
    sessionId: sessionId,
    body: 'Felt strong today',
    createdAt: t1,
    updatedAt: t1,
    schemaVersion: 1,
  );

  final extraWork = ExtraWork(
    id: extraWorkId,
    sessionId: sessionId,
    position: 0,
    body: '10 min treadmill cooldown',
    createdAt: t2,
    updatedAt: t2,
    schemaVersion: 1,
  );

  final snapshotJson = CanonicalJson.encode(workoutDay.toJson());
  final snapshotHash = CanonicalJson.sha256Hex(snapshotJson);
  final snapshot = SessionSnapshot(
    workoutDay: workoutDay,
    canonicalJson: snapshotJson,
    sha256Hash: snapshotHash,
    capturedAt: t0,
    schemaVersion: 1,
  );

  final session = Session(
    id: sessionId,
    workoutDayId: workoutDayId,
    snapshot: snapshot,
    sessionExercises: [sessionExercise],
    notes: [sessionNote],
    extraWork: [extraWork],
    startedAt: t0,
    endedAt: t2,
    createdAt: t0,
    updatedAt: t2,
    schemaVersion: 1,
  );

  writeGolden('exercise_metadata', metadata.toJson());
  writeGolden('workout_set', workoutSet.toJson());
  writeGolden('exercise', exercise.toJson());
  writeGolden('exercise_with_rest', exerciseWithRest.toJson());
  writeGolden('exercise_group', exerciseGroup.toJson());
  writeGolden('workout_day', workoutDay.toJson());
  writeGolden('program', program.toJson());
  writeGolden('substitute_exercise', substitute.toJson());
  writeGolden('executed_set', executedSet.toJson());
  writeGolden('session_exercise', sessionExercise.toJson());
  writeGolden('session_note', sessionNote.toJson());
  writeGolden('extra_work', extraWork.toJson());
  writeGolden('session_snapshot', snapshot.toJson());
  writeGolden('session', session.toJson());
}
