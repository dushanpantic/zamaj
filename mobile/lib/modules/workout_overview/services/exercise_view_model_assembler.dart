import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/planned_summary_formatter.dart';

abstract final class ExerciseViewModelAssembler {
  static List<SupersetGroupViewModel> assemble(SessionState sessionState) {
    final session = sessionState.session;
    final cursor = sessionState.cursor;
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    final groups = <SupersetGroupViewModel>[];
    String? currentTag;
    var hasCurrent = false;
    final buffer = <ExerciseViewModel>[];

    void flush() {
      if (buffer.isEmpty) return;
      if (currentTag == null) {
        for (final vm in buffer) {
          groups.add(
            SupersetGroupViewModel(supersetTag: null, exercises: [vm]),
          );
        }
      } else {
        groups.add(
          SupersetGroupViewModel(
            supersetTag: currentTag,
            exercises: List<ExerciseViewModel>.of(buffer),
          ),
        );
      }
      buffer.clear();
    }

    for (final ex in sorted) {
      final planned = _lookupPlannedExercise(ex, session);
      final plannedSummary = PlannedSummaryFormatter.summarize(planned);
      final isCursorTarget =
          cursor is ActiveCursor && cursor.sessionExerciseId == ex.id;
      final cursorSetIndex = isCursorTarget ? cursor.setIndex : null;
      final effectiveMt = switch (ex.state) {
        ReplacedState(:final substitute) => substitute.measurementType,
        _ => planned.measurementType,
      };
      final setRows = _buildSetRows(ex, planned, cursor);
      final vm = ExerciseViewModel(
        sessionExercise: ex,
        plannedExerciseInSnapshot: planned,
        plannedSummary: plannedSummary,
        setRows: setRows,
        isCursorTarget: isCursorTarget,
        cursorSetIndex: cursorSetIndex,
        effectiveMeasurementType: effectiveMt,
      );

      final tagMatches = hasCurrent &&
          ex.supersetTag != null &&
          ex.supersetTag == currentTag;
      if (tagMatches) {
        buffer.add(vm);
      } else {
        flush();
        currentTag = ex.supersetTag;
        hasCurrent = true;
        buffer.add(vm);
      }
    }
    flush();

    return groups;
  }

  static List<SetRowViewModel> _buildSetRows(
    SessionExercise sessionExercise,
    Exercise plannedExercise,
    Cursor cursor,
  ) {
    final plannedSets = List<WorkoutSet>.of(plannedExercise.sets)
      ..sort((a, b) => a.position.compareTo(b.position));
    final executedSets = List<ExecutedSet>.of(sessionExercise.executedSets)
      ..sort((a, b) => a.position.compareTo(b.position));

    final rows = <SetRowViewModel>[];

    for (var i = 0; i < plannedSets.length; i++) {
      final executed = i < executedSets.length ? executedSets[i] : null;
      final isNextLogTarget = cursor is ActiveCursor &&
          cursor.sessionExerciseId == sessionExercise.id &&
          cursor.setIndex == i;
      rows.add(
        SetRowViewModel(
          position: i,
          plannedValues: plannedSets[i].plannedValues,
          executedSet: executed,
          isNextLogTarget: isNextLogTarget,
        ),
      );
    }

    for (var j = plannedSets.length; j < executedSets.length; j++) {
      rows.add(
        SetRowViewModel(
          position: j,
          plannedValues: null,
          executedSet: executedSets[j],
          isNextLogTarget: false,
        ),
      );
    }

    return rows;
  }

  static Exercise _lookupPlannedExercise(
    SessionExercise sessionExercise,
    Session session,
  ) {
    for (final group in session.snapshot.workoutDay.exerciseGroups) {
      for (final exercise in group.exercises) {
        if (exercise.id == sessionExercise.plannedExerciseIdInSnapshot) {
          return exercise;
        }
      }
    }
    throw StateError(
      'Planned exercise ${sessionExercise.plannedExerciseIdInSnapshot} '
      'not found in session ${session.id} snapshot',
    );
  }
}

