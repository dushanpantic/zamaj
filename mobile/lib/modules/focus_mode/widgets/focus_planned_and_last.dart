import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/rep_target_formatter.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/focus_mode/models/focus_mode_view_model.dart';

class FocusPlannedAndLast extends StatelessWidget {
  const FocusPlannedAndLast({super.key, required this.panel});

  final FocusModeViewModel panel;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final plannedLabel = focusFormatPlanned(
      panel.currentPlannedValues,
      panel.plannedSummary,
    );
    final lastLabel = focusFormatLast(panel.lastExecutedValues);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Text(
              'Planned',
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                plannedLabel,
                style: typography.numeric.copyWith(color: colors.planned),
              ),
            ),
          ],
        ),
        if (lastLabel != null) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                'Last',
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  lastLabel,
                  style: typography.numeric.copyWith(color: colors.actual),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

String focusFormatPlanned(PlannedSetValues? values, String summary) {
  if (values == null) return summary;
  return switch (values) {
    PlannedRepBased(:final weightKg, :final repTarget) =>
      '${WeightFormatter.formatKg(weightKg)}kg × ${RepTargetFormatter.format(repTarget)}',
    PlannedTimeBased(:final durationSeconds, :final weightKg) =>
      weightKg == null
          ? '${durationSeconds}s'
          : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
    PlannedBodyweight(:final repTarget) =>
      '× ${RepTargetFormatter.format(repTarget)}',
  };
}

String? focusFormatLast(ActualSetValues? values) {
  if (values == null) return null;
  return switch (values) {
    ActualRepBased(:final weightKg, :final reps) =>
      '${WeightFormatter.formatKg(weightKg)}kg × $reps',
    ActualTimeBased(:final durationSeconds, :final weightKg) =>
      weightKg == null
          ? '${durationSeconds}s'
          : '${WeightFormatter.formatKg(weightKg)}kg × ${durationSeconds}s',
    ActualBodyweight(:final reps) => '× $reps',
  };
}
