/// Formats an elapsed [Duration] as a clock readout: `mm:ss` under one hour,
/// `h:mm:ss` at or beyond one hour. Negative durations clamp to zero.
///
/// Single source of truth shared by the live in-session timer and the
/// post-session summary card so both read identically.
String formatElapsed(Duration elapsed) {
  final totalSeconds = elapsed.isNegative ? 0 : elapsed.inSeconds;
  final h = totalSeconds ~/ 3600;
  final m = (totalSeconds % 3600) ~/ 60;
  final s = totalSeconds % 60;
  final mm = m.toString().padLeft(2, '0');
  final ss = s.toString().padLeft(2, '0');
  if (h > 0) return '$h:$mm:$ss';
  return '$mm:$ss';
}
