/// Pure helpers for edge-driven auto-scroll while a drag is in flight in the
/// workout-overview list. The list is a [CustomScrollView] with no built-in
/// auto-scroll, so we drive scrolling ourselves from the pointer's global Y
/// position relative to the visible viewport.
library;

/// Returns the desired scroll velocity in logical-pixels-per-second for a
/// pointer at [pointerY] (global coords) over a viewport bounded by
/// [viewportTop] and [viewportBottom] (also global coords).
///
/// - Returns 0 when the pointer sits inside the safe band
///   (`viewportTop + edgeZone` .. `viewportBottom - edgeZone`).
/// - Returns a negative value (scroll up — reveal items above) when the
///   pointer is in the top edge zone.
/// - Returns a positive value (scroll down — reveal items below) when the
///   pointer is in the bottom edge zone.
/// - The magnitude ramps linearly from [minSpeed] at the boundary of the
///   edge zone to [maxSpeed] at the viewport edge, and stays capped at
///   ±[maxSpeed] if the pointer travels past the edge.
///
/// All distances are in logical pixels; the returned value is in
/// logical-pixels per second.
double computeScrollDelta({
  required double pointerY,
  required double viewportTop,
  required double viewportBottom,
  required double edgeZone,
  required double maxSpeed,
  double minSpeed = 200,
}) {
  assert(edgeZone > 0, 'edgeZone must be positive');
  assert(maxSpeed > 0, 'maxSpeed must be positive');
  assert(minSpeed >= 0, 'minSpeed must be non-negative');
  assert(maxSpeed >= minSpeed, 'maxSpeed must be >= minSpeed');
  if (viewportBottom <= viewportTop) return 0;

  final topThreshold = viewportTop + edgeZone;
  final bottomThreshold = viewportBottom - edgeZone;

  if (pointerY < topThreshold) {
    final distanceIntoZone = (topThreshold - pointerY).clamp(0.0, edgeZone);
    final t = distanceIntoZone / edgeZone;
    return -(minSpeed + (maxSpeed - minSpeed) * t);
  }
  if (pointerY > bottomThreshold) {
    final distanceIntoZone = (pointerY - bottomThreshold).clamp(0.0, edgeZone);
    final t = distanceIntoZone / edgeZone;
    return minSpeed + (maxSpeed - minSpeed) * t;
  }
  return 0;
}
