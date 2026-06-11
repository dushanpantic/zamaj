/// Bump-button step values for in-session numeric inputs.
///
/// The single source of truth for "how much does ± nudge a value", shared by
/// the focus-mode panels and the workout-overview set-row inline editor so the
/// two stepper presentations can never drift apart on step policy.
///
/// Per MVP design doc:
///   - weight: ±1 when current ≤ 10 kg, ±2.5 otherwise
///   - reps:   ±1
///   - duration: ±5 seconds (manual entry always allowed)
abstract final class IncrementRules {
  static const List<int> repSteps = [-1, 1];
  static const List<int> durationSteps = [-5, 5];

  /// Double-typed variants of [repSteps] / [durationSteps] for steppers that
  /// operate on a `double` value (the set-row inline editor and the focus
  /// rep/time panels), so every in-session control still draws its increments
  /// from this one class rather than re-listing literals.
  static const List<double> repStepsDouble = [-1, 1];
  static const List<double> durationStepsDouble = [-5, 5];

  /// Returns the bump steps that should be exposed for the current weight.
  ///
  /// The cutoff is non-strict on the low side: at exactly 10 kg we still
  /// expose the small steps (the design doc says "≤ 10 → ±1").
  static List<double> weightSteps(double currentKg) {
    if (currentKg <= 10) return const [-1, 1];
    return const [-2.5, 2.5];
  }

  /// Snaps a weight to the half-kg resolution that domain validation requires
  /// (`ExecutedSet.weightKg_half_kg_resolution`). The single rounding rule for
  /// every weight input across the app; rounds the midpoint away from zero and
  /// does not clamp (callers clamp where they need to).
  static double roundHalfKg(double kg) => (kg * 2).round() / 2;

  /// Bumps a weight value by [delta], clamping to ≥ 0 and rounding to the
  /// half-kg resolution via [roundHalfKg].
  static double bumpWeight(double current, double delta) {
    final next = current + delta;
    if (next <= 0) return 0;
    return roundHalfKg(next);
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
