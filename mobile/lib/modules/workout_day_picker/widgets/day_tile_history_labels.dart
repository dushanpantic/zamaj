import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/relative_date_formatter.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';

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
    assert(
      !(lastCompleted == null && summary.thisWeekCount > 0),
      'thisWeekCount > 0 implies a lastCompleted timestamp exists',
    );

    final label = lastCompleted == null
        ? 'Not done yet'
        : RelativeDateFormatter.format(lastCompleted, referenceNow);
    final tone = lastCompleted == null
        ? colors.onSurfaceMuted
        : colors.onSurface;

    return Text(label, style: typography.bodySmall.copyWith(color: tone));
  }
}
