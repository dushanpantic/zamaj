/// Renders a whole-second count as a zero-padded `mm:ss` clock readout.
///
/// The one mm:ss source for the focus surface: both the time-based panel's
/// countdown hero and the rest-timer bar's glance read off this, so the two
/// can never drift on padding or the negative-clamp policy. Negatives clamp to
/// `00:00` (a depleted countdown never shows a minus sign).
abstract final class MmssFormatter {
  static String format(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}
