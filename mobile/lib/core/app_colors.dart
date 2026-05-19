import 'package:flutter/painting.dart';

/// Semantic color tokens for the Zamaj app.
///
/// Every UI file reads colors from [AppColors], never from hard-coded
/// [Color] literals. Dark is the default palette because gyms lean dark.
class AppColors {
  const AppColors({
    required this.background,
    required this.surface,
    required this.surfaceVariant,
    required this.outline,
    required this.onBackground,
    required this.onSurface,
    required this.onSurfaceMuted,
    required this.primary,
    required this.onPrimary,
    required this.error,
    required this.onError,
    required this.success,
    required this.warning,
    required this.planned,
    required this.actual,
    required this.exerciseCompleted,
    required this.exerciseSkipped,
    required this.exerciseReplaced,
    required this.warmup,
    required this.warmupBg,
    required this.loggableHint,
    required this.restTimer,
    required this.restTimerOvertime,
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;
  final Color outline;

  final Color onBackground;
  final Color onSurface;
  final Color onSurfaceMuted;

  final Color primary;
  final Color onPrimary;

  final Color error;
  final Color onError;
  final Color success;
  final Color warning;

  final Color planned;
  final Color actual;

  final Color exerciseCompleted;
  final Color exerciseSkipped;
  final Color exerciseReplaced;

  /// Foreground accent for warmup chips/badges/pills. Reused at the set
  /// level if warmup sets land later.
  final Color warmup;

  /// Tinted surface background for warmup containers. Designed to combine
  /// with [surface] / [surfaceVariant] at low alpha.
  final Color warmupBg;

  /// Subtle accent applied to the most-recently-touched exercise's loggable
  /// row so the user's eye returns there after a rest. Intended for use as a
  /// low-alpha background or border tint, not full-bleed text.
  final Color loggableHint;

  final Color restTimer;
  final Color restTimerOvertime;

  /// Translucent overlay color for modal/scrim layers behind dialogs and
  /// saving indicators. Always combined with an alpha around 0.4-0.6.
  final Color scrim;

  static const AppColors dark = AppColors(
    background: Color(0xFF0B0B0E),
    surface: Color(0xFF17171C),
    surfaceVariant: Color(0xFF22222A),
    outline: Color(0xFF3A3A44),
    onBackground: Color(0xFFE7E7EA),
    onSurface: Color(0xFFE7E7EA),
    onSurfaceMuted: Color(0xFF9A9AA6),
    primary: Color(0xFFF97316),
    onPrimary: Color(0xFF0B0B0E),
    error: Color(0xFFEF4444),
    onError: Color(0xFF0B0B0E),
    success: Color(0xFF22C55E),
    warning: Color(0xFFF59E0B),
    planned: Color(0xFF9A9AA6),
    actual: Color(0xFFE7E7EA),
    exerciseCompleted: Color(0xFF22C55E),
    exerciseSkipped: Color(0xFF71717A),
    exerciseReplaced: Color(0xFFF59E0B),
    warmup: Color(0xFF60A5FA),
    warmupBg: Color(0xFF1E293B),
    loggableHint: Color(0xFFF97316),
    restTimer: Color(0xFFF97316),
    restTimerOvertime: Color(0xFFEF4444),
    scrim: Color(0xCC000000),
  );

  static const AppColors light = AppColors(
    background: Color(0xFFFAFAF9),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF4F4F5),
    outline: Color(0xFFD4D4D8),
    onBackground: Color(0xFF18181B),
    onSurface: Color(0xFF18181B),
    onSurfaceMuted: Color(0xFF71717A),
    primary: Color(0xFFEA580C),
    onPrimary: Color(0xFFFFFFFF),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFD97706),
    planned: Color(0xFF71717A),
    actual: Color(0xFF18181B),
    exerciseCompleted: Color(0xFF16A34A),
    exerciseSkipped: Color(0xFFA1A1AA),
    exerciseReplaced: Color(0xFFD97706),
    warmup: Color(0xFF2563EB),
    warmupBg: Color(0xFFE0F2FE),
    loggableHint: Color(0xFFEA580C),
    restTimer: Color(0xFFEA580C),
    restTimerOvertime: Color(0xFFDC2626),
    scrim: Color(0x99000000),
  );
}
