import 'package:zamaj/modules/domain/domain.dart';

/// Pure mapping helpers for the add-exercise flow: which library movements the
/// picker must exclude, and how a picker choice (library entry or one-off)
/// becomes an [AddedExercisePlan].
abstract final class AddExercisePlanBuilder {
  /// The set of `libraryExerciseId`s already present in [session] (in any
  /// state), which the add-exercise picker must show as disabled — re-doing a
  /// movement already in the session happens on its existing card, not by
  /// re-adding it.
  ///
  /// Each session-exercise's effective movement is resolved through
  /// [EffectiveExercises], so an added (snapshot-less) row matches on its inline
  /// plan's library id. One-offs (null library id) contribute nothing.
  /// [excludeSessionExerciseId], when set, drops one exercise from the set —
  /// used by replace, where the exercise being terminated may share the
  /// replacement's movement.
  static Set<String> excludedLibraryIds(
    Session session, {
    String? excludeSessionExerciseId,
  }) {
    final effective = EffectiveExercises.of(session);
    final ids = <String>{};
    for (final exercise in session.sessionExercises) {
      if (exercise.id == excludeSessionExerciseId) continue;
      final libraryId = effective
          .forSessionExercise(exercise)
          .plannedExercise
          .libraryExerciseId;
      if (libraryId != null) ids.add(libraryId);
    }
    return ids;
  }

  /// Builds an inline plan from a chosen library [entry]. Name, measurement
  /// type, library link, and metadata come from the entry; planned values and
  /// set count come from the plan-config inputs.
  static AddedExercisePlan fromLibrary({
    required LibraryExercise entry,
    required PlannedSetValues plannedValues,
    required int setCount,
  }) {
    return AddedExercisePlan(
      name: entry.name,
      measurementType: entry.measurementType,
      plannedValues: plannedValues,
      setCount: setCount,
      libraryExerciseId: entry.id,
      metadata: ExerciseMetadata(videoUrl: entry.videoUrl),
    );
  }

  /// Builds an inline plan for a one-off (unlinked) movement. A null library id
  /// means it is never deduplicated. Rejects an empty name; [setCount] < 1 and
  /// measurement/values mismatches are rejected by [AddedExercisePlan] itself.
  static AddedExercisePlan oneOff({
    required String name,
    required MeasurementType measurementType,
    required PlannedSetValues plannedValues,
    required int setCount,
  }) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      throw const ValidationError(
        entityId: 'add_exercise',
        invariant: 'one_off_name_non_empty',
        message: 'A one-off exercise needs a non-empty name',
      );
    }
    return AddedExercisePlan(
      name: trimmed,
      measurementType: measurementType,
      plannedValues: plannedValues,
      setCount: setCount,
    );
  }
}
