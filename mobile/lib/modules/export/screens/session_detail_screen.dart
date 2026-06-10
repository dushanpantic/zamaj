import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/export/bloc/bloc.dart';
import 'package:zamaj/modules/export/widgets/export_preview_sheet.dart';
import 'package:zamaj/modules/export/widgets/session_detail_exercise_card.dart';
import 'package:zamaj/modules/export/widgets/set_value_editor_sheet.dart';

/// Review of a finished [Session]: the frozen snapshot's planned values
/// rendered beside what was actually logged, set by set, with skipped and
/// replaced exercises marked and supersets grouped, followed by the session's
/// notes and extra work.
///
/// Read-only by default; for an in-week session ([SessionDetailLoaded.canEdit])
/// logged set values can be corrected in place (wired in the exercise card).
/// Reactive via [SessionDetailBloc] so a correction re-renders without a manual
/// refresh. The app-bar share icon hosts the per-session text export.
class SessionDetailScreen extends StatefulWidget {
  const SessionDetailScreen({super.key});

  @override
  State<SessionDetailScreen> createState() => _SessionDetailScreenState();
}

class _SessionDetailScreenState extends State<SessionDetailScreen> {
  /// Per-process gate: the "tap a logged value to fix it" hint fires once per
  /// cold start on the first editable (in-week) detail opened, then never again
  /// until the app is killed. Persisting "once-ever" is deferred to the planned
  /// cross-screen coach-mark refactor (no `shared_preferences` yet).
  static bool _hintShownThisSession = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _maybeShowCorrectionHint();
  }

  void _maybeShowCorrectionHint() {
    if (_hintShownThisSession) return;
    final state = context.read<SessionDetailBloc>().state;
    if (state is! SessionDetailLoaded || !state.canEdit) return;
    _hintShownThisSession = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final colors = Theme.of(context).appColors;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          duration: const Duration(seconds: 6),
          backgroundColor: colors.surface,
          content: Text(
            'Tip: Tap a logged value to fix it.',
            style: AppTypography.standard.bodySmall.copyWith(
              color: colors.onSurface,
            ),
          ),
          action: SnackBarAction(
            label: 'Got it',
            textColor: colors.primary,
            onPressed: () {},
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return BlocBuilder<SessionDetailBloc, SessionDetailState>(
      builder: (context, state) {
        final SessionDetailLoaded(:session, :groups, :canEdit) =
            state as SessionDetailLoaded;
        final workoutDayName = session.snapshot.workoutDay.name;

        final SessionDetailEditSet? onEditSet = canEdit
            ? ({
                required executedSetId,
                required currentValues,
                required measurementType,
                required title,
              }) => _editSet(
                context,
                executedSetId: executedSetId,
                currentValues: currentValues,
                measurementType: measurementType,
                title: title,
              )
            : null;

        return Scaffold(
          backgroundColor: colors.background,
          appBar: AppBar(
            title: Text(workoutDayName),
            actions: [
              IconButton(
                tooltip: 'Share',
                icon: const Icon(Icons.share),
                onPressed: () => _showExport(context, session, workoutDayName),
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
                SessionDetailGroupCard(group: group, onEditSet: onEditSet),
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
      },
    );
  }

  /// Opens the value editor for one logged set, then dispatches the correction.
  /// The bloc routes it through `SessionFlowEngine.updateExecutedSet` and the
  /// `watchSession` stream re-renders the detail screen — no manual refresh.
  Future<void> _editSet(
    BuildContext context, {
    required String executedSetId,
    required ActualSetValues currentValues,
    required MeasurementType measurementType,
    required String title,
  }) async {
    final bloc = context.read<SessionDetailBloc>();
    final newValues = await SetValueEditorSheet.show(
      context,
      initialValues: currentValues,
      measurementType: measurementType,
      title: title,
    );
    if (newValues == null) return;
    bloc.add(
      SessionDetailSetValueEdited(
        executedSetId: executedSetId,
        actualValues: newValues,
      ),
    );
  }

  void _showExport(
    BuildContext context,
    Session session,
    String workoutDayName,
  ) {
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
