import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

/// Named diameters for an inline progress spinner — one small scale so every
/// call site picks a step instead of a raw pixel size.
enum AppInlineSpinnerSize {
  /// 12 dp — inside a dense chip or caption row (e.g. the save-state chip).
  sm,

  /// 16 dp — the default; stands in for an inline icon in a button or app-bar
  /// action slot.
  md,

  /// 24 dp — a prominent inline wait (e.g. a deleting list tile).
  lg,
}

/// The one inline progress spinner used wherever a control shows in-place work
/// without blocking the screen: button icons, app-bar actions, save chips.
///
/// Diameter comes from [AppSpinnerSize] via [size]; stroke comes from
/// [AppStroke] (the compact stroke for [AppInlineSpinnerSize.sm], the standard
/// indicator stroke otherwise). Colour defaults to `onSurfaceMuted`; pass
/// [color] for on-primary contexts such as inside a filled button.
class AppInlineSpinner extends StatelessWidget {
  const AppInlineSpinner({
    super.key,
    this.size = AppInlineSpinnerSize.md,
    this.color,
  });

  final AppInlineSpinnerSize size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final resolvedColor = color ?? Theme.of(context).appColors.onSurfaceMuted;
    final (diameter, stroke) = switch (size) {
      AppInlineSpinnerSize.sm => (
        AppSpinnerSize.sm,
        AppStroke.indicatorCompact,
      ),
      AppInlineSpinnerSize.md => (AppSpinnerSize.md, AppStroke.indicator),
      AppInlineSpinnerSize.lg => (AppSpinnerSize.lg, AppStroke.indicator),
    };
    return SizedBox(
      width: diameter,
      height: diameter,
      child: CircularProgressIndicator(
        strokeWidth: stroke,
        color: resolvedColor,
      ),
    );
  }
}
