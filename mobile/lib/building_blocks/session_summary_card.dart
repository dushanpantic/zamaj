import 'package:flutter/material.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/duration_format.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// Headline read-out of a finished session's [SessionSummary]: time, working
/// sets done vs planned, and weighted volume.
///
/// Volume is omitted entirely when the session moved no weighted load (an
/// all-bodyweight day), so the card never shows a misleading `0 kg`. Read-only
/// display shared by the post-session overview banner and the history detail
/// header — one widget so both surfaces stay identical.
class SessionSummaryCard extends StatelessWidget {
  const SessionSummaryCard({super.key, required this.summary, this.footer});

  final SessionSummary summary;

  /// Optional muted line shown beneath the stats (e.g. the overview's
  /// "Completed sets remain editable."). Omitted when null.
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final footerText = footer;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: colors.exerciseCompleted.withValues(alpha: AppOpacity.tintFill),
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(
          color: colors.exerciseCompleted.withValues(
            alpha: AppOpacity.borderTint,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _Stat(label: 'Duration', value: formatElapsed(summary.duration)),
              _Stat(
                label: 'Sets',
                value:
                    '${summary.completedWorkingSets} of '
                    '${summary.plannedWorkingSets}',
              ),
              if (summary.hasWeightedVolume)
                _Stat(
                  label: 'Volume',
                  value:
                      '${WeightFormatter.formatKg(summary.weightedVolumeKg)}'
                      ' kg',
                ),
            ],
          ),
          if (footerText != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              footerText,
              style: AppTypography.standard.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// One labelled stat: a tabular-figure value over a muted caption. Expands to
/// share the row width evenly with its siblings.
class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: typography.numeric.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xxs),
          Text(
            label,
            style: typography.labelSmall.copyWith(color: colors.onSurfaceMuted),
          ),
        ],
      ),
    );
  }
}
