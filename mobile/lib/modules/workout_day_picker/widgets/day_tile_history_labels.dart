import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';
import 'package:zamaj/modules/workout_day_picker/services/relative_date_formatter.dart';

class DayTileHistoryLabels extends StatelessWidget {
  const DayTileHistoryLabels({
    super.key,
    required this.summary,
    required this.referenceNow,
  });

  final DayHistorySummary summary;
  final DateTime referenceNow;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final lastCompleted = summary.lastCompleted;
    final weekCount = summary.thisWeekCount;

    final primary = _primaryLine(lastCompleted, weekCount);
    final secondary = _secondaryLine(lastCompleted, weekCount);
    final total = summary.totalCompletedCount > 0
        ? '${summary.totalCompletedCount} total'
        : null;

    final invariantViolation = lastCompleted == null && weekCount > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (invariantViolation)
          Text(
            'no_last_completed_with_nonzero_week_count',
            style: typography.bodySmall.copyWith(color: colors.error),
          )
        else ...[
          Text(
            primary,
            style: typography.bodySmall.copyWith(color: colors.onSurface),
          ),
          if (secondary != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              total == null ? secondary : '$secondary · $total',
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
          ] else if (total != null) ...[
            const SizedBox(height: AppSpacing.xs),
            Text(
              total,
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
          ],
        ],
      ],
    );
  }

  String _primaryLine(DateTime? lastCompleted, int weekCount) {
    if (lastCompleted == null) {
      return 'Not completed yet';
    }
    final relative = RelativeDateFormatter.format(lastCompleted, referenceNow);
    return 'Last completed: $relative';
  }

  String? _secondaryLine(DateTime? lastCompleted, int weekCount) {
    if (lastCompleted == null) {
      return null;
    }
    if (weekCount == 0) {
      return 'Not completed this week';
    }
    return '$weekCount× this week';
  }
}
