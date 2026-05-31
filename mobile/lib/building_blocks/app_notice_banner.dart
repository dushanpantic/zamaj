import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Tonal intent of an [AppNoticeBanner]. Drives the accent colour (icon,
/// hairline border, tinted fill) and the default leading glyph, mirroring the
/// way [AppStateView]'s `AppStateTone` picks its hero colour.
enum AppNoticeTone {
  /// A failure the user should notice — a save that didn't land, a delete that
  /// failed. Red.
  error,

  /// A caution that isn't a hard failure. Amber.
  warning,

  /// A neutral heads-up. Carries the rationed accent.
  info,
}

/// The one inline notice strip for the app — the compact sibling of
/// [AppStateView].
///
/// Where [AppStateView] owns the *whole* screen ("this list is empty / broke"),
/// [AppNoticeBanner] is the one-or-two-line strip pinned above a list or inside
/// a card for "this thing went wrong but the screen is otherwise fine." It
/// replaces the four re-derived banners — program management's
/// `DomainErrorBanner`, the picker's `MaterialBanner`, and the two live-surface
/// transient banners — that each re-guessed the same `error @ tintFill` fill,
/// `error @ borderTint` hairline, leading icon, and dismiss affordance.
///
/// Chrome is entirely token-sourced: the fill is the tone colour at
/// [AppOpacity.tintFill], the hairline border the same colour at
/// [AppOpacity.borderTint] / [AppStroke.hairline]. It follows the dark-first
/// "depth is a lighter surface + an outline, never a drop-shadow" rule, so it
/// carries no shadow.
///
/// Pure presentation: it takes already-presented [title] / [body] strings, not
/// a `DomainError`, so it stays domain-free like the rest of `building_blocks`.
/// Callers map their domain error to strings (e.g. via `DomainErrorPresenter`)
/// before handing them in.
class AppNoticeBanner extends StatelessWidget {
  const AppNoticeBanner({
    super.key,
    required this.title,
    this.body,
    this.tone = AppNoticeTone.error,
    this.icon,
    this.onDismiss,
    this.margin = const EdgeInsets.symmetric(
      horizontal: AppSpacing.lg,
      vertical: AppSpacing.sm,
    ),
  });

  /// Single-line headline naming what happened.
  final String title;

  /// Optional supporting detail rendered under the [title].
  final String? body;

  /// Drives the accent colour and the default leading glyph.
  final AppNoticeTone tone;

  /// Overrides the tone's default leading glyph when a more specific icon reads
  /// better. Defaults to the tone's conventional glyph.
  final IconData? icon;

  /// When non-null, renders a trailing dismiss affordance (a full
  /// [AppSpacing.touchMin] tap target) that invokes this.
  final VoidCallback? onDismiss;

  /// Outer margin around the strip. Defaults to the standard inset used when the
  /// banner is pinned above a list; pass [EdgeInsets.zero] for a banner that
  /// sits flush inside a card.
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final accent = switch (tone) {
      AppNoticeTone.error => colors.error,
      AppNoticeTone.warning => colors.warning,
      AppNoticeTone.info => colors.primary,
    };
    final glyph =
        icon ??
        switch (tone) {
          AppNoticeTone.error => Icons.error_outline,
          AppNoticeTone.warning => Icons.warning_amber_rounded,
          AppNoticeTone.info => Icons.info_outline,
        };

    return Container(
      margin: margin,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: accent.withValues(alpha: AppOpacity.borderTint),
          width: AppStroke.hairline,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppIcon(glyph, color: accent, size: AppIconSize.lg),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: typography.label.copyWith(color: accent)),
                if (body != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    body!,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: AppSpacing.sm),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: AppIcon(
                Icons.close,
                color: colors.onSurfaceMuted,
                size: AppIconSize.md,
              ),
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                minWidth: AppSpacing.touchMin,
                minHeight: AppSpacing.touchMin,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
