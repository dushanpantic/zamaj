import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/relative_date_formatter.dart';

class ProgramStatsHeader extends StatelessWidget {
  const ProgramStatsHeader({
    super.key,
    required this.dayCount,
    required this.exerciseCount,
    required this.lastEdited,
  });

  final int dayCount;
  final int exerciseCount;
  final DateTime? lastEdited;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final parts = <String>[
      '$dayCount ${dayCount == 1 ? 'day' : 'days'}',
      '$exerciseCount ${exerciseCount == 1 ? 'exercise' : 'exercises'}',
    ];
    if (lastEdited != null) {
      final relative = RelativeDateFormatter.format(
        lastEdited!,
        clock.now().toUtc(),
      );
      parts.add('edited $relative');
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colors.outline)),
      ),
      child: Text(
        parts.join(' · '),
        style: typography.caption.copyWith(color: colors.onSurfaceMuted),
      ),
    );
  }
}
