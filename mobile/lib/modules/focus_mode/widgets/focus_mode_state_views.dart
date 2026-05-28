import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';

class FocusLoadingView extends StatelessWidget {
  const FocusLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Center(child: CircularProgressIndicator(color: colors.primary));
  }
}

class FocusNotFoundView extends StatelessWidget {
  const FocusNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.search_off, color: colors.onSurfaceMuted, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Session not found',
              style: typography.titleSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton(
              onPressed: () => Navigator.of(context).maybePop(),
              child: const Text('Back'),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusErrorView extends StatelessWidget {
  const FocusErrorView({super.key, required this.error, required this.onRetry});

  final DomainError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final presented = DomainErrorPresenter.present(error);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              presented.title,
              style: typography.titleSmall.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              presented.body,
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class FocusTransientErrorBanner extends StatelessWidget {
  const FocusTransientErrorBanner({
    super.key,
    required this.error,
    required this.onDismiss,
  });

  final DomainError error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final presented = DomainErrorPresenter.present(error);
    return Material(
      color: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: colors.background,
          borderRadius: BorderRadius.circular(AppRadius.md),
          border: Border.all(color: colors.error.withValues(alpha: 0.6)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 20),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    presented.title,
                    style: typography.label.copyWith(color: colors.error),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    presented.body,
                    style: typography.bodySmall.copyWith(
                      color: colors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              tooltip: 'Dismiss',
              icon: Icon(Icons.close, color: colors.onSurfaceMuted, size: 18),
              constraints: const BoxConstraints(
                minWidth: AppSpacing.touchMin,
                minHeight: AppSpacing.touchMin,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
