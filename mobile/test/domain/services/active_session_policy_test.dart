import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/services/active_session_policy.dart';

import '../../support/generators.dart';

/// Builds a Session whose selection-relevant scalar fields are controlled.
/// All other fields come from [anySession] with a fixed seed so the resulting
/// Session is a valid aggregate.
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
  group('ActiveSessionPolicy.select', () {
    test('empty list → null', () {
      expect(ActiveSessionPolicy.select([]), isNull);
    });

    test('all sessions completed → null', () {
      final t = DateTime(2025, 4, 14);
      final a = _session(id: 'a', startedAt: t, updatedAt: t, endedAt: t);
      final b = _session(id: 'b', startedAt: t, updatedAt: t, endedAt: t);
      expect(ActiveSessionPolicy.select([a, b]), isNull);
    });

    test('a single in-progress session is selected', () {
      final t = DateTime(2025, 4, 14);
      final s = _session(id: 's', startedAt: t, updatedAt: t);
      expect(ActiveSessionPolicy.select([s])?.id, 's');
    });

    test('most recently updated in-progress session wins', () {
      final t0 = DateTime(2025, 4, 14);
      final a = _session(id: 'a', startedAt: t0, updatedAt: t0);
      final b = _session(
        id: 'b',
        startedAt: t0,
        updatedAt: t0.add(const Duration(hours: 1)),
      );
      final c = _session(id: 'c', startedAt: t0, updatedAt: t0);
      expect(ActiveSessionPolicy.select([a, b, c])?.id, 'b');
    });

    test('equal updatedAt → later startedAt wins', () {
      final updated = DateTime(2025, 4, 14, 12);
      final a = _session(
        id: 'a',
        startedAt: DateTime(2025, 4, 14, 9),
        updatedAt: updated,
      );
      final b = _session(
        id: 'b',
        startedAt: DateTime(2025, 4, 14, 11),
        updatedAt: updated,
      );
      final c = _session(
        id: 'c',
        startedAt: DateTime(2025, 4, 14, 10),
        updatedAt: updated,
      );
      expect(ActiveSessionPolicy.select([a, b, c])?.id, 'b');
    });

    test('equal updatedAt and startedAt → greatest id wins', () {
      final t = DateTime(2025, 4, 14);
      final a = _session(id: 'aaa', startedAt: t, updatedAt: t);
      final b = _session(id: 'bbb', startedAt: t, updatedAt: t);
      final c = _session(id: 'ccc', startedAt: t, updatedAt: t);
      expect(ActiveSessionPolicy.select([a, b, c])?.id, 'ccc');
    });

    test('a completed session never wins over an in-progress one, even when '
        'updated more recently', () {
      final t0 = DateTime(2025, 4, 14);
      final active = _session(id: 'active', startedAt: t0, updatedAt: t0);
      final completedLater = _session(
        id: 'done',
        startedAt: t0,
        updatedAt: t0.add(const Duration(days: 1)),
        endedAt: t0.add(const Duration(days: 1)),
      );
      expect(
        ActiveSessionPolicy.select([active, completedLater])?.id,
        'active',
      );
    });

    test('selection is independent of input order', () {
      final t0 = DateTime(2025, 4, 14);
      final a = _session(id: 'a', startedAt: t0, updatedAt: t0);
      final b = _session(
        id: 'b',
        startedAt: t0,
        updatedAt: t0.add(const Duration(hours: 1)),
      );
      expect(ActiveSessionPolicy.select([a, b])?.id, 'b');
      expect(ActiveSessionPolicy.select([b, a])?.id, 'b');
    });
  });
}
