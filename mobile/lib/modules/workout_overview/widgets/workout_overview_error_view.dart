import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';

class WorkoutOverviewErrorView extends StatelessWidget {
  const WorkoutOverviewErrorView({
    super.key,
    required this.error,
    required this.onRetry,
  });

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

class WorkoutOverviewNotFoundView extends StatelessWidget {
  const WorkoutOverviewNotFoundView({super.key});

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
