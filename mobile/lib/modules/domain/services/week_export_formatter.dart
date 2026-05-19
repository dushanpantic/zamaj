import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/modules/domain/models/session.dart';
import 'package:zamaj/modules/domain/services/session_export_formatter.dart';

/// Renders a list of completed sessions for one calendar week to plain
/// text. The output starts with a `Week of <YYYY-MM-DD>` header, followed
/// by each session's formatted body separated by a divider line.
///
/// Sessions whose `endedAt` is null are skipped. Sessions are emitted in
/// chronological order by `endedAt` (oldest first); ties are broken by
/// session id for determinism.
abstract final class WeekExportFormatter {
  static String format({
    required DateTime weekStart,
    required List<Session> sessions,
    bool includeWarmups = true,
  }) {
    final buf = StringBuffer();
    final start = weekStart.isUtc ? weekStart.toLocal() : weekStart;
    buf.write('Week of ${DateFormatter.isoDate(start)}');

    final completed = sessions.where((s) => s.endedAt != null).toList()
      ..sort(_chronological);

    if (completed.isEmpty) {
      buf.writeln();
      buf.writeln();
      buf.write('(No completed sessions this week)');
      return buf.toString();
    }

    for (final s in completed) {
      buf.writeln();
      buf.writeln();
      buf.writeln('───────────────');
      buf.write(
        SessionExportFormatter.format(s, includeWarmups: includeWarmups),
      );
    }

    return buf.toString();
  }

  static int _chronological(Session a, Session b) {
    final aEnd = a.endedAt!;
    final bEnd = b.endedAt!;
    final byEnded = aEnd.compareTo(bEnd);
    if (byEnded != 0) return byEnded;
    return a.id.compareTo(b.id);
  }
}
