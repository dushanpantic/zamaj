import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/models/actual_set_values.dart';
import 'package:zamaj/modules/domain/models/executed_set.dart';
import 'package:zamaj/modules/domain/models/exercise.dart';
import 'package:zamaj/modules/domain/models/exercise_state.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
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
/// (e.g. `100kg 4 × 8`), and `Done:` lines show one executed set per row in
/// position order.
abstract final class SessionExportFormatter {
  static String format(Session session) {
    final buf = StringBuffer();
    buf.writeln(session.snapshot.workoutDay.name);

    final dateInstant = session.endedAt ?? session.startedAt;
    final local = dateInstant.isUtc ? dateInstant.toLocal() : dateInstant;
    buf.writeln(DateFormatter.isoDate(local));
    if (session.endedAt == null) {
      buf.writeln('(in progress)');
    }

    final plannedById = _plannedLookup(session.snapshot.workoutDay);
    final ordered = [...session.sessionExercises]
      ..sort((a, b) => a.position.compareTo(b.position));

    for (final block in _groupConsecutiveBySupersetTag(ordered)) {
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

    buf.writeln('${indent}Done:');
    for (final s in sets) {
      buf.writeln('$indent${_renderExecutedSet(s)}');
    }
  }

  static String _renderExecutedSet(ExecutedSet s) {
    return switch (s.actualValues) {
      ActualRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)} × $reps',
      ActualTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)} × ${durationSeconds}s',
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
      PlannedRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${sets.length} × $reps',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${sets.length} × ${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '${sets.length} × ${durationSeconds}s',
    };
  }

  static String _renderPlannedValues(WorkoutSet s) {
    return switch (s.plannedValues) {
      PlannedRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg × $reps',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
    };
  }

  static String _substitutePlanSummary(SubstituteExercise sub) {
    return switch (sub.plannedValues) {
      PlannedRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg ${sub.setCount} × $reps',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${sub.setCount} × ${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg '
                  '${sub.setCount} × ${durationSeconds}s',
    };
  }

}
