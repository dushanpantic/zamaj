import 'dart:async';

import 'package:clock/clock.dart';
import 'package:uuid/uuid.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise_group_kind.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/extra_work.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
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
  final StreamController<String> _changeController =
      StreamController<String>.broadcast(sync: true);

  void seedWorkoutDay(WorkoutDay workoutDay) {
    _workoutDays[workoutDay.id] = workoutDay;
  }

  void seedSession(Session session) {
    _sessions[session.id] = session;
    _changeController.add(session.id);
  }

  void _notify(String sessionId) {
    if (!_changeController.isClosed) _changeController.add(sessionId);
  }

  /// Closes the internal change broadcaster. Optional — tests can call this
  /// in tearDown when they want strict resource hygiene.
  Future<void> dispose() => _changeController.close();

  @override
  Stream<Session?> watchSession(String sessionId) async* {
    yield _sessions[sessionId];
    yield* _changeController.stream
        .where((id) => id == sessionId)
        .map((_) => _sessions[sessionId]);
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
      final supersetTag = group.kind is SupersetKind ? group.id : null;
      for (final exercise in group.exercises) {
        exercises.add(
          SessionExercise(
            id: _uuid.v4(),
            sessionId: sessionId,
            position: position++,
            plannedExerciseIdInSnapshot: exercise.id,
            state: const ExerciseState.unfinished(),
            executedSets: const [],
            supersetTag: supersetTag,
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
    _notify(sessionId);
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
  Future<Session?> getActiveSession() async {
    final active = _sessions.values.where((s) => s.endedAt == null).toList()
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return active.isEmpty ? null : active.first;
  }

  @override
  Stream<Session?> watchActiveSession() async* {
    yield await getActiveSession();
    yield* _changeController.stream.asyncMap((_) => getActiveSession());
  }

  @override
  Future<Session> endSession(String sessionId) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();
    final updated = session.copyWith(endedAt: now, updatedAt: now);
    _sessions[sessionId] = updated;
    _notify(sessionId);
    return updated;
  }

  @override
  Future<void> deleteSession(String sessionId) async {
    _requireSession(sessionId);
    _sessions.remove(sessionId);
    _notify(sessionId);
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
      // Match DriftSessionRepository: only auto-transition unfinished →
      // completed. Replaced exercises stay replaced even when overlogged.
      final newState =
          exercise.state is UnfinishedState && newSets.length >= plannedSetCount
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
    _notify(session.id);
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
    _notify(session.id);
    return updated;
  }

  @override
  Future<Session> deleteExecutedSet({required String executedSetId}) async {
    final session = await getSessionByExecutedSetId(executedSetId);
    final now = clock.now().toUtc();

    final updatedExercises = session.sessionExercises.map((exercise) {
      final setIndex = exercise.executedSets.indexWhere(
        (s) => s.id == executedSetId,
      );
      if (setIndex == -1) return exercise;

      final newSets = List<ExecutedSet>.of(exercise.executedSets)
        ..removeAt(setIndex);
      final plannedSetCount = _lookupPlannedSetCount(exercise, session);
      final wasCompleted = exercise.state is CompletedState;
      final newState = wasCompleted && newSets.length < plannedSetCount
          ? const ExerciseState.unfinished()
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
    _notify(session.id);
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
    _notify(session.id);
    return updated;
  }

  @override
  Future<Session> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    required PlannedSetValues substitutePlannedValues,
    required int substituteSetCount,
    ExerciseMetadata? substituteMetadata,
    String? substituteLibraryExerciseId,
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
            plannedValues: substitutePlannedValues,
            setCount: substituteSetCount,
            metadata: substituteMetadata,
            libraryExerciseId: substituteLibraryExerciseId,
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
    _notify(session.id);
    return updated;
  }

  @override
  Future<Session> reorderUnfinished({
    required String sessionId,
    required List<String> orderedUnfinishedIds,
  }) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();

    final exerciseById = {for (final e in session.sessionExercises) e.id: e};

    for (final id in orderedUnfinishedIds) {
      final exercise = exerciseById[id];
      if (exercise == null) {
        throw NotFoundError(entityType: 'SessionExercise', id: id);
      }
      if (exercise.state is! UnfinishedState) {
        throw OrderingError(
          sessionExerciseId: id,
          currentState: exercise.state.discriminator,
          message:
              'SessionExercise $id is in state ${exercise.state.discriminator}, not unfinished',
        );
      }
    }

    // Permute among the provided unfinished ids' existing position slots.
    // Locked exercises and any unfinished exercise not in the input are
    // unaffected.
    final slots =
        orderedUnfinishedIds.map((id) => exerciseById[id]!.position).toList()
          ..sort();
    final newPositionById = <String, int>{
      for (var i = 0; i < orderedUnfinishedIds.length; i++)
        orderedUnfinishedIds[i]: slots[i],
    };

    final updatedExercises = session.sessionExercises.map((e) {
      final newPos = newPositionById[e.id];
      if (newPos == null || newPos == e.position) return e;
      return e.copyWith(position: newPos, updatedAt: now);
    }).toList();

    final updated = session.copyWith(
      sessionExercises: updatedExercises,
      updatedAt: now,
    );
    _sessions[sessionId] = updated;
    _notify(sessionId);
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

    // Pull the chosen members into one contiguous block anchored at the
    // earliest chosen member's slot, ordered as provided; every other
    // exercise keeps its relative order. Mirrors
    // DriftSessionRepository.createSuperset so the fake and production agree
    // on the post-create ordering — the assembler groups a superset only from
    // a contiguous run of same-tag rows.
    final chosen = sessionExerciseIds.toSet();
    final orderedIds =
        ([...session.sessionExercises]
              ..sort((a, b) => a.position.compareTo(b.position)))
            .map((e) => e.id)
            .toList();
    final anchorIndex = orderedIds.indexWhere(chosen.contains);
    final remaining = orderedIds.where((id) => !chosen.contains(id)).toList();
    final newOrder = <String>[
      ...remaining.take(anchorIndex),
      ...sessionExerciseIds,
      ...remaining.skip(anchorIndex),
    ];

    final byId = {for (final e in session.sessionExercises) e.id: e};
    final result = <SessionExercise>[];
    for (var i = 0; i < newOrder.length; i++) {
      final exercise = byId[newOrder[i]]!;
      if (chosen.contains(exercise.id)) {
        result.add(
          exercise.copyWith(supersetTag: tag, position: i, updatedAt: now),
        );
      } else if (exercise.position != i) {
        result.add(exercise.copyWith(position: i, updatedAt: now));
      } else {
        result.add(exercise);
      }
    }

    final updated = session.copyWith(sessionExercises: result, updatedAt: now);
    _sessions[sessionId] = updated;
    _notify(sessionId);
    return updated;
  }

  @override
  Future<Session> addToSuperset({
    required String sessionId,
    required String supersetTag,
    required String sessionExerciseId,
  }) async {
    final session = _requireSession(sessionId);
    final now = clock.now().toUtc();

    final members = session.sessionExercises
        .where((e) => e.supersetTag == supersetTag)
        .toList();
    if (members.isEmpty) {
      throw NotFoundError(entityType: 'Superset', id: supersetTag);
    }
    for (final m in members) {
      if (m.state is! UnfinishedState) {
        throw OrderingError(
          sessionExerciseId: m.id,
          currentState: m.state.discriminator,
          message:
              'Cannot append to superset $supersetTag: member ${m.id} is '
              '${m.state.discriminator}, not unfinished',
        );
      }
    }
    final dragged = session.sessionExercises.firstWhere(
      (e) => e.id == sessionExerciseId,
      orElse: () => throw NotFoundError(
        entityType: 'SessionExercise',
        id: sessionExerciseId,
      ),
    );
    if (dragged.state is! UnfinishedState) {
      throw OrderingError(
        sessionExerciseId: sessionExerciseId,
        currentState: dragged.state.discriminator,
        message:
            'Cannot append exercise $sessionExerciseId to superset: state '
            'is ${dragged.state.discriminator}',
      );
    }
    if (dragged.supersetTag != null) {
      throw ValidationError(
        entityId: sessionExerciseId,
        invariant: 'append_to_superset_dragged_already_grouped',
        message:
            'Exercise $sessionExerciseId is already in superset '
            '${dragged.supersetTag}',
      );
    }

    final unfinishedSorted =
        session.sessionExercises
            .where((e) => e.state is UnfinishedState)
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    final unfinishedIds = unfinishedSorted.map((e) => e.id).toList()
      ..remove(sessionExerciseId);
    final insertAfter = unfinishedIds.indexOf(members.last.id);
    unfinishedIds.insert(insertAfter + 1, sessionExerciseId);

    final slots = unfinishedSorted.map((e) => e.position).toList()..sort();
    final newPositionById = <String, int>{
      for (var i = 0; i < unfinishedIds.length; i++) unfinishedIds[i]: slots[i],
    };

    final updatedExercises = session.sessionExercises.map((e) {
      final newPos = newPositionById[e.id];
      if (e.id == sessionExerciseId) {
        return e.copyWith(
          supersetTag: supersetTag,
          position: newPos ?? e.position,
          updatedAt: now,
        );
      }
      if (newPos != null && newPos != e.position) {
        return e.copyWith(position: newPos, updatedAt: now);
      }
      return e;
    }).toList();

    final updated = session.copyWith(
      sessionExercises: updatedExercises,
      updatedAt: now,
    );
    _sessions[sessionId] = updated;
    _notify(sessionId);
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
    _notify(sessionId);
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
    _notify(sessionId);
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
    _notify(sessionId);
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
      ActualBodyweight() => const MeasurementType.bodyweight(),
    };
  }
}
