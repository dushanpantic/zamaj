import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/training_week.dart';
import 'package:zamaj/modules/workout_day_picker/services/session_history_summarizer.dart';

import '../../../support/generators.dart';

/// Builds a Session whose top-level scalar fields are controlled.
/// All other fields come from [anySession] with a fixed seed so the
/// resulting Session is a valid aggregate.
Session _session({
  required String id,
  DateTime? endedAt,
  required DateTime startedAt,
  required DateTime updatedAt,
}) {
  final base = anySession(Random(0));
  return base.copyWith(
    id: id,
    endedAt: endedAt,
    startedAt: startedAt,
    updatedAt: updatedAt,
  );
}

void main() {
  group('SessionHistorySummarizer.summarize', () {
    final monday = DateTime(2025, 4, 14);
    final window = TrainingWeek(start: monday, end: DateTime(2025, 4, 21));

    test('empty list → zero counts and null timestamps/active id', () {
      final summary = SessionHistorySummarizer.summarize([], window);
      expect(summary.lastCompleted, isNull);
      expect(summary.totalCompletedCount, 0);
      expect(summary.thisWeekCount, 0);
      expect(summary.activeSessionId, isNull);
    });

    test('one completed session inside the window', () {
      final endedAt = DateTime(2025, 4, 15, 18);
      final s = _session(
        id: 'sess-a',
        startedAt: DateTime(2025, 4, 15, 17),
        updatedAt: endedAt,
        endedAt: endedAt,
      );
      final summary = SessionHistorySummarizer.summarize([s], window);
      expect(summary.lastCompleted, endedAt);
      expect(summary.totalCompletedCount, 1);
      expect(summary.thisWeekCount, 1);
      expect(summary.activeSessionId, isNull);
    });

    test('one completed session outside the window', () {
      final endedAt = DateTime(2025, 4, 10, 18);
      final s = _session(
        id: 'sess-a',
        startedAt: DateTime(2025, 4, 10, 17),
        updatedAt: endedAt,
        endedAt: endedAt,
      );
      final summary = SessionHistorySummarizer.summarize([s], window);
      expect(summary.lastCompleted, endedAt);
      expect(summary.totalCompletedCount, 1);
      expect(summary.thisWeekCount, 0);
      expect(summary.activeSessionId, isNull);
    });

    test(
      'one active-only session → totals are 0 and activeSessionId is set',
      () {
        final s = _session(
          id: 'sess-active',
          startedAt: DateTime(2025, 4, 15, 17),
          updatedAt: DateTime(2025, 4, 15, 18),
          // endedAt: null
        );
        final summary = SessionHistorySummarizer.summarize([s], window);
        expect(summary.lastCompleted, isNull);
        expect(summary.totalCompletedCount, 0);
        expect(summary.thisWeekCount, 0);
        expect(summary.activeSessionId, 'sess-active');
      },
    );

    test('mixed completed and active', () {
      final older = _session(
        id: 'old',
        startedAt: DateTime(2025, 4, 1),
        updatedAt: DateTime(2025, 4, 1, 12),
        endedAt: DateTime(2025, 4, 1, 12),
      );
      final inWeek = _session(
        id: 'in-week',
        startedAt: DateTime(2025, 4, 15, 8),
        updatedAt: DateTime(2025, 4, 15, 10),
        endedAt: DateTime(2025, 4, 15, 10),
      );
      final inWeekLater = _session(
        id: 'in-week-later',
        startedAt: DateTime(2025, 4, 17, 8),
        updatedAt: DateTime(2025, 4, 17, 10),
        endedAt: DateTime(2025, 4, 17, 10),
      );
      final active = _session(
        id: 'active',
        startedAt: DateTime(2025, 4, 18, 8),
        updatedAt: DateTime(2025, 4, 18, 12),
      );
      final summary = SessionHistorySummarizer.summarize([
        older,
        inWeek,
        inWeekLater,
        active,
      ], window);
      expect(summary.lastCompleted, DateTime(2025, 4, 17, 10));
      expect(summary.totalCompletedCount, 3);
      expect(summary.thisWeekCount, 2);
      expect(summary.activeSessionId, 'active');
    });

    test('thisWeek boundary: endedAt == window.start is inside', () {
      final s = _session(
        id: 'edge-start',
        startedAt: window.start.subtract(const Duration(hours: 1)),
        updatedAt: window.start,
        endedAt: window.start,
      );
      final summary = SessionHistorySummarizer.summarize([s], window);
      expect(summary.thisWeekCount, 1);
    });

    test('thisWeek boundary: endedAt == window.end is outside', () {
      final s = _session(
        id: 'edge-end',
        startedAt: window.end.subtract(const Duration(hours: 1)),
        updatedAt: window.end,
        endedAt: window.end,
      );
      final summary = SessionHistorySummarizer.summarize([s], window);
      expect(summary.thisWeekCount, 0);
      // ... but still counted as a total
      expect(summary.totalCompletedCount, 1);
    });

    test('active tiebreak: latest updatedAt wins', () {
      final t0 = DateTime(2025, 4, 14);
      final a = _session(id: 'aaa', startedAt: t0, updatedAt: t0);
      final b = _session(
        id: 'bbb',
        startedAt: t0,
        updatedAt: t0.add(const Duration(hours: 1)),
      );
      final c = _session(id: 'ccc', startedAt: t0, updatedAt: t0);
      final summary = SessionHistorySummarizer.summarize([a, b, c], window);
      expect(summary.activeSessionId, 'bbb');
    });

    test('active tiebreak: equal updatedAt → latest startedAt wins', () {
      final updated = DateTime(2025, 4, 14, 12);
      final a = _session(
        id: 'aaa',
        startedAt: DateTime(2025, 4, 14, 9),
        updatedAt: updated,
      );
      final b = _session(
        id: 'bbb',
        startedAt: DateTime(2025, 4, 14, 11),
        updatedAt: updated,
      );
      final c = _session(
        id: 'ccc',
        startedAt: DateTime(2025, 4, 14, 10),
        updatedAt: updated,
      );
      final summary = SessionHistorySummarizer.summarize([a, b, c], window);
      expect(summary.activeSessionId, 'bbb');
    });

    test('active tiebreak: equal updatedAt and startedAt → max id wins', () {
      final t = DateTime(2025, 4, 14);
      final a = _session(id: 'aaa', startedAt: t, updatedAt: t);
      final b = _session(id: 'bbb', startedAt: t, updatedAt: t);
      final c = _session(id: 'ccc', startedAt: t, updatedAt: t);
      final summary = SessionHistorySummarizer.summarize([a, b, c], window);
      expect(summary.activeSessionId, 'ccc');
    });

    test('lastCompleted is the maximum endedAt across completed sessions', () {
      final s1 = _session(
        id: 's1',
        startedAt: DateTime(2025, 4, 14),
        updatedAt: DateTime(2025, 4, 14, 12),
        endedAt: DateTime(2025, 4, 14, 12),
      );
      final s2 = _session(
        id: 's2',
        startedAt: DateTime(2025, 4, 16),
        updatedAt: DateTime(2025, 4, 16, 13),
        endedAt: DateTime(2025, 4, 16, 13),
      );
      final s3 = _session(
        id: 's3',
        startedAt: DateTime(2025, 4, 15),
        updatedAt: DateTime(2025, 4, 15, 14),
        endedAt: DateTime(2025, 4, 15, 14),
      );
      final summary = SessionHistorySummarizer.summarize([s1, s2, s3], window);
      expect(summary.lastCompleted, DateTime(2025, 4, 16, 13));
    });
  });
}
