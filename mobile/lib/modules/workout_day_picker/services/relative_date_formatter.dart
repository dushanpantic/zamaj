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
    return _iso(t);
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

  static String _iso(DateTime t) {
    final y = t.year.toString().padLeft(4, '0');
    final m = t.month.toString().padLeft(2, '0');
    final d = t.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
