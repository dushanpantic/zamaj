import 'package:flutter/animation.dart';

/// Motion tokens for the Zamaj UI: every animated widget reads its duration and
/// curve from one of these named steps instead of a hand-picked literal.
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
