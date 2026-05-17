import 'package:zamaj/modules/domain/models/rep_target.dart';
import 'package:zamaj/modules/program_management/services/text_plan/parse_result.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_draft.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_error.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

abstract final class TextPlanParser {
  static ParseResult parse(String input) {
    if (input.length > 100000) {
      return const ParseResult.failure(
        PlanParseError(
          line: 1,
          column: 1,
          code: PlanParseErrorCode.inputTooLarge,
          message:
              'Input exceeds the maximum allowed size of 100,000 characters.',
        ),
      );
    }

    if (input.trim().isEmpty) {
      return const ParseResult.failure(
        PlanParseError(
          line: 1,
          column: 1,
          code: PlanParseErrorCode.emptyInput,
          message: 'Input is empty or contains only whitespace.',
        ),
      );
    }

    final lines = _splitLines(input);
    return _parseLines(lines);
  }
}

List<String> _splitLines(String input) {
  final result = <String>[];
  var start = 0;
  for (var i = 0; i < input.length; i++) {
    if (input[i] == '\r' && i + 1 < input.length && input[i + 1] == '\n') {
      result.add(input.substring(start, i));
      start = i + 2;
      i++;
    } else if (input[i] == '\n') {
      result.add(input.substring(start, i));
      start = i + 1;
    }
  }
  result.add(input.substring(start));
  return result;
}

ParseResult _parseLines(List<String> lines) {
  String? programName;
  final days = <_DayScope>[];
  _DayScope? currentDay;
  _GroupScope? currentGroup;

  for (var i = 0; i < lines.length; i++) {
    final lineNumber = i + 1;
    final rawLine = lines[i];
    final trimmed = rawLine.trim();

    if (trimmed.isEmpty) {
      _closeGroupIfOpen(currentDay, currentGroup);
      currentGroup = null;
      continue;
    }

    if (programName == null &&
        !_isDayHeader(trimmed) &&
        !_isSupersetMarker(trimmed) &&
        !_isSetLine(trimmed)) {
      programName = trimmed;
      continue;
    }

    final classification = _classify(trimmed, currentDay != null);

    switch (classification) {
      case _DayHeaderClassification(:final name):
        _closeGroupIfOpen(currentDay, currentGroup);
        currentGroup = null;
        currentDay = _DayScope(name: name);
        days.add(currentDay);

      case _SupersetMarkerClassification():
        if (currentDay == null) {
          final col = _firstNonWhitespaceColumn(rawLine);
          return ParseResult.failure(
            PlanParseError(
              line: lineNumber,
              column: col,
              code: PlanParseErrorCode.orphanSupersetMarker,
              message:
                  'Superset marker found outside of a workout day on line $lineNumber.',
            ),
          );
        }
        _closeGroupIfOpen(currentDay, currentGroup);
        currentGroup = _GroupScope(isSuperset: true);
        currentDay.groups.add(currentGroup);

      case _SetLineClassification(:final tokens):
        if (currentDay == null) {
          final col = _firstNonWhitespaceColumn(rawLine);
          return ParseResult.failure(
            PlanParseError(
              line: lineNumber,
              column: col,
              code: PlanParseErrorCode.orphanSetLine,
              message:
                  'Planned-set line found outside of a workout day on line $lineNumber.',
            ),
          );
        }
        if (currentGroup == null || currentGroup.exercises.isEmpty) {
          final col = _firstNonWhitespaceColumn(rawLine);
          return ParseResult.failure(
            PlanParseError(
              line: lineNumber,
              column: col,
              code: PlanParseErrorCode.orphanSetLine,
              message:
                  'Planned-set line found with no current exercise on line $lineNumber.',
            ),
          );
        }
        _attachPlannedSet(
          currentGroup.exercises.last,
          tokens,
          lineNumber,
          rawLine,
        );

      case _ExerciseNameClassification(:final name):
        if (currentDay == null) {
          final col = _firstNonWhitespaceColumn(rawLine);
          return ParseResult.failure(
            PlanParseError(
              line: lineNumber,
              column: col,
              code: PlanParseErrorCode.missingWorkoutDay,
              message:
                  'Exercise name found outside of a workout day on line $lineNumber.',
            ),
          );
        }
        if (currentGroup == null) {
          currentGroup = _GroupScope(isSuperset: false);
          currentDay.groups.add(currentGroup);
        }
        final dayIndex = days.length - 1;
        final groupIndex = currentDay.groups.length - 1;
        final exerciseIndex = currentGroup.exercises.length;
        final draftId = 'exercise_${dayIndex}_${groupIndex}_$exerciseIndex';
        currentGroup.exercises.add(
          _ExerciseScope(name: name, draftId: draftId),
        );

      case _UnknownClassification():
        final col = _firstNonWhitespaceColumn(rawLine);
        return ParseResult.failure(
          PlanParseError(
            line: lineNumber,
            column: col,
            code: PlanParseErrorCode.unknownLine,
            message: 'Unrecognized line at line $lineNumber.',
          ),
        );
    }
  }

  if (programName == null) {
    return const ParseResult.failure(
      PlanParseError(
        line: 1,
        column: 1,
        code: PlanParseErrorCode.missingProgramName,
        message: 'No program name found in the input.',
      ),
    );
  }

  if (days.isEmpty) {
    return const ParseResult.failure(
      PlanParseError(
        line: 1,
        column: 1,
        code: PlanParseErrorCode.missingProgramName,
        message: 'No workout days found in the input.',
      ),
    );
  }

  final allWarnings = <PlanParseWarning>[];
  final draftDays = days.map((day) {
    final draftGroups = day.groups.map((group) {
      final draftExercises = group.exercises.map((exercise) {
        allWarnings.addAll(exercise.warnings);
        return PlanDraftExercise(
          draftId: exercise.draftId,
          name: exercise.name,
          plannedRestSeconds: exercise.plannedRestSeconds,
          notes: null,
          videoUrl: null,
          sets: exercise.sets,
          warnings: exercise.warnings,
        );
      }).toList();
      return PlanDraftGroup(exercises: draftExercises);
    }).toList();
    return PlanDraftWorkoutDay(name: day.name, groups: draftGroups);
  }).toList();

  final draft = PlanDraft(programName: programName, workoutDays: draftDays);
  return ParseResult.success(draft: draft, warnings: allWarnings);
}

