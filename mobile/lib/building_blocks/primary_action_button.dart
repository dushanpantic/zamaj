import 'package:flutter/material.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// The one full-width primary action for the live-session surface — the same
/// chrome whether it reads `LOG SET` (focus / set-row), `SAVE` (editing an
/// existing set), or any other in-session commit.
///
/// Collapses the divergence (F4) where the focus `LOG SET` was 64 dp / radius
/// `lg` with a sub-label and the inline editor's button was 56 dp / radius `md`
/// with none: one height ([AppInSessionSize.primaryAction]), one radius
/// ([AppRadius.lg]), one label style ([AppTypography.actionLabel]), and an
/// optional [subLabel] (e.g. "Set 3 of 4"). [enabled] `false` greys it out and
/// blocks the tap.
class PrimaryActionButton extends StatelessWidget {
  const PrimaryActionButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.subLabel,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final String? subLabel;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return SizedBox(
      width: double.infinity,
      height: AppInSessionSize.primaryAction,
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
            Text(label, style: typography.actionLabel),
            if (subLabel != null) ...[
              const SizedBox(height: AppSpacing.xxs),
              Text(
                subLabel!,
                style: typography.caption.copyWith(
                  color: colors.onPrimary.withValues(
                    alpha: AppOpacity.labelSecondary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
