/// Abstract contract for session persistence.
///
/// All method signatures are typed solely in domain terms. No Drift-generated
/// types appear in any public signature (Req 10.2).
library;

import '../models/actual_set_values.dart';
import '../models/exercise_metadata.dart';
import '../models/measurement_type.dart';
import '../models/session.dart';

abstract class SessionRepository {
  /// Starts a new session for [workoutDayId], capturing an immutable snapshot
  /// of the workout day at this moment (Req 6). Returns the fully hydrated
  /// [Session] with all [SessionExercise]s pre-seeded in `unfinished` state.
  Future<Session> startSession({required String workoutDayId});

  Future<Session?> getSession(String sessionId);
  Future<List<Session>> listSessionsForWorkoutDay(String workoutDayId);

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

  Future<Session> skipExercise(String sessionExerciseId);

  Future<Session> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
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
