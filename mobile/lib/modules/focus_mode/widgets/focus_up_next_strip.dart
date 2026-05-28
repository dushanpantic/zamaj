import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_group_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/focus_marquee_text.dart';

/// Compact strip directly below the app bar previewing the next group.
/// Sized small so it doesn't eat into the editor area; hidden on the
/// final group when there's nothing to preview.
class FocusUpNextStrip extends StatelessWidget {
  const FocusUpNextStrip({super.key, required this.group});

  final FocusModeGroupViewModel group;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final upNext = group.upNextGroupLabel;
    if (upNext == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: colors.surface.withValues(alpha: 0.25),
        border: Border(
          bottom: BorderSide(color: colors.outline.withValues(alpha: 0.4)),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.arrow_forward, size: 16, color: colors.onSurfaceMuted),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: FocusMarqueeText(
              text: 'Up next: $upNext',
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
          ),
        ],
      ),
    );
  }
}
