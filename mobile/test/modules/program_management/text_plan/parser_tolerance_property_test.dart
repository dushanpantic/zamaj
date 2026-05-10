// **Validates: Requirements R10 AC3**

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/services/text_plan/text_plan_parser.dart';

import '../../../support/program_management_generators.dart';

void main() {
  const iterations = 100;

  test(
    'Property 3: tolerance invariants — parse(P) == parse(P\') for surface variations',
    () {
      final rng = Random(20240101);

      for (var i = 0; i < iterations; i++) {
        final seed = rng.nextInt(1 << 30);
        final iterRng = Random(seed);

        final p = anyValidPlanText(iterRng);
        final pPrime = _applyRandomToleranceTransformations(
          p,
          Random(seed + 1),
        );

        final resultP = TextPlanParser.parse(p);
        final resultPPrime = TextPlanParser.parse(pPrime);

        if (resultP != resultPPrime) {
          fail(
            'Iteration $i failed.\n'
            'Seed: $seed\n'
            'P:\n$p\n\n'
            'P\':\n$pPrime\n\n'
            'parse(P): $resultP\n'
            'parse(P\'): $resultPPrime',
          );
        }
      }
    },
  );
}

/// Applies a random combination of tolerance-preserving surface transformations
/// to [input], producing a text that the parser should parse identically.
String _applyRandomToleranceTransformations(String input, Random rng) {
  final lines = _splitLines(input);
  final transformed = lines.map((line) => _transformLine(line, rng)).toList();
  final lineEnding = _pickLineEnding(rng);
  return transformed.join(lineEnding);
}

/// Splits on \r\n and \n (matching the parser's own _splitLines logic).
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

String _pickLineEnding(Random rng) => rng.nextBool() ? '\n' : '\r\n';

String _transformLine(String line, Random rng) {
  final trimmed = line.trim();

  if (trimmed.isEmpty) {
    return _addLeadingTrailingWhitespace('', rng);
  }

  final lower = trimmed.toLowerCase();

  if (_isDayHeader(lower)) {
    return _addLeadingTrailingWhitespace(
      _transformDayHeader(trimmed, rng),
      rng,
    );
  }

  if (_isSupersetMarker(lower)) {
    return _addLeadingTrailingWhitespace(
      _transformSupersetMarker(trimmed, rng),
      rng,
    );
  }

  if (_isSetLine(trimmed)) {
    return _addLeadingTrailingWhitespace(_transformSetLine(trimmed, rng), rng);
  }

  return _addLeadingTrailingWhitespace(trimmed, rng);
}

bool _isDayHeader(String lower) {
  return lower == 'day' ||
      lower.startsWith('day ') ||
      lower.startsWith('day\t');
}

bool _isSupersetMarker(String lower) {
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
  return RegExp(r'^\d+[xX×]\d+$').hasMatch(firstToken);
}

String _addLeadingTrailingWhitespace(String s, Random rng) {
  final leading = rng.nextBool() ? ' ' * (1 + rng.nextInt(3)) : '';
  final trailing = rng.nextBool() ? ' ' * (1 + rng.nextInt(3)) : '';
  return '$leading$s$trailing';
}

String _transformDayHeader(String line, Random rng) {
  final rest = line.substring(3).trim();
  final keyword = _randomCaseVariant('day', rng);
  if (rest.isEmpty) return keyword;
  final sep = _randomWhitespaceSep(rng);
  return '$keyword$sep$rest';
}

String _transformSupersetMarker(String line, Random rng) {
  final lower = line.toLowerCase();
  if (lower.startsWith('super-set')) {
    final keyword = _randomCaseVariant('super-set', rng);
    final suffix = _supersetSuffix(line, 9);
    return '$keyword$suffix';
  }
  if (lower.startsWith('superset')) {
    final keyword = _randomCaseVariant('superset', rng);
    final suffix = _supersetSuffix(line, 8);
    return '$keyword$suffix';
  }
  final keyword = _randomCaseVariant('ss', rng);
  final suffix = _supersetSuffix(line, 2);
  return '$keyword$suffix';
}

String _supersetSuffix(String line, int keywordLen) {
  if (line.length <= keywordLen) return '';
  final after = line.substring(keywordLen);
  if (after.startsWith(':')) return ':';
  return '';
}

String _transformSetLine(String line, Random rng) {
  final tokens = line.split(RegExp(r'[ \t]+'));
  final transformed = tokens.map((t) => _transformToken(t, rng)).toList();
  final sep = _randomWhitespaceSep(rng);
  return transformed.join(sep);
}

String _transformToken(String token, Random rng) {
  final multMatch = RegExp(r'^(\d+)([xX×])(\d+)$').firstMatch(token);
  if (multMatch != null) {
    final lhs = multMatch.group(1)!;
    final rhs = multMatch.group(3)!;
    final sign = _randomMultSign(rng);
    return '$lhs$sign$rhs';
  }

  final weightMatch = RegExp(r'^(\d+(?:\.\d+)?)[kK][gG]$').firstMatch(token);
  if (weightMatch != null) {
    final num = weightMatch.group(1)!;
    final suffix = _randomCaseVariant('kg', rng);
    return '$num$suffix';
  }

  final restSecMatch = RegExp(r'^(\d+)[sS]$').firstMatch(token);
  if (restSecMatch != null) {
    final num = restSecMatch.group(1)!;
    final suffix = _randomCaseVariant('s', rng);
    return '$num$suffix';
  }

  final restMinMatch = RegExp(r'^(\d+)[mM]$').firstMatch(token);
  if (restMinMatch != null) {
    final num = restMinMatch.group(1)!;
    final suffix = _randomCaseVariant('m', rng);
    return '$num$suffix';
  }

  return token;
}

String _randomCaseVariant(String word, Random rng) {
  switch (rng.nextInt(3)) {
    case 0:
      return word.toLowerCase();
    case 1:
      return word.toUpperCase();
    default:
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
  }
}

String _randomMultSign(Random rng) {
  switch (rng.nextInt(3)) {
    case 0:
      return 'x';
    case 1:
      return 'X';
    default:
      return '×';
  }
}

String _randomWhitespaceSep(Random rng) {
  final spaces = 1 + rng.nextInt(3);
  return ' ' * spaces;
}
