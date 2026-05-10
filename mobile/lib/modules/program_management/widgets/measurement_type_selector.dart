import 'package:flutter/material.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';

class MeasurementTypeSelector extends StatelessWidget {
  const MeasurementTypeSelector({
    super.key,
    required this.selected,
    required this.onChanged,
    this.enabled = true,
  });

  final MeasurementType selected;
  final void Function(MeasurementType) onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Row(
      children: [
        _TypeChip(
          label: 'Rep-based',
          isSelected: selected is RepBasedMeasurement,
          enabled: enabled,
          onTap: enabled
              ? () => onChanged(const MeasurementType.repBased())
              : null,
          colors: colors,
        ),
        const SizedBox(width: AppSpacing.sm),
        _TypeChip(
          label: 'Time-based',
          isSelected: selected is TimeBasedMeasurement,
          enabled: enabled,
          onTap: enabled
              ? () => onChanged(const MeasurementType.timeBased())
              : null,
          colors: colors,
        ),
      ],
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.isSelected,
    required this.enabled,
    required this.onTap,
    required this.colors,
  });

  final String label;
  final bool isSelected;
  final bool enabled;
  final VoidCallback? onTap;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    const typography = AppTypography.standard;

    final backgroundColor = isSelected
        ? (enabled ? colors.primary : colors.primary.withValues(alpha: 0.5))
        : colors.surfaceVariant;

    final textColor = isSelected
        ? (enabled ? colors.onPrimary : colors.onPrimary.withValues(alpha: 0.5))
        : (enabled
              ? colors.onSurfaceMuted
              : colors.onSurfaceMuted.withValues(alpha: 0.5));

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(label, style: typography.label.copyWith(color: textColor)),
      ),
    );
  }
}
