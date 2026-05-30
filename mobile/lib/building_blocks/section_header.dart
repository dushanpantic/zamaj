import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// The one section eyebrow for the app: an uppercase, tracked, muted label
/// that introduces a group of content.
///
/// Collapses the three drifting treatments (muted+tracking label, icon+label
/// row, boxed titleSmall) into a single role mapped to the
/// [AppTypography.overline] style, so the eyebrow's casing and tracking live in
/// exactly one place. An optional leading [icon] sits before the label; an
/// optional [trailing] widget (e.g. an "Add" action) is pinned to the far end
/// of the row.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.icon, this.trailing});

  final String title;
  final IconData? icon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final label = Text(
      title.toUpperCase(),
      style: AppTypography.standard.overline.copyWith(
        color: colors.onSurfaceMuted,
      ),
    );

    if (icon == null && trailing == null) return label;

    return Row(
      children: [
        if (icon != null) ...[
          AppIcon(icon!, size: AppIconSize.sm, color: colors.onSurfaceMuted),
          const SizedBox(width: AppSpacing.xs),
        ],
        Expanded(child: label),
        ?trailing,
      ],
    );
  }
}
