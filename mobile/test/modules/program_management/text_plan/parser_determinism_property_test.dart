// Validates: Requirements R10 AC2

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/services/text_plan/text_plan_parser.dart';

import '../../../support/program_management_generators.dart';

void main() {
  const iterations = 100;

  test(
    'Property 2: parser determinism — same input always produces same ParseResult',
    () {
      final rng = Random(42);
      for (var i = 0; i < iterations; i++) {
        final text = anyPlanText(rng);
        final first = TextPlanParser.parse(text);
        final second = TextPlanParser.parse(text);
        expect(
          first,
          equals(second),
          reason: 'iteration $i: text=${text.replaceAll('\n', '\\n')}',
        );
      }
    },
  );
}
