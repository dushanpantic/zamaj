import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_group_role.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/substitute_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';

/// Renders a [Session] to plain text suitable for sharing to a coach via
/// WhatsApp / SMS / email.
///
/// Pure Dart. No locale, no IO. The output is stable for a given session
/// and intentionally compact — `Plan:` lines collapse uniform planned values
/// (e.g. `100kg 4 × 8`). When every executed set satisfies its planned
/// counterpart the `Done:` body collapses to `Done: as planned`; otherwise
/// it lists one executed set per row in position order.
///
/// "Satisfies" is per measurement type: rep-based and bodyweight require an
/// exact match against a fixed rep target (range targets never collapse —
/// the actuals are always shown), and time-based requires the actual
/// duration to be at least the planned duration (weight, if any, must
/// match).
abstract final class SessionExportFormatter {
  static String format(Session session, {bool includeWarmups = true}) {
    final buf = StringBuffer();
    buf.writeln(session.snapshot.workoutDay.name);

    final dateInstant = session.endedAt ?? session.startedAt;
    final local = dateInstant.isUtc ? dateInstant.toLocal() : dateInstant;
    final dateStr = DateFormatter.isoDate(local);
    if (session.endedAt == null) {
      buf.writeln(dateStr);
      buf.writeln('(in progress)');
    } else {
      final duration = session.endedAt!.difference(session.startedAt);
      if (duration > Duration.zero) {
        buf.writeln('$dateStr · ${_formatDuration(duration)}');
      } else {
        buf.writeln(dateStr);
      }
    }

    final plannedById = _plannedLookup(session.snapshot.workoutDay);
    final warmupExerciseIds = _warmupExerciseIds(session.snapshot.workoutDay);
    final ordered = [...session.sessionExercises]
      ..sort((a, b) => a.position.compareTo(b.position));
    final filtered = includeWarmups
        ? ordered
        : ordered
              .where(
                (sx) =>
                    !warmupExerciseIds.contains(sx.plannedExerciseIdInSnapshot),
              )
              .toList();

    for (final block in _groupConsecutiveBySupersetTag(filtered)) {
      buf.writeln();
      _renderBlock(buf, block, plannedById);
    }

    if (session.notes.isNotEmpty) {
      buf.writeln();
      buf.writeln('Notes:');
      for (final n in session.notes) {
        buf.writeln('- ${n.body}');
      }
    }

    if (session.extraWork.isNotEmpty) {
      buf.writeln();
      buf.writeln('Extra work:');
      for (final e in session.extraWork) {
        buf.writeln('- ${e.body}');
      }
    }

    return buf.toString().trimRight();
  }

  static Map<String, Exercise> _plannedLookup(WorkoutDay day) {
    final out = <String, Exercise>{};
    for (final g in day.exerciseGroups) {
      for (final e in g.exercises) {
        out[e.id] = e;
      }
    }
    return out;
  }

  // Renders a positive Duration as `1h 24m`, `45m`, `2h`, or `<1m` for
  // sub-minute workouts. Callers handle zero/negative.
  static String _formatDuration(Duration d) {
    if (d.inMinutes < 1) return '<1m';
    final hours = d.inHours;
    final minutes = d.inMinutes % 60;
    if (hours == 0) return '${minutes}m';
    if (minutes == 0) return '${hours}h';
    return '${hours}h ${minutes}m';
  }

  // Exercises that belong to a warmup group in the snapshot. Replaced
  // exercises inherit the slot, so substituting a warmup still excludes it.
  static Set<String> _warmupExerciseIds(WorkoutDay day) {
    final out = <String>{};
    for (final g in day.exerciseGroups) {
      if (!isWarmupGroup(g.role)) continue;
      for (final e in g.exercises) {
        out.add(e.id);
      }
    }
    return out;
  }

  /// Groups consecutive exercises that share a non-null superset tag.
  /// Singles produce a single-element block.
  static List<List<SessionExercise>> _groupConsecutiveBySupersetTag(
    List<SessionExercise> ordered,
  ) {
    final blocks = <List<SessionExercise>>[];
    for (final ex in ordered) {
      final tag = ex.supersetTag;
      if (tag != null &&
          blocks.isNotEmpty &&
          blocks.last.first.supersetTag == tag) {
        blocks.last.add(ex);
      } else {
        blocks.add([ex]);
      }
    }
    return blocks;
  }

  static void _renderBlock(
    StringBuffer buf,
    List<SessionExercise> block,
    Map<String, Exercise> plannedById,
  ) {
    if (block.length > 1) {
      final names = block.map((e) => _displayName(e, plannedById)).join(' + ');
      buf.writeln('Superset: $names');
      for (var i = 0; i < block.length; i++) {
        if (i > 0) buf.writeln();
        _renderExercise(buf, block[i], plannedById, indent: '  ');
      }
    } else {
      _renderExercise(buf, block.single, plannedById);
    }
  }

  static String _displayName(
    SessionExercise sx,
    Map<String, Exercise> plannedById,
  ) {
    final planned = plannedById[sx.plannedExerciseIdInSnapshot];
    final plannedName = planned?.name ?? '(unknown)';
    return switch (sx.state) {
      ReplacedState(:final substitute) => '$plannedName → ${substitute.name}',
      _ => plannedName,
    };
  }

