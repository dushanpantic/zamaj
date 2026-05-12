// Validates: Requirement R9 AC4

import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/workout_day_picker/services/current_week_window.dart';
import 'package:zamaj/modules/workout_day_picker/services/session_history_summarizer.dart';

import '../../../support/generators.dart';

/// Builds an active session (endedAt = null) with controlled scalar fields.
Session _activeSession({
  required String id,
  required DateTime startedAt,
  required DateTime updatedAt,
  required Random rng,
}) {
  return anySession(
    rng,
  ).copyWith(id: id, endedAt: null, startedAt: startedAt, updatedAt: updatedAt);
}

/// Reference impl of the tiebreak: lex order on (updatedAt, startedAt, id).
String _expectedWinner(List<Session> actives) {
  Session best = actives.first;
  for (final s in actives.skip(1)) {
    final byU = s.updatedAt.compareTo(best.updatedAt);
    if (byU > 0) {
      best = s;
      continue;
    }
    if (byU < 0) continue;
    final byS = s.startedAt.compareTo(best.startedAt);
    if (byS > 0) {
      best = s;
      continue;
    }
    if (byS < 0) continue;
    if (s.id.compareTo(best.id) > 0) {
      best = s;
    }
  }
  return best.id;
}

void main() {
  const iterations = 100;

  test(
    'activeSessionId is the (updatedAt, startedAt, id) lex max over actives',
    () {
      final rng = Random(123);
      final window = CurrentWeekWindow.compute(DateTime(2025, 4, 14));
      final base = DateTime(2025, 1, 1);

      for (var i = 0; i < iterations; i++) {
        final count = 2 + rng.nextInt(5); // 2..6 active sessions
        // Use a small pool of timestamps and ids so collisions are likely
        // and the tiebreak path is actually exercised.
        final actives = List<Session>.generate(count, (k) {
          final updatedDay = rng.nextInt(3);
          final startedDay = rng.nextInt(3);
          return _activeSession(
            id: 'id-${rng.nextInt(5)}-$k',
            startedAt: base.add(Duration(days: startedDay)),
            updatedAt: base.add(Duration(days: updatedDay)),
            rng: rng,
          );
        });

        final summary = SessionHistorySummarizer.summarize(actives, window);
        expect(
          summary.activeSessionId,
          equals(_expectedWinner(actives)),
          reason: 'iteration $i',
        );
      }
    },
  );
}
