import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_group_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/undoable_set.dart';
import 'package:zamaj/modules/focus_mode/services/focus_mode_assembler.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_bodyweight_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_complete_button.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_rep_based_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_rest_timer_bar.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_set_progress.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_time_based_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_workout_complete_view.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/replace_exercise_dialog.dart';

/// Top-level execution screen. Renders the focused group as one ACTIVE
/// panel (with full editor) plus compact PARTNER cards for any other
/// superset members. A single pinned LOG SET at the bottom targets the
/// active panel. The rest timer and "switch exercise" affordance in the
/// app bar are shared across panels.
class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return MultiBlocListener(
      listeners: [
        BlocListener<FocusModeBloc, FocusModeState>(
          listenWhen: _isSetJustLogged,
          listener: (_, _) => Haptics.tap(),
        ),
        BlocListener<FocusModeBloc, FocusModeState>(
          listenWhen: (p, c) =>
              p is! FocusModeWorkoutComplete && c is FocusModeWorkoutComplete,
          listener: (_, _) => Haptics.emphasis(),
        ),
        BlocListener<FocusModeBloc, FocusModeState>(
          listenWhen: _restJustWentOvertime,
          listener: (_, _) => Haptics.emphasis(),
        ),
      ],
      child: BlocBuilder<FocusModeBloc, FocusModeState>(
        builder: (context, state) {
          return Scaffold(
            backgroundColor: colors.background,
            appBar: _appBarFor(context, state),
            body: SafeArea(child: _body(context, state)),
          );
        },
      ),
    );
  }

  static bool _isSetJustLogged(FocusModeState p, FocusModeState c) {
    if (c is! FocusModeReady) return false;
    final priorId = p is FocusModeReady ? p.undoable?.executedSetId : null;
    final nextId = c.undoable?.executedSetId;
    return nextId != null && nextId != priorId;
  }

  static bool _restJustWentOvertime(FocusModeState p, FocusModeState c) {
    if (c is! FocusModeReady) return false;
    final nextOver = c.restTimer?.isOvertime ?? false;
    if (!nextOver) return false;
    final priorOver =
        (p is FocusModeReady ? p.restTimer?.isOvertime : null) ?? false;
    return !priorOver;
  }

  PreferredSizeWidget _appBarFor(BuildContext context, FocusModeState state) {
    final title = switch (state) {
      FocusModeInitial() => 'Focus',
      FocusModeLoading() => 'Focus',
      FocusModeNotFound() => 'Focus',
      FocusModeLoadFailure() => 'Focus',
      FocusModeWorkoutComplete(:final sessionState) =>
        sessionState.session.snapshot.workoutDay.name,
      FocusModeReady(:final groupViewModel) => groupViewModel.workoutDayName,
    };
    final ready = state is FocusModeReady ? state : null;
    return AppBar(
      title: Text(title),
      actions: [
        if (ready != null) ...[_SwitchExerciseButton(state: ready)],
      ],
    );
  }

  Widget _body(BuildContext context, FocusModeState state) {
    return switch (state) {
      FocusModeInitial() || FocusModeLoading() => const _LoadingView(),
      FocusModeNotFound() => const _NotFoundView(),
      FocusModeLoadFailure(:final error) => _ErrorView(
        error: error,
        onRetry: () =>
            context.read<FocusModeBloc>().add(const FocusModeRetried()),
      ),
      FocusModeWorkoutComplete(:final sessionState) => FocusWorkoutCompleteView(
        workoutDayName: sessionState.session.snapshot.workoutDay.name,
        onBackToOverview: () => Navigator.of(context).maybePop(),
      ),
      FocusModeReady() => _ReadyBody(state: state),
    };
  }
}

class _ReadyBody extends StatelessWidget {
  const _ReadyBody({required this.state});

  final FocusModeReady state;

