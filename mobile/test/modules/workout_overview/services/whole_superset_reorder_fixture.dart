// Shared fixtures for the whole-superset reorder tests. Both the drag resolver
// (SupersetReorderResolver, Slice 2) and the move resolver (ReorderMoveResolver,
// Slice 3) assert against the SAME target index here, so a regression in either
// resolver's arithmetic fails both tests rather than silently diverging.

import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

/// Session id used across the whole-superset reorder fixtures.
const supersetSessionId = 'session-1';

/// The superset tag for the `[x, y]` group in the shared background layout.
const supersetXyTag = 'xy';

/// The between-group gap index immediately below standalone "q" in the
/// background layout `p · [x,y] · q` (all unfinished). The unfinished sequence
/// is `[p, x, y, q]`, so the gap below `q` is index 4 — where both a downward
/// drag of `[x,y]` and "Move down" on `[x,y]` must land. Referenced by both
/// resolver tests so their arithmetic cannot silently diverge.
const gapBelowQ = 4;

/// A single exercise spec for the fixture group builder.
class ExSpec {
  ExSpec(this.id, {required this.state, this.supersetTag});
  final String id;
  final ExerciseState state;
  final String? supersetTag;
}

ExSpec unfinished(String id, {String? tag}) =>
    ExSpec(id, state: const ExerciseState.unfinished(), supersetTag: tag);

ExSpec finished(String id, {String? tag}) =>
    ExSpec(id, state: const ExerciseState.completed(), supersetTag: tag);

/// Builds the assembled overview groups from a flat spec list, collapsing
/// consecutive same-tag specs into one [SupersetGroup] (mirroring the
/// assembler's contiguous-run rule).
List<SupersetGroupViewModel> buildGroups(List<ExSpec> specs) {
  final now = DateTime.utc(2025);
  ExerciseViewModel viewModel(ExSpec s, int position) {
    final ex = SessionExercise(
      id: s.id,
      sessionId: supersetSessionId,
      position: position,
      plannedExerciseIdInSnapshot: 'planned-${s.id}',
      state: s.state,
      executedSets: const [],
      supersetTag: s.supersetTag,
      createdAt: now,
      updatedAt: now,
      schemaVersion: 1,
    );
    return ExerciseViewModel(
      sessionExercise: ex,
      plannedExerciseName: s.id,
      plannedSummary: '0 sets',
      libraryExerciseId: null,
      plannedMeasurementType: const MeasurementType.repBased(),
      plannedMetadata: const ExerciseMetadata(),
      plannedRestSeconds: null,
      setRows: const <SetRowViewModel>[],
      isLoggable: false,
      effectiveMeasurementType: const MeasurementType.repBased(),
    );
  }

  final out = <SupersetGroupViewModel>[];
  var i = 0;
  while (i < specs.length) {
    final s = specs[i];
    final vm = viewModel(s, i);
    if (s.supersetTag == null) {
      out.add(SupersetGroupViewModel.single(exercise: vm));
      i++;
      continue;
    }
    final tag = s.supersetTag!;
    final group = <ExerciseViewModel>[vm];
    var j = i + 1;
    while (j < specs.length && specs[j].supersetTag == tag) {
      group.add(viewModel(specs[j], j));
      j++;
    }
    if (group.length == 1) {
      out.add(SupersetGroupViewModel.single(exercise: group.single));
    } else {
      out.add(SupersetGroupViewModel.superset(tag: tag, exercises: group));
    }
    i = j;
  }
  return out;
}

/// Background layout shared by the equivalence scenarios: `p · [x,y] · q`,
/// every exercise unfinished, the superset tagged [supersetXyTag].
List<SupersetGroupViewModel> backgroundPxyQ() => buildGroups([
  unfinished('p'),
  unfinished('x', tag: supersetXyTag),
  unfinished('y', tag: supersetXyTag),
  unfinished('q'),
]);
