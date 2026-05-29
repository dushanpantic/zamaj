import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroller.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

/// The drag *source* for an exercise card. Lives inside the leading 48 dp
/// slot of the card header so the long-press gesture is scoped to a visible,
/// dedicated affordance and never competes with taps on LOG SET, the kebab,
/// or header-tap-to-expand. Builds the same payload shape and drives the
/// same auto-scroller / drag-session machinery as the previous whole-card
/// draggable, so drop targets behave identically.
class DragHandle extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final screenWidth = MediaQuery.of(context).size.width;
    final pillWidth = (screenWidth * 0.7).clamp(220.0, 360.0);
    final icon = SizedBox(
      width: AppSpacing.touchMin,
      height: AppSpacing.touchMin,
      child: Icon(
        Icons.drag_indicator,
        color: colors.onSurfaceMuted,
        size: 20,
        semanticLabel: 'Drag handle',
      ),
    );
    return LongPressDraggable<ExerciseDragPayload>(
      data: ExerciseDragPayload(
        sessionExerciseId: exercise.sessionExercise.id,
        supersetTag: exercise.sessionExercise.supersetTag,
      ),
      delay: const Duration(milliseconds: 250),
      onDragStarted: () {
        Haptics.grab();
        autoScroller.begin();
        dragSession.begin();
      },
      onDragUpdate: (details) =>
          autoScroller.updatePointer(details.globalPosition.dy),
      onDragEnd: (_) {
        autoScroller.end();
        dragSession.end();
      },
      onDraggableCanceled: (_, _) {
        autoScroller.end();
        dragSession.end();
      },
      feedback: _DragFeedbackPill(
        exerciseName: exerciseName,
        width: pillWidth,
        dragSession: dragSession,
      ),
      childWhenDragging: Opacity(opacity: 0.3, child: icon),
      child: icon,
    );
  }
}

/// Compact pill shown under the finger while dragging an exercise card.
/// Occludes far less of the screen than dragging the full card, so the
/// user can see and aim at the reorder gaps between groups. Fades to 60%
/// opacity (P3.2) when the pointer has been outside every valid drop
/// target for more than 250 ms, signalling "no target here".
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
          duration: const Duration(milliseconds: 150),
          opacity: dimmed ? 0.6 : 1.0,
          child: Material(
            elevation: 8,
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: Container(
              width: width,
              height: AppSpacing.touchMin,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: colors.primary, width: 2),
              ),
              child: Row(
                children: [
                  Icon(Icons.drag_indicator, size: 20, color: colors.primary),
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
                  Icon(Icons.swap_vert, size: 18, color: colors.onSurfaceMuted),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
