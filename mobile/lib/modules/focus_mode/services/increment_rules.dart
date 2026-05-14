/// Bump-button step values for focus-mode numeric inputs.
///
/// Per MVP design doc:
///   - weight: ±1 when current ≤ 10 kg, ±2.5 otherwise
///   - reps:   ±1
///   - duration: ±5 seconds (manual entry always allowed)
abstract final class IncrementRules {
  static const List<int> repSteps = [-1, 1];
  static const List<int> durationSteps = [-5, 5];

  /// Returns the bump steps that should be exposed for the current weight.
  ///
  /// The cutoff is non-strict on the low side: at exactly 10 kg we still
  /// expose the small steps (the design doc says "≤ 10 → ±1").
  static List<double> weightSteps(double currentKg) {
    if (currentKg <= 10) return const [-1, 1];
    return const [-2.5, 2.5];
  }

  /// Bumps a weight value by [delta], clamping to ≥ 0 and rounding to the
  /// half-kg resolution that domain validation requires
  /// (`ExecutedSet.weightKg_half_kg_resolution`).
  static double bumpWeight(double current, double delta) {
    final next = current + delta;
    if (next <= 0) return 0;
    return (next * 2).round() / 2;
  }

  /// Bumps an integer rep count by [delta], clamping to ≥ 0.
  static int bumpReps(int current, int delta) {
    final next = current + delta;
    return next < 0 ? 0 : next;
  }

  /// Bumps a duration in seconds by [delta], clamping to ≥ 0.
  static int bumpDuration(int current, int delta) {
    final next = current + delta;
    return next < 0 ? 0 : next;
  }
}
