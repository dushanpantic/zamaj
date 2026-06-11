import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/increment_rules.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/workout_overview/workout_overview.dart';

/// Modal bottom sheet for correcting a logged set's actual values after a
/// session, on the read-only review screen.
///
/// Measurement-type aware (rep-based / time-based / bodyweight), seeded with the
/// set's current [ActualSetValues] and returning the new values on SAVE (or
/// `null` when dismissed). This is the calm `export/` review surface, so it uses
/// the normal [AppSpacing.touchMin] (48 dp) tap floor and standard typography —
/// not the 64 dp in-session sweaty-hands sizing. Parse/round and seed semantics
/// come from the shared [SetValueInputMapper], so this editor and the in-session
/// `SetRow` editor stay in lockstep.
class SetValueEditorSheet extends StatefulWidget {
  const SetValueEditorSheet({
    super.key,
    required this.initialValues,
    required this.measurementType,
    required this.title,
  });

  final ActualSetValues initialValues;
  final MeasurementType measurementType;
  final String title;

  /// Opens the editor and resolves to the new [ActualSetValues] on SAVE, or
  /// `null` if the sheet was dismissed without saving.
  static Future<ActualSetValues?> show(
    BuildContext context, {
    required ActualSetValues initialValues,
    required MeasurementType measurementType,
    required String title,
  }) {
    return showModalBottomSheet<ActualSetValues>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).appColors.surfaceElevated,
      builder: (_) => SetValueEditorSheet(
        initialValues: initialValues,
        measurementType: measurementType,
        title: title,
      ),
    );
  }

  @override
  State<SetValueEditorSheet> createState() => _SetValueEditorSheetState();
}

class _SetValueEditorSheetState extends State<SetValueEditorSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _duration;

  @override
  void initState() {
    super.initState();
    final fields = SetValueInputMapper.seed(
      widget.initialValues,
      widget.measurementType,
    );
    _weight = TextEditingController(text: fields.weight);
    _reps = TextEditingController(text: fields.reps);
    _duration = TextEditingController(text: fields.duration);
  }

  @override
  void dispose() {
    _weight.dispose();
    _reps.dispose();
    _duration.dispose();
    super.dispose();
  }

  ActualSetValues? _readValues() => SetValueInputMapper.parse(
    measurementType: widget.measurementType,
    weightText: _weight.text,
    repsText: _reps.text,
    durationText: _duration.text,
  );

  void _save() {
    final values = _readValues();
    if (values == null) return;
    Navigator.of(context).pop(values);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final canSave = _readValues() != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.title,
            style: typography.titleSmall.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.lg),
          ..._fields(),
          const SizedBox(height: AppSpacing.lg),
          SizedBox(
            height: AppSpacing.touchMin,
            child: FilledButton(
              onPressed: canSave ? _save : null,
              style: FilledButton.styleFrom(
                backgroundColor: colors.primary,
                foregroundColor: colors.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
              ),
              child: Text('SAVE', style: typography.actionLabel),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _fields() {
    switch (widget.measurementType) {
      case RepBasedMeasurement():
        return [
          _weightField(),
          const SizedBox(height: AppSpacing.md),
          _repsField(),
        ];
      case TimeBasedMeasurement():
        return [
          _durationField(),
          const SizedBox(height: AppSpacing.md),
          _weightField(label: 'kg (optional)'),
        ];
      case BodyweightMeasurement():
        return [_repsField()];
    }
  }

  Widget _weightField({String label = 'kg'}) => _StepperField(
    controller: _weight,
    label: label,
    allowDecimal: true,
    stepsFor: IncrementRules.weightSteps,
    onChanged: () => setState(() {}),
  );

  Widget _repsField() => _StepperField(
    controller: _reps,
    label: 'reps',
    allowDecimal: false,
    stepsFor: (_) => IncrementRules.repStepsDouble,
    onChanged: () => setState(() {}),
  );

  Widget _durationField() => _StepperField(
    controller: _duration,
    label: 'seconds',
    allowDecimal: false,
    stepsFor: (_) => IncrementRules.durationStepsDouble,
    onChanged: () => setState(() {}),
  );
}

/// A `[−] value [+]` stepper at the normal [AppSpacing.touchMin] (48 dp) tap
/// floor for the calm review surface. Deliberately separate from the in-session
/// `SetRow` stepper, which is oversized for sweaty hands; the two share value
/// semantics through [SetValueInputMapper]/[IncrementRules], not widget code.
class _StepperField extends StatefulWidget {
  const _StepperField({
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
  State<_StepperField> createState() => _StepperFieldState();
}

class _StepperFieldState extends State<_StepperField> {
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
      widget.controller.text = WeightFormatter.formatKg(
        IncrementRules.roundHalfKg(next),
      );
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
                    style: typography.numeric.copyWith(color: colors.onSurface),
                    onChanged: (_) => widget.onChanged(),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
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

/// Normal-density (48 dp) step button for the review-surface editor.
class _StepButton extends StatelessWidget {
  const _StepButton({required this.label, required this.onPressed});

  static const double _size = AppSpacing.touchMin;

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(_size, _size),
          textStyle: AppTypography.standard.bodySmall,
        ),
        child: Text(label),
      ),
    );
  }
}
