import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/undoable_set.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_complete_button.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_rep_based_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_rest_timer_bar.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_set_progress.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_time_based_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_up_next.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_workout_complete_view.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
import 'package:zamaj/modules/program_management/services/external_link_launcher.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/workout_overview/widgets/replace_exercise_dialog.dart';

/// Top-level execution screen. Single-exercise layout that always renders
/// the cursor target; advances automatically as the bloc reassembles.
class FocusModeScreen extends StatefulWidget {
  const FocusModeScreen({super.key});

  @override
  State<FocusModeScreen> createState() => _FocusModeScreenState();
}

class _FocusModeScreenState extends State<FocusModeScreen> {
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return BlocBuilder<FocusModeBloc, FocusModeState>(
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.background,
          appBar: _appBarFor(context, state),
          body: SafeArea(child: _body(context, state)),
        );
      },
    );
  }

  PreferredSizeWidget _appBarFor(BuildContext context, FocusModeState state) {
    final title = switch (state) {
      FocusModeInitial() => 'Focus',
      FocusModeLoading() => 'Focus',
      FocusModeNotFound() => 'Focus',
      FocusModeLoadFailure() => 'Focus',
      FocusModeWorkoutComplete(:final sessionState) =>
        sessionState.session.snapshot.workoutDay.name,
      FocusModeReady(:final viewModel) => viewModel.workoutDayName,
    };
    final ready = state is FocusModeReady ? state : null;
    return AppBar(
      title: Text(title),
      actions: [if (ready != null) _ExerciseActionsMenu(state: ready)],
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
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final vm = state.viewModel;
    final canMutate = !state.mutationInFlight;
    final isResting = state.restTimer != null;

    return Stack(
      children: [
        Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.md,
                  AppSpacing.lg,
                  AppSpacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (state.lastTransientError != null) ...[
                      _TransientErrorBanner(
                        error: state.lastTransientError!,
                        onDismiss: () => context.read<FocusModeBloc>().add(
                          const FocusModeErrorDismissed(),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],
                    _ExerciseHeader(viewModel: vm),
                    const SizedBox(height: AppSpacing.sm),
                    FocusSetProgress(
                      completed: vm.completedSetsCount,
                      total: vm.totalPlannedSets,
                      currentIndex: vm.currentSetIndex,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    _PlannedAndLast(viewModel: vm),
                    const SizedBox(height: AppSpacing.lg),
                    _CurrentValuesPanel(state: state, canMutate: canMutate),
                    const SizedBox(height: AppSpacing.lg),
                    if (vm.upNextExerciseName != null)
                      FocusUpNext(
                        label: 'Up next',
                        detail: vm.upNextExerciseName!,
                      )
                    else
                      Text(
                        'Last exercise in this session',
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            _PinnedActionBar(
              state: state,
              canMutate: canMutate,
              isResting: isResting,
            ),
          ],
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

/// Pinned bottom action bar. Always reachable with the thumb during a working
/// set so the COMPLETE button never scrolls out of view. During rest, the
/// timer takes visual focus and COMPLETE is demoted to a secondary "Skip rest"
/// affordance — finishing the rest is the only logical next step.
class _PinnedActionBar extends StatelessWidget {
  const _PinnedActionBar({
    required this.state,
    required this.canMutate,
    required this.isResting,
  });

  final FocusModeReady state;
  final bool canMutate;
  final bool isResting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bloc = context.read<FocusModeBloc>();
    final vm = state.viewModel;

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
          if (isResting) ...[
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
            const SizedBox(height: AppSpacing.sm),
            _SkipRestButton(
              enabled: canMutate,
              onPressed: () => bloc.add(const FocusModeRestSkipped()),
            ),
          ] else
            FocusCompleteButton(
              onPressed: () => bloc.add(const FocusModeSetCompleted()),
              label: 'COMPLETE SET',
              subLabel: vm.totalPlannedSets > 0
                  ? 'Set ${vm.currentSetIndex + 1}'
                        '${vm.totalPlannedSets > 0 ? ' of ${vm.totalPlannedSets}' : ''}'
                  : null,
              enabled: canMutate,
            ),
          if (state.undoable != null) ...[
            const SizedBox(height: AppSpacing.xs),
            _UndoLastSetButton(
              undoable: state.undoable!,
              enabled: canMutate,
            ),
          ],
        ],
      ),
    );
  }
}

/// Secondary CTA shown beneath the rest timer. While resting, COMPLETE is
/// demoted; this is the only forward action so it stays prominent (filled
/// tonal) but visually subordinate to the live timer above.
class _SkipRestButton extends StatelessWidget {
  const _SkipRestButton({required this.enabled, required this.onPressed});

  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return SizedBox(
      width: double.infinity,
      height: AppSpacing.touchMin,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.skip_next, size: 20),
        label: const Text('Skip rest → next set'),
        style: FilledButton.styleFrom(
          backgroundColor: colors.surfaceVariant,
          foregroundColor: colors.onSurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
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

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({required this.viewModel});

  final FocusModeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          viewModel.displayExerciseName,
          style: typography.displaySmall.copyWith(color: colors.onBackground),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (viewModel.isReplaced) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Replaced from "${viewModel.plannedExerciseName}"',
            style: typography.caption.copyWith(color: colors.exerciseReplaced),
          ),
        ],
      ],
    );
  }
}

