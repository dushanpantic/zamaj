import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/session_note.dart';
import 'package:zamaj/modules/domain/models/session_snapshot.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';

class FakeSessionRepository implements SessionRepository {
  FakeSessionRepository({required this.clock, Uuid? uuid})
    : _uuid = uuid ?? const Uuid();

  final Clock clock;
  final Uuid _uuid;
  final Map<String, Session> _sessions = {};
  final Map<String, WorkoutDay> _workoutDays = {};

  void seedWorkoutDay(WorkoutDay workoutDay) {
    _workoutDays[workoutDay.id] = workoutDay;
  }

  void seedSession(Session session) {
    _sessions[session.id] = session;
  }

  @override
  Future<Session> startSession({required String workoutDayId}) async {
    final workoutDay = _workoutDays[workoutDayId];
    if (workoutDay == null) {
      throw NotFoundError(entityType: 'WorkoutDay', id: workoutDayId);
    }

    final now = clock.now().toUtc();
    final snapshot = SessionSnapshot.capture(
      workoutDay: workoutDay,
      capturedAt: now,
      schemaVersion: 1,
    );

    final sessionId = _uuid.v4();
    var position = 0;
    final exercises = <SessionExercise>[];
    for (final group in workoutDay.exerciseGroups) {
      for (final exercise in group.exercises) {
        exercises.add(
          SessionExercise(
            id: _uuid.v4(),
            sessionId: sessionId,
            position: position++,
            plannedExerciseIdInSnapshot: exercise.id,
            state: const ExerciseState.unfinished(),
            executedSets: const [],
            createdAt: now,
            updatedAt: now,
            schemaVersion: 1,
          ),
        );
      }
    }

    final session = Session(
      id: sessionId,
      workoutDayId: workoutDayId,
      snapshot: snapshot,
      sessionExercises: exercises,
      notes: const [],
      extraWork: const [],
      startedAt: now,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );

    _sessions[sessionId] = session;
    return session;
  }

  @override
  Future<Session?> getSession(String sessionId) async {
    return _sessions[sessionId];
  }

  @override
  Future<Session> getSessionByExerciseId(String sessionExerciseId) async {
    for (final session in _sessions.values) {
      if (session.sessionExercises.any((e) => e.id == sessionExerciseId)) {
        return session;
      }
    }
    throw NotFoundError(entityType: 'SessionExercise', id: sessionExerciseId);
  }

  @override
  Future<Session> getSessionByExecutedSetId(String executedSetId) async {
    for (final session in _sessions.values) {
      for (final exercise in session.sessionExercises) {
        if (exercise.executedSets.any((s) => s.id == executedSetId)) {
          return session;
        }
      }
    }
    throw NotFoundError(entityType: 'ExecutedSet', id: executedSetId);
  }

  @override
  Future<List<Session>> listSessionsForWorkoutDay(String workoutDayId) async {
    return _sessions.values
        .where((s) => s.workoutDayId == workoutDayId)
        .toList();
  }

