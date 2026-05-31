import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class SessionEndedBanner extends StatelessWidget {
  const SessionEndedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      margin: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.md,
        AppSpacing.lg,
        0,
      ),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.exerciseCompleted.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.exerciseCompleted.withValues(
            alpha: AppOpacity.borderTint,
          ),
        ),
      ),
      child: Row(
        children: [
          AppIcon(
            Icons.check_circle,
            color: colors.exerciseCompleted,
            size: AppIconSize.lg,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Session ended. Completed sets remain editable.',
              style: AppTypography.standard.bodySmall.copyWith(
                color: colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
