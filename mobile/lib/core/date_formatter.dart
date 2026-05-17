/// Date formatting helpers shared across UI and export formatters.
///
/// All callers should pass an already-local [DateTime]; this helper does
/// not perform a timezone conversion so domain export code (which already
/// converts UTC to local at the boundary) and UI code see consistent
/// output.
abstract final class DateFormatter {
  /// Formats [date] as ISO-style `YYYY-MM-DD` in whatever zone [date]
  /// already carries.
  static String isoDate(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
