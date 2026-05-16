import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';

enum SetRowMode {
  /// Already executed; tap to edit values.
  completed,

  /// Next set to log on this exercise. Tap to expand the inline editor.
  nextTarget,

  /// Future set on this exercise — visible but not yet reachable.
  pending,

  /// Trailing set whose planned entry no longer exists (the user logged
  /// more sets than the plan called for).
  trailing,
}

/// One row in an exercise card's expanded body.
///
/// Renders a compact "set N: planned ↔ actual" line and, when [isExpanded],
/// an inline editor that logs (or edits) the actual values.
class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.viewModel,
    required this.sessionExerciseId,
    required this.measurementType,
    required this.isExpanded,
    required this.canMutate,
    required this.onTapHeader,
    required this.onLogSet,
    required this.onEditSet,
  });

  final SetRowViewModel viewModel;
  final String sessionExerciseId;
  final MeasurementType measurementType;
  final bool isExpanded;
  final bool canMutate;
  final VoidCallback onTapHeader;
  final void Function(ActualSetValues values, String? plannedSetIdInSnapshot)
  onLogSet;
  final void Function(String executedSetId, ActualSetValues values) onEditSet;

  SetRowMode get mode {
    final executed = viewModel.executedSet;
    if (executed != null && viewModel.plannedValues == null) {
      return SetRowMode.trailing;
    }
    if (executed != null) return SetRowMode.completed;
    if (viewModel.isNextLogTarget) return SetRowMode.nextTarget;
    return SetRowMode.pending;
  }

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController();
    _reps = TextEditingController();
    _duration = TextEditingController();
    _seedFromViewModel();
  }

  @override
  void didUpdateWidget(covariant SetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Mirror focus mode: refresh the editor from the latest view model on
    // every update, except when the user is mid-edit on this row (still
    // expanded and the executed set hasn't changed under them).
    final stillEditing =
        oldWidget.isExpanded &&
        widget.isExpanded &&
        widget.viewModel.executedSet?.id == oldWidget.viewModel.executedSet?.id;
    if (stillEditing) return;
    _seedFromViewModel();
  }

  void _seedFromViewModel() {
    final vm = widget.viewModel;
    final seed =
        vm.executedSet?.actualValues ??
        vm.suggestedActualValues ??
        _plannedAsActual(vm.plannedValues);
    switch (widget.measurementType) {
      case RepBasedMeasurement():
        final rb = seed is ActualRepBased ? seed : null;
        _weight.text = WeightFormatter.formatKg(rb?.weightKg ?? 0);
        _reps.text = (rb?.reps ?? 0).toString();
      case TimeBasedMeasurement():
        final tb = seed is ActualTimeBased ? seed : null;
        _duration.text = (tb?.durationSeconds ?? 0).toString();
        _weight.text = tb?.weightKg != null
            ? WeightFormatter.formatKg(tb!.weightKg!)
            : '';
    }
  }

  static ActualSetValues? _plannedAsActual(PlannedSetValues? planned) =>
      switch (planned) {
        PlannedRepBased(:final weightKg, :final reps) =>
          ActualSetValues.repBased(weightKg: weightKg, reps: reps),
        PlannedTimeBased(:final durationSeconds, :final weightKg) =>
          ActualSetValues.timeBased(
            durationSeconds: durationSeconds,
            weightKg: weightKg,
          ),
        null => null,
      };

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _submit() {
    final values = _readValues();
    if (values == null) return;
    final executed = widget.viewModel.executedSet;
    if (executed == null) {
      widget.onLogSet(values, widget.viewModel.plannedSetIdInSnapshot);
    } else {
      widget.onEditSet(executed.id, values);
    }
  }

  ActualSetValues? _readValues() {
    return switch (widget.measurementType) {
      RepBasedMeasurement() => _readRepBased(),
      TimeBasedMeasurement() => _readTimeBased(),
    };
  }

  ActualSetValues? _readRepBased() {
    final weight = double.tryParse(_weight.text.trim());
    final reps = int.tryParse(_reps.text.trim());
    if (weight == null || reps == null) return null;
    if (weight < 0 || reps < 0) return null;
    final rounded = (weight * 2).round() / 2;
    return ActualSetValues.repBased(weightKg: rounded, reps: reps);
  }

  ActualSetValues? _readTimeBased() {
    final seconds = int.tryParse(_duration.text.trim());
    if (seconds == null || seconds < 0) return null;
    final weightRaw = _weight.text.trim();
    double? weightKg;
    if (weightRaw.isNotEmpty) {
      final parsed = double.tryParse(weightRaw);
      if (parsed == null || parsed < 0) return null;
      weightKg = (parsed * 2).round() / 2;
    }
    return ActualSetValues.timeBased(
      durationSeconds: seconds,
      weightKg: weightKg,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final mode = widget.mode;
    final isInteractive =
        widget.canMutate &&
        (mode == SetRowMode.completed ||
            mode == SetRowMode.nextTarget ||
            mode == SetRowMode.trailing);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isInteractive ? widget.onTapHeader : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(
                viewModel: widget.viewModel,
                mode: mode,
                measurementType: widget.measurementType,
                typography: typography,
                colors: colors,
              ),
              if (widget.isExpanded && isInteractive) ...[
                const SizedBox(height: AppSpacing.sm),
                _Editor(
                  measurementType: widget.measurementType,
                  mode: mode,
                  weight: _weight,
                  reps: _reps,
                  duration: _duration,
                  onSubmit: _submit,
                  onChanged: () => setState(() {}),
                  canSubmit: _readValues() != null,
                  isEditingExisting: widget.viewModel.executedSet != null,
                ),
                const SizedBox(height: AppSpacing.xs),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.viewModel,
    required this.mode,
    required this.measurementType,
    required this.typography,
    required this.colors,
  });

  final SetRowViewModel viewModel;
  final SetRowMode mode;
  final MeasurementType measurementType;
  final AppTypography typography;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 28,
          child: Text(
            'Set ${viewModel.position + 1}',
            style: typography.caption.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            _plannedLabel(viewModel.plannedValues, measurementType),
            style: typography.bodySmall.copyWith(color: colors.planned),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Text(
          _actualLabel(viewModel.executedSet, mode),
          style: typography.numericSm.copyWith(
            color: viewModel.executedSet != null
                ? colors.actual
                : colors.onSurfaceMuted,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        _StatusIcon(mode: mode, colors: colors),
      ],
    );
  }

  String _plannedLabel(PlannedSetValues? planned, MeasurementType mt) {
    if (planned == null) return '—';
    return switch (planned) {
      PlannedRepBased(:final weightKg, :final reps) =>
        '${WeightFormatter.formatKg(weightKg)}kg × $reps',
      PlannedTimeBased(:final durationSeconds, :final weightKg) =>
        weightKg == null
            ? '${durationSeconds}s'
            : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
    };
  }

  String _actualLabel(ExecutedSet? executed, SetRowMode mode) {
    if (executed != null) {
      return switch (executed.actualValues) {
        ActualRepBased(:final weightKg, :final reps) =>
          '${WeightFormatter.formatKg(weightKg)} × $reps',
        ActualTimeBased(:final durationSeconds, :final weightKg) =>
          weightKg == null
              ? '${durationSeconds}s'
              : '${WeightFormatter.formatKg(weightKg)} × ${durationSeconds}s',
      };
    }
    return switch (mode) {
      SetRowMode.nextTarget => 'Tap to log',
      SetRowMode.pending => '—',
      SetRowMode.completed => '—',
      SetRowMode.trailing => '—',
    };
  }
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.mode, required this.colors});

  final SetRowMode mode;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      SetRowMode.completed => Icon(
        Icons.check_circle,
        color: colors.exerciseCompleted,
        size: 18,
      ),
      SetRowMode.trailing => Icon(
        Icons.check_circle,
        color: colors.exerciseCompleted,
        size: 18,
      ),
      SetRowMode.nextTarget => Icon(
        Icons.radio_button_unchecked,
        color: colors.primary,
        size: 18,
      ),
      SetRowMode.pending => Icon(
        Icons.circle_outlined,
        color: colors.onSurfaceMuted,
        size: 18,
      ),
    };
  }
}

