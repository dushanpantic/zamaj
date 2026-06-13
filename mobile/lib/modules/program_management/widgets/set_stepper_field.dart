import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// A labelled numeric value with a − / + step button on each side. The centre
/// is a directly-editable [TextField] (type an absolute value); the buttons
/// nudge it by a step the caller supplies (drawn from `IncrementRules`). Used
/// by the uniform sets editor for weight, reps, and duration.
///
/// Step magnitude is conveyed by the button labels (e.g. `+2.5`), never by
/// colour alone, and each button carries a [Semantics] label for screen
/// readers. Tap targets are ≥ [AppSpacing.touchMin] (48 dp) — program editing
/// is not an in-session surface, so the 64 dp sweaty-hands floor does not apply.
class SetStepperField extends StatefulWidget {
  const SetStepperField({
    super.key,
    required this.label,
    required this.value,
    required this.semanticNoun,
    required this.decrementLabel,
    required this.incrementLabel,
    required this.onChanged,
    required this.onDecrement,
    required this.onIncrement,
    this.keyboardType = const TextInputType.numberWithOptions(decimal: true),
    this.inputFormatters,
  });

  final String label;
  final String value;

  /// Noun used in the buttons' screen-reader labels, e.g. "weight" →
  /// "Increase weight".
  final String semanticNoun;
  final String decrementLabel;
  final String incrementLabel;
  final void Function(String) onChanged;

  /// `null` disables the button (e.g. at a bound).
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;

  @override
  State<SetStepperField> createState() => _SetStepperFieldState();
}

class _SetStepperFieldState extends State<SetStepperField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(SetStepperField oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The owning bloc rewrote the value (a bump or set-all edit) — resync the
    // field without clobbering an in-progress caret on plain typing.
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.label,
          style: typography.caption.copyWith(color: colors.onSurfaceMuted),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          children: [
            _StepButton(
              label: widget.decrementLabel,
              semanticLabel: 'Decrease ${widget.semanticNoun}',
              onPressed: widget.onDecrement,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: _controller,
                textAlign: TextAlign.center,
                keyboardType: widget.keyboardType,
                inputFormatters: widget.inputFormatters,
                style: typography.numeric.copyWith(color: colors.onSurface),
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: AppSpacing.md,
                  ),
                ),
                onChanged: widget.onChanged,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            _StepButton(
              label: widget.incrementLabel,
              semanticLabel: 'Increase ${widget.semanticNoun}',
              onPressed: widget.onIncrement,
            ),
          ],
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.label,
    required this.semanticLabel,
    required this.onPressed,
  });

  final String label;
  final String semanticLabel;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: SizedBox(
        width: AppSpacing.touchMin,
        height: AppSpacing.touchMin,
        child: OutlinedButton(
          onPressed: onPressed,
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            textStyle: AppTypography.standard.actionLabel,
          ),
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(label, maxLines: 1),
          ),
        ),
      ),
    );
  }
}
