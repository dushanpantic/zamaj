import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/drag_hover_registration.dart';
import 'package:zamaj/modules/workout_overview/widgets/overview_drag_payload.dart';

/// Drop zone between two exercise groups. The hit area is always
/// [_restHitHeight] tall so the user has a comfortable target while
/// dragging; the visible indicator is a thin centered line at rest, a
/// taller bar with a muted "Move here" label while a drag is active, and
/// a full-width primary bar when a drag is hovering directly over it.
class ReorderGap extends StatefulWidget {
  const ReorderGap({
    super.key,
    required this.sessionId,
    required this.unfinishedIndex,
    required this.enabled,
    required this.dragSession,
  });

  final String sessionId;
  final int unfinishedIndex;
  final bool enabled;
  final DragSession dragSession;

  @override
  State<ReorderGap> createState() => _ReorderGapState();
}

class _ReorderGapState extends State<ReorderGap>
    with DragHoverRegistration<ReorderGap> {
  static const double _restHitHeight = 32;
  static const double _activeHitHeight = 40;
  static const double _hoverHitHeight = 48;

  @override
  DragSession get dragSession => widget.dragSession;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return AnimatedBuilder(
      animation: widget.dragSession,
      builder: (context, _) {
        final dragActive = widget.dragSession.active && widget.enabled;
        return DragTarget<OverviewDragPayload>(
          onWillAcceptWithDetails: (details) {
            if (!widget.enabled) return false;
            switch (details.data) {
              // Members of a superset reorder inside their own group via the
              // intra-superset gaps. Letting one land on a top-level gap would
              // split the contiguous run and silently break the group; only a
              // standalone (untagged) exercise reorders here.
              case ExerciseDragPayload(:final supersetTag):
                return supersetTag == null;
              // A whole superset reorders by being dropped into a between-group
              // gap — moved as one contiguous block.
              case SupersetDragPayload():
                return true;
            }
          },
          onLeave: (_) => clearHoverRegistration(),
          onAcceptWithDetails: (details) {
            clearHoverRegistration();
            Haptics.tap();
            final bloc = context.read<WorkoutOverviewBloc>();
            switch (details.data) {
              case ExerciseDragPayload(:final sessionExerciseId):
                bloc.add(
                  WorkoutOverviewDropResolved(
                    draggedSessionExerciseId: sessionExerciseId,
                    target: DropTarget.beforeIndex(widget.unfinishedIndex),
                  ),
                );
              case SupersetDragPayload(:final tag):
                bloc.add(
                  WorkoutOverviewSupersetReordered(
                    supersetTag: tag,
                    targetUnfinishedIndex: widget.unfinishedIndex,
                  ),
                );
            }
          },
          builder: (context, candidate, _) {
            final hovering = candidate.isNotEmpty && widget.enabled;
            syncHoverRegistration(hovering);
            final supersetHovering =
                hovering &&
                candidate.whereType<SupersetDragPayload>().isNotEmpty;
            // A superset hover gets its own "Move superset here" label so the
            // group move reads differently from a single-card reorder.
            final showLabel = supersetHovering || (dragActive && !hovering);
            final labelText = supersetHovering
                ? 'Move superset here'
                : 'Move here';
            final labelColor = supersetHovering
                ? colors.primary
                : colors.onSurfaceMuted;
            final height = hovering
                ? _hoverHitHeight
                : dragActive
                ? _activeHitHeight
                : _restHitHeight;
            final barHeight = hovering
                ? 6.0
                : dragActive
                ? 4.0
                : 2.0;
            // Full-width bar only for a plain single-card hover; the labelled
            // layouts (active drag, superset hover) inset the bars to make room.
            final barMargin = (hovering && !supersetHovering)
                ? 0.0
                : dragActive
                ? AppSpacing.lg
                : AppSpacing.xl;
            final barColor = hovering
                ? colors.primary
                : dragActive
                ? colors.primary.withValues(alpha: AppOpacity.dropTargetActive)
                : colors.outline.withValues(alpha: AppOpacity.dropTargetIdle);
            return AnimatedContainer(
              duration: AppDuration.base,
              curve: AppCurve.standard,
              height: height,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: AppDuration.base,
                      curve: AppCurve.standard,
                      height: barHeight,
                      margin: EdgeInsets.symmetric(horizontal: barMargin),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  if (showLabel) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        labelText,
                        style: typography.caption.copyWith(color: labelColor),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AnimatedContainer(
                        duration: AppDuration.base,
                        curve: AppCurve.standard,
                        height: barHeight,
                        margin: EdgeInsets.symmetric(horizontal: barMargin),
                        decoration: BoxDecoration(
                          color: barColor,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }
}
