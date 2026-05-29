import 'package:flutter/scheduler.dart';
import 'package:flutter/widgets.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroll.dart';

/// Drives edge auto-scroll on the workout-overview list while a drag is in
/// flight. The list is a [CustomScrollView] with no built-in auto-scroll, so
/// we tick from a [Ticker] and jump the [ScrollController] each frame based
/// on the pointer's global Y position relative to the visible viewport.
class DragAutoScroller {
  DragAutoScroller({
    required TickerProvider tickerProvider,
    required this.scrollController,
    required this.viewportTopProvider,
    required this.viewportBottomProvider,
    this.edgeZone = 96.0,
    this.maxSpeed = 1000.0,
  }) {
    _ticker = tickerProvider.createTicker(_onTick);
  }

  final ScrollController scrollController;
  final double Function() viewportTopProvider;
  final double Function() viewportBottomProvider;
  final double edgeZone;
  final double maxSpeed;

  late final Ticker _ticker;
  Duration? _lastElapsed;
  double _pointerY = 0;
  bool _active = false;

  void begin() {
    _active = true;
    _lastElapsed = null;
    if (!_ticker.isActive) _ticker.start();
  }

  void updatePointer(double globalY) {
    if (!_active) return;
    _pointerY = globalY;
  }

  void end() {
    _active = false;
    _lastElapsed = null;
    if (_ticker.isActive) _ticker.stop();
  }

  void dispose() {
    _ticker.dispose();
  }

  void _onTick(Duration elapsed) {
    if (!_active) return;
    final last = _lastElapsed;
    _lastElapsed = elapsed;
    if (last == null) return;
    final dt = (elapsed - last).inMicroseconds / Duration.microsecondsPerSecond;
    if (dt <= 0) return;
    final velocity = computeScrollDelta(
      pointerY: _pointerY,
      viewportTop: viewportTopProvider(),
      viewportBottom: viewportBottomProvider(),
      edgeZone: edgeZone,
      maxSpeed: maxSpeed,
    );
    if (velocity == 0) return;
    if (!scrollController.hasClients) return;
    final position = scrollController.position;
    final target = (position.pixels + velocity * dt).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target != position.pixels) {
      position.jumpTo(target);
    }
  }
}
