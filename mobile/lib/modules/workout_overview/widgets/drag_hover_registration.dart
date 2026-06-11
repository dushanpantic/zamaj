import 'package:flutter/widgets.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';

/// Shared drag-hover registration plumbing for the workout-overview drop
/// targets (the reorder gaps, the superset drop target, and the onto-card
/// draggable). Each target tracks whether a drag is currently hovering it and
/// reports enter/leave to the shared [DragSession], so exactly one target owns
/// the hover at a time and a selection haptic fires once, on entry.
///
/// The host [State] supplies the [dragSession]; this mixin owns the registered
/// flag, the enter/leave reporting, the post-frame sync driven from the
/// DragTarget builder, and the dispose-time cleanup.
mixin DragHoverRegistration<T extends StatefulWidget> on State<T> {
  /// The session this target reports hover transitions to — normally
  /// `widget.dragSession`.
  DragSession get dragSession;

  bool _registered = false;

  void _setRegistered(bool value) {
    if (_registered == value) return;
    _registered = value;
    if (value) {
      Haptics.selectionChange();
      dragSession.hoverEntered();
    } else {
      dragSession.hoverLeft();
    }
  }

  /// Clears the hover registration immediately. Call from the DragTarget's
  /// `onLeave` and `onAcceptWithDetails`.
  void clearHoverRegistration() => _setRegistered(false);

  /// Reconciles the registration with the DragTarget builder's current
  /// [hovering] flag, deferred to after the frame so the shared [DragSession]
  /// is never mutated mid-build (and the enter haptic lands on the transition).
  void syncHoverRegistration(bool hovering) {
    if (hovering == _registered) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _setRegistered(hovering);
    });
  }

  @override
  void dispose() {
    if (_registered) {
      _registered = false;
      dragSession.hoverLeft();
    }
    super.dispose();
  }
}
