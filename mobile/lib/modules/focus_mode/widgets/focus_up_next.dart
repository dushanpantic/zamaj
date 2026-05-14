import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Lightweight one-line preview of what's next: either the next set on
/// the current exercise, or the next exercise. The design doc explicitly
/// asks the focus mode to *avoid* showing the entire workout.
class FocusUpNext extends StatelessWidget {
  const FocusUpNext({super.key, required this.label, required this.detail});

  /// Short prefix label, e.g. "Up next" or "Last set".
  final String label;

  /// Detail line, e.g. "Set 4 of 4" or "Incline DB Press".
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(Icons.arrow_forward, size: 16, color: colors.onSurfaceMuted),
        const SizedBox(width: AppSpacing.xs),
        Text(
          '$label  ',
          style: typography.caption.copyWith(color: colors.onSurfaceMuted),
        ),
        Expanded(
          child: Text(
            detail,
            style: typography.bodySmall.copyWith(color: colors.onSurface),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
