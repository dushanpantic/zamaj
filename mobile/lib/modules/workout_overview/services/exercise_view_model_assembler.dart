import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/planned_summary_formatter.dart';

abstract final class ExerciseViewModelAssembler {
  static List<SupersetGroupViewModel> assemble(SessionState sessionState) {
    final session = sessionState.session;
    final cursor = sessionState.cursor;

    final plannedById = <String, Exercise>{
      for (final group in session.snapshot.workoutDay.exerciseGroups)
        for (final exercise in group.exercises) exercise.id: exercise,
    };

    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    final viewModels = <ExerciseViewModel>[
      for (final ex in sorted) _buildViewModel(ex, plannedById, cursor),
    ];

    return _groupByAdjacentSupersetTag(viewModels, sorted);
  }

  static ExerciseViewModel _buildViewModel(
    SessionExercise sessionExercise,
    Map<String, Exercise> plannedById,
    Cursor cursor,
  ) {
    final planned = plannedById[sessionExercise.plannedExerciseIdInSnapshot];
    if (planned == null) {
      throw NotFoundError(
        entityType: 'Exercise',
        id: sessionExercise.plannedExerciseIdInSnapshot,
      );
    }
    final isCursorTarget =
        cursor is ActiveCursor &&
        cursor.sessionExerciseId == sessionExercise.id;
    final cursorSetIndex = isCursorTarget ? cursor.setIndex : null;
    final effectiveMt = switch (sessionExercise.state) {
      ReplacedState(:final substitute) => substitute.measurementType,
      _ => planned.measurementType,
    };
    return ExerciseViewModel(
      sessionExercise: sessionExercise,
      plannedSummary: PlannedSummaryFormatter.summarize(planned),
      plannedMeasurementType: planned.measurementType,
      plannedMetadata: planned.metadata,
      plannedExerciseName: planned.name,
      setRows: _buildSetRows(sessionExercise, planned, cursor),
      isCursorTarget: isCursorTarget,
      cursorSetIndex: cursorSetIndex,
      effectiveMeasurementType: effectiveMt,
    );
  }

  static List<SupersetGroupViewModel> _groupByAdjacentSupersetTag(
    List<ExerciseViewModel> viewModels,
    List<SessionExercise> sortedSessionExercises,
  ) {
    final groups = <SupersetGroupViewModel>[];
    var i = 0;
    while (i < viewModels.length) {
      final ex = sortedSessionExercises[i];
      final tag = ex.supersetTag;
      if (tag == null) {
        groups.add(SupersetGroupViewModel.single(exercise: viewModels[i]));
        i++;
        continue;
      }
      var j = i + 1;
      while (j < viewModels.length &&
          sortedSessionExercises[j].supersetTag == tag) {
        j++;
      }
      if (j - i == 1) {
        groups.add(SupersetGroupViewModel.single(exercise: viewModels[i]));
      } else {
        groups.add(
          SupersetGroupViewModel.superset(
            tag: tag,
            exercises: viewModels.sublist(i, j),
          ),
        );
      }
      i = j;
    }
    return groups;
  }

  static List<SetRowViewModel> _buildSetRows(
    SessionExercise sessionExercise,
    Exercise plannedExercise,
    Cursor cursor,
  ) {
    // Executed sets are ordered by their LexoRank-style [position] field,
    // which encodes chronological completion order — not the planned-set
    // index. So the i-th executed set in this list is the i-th set the user
    // actually performed; row i pairs it with the i-th planned set.
    final sortedExecuted = List<ExecutedSet>.of(sessionExercise.executedSets)
      ..sort((a, b) => a.position.compareTo(b.position));

    final state = sessionExercise.state;
    final PlannedSetValues? Function(int) plannedValuesAt;
    final String? Function(int) plannedSetIdAt;
    final int plannedCount;
    if (state is ReplacedState) {
      final substituteSetCount = state.substitute.setCount;
      plannedValuesAt = (i) =>
          i < substituteSetCount ? state.substitute.plannedValues : null;
      plannedSetIdAt = (_) => null;
      plannedCount = substituteSetCount;
    } else {
      final sortedPlanned = List<WorkoutSet>.of(plannedExercise.sets)
        ..sort((a, b) => a.position.compareTo(b.position));
      plannedValuesAt = (i) =>
          i < sortedPlanned.length ? sortedPlanned[i].plannedValues : null;
      plannedSetIdAt = (i) =>
          i < sortedPlanned.length ? sortedPlanned[i].id : null;
      plannedCount = sortedPlanned.length;
    }

    final maxIndex = sortedExecuted.length > plannedCount
        ? sortedExecuted.length
        : plannedCount;

    final rows = <SetRowViewModel>[];
    ActualSetValues? lastExecutedActuals;
    for (var i = 0; i < maxIndex; i++) {
      final plannedValues = plannedValuesAt(i);
      final executed = i < sortedExecuted.length ? sortedExecuted[i] : null;
      if (plannedValues == null && executed == null) continue;
      rows.add(
        SetRowViewModel(
          position: i,
          plannedValues: plannedValues,
          plannedSetIdInSnapshot: plannedSetIdAt(i),
          executedSet: executed,
          isNextLogTarget:
              cursor is ActiveCursor &&
              cursor.sessionExerciseId == sessionExercise.id &&
              cursor.setIndex == i,
          suggestedActualValues: executed == null ? lastExecutedActuals : null,
        ),
      );
      if (executed != null) {
        lastExecutedActuals = executed.actualValues;
      }
    }
    return rows;
  }
}
