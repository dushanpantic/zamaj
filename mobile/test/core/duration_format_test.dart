import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/duration_format.dart';

void main() {
  group('formatElapsed', () {
    test('under one hour shows minutes and seconds', () {
      expect(formatElapsed(const Duration(minutes: 42, seconds: 18)), '42:18');
    });

    test('at or over one hour shows hours, minutes and seconds', () {
      expect(
        formatElapsed(const Duration(hours: 1, minutes: 3, seconds: 9)),
        '1:03:09',
      );
    });

    test('sub-minute durations pad to two digits', () {
      expect(formatElapsed(const Duration(seconds: 7)), '00:07');
    });

    test('negative durations clamp to zero', () {
      expect(formatElapsed(const Duration(seconds: -5)), '00:00');
    });
  });
}
