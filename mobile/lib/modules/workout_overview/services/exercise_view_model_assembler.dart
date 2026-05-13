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
    final plannedByPosition = <int, WorkoutSet>{
      for (final s in plannedExercise.sets) s.position: s,
    };
    final executedByPosition = <int, ExecutedSet>{
      for (final s in sessionExercise.executedSets) s.position: s,
    };

    final maxPosition = [
      ...plannedByPosition.keys,
      ...executedByPosition.keys,
    ].fold<int>(-1, (a, b) => b > a ? b : a);

    final rows = <SetRowViewModel>[];
    for (var p = 0; p <= maxPosition; p++) {
      final planned = plannedByPosition[p];
      final executed = executedByPosition[p];
      if (planned == null && executed == null) continue;
      rows.add(
        SetRowViewModel(
          position: p,
          plannedValues: planned?.plannedValues,
          plannedSetIdInSnapshot: planned?.id,
          executedSet: executed,
          isNextLogTarget:
              cursor is ActiveCursor &&
              cursor.sessionExerciseId == sessionExercise.id &&
              cursor.setIndex == p,
        ),
      );
    }
    return rows;
  }
}
