import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_group_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';

/// Builds the focus-mode view models from a [SessionState] anchored on a
/// session-exercise id.
///
/// Returns null when [anchorSessionExerciseId] is unknown, or when the
/// anchor's group has no visible panels (i.e. every member is `skipped`).
/// The bloc transitions to a dedicated workout-complete state when the
/// session itself is complete, before calling the assembler.
abstract final class FocusModeAssembler {
  static FocusModeGroupViewModel? assemble(
    SessionState state, {
    required String anchorSessionExerciseId,
  }) {
    final session = state.session;
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    final groups = _computeGroups(sorted);
    final groupIndex = groups.indexWhere(
      (g) => g.any((e) => e.id == anchorSessionExerciseId),
    );
    if (groupIndex == -1) return null;
    final group = groups[groupIndex];

    final panels = <FocusModeViewModel>[
      for (final exercise in group)
        if (exercise.state is! SkippedState)
          _buildPanel(exercise, session, _resolveGroupRole(exercise, session)),
    ];
    if (panels.isEmpty) return null;

    final supersetTag = group.first.supersetTag;
    final tagSharedByAll =
        supersetTag != null && group.every((e) => e.supersetTag == supersetTag);

    final upNext = _findNextGroup(
      groups,
      startingAfter: groupIndex,
      session: session,
    );

    return FocusModeGroupViewModel(
      sessionId: session.id,
      workoutDayName: session.snapshot.workoutDay.name,
      supersetTag: tagSharedByAll ? supersetTag : null,
      panels: panels,
      upNextGroupLabel: upNext?.label,
      upNextGroupAnchorId: upNext?.anchorId,
    );
  }

