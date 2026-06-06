import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/increment_rules.dart';
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

  /// Tap-to-edit affordance for `completed` and `trailing` rows.
  bool _editingExisting = false;

  /// Opt-in ± editor for a `loggable` row. Default closed: the row shows the
  /// suggested value behind the tappable log circle, and the user only opens
  /// the editor when logging a value that differs from the suggestion.
  bool _editorOpen = false;

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
    // when the user is mid-edit on this row (executed set unchanged and an
    // editor is still open) — reseeding then would clobber their typing.
    final sameExecuted =
        widget.viewModel.executedSet?.id == oldWidget.viewModel.executedSet?.id;
    if (sameExecuted && (_editingExisting || _editorOpen)) return;
    if (!sameExecuted) {
      _editingExisting = false;
      _editorOpen = false;
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

  /// The value a one-tap log on a loggable row would record: the suggested
  /// actual (last logged set on this exercise) falling back to the planned
  /// target. Null only when there is neither — then the circle opens the
  /// editor instead of logging nothing.
  ActualSetValues? _quickLogValues() =>
      widget.viewModel.suggestedActualValues ??
      _plannedAsActual(widget.viewModel.plannedValues);

  void _quickLog() {
    final values = _quickLogValues();
    if (values == null) {
      setState(() => _editorOpen = true);
      return;
    }
    widget.onLogSet(values, widget.viewModel.plannedSetIdInSnapshot);
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
    final showEditor = switch (mode) {
      SetRowMode.loggable => _editorOpen,
      SetRowMode.completed ||
      SetRowMode.trailing => widget.canMutate && _editingExisting,
      SetRowMode.future => false,
    };
    final canTapHeader =
        widget.canMutate &&
        (mode == SetRowMode.loggable ||
            mode == SetRowMode.completed ||
            mode == SetRowMode.trailing);
    final isHighlighted =
        mode == SetRowMode.loggable && widget.highlightLoggable;
    final suggested = mode == SetRowMode.loggable ? _quickLogValues() : null;

    void toggleEditor() {
      setState(() {
        if (mode == SetRowMode.loggable) {
          _editorOpen = !_editorOpen;
        } else {
          _editingExisting = !_editingExisting;
        }
      });
    }

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
            editorOpen: _editorOpen,
            suggestedActual: suggested,
            onQuickLog: widget.canMutate ? _quickLog : null,
            onToggleEditor: toggleEditor,
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
              color: colors.loggableHint.withValues(
                alpha: AppOpacity.tintFillSubtle,
              ),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              border: Border.all(
                color: colors.loggableHint.withValues(
                  alpha: AppOpacity.borderTint,
                ),
              ),
            ),
            child: content,
          )
        : content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: canTapHeader ? toggleEditor : null,
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
    required this.editorOpen,
    required this.suggestedActual,
    required this.onQuickLog,
    required this.onToggleEditor,
  });

  final SetRowViewModel viewModel;
  final SetRowMode mode;
  final MeasurementType measurementType;
  final AppTypography typography;
  final AppColors colors;

  /// Whether the loggable row's ± editor is currently open. When true the
  /// trailing slot shows a collapse chevron instead of the log circle, so
  /// there is a single commit control (the editor's LOG SET button).
  final bool editorOpen;

  /// Value a one-tap log would record; rendered dimmed beside the log circle
  /// so the user sees what tapping will log. Loggable rows only.
  final ActualSetValues? suggestedActual;

  /// Quick-log the suggested value. Null disables the circle (session not
  /// live).
  final VoidCallback? onQuickLog;

  /// Toggles the opt-in ± editor open/closed.
  final VoidCallback onToggleEditor;

  /// Width of the leading "Set N" label, sized so single- and double-digit set
  /// numbers share one column and planned values line up across rows.
  static const double _setLabelWidth = AppSpacing.xl + AppSpacing.xs;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: _setLabelWidth,
          child: Text(
            'Set ${viewModel.position + 1}',
            style: typography.caption.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            SetValueFormatter.formatPlanned(
              viewModel.plannedValues,
              measurementType,
            ),
            style: typography.bodySmall.copyWith(color: colors.planned),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        _buildTrailing(),
      ],
    );
  }

  Widget _buildTrailing() {
    if (mode == SetRowMode.loggable) {
      if (editorOpen) {
        return _CollapseButton(onPressed: onToggleEditor, colors: colors);
      }
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (suggestedActual != null)
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: Text(
                '→ ${SetValueFormatter.formatActual(suggestedActual!)}',
                style: typography.numericSm.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
          _LoggableCircleButton(onTap: onQuickLog, colors: colors),
        ],
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          _actualLabel(viewModel.executedSet),
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

  String _actualLabel(ExecutedSet? executed) => executed == null
      ? '—'
      : SetValueFormatter.formatActual(executed.actualValues);
}

class _StatusIcon extends StatelessWidget {
  const _StatusIcon({required this.mode, required this.colors});

  final SetRowMode mode;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return switch (mode) {
      SetRowMode.completed => AppIcon(
        Icons.check_circle,
        color: colors.exerciseCompleted,
        size: AppIconSize.status,
      ),
      SetRowMode.trailing => AppIcon(
        Icons.check_circle,
        color: colors.exerciseCompleted,
        size: AppIconSize.status,
      ),
      // Loggable rows render the tappable `_LoggableCircleButton` instead of
      // a status icon, so this branch is never hit for them.
      SetRowMode.loggable => const SizedBox.shrink(),
      SetRowMode.future => AppIcon(
        Icons.circle_outlined,
        color: colors.onSurfaceMuted,
        size: AppIconSize.status,
      ),
    };
  }
}

