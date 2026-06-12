import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/training_week.dart';

void main() {
  group('TrainingWeek.compute', () {
    test('start is the most recent Monday at 00:00 local time', () {
      // Tuesday 2025-04-15 14:32:11 → start = Monday 2025-04-14 00:00
      final now = DateTime(2025, 4, 15, 14, 32, 11);
      final week = TrainingWeek.compute(now);
      expect(week.start, DateTime(2025, 4, 14));
      expect(week.start.weekday, DateTime.monday);
      expect(week.start.hour, 0);
      expect(week.start.minute, 0);
      expect(week.start.second, 0);
      expect(week.start.millisecond, 0);
    });

    test('every weekday anchors to the same Monday', () {
      // Week of 2025-04-14 (Mon) through 2025-04-20 (Sun)
      const weekStart = 14;
      for (var dayOffset = 0; dayOffset < 7; dayOffset++) {
        final now = DateTime(2025, 4, weekStart + dayOffset, 9, 0, 0);
        final week = TrainingWeek.compute(now);
        expect(
          week.start,
          DateTime(2025, 4, weekStart),
          reason: 'dayOffset=$dayOffset (weekday=${now.weekday})',
        );
      }
    });

    test('Monday at exactly 00:00:00.000 returns "now" as start', () {
      final monday = DateTime(2025, 4, 14);
      final week = TrainingWeek.compute(monday);
      expect(week.start, monday);
      expect(week.start, equals(monday));
    });

    test('end equals start + 7 calendar days at local 00:00', () {
      final now = DateTime(2025, 4, 15, 14, 32);
      final week = TrainingWeek.compute(now);
      expect(week.end, DateTime(2025, 4, 21));
      expect(week.end.weekday, DateTime.monday);
      expect(week.end.hour, 0);
      expect(week.end.minute, 0);
      expect(week.end.second, 0);
    });

    test('window across a month boundary advances correctly', () {
      // 2025-04-30 (Wed) → Monday 2025-04-28; end = 2025-05-05
      final now = DateTime(2025, 4, 30, 12);
      final week = TrainingWeek.compute(now);
      expect(week.start, DateTime(2025, 4, 28));
      expect(week.end, DateTime(2025, 5, 5));
    });

    test('window across a year boundary advances correctly', () {
      // 2024-12-31 (Tue) → Monday 2024-12-30; end = 2025-01-06
      final now = DateTime(2024, 12, 31, 23, 59);
      final week = TrainingWeek.compute(now);
      expect(week.start, DateTime(2024, 12, 30));
      expect(week.end, DateTime(2025, 1, 6));
    });

    test(
      'window across DST spring-forward keeps the 7-day calendar invariant',
      () {
        // 2025-03-09 is the US DST spring-forward Sunday.
        // The week containing it: Monday 2025-03-03 → Monday 2025-03-10.
        final now = DateTime(2025, 3, 6, 10);
        final week = TrainingWeek.compute(now);
        expect(week.start, DateTime(2025, 3, 3));
        expect(week.end, DateTime(2025, 3, 10));
        // Calendar invariant: end-date = start-date + 7 days; civil time is 00:00.
        expect(week.end.day - week.start.day, 7);
      },
    );

    test('window across DST fall-back keeps the 7-day calendar invariant', () {
      // 2025-11-02 is the US DST fall-back Sunday.
      // The week containing it: Monday 2025-10-27 → Monday 2025-11-03.
      final now = DateTime(2025, 10, 30, 10);
      final week = TrainingWeek.compute(now);
      expect(week.start, DateTime(2025, 10, 27));
      expect(week.end, DateTime(2025, 11, 3));
    });

    test('UTC "now" is converted to local time before anchoring', () {
      // Construct a UTC instant; compute() converts via toLocal() first.
      final utcNow = DateTime.utc(2025, 4, 15, 14, 32);
      final week = TrainingWeek.compute(utcNow);
      // The start is always a local-time Monday.
      expect(week.start.weekday, DateTime.monday);
      expect(week.start.hour, 0);
      expect(week.start.isUtc, isFalse);
    });

    test('contains() is half-open [start, end)', () {
      final week = TrainingWeek(
        start: DateTime(2025, 4, 14),
        end: DateTime(2025, 4, 21),
      );
      expect(week.contains(week.start), isTrue);
      expect(week.contains(DateTime(2025, 4, 14, 0, 0, 0, 1)), isTrue);
      expect(week.contains(DateTime(2025, 4, 17, 12)), isTrue);
      expect(week.contains(week.end), isFalse);
      expect(week.contains(DateTime(2025, 4, 13, 23, 59, 59, 999)), isFalse);
    });
  });
}
