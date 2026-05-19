/// Whether an [ExerciseGroup] is a warmup or part of the main work.
///
/// Cooldown / activation can be added later without a schema migration —
/// the column is just text.
enum ExerciseGroupRole {
  warmup,
  main;

  static ExerciseGroupRole fromName(String name) {
    return ExerciseGroupRole.values.firstWhere(
      (r) => r.name == name,
      orElse: () => ExerciseGroupRole.main,
    );
  }
}

/// Returns true when [group] or any of its enclosing context is a warmup.
///
/// Single helper so future warmup-set work (which adds another axis on
/// [WorkoutSet]) can route through the same predicate.
bool isWarmupGroup(ExerciseGroupRole role) => role == ExerciseGroupRole.warmup;