  @override
  Widget build(BuildContext context) {
    final group = state.groupViewModel;
    final canMutate = !state.mutationInFlight;

    final activeId = group.activeSessionExerciseId;
    final activePanel = activeId == null
        ? null
        : group.panels.firstWhere(
            (p) => p.sessionExerciseId == activeId,
            orElse: () => group.panels.first,
          );
    final partnerPanels = [
      for (final panel in group.panels)
        if (panel.sessionExerciseId != activeId) panel,
    ];

    return Stack(
      children: [
        Column(
          children: [
            _SupersetUpNextStrip(group: group),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.md,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (activePanel != null) ...[
                      _ActivePanelCard(
                        state: state,
                        panel: activePanel,
                        canMutate: canMutate,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],
                    if (partnerPanels.isNotEmpty)
                      Expanded(
                        child: _PartnerPanelList(
                          state: state,
                          panels: partnerPanels,
                          canMutate: canMutate,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _PinnedBottomBar(
              state: state,
              activePanel: activePanel,
              canMutate: canMutate,
            ),
          ],
        ),
        if (state.lastTransientError != null)
          Positioned(
            top: AppSpacing.sm,
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            child: _TransientErrorBanner(
              error: state.lastTransientError!,
              onDismiss: () => context.read<FocusModeBloc>().add(
                const FocusModeErrorDismissed(),
              ),
            ),
          ),
        if (state.mutationInFlight)
          const Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: LinearProgressIndicator(minHeight: 2),
          ),
      ],
    );
  }
}

/// Compact strip directly below the app bar. Shows the superset label
/// (when applicable) and the "Up next" caption for the following group.
/// Sized small so it doesn't eat into the editor area.
class _SupersetUpNextStrip extends StatelessWidget {
  const _SupersetUpNextStrip({required this.group});

  final FocusModeGroupViewModel group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isSuperset = group.supersetTag != null;
    final upNext = group.upNextGroupLabel;
    if (!isSuperset && upNext == null) {
      return const SizedBox.shrink();
    }
    final supersetLabel = isSuperset
        ? 'Superset · ${group.panels.map((p) => p.displayExerciseName).join(' + ')}'
        : null;
    final segments = <String>[
      ?supersetLabel,
      if (upNext != null) 'Up next: $upNext',
    ];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          if (isSuperset) ...[
            Icon(Icons.link, size: 16, color: colors.onSurfaceMuted),
            const SizedBox(width: AppSpacing.xs),
          ],
          Expanded(
            child: Text(
              segments.join('  ·  '),
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full editor for the currently active panel — pips, planned/last,
/// numeric hero + bump rows, 3-dot menu. The LOG SET button lives in the
/// pinned bottom bar, not inside the card.
class _ActivePanelCard extends StatelessWidget {
  const _ActivePanelCard({
    required this.state,
    required this.panel,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel panel;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      key: ValueKey('active-panel-${panel.sessionExerciseId}'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _PanelHeader(panel: panel)),
              _PanelActionsMenu(state: state, panel: panel),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          FocusSetProgress(
            completed: panel.completedSetsCount,
            total: panel.totalPlannedSets,
            currentIndex: panel.currentSetIndex,
          ),
          const SizedBox(height: AppSpacing.md),
          _PlannedAndLast(panel: panel),
          const SizedBox(height: AppSpacing.md),
          _CurrentValuesPanel(state: state, panel: panel, canMutate: canMutate),
        ],
      ),
    );
  }
}

/// Stack of partner cards for the non-active panels in a superset group.
/// The cards stay non-scrolling when they fit; falls back to a scrollable
/// list only when they overflow (e.g. a 3-exercise giant set on a small
/// device). The active card + pinned LOG SET remain fixed regardless.
class _PartnerPanelList extends StatelessWidget {
  const _PartnerPanelList({
    required this.state,
    required this.panels,
    required this.canMutate,
  });

  final FocusModeReady state;
  final List<FocusModeViewModel> panels;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < panels.length; i++) ...[
            _PartnerPanelCard(
              state: state,
              panel: panels[i],
              canMutate: canMutate,
            ),
            if (i < panels.length - 1) const SizedBox(height: AppSpacing.sm),
          ],
        ],
      ),
    );
  }
}

