import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/increment_rules.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_numeric_field.dart';

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
        FocusBigNumericField(
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
        FocusBumpRow(
          steps: IncrementRules.repStepsDouble,
          enabled: widget.enabled,
          onTap: (delta) => widget.onRepsBump(delta.round()),
          formatter: (v) => v.toInt().toString(),
        ),
      ],
    );
  }
}