  /// Lists every visible group in the session for the "switch" picker.
  ///
  /// Groups whose members are all skipped or all completed-without-quota-met
  /// are omitted — they wouldn't render a focusable panel. The currently
  /// focused group (matching [currentAnchorId]) is flagged so the picker can
  /// disable or annotate it.
  static List<FocusModeSwitchOption> listSwitchOptions(
    SessionState state, {
    required String currentAnchorId,
  }) {
    final session = state.session;
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));
    final groups = _computeGroups(sorted);

    final options = <FocusModeSwitchOption>[];
    for (final group in groups) {
      final visible = group
          .where((e) => e.state is! SkippedState)
          .toList(growable: false);
      if (visible.isEmpty) continue;
      final label = _groupLabel(visible, session);
      final isSuperset =
          visible.length > 1 && visible.first.supersetTag != null;
      final anchor = visible.first.id;
      final isCurrent = group.any((e) => e.id == currentAnchorId);
      options.add(
        FocusModeSwitchOption(
          anchorSessionExerciseId: anchor,
          label: label,
          isSuperset: isSuperset,
          isCurrent: isCurrent,
        ),
      );
    }
    return options;
  }

  /// Returns the anchor session-exercise id the bloc should switch to after
  /// [completedAnchorId]'s group becomes fully terminal. Falls back to the
  /// first remaining open target in any group. Returns null when the
  /// session is complete.
  static String? findNextAnchorAfter(
    SessionState state, {
    required String completedAnchorId,
  }) {
    final session = state.session;
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));
    final groups = _computeGroups(sorted);

    final currentIndex = groups.indexWhere(
      (g) => g.any((e) => e.id == completedAnchorId),
    );

    bool hasOpenTarget(List<SessionExercise> group) {
      for (final ex in group) {
        if (state.openTargets.any((t) => t.sessionExerciseId == ex.id)) {
          return true;
        }
      }
      return false;
    }

    if (currentIndex != -1) {
      for (var i = currentIndex + 1; i < groups.length; i++) {
        if (hasOpenTarget(groups[i])) {
          return groups[i]
              .firstWhere(
                (e) =>
                    state.openTargets.any((t) => t.sessionExerciseId == e.id),
              )
              .id;
        }
      }
      for (var i = 0; i < currentIndex; i++) {
        if (hasOpenTarget(groups[i])) {
          return groups[i]
              .firstWhere(
                (e) =>
                    state.openTargets.any((t) => t.sessionExerciseId == e.id),
              )
              .id;
        }
      }
    } else if (state.openTargets.isNotEmpty) {
      return state.openTargets.first.sessionExerciseId;
    }
    return null;
  }

  // -------------------------------------------------------------------------

  static List<List<SessionExercise>> _computeGroups(
    List<SessionExercise> sortedExercises,
  ) {
    final groups = <List<SessionExercise>>[];
    var i = 0;
    while (i < sortedExercises.length) {
      final tag = sortedExercises[i].supersetTag;
      if (tag == null) {
        groups.add([sortedExercises[i]]);
        i++;
        continue;
      }
      var j = i + 1;
      while (j < sortedExercises.length &&
          sortedExercises[j].supersetTag == tag) {
        j++;
      }
      groups.add(sortedExercises.sublist(i, j));
      i = j;
    }
    return groups;
  }

  static ({String label, String anchorId})? _findNextGroup(
    List<List<SessionExercise>> groups, {
    required int startingAfter,
    required Session session,
  }) {
    for (var i = startingAfter + 1; i < groups.length; i++) {
      final visible = groups[i]
          .where((e) => e.state is! SkippedState)
          .toList(growable: false);
      if (visible.isEmpty) continue;
      final actionable = visible
          .where((e) {
            return switch (e.state) {
              UnfinishedState() || ReplacedState() => true,
              _ => false,
            };
          })
          .toList(growable: false);
      if (actionable.isEmpty) continue;
      return (
        label: _groupLabel(visible, session),
        anchorId: actionable.first.id,
      );
    }
    return null;
  }

  static String _groupLabel(List<SessionExercise> visible, Session session) {
    if (visible.length == 1) {
      return _displayName(visible.first, session);
    }
    return visible.map((e) => _displayName(e, session)).join(' + ');
  }

  static String _displayName(SessionExercise exercise, Session session) {
    return switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.name,
      _ => _lookupPlanned(sessionExercise: exercise, session: session).name,
    };
  }

  static ExerciseGroupRole _resolveGroupRole(
    SessionExercise sessionExercise,
    Session session,
  ) {
    for (final group in session.snapshot.workoutDay.exerciseGroups) {
      for (final ex in group.exercises) {
        if (ex.id == sessionExercise.plannedExerciseIdInSnapshot) {
          return group.role;
        }
      }
    }
    return ExerciseGroupRole.main;
  }

  static FocusModeViewModel _buildPanel(
    SessionExercise exercise,
    Session session,
    ExerciseGroupRole plannedGroupRole,
  ) {
    final planned = _lookupPlanned(sessionExercise: exercise, session: session);
    final effectiveMt = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.measurementType,
      _ => planned.measurementType,
    };
    final isReplaced = exercise.state is ReplacedState;
    final displayName = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.name,
      _ => planned.name,
    };
    final displayMetadata = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.metadata,
      _ => planned.metadata,
    };

    final totalPlannedSets = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.setCount,
      _ => planned.sets.length,
    };

    final sortedExecuted = List<ExecutedSet>.of(exercise.executedSets)
      ..sort((a, b) => a.position.compareTo(b.position));
    final lastExecuted = sortedExecuted.isEmpty ? null : sortedExecuted.last;

    final isLoggable = switch (exercise.state) {
      UnfinishedState() ||
      ReplacedState() => sortedExecuted.length < totalPlannedSets,
      _ => false,
    };
    final currentSetIndex = sortedExecuted.length;

    final (
      currentPlannedValues,
      currentPlannedSetId,
      plannedSummary,
    ) = switch (exercise.state) {
      ReplacedState(:final substitute) => (
        currentSetIndex < substitute.setCount ? substitute.plannedValues : null,
        null,
        _summarizeSubstitute(substitute),
      ),
      _ => () {
        final sortedPlanned = List<WorkoutSet>.of(planned.sets)
          ..sort((a, b) => a.position.compareTo(b.position));
        final currentPlanned = currentSetIndex < sortedPlanned.length
            ? sortedPlanned[currentSetIndex]
            : null;
        return (
          currentPlanned?.plannedValues,
          currentPlanned?.id,
          _summarizePlanned(planned),
        );
      }(),
    };

    return FocusModeViewModel(
      sessionExerciseId: exercise.id,
      displayExerciseName: displayName,
      displayMetadata: displayMetadata,
      effectiveMeasurementType: effectiveMt,
      currentSetIndex: currentSetIndex,
      totalPlannedSets: totalPlannedSets,
      completedSetsCount: sortedExecuted.length,
      currentPlannedValues: currentPlannedValues,
      plannedSummary: plannedSummary,
      currentPlannedSetIdInSnapshot: currentPlannedSetId,
      lastExecutedValues: lastExecuted?.actualValues,
      plannedRestSeconds: planned.plannedRestSeconds,
      isReplaced: isReplaced,
      plannedExerciseName: planned.name,
      isLoggable: isLoggable,
      plannedGroupRole: plannedGroupRole,
    );
  }

  static String _summarizeSubstitute(SubstituteExercise substitute) {
    return switch (substitute.plannedValues) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${substitute.setCount}×${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${substitute.setCount}×${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '${substitute.setCount}×${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '${substitute.setCount}×${RepTargetFormatter.format(repTarget)}',
    };
  }

  static Exercise _lookupPlanned({
    required SessionExercise sessionExercise,
    required Session session,
  }) {
    for (final group in session.snapshot.workoutDay.exerciseGroups) {
      for (final ex in group.exercises) {
        if (ex.id == sessionExercise.plannedExerciseIdInSnapshot) {
          return ex;
        }
      }
    }
    throw NotFoundError(
      entityType: 'Exercise',
      id: sessionExercise.plannedExerciseIdInSnapshot,
    );
  }

  static String _summarizePlanned(Exercise plannedExercise) {
    final sets = List<WorkoutSet>.of(plannedExercise.sets)
      ..sort((a, b) => a.position.compareTo(b.position));
    if (sets.isEmpty) return '0 sets';

    final first = sets.first.plannedValues;
    final allSame = sets.every((s) => s.plannedValues == first);
    if (!allSame) return '${sets.length} sets';

    return switch (first) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${sets.length}×${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${sets.length}×${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '${sets.length}×${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '${sets.length}×${RepTargetFormatter.format(repTarget)}',
    };
  }
}
