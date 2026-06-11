import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/haptics.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_mode_state_views.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_ready_body.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_switch_exercise_button.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_workout_complete_view.dart';

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
          listenWhen: _restJustEnded,
          listener: (_, _) => Haptics.emphasis(),
        ),
        BlocListener<FocusModeBloc, FocusModeState>(
          listenWhen: _countdownJustFinished,
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

  static bool _restJustEnded(FocusModeState p, FocusModeState c) {
    if (p is! FocusModeReady || c is! FocusModeReady) return false;
    final priorTimer = p.restTimer;
    if (priorTimer == null) return false;
    if (c.restTimer != null) return false;
    return priorTimer.remainingSeconds <= 1;
  }

  /// The timed-set countdown reached its target and entered its 00:00 flash.
  /// Keys off the explicit finished flag, so a manual cancel stays quiet.
  static bool _countdownJustFinished(FocusModeState p, FocusModeState c) {
    if (c is! FocusModeReady) return false;
    final priorFinished = p is FocusModeReady && p.stopwatch.isFinished;
    return c.stopwatch.isFinished && !priorFinished;
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
        if (ready != null) ...[FocusSwitchExerciseButton(state: ready)],
      ],
    );
  }

  Widget _body(BuildContext context, FocusModeState state) {
    return switch (state) {
      FocusModeInitial() || FocusModeLoading() => const FocusLoadingView(),
      FocusModeNotFound() => const FocusNotFoundView(),
      FocusModeLoadFailure(:final error) => FocusErrorView(
        error: error,
        onRetry: () =>
            context.read<FocusModeBloc>().add(const FocusModeRetried()),
      ),
      FocusModeWorkoutComplete(
        :final sessionState,
        :final lastTransientError,
      ) =>
        FocusWorkoutCompleteView(
          workoutDayName: sessionState.session.snapshot.workoutDay.name,
          onBackToOverview: () => Navigator.of(context).maybePop(),
          transientError: lastTransientError,
          onDismissError: () => context.read<FocusModeBloc>().add(
            const FocusModeErrorDismissed(),
          ),
        ),
      FocusModeReady() => FocusReadyBody(state: state),
    };
  }
}
