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

  /// Compact variant for narrow columns: same "Today"/"Yesterday" anchors,
  /// an abbreviated weekday ("Tue") for 2–6 days back, and a short month +
  /// day ("Jun 5") for anything earlier — with the year appended only when
  /// [target] falls outside [now]'s year ("Jun 5, 2024"). Pair with
  /// [formatAbsolute] in a tooltip for the unambiguous full date.
  static String formatCompact(DateTime target, DateTime now) {
    final t = target.isUtc ? target.toLocal() : target;
    final n = now.isUtc ? now.toLocal() : now;
    final targetDate = DateTime(t.year, t.month, t.day);
    final nowDate = DateTime(n.year, n.month, n.day);
    final deltaDays = nowDate.difference(targetDate).inDays;
    if (deltaDays == 0) return 'Today';
    if (deltaDays == 1) return 'Yesterday';
    if (deltaDays > 1 && deltaDays < 7) return _shortWeekday(t.weekday);
    return _shortMonthDay(t, includeYear: t.year != n.year);
  }

  /// Unambiguous absolute date for tooltips / accessible labels: "Jun 5, 2024".
  static String formatAbsolute(DateTime target) {
    final t = target.isUtc ? target.toLocal() : target;
    return _shortMonthDay(t, includeYear: true);
  }

  static String _shortMonthDay(DateTime t, {required bool includeYear}) {
    final monthDay = '${_shortMonths[t.month - 1]} ${t.day}';
    return includeYear ? '$monthDay, ${t.year}' : monthDay;
  }

  static const List<String> _shortMonths = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  static String _shortWeekday(int weekday) {
    switch (weekday) {
      case DateTime.monday:
        return 'Mon';
      case DateTime.tuesday:
        return 'Tue';
      case DateTime.wednesday:
        return 'Wed';
      case DateTime.thursday:
        return 'Thu';
      case DateTime.friday:
        return 'Fri';
      case DateTime.saturday:
        return 'Sat';
      case DateTime.sunday:
        return 'Sun';
      default:
        throw ArgumentError('Unknown weekday: $weekday');
    }
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
