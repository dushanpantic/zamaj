import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
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

class _DraggableExerciseState extends State<DraggableExercise> {
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
        // A dragged exercise that is itself part of a superset cannot
        // create or append to a new superset by being dropped onto a
        // standalone card. Drag-to-ungroup remains the supported flow
        // for leaving a superset; the within-superset reorder gaps
        // handle in-place moves.
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
            target: DropTarget.ontoExercise(widget.exercise.sessionExercise.id),
          ),
        );
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        if (highlight != _registered) {
          // candidate count changed via builder rebuild; sync our flag in a
          // post-frame callback so the haptic fires on the enter transition.
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _setRegistered(highlight);
          });
        }
        return AnimatedScale(
          duration: const Duration(milliseconds: 80),
          scale: highlight ? 0.98 : 1,
          child: Stack(
            children: [
              widget.child,
              Positioned.fill(
                child: IgnorePointer(
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 120),
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
        color: colors.primary.withValues(alpha: 0.08),
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
              Icon(Icons.link, size: 18, color: colors.onPrimary),
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
