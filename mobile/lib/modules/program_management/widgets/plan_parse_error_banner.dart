import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_error.dart';

class PlanParseErrorBanner extends StatelessWidget {
  const PlanParseErrorBanner({super.key, required this.error});

  final PlanParseError error;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.error.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.error.withValues(alpha: AppOpacity.borderTint),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(
            Icons.error_outline,
            color: colors.error,
            size: AppIconSize.lg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _errorCodeLabel(error.code),
                  style: typography.label.copyWith(color: colors.error),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Line ${error.line}, column ${error.column}',
                  style: typography.caption.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  error.message,
                  style: typography.bodySmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _errorCodeLabel(PlanParseErrorCode code) {
    return switch (code) {
      PlanParseErrorCode.emptyInput => 'Empty input',
      PlanParseErrorCode.unknownLine => 'Unknown line',
      PlanParseErrorCode.missingProgramName => 'Missing program name',
      PlanParseErrorCode.missingWorkoutDay => 'Missing workout day',
      PlanParseErrorCode.orphanSetLine => 'Orphan set line',
      PlanParseErrorCode.orphanSupersetMarker => 'Orphan superset marker',
      PlanParseErrorCode.inputTooLarge => 'Input too large',
    };
  }
}
