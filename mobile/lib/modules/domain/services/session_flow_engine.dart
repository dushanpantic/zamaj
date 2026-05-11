import 'package:clock/clock.dart';
import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';
import 'package:zamaj/modules/domain/services/cursor.dart';
import 'package:zamaj/modules/domain/services/session_state.dart';

/// Stateless service that orchestrates workout session execution.
///
/// Every mutation round-trips through the [SessionRepository], recomputes the
/// [Cursor], and returns a fresh [SessionState] to the caller.
class SessionFlowEngine {
  SessionFlowEngine({
    required SessionRepository repository,
    required Clock clock,
  })  : _repository = repository,
        _clock = clock;

  final SessionRepository _repository;
  final Clock _clock;

  /// Starts a new session from a workout day.
  Future<SessionState> startSession({required String workoutDayId}) async {
    final session = await _repository.startSession(
      workoutDayId: workoutDayId,
    );
    return _buildState(session);
  }

  /// Resumes an existing session.
  Future<SessionState> resumeSession({required String sessionId}) async {
    final session = await _repository.getSession(sessionId);
    if (session == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }
    return _buildState(session);
  }

  /// Ends the current session.
  Future<SessionState> endSession({required String sessionId}) async {
    final session = await _repository.getSession(sessionId);
    if (session == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }
    if (session.endedAt != null) {
      throw ImmutabilityError(
        sessionId: sessionId,
        message: 'Session $sessionId has already ended',
      );
    }
    final updatedSession = await _repository.endSession(sessionId);
    return _buildState(updatedSession);
  }

  /// Skips an unfinished exercise, advancing the cursor past it.
  Future<SessionState> skipExercise({
    required String sessionExerciseId,
  }) async {
    final session = await _repository.getSessionByExerciseId(
      sessionExerciseId,
    );
    final exercise = session.sessionExercises.firstWhere(
      (SessionExercise e) => e.id == sessionExerciseId,
    );
    _assertUnfinished(exercise);
    final updatedSession =
        await _repository.skipExercise(sessionExerciseId);
    return _buildState(updatedSession);
  }

