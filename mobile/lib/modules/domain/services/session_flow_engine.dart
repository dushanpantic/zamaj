import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/repositories/session_repository.dart';
import 'package:zamaj/modules/domain/services/log_target.dart';
import 'package:zamaj/modules/domain/services/session_state.dart';

/// Stateless service that orchestrates workout session execution.
///
/// Every mutation round-trips through the [SessionRepository], recomputes the
/// per-exercise [LogTarget] projection, and returns a fresh [SessionState] to
/// the caller.
class SessionFlowEngine {
  SessionFlowEngine({required SessionRepository repository})
    : _repository = repository;

  final SessionRepository _repository;

  /// Starts a new session from a workout day.
  Future<SessionState> startSession({required String workoutDayId}) async {
    final session = await _repository.startSession(workoutDayId: workoutDayId);
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

  /// Reactive read of a session as a fully-assembled [SessionState].
  ///
  /// Emits the current value immediately and re-emits whenever the underlying
  /// session changes — regardless of whether the change originated from this
  /// caller or another collaborator (e.g. a second screen pushed on top of
  /// the same session). Emits `null` when the session does not exist.
  Stream<SessionState?> watchSession({required String sessionId}) {
    return _repository
        .watchSession(sessionId)
        .map((session) => session == null ? null : _buildState(session));
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

  /// Skips an unfinished exercise.
  Future<SessionState> skipExercise({required String sessionExerciseId}) async {
    final session = await _repository.getSessionByExerciseId(sessionExerciseId);
    final exercise = session.sessionExercises.firstWhere(
      (SessionExercise e) => e.id == sessionExerciseId,
    );
    _assertUnfinished(exercise);
    final updatedSession = await _repository.skipExercise(sessionExerciseId);
    return _buildState(updatedSession);
  }

  /// Locks an `unfinished` exercise into `completed` even when fewer than
  /// the planned number of sets have been logged. Sets already logged
  /// remain attached. Mirrors [skipExercise] semantically (terminal state)
  /// but preserves the executed work.
  Future<SessionState> markExerciseDone({
    required String sessionExerciseId,
  }) async {
    final session = await _repository.getSessionByExerciseId(sessionExerciseId);
    final exercise = session.sessionExercises.firstWhere(
      (SessionExercise e) => e.id == sessionExerciseId,
    );
    _assertUnfinished(exercise);
    final updatedSession = await _repository.markExerciseDone(
      sessionExerciseId: sessionExerciseId,
    );
    return _buildState(updatedSession);
  }

  /// Replaces an unfinished exercise with a substitute.
  Future<SessionState> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    required PlannedSetValues substitutePlannedValues,
    required int substituteSetCount,
    ExerciseMetadata? substituteMetadata,
    String? substituteLibraryExerciseId,
  }) async {
    final session = await _repository.getSessionByExerciseId(sessionExerciseId);
    final exercise = session.sessionExercises.firstWhere(
      (SessionExercise e) => e.id == sessionExerciseId,
    );
    _assertUnfinished(exercise);
    final updatedSession = await _repository.replaceExercise(
      sessionExerciseId: sessionExerciseId,
      substituteName: substituteName,
      substituteMeasurementType: substituteMeasurementType,
      substitutePlannedValues: substitutePlannedValues,
      substituteSetCount: substituteSetCount,
      substituteMetadata: substituteMetadata,
      substituteLibraryExerciseId: substituteLibraryExerciseId,
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
          currentState: exercise.state.discriminator,
          message:
              'Cannot reorder exercise $id: state is ${exercise.state.discriminator}',
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

  /// Computes the list of currently-loggable [LogTarget]s for a session.
  ///
  /// One target per exercise in `unfinished` or `replaced` state whose
  /// `executedSets.length < plannedSetCount`, sorted by exercise position.
  /// Each target's `plannedSetIndex == exercise.executedSets.length`, i.e. the
  /// next chronological slot for that exercise. Returns an empty list when no
  /// exercise can be logged to.
  ///
  /// Exercises in `completed` state are NOT returned: appending an "extra set"
  /// to a completed exercise is allowed by [completeSet] but is an explicit
  /// UI-driven affordance, not a default suggestion.
  List<LogTarget> computeOpenTargets(Session session) {
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    final targets = <LogTarget>[];
    for (final exercise in sorted) {
      switch (exercise.state) {
        case UnfinishedState():
        case ReplacedState():
          final plannedSetCount = _lookupPlannedSetCount(exercise, session);
          if (exercise.executedSets.length < plannedSetCount) {
            targets.add(
              LogTarget(
                sessionExerciseId: exercise.id,
                plannedSetIndex: exercise.executedSets.length,
              ),
            );
          }
        case CompletedState():
        case SkippedState():
          continue;
      }
    }
    return targets;
  }

  /// Suggests actual values for the next set on [sessionExerciseId].
  ///
  /// Returns the last executed set's actual values when at least one set
  /// exists; otherwise returns the planned values converted to an
  /// [ActualSetValues] (ranges seed with the upper bound). Throws
  /// [NotFoundError] when the exercise id is unknown.
  ActualSetValues suggestValuesFor({
    required Session session,
    required String sessionExerciseId,
  }) {
    final exercise = session.sessionExercises.firstWhere(
      (e) => e.id == sessionExerciseId,
      orElse: () => throw NotFoundError(
        entityType: 'SessionExercise',
        id: sessionExerciseId,
      ),
    );

    if (exercise.executedSets.isNotEmpty) {
      return exercise.executedSets.last.actualValues;
    }

    final plannedValues = _lookupPlannedValuesAtPosition(
      exercise,
      session,
      position: 0,
    );
    return _convertPlannedToActual(plannedValues);
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
        message:
            'Extra work body must contain at least one non-whitespace character',
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
        message:
            'Session note body must contain at least one non-whitespace character',
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

  /// Completes a set on [sessionExerciseId] with [actualValues].
  ///
  /// Loggable states are `unfinished`, `replaced`, and `completed` (the last
  /// covers the "extra set on a finished exercise" affordance). Logging on a
  /// `skipped` exercise throws [OrderingError]. Cross-exercise ordering is
  /// unrestricted — the caller picks which loggable exercise to append to.
  Future<SessionState> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  }) async {
    final session = await _repository.getSessionByExerciseId(sessionExerciseId);

    if (session.endedAt != null) {
      throw ImmutabilityError(
        sessionId: session.id,
        message: 'Cannot complete set on ended session ${session.id}',
      );
    }

    final exercise = session.sessionExercises.firstWhere(
      (e) => e.id == sessionExerciseId,
      orElse: () => throw NotFoundError(
        entityType: 'SessionExercise',
        id: sessionExerciseId,
      ),
    );

    if (exercise.state is SkippedState) {
      throw OrderingError(
        sessionExerciseId: sessionExerciseId,
        currentState: exercise.state.discriminator,
        message: 'Cannot complete set on skipped exercise $sessionExerciseId',
      );
    }

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
      orElse: () =>
          throw NotFoundError(entityType: 'ExecutedSet', id: executedSetId),
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

  /// Deletes a previously completed set, reverting exercise state to
  /// `unfinished` if the deletion drops the executed-set count below the
  /// planned count.
  Future<SessionState> deleteExecutedSet({
    required String executedSetId,
  }) async {
    final session = await _repository.getSessionByExecutedSetId(executedSetId);
    if (session.endedAt != null) {
      throw ImmutabilityError(
        sessionId: session.id,
        message: 'Cannot delete executed set on ended session ${session.id}',
      );
    }
    final updatedSession = await _repository.deleteExecutedSet(
      executedSetId: executedSetId,
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
          currentState: exercise.state.discriminator,
          message:
              'Cannot add exercise $id to superset: state is ${exercise.state.discriminator}',
        );
      }
    }

    final updatedSession = await _repository.createSuperset(
      sessionId: sessionId,
      sessionExerciseIds: sessionExerciseIds,
    );
    return _buildState(updatedSession);
  }

