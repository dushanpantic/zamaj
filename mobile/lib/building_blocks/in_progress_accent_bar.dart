import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

/// The left-edge accent bar marking a tile whose program or day owns the
/// active in-flight session. Place it as a direct child of a [Stack], after
/// the tile body, so it fills the stack's left edge.
class InProgressAccentBar extends StatelessWidget {
  const InProgressAccentBar({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Positioned(
      left: 0,
      top: 0,
      bottom: 0,
      child: IgnorePointer(
        child: Container(
          width: AppSpacing.xs,
          decoration: BoxDecoration(
            color: colors.primary,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadius.md),
              bottomLeft: Radius.circular(AppRadius.md),
            ),
          ),
        ),
      ),
    );
  }
}
