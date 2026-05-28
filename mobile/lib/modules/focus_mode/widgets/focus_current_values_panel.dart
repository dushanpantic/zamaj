import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/bloc/bloc.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_bodyweight_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_rep_based_panel.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_time_based_panel.dart';

class FocusCurrentValuesPanel extends StatelessWidget {
  const FocusCurrentValuesPanel({
    super.key,
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
