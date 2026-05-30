import 'package:flutter/animation.dart';

/// Motion tokens for the Zamaj UI.
///
/// Mirrors [AppSpacing] / [AppRadius] / [AppIconSize]: every animated widget
/// reads its duration and curve from one of these named steps instead of a
/// hand-picked literal, so transitions feel like one designed system rather
/// than per-screen guesses. Three durations cover the app — the scattered
/// 80 / 120 / 150 / 220 ms literals collapse onto [fast] / [base] / [slow]
/// (the two 150 ms cases round to [base]; the gap is imperceptible).
abstract final class AppDuration {
  /// Micro-feedback: a press/drag scale or fade that should feel instant.
  static const Duration fast = Duration(milliseconds: 80);

  /// Standard layout transition — the workhorse (gaps, card borders, opacity).
  static const Duration base = Duration(milliseconds: 120);

  /// Larger panel / content transition (e.g. the focus panel resizing).
  static const Duration slow = Duration(milliseconds: 220);
}

/// Easing curves paired with [AppDuration]. Two curves cover the app: a
/// [standard] decelerating ease for most transitions and a slightly springier
/// [emphasized] ease for the larger, more noticeable panel motion.
abstract final class AppCurve {
  /// Default decelerating ease for most transitions.
  static const Curve standard = Curves.easeOut;

  /// Emphasized ease for larger, more prominent motion (e.g. panel resize).
  static const Curve emphasized = Curves.easeOutCubic;
}
