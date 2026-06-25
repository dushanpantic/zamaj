import 'package:flutter/material.dart';
import 'package:zamaj/core/app_elevation.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroller.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';
import 'package:zamaj/modules/workout_overview/widgets/overview_drag_payload.dart';

/// The drag *source* for a reorderable row: a single exercise card's leading
/// slot, or a superset header. Lives on a visible, dedicated affordance so the
/// long-press gesture is scoped to it and never competes with taps on LOG SET,
/// the kebab, or header-tap-to-expand. It carries an [OverviewDragPayload] —
/// an [ExerciseDragPayload] for one card or a [SupersetDragPayload] for a whole
/// group — and drives the same auto-scroller / drag-session machinery for both,
/// so every drop target behaves identically.
///
/// Sized as a sweaty-hands grab target ([kExerciseLeadingSlotWidth], ≈ full
/// header height) with a drawn resting fill, so users aim at the whole region
/// rather than a 20 px glyph. A [Listener]-driven "grab forming" press state
/// confirms the touch *during* the long-press window — not only once it
/// succeeds — so a near-miss or slight drift no longer reads as nothing
/// happening.
class DragHandle extends StatefulWidget {
  const DragHandle({
    super.key,
    required this.payload,
    required this.feedbackLabel,
    required this.autoScroller,
    required this.dragSession,
    this.isGroup = false,
    this.semanticLabel = 'Drag handle',
  });

  /// The payload this handle's drag carries.
  final OverviewDragPayload payload;

  /// Text shown in the drag-feedback pill — an exercise name, or a group
  /// descriptor like "Superset (3)".
  final String feedbackLabel;

  /// When true the feedback pill leads with the superset link icon so the
  /// dragged thing reads as a whole group rather than a single card.
  final bool isGroup;

  /// Accessibility label for the handle glyph ("Drag handle" / "Drag superset").
  final String semanticLabel;

  final DragAutoScroller autoScroller;
  final DragSession dragSession;

  @override
  State<DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<DragHandle>
    with AutomaticKeepAliveClientMixin {
  bool _pressed = false;

  /// While a drag this handle started is in flight, the enclosing list row is
  /// force-kept-alive. The drag *source* lives in a lazy [SliverList], so
  /// dragging toward the bottom auto-scrolls the source off the top of the
  /// viewport — and the sliver would then dispose it mid-drag. A disposed
  /// [LongPressDraggable] never fires [onDragEnd]/[onDraggableCanceled] (the
  /// drag avatar guards both on `mounted`), which strands the auto-scroller's
  /// ticker (runaway scroll that snaps back to the bottom, no way to scroll up)
  /// and leaves [DragSession.active] true (the "Move here" gaps stay lit after
  /// release). Keeping the row alive lets the gesture complete normally so the
  /// existing teardown runs.
  bool _dragging = false;

  @override
  bool get wantKeepAlive => _dragging;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  void _beginDrag() {
    _setPressed(false);
    Haptics.grab();
    widget.autoScroller.begin();
    widget.dragSession.begin();
    _dragging = true;
    updateKeepAlive();
  }

  void _endDrag() {
    _setPressed(false);
    widget.autoScroller.end();
    widget.dragSession.end();
    if (_dragging) {
      _dragging = false;
      updateKeepAlive();
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required by AutomaticKeepAliveClientMixin.
    final colors = Theme.of(context).appColors;
    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = (screenWidth * 0.7).clamp(220.0, 360.0);
    final handle = AnimatedScale(
      duration: AppDuration.fast,
      curve: AppCurve.standard,
      scale: _pressed ? 0.94 : 1,
      child: AnimatedContainer(
        duration: AppDuration.fast,
        curve: AppCurve.standard,
        width: kExerciseLeadingSlotWidth,
        height: kExerciseLeadingSlotWidth,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: _pressed
              ? colors.primary.withValues(alpha: AppOpacity.tintFill)
              : colors.surfaceVariant,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: AppIcon(
          Icons.drag_indicator,
          color: _pressed ? colors.primary : colors.onSurfaceMuted,
          size: AppIconSize.lg,
          semanticLabel: widget.semanticLabel,
        ),
      ),
    );
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: LongPressDraggable<OverviewDragPayload>(
        data: widget.payload,
        delay: AppDuration.dragHold,
        onDragStarted: _beginDrag,
        onDragUpdate: (details) =>
            widget.autoScroller.updatePointer(details.globalPosition.dy),
        onDragEnd: (_) => _endDrag(),
        onDraggableCanceled: (_, _) => _endDrag(),
        feedback: _DragFeedbackPill(
          label: widget.feedbackLabel,
          isGroup: widget.isGroup,
          width: pillWidth,
          dragSession: widget.dragSession,
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: handle),
        child: handle,
      ),
    );
  }
}

/// Compact pill shown under the finger while dragging a card or a whole
/// superset. Occludes far less of the screen than dragging the full card(s),
/// so the user can see and aim at the reorder gaps between groups. Fades to
/// 60% opacity when the pointer has been outside every valid drop target for
/// more than 250 ms, signalling "no drop target here" — the same cue for a
/// group drag released over a non-accepting target.
class _DragFeedbackPill extends StatelessWidget {
  const _DragFeedbackPill({
    required this.label,
    required this.isGroup,
    required this.width,
    required this.dragSession,
  });

  final String label;

  /// Leads the pill with the superset link icon (a dragged group) instead of
  /// the reorder glyph (a single card).
  final bool isGroup;
  final double width;
  final DragSession dragSession;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return AnimatedBuilder(
      animation: dragSession,
      builder: (context, _) {
        final dimmed = dragSession.isOutsideStable;
        return AnimatedOpacity(
          duration: AppDuration.base,
          opacity: dimmed ? 0.6 : 1.0,
          child: Material(
            elevation: AppElevation.drag,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              width: width,
              height: AppSpacing.touchMin,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: colors.primary,
                  width: AppStroke.emphasis,
                ),
              ),
              child: Row(
                children: [
                  AppIcon(
                    isGroup ? Icons.link : Icons.drag_indicator,
                    size: AppIconSize.lg,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: typography.label.copyWith(color: colors.onSurface),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppIcon(
                    Icons.swap_vert,
                    size: AppIconSize.md,
                    color: colors.onSurfaceMuted,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
