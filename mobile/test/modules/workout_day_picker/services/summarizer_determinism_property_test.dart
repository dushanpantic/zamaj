// Validates: Requirement R9 AC5

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';
import 'package:zamaj/modules/workout_day_picker/services/session_history_summarizer.dart';

import '../../../support/generators.dart';

void main() {
  const iterations = 100;

  test('summarize is deterministic for identical inputs', () {
    final rng = Random(7);
    for (var i = 0; i < iterations; i++) {
      final count = rng.nextInt(15);
      final sessions = List<Session>.generate(count, (_) => anySession(rng));
      final dayOffset = rng.nextInt(2 * 365);
      final anchor = DateTime(2025).add(Duration(days: dayOffset));
      final window = CurrentWeekWindow.compute(anchor);

      final first = SessionHistorySummarizer.summarize(sessions, window);
      final second = SessionHistorySummarizer.summarize(sessions, window);
      expect(first, equals(second), reason: 'iteration $i');
    }
  });
}
