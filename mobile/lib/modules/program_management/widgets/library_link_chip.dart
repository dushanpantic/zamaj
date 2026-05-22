import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class LibraryLinkChip extends StatelessWidget {
  const LibraryLinkChip({
    super.key,
    required this.linkedName,
    required this.onTap,
  });

  final String? linkedName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final isLinked = linkedName != null;
    final bg = isLinked
        ? colors.primary.withValues(alpha: 0.12)
        : colors.surfaceVariant;
    final fg = isLinked ? colors.primary : colors.onSurfaceMuted;
    final iconData = isLinked ? Icons.link : Icons.link_off;
    final label = isLinked ? 'Linked: $linkedName' : 'Not in library · Link';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(iconData, size: 16, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTypography.standard.label.copyWith(color: fg),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Icon(Icons.chevron_right, size: 16, color: fg),
          ],
        ),
      ),
    );
  }
}
