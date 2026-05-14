import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Tiny row of pips showing `completed / total` for the current exercise.
///
/// Filled pip = completed set. Hollow pip = pending. Highlighted pip = the
/// set we're about to log. Long set counts (>12) collapse to a "3 / 4"
/// numeric badge to avoid wrapping.
class FocusSetProgress extends StatelessWidget {
  const FocusSetProgress({
    super.key,
    required this.completed,
    required this.total,
    required this.currentIndex,
  });

  final int completed;
  final int total;
  final int currentIndex;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    if (total <= 0) {
      return Text(
        'Set ${currentIndex + 1}',
        style: typography.caption.copyWith(color: colors.onSurfaceMuted),
      );
    }
    if (total > 12) {
      return Text(
        'Set ${currentIndex + 1} of $total',
        style: typography.caption.copyWith(color: colors.onSurfaceMuted),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < total; i++) ...[
          _Pip(isCompleted: i < completed, isCurrent: i == currentIndex),
          if (i < total - 1) const SizedBox(width: AppSpacing.xs),
        ],
        const SizedBox(width: AppSpacing.sm),
        Text(
          '${currentIndex + 1} / $total',
          style: typography.caption.copyWith(color: colors.onSurfaceMuted),
        ),
      ],
    );
  }
}

class _Pip extends StatelessWidget {
  const _Pip({required this.isCompleted, required this.isCurrent});

  final bool isCompleted;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final color = isCompleted
        ? colors.exerciseCompleted
        : isCurrent
        ? colors.primary
        : colors.outline;
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: isCompleted || isCurrent ? color : Colors.transparent,
        border: isCompleted || isCurrent ? null : Border.all(color: color),
        shape: BoxShape.circle,
      ),
    );
  }
}
