import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

/// A single placeholder bar standing in for a line of text while content
/// loads.
///
/// Replaces the two identical per-screen `_SkeletonBar` copies. Static (no
/// shimmer) by design — motion tokens land in a later slice, and a calm
/// placeholder reads fine on the near-black canvas. Provide at most one of
/// [width] (a fixed size, for an inline bar inside a row) or [widthFactor] (a
/// fraction of the available width, preferred inside tiles so bars scale with
/// the card).
class AppSkeletonBar extends StatelessWidget {
  const AppSkeletonBar({
    super.key,
    this.width,
    this.widthFactor,
    this.height = AppSpacing.md,
  }) : assert(
         width == null || widthFactor == null,
         'Provide at most one of width or widthFactor.',
       );

  final double? width;
  final double? widthFactor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final bar = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: colors.surfaceVariant,
        borderRadius: BorderRadius.circular(AppRadius.sm),
      ),
    );
    if (widthFactor == null) return bar;
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: bar,
    );
  }
}

/// Card-shaped placeholder mirroring the standard list-tile chrome (surface
/// fill, hairline outline, [AppRadius.md]) with [lineWidthFactors] stacked
/// [AppSkeletonBar]s. Drop-in for one loading list row.
class AppSkeletonTile extends StatelessWidget {
  const AppSkeletonTile({
    super.key,
    this.lineWidthFactors = const [0.55, 0.38],
  });

  /// One bar per entry, each sized to the given fraction of the tile width.
  /// The default mirrors a title line over a shorter metadata line.
  final List<double> lineWidthFactors;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.md,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < lineWidthFactors.length; i++) ...[
            if (i > 0) const SizedBox(height: AppSpacing.xs),
            AppSkeletonBar(widthFactor: lineWidthFactors[i]),
          ],
        ],
      ),
    );
  }
}

/// A non-interactive, non-scrolling list of [AppSkeletonTile]s that mirrors a
/// loading list, using the same outer padding and item rhythm as the real
/// lists so content doesn't jump when it arrives.
///
/// This is the standard content-load placeholder; a bare spinner is reserved
/// for blocking save/commit waits where the layout can't be predicted.
class AppListSkeleton extends StatelessWidget {
  const AppListSkeleton({
    super.key,
    this.itemCount = 5,
    this.lineWidthFactors = const [0.55, 0.38],
    this.padding,
  });

  final int itemCount;
  final List<double> lineWidthFactors;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final resolvedPadding =
        padding ??
        EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          top: AppSpacing.lg,
          bottom: AppSpacing.xxxl + MediaQuery.viewPaddingOf(context).bottom,
        );

    return Semantics(
      label: 'Loading',
      container: true,
      child: ExcludeSemantics(
        child: ListView.separated(
          padding: resolvedPadding,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: itemCount,
          separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, _) =>
              AppSkeletonTile(lineWidthFactors: lineWidthFactors),
        ),
      ),
    );
  }
}
