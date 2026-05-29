import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

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

class _ReorderGapState extends State<ReorderGap> {
  static const double _restHitHeight = 32;
  static const double _activeHitHeight = 40;
  static const double _hoverHitHeight = 48;

  bool _registered = false;

  void _setRegistered(bool value) {
    if (_registered == value) return;
    _registered = value;
    if (value) {
      Haptics.selectionChange();
      widget.dragSession.hoverEntered();
    } else {
      widget.dragSession.hoverLeft();
    }
  }

  @override
  void dispose() {
    if (_registered) {
      _registered = false;
      widget.dragSession.hoverLeft();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return AnimatedBuilder(
      animation: widget.dragSession,
      builder: (context, _) {
        final dragActive = widget.dragSession.active && widget.enabled;
        return DragTarget<ExerciseDragPayload>(
          onWillAcceptWithDetails: (details) {
            if (!widget.enabled) return false;
            // Members of a superset reorder inside their own group via the
            // intra-superset gaps. Letting them land on a top-level gap
            // would split the contiguous run and silently break the group.
            if (details.data.supersetTag != null) return false;
            return true;
          },
          onLeave: (_) => _setRegistered(false),
          onAcceptWithDetails: (details) {
            _setRegistered(false);
            Haptics.tap();
            context.read<WorkoutOverviewBloc>().add(
              WorkoutOverviewDropResolved(
                draggedSessionExerciseId: details.data.sessionExerciseId,
                target: DropTarget.beforeIndex(widget.unfinishedIndex),
              ),
            );
          },
          builder: (context, candidate, _) {
            final hovering = candidate.isNotEmpty && widget.enabled;
            if (hovering != _registered) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                _setRegistered(hovering);
              });
            }
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
            final barMargin = hovering
                ? 0.0
                : dragActive
                ? AppSpacing.lg
                : AppSpacing.xl;
            final barColor = hovering
                ? colors.primary
                : dragActive
                ? colors.primary.withValues(alpha: 0.55)
                : colors.outline.withValues(alpha: 0.4);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: height,
              alignment: Alignment.center,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Expanded(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      curve: Curves.easeOut,
                      height: barHeight,
                      margin: EdgeInsets.symmetric(horizontal: barMargin),
                      decoration: BoxDecoration(
                        color: barColor,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                    ),
                  ),
                  if (dragActive && !hovering) ...[
                    const SizedBox(width: AppSpacing.sm),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                      ),
                      child: Text(
                        'Move here',
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 120),
                        curve: Curves.easeOut,
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
