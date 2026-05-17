// Validates: Requirement R7 AC8

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/relative_date_formatter.dart';

void main() {
  const iterations = 200;

  test('format(t, n) is deterministic for arbitrary (target, now) pairs', () {
    final rng = Random(42);
    final base = DateTime(2025, 6, 1).millisecondsSinceEpoch;
    const oneDayMs = 24 * 60 * 60 * 1000;

    for (var i = 0; i < iterations; i++) {
      // target offset spans roughly [-365, +365] days from base.
      final targetOffsetMs =
          (rng.nextInt(2 * 365 + 1) - 365) * oneDayMs + rng.nextInt(oneDayMs);
      final nowOffsetMs =
          (rng.nextInt(2 * 365 + 1) - 365) * oneDayMs + rng.nextInt(oneDayMs);
      final target = DateTime.fromMillisecondsSinceEpoch(base + targetOffsetMs);
      final now = DateTime.fromMillisecondsSinceEpoch(base + nowOffsetMs);

      final first = RelativeDateFormatter.format(target, now);
      final second = RelativeDateFormatter.format(target, now);
      expect(
        first,
        equals(second),
        reason: 'iteration $i: target=$target now=$now',
      );
    }
  });
}
