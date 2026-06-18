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
  ///
  /// When [isDeload] is true the captured snapshot is run through
  /// [DeloadTransform.halveWorkingSets] before it is frozen, halving every
  /// `main`-role exercise's planned set count, and the session is flagged with
  /// `isDeload == true`. The program template is never mutated.
  Future<Session> startSession({
    required String workoutDayId,
    bool isDeload = false,
  });

  Future<Session?> getSession(String sessionId);
  Future<Session> getSessionByExerciseId(String sessionExerciseId);
  Future<Session> getSessionByExecutedSetId(String executedSetId);
  Future<List<Session>> listSessionsForWorkoutDay(String workoutDayId);

  /// Returns every ended session (its `endedAt` is set), fully hydrated
  /// (snapshot, exercises, executed sets, notes, extra work), in no particular
  /// order. Feeds cross-program exercise-progress aggregation, which sorts and
  /// filters in pure Dart. Recomputed from live rows on each call, so a deleted
  /// session drops out automatically.
  Future<List<Session>> listCompletedSessions();

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

  /// Permanently removes a session and all of its dependent rows (exercises,
  /// executed sets, notes, extra work). The program template snapshot embedded
  /// in the session is discarded with it. Cascades through foreign keys, so
  /// no orphans remain. Throws [NotFoundError] if no such session exists.
  Future<void> deleteSession(String sessionId);

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
  /// reverts to `unfinished`. The exercise's `position` is never modified by
  /// this operation.
  Future<Session> deleteExecutedSet({required String executedSetId});

  Future<Session> skipExercise(String sessionExerciseId);

  Future<Session> replaceExercise({
    required String sessionExerciseId,
    required String substituteName,
    required MeasurementType substituteMeasurementType,
    required PlannedSetValues substitutePlannedValues,
    required int substituteSetCount,
    ExerciseMetadata? substituteMetadata,
    String? substituteLibraryExerciseId,
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

  /// Appends [sessionExerciseId] to the existing superset identified by
  /// [supersetTag]. Atomic: the new member receives the same tag, is
  /// repositioned to sit immediately after the last existing member of the
  /// group, and any displaced exercises shift one slot to make room. All in
  /// a single transaction.
  ///
  /// Preconditions (engine-validated, repo re-asserts):
  /// - [supersetTag] names a non-empty contiguous run of members in
  ///   [sessionId], all in `UnfinishedState`.
  /// - The exercise at [sessionExerciseId] is in `UnfinishedState` and has
  ///   `supersetTag == null`.
  ///
  /// The tag is preserved (never rotated) so anything observing tag identity
  /// — the assembler that groups by tag, the "Ungroup" handler that fetches
  /// all members by tag, etc — keeps working across appends.
  Future<Session> addToSuperset({
    required String sessionId,
    required String supersetTag,
    required String sessionExerciseId,
  });
}
