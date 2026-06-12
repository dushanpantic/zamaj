import 'package:zamaj/core/planned_summary_formatter.dart';
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
    String? userPinnedPanelId,
  }) {
    final session = state.session;
    final effective = EffectiveExercises.of(session);
    final loggableIds = <String>{
      for (final t in state.openTargets) t.sessionExerciseId,
    };
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));

    final groups = groupBySupersetRun(sorted);
    final groupIndex = groups.indexWhere(
      (g) => g.any((e) => e.id == anchorSessionExerciseId),
    );
    if (groupIndex == -1) return null;
    final group = groups[groupIndex];

    final panels = <FocusModeViewModel>[
      for (final exercise in group)
        if (exercise.state is! SkippedState)
          _buildPanel(
            exercise,
            effective,
            _resolveGroupRole(exercise, effective),
            isLoggable: loggableIds.contains(exercise.id),
          ),
    ];
    if (panels.isEmpty) return null;

    final supersetTag = group.first.supersetTag;
    final tagSharedByAll =
        supersetTag != null && group.every((e) => e.supersetTag == supersetTag);

    final upNext = _findNextGroup(
      groups,
      startingAfter: groupIndex,
      effective: effective,
    );

    final activePick = _pickActivePanelId(
      panels: panels,
      group: group,
      userPinnedPanelId: userPinnedPanelId,
    );

    return FocusModeGroupViewModel(
      sessionId: session.id,
      workoutDayName: session.snapshot.workoutDay.name,
      supersetTag: tagSharedByAll ? supersetTag : null,
      panels: panels,
      upNextGroupLabel: upNext?.label,
      upNextGroupAnchorId: upNext?.anchorId,
      activeSessionExerciseId: activePick?.id,
      activeIsUserPinned: activePick?.isUserPinned ?? false,
    );
  }

  /// Picks the panel that should render as ACTIVE inside [group].
  ///
  /// See `focus.md` §3.3 for the full rule. In short:
  ///   1. Only loggable panels are candidates. If none, returns null (the
  ///      group is terminal; the bloc will transition away).
  ///   2. Among loggable panels, the minimum `completedSetsCount` wins.
  ///   3. Ties broken by rotation: pick the panel that comes next in
  ///      position order after the one that logged most recently.
  ///   4. A valid [userPinnedPanelId] overrides (2)+(3) when it appears
  ///      in the loggable candidate set.
  static ({String id, bool isUserPinned})? _pickActivePanelId({
    required List<FocusModeViewModel> panels,
    required List<SessionExercise> group,
    required String? userPinnedPanelId,
  }) {
    final loggable = panels.where((p) => p.isLoggable).toList(growable: false);
    if (loggable.isEmpty) return null;
    if (loggable.length == 1) {
      return (id: loggable.single.sessionExerciseId, isUserPinned: false);
    }

    if (userPinnedPanelId != null &&
        loggable.any((p) => p.sessionExerciseId == userPinnedPanelId)) {
      return (id: userPinnedPanelId, isUserPinned: true);
    }

    final minCount = loggable
        .map((p) => p.completedSetsCount)
        .reduce((a, b) => a < b ? a : b);
    final pool = loggable
        .where((p) => p.completedSetsCount == minCount)
        .toList(growable: false);
    if (pool.length == 1) {
      return (id: pool.single.sessionExerciseId, isUserPinned: false);
    }

    // Tie-breaker: among the pool, pick the panel that comes next in
    // position order after the panel containing the most-recent
    // completedAt in this group.
    final mostRecentExerciseId = _mostRecentlyLoggedExerciseId(group);
    final positionById = <String, int>{
      for (var i = 0; i < group.length; i++) group[i].id: i,
    };
    final poolIds = pool.map((p) => p.sessionExerciseId).toSet();

    if (mostRecentExerciseId != null) {
      final startPos = positionById[mostRecentExerciseId]!;
      for (var step = 1; step <= group.length; step++) {
        final candidate = group[(startPos + step) % group.length];
        if (poolIds.contains(candidate.id)) {
          return (id: candidate.id, isUserPinned: false);
        }
      }
    }

    // No prior set in the group — pick the lowest-position panel in pool.
    pool.sort(
      (a, b) => positionById[a.sessionExerciseId]!.compareTo(
        positionById[b.sessionExerciseId]!,
      ),
    );
    return (id: pool.first.sessionExerciseId, isUserPinned: false);
  }

  static String? _mostRecentlyLoggedExerciseId(List<SessionExercise> group) {
    DateTime? best;
    String? bestId;
    for (final ex in group) {
      for (final set in ex.executedSets) {
        if (best == null || set.completedAt.isAfter(best)) {
          best = set.completedAt;
          bestId = ex.id;
        }
      }
    }
    return bestId;
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
    final effective = EffectiveExercises.of(session);
    final sorted = List<SessionExercise>.of(session.sessionExercises)
      ..sort((a, b) => a.position.compareTo(b.position));
    final groups = groupBySupersetRun(sorted);

    final options = <FocusModeSwitchOption>[];
    for (final group in groups) {
      final visible = group
          .where((e) => e.state is! SkippedState)
          .toList(growable: false);
      if (visible.isEmpty) continue;
      final label = _groupLabel(visible, effective);
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
    final groups = groupBySupersetRun(sorted);

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

  static ({String label, String anchorId})? _findNextGroup(
    List<List<SessionExercise>> groups, {
    required int startingAfter,
    required EffectiveExercises effective,
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
        label: _groupLabel(visible, effective),
        anchorId: actionable.first.id,
      );
    }
    return null;
  }

  static String _groupLabel(
    List<SessionExercise> visible,
    EffectiveExercises effective,
  ) {
    if (visible.length == 1) {
      return _displayName(visible.first, effective);
    }
    return visible.map((e) => _displayName(e, effective)).join(' + ');
  }

  static String _displayName(
    SessionExercise exercise,
    EffectiveExercises effective,
  ) {
    return effective.forSessionExercise(exercise).displayName;
  }

  static ExerciseGroupRole _resolveGroupRole(
    SessionExercise sessionExercise,
    EffectiveExercises effective,
  ) {
    return effective.forSessionExercise(sessionExercise).plannedGroupRole;
  }

  static FocusModeViewModel _buildPanel(
    SessionExercise exercise,
    EffectiveExercises effective,
    ExerciseGroupRole plannedGroupRole, {
    required bool isLoggable,
  }) {
    final eff = effective.forSessionExercise(exercise);
    final planned = eff.plannedExercise;
    final effectiveMt = eff.effectiveMeasurementType;
    final isReplaced = exercise.state is ReplacedState;
    final displayName = eff.displayName;
    final displayMetadata = switch (exercise.state) {
      ReplacedState(:final substitute) => substitute.metadata,
      _ => planned.metadata,
    };

    final totalPlannedSets = eff.plannedSetCount;

    final sortedExecuted = List<ExecutedSet>.of(exercise.executedSets)
      ..sort((a, b) => a.position.compareTo(b.position));
    final lastExecuted = sortedExecuted.isEmpty ? null : sortedExecuted.last;

    final currentSetIndex = sortedExecuted.length;

    final (
      currentPlannedValues,
      currentPlannedSetId,
      plannedSummary,
    ) = switch (exercise.state) {
      ReplacedState(:final substitute) => (
        currentSetIndex < substitute.setCount ? substitute.plannedValues : null,
        null,
        PlannedSummaryFormatter.summarizeValues(
          substitute.plannedValues,
          substitute.setCount,
        ),
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
          PlannedSummaryFormatter.summarize(planned),
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
}
