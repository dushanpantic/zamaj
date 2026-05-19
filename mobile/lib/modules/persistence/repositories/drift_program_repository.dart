import 'package:clock/clock.dart';
import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/core/canonical_json.dart';
import 'package:zamaj/core/schema_versions.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group.dart' as domain;
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program.dart' as domain;
import 'package:zamaj/modules/domain/models/program_aggregate.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart' as domain;
import 'package:zamaj/modules/domain/models/workout_set.dart' as domain;
import 'package:zamaj/modules/domain/repositories/program_repository.dart';
import 'package:zamaj/modules/persistence/database/app_database.dart';
import 'package:zamaj/modules/persistence/database/datetime_utils.dart';
import 'package:zamaj/modules/persistence/database/timestamp_oracle.dart';
import 'package:zamaj/modules/persistence/mappers/program_mapper.dart';
import 'package:zamaj/modules/persistence/mappers/workout_day_mapper.dart';

class DriftProgramRepository implements ProgramRepository {
  DriftProgramRepository({required AppDatabase db, Clock clock = const Clock()})
    : _db = db,
      _clock = clock,
      _timestamps = TimestampOracle(clock);

  final AppDatabase _db;
  final Clock _clock;
  final TimestampOracle _timestamps;
  final _uuid = const Uuid();
  final _programMapper = ProgramMapper();
  final _workoutDayMapper = WorkoutDayMapper();

  @override
  Future<domain.Program> createProgram({required String name}) async {
    return _db.transaction(() async {
      final id = _uuid.v4();
      final now = _clock.now().toUtc();
      await _db
          .into(_db.programs)
          .insert(
            ProgramsCompanion.insert(
              id: id,
              name: name,
              createdAtMs: utcToMs(now),
              updatedAtMs: utcToMs(now),
              schemaVersion: SchemaVersions.domain,
            ),
          );
      final row = await (_db.select(
        _db.programs,
      )..where((t) => t.id.equals(id))).getSingle();
      return _programMapper.toDomain(row, []);
    });
  }

  @override
  Future<domain.Program?> getProgram(String programId) async {
    final row = await (_db.select(
      _db.programs,
    )..where((t) => t.id.equals(programId))).getSingleOrNull();
    if (row == null) return null;
    final dayIds = await _getWorkoutDayIdsForProgram(programId);
    return _programMapper.toDomain(row, dayIds);
  }

  @override
  Future<List<domain.Program>> listPrograms() async {
    final rows = await _db.select(_db.programs).get();
    final links =
        await (_db.select(_db.programWorkoutDays)..orderBy([
              (t) => OrderingTerm.asc(t.programId),
              (t) => OrderingTerm.asc(t.position),
            ]))
            .get();
    final dayIdsByProgram = <String, List<String>>{};
    for (final link in links) {
      (dayIdsByProgram[link.programId] ??= []).add(link.workoutDayId);
    }
    return [
      for (final row in rows)
        _programMapper.toDomain(row, dayIdsByProgram[row.id] ?? const []),
    ];
  }

