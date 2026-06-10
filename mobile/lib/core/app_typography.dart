import 'package:flutter/painting.dart';

/// Typography tokens for the Zamaj app.
///
/// Uses the platform default font family so nothing is shipped in the
/// bundle for MVP. [numeric] and [numericLarge] enable tabular figures so
/// weights, reps, and timer readouts do not jitter as digits change.
class AppTypography {
  const AppTypography({
    required this.display,
    required this.displaySmall,
    required this.title,
    required this.titleSmall,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.labelSmall,
    required this.caption,
    required this.numeric,
    required this.numericXs,
    required this.numericSm,
    required this.numericMd,
    required this.numericLarge,
    required this.numericHero,
    required this.actionLabel,
    required this.badge,
    required this.overline,
  });

  final TextStyle display;
  final TextStyle displaySmall;
  final TextStyle title;
  final TextStyle titleSmall;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle labelSmall;
  final TextStyle caption;
  final TextStyle numeric;
  final TextStyle numericXs;
  final TextStyle numericSm;
  final TextStyle numericMd;
  final TextStyle numericLarge;
  final TextStyle numericHero;
  final TextStyle actionLabel;
  final TextStyle badge;

  /// Section eyebrow / group label: small, semibold, tracked. Rendered
  /// uppercase by [SectionHeader].
  final TextStyle overline;

  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  /// The one sanctioned non-default font family: a monospace face used only on
  /// the plan-text surfaces (import editor, plan-preview text, export preview)
  /// where column alignment carries meaning. Every other style uses the app's
  /// default family; this is intentionally the sole exception, referenced by
  /// name so the "one family" typography guard can carve it out.
  static const String monoFamily = 'monospace';

  static const AppTypography standard = AppTypography(
    display: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15),
    displaySmall: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),
    title: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    body: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),
    bodySmall: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    label: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.25),
    labelSmall: TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.25,
    ),
    caption: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3),
    numeric: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    numericXs: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    numericSm: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    numericMd: TextStyle(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.15,
      fontFeatures: _tabular,
    ),
    numericLarge: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.1,
      fontFeatures: _tabular,
    ),
    numericHero: TextStyle(
      fontSize: 44,
      fontWeight: FontWeight.w700,
      height: 1.05,
      fontFeatures: _tabular,
    ),
    actionLabel: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.5,
    ),
    badge: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, height: 1.2),
    overline: TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.8,
    ),
  );
}
