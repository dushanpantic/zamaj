import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

class LibraryLinkChip extends StatelessWidget {
  const LibraryLinkChip({
    super.key,
    required this.isLinked,
    required this.linkedName,
    required this.onTap,
  });

  /// Whether the exercise is linked to a library entry. Decoupled from
  /// [linkedName]: an exercise can be linked while its library entry's name is
  /// still being resolved (or has been deleted), in which case the chip shows a
  /// generic "Linked" rather than the exercise's own (local) name.
  final bool isLinked;

  /// The linked **library entry's** name, or null when unlinked / unresolved.
  /// This is intentionally not the exercise's local name — the two can differ
  /// when the user keeps a local name while linking to a library movement.
  final String? linkedName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bg = isLinked
        ? colors.primary.withValues(alpha: AppOpacity.tintFill)
        : colors.surfaceVariant;
    final fg = isLinked ? colors.primary : colors.onSurfaceMuted;
    final iconData = isLinked ? Icons.link : Icons.link_off;
    final label = isLinked
        ? (linkedName == null ? 'Linked' : 'Linked: $linkedName')
        : 'Not in library · Link';
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
            AppIcon(iconData, size: AppIconSize.sm, color: fg),
            const SizedBox(width: AppSpacing.xs),
            Flexible(
              child: Text(
                label,
                style: AppTypography.standard.label.copyWith(color: fg),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            AppIcon(Icons.chevron_right, size: AppIconSize.sm, color: fg),
          ],
        ),
      ),
    );
  }
}
