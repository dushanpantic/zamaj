// Validates: P1 — edge auto-scroll ramp.

import 'package:flutter_test/flutter_test.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroll.dart';

void main() {
  group('computeScrollDelta', () {
    const top = 100.0;
    const bottom = 700.0; // 600 dp viewport
    const edgeZone = 96.0;
    const maxSpeed = 1000.0;
    const minSpeed = 200.0;

    double call(double pointerY) => computeScrollDelta(
      pointerY: pointerY,
      viewportTop: top,
      viewportBottom: bottom,
      edgeZone: edgeZone,
      maxSpeed: maxSpeed,
      minSpeed: minSpeed,
    );

    test('pointer in safe band returns 0', () {
      expect(call(top + edgeZone), 0);
      expect(call(top + edgeZone + 1), 0);
      expect(call((top + bottom) / 2), 0);
      expect(call(bottom - edgeZone - 1), 0);
      expect(call(bottom - edgeZone), 0);
    });

    test('pointer exactly at top edge returns -maxSpeed', () {
      expect(call(top), closeTo(-maxSpeed, 1e-9));
    });

    test('pointer exactly at bottom edge returns +maxSpeed', () {
      expect(call(bottom), closeTo(maxSpeed, 1e-9));
    });

    test('pointer past top edge stays clamped at -maxSpeed', () {
      expect(call(top - 50), closeTo(-maxSpeed, 1e-9));
    });

    test('pointer past bottom edge stays clamped at +maxSpeed', () {
      expect(call(bottom + 50), closeTo(maxSpeed, 1e-9));
    });

    test('top ramp is monotonic non-decreasing toward the edge', () {
      // Walking from the safe-band boundary toward the top edge should
      // monotonically increase |velocity|.
      var previousMagnitude = 0.0;
      for (var i = 0; i <= edgeZone.toInt(); i++) {
        final y = top + edgeZone - i; // edgeZone away → 0 away
        final v = call(y);
        expect(v, lessThanOrEqualTo(0));
        expect(v.abs(), greaterThanOrEqualTo(previousMagnitude - 1e-9));
        previousMagnitude = v.abs();
      }
      expect(previousMagnitude, closeTo(maxSpeed, 1e-9));
    });

    test('bottom ramp is monotonic non-decreasing toward the edge', () {
      var previousMagnitude = 0.0;
      for (var i = 0; i <= edgeZone.toInt(); i++) {
        final y = bottom - edgeZone + i;
        final v = call(y);
        expect(v, greaterThanOrEqualTo(0));
        expect(v.abs(), greaterThanOrEqualTo(previousMagnitude - 1e-9));
        previousMagnitude = v.abs();
      }
      expect(previousMagnitude, closeTo(maxSpeed, 1e-9));
    });

    test('top ramp begins at -minSpeed at zone boundary', () {
      // Just inside the top zone: one pixel past the safe-band boundary.
      final v = call(top + edgeZone - 0.000001);
      expect(v, lessThan(0));
      expect(v.abs(), closeTo(minSpeed, 1));
    });

    test('bottom ramp begins at +minSpeed at zone boundary', () {
      final v = call(bottom - edgeZone + 0.000001);
      expect(v, greaterThan(0));
      expect(v, closeTo(minSpeed, 1));
    });

    test('midpoint of top zone returns midpoint speed', () {
      // 48 dp into a 96 dp zone → t = 0.5 → minSpeed + 0.5 * (max - min).
      const expectedMagnitude = minSpeed + 0.5 * (maxSpeed - minSpeed);
      expect(call(top + edgeZone / 2), closeTo(-expectedMagnitude, 1e-9));
    });

    test('midpoint of bottom zone returns midpoint speed', () {
      const expectedMagnitude = minSpeed + 0.5 * (maxSpeed - minSpeed);
      expect(call(bottom - edgeZone / 2), closeTo(expectedMagnitude, 1e-9));
    });

    test('zero-height viewport returns 0', () {
      final v = computeScrollDelta(
        pointerY: 50,
        viewportTop: 100,
        viewportBottom: 100,
        edgeZone: edgeZone,
        maxSpeed: maxSpeed,
      );
      expect(v, 0);
    });
  });
}
