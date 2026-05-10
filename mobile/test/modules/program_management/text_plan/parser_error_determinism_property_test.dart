// Validates: Requirement R10 AC5

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/program_management/services/text_plan/parse_result.dart';
import 'package:zamaj/modules/program_management/services/text_plan/text_plan_parser.dart';

import '../../../support/program_management_generators.dart';

void main() {
  const iterations = 100;

  test(
    'error determinism: same unparseable input always produces the same error',
    () {
      final rng = Random(42);
      for (var i = 0; i < iterations; i++) {
        final text = anyUnparseablePlanText(rng);

        final result1 = TextPlanParser.parse(text);
        final result2 = TextPlanParser.parse(text);
        final result3 = TextPlanParser.parse(text);

        expect(
          result1,
          isA<PlanParseFailure>(),
          reason: 'iteration $i: expected failure for text=${_repr(text)}',
        );
        expect(
          result2,
          isA<PlanParseFailure>(),
          reason: 'iteration $i: expected failure for text=${_repr(text)}',
        );
        expect(
          result3,
          isA<PlanParseFailure>(),
          reason: 'iteration $i: expected failure for text=${_repr(text)}',
        );

        final error1 = (result1 as PlanParseFailure).error;
        final error2 = (result2 as PlanParseFailure).error;
        final error3 = (result3 as PlanParseFailure).error;

        expect(
          error2.line,
          equals(error1.line),
          reason:
              'iteration $i: line mismatch on 2nd call, text=${_repr(text)}',
        );
        expect(
          error3.line,
          equals(error1.line),
          reason:
              'iteration $i: line mismatch on 3rd call, text=${_repr(text)}',
        );

        expect(
          error2.column,
          equals(error1.column),
          reason:
              'iteration $i: column mismatch on 2nd call, text=${_repr(text)}',
        );
        expect(
          error3.column,
          equals(error1.column),
          reason:
              'iteration $i: column mismatch on 3rd call, text=${_repr(text)}',
        );

        expect(
          error2.code,
          equals(error1.code),
          reason:
              'iteration $i: code mismatch on 2nd call, text=${_repr(text)}',
        );
        expect(
          error3.code,
          equals(error1.code),
          reason:
              'iteration $i: code mismatch on 3rd call, text=${_repr(text)}',
        );
      }
    },
  );
}

String _repr(String text) {
  if (text.isEmpty) return '(empty)';
  return '"${text.replaceAll('\n', '\\n').replaceAll('\r', '\\r')}"';
}
