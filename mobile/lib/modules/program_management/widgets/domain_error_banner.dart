import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';

class DomainErrorBanner extends StatelessWidget {
  const DomainErrorBanner({super.key, required this.error, this.onDismiss});

  final DomainError error;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final presented = DomainErrorPresenter.present(error);

    return Container(
      margin: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
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
                  presented.title,
                  style: typography.label.copyWith(color: colors.error),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  presented.body,
                  style: typography.bodySmall.copyWith(color: colors.onSurface),
                ),
              ],
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: AppIcon(
                Icons.close,
                color: colors.onSurfaceMuted,
                size: AppIconSize.md,
              ),
            ),
        ],
      ),
    );
  }
}
