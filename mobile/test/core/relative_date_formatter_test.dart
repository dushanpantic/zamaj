import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/core/relative_date_formatter.dart';

void main() {
  group('RelativeDateFormatter.format', () {
    test('returns "Today" when target equals now', () {
      final t = DateTime(2025, 4, 15, 10, 30);
      expect(RelativeDateFormatter.format(t, t), 'Today');
    });

    test('returns "Today" when target and now share the same local day', () {
      final now = DateTime(2025, 4, 15, 23, 59);
      final target = DateTime(2025, 4, 15, 0, 0, 1);
      expect(RelativeDateFormatter.format(target, now), 'Today');
    });

    test('returns "Yesterday" when target is one local day before now', () {
      final now = DateTime(2025, 4, 15, 8);
      final target = DateTime(2025, 4, 14, 22);
      expect(RelativeDateFormatter.format(target, now), 'Yesterday');
    });

    test('returns the weekday name for each of 2..6 days back', () {
      // now = 2025-04-15 (Tuesday).
      final now = DateTime(2025, 4, 15, 12);
      // 2 days back → 2025-04-13 (Sunday)
      expect(
        RelativeDateFormatter.format(DateTime(2025, 4, 13, 9), now),
        'Sunday',
      );
      // 3 days back → 2025-04-12 (Saturday)
      expect(
        RelativeDateFormatter.format(DateTime(2025, 4, 12, 9), now),
        'Saturday',
      );
      // 4 days back → 2025-04-11 (Friday)
      expect(
        RelativeDateFormatter.format(DateTime(2025, 4, 11, 9), now),
        'Friday',
      );
      // 5 days back → 2025-04-10 (Thursday)
      expect(
        RelativeDateFormatter.format(DateTime(2025, 4, 10, 9), now),
        'Thursday',
      );
      // 6 days back → 2025-04-09 (Wednesday)
      expect(
        RelativeDateFormatter.format(DateTime(2025, 4, 9, 9), now),
        'Wednesday',
      );
    });

    test('returns ISO YYYY-MM-DD at exactly 7 days back', () {
      final now = DateTime(2025, 4, 15);
      final target = DateTime(2025, 4, 8, 14);
      expect(RelativeDateFormatter.format(target, now), '2025-04-08');
    });

    test('returns ISO YYYY-MM-DD for distant past', () {
      final now = DateTime(2025, 4, 15);
      final target = DateTime(2020, 12, 1, 6);
      expect(RelativeDateFormatter.format(target, now), '2020-12-01');
    });

    test('returns ISO YYYY-MM-DD for future targets', () {
      final now = DateTime(2025, 4, 15);
      final target = DateTime(2025, 4, 16, 14);
      expect(RelativeDateFormatter.format(target, now), '2025-04-16');
    });

    test('pads single-digit month and day to two digits and year to four', () {
      final now = DateTime(2025, 4, 15);
      // 2025-01-02 is far enough back to be in the ISO branch.
      final target = DateTime(2025, 1, 2);
      expect(RelativeDateFormatter.format(target, now), '2025-01-02');
    });

    test('UTC inputs are converted to local time before computing', () {
      // Build a UTC instant whose local-time date equals "now"'s local date.
      final now = DateTime(2025, 4, 15, 12);
      final target = DateTime(
        2025,
        4,
        15,
        14,
      ).toUtc(); // same local day after toLocal() roundtrip
      expect(RelativeDateFormatter.format(target, now), 'Today');
    });

    test('format(t, n) is symmetric to "Today" for any t == n', () {
      // R7 AC7: target == now → "Today"
      for (var monthOffset = 0; monthOffset < 12; monthOffset++) {
        final t = DateTime(2025, 1 + monthOffset, 15, 9);
        expect(RelativeDateFormatter.format(t, t), 'Today');
      }
    });
  });
}
