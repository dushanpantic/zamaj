/// Renders a planned rest duration in seconds as a compact human label.
///
/// Examples: `45` → `45s`, `60` → `1m`, `90` → `1m 30s`, `0` → `0s`.
abstract final class RestFormatter {
  static String format(int seconds) {
    if (seconds < 60) return '${seconds}s';
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    if (remainder == 0) return '${minutes}m';
    return '${minutes}m ${remainder}s';
  }
}
