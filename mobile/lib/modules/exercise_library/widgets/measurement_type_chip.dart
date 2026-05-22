import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// Small read-only badge that names a [MeasurementType]. Used in tiles and
/// suggestion cards. Not interactive — use `MeasurementTypeSelector` from
/// program_management for the editor control.
class MeasurementTypeChip extends StatelessWidget {
  const MeasurementTypeChip({super.key, required this.measurementType});

  final MeasurementType measurementType;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        labelFor(measurementType),
        style: typography.badge.copyWith(color: colors.onSurfaceMuted),
      ),
    );
  }

  static String labelFor(MeasurementType type) {
    return switch (type) {
      RepBasedMeasurement() => 'Reps',
      TimeBasedMeasurement() => 'Time',
      BodyweightMeasurement() => 'Bodyweight',
    };
  }
}