class _Editor extends StatelessWidget {
  const _Editor({
    required this.measurementType,
    required this.mode,
    required this.weight,
    required this.reps,
    required this.duration,
    required this.onSubmit,
    required this.onChanged,
    required this.canSubmit,
    required this.isEditingExisting,
  });

  final MeasurementType measurementType;
  final SetRowMode mode;
  final TextEditingController weight;
  final TextEditingController reps;
  final TextEditingController duration;
  final VoidCallback onSubmit;
  final VoidCallback onChanged;
  final bool canSubmit;
  final bool isEditingExisting;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          switch (measurementType) {
            RepBasedMeasurement() => _RepBasedFields(
              weight: weight,
              reps: reps,
              onChanged: onChanged,
            ),
            TimeBasedMeasurement() => _TimeBasedFields(
              duration: duration,
              weight: weight,
              onChanged: onChanged,
            ),
          },
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: AppSpacing.touchMin,
            child: FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              child: Text(isEditingExisting ? 'SAVE' : 'LOG SET'),
            ),
          ),
        ],
      ),
    );
  }
}

class _RepBasedFields extends StatelessWidget {
  const _RepBasedFields({
    required this.weight,
    required this.reps,
    required this.onChanged,
  });

  final TextEditingController weight;
  final TextEditingController reps;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _NumericField(
            controller: weight,
            label: 'kg',
            allowDecimal: true,
            steps: const [-2.5, 2.5],
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _NumericField(
            controller: reps,
            label: 'reps',
            allowDecimal: false,
            steps: const [-1, 1],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _TimeBasedFields extends StatelessWidget {
  const _TimeBasedFields({
    required this.duration,
    required this.weight,
    required this.onChanged,
  });

  final TextEditingController duration;
  final TextEditingController weight;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: _NumericField(
            controller: duration,
            label: 'seconds',
            allowDecimal: false,
            steps: const [-5, 5],
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _NumericField(
            controller: weight,
            label: 'kg (optional)',
            allowDecimal: true,
            steps: const [-2.5, 2.5],
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}

class _NumericField extends StatelessWidget {
  const _NumericField({
    required this.controller,
    required this.label,
    required this.allowDecimal,
    required this.steps,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool allowDecimal;
  final List<double> steps;
  final VoidCallback onChanged;

  void _bump(double delta) {
    final current = double.tryParse(controller.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, double.maxFinite).toDouble();
    if (allowDecimal) {
      final rounded = (next * 2).round() / 2;
      controller.text = WeightFormatter.formatKg(rounded);
    } else {
      controller.text = next.round().toString();
    }
    onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
            ),
          ],
          decoration: InputDecoration(labelText: label, isDense: true),
          style: AppTypography.standard.numeric.copyWith(
            color: colors.onSurface,
          ),
          onChanged: (_) => onChanged(),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            for (final step in steps)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2),
                  child: SizedBox(
                    height: 36,
                    child: OutlinedButton(
                      onPressed: () => _bump(step),
                      style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.zero,
                        textStyle: AppTypography.standard.label,
                      ),
                      child: Text(
                        step > 0
                            ? '+${_fmtStep(step, allowDecimal)}'
                            : _fmtStep(step, allowDecimal),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  String _fmtStep(double v, bool allowDecimal) {
    if (!allowDecimal) return v.toInt().toString();
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }
}