/// Compact two-row card representing a non-active superset member. The
/// whole card is a tap target → makes that exercise active (overrides
/// auto-rotation). The 3-dot menu still works (replace / skip / mark
/// done / open video) so the user doesn't have to switch first to skip.
class _PartnerPanelCard extends StatelessWidget {
  const _PartnerPanelCard({
    required this.state,
    required this.panel,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel panel;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isCompleted = !panel.isLoggable;
    final onTap = (isCompleted || !canMutate)
        ? null
        : () {
            Haptics.tap();
            context.read<FocusModeBloc>().add(
              FocusModeFocusedPanelSelected(panel.sessionExerciseId),
            );
          };
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: Container(
          constraints: const BoxConstraints(minHeight: AppSpacing.touchMin + 8),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surface.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: colors.outline.withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      panel.displayExerciseName,
                      style: typography.titleSmall.copyWith(
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  if (isCompleted)
                    Icon(
                      Icons.check_circle,
                      color: colors.exerciseCompleted,
                      size: 20,
                    )
                  else
                    FocusSetProgress(
                      completed: panel.completedSetsCount,
                      total: panel.totalPlannedSets,
                      currentIndex: panel.currentSetIndex,
                    ),
                  _PanelActionsMenu(state: state, panel: panel),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _partnerSubtitle(panel),
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _partnerSubtitle(FocusModeViewModel panel) {
    final planned = _formatPlanned(
      panel.currentPlannedValues,
      panel.plannedSummary,
    );
    final last = _formatLast(panel.lastExecutedValues);
    final segments = <String>[
      'Planned: $planned',
      if (last != null) 'Last: $last',
    ];
    return segments.join('  ·  ');
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({required this.panel});

  final FocusModeViewModel panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isWarmup = panel.plannedGroupRole == ExerciseGroupRole.warmup;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isWarmup) ...[
          _WarmupPill(colors: colors),
          const SizedBox(height: AppSpacing.xs),
        ],
        Text(
          panel.displayExerciseName,
          style: typography.title.copyWith(color: colors.onBackground),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (panel.isReplaced) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Replaced from "${panel.plannedExerciseName}"',
            style: typography.caption.copyWith(color: colors.exerciseReplaced),
          ),
        ],
      ],
    );
  }
}

