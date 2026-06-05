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
    required this.surfaceElevated,
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
    required this.scrim,
  });

  final Color background;
  final Color surface;
  final Color surfaceVariant;

  /// Fourth tonal step, lighter than [surface]/[surfaceVariant], for the
  /// top-most modal layers (dialogs and bottom sheets) so they read as sitting
  /// *above* the cards on the page instead of level with them.
  final Color surfaceElevated;

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

  /// Foreground accent for warmup chips/badges/pills.
  final Color warmup;

  /// Tinted surface background for warmup containers. Designed to combine
  /// with [surface] / [surfaceVariant] at low alpha.
  final Color warmupBg;

  /// Subtle accent applied to the most-recently-touched exercise's loggable
  /// row so the user's eye returns there after a rest. Intended for use as a
  /// low-alpha background or border tint, not full-bleed text.
  final Color loggableHint;

  final Color restTimer;

  /// Translucent overlay color for modal/scrim layers behind dialogs and
  /// saving indicators. Always combined with an alpha around 0.4-0.6.
  final Color scrim;

  // Palette: "Ember", warm graphite surfaces with a molten-orange accent.
  static const AppColors dark = AppColors(
    background: Color(0xFF100E0C),
    surface: Color(0xFF1B1815),
    surfaceVariant: Color(0xFF272320),
    surfaceElevated: Color(0xFF332E2A),
    outline: Color(0xFF3D3833),
    onBackground: Color(0xFFECEAE6),
    onSurface: Color(0xFFECEAE6),
    onSurfaceMuted: Color(0xFFA39E96),
    primary: Color(0xFFF97316),
    onPrimary: Color(0xFF1A1005),
    error: Color(0xFFEF4444),
    onError: Color(0xFF1A0A0A),
    success: Color(0xFF22C55E),
    warning: Color(0xFFFACC15),
    planned: Color(0xFFA39E96),
    actual: Color(0xFFF4EFE8),
    exerciseCompleted: Color(0xFF22C55E),
    exerciseSkipped: Color(0xFF78716C),
    exerciseReplaced: Color(0xFFC084FC),
    warmup: Color(0xFF38BDF8),
    warmupBg: Color(0xFF13262B),
    loggableHint: Color(0xFFF97316),
    restTimer: Color(0xFFF97316),
    scrim: Color(0xCC000000),
  );

  // Light palette. The app is dark-first, so this is kept token-correct but
  // unpolished.
  static const AppColors light = AppColors(
    background: Color(0xFFFBF8F4),
    surface: Color(0xFFFFFFFF),
    surfaceVariant: Color(0xFFF4F1EC),
    surfaceElevated: Color(0xFFFFFFFF),
    outline: Color(0xFFDDD7CE),
    onBackground: Color(0xFF1C1A17),
    onSurface: Color(0xFF1C1A17),
    onSurfaceMuted: Color(0xFF76706A),
    primary: Color(0xFFEA580C),
    onPrimary: Color(0xFFFFFFFF),
    error: Color(0xFFDC2626),
    onError: Color(0xFFFFFFFF),
    success: Color(0xFF16A34A),
    warning: Color(0xFFCA8A04),
    planned: Color(0xFF76706A),
    actual: Color(0xFF1C1A17),
    exerciseCompleted: Color(0xFF16A34A),
    exerciseSkipped: Color(0xFFA8A29E),
    exerciseReplaced: Color(0xFF9333EA),
    warmup: Color(0xFF0284C7),
    warmupBg: Color(0xFFE0F2FE),
    loggableHint: Color(0xFFEA580C),
    restTimer: Color(0xFFEA580C),
    scrim: Color(0x99000000),
  );
}
