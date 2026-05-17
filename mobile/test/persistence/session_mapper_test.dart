import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/domain/models/workout_set.dart' as domain;
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/mappers/session_mapper.dart';

void main() {
  final mapper = SessionMapper();

  const sessionId = '11111111-1111-4111-8111-111111111111';
  const workoutDayId = '22222222-2222-4222-8222-222222222222';
  const sessionExerciseId = '33333333-3333-4333-8333-333333333333';
  const executedSetId = '44444444-4444-4444-8444-444444444444';
  const sessionNoteId = '55555555-5555-4555-8555-555555555555';
  const extraWorkId = '66666666-6666-4666-8666-666666666666';
  const plannedExerciseId = '77777777-7777-4777-8777-777777777777';
  const plannedSetId = '88888888-8888-4888-8888-888888888888';
  const groupId = 'aaaaaaaa-aaaa-4aaa-8aaa-aaaaaaaaaaaa';
  const programId = '99999999-9999-4999-8999-999999999999';

  late String snapshotJson;
  late String snapshotHash;

  setUpAll(() {
    final workoutDay = domain.WorkoutDay(
      id: workoutDayId,
      programId: programId,
      name: 'Push Day',
      exerciseGroups: [
        domain.ExerciseGroup(
          id: groupId,
          workoutDayId: workoutDayId,
          position: 0,
          kind: const ExerciseGroupKind.single(),
          exercises: [
            domain.Exercise(
              id: plannedExerciseId,
              exerciseGroupId: groupId,
              position: 0,
              name: 'Bench Press',
              measurementType: const MeasurementType.repBased(),
              metadata: const ExerciseMetadata(notes: null, videoUrl: null),
              sets: [
                domain.WorkoutSet(
                  id: plannedSetId,
                  exerciseId: plannedExerciseId,
                  position: 0,
                  measurementType: const MeasurementType.repBased(),
                  plannedValues: PlannedSetValues.repBased(
                    weightKg: 60.0,
                    repTarget: RepTarget.fixed(reps: 8),
                  ),
                  createdAt: DateTime.fromMillisecondsSinceEpoch(
                    1700000000000,
                    isUtc: true,
                  ),
                  updatedAt: DateTime.fromMillisecondsSinceEpoch(
                    1700000000000,
                    isUtc: true,
                  ),
                  schemaVersion: 1,
                ),
              ],
              createdAt: DateTime.fromMillisecondsSinceEpoch(
                1700000000000,
                isUtc: true,
              ),
              updatedAt: DateTime.fromMillisecondsSinceEpoch(
                1700000000000,
                isUtc: true,
              ),
              schemaVersion: 1,
            ),
          ],
          createdAt: DateTime.fromMillisecondsSinceEpoch(
            1700000000000,
            isUtc: true,
          ),
          updatedAt: DateTime.fromMillisecondsSinceEpoch(
            1700000000000,
            isUtc: true,
          ),
          schemaVersion: 1,
        ),
      ],
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        1700000000000,
        isUtc: true,
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        1700000000000,
        isUtc: true,
      ),
      schemaVersion: 1,
    );
    snapshotJson = CanonicalJson.encode(workoutDay.toJson());
    snapshotHash = CanonicalJson.sha256Hex(snapshotJson);
  });

  late Session sessionRow;
  late SessionExercise sessionExerciseRow;
  late ExecutedSet executedSetRow;
  late SessionNote sessionNoteRow;
  late ExtraWorkItem extraWorkRow;

  final actualJson = const ActualSetValues.repBased(
    weightKg: 60.0,
    reps: 8,
  ).toJson();
  final actualPayload = CanonicalJson.encode(actualJson);

  setUp(() {
    sessionRow = Session(
      id: sessionId,
      workoutDayId: workoutDayId,
      snapshotJson: snapshotJson,
      snapshotHash: snapshotHash,
      startedAtMs: 1700000010000,
      endedAtMs: 1700000020000,
      createdAtMs: 1700000010000,
      updatedAtMs: 1700000020000,
      schemaVersion: 1,
    );

    sessionExerciseRow = const SessionExercise(
      id: sessionExerciseId,
      sessionId: sessionId,
      position: 0,
      plannedExerciseIdInSnapshot: plannedExerciseId,
      stateDiscriminator: 'unfinished',
      substitutePayloadJson: null,
      createdAtMs: 1700000010000,
      updatedAtMs: 1700000010000,
      schemaVersion: 1,
    );

    executedSetRow = ExecutedSet(
      id: executedSetId,
      sessionExerciseId: sessionExerciseId,
      position: 0,
      measurementTypeDiscriminator: 'repBased',
      actualValuesDiscriminator: actualJson['type'] as String,
      actualValuesPayloadJson: actualPayload,
      plannedSetIdInSnapshot: plannedSetId,
      completedAtMs: 1700000015000,
      createdAtMs: 1700000015000,
      updatedAtMs: 1700000015000,
      schemaVersion: 1,
    );

    sessionNoteRow = const SessionNote(
      id: sessionNoteId,
      sessionId: sessionId,
      body: 'Felt strong today',
      createdAtMs: 1700000018000,
      updatedAtMs: 1700000018000,
      schemaVersion: 1,
    );

    extraWorkRow = const ExtraWorkItem(
      id: extraWorkId,
      sessionId: sessionId,
      position: 0,
      body: '10 min treadmill',
      createdAtMs: 1700000019000,
      updatedAtMs: 1700000019000,
      schemaVersion: 1,
    );
  });

  test('sessionToRow round-trips all fields', () {
    final domainSession = mapper.toDomain(
      sessionRow,
      [sessionExerciseRow],
      [executedSetRow],
      [sessionNoteRow],
      [extraWorkRow],
    );
    final companion = mapper.sessionToRow(domainSession);

    expect(companion.id.value, equals(sessionRow.id));
    expect(companion.workoutDayId.value, equals(sessionRow.workoutDayId));
    expect(companion.snapshotJson.value, equals(sessionRow.snapshotJson));
    expect(companion.snapshotHash.value, equals(sessionRow.snapshotHash));
    expect(companion.startedAtMs.value, equals(sessionRow.startedAtMs));
    expect(companion.endedAtMs.value, equals(sessionRow.endedAtMs));
    expect(companion.createdAtMs.value, equals(sessionRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(sessionRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(sessionRow.schemaVersion));
  });

  test('sessionExerciseToRow round-trips all fields', () {
    final domainSession = mapper.toDomain(
      sessionRow,
      [sessionExerciseRow],
      [executedSetRow],
      [sessionNoteRow],
      [extraWorkRow],
    );
    final companion = mapper.sessionExerciseToRow(
      domainSession.sessionExercises.first,
    );

    expect(companion.id.value, equals(sessionExerciseRow.id));
    expect(companion.sessionId.value, equals(sessionExerciseRow.sessionId));
    expect(companion.position.value, equals(sessionExerciseRow.position));
    expect(
      companion.plannedExerciseIdInSnapshot.value,
      equals(sessionExerciseRow.plannedExerciseIdInSnapshot),
    );
    expect(
      companion.stateDiscriminator.value,
      equals(sessionExerciseRow.stateDiscriminator),
    );
    expect(
      companion.substitutePayloadJson.value,
      equals(sessionExerciseRow.substitutePayloadJson),
    );
    expect(companion.createdAtMs.value, equals(sessionExerciseRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(sessionExerciseRow.updatedAtMs));
    expect(
      companion.schemaVersion.value,
      equals(sessionExerciseRow.schemaVersion),
    );
  });

  test('executedSetToRow round-trips all fields', () {
    final domainSession = mapper.toDomain(
      sessionRow,
      [sessionExerciseRow],
      [executedSetRow],
      [sessionNoteRow],
      [extraWorkRow],
    );
    final companion = mapper.executedSetToRow(
      domainSession.sessionExercises.first.executedSets.first,
    );

    expect(companion.id.value, equals(executedSetRow.id));
    expect(
      companion.sessionExerciseId.value,
      equals(executedSetRow.sessionExerciseId),
    );
    expect(companion.position.value, equals(executedSetRow.position));
    expect(
      companion.measurementTypeDiscriminator.value,
      equals(executedSetRow.measurementTypeDiscriminator),
    );
    expect(
      companion.actualValuesDiscriminator.value,
      equals(executedSetRow.actualValuesDiscriminator),
    );
    expect(
      companion.actualValuesPayloadJson.value,
      equals(executedSetRow.actualValuesPayloadJson),
    );
    expect(
      companion.plannedSetIdInSnapshot.value,
      equals(executedSetRow.plannedSetIdInSnapshot),
    );
    expect(companion.completedAtMs.value, equals(executedSetRow.completedAtMs));
    expect(companion.createdAtMs.value, equals(executedSetRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(executedSetRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(executedSetRow.schemaVersion));
  });

  test('sessionNoteToRow round-trips all fields', () {
    final domainSession = mapper.toDomain(
      sessionRow,
      [sessionExerciseRow],
      [executedSetRow],
      [sessionNoteRow],
      [extraWorkRow],
    );
    final companion = mapper.sessionNoteToRow(domainSession.notes.first);

    expect(companion.id.value, equals(sessionNoteRow.id));
    expect(companion.sessionId.value, equals(sessionNoteRow.sessionId));
    expect(companion.body.value, equals(sessionNoteRow.body));
    expect(companion.createdAtMs.value, equals(sessionNoteRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(sessionNoteRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(sessionNoteRow.schemaVersion));
  });

  test('extraWorkToRow round-trips all fields', () {
    final domainSession = mapper.toDomain(
      sessionRow,
      [sessionExerciseRow],
      [executedSetRow],
      [sessionNoteRow],
      [extraWorkRow],
    );
    final companion = mapper.extraWorkToRow(domainSession.extraWork.first);

    expect(companion.id.value, equals(extraWorkRow.id));
    expect(companion.sessionId.value, equals(extraWorkRow.sessionId));
    expect(companion.position.value, equals(extraWorkRow.position));
    expect(companion.body.value, equals(extraWorkRow.body));
    expect(companion.createdAtMs.value, equals(extraWorkRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(extraWorkRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(extraWorkRow.schemaVersion));
  });
}
