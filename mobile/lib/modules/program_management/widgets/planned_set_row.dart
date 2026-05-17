import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';

class PlannedSetRow extends StatelessWidget {
  const PlannedSetRow({
    super.key,
    required this.setDraft,
    required this.onWeightChanged,
    required this.onRepsChanged,
    required this.onDurationChanged,
    required this.onDelete,
    required this.onDuplicate,
    this.reorderIndex,
  });

  final PlannedSetDraft setDraft;
  final void Function(String) onWeightChanged;
  final void Function(String) onRepsChanged;
  final void Function(String) onDurationChanged;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final int? reorderIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          if (reorderIndex != null)
            ReorderableDragStartListener(
              index: reorderIndex!,
              child: Padding(
                padding: const EdgeInsets.only(right: AppSpacing.sm),
                child: Icon(
                  Icons.drag_handle,
                  color: colors.onSurfaceMuted,
                  size: 20,
                ),
              ),
            ),
          Expanded(
            child: switch (setDraft.values) {
              PlannedSetDraftRepBased(:final weightInput, :final repsInput) =>
                _RepBasedFields(
                  weightInput: weightInput,
                  repsInput: repsInput,
                  onWeightChanged: onWeightChanged,
                  onRepsChanged: onRepsChanged,
                ),
              PlannedSetDraftTimeBased(
                :final durationInput,
                :final weightInput,
              ) =>
                _TimeBasedField(
                  durationInput: durationInput,
                  weightInput: weightInput,
                  onDurationChanged: onDurationChanged,
                  onWeightChanged: onWeightChanged,
                ),
            },
          ),
          IconButton(
            icon: Icon(
              Icons.content_copy_outlined,
              color: colors.onSurfaceMuted,
              size: 20,
            ),
            onPressed: onDuplicate,
            tooltip: 'Duplicate set',
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchMin,
              minHeight: AppSpacing.touchMin,
            ),
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: colors.error, size: 20),
            onPressed: onDelete,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(
              minWidth: AppSpacing.touchMin,
              minHeight: AppSpacing.touchMin,
            ),
          ),
        ],
      ),
    );
  }
}

class _RepBasedFields extends StatefulWidget {
  const _RepBasedFields({
    required this.weightInput,
    required this.repsInput,
    required this.onWeightChanged,
    required this.onRepsChanged,
  });

  final String weightInput;
  final String repsInput;
  final void Function(String) onWeightChanged;
  final void Function(String) onRepsChanged;

  @override
  State<_RepBasedFields> createState() => _RepBasedFieldsState();
}

class _RepBasedFieldsState extends State<_RepBasedFields> {
  late final TextEditingController _weightController;
  late final TextEditingController _repsController;

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(text: widget.weightInput);
    _repsController = TextEditingController(text: widget.repsInput);
  }

  @override
  void didUpdateWidget(_RepBasedFields oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weightInput != widget.weightInput &&
        _weightController.text != widget.weightInput) {
      _weightController.text = widget.weightInput;
    }
    if (oldWidget.repsInput != widget.repsInput &&
        _repsController.text != widget.repsInput) {
      _repsController.text = widget.repsInput;
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const typography = AppTypography.standard;
    final colors = Theme.of(context).appColors;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: typography.bodySmall.copyWith(color: colors.onSurface),
            decoration: const InputDecoration(
              labelText: 'Weight (kg)',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            onChanged: widget.onWeightChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _repsController,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9\-–]')),
            ],
            style: typography.bodySmall.copyWith(color: colors.onSurface),
            decoration: const InputDecoration(
              labelText: 'Reps (or range, e.g. 6-8)',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            onChanged: widget.onRepsChanged,
          ),
        ),
      ],
    );
  }
}

class _TimeBasedField extends StatefulWidget {
  const _TimeBasedField({
    required this.durationInput,
    required this.weightInput,
    required this.onDurationChanged,
    required this.onWeightChanged,
  });

  final String durationInput;
  final String weightInput;
  final void Function(String) onDurationChanged;
  final void Function(String) onWeightChanged;

  @override
  State<_TimeBasedField> createState() => _TimeBasedFieldState();
}

class _TimeBasedFieldState extends State<_TimeBasedField> {
  late final TextEditingController _durationController;
  late final TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _durationController = TextEditingController(text: widget.durationInput);
    _weightController = TextEditingController(text: widget.weightInput);
  }

  @override
  void didUpdateWidget(_TimeBasedField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.durationInput != widget.durationInput &&
        _durationController.text != widget.durationInput) {
      _durationController.text = widget.durationInput;
    }
    if (oldWidget.weightInput != widget.weightInput &&
        _weightController.text != widget.weightInput) {
      _weightController.text = widget.weightInput;
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const typography = AppTypography.standard;
    final colors = Theme.of(context).appColors;

    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            style: typography.bodySmall.copyWith(color: colors.onSurface),
            decoration: const InputDecoration(
              labelText: 'Duration (s)',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            onChanged: widget.onDurationChanged,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: TextField(
            controller: _weightController,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
            ],
            style: typography.bodySmall.copyWith(color: colors.onSurface),
            decoration: const InputDecoration(
              labelText: 'Weight (kg, opt)',
              contentPadding: EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
            ),
            onChanged: widget.onWeightChanged,
          ),
        ),
      ],
    );
  }
}
