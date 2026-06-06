import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/widgets/export_preview_sheet.dart';
import 'package:zamaj/modules/export/widgets/session_detail_exercise_card.dart';
import 'package:zamaj/modules/workout_overview/workout_overview.dart';

/// Read-only review of a finished [Session]: the frozen snapshot's planned
/// values rendered beside what was actually logged, set by set, with skipped
/// and replaced exercises marked and supersets grouped, followed by the
/// session's notes and extra work.
///
/// Read-only by design (no mutations); reached from the recent-sessions list
/// with the already-hydrated session in hand, so it needs no bloc. The app-bar
/// share icon hosts the per-session text export that used to open from the list.
class SessionDetailScreen extends StatelessWidget {
  const SessionDetailScreen({super.key, required this.session});

  final Session session;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    final workoutDayName = session.snapshot.workoutDay.name;
    final groups = ExerciseViewModelAssembler.assembleReadOnly(session);

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: Text(workoutDayName),
        actions: [
          IconButton(
            tooltip: 'Share',
            icon: const Icon(Icons.ios_share),
            onPressed: () => _showExport(context, workoutDayName),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xxxl + MediaQuery.viewPaddingOf(context).bottom,
        ),
        children: [
          for (final group in groups) ...[
            SessionDetailGroupCard(group: group),
            const SizedBox(height: AppSpacing.sm),
          ],
          if (session.notes.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Notes'),
            const SizedBox(height: AppSpacing.sm),
            for (final note in session.notes)
              _BulletLine(text: note.body, colors: colors),
          ],
          if (session.extraWork.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.lg),
            const SectionHeader('Extra work'),
            const SizedBox(height: AppSpacing.sm),
            for (final entry in session.extraWork)
              _BulletLine(text: entry.body, colors: colors),
          ],
        ],
      ),
    );
  }

  void _showExport(BuildContext context, String workoutDayName) {
    ExportPreviewSheet.show(
      context,
      title: workoutDayName,
      buildText: (includeWarmups) => SessionExportFormatter.format(
        session,
        includeWarmups: includeWarmups,
      ),
      shareSubject: '$workoutDayName workout',
    );
  }
}

class _BulletLine extends StatelessWidget {
  const _BulletLine({required this.text, required this.colors});

  final String text;
  final AppColors colors;

  @override
  Widget build(BuildContext context) {
    final style = AppTypography.standard.bodySmall.copyWith(
      color: colors.onSurface,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Bullet(textStyle: style),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text, style: style)),
        ],
      ),
    );
  }
}