/// The single commit affordance for a collapsed loggable row: a primary
/// circle that logs the suggested value in one tap. Sized to the in-session
/// primary-action floor (≥56 dp) for sweaty-hands use. Hidden while the row's
/// ± editor is open (the editor's LOG SET button commits there).
class _LoggableCircleButton extends StatelessWidget {
  const _LoggableCircleButton({required this.onTap, required this.colors});

  static const double _size = AppInSessionSize.controlMin;

  final VoidCallback? onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Log set',
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: _size,
            height: _size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.primary.withValues(alpha: AppOpacity.tintFill),
              border: Border.all(
                color: colors.primary,
                width: AppStroke.emphasis,
              ),
            ),
            child: AppIcon(
              Icons.check,
              color: colors.primary,
              size: AppIconSize.xl,
              semanticLabel: 'Log set',
            ),
          ),
        ),
      ),
    );
  }
}

/// Chevron shown in a loggable row's trailing slot while its ± editor is open,
/// so the user can collapse back to the one-tap log circle.
class _CollapseButton extends StatelessWidget {
  const _CollapseButton({required this.onPressed, required this.colors});

  final VoidCallback onPressed;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: AppSpacing.touchMin,
      height: AppSpacing.touchMin,
      child: IconButton(
        tooltip: 'Collapse',
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        icon: AppIcon(
          Icons.expand_less,
          color: colors.onSurfaceMuted,
          size: AppIconSize.xl,
        ),
      ),
    );
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
          PrimaryActionButton(
            label: isEditingExisting ? 'SAVE' : 'LOG SET',
            onPressed: onSubmit,
            enabled: canSubmit,
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
          stepsFor: IncrementRules.weightSteps,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _NumericField(
          controller: reps,
          label: 'reps',
          allowDecimal: false,
          stepsFor: _repStepsFor,
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
      stepsFor: _repStepsFor,
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
          stepsFor: _durationStepsFor,
          onChanged: onChanged,
        ),
        const SizedBox(height: AppSpacing.sm),
        _NumericField(
          controller: weight,
          label: 'kg (optional)',
          allowDecimal: true,
          stepsFor: IncrementRules.weightSteps,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// Reps always nudge ±1 and durations ±5 regardless of the current value, so
/// these adapt [IncrementRules]' constants to the `stepsFor` signature (weight
/// uses [IncrementRules.weightSteps] directly, which *is* value-dependent).
List<double> _repStepsFor(double _) => IncrementRules.repStepsDouble;
List<double> _durationStepsFor(double _) => IncrementRules.durationStepsDouble;

/// Numeric input rendered as a counter — step buttons flank a centered,
/// borderless field showing the value with a caption beneath. Tapping the
/// value opens the keyboard for manual entry.
///
/// [stepsFor] yields the `[negativeStep, positiveStep]` pair for the current
/// value, sourced from [IncrementRules] so this compact card stepper and the
/// big focus panel share one step policy (e.g. weight nudges ±1 below 10 kg,
/// ±2.5 above — recomputed as the value crosses the threshold).
class _NumericField extends StatefulWidget {
  const _NumericField({
    required this.controller,
    required this.label,
    required this.allowDecimal,
    required this.stepsFor,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final bool allowDecimal;
  final List<double> Function(double current) stepsFor;
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
    final steps = widget.stepsFor(
      double.tryParse(widget.controller.text.trim()) ?? 0,
    );
    final negative = steps.first;
    final positive = steps.last;

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

  static const double _width = AppInSessionSize.stepButton;
  static const double _height = AppInSessionSize.stepButton;

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
