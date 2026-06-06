import 'package:flutter/material.dart';
import 'package:zamaj/core/app_elevation.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroller.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

/// The drag *source* for an exercise card. Lives in the card header's leading
/// slot so the long-press gesture is scoped to a visible, dedicated affordance
/// and never competes with taps on LOG SET, the kebab, or header-tap-to-expand.
/// Builds the same payload shape and drives the same auto-scroller /
/// drag-session machinery as the previous whole-card draggable, so drop targets
/// behave identically.
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
    required this.exercise,
    required this.exerciseName,
    required this.autoScroller,
    required this.dragSession,
  });

  final ExerciseViewModel exercise;
  final String exerciseName;
  final DragAutoScroller autoScroller;
  final DragSession dragSession;

  @override
  State<DragHandle> createState() => _DragHandleState();
}

class _DragHandleState extends State<DragHandle> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value || !mounted) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
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
          semanticLabel: 'Drag handle',
        ),
      ),
    );
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: LongPressDraggable<ExerciseDragPayload>(
        data: ExerciseDragPayload(
          sessionExerciseId: widget.exercise.sessionExercise.id,
          supersetTag: widget.exercise.sessionExercise.supersetTag,
        ),
        delay: AppDuration.dragHold,
        onDragStarted: () {
          _setPressed(false);
          Haptics.grab();
          widget.autoScroller.begin();
          widget.dragSession.begin();
        },
        onDragUpdate: (details) =>
            widget.autoScroller.updatePointer(details.globalPosition.dy),
        onDragEnd: (_) {
          _setPressed(false);
          widget.autoScroller.end();
          widget.dragSession.end();
        },
        onDraggableCanceled: (_, _) {
          _setPressed(false);
          widget.autoScroller.end();
          widget.dragSession.end();
        },
        feedback: _DragFeedbackPill(
          exerciseName: widget.exerciseName,
          width: pillWidth,
          dragSession: widget.dragSession,
        ),
        childWhenDragging: Opacity(opacity: 0.3, child: handle),
        child: handle,
      ),
    );
  }
}

/// Compact pill shown under the finger while dragging an exercise card.
/// Occludes far less of the screen than dragging the full card, so the
/// user can see and aim at the reorder gaps between groups. Fades to 60%
/// opacity when the pointer has been outside every valid drop target for
/// more than 250 ms, signalling "no target here".
class _DragFeedbackPill extends StatelessWidget {
  const _DragFeedbackPill({
    required this.exerciseName,
    required this.width,
    required this.dragSession,
  });

  final String exerciseName;
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
                    Icons.drag_indicator,
                    size: AppIconSize.lg,
                    color: colors.primary,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      exerciseName,
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
