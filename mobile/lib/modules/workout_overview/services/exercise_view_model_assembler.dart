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
      plannedRestSeconds: planned.plannedRestSeconds,
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
    // executedSets is already in chronological order (mapper sorts by the
    // dense ExecutedSet.position). Planned sets live on the template side
    // and use LexoRank ordering, so sort them once.
    final executed = sessionExercise.executedSets;
    final state = sessionExercise.state;
    final PlannedSetValues? Function(int) plannedValuesAt;
    final String? Function(int) plannedSetIdAt;
    final int plannedCount;
    if (state is ReplacedState) {
      final n = state.substitute.setCount;
      plannedValuesAt = (i) => i < n ? state.substitute.plannedValues : null;
      plannedSetIdAt = (_) => null;
      plannedCount = n;
    } else {
      final sorted = List<WorkoutSet>.of(plannedExercise.sets)
        ..sort((a, b) => a.position.compareTo(b.position));
      plannedValuesAt = (i) =>
          i < sorted.length ? sorted[i].plannedValues : null;
      plannedSetIdAt = (i) => i < sorted.length ? sorted[i].id : null;
      plannedCount = sorted.length;
    }

    final maxIndex = executed.length > plannedCount
        ? executed.length
        : plannedCount;
    final rows = <SetRowViewModel>[];
    for (var i = 0; i < maxIndex; i++) {
      final planned = plannedValuesAt(i);
      final exec = i < executed.length ? executed[i] : null;
      if (planned == null && exec == null) continue;
      rows.add(
        SetRowViewModel(
          position: i,
          plannedValues: planned,
          plannedSetIdInSnapshot: plannedSetIdAt(i),
          executedSet: exec,
          isNextLogTarget:
              cursor is ActiveCursor &&
              cursor.sessionExerciseId == sessionExercise.id &&
              cursor.setIndex == i,
          suggestedActualValues: exec == null && executed.isNotEmpty
              ? executed.last.actualValues
              : null,
        ),
      );
    }
    return rows;
  }
}
