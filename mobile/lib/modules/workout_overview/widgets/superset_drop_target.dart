import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_motion.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

/// Wraps a whole [SupersetCard] in a DragTarget so an *outside* exercise
/// dropped anywhere on the group is appended to it (a 3rd+ member). The
/// target is `translucent` so it also catches drops on the header and the
/// inter-member padding, while the intra-superset reorder gaps — which are
/// nested deeper and hit-tested first — still own member-to-member moves.
///
/// The two targets partition the payload space and never compete:
///
/// - reorder gaps accept only payloads whose `supersetTag` matches the group
///   (members reordering in place),
/// - this target accepts only payloads with `supersetTag == null` (outsiders
///   joining the group).
///
/// On accept it emits a [DropTarget.ontoExercise] anchored to an unfinished
/// member; the [DropResolver] maps that to an append-to-superset intent.
/// Acceptance is gated on every member still being unfinished, mirroring the
/// menu-driven "Group into superset" path — the engine refuses a group that
/// mixes terminal and live members.
class SupersetDropTarget extends StatefulWidget {
  const SupersetDropTarget({
    super.key,
    required this.anchorSessionExerciseId,
    required this.canAccept,
    required this.dragSession,
    required this.child,
  });

  /// Id of an unfinished member the resolved [DropTarget.ontoExercise] points
  /// at. Any unfinished member works — the resolver only reads its tag.
  final String anchorSessionExerciseId;

  /// Whether the group can currently accept an appended member (session is
  /// live and every existing member is unfinished).
  final bool canAccept;

  final DragSession dragSession;
  final Widget child;

  @override
  State<SupersetDropTarget> createState() => _SupersetDropTargetState();
}

class _SupersetDropTargetState extends State<SupersetDropTarget> {
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
    return DragTarget<ExerciseDragPayload>(
      // Translucent so the whole group — header and padding included — is a
      // valid append zone; deeper reorder gaps are still resolved first.
      hitTestBehavior: HitTestBehavior.translucent,
      onWillAcceptWithDetails: (details) {
        if (!widget.canAccept) return false;
        // Members reorder in place via the intra-superset gaps. Only outside
        // (ungrouped) exercises append here; this guard is what keeps member
        // reorders flowing to the deeper gap targets.
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
            target: DropTarget.ontoExercise(widget.anchorSessionExerciseId),
          ),
        );
      },
      builder: (context, candidate, _) {
        final highlight = candidate.isNotEmpty;
        if (highlight != _registered) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            _setRegistered(highlight);
          });
        }
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
                    child: _AppendToSupersetOverlay(),
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

/// Hover overlay shown on a superset that's a valid drop target for an
/// append gesture. Distinct label ("Add to superset") from the create-a-pair
/// overlay so the user can tell appending to an existing group apart from
/// pairing two standalone cards.
class _AppendToSupersetOverlay extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
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
              Icon(Icons.add_link, size: 18, color: colors.onPrimary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                'Add to superset',
                style: typography.actionLabel.copyWith(color: colors.onPrimary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
