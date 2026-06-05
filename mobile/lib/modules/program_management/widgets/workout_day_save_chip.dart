import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class WorkoutDaySaveChip extends StatelessWidget {
  const WorkoutDaySaveChip({
    super.key,
    required this.isSaving,
    required this.hasError,
    required this.onRetry,
  });

  final bool isSaving;
  final bool hasError;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isError = hasError && !isSaving;
    final label = isError
        ? 'Save failed — tap to retry'
        : isSaving
        ? 'Saving…'
        : 'Saved';
    final color = isError ? colors.error : colors.onSurfaceMuted;
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: InkWell(
        onTap: isError ? onRetry : null,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.xs,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSaving)
                Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: AppStroke.indicatorCompact,
                      color: color,
                    ),
                  ),
                ),
              Text(
                label,
                style: AppTypography.standard.caption.copyWith(color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
