import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/added_exercise_plan.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_metadata.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

/// Snapshot-aware resolver for [SessionExercise]s.
///
/// A session's immutable snapshot is the source of truth for a snapshot-backed
/// session-exercise's planned data; a [ReplacedState] substitute overrides the
/// measurement type, set count, display name, and planned values while the
/// group role still derives from the snapshot. This projection is the one place
/// that pairing lives — previously copied into the engine, the Drift repo, and
/// the overview/focus assemblers with three behavioural divergences (a silent
/// planned-set-count of zero and a `main` group-role fallback on a missing
/// snapshot entry).
///
/// An **added** session-exercise ([SessionExercise.addedPlan] non-null) is work
/// not present in the frozen snapshot: it resolves entirely from its inline
/// [AddedExercisePlan], with a synthesized [Exercise] standing in for the
/// (absent) snapshot entry and a `main` group role. For these the
/// `plannedExerciseIdInSnapshot` is a synthetic id and is never looked up.
/// A non-added session-exercise whose planned id is missing from the snapshot
/// still **always** throws [NotFoundError].
class EffectiveExercises {
  EffectiveExercises._(this._plannedById, this._roleById);

  final Map<String, Exercise> _plannedById;
  final Map<String, ExerciseGroupRole> _roleById;

  /// Builds the projection from a [Session]'s captured snapshot.
  factory EffectiveExercises.of(Session session) =>
      EffectiveExercises.fromWorkoutDay(session.snapshot.workoutDay);

  /// Builds the projection from a snapshot [workoutDay] directly. Useful for
  /// callers (e.g. the Drift repo) that hold the parsed snapshot but not a fully
  /// hydrated [Session].
  factory EffectiveExercises.fromWorkoutDay(WorkoutDay workoutDay) {
    final plannedById = <String, Exercise>{};
    final roleById = <String, ExerciseGroupRole>{};
    for (final group in workoutDay.exerciseGroups) {
      for (final exercise in group.exercises) {
        plannedById[exercise.id] = exercise;
        roleById[exercise.id] = group.role;
      }
    }
    return EffectiveExercises._(plannedById, roleById);
  }

  /// Resolves the effective view of [sessionExercise].
  ///
  /// Branch order: an added exercise (inline plan) resolves from its plan; a
  /// snapshot-backed exercise resolves from the snapshot (the replaced
  /// substitute is then applied by the [EffectiveExercise] getters). Throws
  /// [NotFoundError] only when a non-added session-exercise's planned exercise
  /// is absent from the snapshot — including for a replaced exercise, whose
  /// group role still requires the snapshot original.
  EffectiveExercise forSessionExercise(SessionExercise sessionExercise) {
    final addedPlan = sessionExercise.addedPlan;
    if (addedPlan != null) {
      return EffectiveExercise._(
        plannedExercise: _synthesizePlanned(sessionExercise, addedPlan),
        sessionExercise: sessionExercise,
        plannedGroupRole: ExerciseGroupRole.main,
      );
    }
    final id = sessionExercise.plannedExerciseIdInSnapshot;
    final planned = _plannedById[id];
    final role = _roleById[id];
    if (planned == null || role == null) {
      throw NotFoundError(entityType: 'Exercise', id: id);
    }
    return EffectiveExercise._(
      plannedExercise: planned,
      sessionExercise: sessionExercise,
      plannedGroupRole: role,
    );
  }

  /// Synthesizes a stand-in [Exercise] for an added session-exercise from its
  /// inline plan, so the [EffectiveExercise] getters (which read
  /// `plannedExercise`) work unchanged. The plan's single planned-value set is
  /// repeated [AddedExercisePlan.setCount] times.
  static Exercise _synthesizePlanned(
    SessionExercise sessionExercise,
    AddedExercisePlan plan,
  ) {
    final syntheticId = sessionExercise.plannedExerciseIdInSnapshot;
    return Exercise(
      id: syntheticId,
      exerciseGroupId: 'added:${sessionExercise.id}',
      position: sessionExercise.position,
      name: plan.name,
      measurementType: plan.measurementType,
      metadata: plan.metadata ?? const ExerciseMetadata(),
      libraryExerciseId: plan.libraryExerciseId,
      sets: [
        for (var i = 0; i < plan.setCount; i++)
          WorkoutSet(
            id: '$syntheticId-set-$i',
            exerciseId: syntheticId,
            position: i,
            measurementType: plan.measurementType,
            plannedValues: plan.plannedValues,
            createdAt: sessionExercise.createdAt,
            updatedAt: sessionExercise.updatedAt,
            schemaVersion: sessionExercise.schemaVersion,
          ),
      ],
      createdAt: sessionExercise.createdAt,
      updatedAt: sessionExercise.updatedAt,
      schemaVersion: sessionExercise.schemaVersion,
    );
  }
}

/// Resolved, snapshot-aware view of a single [SessionExercise].
class EffectiveExercise {
  EffectiveExercise._({
    required this.plannedExercise,
    required this.sessionExercise,
    required this.plannedGroupRole,
  });

  /// The planned exercise this view resolves against. For a snapshot-backed
  /// session-exercise it is the snapshot entry (present even when the exercise
  /// is replaced — the substitute is applied by the getters below). For an
  /// added exercise it is a stand-in synthesized from the inline plan, since
  /// there is no snapshot entry.
  final Exercise plannedExercise;

  final SessionExercise sessionExercise;

  /// The role of the snapshot group the planned exercise belongs to.
  final ExerciseGroupRole plannedGroupRole;

  /// The measurement type the user logs against — the substitute's when
  /// replaced, otherwise the planned exercise's.
  MeasurementType get effectiveMeasurementType =>
      switch (sessionExercise.state) {
        ReplacedState(:final substitute) => substitute.measurementType,
        _ => plannedExercise.measurementType,
      };

  /// The number of planned sets — the substitute's set count when replaced,
  /// otherwise the planned exercise's set count.
  int get plannedSetCount => switch (sessionExercise.state) {
    ReplacedState(:final substitute) => substitute.setCount,
    _ => plannedExercise.sets.length,
  };

  /// The name shown to the user — the substitute's when replaced.
  String get displayName => switch (sessionExercise.state) {
    ReplacedState(:final substitute) => substitute.name,
    _ => plannedExercise.name,
  };

  /// The effective planned values for the set at [position] (0-based),
  /// resolving the substitute when replaced. A replaced exercise uses the same
  /// substitute values for every set. Throws [NotFoundError] when [position] is
  /// out of range for a non-replaced exercise.
  PlannedSetValues plannedValuesAt(int position) {
    final state = sessionExercise.state;
    if (state is ReplacedState) {
      return state.substitute.plannedValues;
    }
    final sorted = List<WorkoutSet>.of(plannedExercise.sets)
      ..sort((a, b) => a.position.compareTo(b.position));
    if (position >= sorted.length) {
      throw NotFoundError(
        entityType: 'WorkoutSet',
        id: '${plannedExercise.id}[position=$position]',
      );
    }
    return sorted[position].plannedValues;
  }
}
