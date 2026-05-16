/// Abstract contract for session persistence.
///
/// All method signatures are typed solely in domain terms. No Drift-generated
/// types appear in any public signature (Req 10.2).
library;

import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';

abstract class SessionRepository {
  /// Starts a new session for [workoutDayId], capturing an immutable snapshot
  /// of the workout day at this moment (Req 6). Returns the fully hydrated
  /// [Session] with all [SessionExercise]s pre-seeded in `unfinished` state.
  Future<Session> startSession({required String workoutDayId});

  Future<Session?> getSession(String sessionId);
  Future<Session> getSessionByExerciseId(String sessionExerciseId);
  Future<Session> getSessionByExecutedSetId(String executedSetId);
  Future<List<Session>> listSessionsForWorkoutDay(String workoutDayId);

  /// Returns the currently in-flight session (one whose `endedAt` is null), or
  /// null when no session is active. If — defensively — more than one row has
  /// `endedAt == null`, returns the most recently started one.
  Future<Session?> getActiveSession();

  /// Reactive read of the currently in-flight session. Emits the latest
  /// in-flight [Session] (or null when none is active) on subscribe, then
  /// re-emits whenever session-related rows change. Used by the global
  /// "session in flight" banner to surface a resume affordance from anywhere
  /// in the app.
  Stream<Session?> watchActiveSession();

  /// Reactive read of a session. Emits the current value immediately, then
  /// re-emits whenever the session or any of its related rows (exercises,
  /// executed sets, notes, extra work) change. Emits `null` when the session
  /// does not exist or has been deleted.
  ///
  /// Subscribers receive every committed mutation regardless of which caller
  /// initiated it, which lets multiple screens of the same session stay in
  /// lock-step without manual refresh signals.
  Stream<Session?> watchSession(String sessionId);

  Future<Session> endSession(String sessionId);

  Future<Session> completeSet({
    required String sessionExerciseId,
    required ActualSetValues actualValues,
    String? plannedSetIdInSnapshot,
  });

  Future<Session> updateExecutedSet({
    required String executedSetId,
    required ActualSetValues actualValues,
  });

  /// Deletes a previously completed set.
  ///
  /// If the parent exercise was in `completed` state and removing this set
  /// drops its executed-set count below the planned count, the exercise
  /// reverts to `unfinished` and is reinserted at the front of the unfinished
  /// sequence (so the cursor lands on it again).
  Future<Session> deleteExecutedSet({required String executedSetId});

  Future<Session> skipExercise(String sessionExerciseId);

  Future<Session> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    required PlannedSetValues substitutePlannedValues,
    required int substituteSetCount,
    ExerciseMetadata? substituteMetadata,
  });

  /// Reorders unfinished [SessionExercise]s only. Throws [OrderingError] if
  /// any id in [orderedUnfinishedIds] is not in `unfinished` state (Req 7 AC 3).
  Future<Session> reorderUnfinished({
    required String sessionId,
    required List<String> orderedUnfinishedIds,
  });

  Future<Session> addSessionNote({
    required String sessionId,
    required String body,
  });

  Future<Session> addExtraWork({
    required String sessionId,
    required String body,
  });

  Future<Session> createSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  });

  Future<Session> removeSuperset({
    required String sessionId,
    required List<String> sessionExerciseIds,
  });
}