  @override
  Future<domain.Program> updateProgram(domain.Program program) async {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.programs,
      )..where((t) => t.id.equals(program.id))).getSingleOrNull();
      if (existing == null) {
        throw NotFoundError(entityType: 'Program', id: program.id);
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(existing.updatedAtMs),
        createdAt: msToUtc(existing.createdAtMs),
      );
      await (_db.update(
        _db.programs,
      )..where((t) => t.id.equals(program.id))).write(
        ProgramsCompanion(
          name: Value(program.name),
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );
      final updated = await (_db.select(
        _db.programs,
      )..where((t) => t.id.equals(program.id))).getSingle();
      final dayIds = await _getWorkoutDayIdsForProgram(program.id);
      return _programMapper.toDomain(updated, dayIds);
    });
  }

  @override
  Future<void> deleteProgram(String programId) async {
    await (_db.delete(_db.programs)..where((t) => t.id.equals(programId))).go();
  }

  @override
  Future<domain.WorkoutDay> createWorkoutDay({
    required String programId,
    required String name,
  }) async {
    return _db.transaction(() async {
      final programRow = await (_db.select(
        _db.programs,
      )..where((t) => t.id.equals(programId))).getSingleOrNull();
      if (programRow == null) {
        throw NotFoundError(entityType: 'Program', id: programId);
      }

      final id = _uuid.v4();
      final now = _clock.now().toUtc();
      await _db
          .into(_db.workoutDays)
          .insert(
            WorkoutDaysCompanion.insert(
              id: id,
              programId: programId,
              name: name,
              createdAtMs: utcToMs(now),
              updatedAtMs: utcToMs(now),
              schemaVersion: SchemaVersions.domain,
            ),
          );

      final newPosition = await _nextPositionForProgramWorkoutDays(programId);
      await _db
          .into(_db.programWorkoutDays)
          .insert(
            ProgramWorkoutDaysCompanion.insert(
              programId: programId,
              workoutDayId: id,
              position: newPosition,
            ),
          );

      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(programRow.updatedAtMs),
        createdAt: msToUtc(programRow.createdAtMs),
      );
      await (_db.update(
        _db.programs,
      )..where((t) => t.id.equals(programId))).write(
        ProgramsCompanion(
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );

      final dayRow = await (_db.select(
        _db.workoutDays,
      )..where((t) => t.id.equals(id))).getSingle();
      return _workoutDayMapper.toDomain(dayRow, [], [], []);
    });
  }

  @override
  Future<domain.WorkoutDay?> getWorkoutDay(String workoutDayId) async {
    return _loadWorkoutDay(workoutDayId);
  }

  @override
  Future<List<domain.WorkoutDay>> listWorkoutDaysForProgram(
    String programId,
  ) async {
    final dayIds = await _getWorkoutDayIdsForProgram(programId);
    if (dayIds.isEmpty) return const [];

    final dayRows = await (_db.select(
      _db.workoutDays,
    )..where((t) => t.id.isIn(dayIds))).get();
    final dayRowById = {for (final r in dayRows) r.id: r};

    final groupRows =
        await (_db.select(_db.exerciseGroups)
              ..where((t) => t.workoutDayId.isIn(dayIds))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final groupIds = groupRows.map((g) => g.id).toList();

    final exerciseRows = groupIds.isEmpty
        ? <Exercise>[]
        : await (_db.select(_db.exercises)
                ..where((t) => t.exerciseGroupId.isIn(groupIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();
    final exerciseIds = exerciseRows.map((e) => e.id).toList();

    final setRows = exerciseIds.isEmpty
        ? <WorkoutSet>[]
        : await (_db.select(_db.workoutSets)
                ..where((t) => t.exerciseId.isIn(exerciseIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

    final groupsByDay = <String, List<ExerciseGroup>>{};
    for (final g in groupRows) {
      (groupsByDay[g.workoutDayId] ??= []).add(g);
    }

    return [
      for (final id in dayIds)
        if (dayRowById[id] case final dayRow?)
          _workoutDayMapper.toDomain(
            dayRow,
            groupsByDay[id] ?? const [],
            exerciseRows,
            setRows,
          ),
    ];
  }

  @override
  Future<domain.WorkoutDay> updateWorkoutDay(
    domain.WorkoutDay workoutDay,
  ) async {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.workoutDays,
      )..where((t) => t.id.equals(workoutDay.id))).getSingleOrNull();
      if (existing == null) {
        throw NotFoundError(entityType: 'WorkoutDay', id: workoutDay.id);
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(existing.updatedAtMs),
        createdAt: msToUtc(existing.createdAtMs),
      );
      await (_db.update(
        _db.workoutDays,
      )..where((t) => t.id.equals(workoutDay.id))).write(
        WorkoutDaysCompanion(
          name: Value(workoutDay.name),
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );
      final updated = await _loadWorkoutDay(workoutDay.id);
      return updated!;
    });
  }

  @override
  Future<void> deleteWorkoutDay(String workoutDayId) async {
    await (_db.delete(
      _db.workoutDays,
    )..where((t) => t.id.equals(workoutDayId))).go();
  }

  @override
  Future<void> reorderWorkoutDays(
    String programId,
    List<String> orderedWorkoutDayIds,
  ) async {
    await _db.transaction(() async {
      for (var i = 0; i < orderedWorkoutDayIds.length; i++) {
        final dayId = orderedWorkoutDayIds[i];
        final existing =
            await (_db.select(_db.programWorkoutDays)..where(
                  (t) =>
                      t.programId.equals(programId) &
                      t.workoutDayId.equals(dayId),
                ))
                .getSingleOrNull();
        if (existing == null) {
          throw NotFoundError(entityType: 'WorkoutDay', id: dayId);
        }
      }
      await _db.batch((b) {
        for (var i = 0; i < orderedWorkoutDayIds.length; i++) {
          b.update(
            _db.programWorkoutDays,
            ProgramWorkoutDaysCompanion(position: Value(-(i + 1))),
            where: (t) =>
                t.programId.equals(programId) &
                t.workoutDayId.equals(orderedWorkoutDayIds[i]),
          );
        }
        for (var i = 0; i < orderedWorkoutDayIds.length; i++) {
          b.update(
            _db.programWorkoutDays,
            ProgramWorkoutDaysCompanion(position: Value(i)),
            where: (t) =>
                t.programId.equals(programId) &
                t.workoutDayId.equals(orderedWorkoutDayIds[i]),
          );
        }
      });
    });
  }

  @override
  Future<domain.ExerciseGroup> createExerciseGroup({
    required String workoutDayId,
    required ExerciseGroupKind kind,
    required List<domain.Exercise> exercises,
    ExerciseGroupRole role = ExerciseGroupRole.main,
  }) async {
    return _db.transaction(() async {
      final dayRow = await (_db.select(
        _db.workoutDays,
      )..where((t) => t.id.equals(workoutDayId))).getSingleOrNull();
      if (dayRow == null) {
        throw NotFoundError(entityType: 'WorkoutDay', id: workoutDayId);
      }

      final position = await _nextPositionForExerciseGroups(workoutDayId);

      final groupId = _uuid.v4();
      final now = _clock.now().toUtc();
      final kindJson = kind.toJson();
      await _db
          .into(_db.exerciseGroups)
          .insert(
            ExerciseGroupsCompanion.insert(
              id: groupId,
              workoutDayId: workoutDayId,
              position: position,
              kindDiscriminator: kindJson['type'] as String,
              kindPayloadJson: CanonicalJson.encode(kindJson),
              roleDiscriminator: Value(role.name),
              createdAtMs: utcToMs(now),
              updatedAtMs: utcToMs(now),
              schemaVersion: SchemaVersions.domain,
            ),
          );

      for (var i = 0; i < exercises.length; i++) {
        final ex = exercises[i];
        final exerciseId = _uuid.v4();
        final measurementJson = ex.measurementType.toJson();
        await _db
            .into(_db.exercises)
            .insert(
              ExercisesCompanion.insert(
                id: exerciseId,
                exerciseGroupId: groupId,
                position: i,
                name: ex.name,
                measurementTypeDiscriminator: measurementJson['type'] as String,
                measurementTypePayloadJson: CanonicalJson.encode(
                  measurementJson,
                ),
                notes: Value(ex.metadata.notes),
                videoUrl: Value(ex.metadata.videoUrl),
                createdAtMs: utcToMs(now),
                updatedAtMs: utcToMs(now),
                schemaVersion: SchemaVersions.domain,
              ),
            );
        for (var j = 0; j < ex.sets.length; j++) {
          final s = ex.sets[j];
          final setId = _uuid.v4();
          final plannedJson = s.plannedValues.toJson();
          await _db
              .into(_db.workoutSets)
              .insert(
                WorkoutSetsCompanion.insert(
                  id: setId,
                  exerciseId: exerciseId,
                  position: j,
                  plannedValuesDiscriminator: plannedJson['type'] as String,
                  plannedValuesPayloadJson: CanonicalJson.encode(plannedJson),
                  createdAtMs: utcToMs(now),
                  updatedAtMs: utcToMs(now),
                  schemaVersion: SchemaVersions.domain,
                ),
              );
        }
      }

      return _loadExerciseGroup(groupId);
    });
  }

  @override
  Future<domain.ExerciseGroup> updateExerciseGroup(
    domain.ExerciseGroup group,
  ) async {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.exerciseGroups,
      )..where((t) => t.id.equals(group.id))).getSingleOrNull();
      if (existing == null) {
        throw NotFoundError(entityType: 'ExerciseGroup', id: group.id);
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(existing.updatedAtMs),
        createdAt: msToUtc(existing.createdAtMs),
      );
      final kindJson = group.kind.toJson();
      await (_db.update(
        _db.exerciseGroups,
      )..where((t) => t.id.equals(group.id))).write(
        ExerciseGroupsCompanion(
          kindDiscriminator: Value(kindJson['type'] as String),
          kindPayloadJson: Value(CanonicalJson.encode(kindJson)),
          roleDiscriminator: Value(group.role.name),
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );
      return _loadExerciseGroup(group.id);
    });
  }

  @override
  Future<void> deleteExerciseGroup(String exerciseGroupId) async {
    await (_db.delete(
      _db.exerciseGroups,
    )..where((t) => t.id.equals(exerciseGroupId))).go();
  }

  @override
  Future<void> reorderExerciseGroups(
    String workoutDayId,
    List<String> orderedGroupIds,
  ) async {
    await _db.transaction(() async {
      for (final groupId in orderedGroupIds) {
        final existing =
            await (_db.select(_db.exerciseGroups)..where(
                  (t) =>
                      t.id.equals(groupId) &
                      t.workoutDayId.equals(workoutDayId),
                ))
                .getSingleOrNull();
        if (existing == null) {
          throw NotFoundError(entityType: 'ExerciseGroup', id: groupId);
        }
      }
      await _db.batch((b) {
        for (var i = 0; i < orderedGroupIds.length; i++) {
          b.update(
            _db.exerciseGroups,
            ExerciseGroupsCompanion(position: Value(-(i + 1))),
            where: (t) => t.id.equals(orderedGroupIds[i]),
          );
        }
        for (var i = 0; i < orderedGroupIds.length; i++) {
          b.update(
            _db.exerciseGroups,
            ExerciseGroupsCompanion(position: Value(i)),
            where: (t) => t.id.equals(orderedGroupIds[i]),
          );
        }
      });
    });
  }

  @override
  Future<domain.Exercise> createExercise({
    required String exerciseGroupId,
    required String name,
    required MeasurementType measurementType,
    ExerciseMetadata metadata = ExerciseMetadata.empty,
    int? plannedRestSeconds,
  }) async {
    return _db.transaction(() async {
      final groupRow = await (_db.select(
        _db.exerciseGroups,
      )..where((t) => t.id.equals(exerciseGroupId))).getSingleOrNull();
      if (groupRow == null) {
        throw NotFoundError(entityType: 'ExerciseGroup', id: exerciseGroupId);
      }

      final position = await _nextPositionForExercises(exerciseGroupId);

      final id = _uuid.v4();
      final now = _clock.now().toUtc();
      final measurementJson = measurementType.toJson();
      await _db
          .into(_db.exercises)
          .insert(
            ExercisesCompanion.insert(
              id: id,
              exerciseGroupId: exerciseGroupId,
              position: position,
              name: name,
              measurementTypeDiscriminator: measurementJson['type'] as String,
              measurementTypePayloadJson: CanonicalJson.encode(measurementJson),
              notes: Value(metadata.notes),
              videoUrl: Value(metadata.videoUrl),
              plannedRestSeconds: Value(plannedRestSeconds),
              createdAtMs: utcToMs(now),
              updatedAtMs: utcToMs(now),
              schemaVersion: SchemaVersions.domain,
            ),
          );

      return _loadExercise(id);
    });
  }

  @override
  Future<domain.Exercise?> getExercise(String exerciseId) async {
    final row = await (_db.select(
      _db.exercises,
    )..where((t) => t.id.equals(exerciseId))).getSingleOrNull();
    if (row == null) return null;
    return _loadExercise(exerciseId);
  }

  @override
  Future<domain.Exercise> updateExercise(domain.Exercise exercise) async {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.exercises,
      )..where((t) => t.id.equals(exercise.id))).getSingleOrNull();
      if (existing == null) {
        throw NotFoundError(entityType: 'Exercise', id: exercise.id);
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(existing.updatedAtMs),
        createdAt: msToUtc(existing.createdAtMs),
      );
      final measurementJson = exercise.measurementType.toJson();
      await (_db.update(
        _db.exercises,
      )..where((t) => t.id.equals(exercise.id))).write(
        ExercisesCompanion(
          name: Value(exercise.name),
          measurementTypeDiscriminator: Value(
            measurementJson['type'] as String,
          ),
          measurementTypePayloadJson: Value(
            CanonicalJson.encode(measurementJson),
          ),
          notes: Value(exercise.metadata.notes),
          videoUrl: Value(exercise.metadata.videoUrl),
          plannedRestSeconds: Value(exercise.plannedRestSeconds),
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );

      await _reconcileExerciseSets(exercise, updatedAt);

      return _loadExercise(exercise.id);
    });
  }

  Future<void> _reconcileExerciseSets(
    domain.Exercise exercise,
    DateTime writeTime,
  ) async {
    final existingRows = await (_db.select(
      _db.workoutSets,
    )..where((t) => t.exerciseId.equals(exercise.id))).get();
    final existingById = {for (final r in existingRows) r.id: r};
    final desiredIds = exercise.sets.map((s) => s.id).toSet();

    for (final existing in existingRows) {
      if (!desiredIds.contains(existing.id)) {
        await (_db.delete(
          _db.workoutSets,
        )..where((t) => t.id.equals(existing.id))).go();
      }
    }

    final offset = exercise.sets.length + existingRows.length + 1000;

    for (var i = 0; i < exercise.sets.length; i++) {
      final set = exercise.sets[i];
      final plannedJson = set.plannedValues.toJson();
      final plannedDiscriminator = plannedJson['type'] as String;
      final plannedPayload = CanonicalJson.encode(plannedJson);
      final existing = existingById[set.id];
      final parkedPosition = offset + i;

      if (existing == null) {
        await _db
            .into(_db.workoutSets)
            .insert(
              WorkoutSetsCompanion.insert(
                id: set.id,
                exerciseId: exercise.id,
                position: parkedPosition,
                plannedValuesDiscriminator: plannedDiscriminator,
                plannedValuesPayloadJson: plannedPayload,
                createdAtMs: utcToMs(writeTime),
                updatedAtMs: utcToMs(writeTime),
                schemaVersion: SchemaVersions.domain,
              ),
            );
      } else {
        final setUpdatedAt = _timestamps.nextUpdatedAt(
          previousUpdatedAt: msToUtc(existing.updatedAtMs),
          createdAt: msToUtc(existing.createdAtMs),
        );
        await (_db.update(
          _db.workoutSets,
        )..where((t) => t.id.equals(set.id))).write(
          WorkoutSetsCompanion(
            position: Value(parkedPosition),
            plannedValuesDiscriminator: Value(plannedDiscriminator),
            plannedValuesPayloadJson: Value(plannedPayload),
            updatedAtMs: Value(utcToMs(setUpdatedAt)),
            schemaVersion: const Value(SchemaVersions.domain),
          ),
        );
      }
    }

    for (var i = 0; i < exercise.sets.length; i++) {
      await (_db.update(_db.workoutSets)
            ..where((t) => t.id.equals(exercise.sets[i].id)))
          .write(WorkoutSetsCompanion(position: Value(i)));
    }
  }

  @override
  Future<void> deleteExercise(String exerciseId) async {
    await (_db.delete(
      _db.exercises,
    )..where((t) => t.id.equals(exerciseId))).go();
  }

  @override
  Future<void> reorderExercises(
    String exerciseGroupId,
    List<String> orderedExerciseIds,
  ) async {
    await _db.transaction(() async {
      for (final exerciseId in orderedExerciseIds) {
        final existing =
            await (_db.select(_db.exercises)..where(
                  (t) =>
                      t.id.equals(exerciseId) &
                      t.exerciseGroupId.equals(exerciseGroupId),
                ))
                .getSingleOrNull();
        if (existing == null) {
          throw NotFoundError(entityType: 'Exercise', id: exerciseId);
        }
      }
      await _db.batch((b) {
        for (var i = 0; i < orderedExerciseIds.length; i++) {
          b.update(
            _db.exercises,
            ExercisesCompanion(position: Value(-(i + 1))),
            where: (t) => t.id.equals(orderedExerciseIds[i]),
          );
        }
        for (var i = 0; i < orderedExerciseIds.length; i++) {
          b.update(
            _db.exercises,
            ExercisesCompanion(position: Value(i)),
            where: (t) => t.id.equals(orderedExerciseIds[i]),
          );
        }
      });
    });
  }

  @override
  Future<domain.WorkoutSet> createSet({
    required String exerciseId,
    required PlannedSetValues plannedValues,
  }) async {
    return _db.transaction(() async {
      final exerciseRow = await (_db.select(
        _db.exercises,
      )..where((t) => t.id.equals(exerciseId))).getSingleOrNull();
      if (exerciseRow == null) {
        throw NotFoundError(entityType: 'Exercise', id: exerciseId);
      }

      final position = await _nextPositionForSets(exerciseId);

      final id = _uuid.v4();
      final now = _clock.now().toUtc();
      final plannedJson = plannedValues.toJson();
      await _db
          .into(_db.workoutSets)
          .insert(
            WorkoutSetsCompanion.insert(
              id: id,
              exerciseId: exerciseId,
              position: position,
              plannedValuesDiscriminator: plannedJson['type'] as String,
              plannedValuesPayloadJson: CanonicalJson.encode(plannedJson),
              createdAtMs: utcToMs(now),
              updatedAtMs: utcToMs(now),
              schemaVersion: SchemaVersions.domain,
            ),
          );

      return _loadSet(id);
    });
  }

  @override
  Future<domain.WorkoutSet> updateSet(domain.WorkoutSet set) async {
    return _db.transaction(() async {
      final existing = await (_db.select(
        _db.workoutSets,
      )..where((t) => t.id.equals(set.id))).getSingleOrNull();
      if (existing == null) {
        throw NotFoundError(entityType: 'WorkoutSet', id: set.id);
      }
      final updatedAt = _timestamps.nextUpdatedAt(
        previousUpdatedAt: msToUtc(existing.updatedAtMs),
        createdAt: msToUtc(existing.createdAtMs),
      );
      final plannedJson = set.plannedValues.toJson();
      await (_db.update(
        _db.workoutSets,
      )..where((t) => t.id.equals(set.id))).write(
        WorkoutSetsCompanion(
          plannedValuesDiscriminator: Value(plannedJson['type'] as String),
          plannedValuesPayloadJson: Value(CanonicalJson.encode(plannedJson)),
          updatedAtMs: Value(utcToMs(updatedAt)),
          schemaVersion: const Value(SchemaVersions.domain),
        ),
      );
      return _loadSet(set.id);
    });
  }

  @override
  Future<void> deleteSet(String setId) async {
    await (_db.delete(_db.workoutSets)..where((t) => t.id.equals(setId))).go();
  }

  @override
  Future<void> reorderSets(
    String exerciseId,
    List<String> orderedSetIds,
  ) async {
    await _db.transaction(() async {
      for (final setId in orderedSetIds) {
        final existing =
            await (_db.select(_db.workoutSets)..where(
                  (t) => t.id.equals(setId) & t.exerciseId.equals(exerciseId),
                ))
                .getSingleOrNull();
        if (existing == null) {
          throw NotFoundError(entityType: 'WorkoutSet', id: setId);
        }
      }
      await _db.batch((b) {
        for (var i = 0; i < orderedSetIds.length; i++) {
          b.update(
            _db.workoutSets,
            WorkoutSetsCompanion(position: Value(-(i + 1))),
            where: (t) => t.id.equals(orderedSetIds[i]),
          );
        }
        for (var i = 0; i < orderedSetIds.length; i++) {
          b.update(
            _db.workoutSets,
            WorkoutSetsCompanion(position: Value(i)),
            where: (t) => t.id.equals(orderedSetIds[i]),
          );
        }
      });
    });
  }

  @override
  Future<domain.Program> saveProgramAggregate(
    ProgramAggregate aggregate,
  ) async {
    return _db.transaction(() async {
      await _db
          .into(_db.programs)
          .insert(
            ProgramsCompanion.insert(
              id: aggregate.id,
              name: aggregate.name,
              createdAtMs: utcToMs(aggregate.createdAt),
              updatedAtMs: utcToMs(aggregate.updatedAt),
              schemaVersion: SchemaVersions.domain,
            ),
          );

      for (final day in aggregate.workoutDays) {
        await _db
            .into(_db.workoutDays)
            .insert(
              WorkoutDaysCompanion.insert(
                id: day.id,
                programId: day.programId,
                name: day.name,
                createdAtMs: utcToMs(aggregate.createdAt),
                updatedAtMs: utcToMs(aggregate.updatedAt),
                schemaVersion: SchemaVersions.domain,
              ),
            );

        await _db
            .into(_db.programWorkoutDays)
            .insert(
              ProgramWorkoutDaysCompanion.insert(
                programId: day.programId,
                workoutDayId: day.id,
                position: day.position,
              ),
            );

        for (final group in day.groups) {
          final kindJson = group.kind.toJson();
          await _db
              .into(_db.exerciseGroups)
              .insert(
                ExerciseGroupsCompanion.insert(
                  id: group.id,
                  workoutDayId: group.workoutDayId,
                  position: group.position,
                  kindDiscriminator: kindJson['type'] as String,
                  kindPayloadJson: CanonicalJson.encode(kindJson),
                  roleDiscriminator: Value(group.role.name),
                  createdAtMs: utcToMs(aggregate.createdAt),
                  updatedAtMs: utcToMs(aggregate.updatedAt),
                  schemaVersion: SchemaVersions.domain,
                ),
              );

          for (final exercise in group.exercises) {
            final measurementJson = exercise.measurementType.toJson();
            await _db
                .into(_db.exercises)
                .insert(
                  ExercisesCompanion.insert(
                    id: exercise.id,
                    exerciseGroupId: exercise.groupId,
                    position: exercise.position,
                    name: exercise.name,
                    measurementTypeDiscriminator:
                        measurementJson['type'] as String,
                    measurementTypePayloadJson: CanonicalJson.encode(
                      measurementJson,
                    ),
                    notes: Value(exercise.metadata.notes),
                    videoUrl: Value(exercise.metadata.videoUrl),
                    plannedRestSeconds: Value(exercise.plannedRestSeconds),
                    createdAtMs: utcToMs(aggregate.createdAt),
                    updatedAtMs: utcToMs(aggregate.updatedAt),
                    schemaVersion: SchemaVersions.domain,
                  ),
                );

            for (final set in exercise.sets) {
              final plannedJson = set.values.toJson();
              await _db
                  .into(_db.workoutSets)
                  .insert(
                    WorkoutSetsCompanion.insert(
                      id: set.id,
                      exerciseId: set.exerciseId,
                      position: set.position,
                      plannedValuesDiscriminator: plannedJson['type'] as String,
                      plannedValuesPayloadJson: CanonicalJson.encode(
                        plannedJson,
                      ),
                      createdAtMs: utcToMs(aggregate.createdAt),
                      updatedAtMs: utcToMs(aggregate.updatedAt),
                      schemaVersion: SchemaVersions.domain,
                    ),
                  );
            }
          }
        }
      }

      final program = await getProgram(aggregate.id);
      return program!;
    });
  }

  Future<List<String>> _getWorkoutDayIdsForProgram(String programId) async {
    final rows =
        await (_db.select(_db.programWorkoutDays)
              ..where((t) => t.programId.equals(programId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return rows.map((r) => r.workoutDayId).toList();
  }

  Future<int> _nextPositionForProgramWorkoutDays(String programId) async {
    final maxExpr = _db.programWorkoutDays.position.max();
    final row =
        await (_db.selectOnly(_db.programWorkoutDays)
              ..addColumns([maxExpr])
              ..where(_db.programWorkoutDays.programId.equals(programId)))
            .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> _nextPositionForExerciseGroups(String workoutDayId) async {
    final maxExpr = _db.exerciseGroups.position.max();
    final row =
        await (_db.selectOnly(_db.exerciseGroups)
              ..addColumns([maxExpr])
              ..where(_db.exerciseGroups.workoutDayId.equals(workoutDayId)))
            .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> _nextPositionForExercises(String exerciseGroupId) async {
    final maxExpr = _db.exercises.position.max();
    final row =
        await (_db.selectOnly(_db.exercises)
              ..addColumns([maxExpr])
              ..where(_db.exercises.exerciseGroupId.equals(exerciseGroupId)))
            .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<int> _nextPositionForSets(String exerciseId) async {
    final maxExpr = _db.workoutSets.position.max();
    final row =
        await (_db.selectOnly(_db.workoutSets)
              ..addColumns([maxExpr])
              ..where(_db.workoutSets.exerciseId.equals(exerciseId)))
            .getSingle();
    return (row.read(maxExpr) ?? -1) + 1;
  }

  Future<domain.WorkoutDay?> _loadWorkoutDay(String workoutDayId) async {
    final dayRow = await (_db.select(
      _db.workoutDays,
    )..where((t) => t.id.equals(workoutDayId))).getSingleOrNull();
    if (dayRow == null) return null;

    final groupRows =
        await (_db.select(_db.exerciseGroups)
              ..where((t) => t.workoutDayId.equals(workoutDayId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();

    final groupIds = groupRows.map((g) => g.id).toList();
    final exerciseRows = groupIds.isEmpty
        ? <Exercise>[]
        : await (_db.select(_db.exercises)
                ..where((t) => t.exerciseGroupId.isIn(groupIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

    final exerciseIds = exerciseRows.map((e) => e.id).toList();
    final setRows = exerciseIds.isEmpty
        ? <WorkoutSet>[]
        : await (_db.select(_db.workoutSets)
                ..where((t) => t.exerciseId.isIn(exerciseIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

    return _workoutDayMapper.toDomain(dayRow, groupRows, exerciseRows, setRows);
  }

  Future<domain.ExerciseGroup> _loadExerciseGroup(String groupId) async {
    final groupRow = await (_db.select(
      _db.exerciseGroups,
    )..where((t) => t.id.equals(groupId))).getSingle();
    final exerciseRows =
        await (_db.select(_db.exercises)
              ..where((t) => t.exerciseGroupId.equals(groupId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    final exerciseIds = exerciseRows.map((e) => e.id).toList();
    final setRows = exerciseIds.isEmpty
        ? <WorkoutSet>[]
        : await (_db.select(_db.workoutSets)
                ..where((t) => t.exerciseId.isIn(exerciseIds))
                ..orderBy([(t) => OrderingTerm.asc(t.position)]))
              .get();

    final dayRow = await (_db.select(
      _db.workoutDays,
    )..where((t) => t.id.equals(groupRow.workoutDayId))).getSingle();

    return _workoutDayMapper
        .toDomain(dayRow, [groupRow], exerciseRows, setRows)
        .exerciseGroups
        .first;
  }

  Future<domain.Exercise> _loadExercise(String exerciseId) async {
    final exerciseRow = await (_db.select(
      _db.exercises,
    )..where((t) => t.id.equals(exerciseId))).getSingle();
    final setRows =
        await (_db.select(_db.workoutSets)
              ..where((t) => t.exerciseId.equals(exerciseId))
              ..orderBy([(t) => OrderingTerm.asc(t.position)]))
            .get();
    return _workoutDayMapper.exerciseToDomain(exerciseRow, setRows);
  }

  Future<domain.WorkoutSet> _loadSet(String setId) async {
    final setRow = await (_db.select(
      _db.workoutSets,
    )..where((t) => t.id.equals(setId))).getSingle();
    return _workoutDayMapper.setToDomain(setRow);
  }
}
