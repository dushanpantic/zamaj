import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/modules/domain/domain.dart';

class WorkoutDayPickerErrorView extends StatelessWidget {
  const WorkoutDayPickerErrorView({
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
