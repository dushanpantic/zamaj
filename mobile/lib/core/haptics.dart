import 'package:flutter/services.dart';

/// App-wide haptic vocabulary.
///
/// Centralises the policy so the same action class fires the same intensity
/// across screens (set logged, drag accepted, rest-overtime, etc.). Haptics
/// are no-ops on platforms / test environments that don't support the
/// HapticFeedback platform channel, so callers do not need to guard.
abstract final class Haptics {
  /// Discrete user action confirmation: set logged, set undone, drag
  /// accepted, exercise complete.
  static Future<void> tap() => HapticFeedback.lightImpact();

  /// Sustained-press start (long-press drag began).
  static Future<void> grab() => HapticFeedback.mediumImpact();

  /// One-shot emphasis: rest-timer crossed into overtime, workout
  /// finished.
  static Future<void> emphasis() => HapticFeedback.heavyImpact();
}
