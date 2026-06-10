import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/plan_preview/plan_preview_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/plan_preview/plan_preview_event.dart';
import 'package:zamaj/modules/program_management/bloc/plan_preview/plan_preview_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';

class PlanPreviewScreen extends StatefulWidget {
  const PlanPreviewScreen({super.key, required this.args});

  final PlanPreviewArgs args;

  @override
  State<PlanPreviewScreen> createState() => _PlanPreviewScreenState();
}

class _PlanPreviewScreenState extends State<PlanPreviewScreen> {
  @override
  void initState() {
    super.initState();
    context.read<PlanPreviewBloc>().add(
      PlanPreviewOpened(
        planDraft: widget.args.draft,
        warnings: widget.args.warnings,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PlanPreviewBloc, PlanPreviewState>(
      listener: _onStateChange,
      builder: (context, state) => _buildScaffold(context, state),
    );
  }

  void _onStateChange(BuildContext context, PlanPreviewState state) {
    if (state is PlanPreviewSaved) {
      Navigator.of(context).pushNamedAndRemoveUntil(
        ProgramManagementRoutes.programList,
        (route) => false,
      );
    }
    if (state is PlanPreviewDiscarded) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _handlePop(BuildContext context, bool didPop) async {
    if (didPop) return;
    final confirmed = await AppConfirmDialog.show(
      context: context,
      title: 'Discard preview?',
      body: 'The imported plan won\'t be saved.',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep preview',
      isDestructive: true,
    );
    if (!context.mounted || confirmed != true) return;
    Navigator.of(context).pop();
  }

  Widget _buildScaffold(BuildContext context, PlanPreviewState state) {
    return switch (state) {
      PlanPreviewInitial() => const Scaffold(body: AppLoadingView()),
      PlanPreviewPreviewing(
        :final draft,
        :final warnings,
        :final lastSaveError,
      ) =>
        PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, _) => _handlePop(context, didPop),
          child: Scaffold(
            appBar: _buildAppBar(context, enabled: true),
            body: Column(
              children: [
                if (lastSaveError != null)
                  AppNoticeBanner(
                    title: DomainErrorPresenter.present(lastSaveError).title,
                    body: DomainErrorPresenter.present(lastSaveError).body,
                  ),
                Expanded(child: _buildPreviewBody(context, draft, warnings)),
              ],
            ),
          ),
        ),
      PlanPreviewSaving(:final draft, :final warnings) => Scaffold(
        appBar: _buildAppBar(context, enabled: false, saving: true),
        body: _buildPreviewBody(context, draft, warnings),
      ),
      PlanPreviewSaved() => const Scaffold(body: AppLoadingView()),
      PlanPreviewDiscarded() => const Scaffold(body: AppLoadingView()),
    };
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool enabled,
    bool saving = false,
  }) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return AppBar(
      title: const Text('Preview'),
      actions: [
        TextButton(
          onPressed: enabled
              ? () => context.read<PlanPreviewBloc>().add(
                  const PlanPreviewDiscardPressed(),
                )
              : null,
          child: Text(
            'Discard',
            style: typography.label.copyWith(
              color: enabled
                  ? colors.onSurfaceMuted
                  : colors.onSurfaceMuted.withValues(alpha: AppOpacity.muted),
            ),
          ),
        ),
        if (saving)
          const Padding(
            padding: EdgeInsets.only(right: AppSpacing.sm),
            child: Center(child: AppInlineSpinner()),
          ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: TextButton(
            onPressed: enabled
                ? () => context.read<PlanPreviewBloc>().add(
                    const PlanPreviewSavePressed(),
                  )
                : null,
            child: Text(
              'Save',
              style: typography.label.copyWith(
                color: enabled ? colors.primary : colors.onSurfaceMuted,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPreviewBody(
    BuildContext context,
    ProgramDraft draft,
    List<PlanParseWarning> warnings,
  ) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final warningsByExerciseId = <String, List<PlanParseWarning>>{};
    for (final warning in warnings) {
      warningsByExerciseId
          .putIfAbsent(warning.exerciseDraftId, () => [])
          .add(warning);
    }

    return ListView(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
      ),
      children: [
        Text(
          draft.name,
          style: typography.title.copyWith(color: colors.onSurface),
        ),
        const SizedBox(height: AppSpacing.xl),
        for (final day in draft.workoutDays) ...[
          _WorkoutDaySection(
            day: day,
            warningsByExerciseId: warningsByExerciseId,
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ],
    );
  }
}

class _WorkoutDaySection extends StatelessWidget {
  const _WorkoutDaySection({
    required this.day,
    required this.warningsByExerciseId,
  });

  final WorkoutDayDraft day;
  final Map<String, List<PlanParseWarning>> warningsByExerciseId;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(day.name),
        const SizedBox(height: AppSpacing.md),
        for (final group in day.groups) ...[
          _ExerciseGroupSection(
            group: group,
            warningsByExerciseId: warningsByExerciseId,
          ),
          const SizedBox(height: AppSpacing.md),
        ],
      ],
    );
  }
}

class _ExerciseGroupSection extends StatelessWidget {
  const _ExerciseGroupSection({
    required this.group,
    required this.warningsByExerciseId,
  });

  final ExerciseGroupDraft group;
  final Map<String, List<PlanParseWarning>> warningsByExerciseId;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    // Only supersets carry a group label; a "Single" caption on every lone
    // exercise is zero-information chrome.
    final isSuperset = group.kind() != const ExerciseGroupKind.single();

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isSuperset) ...[
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              child: Text(
                'Superset',
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ),
            const Divider(height: 1),
          ],
          for (final exercise in group.exercises)
            _ExerciseRow(
              exercise: exercise,
              warnings: warningsByExerciseId[exercise.draftId] ?? const [],
            ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.exercise, required this.warnings});

  final ExerciseDraft exercise;
  final List<PlanParseWarning> warnings;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final measurementLabel = exercise.measurementType.when(
      repBased: () => 'Rep-based',
      timeBased: () => 'Time-based',
      bodyweight: () => 'Bodyweight',
    );

    final restLabel = exercise.plannedRestSeconds != null
        ? '${exercise.plannedRestSeconds}s rest'
        : null;

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            exercise.name,
            style: typography.label.copyWith(color: colors.onSurface),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Text(
                measurementLabel,
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
              if (restLabel != null) ...[
                Text(
                  ' · ',
                  style: typography.caption.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
                Text(
                  restLabel,
                  style: typography.caption.copyWith(
                    color: colors.onSurfaceMuted,
                  ),
                ),
              ],
              Text(
                ' · ${exercise.sets.length} set${exercise.sets.length == 1 ? '' : 's'}',
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ],
          ),
          if (warnings.isNotEmpty)
            for (final warning in warnings)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
                child: AppNoticeBanner(
                  tone: AppNoticeTone.warning,
                  title: _warningMessage(warning),
                  margin: EdgeInsets.zero,
                ),
              ),
        ],
      ),
    );
  }
}

String _warningMessage(PlanParseWarning warning) {
  return switch (warning.code) {
    PlanParseWarningCode.invalidRestToken =>
      'Invalid rest value: "${warning.offendingToken}"',
    PlanParseWarningCode.unrecognizedTrailingToken =>
      'Unrecognized token: "${warning.offendingToken}"',
  };
}