  static void _renderExercise(
    StringBuffer buf,
    SessionExercise sx,
    Map<String, Exercise> plannedById, {
    String indent = '',
  }) {
    final planned = plannedById[sx.plannedExerciseIdInSnapshot];
    final state = sx.state;

    // Header line: name (+ status tag)
    final headerName = _displayName(sx, plannedById);
    final headerSuffix = switch (state) {
      SkippedState() => '  (skipped)',
      ReplacedState() => '  (replaced)',
      _ => '',
    };
    buf.writeln('$indent$headerName$headerSuffix');

    // Plan line — always show coach's planned values from snapshot.
    if (planned != null) {
      buf.writeln('${indent}Plan: ${_plannedSummary(planned)}');
    }

    // If replaced, show substitute's planned values on a second line.
    if (state is ReplacedState) {
      buf.writeln(
        '${indent}Sub plan: ${_substitutePlanSummary(state.substitute)}',
      );
    }

    final sets = [...sx.executedSets]
      ..sort((a, b) => a.position.compareTo(b.position));

    if (state is SkippedState && sets.isEmpty) {
      // No "Done:" body — header already says "(skipped)".
      return;
    }

    if (sets.isEmpty) {
      buf.writeln('${indent}Done: —');
      return;
    }

    final plan = _plannedValuesForComparison(sx, planned);
    if (plan != null && _allActualsMatchPlan(sets, plan)) {
      buf.writeln('${indent}Done: as planned');
      return;
    }

    buf.writeln('${indent}Done:');
    for (final s in sets) {
      buf.writeln('$indent${_renderExecutedSet(s)}');
    }
  }

  /// Returns the per-set planned values to compare actuals against, or
  /// `null` when no plan is available (e.g. snapshot lookup missed).
  /// For replaced exercises the substitute's uniform plan is expanded to
  /// `setCount` entries; otherwise the snapshot's planned sets are used in
  /// position order.
  static List<PlannedSetValues>? _plannedValuesForComparison(
    SessionExercise sx,
    Exercise? planned,
  ) {
    final state = sx.state;
    if (state is ReplacedState) {
      return List<PlannedSetValues>.filled(
        state.substitute.setCount,
        state.substitute.plannedValues,
      );
    }
    if (planned == null) return null;
    final sorted = [...planned.sets]
      ..sort((a, b) => a.position.compareTo(b.position));
    return [for (final s in sorted) s.plannedValues];
  }

  static bool _allActualsMatchPlan(
    List<ExecutedSet> actuals,
    List<PlannedSetValues> plan,
  ) {
    if (actuals.length != plan.length) return false;
    for (var i = 0; i < actuals.length; i++) {
      if (!_setMatches(actuals[i].actualValues, plan[i])) return false;
    }
    return true;
  }

  static bool _setMatches(ActualSetValues actual, PlannedSetValues plan) {
    return switch ((plan, actual)) {
      (
        PlannedRepBased(weightKg: final pKg, repTarget: final target),
        ActualRepBased(weightKg: final aKg, reps: final aReps),
      ) =>
        pKg == aKg && _repTargetSatisfied(target, aReps),
      (
        PlannedTimeBased(durationSeconds: final pSec, weightKg: final pKg),
        ActualTimeBased(durationSeconds: final aSec, weightKg: final aKg),
      ) =>
        aSec >= pSec && pKg == aKg,
      (
        PlannedBodyweight(repTarget: final target),
        ActualBodyweight(reps: final aReps),
      ) =>
        _repTargetSatisfied(target, aReps),
      _ => false,
    };
  }

  // Range rep targets always render actuals — the coach wants to see where
  // in the range you landed.
  static bool _repTargetSatisfied(RepTarget target, int actualReps) {
    return switch (target) {
      RepTargetFixed(:final reps) => reps == actualReps,
      RepTargetRange() => false,
    };
  }

  static String _renderExecutedSet(ExecutedSet s) {
    return switch (s.actualValues) {
      ActualRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)} × $reps',
      ActualTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)} × ${durationSeconds}s',
      ActualBodyweight(:final reps) => '$reps reps',
    };
  }

  /// Compact plan summary for the snapshot's planned values.
  /// Mirrors the UI's planned summary formatter but lives in domain so
  /// the export pipeline is pure Dart.
  static String _plannedSummary(Exercise planned) {
    final sets = [...planned.sets]
      ..sort((a, b) => a.position.compareTo(b.position));
    if (sets.isEmpty) return '0 sets';
    final first = sets.first.plannedValues;
    final allSame = sets.every((s) => s.plannedValues == first);

    if (!allSame) {
      // Fall back to listing per-set planned values inline.
      return sets.map(_renderPlannedValues).join(', ');
    }
    return switch (first) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${sets.length} × ${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${sets.length} × ${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '${sets.length} × ${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '${sets.length} × ${RepTargetFormatter.format(repTarget)}',
    };
  }

  static String _renderPlannedValues(WorkoutSet s) {
    return switch (s.plannedValues) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg × ${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '× ${RepTargetFormatter.format(repTarget)}',
    };
  }

  static String _substitutePlanSummary(SubstituteExercise sub) {
    return switch (sub.plannedValues) {
      PlannedRepBased(:final weightKg, :final repTarget) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${sub.setCount} × ${RepTargetFormatter.format(repTarget)}',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${sub.setCount} × ${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '${sub.setCount} × ${durationSeconds}s',
      PlannedBodyweight(:final repTarget) =>
        '${sub.setCount} × ${RepTargetFormatter.format(repTarget)}',
    };
  }
}
