import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/session_exercise.dart';
import 'package:zamaj/modules/domain/models/workout_day.dart';
import 'package:zamaj/modules/domain/models/workout_set.dart';
import 'package:zamaj/modules/domain/services/exercise_outcome.dart';
import 'package:zamaj/modules/domain/services/warmup_exercises.dart';

/// Renders a [Session] to plain text suitable for sharing to a coach via
/// WhatsApp / SMS / email.
///
/// Pure Dart. No locale, no IO. The output is stable for a given session
/// and intentionally compact — `Plan:` lines collapse uniform planned values
/// (e.g. `100kg 4 × 8`). When every executed set carries identical values
/// the `Done:` body uses the same compact shape (e.g. `Done: 40kg 4 × 10`);
/// otherwise each set is rendered on its own row with its unit
/// (e.g. `100kg × 8`, `30s`, `40kg × 30s`, `10 reps`).
abstract final class SessionExportFormatter {
  static String format(Session session, {bool includeWarmups = true}) {
    final buf = StringBuffer();
    final dayName = session.snapshot.workoutDay.name;
    buf.writeln(session.isDeload ? '$dayName (DELOAD)' : dayName);

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
    final warmupExerciseIds = warmupExerciseIdsIn(session.snapshot.workoutDay);
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
    return planned?.name ?? '(unknown)';
  }

  static void _renderExercise(
    StringBuffer buf,
    SessionExercise sx,
    Map<String, Exercise> plannedById, {
    String indent = '',
  }) {
    final planned = plannedById[sx.plannedExerciseIdInSnapshot];
    final state = sx.state;

    // Outcome is derived from the logged-set record, not the stored
    // discriminator: an exercise ended early lands on `skipped` but reads as
    // partial, and a legacy marked-done-early row stored as `completed` reads
    // as partial too. An unfinished exercise (only seen in an in-progress
    // export) carries no verdict suffix.
    final executedCount = sx.executedSets.length;
    final plannedCount = planned?.sets.length ?? 0;
    final outcome = ExerciseOutcomes.of(
      state: state,
      executedSetCount: executedCount,
      plannedSetCount: plannedCount,
    );

    // Header line: name (+ derived status tag)
    final headerName = _displayName(sx, plannedById);
    final headerSuffix = state is UnfinishedState
        ? ''
        : switch (outcome) {
            ExerciseOutcome.completed => '',
            ExerciseOutcome.partial => '  ($executedCount/$plannedCount sets)',
            ExerciseOutcome.skipped => '  (skipped)',
            ExerciseOutcome.replaced => '  (replaced)',
          };
    buf.writeln('$indent$headerName$headerSuffix');

    // Plan line — always show coach's planned values from snapshot.
    if (planned != null) {
      buf.writeln('${indent}Plan: ${_plannedSummary(planned)}');
    }

    final sets = [...sx.executedSets]
      ..sort((a, b) => a.position.compareTo(b.position));

    if (state is! UnfinishedState && outcome == ExerciseOutcome.skipped) {
      // No "Done:" body — header already says "(skipped)". Unfinished is
      // excluded so an in-progress, untouched exercise still renders "Done: —".
      return;
    }

    if (sets.isEmpty) {
      buf.writeln('${indent}Done: —');
      return;
    }

    final uniform = _uniformActualsSummary(sets);
    if (uniform != null) {
      buf.writeln('${indent}Done: $uniform');
      return;
    }

    buf.writeln('${indent}Done:');
    for (final s in sets) {
      buf.writeln('$indent${_renderExecutedSet(s)}');
    }
  }

  // When every executed set has identical [ActualSetValues], collapse to
  // one line matching the planned-summary shape (e.g. `40kg 4 × 10`).
  // Returns null when the sets differ — callers fall back to per-set rows.
  static String? _uniformActualsSummary(List<ExecutedSet> sets) {
    if (sets.isEmpty) return null;
    final first = sets.first.actualValues;
    for (final s in sets.skip(1)) {
      if (s.actualValues != first) return null;
    }
    final count = sets.length;
    return switch (first) {
      ActualRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg $count × $reps',
      ActualTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '$count × ${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '$count × ${durationSeconds}s',
      ActualBodyweight(:final reps) => '$count × $reps',
    };
  }

  static String _renderExecutedSet(ExecutedSet s) {
    return switch (s.actualValues) {
      ActualRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg × $reps',
      ActualTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
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

}