class _PlannedAndLast extends StatelessWidget {
  const _PlannedAndLast({required this.viewModel});

  final FocusModeViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final plannedLabel = _formatPlanned(
      viewModel.currentPlannedValues,
      viewModel.plannedSummary,
    );
    final lastLabel = _formatLast(viewModel.lastExecutedValues);

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

  String _formatPlanned(PlannedSetValues? values, String summary) {
    if (values == null) return summary;
    return switch (values) {
      PlannedRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg × $reps',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
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
    };
  }
}

class _CurrentValuesPanel extends StatelessWidget {
  const _CurrentValuesPanel({required this.state, required this.canMutate});

  final FocusModeReady state;
  final bool canMutate;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<FocusModeBloc>();
    final draft = state.draft;
    return switch (draft) {
      ActualRepBased(:final weightKg, :final reps) => FocusRepBasedPanel(
        weightKg: weightKg,
        reps: reps,
        enabled: canMutate,
        onWeightBump: (delta) => bloc.add(FocusModeWeightBumped(delta)),
        onRepsBump: (delta) => bloc.add(FocusModeRepsBumped(delta)),
        onWeightCommitted: (v) => bloc.add(FocusModeWeightEdited(v)),
        onRepsCommitted: (v) => bloc.add(FocusModeRepsEdited(v)),
      ),
      ActualTimeBased(:final durationSeconds, :final weightKg) =>
        FocusTimeBasedPanel(
          durationSeconds: durationSeconds,
          weightKg: weightKg,
          stopwatch: state.stopwatch,
          enabled: canMutate,
          onDurationBump: (delta) => bloc.add(FocusModeDurationBumped(delta)),
          onDurationCommitted: (v) => bloc.add(FocusModeDurationEdited(v)),
          onWeightBump: (delta) => bloc.add(FocusModeWeightBumped(delta)),
          onWeightCommitted: (v) => bloc.add(FocusModeWeightEdited(v)),
          onWeightCleared: () => bloc.add(const FocusModeWeightEdited(null)),
          onStopwatchStart: () => bloc.add(const FocusModeStopwatchStarted()),
          onStopwatchStop: () => bloc.add(const FocusModeStopwatchStopped()),
        ),
    };
  }
}

class _ExerciseActionsMenu extends StatelessWidget {
  const _ExerciseActionsMenu({required this.state});

  final FocusModeReady state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final vm = state.viewModel;
    final videoUrl = vm.displayMetadata?.videoUrl;
    final hasVideo = videoUrl != null && videoUrl.isNotEmpty;
    return PopupMenuButton<_ExerciseMenuAction>(
      icon: Icon(Icons.more_vert, color: colors.onSurface),
      onSelected: (action) {
        switch (action) {
          case _ExerciseMenuAction.replace:
            _handleReplace(context);
          case _ExerciseMenuAction.skip:
            _handleSkip(context);
          case _ExerciseMenuAction.openVideo:
            if (hasVideo) _handleOpenVideo(context, videoUrl);
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: _ExerciseMenuAction.replace,
          child: ListTile(
            leading: Icon(Icons.swap_horiz),
            title: Text('Replace exercise'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        const PopupMenuItem(
          value: _ExerciseMenuAction.skip,
          child: ListTile(
            leading: Icon(Icons.skip_next),
            title: Text('Skip exercise'),
            contentPadding: EdgeInsets.zero,
            dense: true,
          ),
        ),
        if (hasVideo)
          const PopupMenuItem(
            value: _ExerciseMenuAction.openVideo,
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
    final vm = state.viewModel;
    final defaults = resolveReplaceExerciseDefaults(
      sessionExerciseId: vm.sessionExerciseId,
      session: state.sessionState.session,
    );
    if (defaults == null) return;
    final result = await ReplaceExerciseDialog.show(
      context: context,
      plannedExerciseName: vm.plannedExerciseName,
      defaultMeasurementType: vm.effectiveMeasurementType,
      defaultPlannedValues: defaults.plannedValues,
      defaultSetCount: defaults.setCount,
    );
    if (result == null) return;
    bloc.add(
      FocusModeExerciseReplaced(
        substituteName: result.name,
        substituteMeasurementType: result.measurementType,
        substitutePlannedValues: result.plannedValues,
        substituteSetCount: result.setCount,
        substituteMetadata: result.metadata,
      ),
    );
  }

  Future<void> _handleSkip(BuildContext context) async {
    final bloc = context.read<FocusModeBloc>();
    final vm = state.viewModel;
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Skip exercise?',
      body:
          'Skipping "${vm.displayExerciseName}" marks it as not done and '
          'moves on. This affects this session only.',
      confirmLabel: 'Skip',
      isDestructive: true,
    );
    if (confirmed != true) return;
    bloc.add(const FocusModeExerciseSkipped());
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

enum _ExerciseMenuAction { replace, skip, openVideo }

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
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
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
                  style: typography.bodySmall.copyWith(color: colors.onSurface),
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
    );
  }
}
