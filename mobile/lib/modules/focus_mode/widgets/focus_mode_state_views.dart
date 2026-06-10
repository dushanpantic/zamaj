import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';

class FocusLoadingView extends StatelessWidget {
  const FocusLoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingView();
  }
}

class FocusNotFoundView extends StatelessWidget {
  const FocusNotFoundView({super.key});

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      icon: Icons.search_off,
      title: 'Session not found',
      primaryAction: AppStateAction(
        label: 'Back',
        onPressed: () => Navigator.of(context).maybePop(),
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
    final presented = DomainErrorPresenter.present(error);
    return AppStateView(
      icon: Icons.error_outline,
      tone: AppStateTone.error,
      title: presented.title,
      message: presented.body,
      primaryAction: AppStateAction(
        label: 'Retry',
        icon: Icons.refresh,
        onPressed: onRetry,
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
    final presented = DomainErrorPresenter.present(error);
    // Floats over the scrolling panels (positioned by `focus_ready_body`), so
    // it sits on an opaque `background` base to occlude what's behind it — the
    // same effective look the inline banner has over the scaffold. Depth is the
    // tint + outline, never a drop-shadow (dark-first house style).
    return Material(
      color: colors.background,
      borderRadius: BorderRadius.circular(AppRadius.md),
      clipBehavior: Clip.antiAlias,
      child: AppNoticeBanner(
        title: presented.title,
        body: presented.body,
        onDismiss: onDismiss,
        margin: EdgeInsets.zero,
      ),
    );
  }
}
