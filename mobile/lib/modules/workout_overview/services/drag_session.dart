import 'dart:async';

import 'package:flutter/foundation.dart';

/// Shared in-flight drag state for the workout-overview list. Tracks:
///
/// - `active`: whether a long-press drag is currently in flight. Drives the
///   reorder-gap "Move here" affordance (P2.1).
/// - hover entries / exits across every [DragTarget] in the list. When the
///   pointer has been outside every valid target for more than 250 ms the
///   carried drag-feedback pill fades to 60 % opacity (P3.2).
class DragSession extends ChangeNotifier {
  bool _active = false;
  int _hoverCount = 0;
  Timer? _outsideTimer;
  bool _isOutsideStable = false;

  bool get active => _active;

  /// `true` when a drag is active, the pointer is not currently inside any
  /// valid drop target, and it has been outside for ≥ 250 ms. Used by the
  /// drag-feedback pill to signal "no target here".
  bool get isOutsideStable => _active && _isOutsideStable;

  void begin() {
    if (_active) return;
    _active = true;
    _hoverCount = 0;
    _isOutsideStable = false;
    _scheduleOutsideTimer();
    notifyListeners();
  }

  void end() {
    if (!_active && _hoverCount == 0 && !_isOutsideStable) return;
    _active = false;
    _hoverCount = 0;
    _isOutsideStable = false;
    _outsideTimer?.cancel();
    _outsideTimer = null;
    notifyListeners();
  }

  void hoverEntered() {
    _hoverCount++;
    if (_hoverCount == 1) {
      _outsideTimer?.cancel();
      _outsideTimer = null;
      if (_isOutsideStable) {
        _isOutsideStable = false;
        notifyListeners();
      }
    }
  }

  void hoverLeft() {
    if (_hoverCount == 0) return;
    _hoverCount--;
    if (_hoverCount == 0 && _active) {
      _scheduleOutsideTimer();
    }
  }

  void _scheduleOutsideTimer() {
    _outsideTimer?.cancel();
    _outsideTimer = Timer(const Duration(milliseconds: 250), () {
      if (!_active || _hoverCount > 0) return;
      _isOutsideStable = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _outsideTimer?.cancel();
    super.dispose();
  }
}
