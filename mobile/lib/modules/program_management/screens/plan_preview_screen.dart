import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/program_management/bloc/plan_preview/plan_preview_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/plan_preview/plan_preview_event.dart';
import 'package:zamaj/modules/program_management/bloc/plan_preview/plan_preview_state.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/navigation/program_management_routes.dart';
import 'package:zamaj/modules/program_management/services/text_plan/plan_parse_warning.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';

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

  Widget _buildScaffold(BuildContext context, PlanPreviewState state) {
    return switch (state) {
      PlanPreviewInitial() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      PlanPreviewPreviewing(
        :final draft,
        :final warnings,
        :final lastSaveError,
      ) =>
        Scaffold(
          appBar: _buildAppBar(context, enabled: true),
          body: Column(
            children: [
              if (lastSaveError != null)
                DomainErrorBanner(error: lastSaveError),
              Expanded(child: _buildPreviewBody(context, draft, warnings)),
            ],
          ),
        ),
      PlanPreviewSaving(:final draft, :final warnings) => Scaffold(
        appBar: _buildAppBar(context, enabled: false),
        body: Stack(
          children: [
            _buildPreviewBody(context, draft, warnings),
            const Positioned.fill(
              child: ColoredBox(
                color: Colors.black38,
                child: Center(child: CircularProgressIndicator()),
              ),
            ),
          ],
        ),
      ),
      PlanPreviewSaved() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      PlanPreviewDiscarded() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
    };
  }

  PreferredSizeWidget _buildAppBar(
    BuildContext context, {
    required bool enabled,
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
                  : colors.onSurfaceMuted.withValues(alpha: 0.4),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: FilledButton(
            onPressed: enabled
                ? () => context.read<PlanPreviewBloc>().add(
                    const PlanPreviewSavePressed(),
                  )
                : null,
            child: const Text('Save'),
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
      padding: const EdgeInsets.all(AppSpacing.lg),
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
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: colors.outline),
          ),
          child: Text(
            day.name,
            style: typography.titleSmall.copyWith(color: colors.onSurface),
          ),
        ),
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

    final kindLabel = group.kind() == const ExerciseGroupKind.single()
        ? 'Single'
        : 'Superset';

    return Container(
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              kindLabel,
              style: typography.caption.copyWith(color: colors.onSurfaceMuted),
            ),
          ),
          const Divider(height: 1),
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
          if (warnings.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.xs),
            for (final warning in warnings) _WarningBadge(warning: warning),
          ],
        ],
      ),
    );
  }
}

class _WarningBadge extends StatelessWidget {
  const _WarningBadge({required this.warning});

  final PlanParseWarning warning;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    final message = _warningMessage(warning);

    return Container(
      margin: const EdgeInsets.only(top: AppSpacing.xs),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: colors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: colors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.warning_amber_rounded, color: colors.warning, size: 14),
          const SizedBox(width: AppSpacing.xs),
          Flexible(
            child: Text(
              message,
              style: typography.caption.copyWith(color: colors.warning),
            ),
          ),
        ],
      ),
    );
  }

  String _warningMessage(PlanParseWarning warning) {
    return switch (warning.code) {
      PlanParseWarningCode.invalidRestToken =>
        'Invalid rest value: "${warning.offendingToken}"',
      PlanParseWarningCode.unrecognizedTrailingToken =>
        'Unrecognized token: "${warning.offendingToken}"',
    };
  }
}