  /// Replaces an unfinished exercise with a substitute.
  Future<SessionState> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    ExerciseMetadata? substituteMetadata,
  }) async {
    final session = await _repository.getSessionByExerciseId(
      sessionExerciseId,
    );
    final exercise = session.sessionExercises.firstWhere(
      (SessionExercise e) => e.id == sessionExerciseId,
    );
    _assertUnfinished(exercise);
    final updatedSession = await _repository.replaceExercise(
      sessionExerciseId: sessionExerciseId,
      substituteName: substituteName,
      substituteMeasurementType: substituteMeasurementType,
      substituteMetadata: substituteMetadata,
    );
    return _buildState(updatedSession);
  }

  /// Reorders all unfinished exercises to the specified order.
  Future<SessionState> reorderUnfinished({
    required String sessionId,
    required List<String> orderedUnfinishedIds,
  }) async {
    final session = await _repository.getSession(sessionId);
    if (session == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }

    final unfinishedExercises = session.sessionExercises
        .where((e) => e.state is UnfinishedState)
        .toList();
    final unfinishedIds = unfinishedExercises.map((e) => e.id).toSet();

    for (final id in orderedUnfinishedIds) {
      if (!unfinishedIds.contains(id)) {
        final exercise = session.sessionExercises
            .where((e) => e.id == id)
            .firstOrNull;
        if (exercise == null) {
          throw NotFoundError(entityType: 'SessionExercise', id: id);
        }
        throw OrderingError(
          sessionExerciseId: id,
          currentState: exercise.state.runtimeType.toString(),
          message:
              'Cannot reorder exercise $id: state is ${exercise.state.runtimeType}',
        );
      }
    }

    final orderedSet = orderedUnfinishedIds.toSet();
    if (orderedSet.length != orderedUnfinishedIds.length ||
        orderedSet.length != unfinishedIds.length ||
        !orderedSet.containsAll(unfinishedIds)) {
      throw ValidationError(
        entityId: sessionId,
        invariant: 'exact_permutation',
        message:
            'orderedUnfinishedIds must be an exact permutation of all unfinished exercise IDs',
      );
    }

    final updatedSession = await _repository.reorderUnfinished(
      sessionId: sessionId,
      orderedUnfinishedIds: orderedUnfinishedIds,
    );
    return _buildState(updatedSession);
  }

  /// Computes the current cursor position for a session.
  ///
  /// Iterates exercises in position order and returns the first unfinished or
  /// replaced exercise that still has sets remaining. Returns
  /// [Cursor.completed] when all exercises are in a terminal state.
  Cursor computeCursor(Session session) {
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    for (final exercise in sorted) {
      switch (exercise.state) {
        case UnfinishedState():
          final plannedSetCount = _lookupPlannedSetCount(exercise, session);
          if (exercise.executedSets.length < plannedSetCount) {
            return Cursor.active(
              sessionExerciseId: exercise.id,
              setIndex: exercise.executedSets.length,
            );
          }
        case ReplacedState():
          final plannedSetCount = _lookupPlannedSetCount(exercise, session);
          if (exercise.executedSets.length < plannedSetCount) {
            return Cursor.active(
              sessionExerciseId: exercise.id,
              setIndex: exercise.executedSets.length,
            );
          }
        case CompletedState():
        case SkippedState():
          continue;
      }
    }

    return const Cursor.completed();
  }

  /// Suggests actual values for the current cursor position.
  ///
  /// Returns `null` when the cursor is completed. Otherwise returns values
  /// based on the last executed set (if any) or the planned values from the
  /// snapshot.
  ActualSetValues? suggestValues({
    required Session session,
    required Cursor cursor,
  }) {
    switch (cursor) {
      case CompletedCursor():
        return null;
      case ActiveCursor(:final sessionExerciseId, :final setIndex):
        final exercise = session.sessionExercises.firstWhere(
          (e) => e.id == sessionExerciseId,
          orElse: () => throw NotFoundError(
            entityType: 'SessionExercise',
            id: sessionExerciseId,
          ),
        );

        final originalExercise = _lookupPlannedExercise(exercise, session);
        final effectiveMeasurementType = switch (exercise.state) {
          ReplacedState(:final substitute) => substitute.measurementType,
          _ => originalExercise.measurementType,
        };

        if (setIndex > 0) {
          final lastSet = exercise.executedSets.last;
          return lastSet.actualValues;
        }

        if (exercise.state is ReplacedState) {
          final ReplacedState replacedState =
              exercise.state as ReplacedState;
          if (replacedState.substitute.measurementType !=
              originalExercise.measurementType) {
            return _defaultZeroValues(effectiveMeasurementType);
          }
        }

        final plannedSet = _lookupPlannedSet(exercise, session, position: 0);
        return _convertPlannedToActual(plannedSet.plannedValues);
    }
  }

  /// Adds freeform extra work to the session.
  Future<SessionState> addExtraWork({
    required String sessionId,
    required String body,
  }) async {
    if (body.trim().isEmpty) {
      throw ValidationError(
        entityId: sessionId,
        invariant: 'extra_work_body_non_empty',
        message: 'Extra work body must contain at least one non-whitespace character',
      );
    }
    final updatedSession = await _repository.addExtraWork(
      sessionId: sessionId,
      body: body,
    );
    return _buildState(updatedSession);
  }

  /// Adds a note to the session.
  Future<SessionState> addSessionNote({
    required String sessionId,
    required String body,
  }) async {
    if (body.trim().isEmpty) {
      throw ValidationError(
        entityId: sessionId,
        invariant: 'session_note_body_non_empty',
        message: 'Session note body must contain at least one non-whitespace character',
      );
    }
    if (body.length > 5000) {
      throw ValidationError(
        entityId: sessionId,
        invariant: 'session_note_body_max_length',
        message: 'Session note body exceeds 5000 characters',
      );
    }
    final updatedSession = await _repository.addSessionNote(
      sessionId: sessionId,
      body: body,
    );
    return _buildState(updatedSession);
  }

  /// Completes the current set with actual values.
  Future<SessionState> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  }) async {
    final session = await _repository.getSessionByExerciseId(
      sessionExerciseId,
    );

    if (session.endedAt != null) {
      throw ImmutabilityError(
        sessionId: session.id,
        message: 'Cannot complete set on ended session ${session.id}',
      );
    }

    final cursor = computeCursor(session);
    if (cursor is CompletedCursor) {
      throw ValidationError(
        entityId: sessionExerciseId,
        invariant: 'cursor_not_terminal',
        message: 'Cannot complete set when all exercises are done',
      );
    }

    final exercise = session.sessionExercises.firstWhere(
      (e) => e.id == sessionExerciseId,
      orElse: () => throw NotFoundError(
        entityType: 'SessionExercise',
        id: sessionExerciseId,
      ),
    );

    final effectiveMeasurementType = _effectiveMeasurementType(
      exercise,
      session,
    );
    _validateMeasurementTypeMatch(
      actualValues: actualValues,
      measurementType: effectiveMeasurementType,
      entityId: sessionExerciseId,
    );

    final updatedSession = await _repository.completeSet(
      sessionExerciseId: sessionExerciseId,
      actualValues: actualValues,
      plannedSetIdInSnapshot: plannedSetIdInSnapshot,
    );

    return _buildState(updatedSession);
  }

  /// Edits a previously completed set's values.
  Future<SessionState> updateExecutedSet({
    required String executedSetId,
    required ActualSetValues actualValues,
  }) async {
    final session = await _repository.getSessionByExecutedSetId(executedSetId);

    final exercise = session.sessionExercises.firstWhere(
      (e) => e.executedSets.any((s) => s.id == executedSetId),
      orElse: () => throw NotFoundError(
        entityType: 'ExecutedSet',
        id: executedSetId,
      ),
    );

    final effectiveMeasurementType = _effectiveMeasurementType(
      exercise,
      session,
    );
    _validateMeasurementTypeMatch(
      actualValues: actualValues,
      measurementType: effectiveMeasurementType,
      entityId: executedSetId,
    );

    final updatedSession = await _repository.updateExecutedSet(
      executedSetId: executedSetId,
      actualValues: actualValues,
    );

    return _buildState(updatedSession);
  }

  /// Groups unfinished exercises into a superset.
  Future<SessionState> createSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) async {
    if (sessionExerciseIds.length < 2) {
      throw ValidationError(
        entityId: sessionId,
        invariant: 'superset_min_exercises',
        message: 'A superset requires at least 2 exercises',
      );
    }

    final session = await _repository.getSession(sessionId);
    if (session == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }

    for (final id in sessionExerciseIds) {
      final exercise = session.sessionExercises.firstWhere(
        (e) => e.id == id,
        orElse: () =>
            throw NotFoundError(entityType: 'SessionExercise', id: id),
      );
      if (exercise.state is! UnfinishedState) {
        throw OrderingError(
          sessionExerciseId: id,
          currentState: exercise.state.runtimeType.toString(),
          message:
              'Cannot add exercise $id to superset: state is ${exercise.state.runtimeType}',
        );
      }
    }

    final updatedSession = await _repository.createSuperset(
      sessionId: sessionId,
      sessionExerciseIds: sessionExerciseIds,
    );
    return _buildState(updatedSession);
  }

  /// Removes superset grouping from exercises.
  Future<SessionState> removeSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  }) async {
    final session = await _repository.getSession(sessionId);
    if (session == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }

    String? sharedTag;
    for (final id in sessionExerciseIds) {
      final exercise = session.sessionExercises.firstWhere(
        (e) => e.id == id,
        orElse: () =>
            throw NotFoundError(entityType: 'SessionExercise', id: id),
      );
      if (exercise.state is! UnfinishedState) {
        throw OrderingError(
          sessionExerciseId: id,
          currentState: exercise.state.runtimeType.toString(),
          message:
              'Cannot remove exercise $id from superset: state is ${exercise.state.runtimeType}',
        );
      }
      if (exercise.supersetTag == null) {
        throw ValidationError(
          entityId: id,
          invariant: 'superset_tag_required',
          message:
              'Exercise $id does not belong to a superset (supersetTag is null)',
        );
      }
      if (sharedTag == null) {
        sharedTag = exercise.supersetTag;
      } else if (exercise.supersetTag != sharedTag) {
        throw ValidationError(
          entityId: id,
          invariant: 'superset_same_group',
          message:
              'Exercise $id has supersetTag ${exercise.supersetTag} but expected $sharedTag',
        );
      }
    }

    final updatedSession = await _repository.removeSuperset(
      sessionId: sessionId,
      sessionExerciseIds: sessionExerciseIds,
    );
    return _buildState(updatedSession);
  }

  /// Returns `true` when every exercise is in a terminal state with all
  /// planned sets fulfilled.
  bool isSessionComplete(Session session) {
    for (final exercise in session.sessionExercises) {
      switch (exercise.state) {
        case CompletedState():
        case SkippedState():
          continue;
        case ReplacedState():
          final plannedSetCount = _lookupPlannedSetCount(exercise, session);
          if (exercise.executedSets.length < plannedSetCount) {
            return false;
          }
        case UnfinishedState():
          return false;
      }
    }
    return true;
  }

  SessionState _buildState(Session session) {
    final cursor = computeCursor(session);
    final suggestedValues = suggestValues(session: session, cursor: cursor);
    return SessionState(
      session: session,
      cursor: cursor,
      suggestedValues: suggestedValues,
    );
  }

  Exercise _lookupPlannedExercise(
    SessionExercise sessionExercise,
    Session session,
  ) {
    final workoutDay = session.snapshot.workoutDay;
    for (final group in workoutDay.exerciseGroups) {
      for (final exercise in group.exercises) {
        if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
          return exercise;
        }
      }
    }
    throw NotFoundError(
      entityType: 'Exercise',
      id: sessionExercise.plannedExerciseIdInSnapshot,
    );
  }

  int _lookupPlannedSetCount(
    SessionExercise sessionExercise,
    Session session,
  ) {
    final exercise = _lookupPlannedExercise(sessionExercise, session);
    return exercise.sets.length;
  }

  WorkoutSet _lookupPlannedSet(
    SessionExercise sessionExercise,
    Session session, {
    required int position,
  }) {
    final exercise = _lookupPlannedExercise(sessionExercise, session);
    final sorted = List<WorkoutSet>.of(exercise.sets)
      ..sort((a, b) => a.position.compareTo(b.position));
    if (position >= sorted.length) {
      throw NotFoundError(
        entityType: 'WorkoutSet',
        id: '${exercise.id}[position=$position]',
      );
    }
    return sorted[position];
  }

  ActualSetValues _convertPlannedToActual(PlannedSetValues planned) {
    return switch (planned) {
      PlannedRepBased(:final weightKg, :final reps) =>
        ActualSetValues.repBased(weightKg: weightKg, reps: reps),
      PlannedTimeBased(:final durationSeconds) =>
        ActualSetValues.timeBased(durationSeconds: durationSeconds),
    };
  }

  ActualSetValues _defaultZeroValues(MeasurementType measurementType) {
    return switch (measurementType) {
      RepBasedMeasurement() =>
        const ActualSetValues.repBased(weightKg: 0, reps: 0),
      TimeBasedMeasurement() =>
        const ActualSetValues.timeBased(durationSeconds: 0),
    };
  }

  MeasurementType _effectiveMeasurementType(
    SessionExercise exercise,
    Session session,
  ) {
    return switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.measurementType,
      _ => _lookupPlannedExercise(exercise, session).measurementType,
    };
  }

  void _validateMeasurementTypeMatch({
    required ActualSetValues actualValues,
    required MeasurementType measurementType,
    required String entityId,
  }) {
    final isValid = switch ((measurementType, actualValues)) {
      (RepBasedMeasurement(), ActualRepBased()) => true,
      (TimeBasedMeasurement(), ActualTimeBased()) => true,
      _ => false,
    };
    if (!isValid) {
      throw ValidationError(
        entityId: entityId,
        invariant: 'measurementType_actualValues_mismatch',
        message:
            'ActualSetValues variant does not match exercise measurementType',
      );
    }
  }

  void _assertUnfinished(SessionExercise exercise) {
    if (exercise.state is! UnfinishedState) {
      throw OrderingError(
        sessionExerciseId: exercise.id,
        currentState: exercise.state.runtimeType.toString(),
        message:
            'Exercise ${exercise.id} must be unfinished but is ${exercise.state.runtimeType}',
      );
    }
  }
}
