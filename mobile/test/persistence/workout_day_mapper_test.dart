import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/mappers/workout_day_mapper.dart';

void main() {
  final mapper = WorkoutDayMapper();

  const workoutDayId = '11111111-1111-4111-8111-111111111111';
  const programId = '22222222-2222-4222-8222-222222222222';
  const groupId = '33333333-3333-4333-8333-333333333333';
  const exerciseId = '44444444-4444-4444-8444-444444444444';
  const setId = '55555555-5555-4555-8555-555555555555';

  final kindJson = const ExerciseGroupKind.single().toJson();
  final kindPayload = CanonicalJson.encode(kindJson);

  final measurementJson = const MeasurementType.repBased().toJson();
  final measurementPayload = CanonicalJson.encode(measurementJson);

  final plannedJson = PlannedSetValues.repBased(
    weightKg: 60.0,
    repTarget: RepTarget.fixed(reps: 8),
  ).toJson();
  final plannedPayload = CanonicalJson.encode(plannedJson);

  const workoutDayRow = WorkoutDay(
    id: workoutDayId,
    programId: programId,
    name: 'Push Day',
    createdAtMs: 1700000000000,
    updatedAtMs: 1700000001000,
    schemaVersion: 1,
  );

  late ExerciseGroup groupRow;
  late Exercise exerciseRow;
  late WorkoutSet setRow;

  setUp(() {
    groupRow = ExerciseGroup(
      id: groupId,
      workoutDayId: workoutDayId,
      position: 0,
      kindDiscriminator: kindJson['type'] as String,
      kindPayloadJson: kindPayload,
      roleDiscriminator: 'main',
      createdAtMs: 1700000002000,
      updatedAtMs: 1700000003000,
      schemaVersion: 1,
    );

    exerciseRow = Exercise(
      id: exerciseId,
      exerciseGroupId: groupId,
      position: 0,
      name: 'Bench Press',
      measurementTypeDiscriminator: measurementJson['type'] as String,
      measurementTypePayloadJson: measurementPayload,
      notes: null,
      videoUrl: null,
      createdAtMs: 1700000004000,
      updatedAtMs: 1700000005000,
      schemaVersion: 1,
    );

    setRow = WorkoutSet(
      id: setId,
      exerciseId: exerciseId,
      position: 0,
      plannedValuesDiscriminator: plannedJson['type'] as String,
      plannedValuesPayloadJson: plannedPayload,
      createdAtMs: 1700000006000,
      updatedAtMs: 1700000007000,
      schemaVersion: 1,
    );
  });

  test('workoutDayToRow round-trips all fields', () {
    final domain = mapper.toDomain(workoutDayRow, [groupRow], [exerciseRow], [
      setRow,
    ]);
    final companion = mapper.workoutDayToRow(domain);

    expect(companion.id.value, equals(workoutDayRow.id));
    expect(companion.programId.value, equals(workoutDayRow.programId));
    expect(companion.name.value, equals(workoutDayRow.name));
    expect(companion.createdAtMs.value, equals(workoutDayRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(workoutDayRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(workoutDayRow.schemaVersion));
  });

  test('exerciseGroupToRow round-trips all fields', () {
    final domain = mapper.toDomain(workoutDayRow, [groupRow], [exerciseRow], [
      setRow,
    ]);
    final companion = mapper.exerciseGroupToRow(domain.exerciseGroups.first);

    expect(companion.id.value, equals(groupRow.id));
    expect(companion.workoutDayId.value, equals(groupRow.workoutDayId));
    expect(companion.position.value, equals(groupRow.position));
    expect(
      companion.kindDiscriminator.value,
      equals(groupRow.kindDiscriminator),
    );
    expect(companion.kindPayloadJson.value, equals(groupRow.kindPayloadJson));
    expect(companion.createdAtMs.value, equals(groupRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(groupRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(groupRow.schemaVersion));
  });

  test('exerciseToRow round-trips all fields', () {
    final domain = mapper.toDomain(workoutDayRow, [groupRow], [exerciseRow], [
      setRow,
    ]);
    final companion = mapper.exerciseToRow(
      domain.exerciseGroups.first.exercises.first,
    );

    expect(companion.id.value, equals(exerciseRow.id));
    expect(
      companion.exerciseGroupId.value,
      equals(exerciseRow.exerciseGroupId),
    );
    expect(companion.position.value, equals(exerciseRow.position));
    expect(companion.name.value, equals(exerciseRow.name));
    expect(
      companion.measurementTypeDiscriminator.value,
      equals(exerciseRow.measurementTypeDiscriminator),
    );
    expect(
      companion.measurementTypePayloadJson.value,
      equals(exerciseRow.measurementTypePayloadJson),
    );
    expect(companion.notes.value, equals(exerciseRow.notes));
    expect(companion.videoUrl.value, equals(exerciseRow.videoUrl));
    expect(companion.createdAtMs.value, equals(exerciseRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(exerciseRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(exerciseRow.schemaVersion));
  });

  test('exerciseToRow round-trips plannedRestSeconds when null', () {
    final rowWithNullRest = Exercise(
      id: exerciseId,
      exerciseGroupId: groupId,
      position: 0,
      name: 'Bench Press',
      measurementTypeDiscriminator: measurementJson['type'] as String,
      measurementTypePayloadJson: measurementPayload,
      notes: null,
      videoUrl: null,
      plannedRestSeconds: null,
      createdAtMs: 1700000004000,
      updatedAtMs: 1700000005000,
      schemaVersion: 1,
    );

    final domain = mapper.toDomain(
      workoutDayRow,
      [groupRow],
      [rowWithNullRest],
      [setRow],
    );
    final companion = mapper.exerciseToRow(
      domain.exerciseGroups.first.exercises.first,
    );

    expect(companion.plannedRestSeconds.value, isNull);
  });

  test('exerciseToRow round-trips plannedRestSeconds when 90', () {
    final rowWithRest = Exercise(
      id: exerciseId,
      exerciseGroupId: groupId,
      position: 0,
      name: 'Bench Press',
      measurementTypeDiscriminator: measurementJson['type'] as String,
      measurementTypePayloadJson: measurementPayload,
      notes: null,
      videoUrl: null,
      plannedRestSeconds: 90,
      createdAtMs: 1700000004000,
      updatedAtMs: 1700000005000,
      schemaVersion: 1,
    );

    final domain = mapper.toDomain(workoutDayRow, [groupRow], [rowWithRest], [
      setRow,
    ]);
    final companion = mapper.exerciseToRow(
      domain.exerciseGroups.first.exercises.first,
    );

    expect(companion.plannedRestSeconds.value, equals(90));
  });

  test('setToRow round-trips all fields', () {
    final domain = mapper.toDomain(workoutDayRow, [groupRow], [exerciseRow], [
      setRow,
    ]);
    final companion = mapper.setToRow(
      domain.exerciseGroups.first.exercises.first.sets.first,
    );

    expect(companion.id.value, equals(setRow.id));
    expect(companion.exerciseId.value, equals(setRow.exerciseId));
    expect(companion.position.value, equals(setRow.position));
    expect(
      companion.plannedValuesDiscriminator.value,
      equals(setRow.plannedValuesDiscriminator),
    );
    expect(
      companion.plannedValuesPayloadJson.value,
      equals(setRow.plannedValuesPayloadJson),
    );
    expect(companion.createdAtMs.value, equals(setRow.createdAtMs));
    expect(companion.updatedAtMs.value, equals(setRow.updatedAtMs));
    expect(companion.schemaVersion.value, equals(setRow.schemaVersion));
  });
}
