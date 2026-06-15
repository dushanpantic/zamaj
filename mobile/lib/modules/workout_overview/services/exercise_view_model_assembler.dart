import 'package:zamaj/core/planned_summary_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';

abstract final class ExerciseViewModelAssembler {
  /// Builds fully read-only view models for a finished [session]: with no open
  /// targets every exercise and set row reports `isLoggable == false`, so the
  /// post-session review screen reuses the exact pairing and superset grouping
  /// without re-implementing it.
  static List<SupersetGroupViewModel> assembleReadOnly(Session session) =>
      assemble(
        SessionState(session: session, openTargets: const [], isComplete: true),
      );

  static List<SupersetGroupViewModel> assemble(SessionState sessionState) {
    final session = sessionState.session;
    final loggableSetIndexByExerciseId = <String, int>{
      for (final t in sessionState.openTargets)
        t.sessionExerciseId: t.plannedSetIndex,
    };

    final effective = EffectiveExercises.of(session);

    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    final viewModels = <ExerciseViewModel>[
      for (final ex in sorted)
        _buildViewModel(
          ex,
          effective.forSessionExercise(ex),
          loggableSetIndexByExerciseId[ex.id],
        ),
    ];

    return _groupByAdjacentSupersetTag(viewModels, sorted);
  }

  static ExerciseViewModel _buildViewModel(
    SessionExercise sessionExercise,
    EffectiveExercise effective,
    int? loggableSetIndex,
  ) {
    final planned = effective.plannedExercise;
    return ExerciseViewModel(
      sessionExercise: sessionExercise,
      plannedSummary: PlannedSummaryFormatter.summarize(planned),
      plannedMeasurementType: planned.measurementType,
      plannedMetadata: planned.metadata,
      plannedRestSeconds: planned.plannedRestSeconds,
      plannedExerciseName: planned.name,
      libraryExerciseId: planned.libraryExerciseId,
      setRows: _buildSetRows(sessionExercise, planned, loggableSetIndex),
      isLoggable: loggableSetIndex != null,
      effectiveMeasurementType: effective.effectiveMeasurementType,
      plannedGroupRole: effective.plannedGroupRole,
    );
  }

  /// Wraps the shared contiguity-based grouping ([groupBySupersetRun]) into the
  /// overview's view models: a lone or null-tagged run renders as a `.single`,
  /// a multi-member tagged run as a `.superset`.
  static List<SupersetGroupViewModel> _groupByAdjacentSupersetTag(
    List<ExerciseViewModel> viewModels,
    List<SessionExercise> sortedSessionExercises,
  ) {
    final vmById = <String, ExerciseViewModel>{
      for (final vm in viewModels) vm.sessionExercise.id: vm,
    };
    final groups = <SupersetGroupViewModel>[];
    for (final run in groupBySupersetRun(sortedSessionExercises)) {
      final runVms = [for (final ex in run) vmById[ex.id]!];
      final tag = run.first.supersetTag;
      if (tag == null || runVms.length == 1) {
        groups.add(SupersetGroupViewModel.single(exercise: runVms.single));
      } else {
        groups.add(
          SupersetGroupViewModel.superset(tag: tag, exercises: runVms),
        );
      }
    }
    return groups;
  }

  static List<SetRowViewModel> _buildSetRows(
    SessionExercise sessionExercise,
    Exercise plannedExercise,
    int? loggableSetIndex,
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
          isLoggable: loggableSetIndex != null && loggableSetIndex == i,
          suggestedActualValues: exec == null && executed.isNotEmpty
              ? executed.last.actualValues
              : null,
        ),
      );
    }
    return rows;
  }
}