class _WarmupPill extends StatelessWidget {
  const _WarmupPill({required this.colors});

  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: colors.warmup.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: colors.warmup.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, size: 12, color: colors.warmup),
          const SizedBox(width: 4),
          Text(
            'WARMUP',
            style: AppTypography.standard.caption.copyWith(
              color: colors.warmup,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlannedAndLast extends StatelessWidget {
  const _PlannedAndLast({required this.panel});

  final FocusModeViewModel panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final plannedLabel = _formatPlanned(
      panel.currentPlannedValues,
      panel.plannedSummary,
    );
    final lastLabel = _formatLast(panel.lastExecutedValues);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Planned',
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                plannedLabel,
                style: typography.numeric.copyWith(color: colors.planned),
              ),
            ),
          ],
        ),
        if (lastLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Last',
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  lastLabel,
                  style: typography.numeric.copyWith(color: colors.actual),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String _formatPlanned(PlannedSetValues? values, String summary) {
  if (values == null) return summary;
  return switch (values) {
    PlannedRepBased(:final weightKg, :final repTarget) =>
      '${WeightFormatter.formatKg(weightKg)}kg × ${RepTargetFormatter.format(repTarget)}',
    PlannedTimeBased(:final durationSeconds, :final weightKg) =>
      weightKg == null
          ? '${durationSeconds}s'
          : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
    PlannedBodyweight(:final repTarget) =>
      '× ${RepTargetFormatter.format(repTarget)}',
  };
}

String? _formatLast(ActualSetValues? values) {
  if (values == null) return null;
  return switch (values) {
    ActualRepBased(:final weightKg, :final reps) =>
      '${WeightFormatter.formatKg(weightKg)}kg × $reps',
    ActualTimeBased(:final durationSeconds, :final weightKg) =>
      weightKg == null
          ? '${durationSeconds}s'
          : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
    ActualBodyweight(:final reps) => '× $reps',
  };
}

class _CurrentValuesPanel extends StatelessWidget {
  const _CurrentValuesPanel({
    required this.state,
    required this.panel,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel panel;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FocusModeBloc>();
    final exerciseId = panel.sessionExerciseId;
    final draft = state.draftFor(exerciseId);
    if (draft == null) return const SizedBox.shrink();
    final stopwatchActive = state.activeStopwatchExerciseId == exerciseId;
    return switch (draft) {
      ActualRepBased(:final weightKg, :final reps) => FocusRepBasedPanel(
        weightKg: weightKg,
        reps: reps,
        enabled: canMutate,
        onWeightBump: (delta) => bloc.add(
          FocusModeWeightBumped(sessionExerciseId: exerciseId, delta: delta),
        ),
        onRepsBump: (delta) => bloc.add(
          FocusModeRepsBumped(sessionExerciseId: exerciseId, delta: delta),
        ),
        onWeightCommitted: (v) => bloc.add(
          FocusModeWeightEdited(sessionExerciseId: exerciseId, weightKg: v),
        ),
        onRepsCommitted: (v) => bloc.add(
          FocusModeRepsEdited(sessionExerciseId: exerciseId, reps: v),
        ),
      ),
      ActualTimeBased(:final durationSeconds, :final weightKg) =>
        FocusTimeBasedPanel(
          durationSeconds: durationSeconds,
          weightKg: weightKg,
          stopwatch: stopwatchActive
              ? state.stopwatch
              : StopwatchViewModel.idle(),
          enabled: canMutate,
          onDurationBump: (delta) => bloc.add(
            FocusModeDurationBumped(
              sessionExerciseId: exerciseId,
              delta: delta,
            ),
          ),
          onDurationCommitted: (v) => bloc.add(
            FocusModeDurationEdited(sessionExerciseId: exerciseId, seconds: v),
          ),
          onWeightBump: (delta) => bloc.add(
            FocusModeWeightBumped(sessionExerciseId: exerciseId, delta: delta),
          ),
          onWeightCommitted: (v) => bloc.add(
            FocusModeWeightEdited(sessionExerciseId: exerciseId, weightKg: v),
          ),
          onWeightCleared: () => bloc.add(
            FocusModeWeightEdited(
              sessionExerciseId: exerciseId,
              weightKg: null,
            ),
          ),
          onStopwatchStart: () =>
              bloc.add(FocusModeStopwatchStarted(exerciseId)),
          onStopwatchStop: () => bloc.add(const FocusModeStopwatchStopped()),
        ),
      ActualBodyweight(:final reps) => FocusBodyweightPanel(
        reps: reps,
        enabled: canMutate,
        onRepsBump: (delta) => bloc.add(
          FocusModeRepsBumped(sessionExerciseId: exerciseId, delta: delta),
        ),
        onRepsCommitted: (v) => bloc.add(
          FocusModeRepsEdited(sessionExerciseId: exerciseId, reps: v),
        ),
      ),
    };
  }
}

/// Pinned bottom region. Contains the LOG SET button (when an active
/// panel is loggable), the rest timer (when active), and the undo
/// affordance (when a set was just logged). Single primary action per
/// screen — the LOG SET button always targets the active panel.
class _PinnedBottomBar extends StatelessWidget {
  const _PinnedBottomBar({
    required this.state,
    required this.activePanel,
    required this.canMutate,
  });

  final FocusModeReady state;
  final FocusModeViewModel? activePanel;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bloc = context.read<FocusModeBloc>();
    final isResting = state.restTimer != null;
    final hasLogButton = activePanel != null;
    if (!hasLogButton && !isResting && state.undoable == null) {
      return const SizedBox.shrink();
    }

    return Container(
      decoration: BoxDecoration(
        color: colors.background,
        border: Border(top: BorderSide(color: colors.outline)),
      ),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        AppSpacing.md,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (activePanel != null)
            FocusCompleteButton(
              onPressed: () => bloc.add(
                FocusModeSetCompleted(activePanel!.sessionExerciseId),
              ),
              label: 'LOG SET — ${activePanel!.displayExerciseName}',
              subLabel: activePanel!.totalPlannedSets > 0
                  ? 'Set ${activePanel!.currentSetIndex + 1} of ${activePanel!.totalPlannedSets}'
                  : null,
              enabled: canMutate,
            ),
          if (isResting) ...[
            if (activePanel != null) const SizedBox(height: AppSpacing.sm),
            FocusRestTimerBar(
              timer: state.restTimer!,
              onPauseToggle: () => bloc.add(
                state.restTimer!.isPaused
                    ? const FocusModeRestResumed()
                    : const FocusModeRestPaused(),
              ),
              onExtend: () => bloc.add(const FocusModeRestExtended()),
              onSkip: () => bloc.add(const FocusModeRestSkipped()),
            ),
          ],
          if (state.undoable != null) ...[
            if (activePanel != null || isResting)
              const SizedBox(height: AppSpacing.xs),
            _UndoLastSetButton(undoable: state.undoable!, enabled: canMutate),
          ],
        ],
      ),
    );
  }
}

