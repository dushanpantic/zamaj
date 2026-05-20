import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Big editable panel for the current bodyweight set: reps only, with
/// bump buttons. Mirrors [FocusRepBasedPanel] but drops the weight column.
class FocusBodyweightPanel extends StatefulWidget {
  const FocusBodyweightPanel({
    super.key,
    required this.reps,
    required this.onRepsBump,
    required this.onRepsCommitted,
    required this.enabled,
  });

  final int reps;

  final void Function(int delta) onRepsBump;
  final void Function(int reps) onRepsCommitted;

  final bool enabled;

  @override
  State<FocusBodyweightPanel> createState() => _FocusBodyweightPanelState();
}

class _FocusBodyweightPanelState extends State<FocusBodyweightPanel> {
  late final TextEditingController _reps;
  final FocusNode _repsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _reps = TextEditingController(text: widget.reps.toString());
    _repsFocus.addListener(_commitRepsOnBlur);
  }

  @override
  void didUpdateWidget(covariant FocusBodyweightPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_repsFocus.hasFocus && widget.reps != oldWidget.reps) {
      _reps.text = widget.reps.toString();
    }
  }

  @override
  void dispose() {
    _repsFocus.removeListener(_commitRepsOnBlur);
    _reps.dispose();
    _repsFocus.dispose();
    super.dispose();
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _BigNumericField(
          controller: _reps,
          focusNode: _repsFocus,
          label: 'reps',
          enabled: widget.enabled,
          onSubmitted: (text) {
            final parsed = int.tryParse(text.trim());
            if (parsed != null) widget.onRepsCommitted(parsed);
          },
        ),
        const SizedBox(height: AppSpacing.md),
        _BumpRow(
          steps: const [-1, 1],
          enabled: widget.enabled,
          onTap: widget.onRepsBump,
        ),
      ],
    );
  }
}

class _BigNumericField extends StatelessWidget {
  const _BigNumericField({
    required this.controller,
    required this.focusNode,
    required this.label,
    required this.enabled,
    required this.onSubmitted,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String label;
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
          keyboardType: const TextInputType.numberWithOptions(decimal: false),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
          ],
          onSubmitted: onSubmitted,
          style: typography.numericHero.copyWith(color: colors.onSurface),
          decoration: InputDecoration(
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
  });

  final List<int> steps;
  final bool enabled;
  final void Function(int delta) onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: SizedBox(
              height: AppSpacing.touchMin,
              child: OutlinedButton(
                onPressed: enabled ? () => onTap(steps[i]) : null,
                style: OutlinedButton.styleFrom(
                  foregroundColor: steps[i] < 0 ? colors.onSurfaceMuted : null,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.xs,
                  ),
                ),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    steps[i] > 0 ? '+${steps[i]}' : '${steps[i]}',
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
