import 'package:flutter/widgets.dart';

/// Icon-size scale for the Zamaj UI.
///
/// Mirrors [AppSpacing] / [AppRadius]: every icon reads its size from one of
/// these named steps instead of a hand-picked literal, so the same role — an
/// inline action glyph, an empty-state illustration — is the same size
/// everywhere. Prefer [AppIcon] over a raw `Icon` so the size is always a
/// token.
abstract final class AppIconSize {
  /// Tiny inline glyph in a dense row (e.g. a rest-timer dot).
  static const double xs = 12;

  /// Small inline glyph paired with caption/label text.
  static const double sm = 16;

  /// Default inline action / kebab glyph — the most common size.
  static const double md = 18;

  /// Emphasized inline glyph (list affordances, menu triggers, chevrons).
  static const double lg = 20;

  /// Toolbar / app-bar default (matches the ambient `IconTheme`).
  static const double xl = 24;

  /// Status glyph on a card (done check, warmup flame). Same value as [md];
  /// named separately so the "state marker" role is explicit at the call site.
  static const double status = 18;

  /// Hero glyph for an empty / not-found state view.
  static const double emptyState = 64;

  /// Hero glyph for an error state view. Same value as [emptyState] — empty
  /// and error views share one hero size (resolves the old 48-vs-64 drift).
  static const double errorState = 64;
}

/// Token-sized [Icon] wrapper.
///
/// Always sizes from [AppIconSize] (defaulting to [AppIconSize.md] for inline
/// glyphs) so call sites never reach for a raw pixel literal. [semanticLabel]
/// is optional for decorative icons but **should be provided for interactive
/// icons** (those standing alone as a tappable affordance) so screen readers
/// announce the action.
class AppIcon extends StatelessWidget {
  const AppIcon(
    this.icon, {
    super.key,
    this.size = AppIconSize.md,
    this.color,
    this.semanticLabel,
  });

  final IconData icon;
  final double size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) =>
      Icon(icon, size: size, color: color, semanticLabel: semanticLabel);
}
