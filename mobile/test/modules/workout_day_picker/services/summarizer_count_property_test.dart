// Validates: Requirements R9 AC2, R9 AC3

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/models/training_week.dart';
import 'package:zamaj/modules/workout_day_picker/services/session_history_summarizer.dart';

import '../../../support/generators.dart';

void main() {
  const iterations = 100;

  test('totalCompletedCount and thisWeekCount agree with a naive recomputation '
      'over arbitrary session lists and windows', () {
    final rng = Random(42);
    for (var i = 0; i < iterations; i++) {
      final sessionCount = rng.nextInt(15);
      final sessions = List<Session>.generate(
        sessionCount,
        (_) => anySession(rng),
      );

      // Build a window anchored on a random Monday in 2025.
      final dayOffset = rng.nextInt(2 * 365);
      final anchor = DateTime(2025).add(Duration(days: dayOffset));
      final window = TrainingWeek.compute(anchor);

      final summary = SessionHistorySummarizer.summarize(sessions, window);

      // Naive recomputation
      final naiveTotal = sessions.where((s) => s.endedAt != null).length;
      final naiveThisWeek = sessions
          .where((s) => s.endedAt != null && window.contains(s.endedAt!))
          .length;

      expect(
        summary.totalCompletedCount,
        equals(naiveTotal),
        reason: 'iteration $i: total mismatch (n=$sessionCount window=$window)',
      );
      expect(
        summary.thisWeekCount,
        equals(naiveThisWeek),
        reason:
            'iteration $i: thisWeek mismatch (n=$sessionCount window=$window)',
      );
      // Bookkeeping: thisWeek must never exceed total.
      expect(
        summary.thisWeekCount,
        lessThanOrEqualTo(summary.totalCompletedCount),
      );
    }
  });
}
