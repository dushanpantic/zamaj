import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

/// The single enforcement point for when the per-member "Remove from superset"
/// action is offered.
///
/// The confirmed gating rule: a member may be extracted only from a **live**
/// session, when **every** member of its superset is unfinished, and the group
/// has **three or more** members. A 2-member group uses Ungroup instead; a
/// partially-finished group is a fixed anchor (Ungroup only). The same rule is
/// shared by the engine precondition, this UI predicate, and undo.
abstract final class SupersetRemoveEligibility {
  static bool canRemove({
    required int memberCount,
    required bool allUnfinished,
    required bool canMutate,
  }) => canMutate && allUnfinished && memberCount >= 3;

  /// Convenience over an assembled [SupersetGroupViewModel]: standalone groups
  /// are never eligible; a superset is evaluated by [canRemove].
  static bool canRemoveFromGroup(
    SupersetGroupViewModel group, {
    required bool canMutate,
  }) {
    return switch (group) {
      SingleGroupViewModel() => false,
      SupersetGroup(:final exercises) => canRemove(
        memberCount: exercises.length,
        allUnfinished: exercises.every(
          (e) => e.sessionExercise.state is UnfinishedState,
        ),
        canMutate: canMutate,
      ),
    };
  }
}
