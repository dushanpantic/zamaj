import 'package:flutter/material.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_typography.dart';

/// Builds Material [ThemeData] from Zamaj design tokens.
///
/// [MaterialApp] wires `theme: AppTheme.light()` and
/// `darkTheme: AppTheme.dark()`; `themeMode: ThemeMode.dark` is the default
/// recommended setting for this product. Widgets should prefer reading
/// colors from [AppColorsExtension] via `Theme.of(context).appColors`
/// rather than from the raw [ColorScheme].
abstract final class AppTheme {
  static ThemeData dark() => _build(AppColors.dark, Brightness.dark);

  static ThemeData light() => _build(AppColors.light, Brightness.light);

  static ThemeData _build(AppColors colors, Brightness brightness) {
    final scheme = ColorScheme(
      brightness: brightness,
      primary: colors.primary,
      onPrimary: colors.onPrimary,
      secondary: colors.primary,
      onSecondary: colors.onPrimary,
      error: colors.error,
      onError: colors.onError,
      surface: colors.surface,
      onSurface: colors.onSurface,
    );

    const typography = AppTypography.standard;

    final textTheme = TextTheme(
      displayLarge: typography.display.copyWith(color: colors.onBackground),
      titleLarge: typography.title.copyWith(color: colors.onSurface),
      titleMedium: typography.titleSmall.copyWith(color: colors.onSurface),
      bodyLarge: typography.body.copyWith(color: colors.onSurface),
      bodyMedium: typography.bodySmall.copyWith(color: colors.onSurface),
      labelLarge: typography.label.copyWith(color: colors.onSurface),
      labelMedium: typography.label.copyWith(color: colors.onSurfaceMuted),
      labelSmall: typography.caption.copyWith(color: colors.onSurfaceMuted),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: colors.background,
      canvasColor: colors.background,
      dividerColor: colors.outline,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colors.background,
        foregroundColor: colors.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: typography.title.copyWith(color: colors.onBackground),
      ),
      cardTheme: CardThemeData(
        color: colors.surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(color: colors.outline),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: colors.surfaceVariant,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: colors.error),
        ),
        labelStyle: typography.label.copyWith(color: colors.onSurfaceMuted),
        hintStyle: typography.body.copyWith(color: colors.onSurfaceMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(64, AppSpacing.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: typography.label,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: colors.primary,
          foregroundColor: colors.onPrimary,
          minimumSize: const Size(64, AppSpacing.touchMin),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: typography.label,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.onSurface,
          minimumSize: const Size(64, AppSpacing.touchMin),
          side: BorderSide(color: colors.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          textStyle: typography.label,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          minimumSize: const Size(64, AppSpacing.touchMin),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          textStyle: typography.label,
        ),
      ),
      iconTheme: IconThemeData(color: colors.onSurface, size: 24),
      dividerTheme: DividerThemeData(
        color: colors.outline,
        space: 1,
        thickness: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.surfaceVariant,
        contentTextStyle: typography.body.copyWith(color: colors.onSurface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      extensions: <ThemeExtension<dynamic>>[AppColorsExtension(colors)],
    );
  }
}

/// Theme extension that exposes the full [AppColors] palette through
/// `Theme.of(context).extension<AppColorsExtension>()`.
///
/// Widgets typically use the [AppColorsX] helper instead:
/// `Theme.of(context).appColors.planned`.
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension(this.colors);

  final AppColors colors;

  @override
  AppColorsExtension copyWith({AppColors? colors}) =>
      AppColorsExtension(colors ?? this.colors);

  @override
  AppColorsExtension lerp(ThemeExtension<AppColorsExtension>? other, double t) {
    if (other is! AppColorsExtension) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppColorsX on ThemeData {
  AppColors get appColors =>
      extension<AppColorsExtension>()?.colors ?? AppColors.dark;
}
