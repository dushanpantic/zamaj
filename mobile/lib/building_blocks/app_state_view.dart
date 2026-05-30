import 'package:flutter/material.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Tonal intent of an [AppStateView], used to pick the hero-icon colour and
/// size from the palette so empty / error / success states read consistently.
enum AppStateTone {
  /// Empty / not-found — a muted, low-key illustration.
  neutral,

  /// A failure the user should notice and (usually) retry.
  error,

  /// A positive "nothing to do here" outcome (e.g. nothing left to suggest).
  success,
}

/// A single call-to-action rendered inside an [AppStateView].
///
/// The view decides the chrome (filled for primary, outlined for secondary);
/// the caller only supplies the verb, the handler, and an optional leading
/// glyph.
class AppStateAction {
  const AppStateAction({
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
}

/// The one full-screen empty / error / not-found view for the whole app.
///
/// Replaces the ~15 bespoke `_EmptyView` / `_FailureView` / `_NotFoundView`
/// classes that each re-derived a centred `Column(icon + title + body +
/// button)` with slightly different icon sizes and heading styles. The heading
/// is locked to one role ([AppTypography.title]) and the hero glyph to one
/// size ([AppIconSize.emptyState] / [AppIconSize.errorState]), so the "empty
/// state heading" role no longer drifts between 16 px and 20 px across screens.
///
/// Returns just the centred content — host it inside a `Scaffold`/`body` (it
/// does not provide its own).
class AppStateView extends StatelessWidget {
  const AppStateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.tone = AppStateTone.neutral,
    this.primaryAction,
    this.secondaryAction,
    this.iconSemanticLabel,
  });

  /// Hero glyph for the state.
  final IconData icon;

  /// Single-line role: what state this is ("No programs yet").
  final String title;

  /// Optional supporting sentence under the title.
  final String? message;

  /// Drives the hero-icon colour and size.
  final AppStateTone tone;

  /// Primary call-to-action (filled). Optional — informational states need
  /// none.
  final AppStateAction? primaryAction;

  /// Secondary call-to-action (outlined), stacked under the primary.
  final AppStateAction? secondaryAction;

  /// Screen-reader label for the hero glyph. Defaults to the [title] when not
  /// provided so the state is announced.
  final String? iconSemanticLabel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final iconColor = switch (tone) {
      AppStateTone.neutral => colors.onSurfaceMuted,
      AppStateTone.error => colors.error,
      AppStateTone.success => colors.success,
    };
    final iconSize = tone == AppStateTone.error
        ? AppIconSize.errorState
        : AppIconSize.emptyState;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              icon,
              color: iconColor,
              size: iconSize,
              semanticLabel: iconSemanticLabel ?? title,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              title,
              style: typography.title.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            if (message != null) ...[
              const SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: typography.body.copyWith(color: colors.onSurfaceMuted),
                textAlign: TextAlign.center,
              ),
            ],
            if (primaryAction != null) ...[
              const SizedBox(height: AppSpacing.xl),
              _StateActionButton(action: primaryAction!, isPrimary: true),
            ],
            if (secondaryAction != null) ...[
              const SizedBox(height: AppSpacing.md),
              _StateActionButton(action: secondaryAction!, isPrimary: false),
            ],
          ],
        ),
      ),
    );
  }
}

class _StateActionButton extends StatelessWidget {
  const _StateActionButton({required this.action, required this.isPrimary});

  final AppStateAction action;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final label = Text(action.label);
    final Widget button;
    if (isPrimary) {
      button = action.icon != null
          ? FilledButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: label,
            )
          : FilledButton(onPressed: action.onPressed, child: label);
    } else {
      button = action.icon != null
          ? OutlinedButton.icon(
              onPressed: action.onPressed,
              icon: Icon(action.icon),
              label: label,
            )
          : OutlinedButton(onPressed: action.onPressed, child: label);
    }

    return SizedBox(width: double.infinity, child: button);
  }
}
