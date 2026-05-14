import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/focus_mode/services/increment_rules.dart';

/// Big editable panel for the current rep-based set: weight + reps with
/// bump buttons.
class FocusRepBasedPanel extends StatefulWidget {
  const FocusRepBasedPanel({
    super.key,
    required this.weightKg,
    required this.reps,
    required this.onWeightBump,
    required this.onRepsBump,
    required this.onWeightCommitted,
    required this.onRepsCommitted,
    required this.enabled,
  });

  final double weightKg;
  final int reps;

  /// Called when the user taps a weight bump button. Positive for "+",
  /// negative for "-". Step magnitudes follow [IncrementRules.weightSteps].
  final void Function(double delta) onWeightBump;
  final void Function(int delta) onRepsBump;

  /// Called when the manual text editor commits a fully-typed value
  /// (on submit / blur). Reset & re-seed handled by the bloc.
  final void Function(double weightKg) onWeightCommitted;
  final void Function(int reps) onRepsCommitted;

  final bool enabled;

  @override
  State<FocusRepBasedPanel> createState() => _FocusRepBasedPanelState();
}

class _FocusRepBasedPanelState extends State<FocusRepBasedPanel> {
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  final FocusNode _weightFocus = FocusNode();
  final FocusNode _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _weight = TextEditingController(
      text: WeightFormatter.formatKg(widget.weightKg),
    );
    _reps = TextEditingController(text: widget.reps.toString());
    _weightFocus.addListener(_commitWeightOnBlur);
    _repsFocus.addListener(_commitRepsOnBlur);
  }

  @override
  void didUpdateWidget(covariant FocusRepBasedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_weightFocus.hasFocus && widget.weightKg != oldWidget.weightKg) {
      _weight.text = WeightFormatter.formatKg(widget.weightKg);
    }
    if (!_repsFocus.hasFocus && widget.reps != oldWidget.reps) {
      _reps.text = widget.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightFocus.removeListener(_commitWeightOnBlur);
    _repsFocus.removeListener(_commitRepsOnBlur);
    _weight.dispose();
    _reps.dispose();
    _weightFocus.dispose();
    _repsFocus.dispose();
    super.dispose();
  }

  void _commitWeightOnBlur() {
    if (_weightFocus.hasFocus) return;
    final parsed = double.tryParse(_weight.text.trim());
    if (parsed == null) {
      _weight.text = WeightFormatter.formatKg(widget.weightKg);
      return;
    }
    widget.onWeightCommitted(parsed);
  }

  void _commitRepsOnBlur() {
    if (_repsFocus.hasFocus) return;
    final parsed = int.tryParse(_reps.text.trim());
    if (parsed == null) {
      _reps.text = widget.reps.toString();
      return;
    }
    widget.onRepsCommitted(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final weightSteps = IncrementRules.weightSteps(widget.weightKg);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: _BigNumericField(
                  controller: _weight,
                  focusNode: _weightFocus,
                  label: 'kg',
                  allowDecimal: true,
                  enabled: widget.enabled,
                  onSubmitted: (text) {
                    final parsed = double.tryParse(text.trim());
                    if (parsed != null) widget.onWeightCommitted(parsed);
                  },
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Text(
                '×',
                style: typography.numericLarge.copyWith(
                  color: colors.onSurfaceMuted,
                  fontSize: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _BigNumericField(
                  controller: _reps,
                  focusNode: _repsFocus,
                  label: 'reps',
                  allowDecimal: false,
                  enabled: widget.enabled,
                  onSubmitted: (text) {
                    final parsed = int.tryParse(text.trim());
                    if (parsed != null) widget.onRepsCommitted(parsed);
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _BumpRow(
                  steps: weightSteps,
                  enabled: widget.enabled,
                  onTap: widget.onWeightBump,
                  formatter: (v) => _fmtDecimalStep(v),
                ),
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: _BumpRow(
                  steps: const [-1, 1],
                  enabled: widget.enabled,
                  onTap: (delta) => widget.onRepsBump(delta.round()),
                  formatter: (v) => v.toInt().toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmtDecimalStep(double v) {
    if (v == v.truncateToDouble()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }
}

class _BigNumericField extends StatelessWidget {
  const _BigNumericField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.allowDecimal,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool allowDecimal;
  final bool enabled;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextField(
          controller: controller,
          focusNode: focusNode,
          enabled: enabled,
          textAlign: TextAlign.center,
          keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
          inputFormatters: [
            FilteringTextInputFormatter.allow(
              allowDecimal ? RegExp(r'[0-9.]') : RegExp(r'[0-9]'),
            ),
          ],
          onSubmitted: onSubmitted,
          style: typography.numericLarge.copyWith(
            color: colors.onSurface,
            fontSize: 44,
          ),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: colors.surfaceVariant,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.md,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.md),
              borderSide: BorderSide(color: colors.outline),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            label,
            style: typography.caption.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
      ],
    );
  }
}

class _BumpRow extends StatelessWidget {
  const _BumpRow({
    required this.steps,
    required this.enabled,
    required this.onTap,
    required this.formatter,
  });

  final List<double> steps;
  final bool enabled;
  final void Function(double delta) onTap;
  final String Function(double v) formatter;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final step in steps)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: SizedBox(
                height: AppSpacing.touchMin,
                child: OutlinedButton(
                  onPressed: enabled ? () => onTap(step) : null,
                  child: Text(
                    step > 0 ? '+${formatter(step)}' : formatter(step),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class FocusModeColors {
  /// Convenience accessor used by panel-internal widgets so we don't pass
  /// theme data through 4 levels of widget tree.
  static AppColors of(BuildContext context) => Theme.of(context).appColors;
}
