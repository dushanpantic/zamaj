import 'package:zamaj/modules/domain/errors.dart';
import 'package:zamaj/modules/domain/models/planned_set_values.dart';
import 'package:zamaj/modules/domain/models/program_aggregate.dart';
import 'package:zamaj/modules/domain/models/rep_target.dart';

/// The single source of truth for program-authoring numeric and text bounds.
///
/// Each `check*` validator throws a [ValidationError] whose `invariant` carries
/// a stable error code (the same code the program-authoring UI maps to its own
/// messages). The aggregate constructors deliberately do **not** enforce these
/// bounds, so legacy out-of-range rows still load; enforcement happens only at
/// the write path via [validateAggregate].
abstract final class ProgramRules {
  static const double weightMaxKg = 1000;
  static const int repsMax = 999;
  static const int durationMaxSeconds = 3600;
  static const int restMaxSeconds = 3600;
  static const int setCountMin = 1;
  static const int setCountMax = 20;
  static const int exerciseNameMaxLength = 80;
  static const int workoutDayNameMaxLength = 100;
  static const int programNameMaxLength = 100;
  static const int videoUrlMaxLength = 2048;
  static const int notesMaxLength = 2000;

  static Never _reject(String code, String message) => throw ValidationError(
    entityId: 'ProgramRules',
    invariant: code,
    message: message,
  );

  static void checkWeightKg(double weightKg) {
    if (weightKg < 0 || weightKg > weightMaxKg) {
      _reject(
        'weight_out_of_range',
        'weight must be in [0, $weightMaxKg], got $weightKg',
      );
    }
    final remainder = (weightKg * 2).round() - (weightKg * 2);
    if (remainder.abs() > 1e-9) {
      _reject(
        'weight_not_half_kg',
        'weight must be a multiple of 0.5 kg, got $weightKg',
      );
    }
  }

  static void checkReps(int reps) {
    if (reps < 0 || reps > repsMax) {
      _reject('reps_out_of_range', 'reps must be in [0, $repsMax], got $reps');
    }
  }

  static void checkRepTarget(RepTarget target) {
    switch (target) {
      case RepTargetFixed(:final reps):
        checkReps(reps);
      case RepTargetRange(:final minReps, :final maxReps):
        checkReps(minReps);
        checkReps(maxReps);
    }
  }

  static void checkDurationSeconds(int seconds) {
    if (seconds < 0 || seconds > durationMaxSeconds) {
      _reject(
        'duration_out_of_range',
        'duration must be in [0, $durationMaxSeconds], got $seconds',
      );
    }
  }

  static void checkRestSeconds(int seconds) {
    if (seconds < 0 || seconds > restMaxSeconds) {
      _reject(
        'rest_out_of_range',
        'rest must be in [0, $restMaxSeconds], got $seconds',
      );
    }
  }

  static void checkSetCount(int count) {
    if (count < setCountMin) {
      _reject('set_count_too_low', 'set count must be >= $setCountMin');
    }
    if (count > setCountMax) {
      _reject('set_count_too_high', 'set count must be <= $setCountMax');
    }
  }

  static void checkExerciseName(String name) =>
      _checkName(name, exerciseNameMaxLength);

  static void checkWorkoutDayName(String name) =>
      _checkName(name, workoutDayNameMaxLength);

  static void checkProgramName(String name) =>
      _checkName(name, programNameMaxLength);

  static void _checkName(String name, int maxLength) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) {
      _reject('name_too_short', 'name must not be empty');
    }
    if (trimmed.length > maxLength) {
      _reject('name_too_long', 'name must be <= $maxLength characters');
    }
  }

  static void checkVideoUrl(String? input) {
    if (input == null) return;
    final trimmed = input.trim();
    if (trimmed.isEmpty) return;
    if (trimmed.length > videoUrlMaxLength) {
      _reject('url_too_long', 'video url must be <= $videoUrlMaxLength chars');
    }
    final uri = Uri.tryParse(trimmed);
    if (uri == null || !uri.isAbsolute) {
      _reject('url_not_absolute', 'video url must be absolute');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      _reject('url_scheme_not_http_https', 'video url scheme must be http(s)');
    }
  }

  static void checkNotes(String? input) {
    if (input == null) return;
    if (input.length > notesMaxLength) {
      _reject('notes_too_long', 'notes must be <= $notesMaxLength characters');
    }
  }

  /// Validates every numeric and text bound across [aggregate] at the write
  /// path. Throws on the first violation. Reads never call this — only saves.
  static void validateAggregate(ProgramAggregate aggregate) {
    checkProgramName(aggregate.name);
    for (final day in aggregate.workoutDays) {
      checkWorkoutDayName(day.name);
      for (final group in day.groups) {
        for (final exercise in group.exercises) {
          checkExerciseName(exercise.name);
          // Note: set-count cardinality (1..20) is a manual-editor UX cap
          // (see [checkSetCount], used by the program-authoring UI), not a
          // persisted-data range bound — the text-plan import path may
          // legitimately exceed it, so it is intentionally not enforced here.
          final rest = exercise.plannedRestSeconds;
          if (rest != null) checkRestSeconds(rest);
          checkNotes(exercise.metadata.notes);
          checkVideoUrl(exercise.metadata.videoUrl);
          for (final set in exercise.sets) {
            _checkPlannedValues(set.values);
          }
        }
      }
    }
  }

  static void _checkPlannedValues(PlannedSetValues values) {
    switch (values) {
      case PlannedRepBased(:final weightKg, :final repTarget):
        checkWeightKg(weightKg);
        checkRepTarget(repTarget);
      case PlannedTimeBased(:final durationSeconds, :final weightKg):
        checkDurationSeconds(durationSeconds);
        if (weightKg != null) checkWeightKg(weightKg);
      case PlannedBodyweight(:final repTarget):
        checkRepTarget(repTarget);
    }
  }
}
