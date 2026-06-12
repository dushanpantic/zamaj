import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/measurement_type.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

/// Snapshot-aware resolver for [SessionExercise]s.
///
/// A session's immutable snapshot is the single source of truth for a
/// session-exercise's planned data; a [ReplacedState] substitute overrides the
/// measurement type, set count, display name, and planned values while the
/// group role still derives from the snapshot. This projection is the one place
/// that pairing lives — previously copied into the engine, the Drift repo, and
/// the overview/focus assemblers with three behavioural divergences (a silent
/// planned-set-count of zero and a `main` group-role fallback on a missing
/// snapshot entry). Here a missing planned exercise **always** throws
/// [NotFoundError].
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
  /// Throws [NotFoundError] when the session-exercise's planned exercise is
  /// absent from the snapshot — including for a replaced exercise, whose group
  /// role still requires the snapshot original.
  EffectiveExercise forSessionExercise(SessionExercise sessionExercise) {
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
}

/// Resolved, snapshot-aware view of a single [SessionExercise].
class EffectiveExercise {
  EffectiveExercise._({
    required this.plannedExercise,
    required this.sessionExercise,
    required this.plannedGroupRole,
  });

  /// The planned exercise from the immutable snapshot. Always present even when
  /// the session-exercise is replaced.
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