  @override
  Future<Session> endSession(String sessionId) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();
    final updated = session.copyWith(endedAt: now, updatedAt: now);
    _sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<Session> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  }) async {
    final session = await getSessionByExerciseId(sessionExerciseId);
    final now = clock.now().toUtc();

    final updatedExercises = session.sessionExercises.map((exercise) {
      if (exercise.id != sessionExerciseId) return exercise;

      final newSet = ExecutedSet(
        id: _uuid.v4(),
        sessionExerciseId: sessionExerciseId,
        position: exercise.executedSets.length,
        measurementType: _measurementTypeFromActual(actualValues),
        actualValues: actualValues,
        plannedSetIdInSnapshot: plannedSetIdInSnapshot,
        completedAt: now,
        createdAt: now,
        updatedAt: now,
        schemaVersion: 1,
      );

      final newSets = [...exercise.executedSets, newSet];
      final plannedSetCount = _lookupPlannedSetCount(exercise, session);
      final newState = newSets.length >= plannedSetCount
          ? const ExerciseState.completed()
          : exercise.state;

      return exercise.copyWith(
        executedSets: newSets,
        state: newState,
        updatedAt: now,
      );
    }).toList();

    final updated = session.copyWith(
      sessionExercises: updatedExercises,
      updatedAt: now,
    );
    _sessions[session.id] = updated;
    return updated;
  }

  @override
  Future<Session> updateExecutedSet({
    required String executedSetId,
    required ActualSetValues actualValues,
  }) async {
    final session = await getSessionByExecutedSetId(executedSetId);
    final now = clock.now().toUtc();

    final updatedExercises = session.sessionExercises.map((exercise) {
      final setIndex = exercise.executedSets.indexWhere(
        (s) => s.id == executedSetId,
      );
      if (setIndex == -1) return exercise;

      final oldSet = exercise.executedSets[setIndex];
      final updatedSet = oldSet.copyWith(
        actualValues: actualValues,
        measurementType: _measurementTypeFromActual(actualValues),
        updatedAt: now,
      );
      final newSets = List<ExecutedSet>.of(exercise.executedSets);
      newSets[setIndex] = updatedSet;

      return exercise.copyWith(executedSets: newSets, updatedAt: now);
    }).toList();

    final updated = session.copyWith(
      sessionExercises: updatedExercises,
      updatedAt: now,
    );
    _sessions[session.id] = updated;
    return updated;
  }

  @override
  Future<Session> skipExercise(String sessionExerciseId) async {
    final session = await getSessionByExerciseId(sessionExerciseId);
    final now = clock.now().toUtc();

    final updatedExercises = session.sessionExercises.map((exercise) {
      if (exercise.id != sessionExerciseId) return exercise;
      return exercise.copyWith(
        state: const ExerciseState.skipped(),
        updatedAt: now,
      );
    }).toList();

    final updated = session.copyWith(
      sessionExercises: updatedExercises,
      updatedAt: now,
    );
    _sessions[session.id] = updated;
    return updated;
  }

  @override
  Future<Session> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    ExerciseMetadata? substituteMetadata,
  }) async {
    final session = await getSessionByExerciseId(sessionExerciseId);
    final now = clock.now().toUtc();

    final updatedExercises = session.sessionExercises.map((exercise) {
      if (exercise.id != sessionExerciseId) return exercise;
      return exercise.copyWith(
        state: ExerciseState.replaced(
          substitute: SubstituteExercise(
            name: substituteName,
            measurementType: substituteMeasurementType,
            metadata: substituteMetadata,
          ),
        ),
        updatedAt: now,
      );
    }).toList();

    final updated = session.copyWith(
      sessionExercises: updatedExercises,
      updatedAt: now,
    );
    _sessions[session.id] = updated;
    return updated;
  }

  @override
  Future<Session> reorderUnfinished({
    required String sessionId,
    required List<String> orderedUnfinishedIds,
  }) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();

    final lockedExercises =
        session.sessionExercises
            .where((e) => e.state is! UnfinishedState)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    final unfinishedById = {
      for (final e in session.sessionExercises)
        if (e.state is UnfinishedState) e.id: e,
    };

    final reordered = <SessionExercise>[];
    var position = 0;

    for (final locked in lockedExercises) {
      reordered.add(locked.copyWith(position: position++));
    }

    for (final id in orderedUnfinishedIds) {
      final exercise = unfinishedById[id]!;
      reordered.add(exercise.copyWith(position: position++, updatedAt: now));
    }

    final updated = session.copyWith(
      sessionExercises: reordered,
      updatedAt: now,
    );
    _sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<Session> createSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();
    final tag = _uuid.v4();

    final supersetIdSet = sessionExerciseIds.toSet();
    final nonSuperset =
        session.sessionExercises
            .where((e) => !supersetIdSet.contains(e.id))
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));

    var position = 0;
    final result = <SessionExercise>[];

    for (final e in nonSuperset) {
      result.add(e.copyWith(position: position++));
    }

    for (final id in sessionExerciseIds) {
      final exercise = session.sessionExercises.firstWhere((e) => e.id == id);
      result.add(
        exercise.copyWith(
          supersetTag: tag,
          position: position++,
          updatedAt: now,
        ),
      );
    }

    final updated = session.copyWith(sessionExercises: result, updatedAt: now);
    _sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<Session> removeSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();

    final updatedExercises = session.sessionExercises.map((exercise) {
      if (sessionExerciseIds.contains(exercise.id)) {
        return exercise.copyWith(supersetTag: null, updatedAt: now);
      }
      return exercise;
    }).toList();

    final updated = session.copyWith(
      sessionExercises: updatedExercises,
      updatedAt: now,
    );
    _sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<Session> addSessionNote({
    required String sessionId,
    required String body,
  }) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();

    final note = SessionNote(
      id: _uuid.v4(),
      sessionId: sessionId,
      body: body,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );

    final updated = session.copyWith(
      notes: [...session.notes, note],
      updatedAt: now,
    );
    _sessions[sessionId] = updated;
    return updated;
  }

  @override
  Future<Session> addExtraWork({
    required String sessionId,
    required String body,
  }) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();

    final entry = ExtraWork(
      id: _uuid.v4(),
      sessionId: sessionId,
      position: session.extraWork.length,
      body: body,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );

    final updated = session.copyWith(
      extraWork: [...session.extraWork, entry],
      updatedAt: now,
    );
    _sessions[sessionId] = updated;
    return updated;
  }

  Session _requireSession(String sessionId) {
    final session = _sessions[sessionId];
    if (session == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }
    return session;
  }

  int _lookupPlannedSetCount(SessionExercise exercise, Session session) {
    final workoutDay = session.snapshot.workoutDay;
    for (final group in workoutDay.exerciseGroups) {
      for (final ex in group.exercises) {
        if (ex.id == exercise.plannedExerciseIdInSnapshot) {
          return ex.sets.length;
        }
      }
    }
    return 0;
  }

  MeasurementType _measurementTypeFromActual(ActualSetValues values) {
    return switch (values) {
      ActualRepBased() => const MeasurementType.repBased(),
      ActualTimeBased() => const MeasurementType.timeBased(),
    };
  }
}
