import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/workout_day_picker/models/day_history_summary.dart';

/// Quick "should I do this today?" chip on a day tile.
///
/// Computed purely from [DayHistorySummary.lastCompleted] vs [referenceNow]:
///
/// - never done → "New" (primary tint)
/// - 0 days ago → "Rested today" (muted; user just trained this day)
/// - 1–2 days ago → "Soon" (amber)
/// - 3+ days ago → "Ready" (green)
///
/// Returns [SizedBox.shrink] when an active session exists for this day —
/// the Resume affordance is the message; an additional badge would compete.
class DayRecommendationBadge extends StatelessWidget {
  const DayRecommendationBadge({
    super.key,
    required this.summary,
    required this.referenceNow,
  });

  final DayHistorySummary summary;
  final DateTime referenceNow;

  @override
  Widget build(BuildContext context) {
    if (summary.activeSessionId != null) return const SizedBox.shrink();
    final recommendation = _compute(summary.lastCompleted, referenceNow);
    if (recommendation == null) return const SizedBox.shrink();

    final colors = Theme.of(context).appColors;
    final tint = switch (recommendation.kind) {
      _RecommendationKind.fresh => colors.primary,
      _RecommendationKind.rested => colors.onSurfaceMuted,
      _RecommendationKind.soon => colors.warning,
      _RecommendationKind.ready => colors.exerciseCompleted,
    };

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: 2,
      ),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: tint.withValues(alpha: 0.5)),
      ),
      child: Text(
        recommendation.label,
        style: AppTypography.standard.badge.copyWith(color: tint),
      ),
    );
  }

  static _Recommendation? _compute(DateTime? lastCompleted, DateTime now) {
    if (lastCompleted == null) {
      return const _Recommendation(_RecommendationKind.fresh, 'New');
    }
    final daysSince = _wholeDaysBetween(lastCompleted, now);
    if (daysSince <= 0) {
      return const _Recommendation(_RecommendationKind.rested, 'Rested today');
    }
    if (daysSince <= 2) {
      return const _Recommendation(_RecommendationKind.soon, 'Soon');
    }
    return const _Recommendation(_RecommendationKind.ready, 'Ready');
  }

  static int _wholeDaysBetween(DateTime then, DateTime now) {
    final thenLocal = then.toLocal();
    final nowLocal = now.toLocal();
    final thenDate = DateTime(thenLocal.year, thenLocal.month, thenLocal.day);
    final nowDate = DateTime(nowLocal.year, nowLocal.month, nowLocal.day);
    return nowDate.difference(thenDate).inDays;
  }
}

enum _RecommendationKind { fresh, rested, soon, ready }

class _Recommendation {
  const _Recommendation(this.kind, this.label);
  final _RecommendationKind kind;
  final String label;
}