void _closeGroupIfOpen(_DayScope? currentDay, _GroupScope? currentGroup) {}

bool _isDayHeader(String trimmed) {
  final lower = trimmed.toLowerCase();
  return lower == 'day' ||
      lower.startsWith('day ') ||
      lower.startsWith('day\t');
}

bool _isSupersetMarker(String trimmed) {
  final lower = trimmed.toLowerCase();
  return lower == 'ss' ||
      lower.startsWith('ss ') ||
      lower.startsWith('ss\t') ||
      lower.startsWith('ss:') ||
      lower == 'superset' ||
      lower.startsWith('superset ') ||
      lower.startsWith('superset\t') ||
      lower.startsWith('superset:') ||
      lower == 'super-set' ||
      lower.startsWith('super-set ') ||
      lower.startsWith('super-set\t') ||
      lower.startsWith('super-set:');
}

bool _isSetLine(String trimmed) {
  final firstToken = trimmed.split(RegExp(r'[ \t]+')).first;
  return _setsByRepsPattern.hasMatch(firstToken) ||
      _setsByTimePattern.hasMatch(firstToken);
}

final _setsByRepsPattern = RegExp(r'^\d+[xX×]\d+(?:[-–]\d+)?$');
final _setsByTimePattern = RegExp(r'^\d+[xX×]\d+[sS]$');

sealed class _Classification {}

final class _DayHeaderClassification extends _Classification {
  final String name;
  _DayHeaderClassification(this.name);
}

final class _SupersetMarkerClassification extends _Classification {}

final class _SetLineClassification extends _Classification {
  final List<String> tokens;
  _SetLineClassification(this.tokens);
}

final class _ExerciseNameClassification extends _Classification {
  final String name;
  _ExerciseNameClassification(this.name);
}

final class _UnknownClassification extends _Classification {}

