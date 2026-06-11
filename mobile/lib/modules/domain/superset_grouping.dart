import 'package:zamaj/modules/domain/models/session_exercise.dart';

/// Groups session exercises into the contiguous superset runs the whole app
/// renders from — the single grouping definition shared by the workout-overview
/// bloc, the overview assembler, and the focus assembler.
///
/// Exercises are first ordered by [SessionExercise.position]; a maximal run of
/// adjacent exercises sharing the same non-null `supersetTag` forms one group,
/// and every other exercise (a null tag, or a tag that doesn't continue into
/// the next position) forms a singleton group. Grouping is by *contiguity*:
/// two exercises that share a tag but are separated by a differently-tagged
/// exercise stay in separate groups (a layout the engine keeps impossible
/// today by holding superset members contiguous).
List<List<SessionExercise>> groupBySupersetRun(
  List<SessionExercise> sessionExercises,
) {
  final sorted = List<SessionExercise>.of(sessionExercises)
    ..sort((a, b) => a.position.compareTo(b.position));
  final groups = <List<SessionExercise>>[];
  var i = 0;
  while (i < sorted.length) {
    final tag = sorted[i].supersetTag;
    if (tag == null) {
      groups.add([sorted[i]]);
      i++;
      continue;
    }
    var j = i + 1;
    while (j < sorted.length && sorted[j].supersetTag == tag) {
      j++;
    }
    groups.add(sorted.sublist(i, j));
    i = j;
  }
  return groups;
}