  /// Appends an unfinished, ungrouped exercise to an existing superset.
  ///
  /// The existing tag is preserved (never rotated). The new exercise is
  /// re-positioned to sit immediately after the last current member of the
  /// group so the assembler's contiguous-run detection still works. All
  /// validation runs in the engine; the repository performs the row updates
  /// in a single transaction.
  ///
  /// Preconditions:
  /// - Every existing member of [supersetTag] is in `UnfinishedState`. Refuse
  ///   if any member is Completed/Skipped/Replaced — mixing terminal and
  ///   live members in one group is the unsafe state the workflow avoids.
  /// - The exercise at [sessionExerciseId] exists, is in `UnfinishedState`,
  ///   and currently has `supersetTag == null`.
  Future<SessionState> addToSuperset({
    required String sessionId,
    required String supersetTag,
    required String sessionExerciseId,
  }) async {
    final session = await _repository.getSession(sessionId);
    if (session == null) {
      throw NotFoundError(entityType: 'Session', id: sessionId);
    }

    final existingMembers = session.sessionExercises
        .where((e) => e.supersetTag == supersetTag)
        .toList();
    if (existingMembers.isEmpty) {
      throw NotFoundError(entityType: 'Superset', id: supersetTag);
    }
    for (final member in existingMembers) {
      if (member.state is! UnfinishedState) {
        throw OrderingError(
          sessionExerciseId: member.id,
          currentState: member.state.discriminator,
          message:
              'Cannot append to superset $supersetTag: member ${member.id} is '
              '${member.state.discriminator}, not unfinished',
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
            'Cannot append exercise $sessionExerciseId to superset: state is '
            '${dragged.state.discriminator}',
      );
    }
    if (dragged.supersetTag != null) {
      throw ValidationError(
        entityId: sessionExerciseId,
        invariant: 'append_to_superset_dragged_already_grouped',
        message:
            'Exercise $sessionExerciseId is already in superset '
            '${dragged.supersetTag}; remove it before appending elsewhere',
      );
    }

    final updatedSession = await _repository.addToSuperset(
      sessionId: sessionId,
      supersetTag: supersetTag,
      sessionExerciseId: sessionExerciseId,
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
          currentState: exercise.state.discriminator,
          message:
              'Cannot remove exercise $id from superset: state is ${exercise.state.discriminator}',
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
    return SessionState(
      session: session,
      openTargets: computeOpenTargets(session),
      isComplete: isSessionComplete(session),
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

  int _lookupPlannedSetCount(SessionExercise sessionExercise, Session session) {
    final state = sessionExercise.state;
    if (state is ReplacedState) {
      return state.substitute.setCount;
    }
    final exercise = _lookupPlannedExercise(sessionExercise, session);
    return exercise.sets.length;
  }

  PlannedSetValues _lookupPlannedValuesAtPosition(
    SessionExercise sessionExercise,
    Session session, {
    required int position,
  }) {
    final state = sessionExercise.state;
    if (state is ReplacedState) {
      return state.substitute.plannedValues;
    }
    return _lookupPlannedSet(
      sessionExercise,
      session,
      position: position,
    ).plannedValues;
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
      PlannedRepBased(:final weightKg, :final repTarget) =>
        ActualSetValues.repBased(
          weightKg: weightKg,
          // Seed with the upper bound for ranges — the optimistic target.
          // Lifters can dial down with the bump buttons before logging.
          reps: switch (repTarget) {
            RepTargetFixed(:final reps) => reps,
            RepTargetRange(:final maxReps) => maxReps,
          },
        ),
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        ActualSetValues.timeBased(
          durationSeconds: durationSeconds,
          weightKg: weightKg,
        ),
      PlannedBodyweight(:final repTarget) => ActualSetValues.bodyweight(
        reps: switch (repTarget) {
          RepTargetFixed(:final reps) => reps,
          RepTargetRange(:final maxReps) => maxReps,
        },
      ),
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
      (BodyweightMeasurement(), ActualBodyweight()) => true,
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
        currentState: exercise.state.discriminator,
        message:
            'Exercise ${exercise.id} must be unfinished but is ${exercise.state.discriminator}',
      );
    }
  }
}