_Classification _classify(String trimmed, bool hasDayScope) {
  if (_isDayHeader(trimmed)) {
    final lower = trimmed.toLowerCase();
    String name;
    if (lower == 'day') {
      name = '';
    } else {
      name = trimmed.substring(3).trim();
    }
    return _DayHeaderClassification(name);
  }

  if (_isSupersetMarker(trimmed)) {
    return _SupersetMarkerClassification();
  }

  final tokens = trimmed.split(RegExp(r'[ \t]+'));
  if (_setsByRepsPattern.hasMatch(tokens.first) ||
      _setsByTimePattern.hasMatch(tokens.first)) {
    return _SetLineClassification(tokens);
  }

  if (hasDayScope) {
    return _ExerciseNameClassification(trimmed);
  }

  return _UnknownClassification();
}

void _attachPlannedSet(
  _ExerciseScope exercise,
  List<String> tokens,
  int lineNumber,
  String rawLine,
) {
  final setToken = tokens.first;
  final multMatch = RegExp(
    r'^(\d+)([xX×])(\d+)(?:[-–](\d+))?$',
  ).firstMatch(setToken);
  final timeMatch = RegExp(r'^(\d+)([xX×])(\d+)[sS]$').firstMatch(setToken);

  if (multMatch == null && timeMatch == null) return;

  if (timeMatch != null) {
    final count = int.parse(timeMatch.group(1)!);
    final durationSeconds = int.parse(timeMatch.group(3)!);
    var remaining = tokens.skip(1).toList();
    double? weightKg;
    if (remaining.isNotEmpty) {
      final weightMatch = RegExp(
        r'^(\d+(?:\.\d+)?)[kK][gG]$',
      ).firstMatch(remaining.first);
      if (weightMatch != null) {
        weightKg = double.parse(weightMatch.group(1)!);
        remaining = remaining.skip(1).toList();
      }
    }
    final restResult = _parseRestTokens(
      remaining,
      lineNumber,
      rawLine,
      exercise.draftId,
    );
    exercise.sets.add(
      PlanDraftSet.timeBased(
        count: count,
        durationSeconds: durationSeconds,
        weightKg: weightKg,
      ),
    );
    if (restResult.restSeconds != null) {
      exercise.plannedRestSeconds = restResult.restSeconds;
    }
    exercise.warnings.addAll(restResult.warnings);
    return;
  }

  final count = int.parse(multMatch!.group(1)!);
  final rhsMin = int.parse(multMatch.group(3)!);
  final rhsMaxStr = multMatch.group(4);
  final rhsMax = rhsMaxStr != null ? int.parse(rhsMaxStr) : null;
  final repTarget = rhsMax == null || rhsMax == rhsMin
      ? RepTarget.fixed(reps: rhsMin)
      : (rhsMax > rhsMin
            ? RepTarget.range(minReps: rhsMin, maxReps: rhsMax)
            : null);

  if (repTarget == null) {
    // Malformed range (max < min) — surface as a parse warning and skip.
    exercise.warnings.add(
      PlanParseWarning(
        line: lineNumber,
        column: _columnOfToken(rawLine, setToken),
        code: PlanParseWarningCode.unrecognizedTrailingToken,
        offendingToken: setToken,
        exerciseDraftId: exercise.draftId,
      ),
    );
    return;
  }

  final remaining = tokens.skip(1).toList();

  PlanDraftSet? parsedSet;
  int? restSeconds;
  final warnings = <PlanParseWarning>[];

  if (remaining.isNotEmpty) {
    final secondToken = remaining.first;
    final weightMatch = RegExp(
      r'^(\d+(?:\.\d+)?)[kK][gG]$',
    ).firstMatch(secondToken);
    final durationMatch = RegExp(r'^(\d+)[sS]$').firstMatch(secondToken);

    if (weightMatch != null) {
      final weight = double.parse(weightMatch.group(1)!);
      parsedSet = PlanDraftSet.repBased(
        count: count,
        repTarget: repTarget,
        weightKg: weight,
      );
      final trailingTokens = remaining.skip(1).toList();
      final restResult = _parseRestTokens(
        trailingTokens,
        lineNumber,
        rawLine,
        exercise.draftId,
      );
      restSeconds = restResult.restSeconds;
      warnings.addAll(restResult.warnings);
    } else if (durationMatch != null) {
      final duration = int.parse(durationMatch.group(1)!);
      var trailingTokens = remaining.skip(1).toList();
      double? timeWeight;
      if (trailingTokens.isNotEmpty) {
        final weightMatch2 = RegExp(
          r'^(\d+(?:\.\d+)?)[kK][gG]$',
        ).firstMatch(trailingTokens.first);
        if (weightMatch2 != null) {
          timeWeight = double.parse(weightMatch2.group(1)!);
          trailingTokens = trailingTokens.skip(1).toList();
        }
      }
      parsedSet = PlanDraftSet.timeBased(
        count: count,
        durationSeconds: duration,
        weightKg: timeWeight,
      );
      final restResult = _parseRestTokens(
        trailingTokens,
        lineNumber,
        rawLine,
        exercise.draftId,
      );
      restSeconds = restResult.restSeconds;
      warnings.addAll(restResult.warnings);
    } else {
      parsedSet = PlanDraftSet.repBased(
        count: count,
        repTarget: repTarget,
        weightKg: 0.0,
      );
      final restResult = _parseRestTokens(
        remaining,
        lineNumber,
        rawLine,
        exercise.draftId,
      );
      restSeconds = restResult.restSeconds;
      warnings.addAll(restResult.warnings);
    }
  } else {
    parsedSet = PlanDraftSet.repBased(
      count: count,
      repTarget: repTarget,
      weightKg: 0.0,
    );
  }

  exercise.sets.add(parsedSet);
  if (restSeconds != null) {
    exercise.plannedRestSeconds = restSeconds;
  }
  exercise.warnings.addAll(warnings);
}

