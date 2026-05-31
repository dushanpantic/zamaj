import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';

class TransientErrorBanner extends StatelessWidget {
  const TransientErrorBanner({
    super.key,
    required this.error,
    required this.onDismiss,
  });

  final DomainError error;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final presented = DomainErrorPresenter.present(error);
    return AppNoticeBanner(
      title: presented.title,
      body: presented.body,
      onDismiss: onDismiss,
    );
  }
}
