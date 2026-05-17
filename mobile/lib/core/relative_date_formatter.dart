import 'package:zamaj/core/date_formatter.dart';

/// Human-readable relative date label for a past [target] anchored on [now].
///
/// Same-day returns "Today", one-day-ago "Yesterday", 2–6 days returns the
/// weekday name, and anything earlier falls back to the ISO date string
/// from [DateFormatter.isoDate].
abstract final class RelativeDateFormatter {
  static String format(DateTime target, DateTime now) {
    final t = target.isUtc ? target.toLocal() : target;
    final n = now.isUtc ? now.toLocal() : now;
    final targetDate = DateTime(t.year, t.month, t.day);
    final nowDate = DateTime(n.year, n.month, n.day);
    final deltaDays = nowDate.difference(targetDate).inDays;
    if (deltaDays == 0) return 'Today';
    if (deltaDays == 1) return 'Yesterday';
    if (deltaDays > 1 && deltaDays < 7) return _weekdayName(t.weekday);
    return DateFormatter.isoDate(t);
  }

  static String _weekdayName(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Monday';
      case DateTime.tuesday:
        return 'Tuesday';
      case DateTime.wednesday:
        return 'Wednesday';
      case DateTime.thursday:
        return 'Thursday';
      case DateTime.friday:
        return 'Friday';
      case DateTime.saturday:
        return 'Saturday';
      case DateTime.sunday:
        return 'Sunday';
      default:
        throw ArgumentError('Unknown weekday: $weekday');
    }
  }
}
