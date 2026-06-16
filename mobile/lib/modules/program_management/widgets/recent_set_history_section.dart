import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/date_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';

/// The exercise editor's "Recent history" section: up to five recent ended
/// sessions of the movement, each showing the planned target, the per-set
/// actuals, and a `▲` marker when the session capped its prescription.
///
/// Strictly descriptive — it reports what happened against the plan and never
/// recommends an action. Renders an empty state when the linked movement has no
/// history yet, and a nudge when the exercise is not linked to a library entry.
class RecentSetHistorySection extends StatelessWidget {
  const RecentSetHistorySection({super.key, required this.view});

  final RecentHistoryView view;

  @override
  Widget build(BuildContext context) {
    final body = switch (view) {
      RecentHistoryUnlinked() => const _NudgeBody(),
      RecentHistoryAvailable(:final history) =>
        history.isEmpty
            ? const _EmptyBody()
            : _RowsBody(entries: history.entries),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Recent history'),
        const SizedBox(height: AppSpacing.sm),
        body,
      ],
    );
  }
}

class _NudgeBody extends StatelessWidget {
  const _NudgeBody();

  @override
  Widget build(BuildContext context) {
    return const _MutedText(
      'Recent history appears once this exercise is linked to a library entry.',
    );
  }
}

class _EmptyBody extends StatelessWidget {
  const _EmptyBody();

  @override
  Widget build(BuildContext context) {
    return const _MutedText('No history yet.');
  }
}

class _RowsBody extends StatelessWidget {
  const _RowsBody({required this.entries});

  final List<CapHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [for (final entry in entries) _HistoryRow(entry: entry)],
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry});

  final CapHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: AppSpacing.xxxl * 2,
            child: Text(
              DateFormatter.isoDate(entry.date.toLocal()),
              style: typography.bodySmall.copyWith(
                color: colors.onSurfaceMuted,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _plannedSummary(entry.plannedSets),
                  style: typography.body.copyWith(color: colors.onSurface),
                ),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  _actualsSummary(entry.actualSets),
                  style: typography.numeric.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
            ),
          ),
          if (entry.isCapped)
            Padding(
              padding: const EdgeInsets.only(left: AppSpacing.sm),
              child: _CapMarker(caption: _capCaption(entry.plannedSets)),
            ),
        ],
      ),
    );
  }
}

class _CapMarker extends StatelessWidget {
  const _CapMarker({required this.caption});

  final String caption;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.arrow_drop_up,
          size: AppSpacing.lg,
          color: colors.exerciseCompleted,
        ),
        Text(
          caption,
          style: typography.bodySmall.copyWith(color: colors.exerciseCompleted),
        ),
      ],
    );
  }
}

class _MutedText extends StatelessWidget {
  const _MutedText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Text(
      text,
      style: AppTypography.standard.bodySmall.copyWith(
        color: colors.onSurfaceMuted,
      ),
    );
  }
}

/// The planned weight + target for the session, read off its first planned set.
/// Reuses the in-app planned formatter so the readout matches the set rows.
String _plannedSummary(List<PlannedSetValues> planned) {
  if (planned.isEmpty) return '—';
  final first = planned.first;
  return SetValueFormatter.formatPlanned(first, _measurementTypeOf(first));
}

/// The per-set reps / holds, joined — e.g. `12 · 12 · 11` or `45s · 50s`.
String _actualsSummary(List<ActualSetValues> actuals) {
  if (actuals.isEmpty) return '—';
  return actuals
      .map(
        (a) => switch (a) {
          ActualRepBased(:final reps) => '$reps',
          ActualBodyweight(:final reps) => '$reps',
          ActualTimeBased(:final durationSeconds) => '${durationSeconds}s',
        },
      )
      .join(' · ');
}

/// Descriptive caption for the cap marker, by target kind.
String _capCaption(List<PlannedSetValues> planned) {
  final first = planned.isEmpty ? null : planned.first;
  return switch (first) {
    PlannedRepBased(:final repTarget) || PlannedBodyweight(:final repTarget) =>
      repTarget is RepTargetRange ? 'top of range' : 'hit target',
    PlannedTimeBased() => 'hit time',
    null => 'capped',
  };
}

MeasurementType _measurementTypeOf(PlannedSetValues planned) =>
    switch (planned) {
      PlannedRepBased() => const MeasurementType.repBased(),
      PlannedTimeBased() => const MeasurementType.timeBased(),
      PlannedBodyweight() => const MeasurementType.bodyweight(),
    };
