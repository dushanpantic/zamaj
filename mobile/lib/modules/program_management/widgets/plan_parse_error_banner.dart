import 'package:flutter/material.dart';
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
        color: colors.error.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.error.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: colors.error, size: 20),
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
      PlanParseErrorCode.empty_input => 'Empty input',
      PlanParseErrorCode.unknown_line => 'Unknown line',
      PlanParseErrorCode.missing_program_name => 'Missing program name',
      PlanParseErrorCode.missing_workout_day => 'Missing workout day',
      PlanParseErrorCode.orphan_set_line => 'Orphan set line',
      PlanParseErrorCode.orphan_superset_marker => 'Orphan superset marker',
      PlanParseErrorCode.input_too_large => 'Input too large',
    };
  }
}
