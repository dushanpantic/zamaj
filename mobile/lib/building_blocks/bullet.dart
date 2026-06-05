import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';

/// A small round list bullet that vertically centers against the first line of
/// its accompanying text. Pass the [textStyle] of that text so the dot sits on
/// the line's optical center, replacing per-call top-padding nudges.
class Bullet extends StatelessWidget {
  const Bullet({
    super.key,
    required this.textStyle,
    this.color,
    this.size = AppSpacing.xs,
  });

  /// Text style of the line this bullet sits beside; its line height drives the
  /// dot's vertical centering.
  final TextStyle textStyle;

  /// Dot colour. Defaults to the muted on-surface colour.
  final Color? color;

  /// Dot diameter.
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final lineHeight = (textStyle.fontSize ?? size) * (textStyle.height ?? 1.0);
    return SizedBox(
      width: size,
      height: lineHeight,
      child: Center(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: color ?? colors.onSurfaceMuted,
            shape: BoxShape.circle,
          ),
        ),
      ),
    );
  }
}
