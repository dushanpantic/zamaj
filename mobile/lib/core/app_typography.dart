import 'package:flutter/painting.dart';

/// Typography tokens for the Zamaj app.
///
/// Uses the platform default font family so nothing is shipped in the
/// bundle for MVP. [numeric] and [numericLarge] enable tabular figures so
/// weights, reps, and timer readouts do not jitter as digits change.
class AppTypography {
  const AppTypography({
    required this.display,
    required this.title,
    required this.titleSmall,
    required this.body,
    required this.bodySmall,
    required this.label,
    required this.caption,
    required this.numeric,
    required this.numericLarge,
  });

  final TextStyle display;
  final TextStyle title;
  final TextStyle titleSmall;
  final TextStyle body;
  final TextStyle bodySmall;
  final TextStyle label;
  final TextStyle caption;
  final TextStyle numeric;
  final TextStyle numericLarge;

  static const _tabular = <FontFeature>[FontFeature.tabularFigures()];

  static const AppTypography standard = AppTypography(
    display: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, height: 1.15),
    title: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, height: 1.2),
    titleSmall: TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.25,
    ),
    body: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, height: 1.4),
    bodySmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, height: 1.4),
    label: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, height: 1.25),
    caption: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, height: 1.3),
    numeric: TextStyle(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      height: 1.2,
      fontFeatures: _tabular,
    ),
    numericLarge: TextStyle(
      fontSize: 36,
      fontWeight: FontWeight.w700,
      height: 1.1,
      fontFeatures: _tabular,
    ),
  );
}