class _UndoLastSetButton extends StatelessWidget {
  const _UndoLastSetButton({required this.undoable, required this.enabled});

  final UndoableSet undoable;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: enabled
            ? () => context.read<FocusModeBloc>().add(
                const FocusModeUndoRequested(),
              )
            : null,
        icon: const Icon(Icons.undo),
        label: Text('Undo last set on ${undoable.exerciseDisplayName}'),
        style: TextButton.styleFrom(
          foregroundColor: colors.onSurfaceMuted,
          minimumSize: const Size(0, AppSpacing.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
        ),
      ),
    );
  }
}

class _PanelActionsMenu extends StatelessWidget {
  const _PanelActionsMenu({required this.state, required this.panel});

  final FocusModeReady state;
  final FocusModeViewModel panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final videoUrl = panel.displayMetadata?.videoUrl;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    final canMarkDone =
        panel.completedSetsCount > 0 && panel.isLoggable && !panel.isReplaced;
    return PopupMenuButton<_PanelMenuAction>(
      icon: Icon(Icons.more_vert, color: colors.onSurface),
      onSelected: (action) {
        switch (action) {
          case _PanelMenuAction.replace:
            _handleReplace(context);
          case _PanelMenuAction.skip:
            _handleSkip(context);
          case _PanelMenuAction.markDone:
            _handleMarkDone(context);
          case _PanelMenuAction.openVideo:
            if (hasVideo) _handleOpenVideo(context, videoUrl);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _PanelMenuAction.replace,
          child: ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('Replace exercise'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (canMarkDone)
          const PopupMenuItem(
            value: _PanelMenuAction.markDone,
            child: ListTile(
              leading: Icon(Icons.task_alt),
              title: Text('Mark done'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
        const PopupMenuItem(
          value: _PanelMenuAction.skip,
          child: ListTile(
            leading: Icon(Icons.skip_next),
            title: Text('Skip exercise'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (hasVideo)
          const PopupMenuItem(
            value: _PanelMenuAction.openVideo,
            child: ListTile(
              leading: Icon(Icons.play_circle_outline),
              title: Text('Open video'),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
          ),
      ],
    );
  }

  Future<void> _handleReplace(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final defaults = resolveReplaceExerciseDefaults(
      sessionExerciseId: panel.sessionExerciseId,
      session: state.sessionState.session,
    );
    if (defaults == null) return;
    final result = await presentReplaceFlow(
      context: context,
      plannedExerciseName: panel.plannedExerciseName,
      defaultMeasurementType: panel.effectiveMeasurementType,
      defaultPlannedValues: defaults.plannedValues,
      defaultSetCount: defaults.setCount,
    );
    if (result == null) return;
    bloc.add(
      FocusModeExerciseReplaced(
        sessionExerciseId: panel.sessionExerciseId,
        substituteName: result.name,
        substituteMeasurementType: result.measurementType,
        substitutePlannedValues: result.plannedValues,
        substituteSetCount: result.setCount,
        substituteMetadata: result.metadata,
        substituteLibraryExerciseId: result.libraryExerciseId,
      ),
    );
  }

  Future<void> _handleSkip(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Skip exercise?',
      body:
          'Skipping "${panel.displayExerciseName}" marks it as not done and '
          'moves on. This affects this session only.',
      confirmLabel: 'Skip',
      isDestructive: true,
    );
    if (confirmed != true) return;
    bloc.add(FocusModeExerciseSkipped(panel.sessionExerciseId));
  }

  Future<void> _handleMarkDone(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Mark exercise done?',
      body:
          'Locks "${panel.displayExerciseName}" as completed with the '
          'sets you have so far (${panel.completedSetsCount} of '
          '${panel.totalPlannedSets}).',
      confirmLabel: 'Mark done',
    );
    if (confirmed != true) return;
    bloc.add(FocusModeExerciseMarkedDone(panel.sessionExerciseId));
  }

  Future<void> _handleOpenVideo(BuildContext context, String url) async {
    final launcher = context.read<ExternalLinkLauncher>();
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    final result = await launcher.launch(uri);
    if (!context.mounted) return;
    if (result is ExternalLinkFailure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open video: ${result.reason}')),
      );
    }
  }
}

enum _PanelMenuAction { replace, skip, markDone, openVideo }

/// App-bar action that opens a "switch to" picker, listing every other
/// visible group in the session. Tapping an option dispatches
/// [FocusModeGroupSwitched] and the panels refresh in place.
class _SwitchExerciseButton extends StatelessWidget {
  const _SwitchExerciseButton({required this.state});

  final FocusModeReady state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final options = FocusModeAssembler.listSwitchOptions(
      state.sessionState,
      currentAnchorId: state.anchorSessionExerciseId,
    );
    if (options.length <= 1) return const SizedBox.shrink();
    return PopupMenuButton<String>(
      tooltip: 'Switch exercise',
      icon: Icon(Icons.swap_vert, color: colors.onSurface),
      onSelected: (anchorId) =>
          context.read<FocusModeBloc>().add(FocusModeGroupSwitched(anchorId)),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<String>(
            value: option.anchorSessionExerciseId,
            enabled: !option.isCurrent,
            child: Row(
              children: [
                Icon(
                  option.isSuperset ? Icons.link : Icons.fitness_center,
                  size: 18,
                  color: colors.onSurfaceMuted,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(child: Text(option.label)),
                if (option.isCurrent) ...[
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    '(current)',
                    style: TextStyle(color: colors.onSurfaceMuted),
                  ),
                ],
              ],
            ),
          ),
      ],
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Center(child: CircularProgressIndicator(color: colors.primary));
  }
}

class _NotFoundView extends StatelessWidget {
  const _NotFoundView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: colors.onSurfaceMuted, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Session not found',
              style: typography.titleSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final DomainError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final presented = DomainErrorPresenter.present(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              presented.title,
              style: typography.titleSmall.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              presented.body,
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _TransientErrorBanner extends StatelessWidget {
  const _TransientErrorBanner({required this.error, required this.onDismiss});

  final DomainError error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final presented = DomainErrorPresenter.present(error);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.error.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presented.title,
                    style: typography.label.copyWith(color: colors.error),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    presented.body,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, color: colors.onSurfaceMuted, size: 18),
              constraints: const BoxConstraints(
                minWidth: AppSpacing.touchMin,
                minHeight: AppSpacing.touchMin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
