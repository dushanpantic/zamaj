import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Tall primary action button. Hosts the complete-set label, optionally
/// suffixed with a set-progress hint ("Set 3 of 4"). Bottom-of-screen, big
/// touch target — design doc calls for one-handed use.
class FocusCompleteButton extends StatelessWidget {
  const FocusCompleteButton({
    super.key,
    required this.onPressed,
    required this.label,
    this.subLabel,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final String label;
  final String? subLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return SizedBox(
      width: double.infinity,
      height: 64,
      child: FilledButton(
        onPressed: enabled ? onPressed : null,
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: typography.label.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
              ),
            ),
            if (subLabel != null) ...[
              const SizedBox(height: 2),
              Text(
                subLabel!,
                style: typography.caption.copyWith(
                  color: colors.onPrimary.withValues(alpha: 0.75),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
