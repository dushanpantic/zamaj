import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/relative_date_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_state.dart';
import 'package:zamaj/modules/program_management/services/recent_history_row_presenter.dart';

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

/// The populated history: each session as one aligned row inside a single
/// bordered surface card, hairline-separated. Planned reads muted (the
/// prescription), actuals read bright (what was logged) — matching the
/// planned/actual emphasis used on the in-session and session-review rows.
class _RowsBody extends StatelessWidget {
  const _RowsBody({required this.entries});

  final List<CapHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline, width: AppStroke.hairline),
      ),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Column(
        children: [
          for (var i = 0; i < entries.length; i++) ...[
            if (i > 0)
              Divider(
                height: AppStroke.hairline,
                thickness: AppStroke.hairline,
                color: colors.outline,
              ),
            _HistoryRow(entry: entries[i], now: now),
          ],
        ],
      ),
    );
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({required this.entry, required this.now});

  final CapHistoryEntry entry;
  final DateTime now;

  /// Holds the longest common compact date label ("Yesterday") on one line so
  /// the planned column starts at the same x on every row.
  static const double _dateColumnWidth = AppSpacing.xxxl + AppSpacing.xl;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final local = entry.date.toLocal();
    final view = RecentHistoryRowPresenter.present(entry);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: _dateColumnWidth,
            child: Tooltip(
              message: RelativeDateFormatter.formatAbsolute(local),
              child: Text(
                RelativeDateFormatter.formatCompact(local, now),
                style: typography.labelSmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              view.plannedText,
              style: typography.numericSm.copyWith(color: colors.planned),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text(
              view.actualsText,
              // Bright when something was logged; muted for the "—" of a
              // session where this movement was skipped — matching the
              // absent-actual treatment on the session-review set row.
              style: typography.numericSm.copyWith(
                color: view.actualsAreMuted
                    ? colors.onSurfaceMuted
                    : colors.actual,
              ),
              textAlign: TextAlign.end,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          // Always reserve the marker slot so the actuals column ends at the
          // same x whether or not the session capped.
          SizedBox(
            width: AppIconSize.status,
            child: view.isCapped
                ? StatusBadge.icon(
                    icon: Icons.arrow_drop_up,
                    color: colors.exerciseCompleted,
                    label: view.capTooltip!,
                  )
                : null,
          ),
        ],
      ),
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
