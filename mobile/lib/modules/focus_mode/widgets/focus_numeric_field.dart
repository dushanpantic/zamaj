import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// The big, centered hero numeric input shared by the rep-based and bodyweight
/// focus panels: a [numericHero]-sized [TextField] with a caption label beneath
/// it. [allowDecimal] toggles the keyboard and input filter between whole
/// numbers (reps) and half-kg weights.
class FocusBigNumericField extends StatelessWidget {
  const FocusBigNumericField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.enabled,
    required this.onSubmitted,
    this.allowDecimal = false,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
  final bool enabled;
  final ValueChanged<String> onSubmitted;
  final bool allowDecimal;

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
          style: typography.numericHero.copyWith(color: colors.onSurface),
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

/// The ± bump-button row shared by the rep-based and bodyweight focus panels.
/// Each step is a 64 dp [AppInSessionSize.stepButton] [OutlinedButton]; the
/// negative step reads muted, the positive step gets a leading `+`. [formatter]
/// renders each step's magnitude (reps as integers, weights with one decimal).
class FocusBumpRow extends StatelessWidget {
  const FocusBumpRow({
    super.key,
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
    final colors = Theme.of(context).appColors;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: AppInSessionSize.stepButton,
              child: OutlinedButton(
                onPressed: enabled ? () => onTap(steps[i]) : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: steps[i] < 0 ? colors.onSurfaceMuted : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                  textStyle: AppTypography.standard.actionLabel,
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    steps[i] > 0
                        ? '+${formatter(steps[i])}'
                        : formatter(steps[i]),
                    maxLines: 1,
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
