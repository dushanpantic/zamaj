import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/models/set_row_view_model.dart';

enum SetRowMode {
  /// Already executed; tap to edit values.
  completed,

  /// Next chronological set on a currently-loggable exercise. Rendered with
  /// the inline editor always expanded — one tap to log.
  loggable,

  /// Future set on this exercise — visible but not yet reachable (the user
  /// must log earlier sets first to keep within-exercise progression in
  /// order).
  future,

  /// Trailing set whose planned entry no longer exists (the user logged
  /// more sets than the plan called for).
  trailing,
}

/// One row in an exercise card's expanded body.
///
/// Renders a compact "set N: planned ↔ actual" line and, when the row is in
/// [SetRowMode.loggable], an always-expanded inline editor that logs the
/// actual values in one tap. Completed and trailing rows reveal the editor
/// on header tap to support after-the-fact edits.
class SetRow extends StatefulWidget {
  const SetRow({
    super.key,
    required this.viewModel,
    required this.sessionExerciseId,
    required this.measurementType,
    required this.canMutate,
    required this.onLogSet,
    required this.onEditSet,
    this.highlightLoggable = false,
  });

  final SetRowViewModel viewModel;
  final String sessionExerciseId;
  final MeasurementType measurementType;
  final bool canMutate;
  final void Function(ActualSetValues values, String? plannedSetIdInSnapshot)
  onLogSet;
  final void Function(String executedSetId, ActualSetValues values) onEditSet;

  /// Applies a subtle accent to a loggable row so the user's eye returns to
  /// the most recently touched exercise after a rest. Ignored for non-
  /// loggable rows.
  final bool highlightLoggable;

  SetRowMode get mode {
    final executed = viewModel.executedSet;
    if (executed != null && viewModel.plannedValues == null) {
      return SetRowMode.trailing;
    }
    if (executed != null) return SetRowMode.completed;
    if (viewModel.isLoggable) return SetRowMode.loggable;
    return SetRowMode.future;
  }

  @override
  State<SetRow> createState() => _SetRowState();
}

