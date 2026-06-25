import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';

/// Converts a session's logged (actual) sets into a planned prescription,
/// carrying a movement's performance forward into the exercise editor.
///
/// The mapping is structure-preserving and lossless per set: a logged rep count
/// becomes a **fixed** rep target (never a range), weights and hold durations
/// pass through unchanged, and the planned set count equals the logged set
/// count. The reverse direction (planned → logged) is the cap-history
/// aggregator's concern; this is purely actual → planned.
abstract final class ActualToPlannedSets {
  /// Maps a single logged set to its planned equivalent.
  static PlannedSetValues fromActual(ActualSetValues actual) =>
      switch (actual) {
        ActualRepBased(:final weightKg, :final reps) =>
          PlannedSetValues.repBased(
            weightKg: weightKg,
            repTarget: RepTarget.fixed(reps: reps),
          ),
        ActualBodyweight(:final reps) => PlannedSetValues.bodyweight(
          repTarget: RepTarget.fixed(reps: reps),
        ),
        ActualTimeBased(:final durationSeconds, :final weightKg) =>
          PlannedSetValues.timeBased(
            durationSeconds: durationSeconds,
            weightKg: weightKg,
          ),
      };

  /// Maps an ordered list of logged sets, one planned set per logged set, in
  /// the same order. An empty list yields an empty prescription.
  static List<PlannedSetValues> fromActuals(List<ActualSetValues> actuals) => [
    for (final actual in actuals) fromActual(actual),
  ];
}