class _RestParseResult {
  final int? restSeconds;
  final List<PlanParseWarning> warnings;
  _RestParseResult({required this.restSeconds, required this.warnings});
}

_RestParseResult _parseRestTokens(
  List<String> tokens,
  int lineNumber,
  String rawLine,
  String exerciseDraftId,
) {
  int? restSeconds;
  final warnings = <PlanParseWarning>[];

  for (final token in tokens) {
    final restMatch = RegExp(r'^(\d+)([sSmM])$').firstMatch(token);
    if (restMatch != null) {
      final value = int.parse(restMatch.group(1)!);
      final unit = restMatch.group(2)!.toLowerCase();
      if (value >= 1 && value <= 3600) {
        if (restSeconds != null) {
          final col = _columnOfToken(rawLine, token);
          warnings.add(
            PlanParseWarning(
              line: lineNumber,
              column: col,
              code: PlanParseWarningCode.invalidRestToken,
              offendingToken: token,
              exerciseDraftId: exerciseDraftId,
            ),
          );
        }
        restSeconds = unit == 'm' ? value * 60 : value;
      } else {
        final col = _columnOfToken(rawLine, token);
        warnings.add(
          PlanParseWarning(
            line: lineNumber,
            column: col,
            code: PlanParseWarningCode.invalidRestToken,
            offendingToken: token,
            exerciseDraftId: exerciseDraftId,
          ),
        );
      }
    } else {
      final col = _columnOfToken(rawLine, token);
      warnings.add(
        PlanParseWarning(
          line: lineNumber,
          column: col,
          code: PlanParseWarningCode.unrecognizedTrailingToken,
          offendingToken: token,
          exerciseDraftId: exerciseDraftId,
        ),
      );
    }
  }

  return _RestParseResult(restSeconds: restSeconds, warnings: warnings);
}

int _firstNonWhitespaceColumn(String rawLine) {
  for (var i = 0; i < rawLine.length; i++) {
    if (rawLine[i] != ' ' && rawLine[i] != '\t') {
      return i + 1;
    }
  }
  return 1;
}

int _columnOfToken(String rawLine, String token) {
  final idx = rawLine.indexOf(token);
  return idx >= 0 ? idx + 1 : 1;
}

class _DayScope {
  final String name;
  final List<_GroupScope> groups = [];
  _DayScope({required this.name});
}

class _GroupScope {
  final bool isSuperset;
  final List<_ExerciseScope> exercises = [];
  _GroupScope({required this.isSuperset});
}

class _ExerciseScope {
  final String name;
  final String draftId;
  int? plannedRestSeconds;
  final List<PlanDraftSet> sets = [];
  final List<PlanParseWarning> warnings = [];
  _ExerciseScope({required this.name, required this.draftId});
}
