import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/bloc/bloc.dart';
import 'package:zamaj/modules/workout_overview/models/exercise_view_model.dart';
import 'package:zamaj/modules/workout_overview/models/superset_group_view_model.dart';
import 'package:zamaj/modules/workout_overview/services/drag_auto_scroller.dart';
import 'package:zamaj/modules/workout_overview/services/drag_session.dart';
import 'package:zamaj/modules/workout_overview/widgets/delayed_mutation_indicator.dart';
import 'package:zamaj/modules/workout_overview/widgets/notes_section.dart';
import 'package:zamaj/modules/workout_overview/widgets/reorder_gap.dart';
import 'package:zamaj/modules/workout_overview/widgets/session_ended_banner.dart';
import 'package:zamaj/modules/workout_overview/widgets/transient_error_banner.dart';
import 'package:zamaj/modules/workout_overview/widgets/workout_group_builder.dart';

/// Scrollable loaded body of the workout overview: the assembled list of
/// exercise groups with reorder gaps between them, the notes / extra-work
/// sections, and the top-of-screen mutation indicator. Owns the scroll
/// controller, the drag auto-scroller, and the shared drag session.
class WorkoutOverviewLoadedBody extends StatefulWidget {
  const WorkoutOverviewLoadedBody({
    super.key,
    required this.state,
    required this.currentSessionExerciseIds,
    required this.onEndOrSkip,
    required this.onUngroup,
    required this.onGroupInto,
    required this.onOpenVideo,
    required this.onAddNote,
    required this.onAddExtraWork,
  });

  final WorkoutOverviewLoaded state;
  final Set<String> currentSessionExerciseIds;

  /// The single adaptive terminal action (Skip exercise / End exercise).
  final void Function(ExerciseViewModel) onEndOrSkip;
  final void Function(String tag) onUngroup;
  final void Function(
    ExerciseViewModel,
    List<ExerciseViewModel>,
    List<SupersetGroup>,
  )
  onGroupInto;
  final void Function(String url) onOpenVideo;
  final VoidCallback onAddNote;
  final VoidCallback onAddExtraWork;

  @override
  State<WorkoutOverviewLoadedBody> createState() =>
      _WorkoutOverviewLoadedBodyState();
}

