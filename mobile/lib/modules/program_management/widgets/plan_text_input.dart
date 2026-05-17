import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class PlanTextInput extends StatelessWidget {
  const PlanTextInput({
    super.key,
    required this.controller,
    required this.onChanged,
    required this.enabled,
  });

  final TextEditingController controller;
  final ValueChanged<String> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return TextField(
      controller: controller,
      onChanged: onChanged,
      enabled: enabled,
      maxLength: 100000,
      maxLines: null,
      minLines: 8,
      keyboardType: TextInputType.multiline,
      buildCounter:
          (context, {required currentLength, required isFocused, maxLength}) =>
              null,
      style: typography.body.copyWith(
        color: colors.onSurface,
        fontFamily: 'monospace',
      ),
      decoration: InputDecoration(
        hintText:
            'Program name\n'
            '\n'
            'Day 1\n'
            'Bench Press\n'
            '4x8 100kg 2m\n'
            '…',
        hintStyle: typography.body.copyWith(
          color: colors.onSurfaceMuted,
          fontFamily: 'monospace',
        ),
        contentPadding: const EdgeInsets.all(AppSpacing.lg),
      ),
    );
  }
}