class _SetRowState extends State<SetRow> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _duration;

  /// Tap-to-edit affordance for `completed` and `trailing` rows. Loggable
  /// rows ignore this flag — their editor is always visible.
  bool _editingExisting = false;

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
    // Refresh the editor from the latest view model on every update, except
    // when the user is mid-edit on this row (executed set unchanged and the
    // editor is still open).
    final stillEditing =
        widget.viewModel.executedSet?.id == oldWidget.viewModel.executedSet?.id;
    if (stillEditing && _editingExisting) return;
    if (widget.viewModel.executedSet?.id !=
        oldWidget.viewModel.executedSet?.id) {
      _editingExisting = false;
    }
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
      case BodyweightMeasurement():
        final bw = seed is ActualBodyweight ? seed : null;
        _reps.text = (bw?.reps ?? 0).toString();
    }
  }

  static ActualSetValues? _plannedAsActual(PlannedSetValues? planned) =>
      switch (planned) {
        PlannedRepBased(:final weightKg, :final repTarget) =>
          ActualSetValues.repBased(
            weightKg: weightKg,
            reps: switch (repTarget) {
              RepTargetFixed(:final reps) => reps,
              RepTargetRange(:final maxReps) => maxReps,
            },
          ),
        PlannedTimeBased(:final durationSeconds, :final weightKg) =>
          ActualSetValues.timeBased(
            durationSeconds: durationSeconds,
            weightKg: weightKg,
          ),
        PlannedBodyweight(:final repTarget) => ActualSetValues.bodyweight(
          reps: switch (repTarget) {
            RepTargetFixed(:final reps) => reps,
            RepTargetRange(:final maxReps) => maxReps,
          },
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
      setState(() => _editingExisting = false);
    }
  }

  ActualSetValues? _readValues() {
    return switch (widget.measurementType) {
      RepBasedMeasurement() => _readRepBased(),
      TimeBasedMeasurement() => _readTimeBased(),
      BodyweightMeasurement() => _readBodyweight(),
    };
  }

  ActualSetValues? _readBodyweight() {
    final reps = int.tryParse(_reps.text.trim());
    if (reps == null || reps < 0) return null;
    return ActualSetValues.bodyweight(reps: reps);
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
    // Loggable editor visibility is intentionally not gated on canMutate:
    // canMutate flips false for the brief window a mutation is in flight,
    // and hiding/restoring the editor in that window made the card jitter
    // on every LOG SET. The bloc's _runMutation already dedupes concurrent
    // submits, so leaving the button tappable during the window is safe.
    final showEditor = switch (mode) {
      SetRowMode.loggable => true,
      SetRowMode.completed ||
      SetRowMode.trailing => widget.canMutate && _editingExisting,
      SetRowMode.future => false,
    };
    final canTapHeader =
        widget.canMutate &&
        (mode == SetRowMode.completed || mode == SetRowMode.trailing);
    final isHighlighted =
        mode == SetRowMode.loggable && widget.highlightLoggable;

    final content = Padding(
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
          if (showEditor) ...[
            const SizedBox(height: AppSpacing.sm),
            _Editor(
              measurementType: widget.measurementType,
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
    );

    final decorated = isHighlighted
        ? Container(
            decoration: BoxDecoration(
              color: colors.loggableHint.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: colors.loggableHint.withValues(alpha: 0.35),
              ),
            ),
            child: content,
          )
        : content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTapHeader
            ? () => setState(() => _editingExisting = !_editingExisting)
            : null,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        child: decorated,
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

  String _actualLabel(ExecutedSet? executed, SetRowMode mode) {
    if (executed != null) {
      return switch (executed.actualValues) {
        ActualRepBased(:final weightKg, :final reps) =>
          '${WeightFormatter.formatKg(weightKg)} × $reps',
        ActualTimeBased(:final durationSeconds, :final weightKg) =>
          weightKg == null
              ? '${durationSeconds}s'
              : '${WeightFormatter.formatKg(weightKg)} × ${durationSeconds}s',
        ActualBodyweight(:final reps) => '× $reps',
      };
    }
    return switch (mode) {
      SetRowMode.loggable => '—',
      SetRowMode.future => '—',
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
      // `adjust` is a centred dot inside a ring — clearly an indicator, not
      // a button. Distinguishes the active loggable row without lying about
      // tap behaviour the way `radio_button_unchecked` did.
      SetRowMode.loggable => Icon(
        Icons.adjust,
        color: colors.primary,
        size: 18,
      ),
      SetRowMode.future => Icon(
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
    required this.weight,
    required this.reps,
    required this.duration,
    required this.onSubmit,
    required this.onChanged,
    required this.canSubmit,
    required this.isEditingExisting,
  });

  final MeasurementType measurementType;
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
            BodyweightMeasurement() => _BodyweightFields(
              reps: reps,
              onChanged: onChanged,
            ),
          },
          const SizedBox(height: AppSpacing.md),
          SizedBox(
            height: 56,
            child: FilledButton(
              onPressed: canSubmit ? onSubmit : null,
              style: FilledButton.styleFrom(
                textStyle: AppTypography.standard.actionLabel,
              ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NumericField(
          controller: weight,
          label: 'kg',
          allowDecimal: true,
          steps: const [-2.5, 2.5],
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _NumericField(
          controller: reps,
          label: 'reps',
          allowDecimal: false,
          steps: const [-1, 1],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

class _BodyweightFields extends StatelessWidget {
  const _BodyweightFields({required this.reps, required this.onChanged});

  final TextEditingController reps;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return _NumericField(
      controller: reps,
      label: 'reps',
      allowDecimal: false,
      steps: const [-1, 1],
      onChanged: onChanged,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _NumericField(
          controller: duration,
          label: 'seconds',
          allowDecimal: false,
          steps: const [-5, 5],
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _NumericField(
          controller: weight,
          label: 'kg (optional)',
          allowDecimal: true,
          steps: const [-2.5, 2.5],
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Numeric input rendered as a counter — step buttons flank a centered,
/// borderless field showing the value with a caption beneath. Tapping the
/// value opens the keyboard for manual entry. [steps] is interpreted as
/// `[negativeStep, positiveStep]` (e.g. `[-2.5, 2.5]`).
class _NumericField extends StatefulWidget {
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

  @override
  State<_NumericField> createState() => _NumericFieldState();
}

class _NumericFieldState extends State<_NumericField> {
  final FocusNode _focus = FocusNode();

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _bump(double delta) {
    final current = double.tryParse(widget.controller.text.trim()) ?? 0;
    final next = (current + delta).clamp(0, double.maxFinite).toDouble();
    if (widget.allowDecimal) {
      final rounded = (next * 2).round() / 2;
      widget.controller.text = WeightFormatter.formatKg(rounded);
    } else {
      widget.controller.text = next.round().toString();
    }
    widget.onChanged();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final negative = widget.steps.first;
    final positive = widget.steps.last;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _StepButton(
          label: _fmtStep(negative, widget.allowDecimal),
          onPressed: () => _bump(negative),
        ),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _focus.requestFocus,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: widget.controller,
                    focusNode: _focus,
                    keyboardType: TextInputType.numberWithOptions(
                      decimal: widget.allowDecimal,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(
                        widget.allowDecimal
                            ? RegExp(r'[0-9.]')
                            : RegExp(r'[0-9]'),
                      ),
                    ],
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                    ),
                    style: typography.numericLarge.copyWith(
                      color: colors.onSurface,
                    ),
                    onChanged: (_) => widget.onChanged(),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.label,
                    style: typography.labelSmall.copyWith(
                      color: colors.onSurfaceMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        _StepButton(
          label: '+${_fmtStep(positive, widget.allowDecimal)}',
          onPressed: () => _bump(positive),
        ),
      ],
    );
  }

  static String _fmtStep(double v, bool allowDecimal) {
    if (!allowDecimal) return v.toInt().toString();
    return v == v.truncateToDouble()
        ? v.toInt().toString()
        : v.toStringAsFixed(1);
  }
}

/// Oversized step button for the inline editor — sweaty-hands ergonomics
/// matter more than card compactness, so this is intentionally larger than
/// [AppSpacing.touchMin].
class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onPressed});

  static const double _width = 64;
  static const double _height = 64;

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _width,
      height: _height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(_width, _height),
          textStyle: AppTypography.standard.actionLabel,
        ),
        child: Text(label),
      ),
    );
  }
}
