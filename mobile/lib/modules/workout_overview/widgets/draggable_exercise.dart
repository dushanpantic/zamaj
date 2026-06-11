import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/drag_hover_registration.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

/// Wraps an exercise card with a DragTarget so the whole card body accepts
/// drops to start a superset. The drag *source* (the LongPressDraggable) is
/// scoped to the dedicated handle inside [ExerciseCard] — see [DragHandle] —
/// so the long-press gesture can't compete with taps on LOG SET / kebab /
/// header-tap-to-expand elsewhere on the card.
class DraggableExercise extends StatefulWidget {
  const DraggableExercise({
    super.key,
    required this.exercise,
    required this.canMutate,
    required this.dragSession,
    required this.child,
  });

  final ExerciseViewModel exercise;
  final bool canMutate;
  final DragSession dragSession;
  final Widget child;

  @override
  State<DraggableExercise> createState() => _DraggableExerciseState();
}

class _DraggableExerciseState extends State<DraggableExercise>
    with DragHoverRegistration<DraggableExercise> {
  @override
  DragSession get dragSession => widget.dragSession;

  @override
  Widget build(BuildContext context) {
    final isUnfinished =
        widget.exercise.sessionExercise.state is UnfinishedState;

    return DragTarget<ExerciseDragPayload>(
      onWillAcceptWithDetails: (details) {
        if (!widget.canMutate) return false;
        if (details.data.sessionExerciseId ==
            widget.exercise.sessionExercise.id) {
          return false;
        }
        if (!isUnfinished) return false;
        if (widget.exercise.sessionExercise.supersetTag != null) return false;
        // A dragged exercise that is itself part of a superset cannot create
        // or append to a new superset by being dropped onto a standalone card,
        // so such a drop is rejected here. Leaving a superset is done via the
        // header ungroup button, and the within-superset reorder gaps handle
        // in-place moves.
        if (details.data.supersetTag != null) return false;
        return true;
      },
      onLeave: (_) => clearHoverRegistration(),
      onAcceptWithDetails: (details) {
        clearHoverRegistration();
        Haptics.tap();
        context.read<WorkoutOverviewBloc>().add(
          WorkoutOverviewDropResolved(
            draggedSessionExerciseId: details.data.sessionExerciseId,
            target: DropTarget.ontoExercise(widget.exercise.sessionExercise.id),
          ),
        );
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        syncHoverRegistration(highlight);
        return AnimatedScale(
          duration: AppDuration.fast,
          scale: highlight ? 0.98 : 1,
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: AppDuration.base,
                    opacity: highlight ? 1 : 0,
                    child: _SupersetDropOverlay(),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Hover overlay shown on a card that's a valid drop target for a
/// superset-create gesture. Tints the card with the primary colour at low
/// alpha and centres a "Group as superset" pill so the user can tell this
/// drop is different from a reorder-into-gap drop.
class _SupersetDropOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: AppOpacity.tintFillSubtle),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppIcon(
                Icons.link,
                size: AppIconSize.md,
                color: colors.onPrimary,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Group as superset',
                style: typography.actionLabel.copyWith(color: colors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
