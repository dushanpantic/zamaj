import 'package:zamaj/modules/domain/models/exercise_state.dart';

/// How a terminal/ended exercise record reads on the app's display surfaces.
///
/// This is the canonical read-side interpretation of a session-exercise: every
/// read surface (live card, session review, history tile, plain-text export)
/// derives its badge from [ExerciseOutcomes.of] rather than switching on the
/// stored [ExerciseState] discriminator directly. Deriving from the logged-set
/// record keeps display honest — a ✓ never editorializes over partial work, and
/// legacy rows (e.g. marked-done-early or skipped-with-sets, written before
/// completion was tied to the set quota) self-heal with no migration.
enum ExerciseOutcome { completed, partial, skipped }

/// Pure derivation of an [ExerciseOutcome] from a record's stored state and its
/// logged-vs-planned set counts.
abstract final class ExerciseOutcomes {
  /// Derives the outcome for a record.
  ///
  /// The logged-set count decides: meeting (or exceeding) the planned quota →
  /// [ExerciseOutcome.completed]; some-but-not-all → [ExerciseOutcome.partial];
  /// none → [ExerciseOutcome.skipped].
  ///
  /// The stored discriminator is deliberately ignored, so a row stored as
  /// `completed` at 2 of 4 sets or `skipped` with 2 sets both read as
  /// [ExerciseOutcome.partial].
  static ExerciseOutcome of({
    required ExerciseState state,
    required int executedSetCount,
    required int plannedSetCount,
  }) {
    if (executedSetCount >= plannedSetCount) return ExerciseOutcome.completed;
    if (executedSetCount == 0) return ExerciseOutcome.skipped;
    return ExerciseOutcome.partial;
  }
}