class _WorkoutOverviewLoadedBodyState extends State<WorkoutOverviewLoadedBody>
    with SingleTickerProviderStateMixin {
  /// Per-process gate: the coach-mark fires once per cold start, then never
  /// again until the app is killed. Persisting "once-ever" is deferred to
  /// the planned cross-screen coach-mark refactor.
  static bool _coachMarkShownThisSession = false;

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _scrollViewKey = GlobalKey();
  late final DragAutoScroller _autoScroller;
  final DragSession _dragSession = DragSession();

  @override
  void initState() {
    super.initState();
    _autoScroller = DragAutoScroller(
      tickerProvider: this,
      scrollController: _scrollController,
      viewportTopProvider: _viewportTop,
      viewportBottomProvider: _viewportBottom,
      edgeZone: 96,
      maxSpeed: 1000,
    );
  }

  @override
  void dispose() {
    _autoScroller.dispose();
    _scrollController.dispose();
    _dragSession.dispose();
    super.dispose();
  }

  double _viewportTop() {
    final box = _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return 0;
    return box.localToGlobal(Offset.zero).dy;
  }

  double _viewportBottom() {
    final box = _scrollViewKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.attached) return double.infinity;
    final origin = box.localToGlobal(Offset.zero);
    return origin.dy + box.size.height;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowCoachMark();
  }

  @override
  void didUpdateWidget(covariant WorkoutOverviewLoadedBody old) {
    super.didUpdateWidget(old);
    _maybeShowCoachMark();
  }

  void _maybeShowCoachMark() {
    if (_coachMarkShownThisSession) return;
    final unfinishedStandalone = widget.state.groups.where((g) {
      if (g is! SingleGroupViewModel) return false;
      return g.exercise.sessionExercise.state is UnfinishedState;
    }).length;
    if (unfinishedStandalone < 2) return;
    _coachMarkShownThisSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colors = Theme.of(context).appColors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 8),
          backgroundColor: colors.surface,
          content: Text(
            'Tip: Reorder with the drag handle, or use the exercise menu → '
            'Move up / Move down. Drop one card onto another to group them '
            'into a superset.',
            style: AppTypography.standard.bodySmall.copyWith(
              color: colors.onSurface,
            ),
          ),
          action: SnackBarAction(
            label: 'Got it',
            textColor: colors.primary,
            onPressed: () {},
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.state;
    final bloc = context.read<WorkoutOverviewBloc>();
    final transient = state.lastTransientError;
    // canLog gates new logs and structural changes (reorder, skip, mark-done,
    // group-into, notes) — i.e. "the session is still live". Editing an
    // already-logged set is gated separately, per row, by canEditExecuted so
    // completed values stay correctable after the session ends. canLog
    // deliberately ignores mutationInFlight: gating UI visibility on the
    // in-flight flag made the kebab and reorder gaps appear/disappear during
    // the brief window between a tap and the engine's response, shifting layout
    // back-and-forth on every LOG SET. Race prevention against concurrent
    // mutations is already handled in [WorkoutOverviewBloc._runMutation], which
    // returns early when a mutation is already in flight.
    final canLog = state.canLog;

    return Stack(
      children: [
        CustomScrollView(
          key: _scrollViewKey,
          controller: _scrollController,
          slivers: [
            if (transient != null)
              SliverToBoxAdapter(
                child: TransientErrorBanner(
                  error: transient,
                  onDismiss: () =>
                      bloc.add(const WorkoutOverviewErrorDismissed()),
                ),
              ),
            if (state.isEnded)
              const SliverToBoxAdapter(child: SessionEndedBanner()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.md,
                AppSpacing.lg,
                AppSpacing.md,
              ),
              sliver: SliverList.builder(
                itemCount: state.groups.length * 2 + 1,
                itemBuilder: (context, index) {
                  if (index.isEven) {
                    final gapIndex = index ~/ 2;
                    return ReorderGap(
                      sessionId: state.sessionState.session.id,
                      unfinishedIndex: _unfinishedIndexAt(
                        state.groups,
                        gapIndex,
                      ),
                      enabled: canLog,
                      dragSession: _dragSession,
                    );
                  }
                  final groupIndex = (index - 1) ~/ 2;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 0),
                    child: WorkoutGroupBuilder(
                      group: state.groups[groupIndex],
                      state: state,
                      currentSessionExerciseIds:
                          widget.currentSessionExerciseIds,
                      onEndOrSkip: widget.onEndOrSkip,
                      onUngroup: widget.onUngroup,
                      onGroupInto: widget.onGroupInto,
                      onOpenVideo: widget.onOpenVideo,
                      canMutate: canLog,
                      autoScroller: _autoScroller,
                      dragSession: _dragSession,
                    ),
                  );
                },
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.sm,
                AppSpacing.lg,
                AppSpacing.lg,
              ),
              sliver: SliverList.list(
                children: [
                  SessionNotesSection(
                    notes: state.sessionState.session.notes,
                    canAdd: canLog,
                    onAddPressed: widget.onAddNote,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  ExtraWorkSection(
                    extraWork: state.sessionState.session.extraWork,
                    canAdd: canLog,
                    onAddPressed: widget.onAddExtraWork,
                  ),
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
          ],
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: DelayedMutationIndicator(inFlight: state.mutationInFlight),
        ),
      ],
    );
  }

  /// Translates a gap-between-groups index into the "unfinished count at or
  /// before this gap" the reorder semantics want — i.e. the number of
  /// unfinished exercises that appear strictly before the gap.
  int _unfinishedIndexAt(List<SupersetGroupViewModel> groups, int gapIndex) {
    var count = 0;
    for (var i = 0; i < gapIndex && i < groups.length; i++) {
      for (final ex in groups[i].allExercises) {
        if (ex.sessionExercise.state is UnfinishedState) count++;
      }
    }
    return count;
  }
}
