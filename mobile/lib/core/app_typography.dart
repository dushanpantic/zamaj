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

  /// The app's bundled default family (Barlow, weights 400–700). Set on every
  /// [standard] style from this one definition point so the whole app renders
  /// in Barlow offline rather than the platform face.
  static const String _family = 'Barlow';

  static const AppTypography standard = AppTypography(
    display: TextStyle(
      fontFamily: _family,
      fontSize: 32,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),
    displaySmall: TextStyle(
      fontFamily: _family,
      fontSize: 28,
      fontWeight: FontWeight.w700,
      height: 1.15,
    ),
    title: TextStyle(
      fontFamily: _family,
      fontSize: 20,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    titleSmall: TextStyle(
      fontFamily: _family,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    body: TextStyle(
      fontFamily: _family,
      fontSize: 16,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    bodySmall: TextStyle(
      fontFamily: _family,
      fontSize: 14,
      fontWeight: FontWeight.w400,
      height: 1.4,
    ),
    label: TextStyle(
      fontFamily: _family,
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 1.25,
    ),
    labelSmall: TextStyle(
      fontFamily: _family,
      fontSize: 13,
      fontWeight: FontWeight.w500,
      height: 1.25,
    ),
    caption: TextStyle(
      fontFamily: _family,
      fontSize: 12,
      fontWeight: FontWeight.w400,
      height: 1.3,
    ),
    numeric: TextStyle(
      fontFamily: _family,
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    numericXs: TextStyle(
      fontFamily: _family,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    numericSm: TextStyle(
      fontFamily: _family,
      fontSize: 14,
      fontWeight: FontWeight.w600,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    numericMd: TextStyle(
      fontFamily: _family,
      fontSize: 22,
      fontWeight: FontWeight.w700,
      height: 1.15,
      fontFeatures: _tabular,
    ),
    numericLarge: TextStyle(
      fontFamily: _family,
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.1,
      fontFeatures: _tabular,
    ),
    numericHero: TextStyle(
      fontFamily: _family,
      fontSize: 44,
      fontWeight: FontWeight.w700,
      height: 1.05,
      fontFeatures: _tabular,
    ),
    actionLabel: TextStyle(
      fontFamily: _family,
      fontSize: 18,
      fontWeight: FontWeight.w700,
      height: 1.2,
      letterSpacing: 0.5,
    ),
    badge: TextStyle(
      fontFamily: _family,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
    ),
    overline: TextStyle(
      fontFamily: _family,
      fontSize: 12,
      fontWeight: FontWeight.w600,
      height: 1.2,
      letterSpacing: 0.8,
    ),
  );
}
