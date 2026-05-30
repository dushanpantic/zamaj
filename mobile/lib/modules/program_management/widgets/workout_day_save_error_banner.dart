import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';

class WorkoutDaySaveErrorBanner extends StatelessWidget {
  const WorkoutDaySaveErrorBanner({
    super.key,
    required this.error,
    required this.onDismiss,
  });

  final DomainError error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      color: colors.error.withValues(alpha: AppOpacity.tintFill),
      child: Row(
        children: [
          AppIcon(
            Icons.error_outline,
            color: colors.error,
            size: AppIconSize.sm,
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              'Failed to save. Please try again.',
              style: AppTypography.standard.labelSmall.copyWith(
                color: colors.error,
              ),
            ),
          ),
          IconButton(
            iconSize: 16,
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            tooltip: 'Dismiss',
            icon: Icon(Icons.close, color: colors.error),
            onPressed: onDismiss,
          ),
        ],
      ),
    );
  }
}
