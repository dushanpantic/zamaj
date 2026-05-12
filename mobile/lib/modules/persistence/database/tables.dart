import 'package:drift/drift.dart';

class Programs extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get name => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ProgramWorkoutDays extends Table {
  TextColumn get programId =>
      text().references(Programs, #id, onDelete: KeyAction.cascade)();
  TextColumn get workoutDayId =>
      text().references(WorkoutDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();

  @override
  Set<Column> get primaryKey => {programId, workoutDayId};

  @override
  List<Set<Column>> get uniqueKeys => [
    {programId, position},
  ];
}

@TableIndex(name: 'workout_days_program_id', columns: {#programId})
class WorkoutDays extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get programId =>
      text().references(Programs, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExerciseGroups extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get workoutDayId =>
      text().references(WorkoutDays, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get kindDiscriminator => text()();
  TextColumn get kindPayloadJson => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {workoutDayId, position},
  ];
}

class Exercises extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get exerciseGroupId =>
      text().references(ExerciseGroups, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get name => text()();
  TextColumn get measurementTypeDiscriminator => text()();
  TextColumn get measurementTypePayloadJson => text()();
  TextColumn get notes => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  IntColumn get plannedRestSeconds => integer().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {exerciseGroupId, position},
  ];
}

class WorkoutSets extends Table {
  @override
  String get tableName => 'sets';

  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get exerciseId =>
      text().references(Exercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get plannedValuesDiscriminator => text()();
  TextColumn get plannedValuesPayloadJson => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {exerciseId, position},
  ];
}

@TableIndex(name: 'sessions_workout_day_id', columns: {#workoutDayId})
class Sessions extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get workoutDayId => text()();
  TextColumn get snapshotJson => text()();
  TextColumn get snapshotHash => text().withLength(min: 64, max: 64)();
  IntColumn get startedAtMs => integer()();
  IntColumn get endedAtMs => integer().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@TableIndex(
  name: 'session_exercises_session_state',
  columns: {#sessionId, #stateDiscriminator},
)
class SessionExercises extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get plannedExerciseIdInSnapshot =>
      text().withLength(min: 36, max: 36)();
  TextColumn get stateDiscriminator => text()();
  TextColumn get substitutePayloadJson => text().nullable()();
  TextColumn get supersetTag => text().nullable()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionId, position},
  ];
}

class ExecutedSets extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get sessionExerciseId =>
      text().references(SessionExercises, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get measurementTypeDiscriminator => text()();
  TextColumn get actualValuesDiscriminator => text()();
  TextColumn get actualValuesPayloadJson => text()();
  TextColumn get plannedSetIdInSnapshot => text().nullable()();
  IntColumn get completedAtMs => integer()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionExerciseId, position},
  ];
}

@TableIndex(name: 'session_notes_session_id', columns: {#sessionId})
class SessionNotes extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  TextColumn get body => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class ExtraWorkItems extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();
  TextColumn get sessionId =>
      text().references(Sessions, #id, onDelete: KeyAction.cascade)();
  IntColumn get position => integer()();
  TextColumn get body => text()();
  IntColumn get createdAtMs => integer()();
  IntColumn get updatedAtMs => integer()();
  IntColumn get schemaVersion => integer()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
    {sessionId, position},
  ];
}
