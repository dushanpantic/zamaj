import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/drop_intent.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/exercise_card.dart';

/// Drop zone between two members of the same superset (or at the top/bottom
/// edges of the member list). Accepts only payloads whose `supersetTag`
/// matches [supersetTag] — that gating is what keeps the contiguous run
/// intact: an outsider dropped here would split the group, and a member
/// dropped onto a top-level gap would do the same in reverse.
///
/// On accept, dispatches a [DropTarget.beforeIndex] with the absolute
/// unfinishedIndex this gap was anchored to. The existing reorder path in
/// the engine permutes positions among unfinished slots; tags are
/// untouched, so the assembler still treats the group as one superset.
class SupersetReorderGap extends StatefulWidget {
  const SupersetReorderGap({
    super.key,
    required this.supersetTag,
    required this.unfinishedIndex,
    required this.dragSession,
  });

  final String supersetTag;
  final int unfinishedIndex;
  final DragSession dragSession;

  @override
  State<SupersetReorderGap> createState() => _SupersetReorderGapState();
}

class _SupersetReorderGapState extends State<SupersetReorderGap> {
  static const double _restHitHeight = 8;
  static const double _activeHitHeight = 24;
  static const double _hoverHitHeight = 32;

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
    return AnimatedBuilder(
      animation: widget.dragSession,
      builder: (context, _) {
        final dragActive = widget.dragSession.active;
        return DragTarget<ExerciseDragPayload>(
          onWillAcceptWithDetails: (details) {
            return details.data.supersetTag == widget.supersetTag;
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
            final hovering = candidate.isNotEmpty;
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
                ? 4.0
                : dragActive
                ? 2.0
                : 0.0;
            final barColor = hovering
                ? colors.primary
                : colors.primary.withValues(alpha: 0.55);
            return AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              curve: Curves.easeOut,
              height: height,
              alignment: Alignment.center,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 120),
                curve: Curves.easeOut,
                height: barHeight,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
