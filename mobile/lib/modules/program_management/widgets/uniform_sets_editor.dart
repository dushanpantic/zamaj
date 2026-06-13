import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/increment_rules.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/services/planned_draft_summary_formatter.dart';
import 'package:zamaj/modules/program_management/services/set_input_adjustment.dart';
import 'package:zamaj/modules/program_management/widgets/set_stepper_field.dart';

/// Uniform-first planned-sets editor: one weight / reps / duration control plus
/// a sets-count control that drive **every** set at once (the common
/// straight-sets case). A "Vary by set" action drops to the per-row editor for
/// pyramids and drop sets. Shown only while [draft]'s sets are uniform.
class UniformSetsEditor extends StatelessWidget {
  const UniformSetsEditor({
    super.key,
    required this.draft,
    required this.onVaryBySet,
  });

  final ExerciseDraft draft;
  final VoidCallback onVaryBySet;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final bloc = context.read<ExerciseEditorBloc>();
    final count = draft.sets.length;
    final first = draft.sets.first.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...switch (first) {
          PlannedSetDraftRepBased(:final weightInput, :final repsInput) => [
            _weightStepper(bloc, weightInput),
            const SizedBox(height: AppSpacing.md),
            _repsStepper(bloc, repsInput),
          ],
          PlannedSetDraftTimeBased(:final durationInput, :final weightInput) =>
            [
              _durationStepper(bloc, durationInput),
              const SizedBox(height: AppSpacing.md),
              _weightStepper(bloc, weightInput, label: 'Weight (kg, opt)'),
            ],
          PlannedSetDraftBodyweight(:final repsInput) => [
            _repsStepper(bloc, repsInput),
          ],
        },
        const SizedBox(height: AppSpacing.md),
        _countStepper(bloc, count),
        const SizedBox(height: AppSpacing.md),
        Text(
          PlannedDraftSummaryFormatter.summarize(draft),
          style: typography.numericSm.copyWith(color: colors.onSurfaceMuted),
        ),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: onVaryBySet,
            icon: const AppIcon(Icons.tune, size: AppIconSize.md),
            label: const Text('Vary by set'),
          ),
        ),
      ],
    );
  }

  Widget _weightStepper(
    ExerciseEditorBloc bloc,
    String weightInput, {
    String label = 'Weight (kg)',
  }) {
    final current = double.tryParse(weightInput.trim()) ?? 0;
    final steps = IncrementRules.weightSteps(current);
    return SetStepperField(
      label: label,
      value: weightInput,
      semanticNoun: 'weight',
      decrementLabel: _signedWeight(steps.first),
      incrementLabel: _signedWeight(steps.last),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
      onChanged: (raw) => bloc.add(AllSetsWeightChanged(rawInput: raw)),
      onDecrement: () => bloc.add(AllSetsWeightBumped(delta: steps.first)),
      onIncrement: () => bloc.add(AllSetsWeightBumped(delta: steps.last)),
    );
  }

  Widget _repsStepper(ExerciseEditorBloc bloc, String repsInput) {
    return SetStepperField(
      label: 'Reps (or range, e.g. 6-8)',
      value: repsInput,
      semanticNoun: 'reps',
      decrementLabel: _signedInt(IncrementRules.repSteps.first),
      incrementLabel: _signedInt(IncrementRules.repSteps.last),
      keyboardType: TextInputType.text,
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9\-–]'))],
      onChanged: (raw) => bloc.add(AllSetsRepsChanged(rawInput: raw)),
      onDecrement: () =>
          bloc.add(AllSetsRepsBumped(delta: IncrementRules.repSteps.first)),
      onIncrement: () =>
          bloc.add(AllSetsRepsBumped(delta: IncrementRules.repSteps.last)),
    );
  }

  Widget _durationStepper(ExerciseEditorBloc bloc, String durationInput) {
    return SetStepperField(
      label: 'Duration (s)',
      value: durationInput,
      semanticNoun: 'duration',
      decrementLabel: _signedInt(IncrementRules.durationSteps.first),
      incrementLabel: _signedInt(IncrementRules.durationSteps.last),
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (raw) => bloc.add(AllSetsDurationChanged(rawInput: raw)),
      onDecrement: () => bloc.add(
        AllSetsDurationBumped(delta: IncrementRules.durationSteps.first),
      ),
      onIncrement: () => bloc.add(
        AllSetsDurationBumped(delta: IncrementRules.durationSteps.last),
      ),
    );
  }

  Widget _countStepper(ExerciseEditorBloc bloc, int count) {
    return SetStepperField(
      label: 'Sets',
      value: '$count',
      semanticNoun: 'set count',
      decrementLabel: '-1',
      incrementLabel: '+1',
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      onChanged: (raw) {
        final next = int.tryParse(raw);
        if (next != null) bloc.add(PlannedSetCountChanged(count: next));
      },
      onDecrement: count > 1
          ? () => bloc.add(PlannedSetCountChanged(count: count - 1))
          : null,
      onIncrement: count < 20
          ? () => bloc.add(PlannedSetCountChanged(count: count + 1))
          : null,
    );
  }

  String _signedWeight(double v) {
    final formatted = SetInputAdjustment.formatWeight(v);
    return v > 0 ? '+$formatted' : formatted;
  }

  String _signedInt(int v) => v > 0 ? '+$v' : '$v';
}
