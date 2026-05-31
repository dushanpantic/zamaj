import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/bloc/link_suggestion/bloc.dart';
import 'package:zamaj/modules/exercise_library/models/link_suggestion_cluster.dart';
import 'package:zamaj/modules/exercise_library/widgets/measurement_type_chip.dart';
import 'package:zamaj/modules/program_management/services/domain_error_presenter.dart';

class LinkSuggestionScreen extends StatefulWidget {
  const LinkSuggestionScreen({super.key});

  @override
  State<LinkSuggestionScreen> createState() => _LinkSuggestionScreenState();
}

class _LinkSuggestionScreenState extends State<LinkSuggestionScreen> {
  @override
  void initState() {
    super.initState();
    context.read<LinkSuggestionBloc>().add(const LinkSuggestionRequested());
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(title: const Text('Suggest from your programs')),
      body: BlocBuilder<LinkSuggestionBloc, LinkSuggestionState>(
        builder: (context, state) {
          return switch (state) {
            LinkSuggestionInitial() ||
            LinkSuggestionLoading() => const AppListSkeleton(),
            LinkSuggestionFailure(:final error) => AppStateView(
              icon: Icons.error_outline,
              tone: AppStateTone.error,
              title: 'Could not scan programs',
              message: error.message,
              primaryAction: AppStateAction(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: () => context.read<LinkSuggestionBloc>().add(
                  const LinkSuggestionRetryRequested(),
                ),
              ),
            ),
            LinkSuggestionLoaded(
              :final visibleClusters,
              :final applyingNormalizedName,
              :final lastError,
            ) =>
              _LoadedView(
                clusters: visibleClusters,
                applyingNormalizedName: applyingNormalizedName,
                lastError: lastError,
              ),
          };
        },
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.clusters,
    required this.applyingNormalizedName,
    required this.lastError,
  });

  final List<LinkSuggestionCluster> clusters;
  final String? applyingNormalizedName;
  final DomainError? lastError;

  @override
  Widget build(BuildContext context) {
    if (clusters.isEmpty) {
      return AppStateView(
        icon: Icons.check_circle_outline,
        tone: AppStateTone.success,
        title: 'Nothing to suggest',
        message:
            'Every exercise across your programs is already linked or unique.',
        primaryAction: AppStateAction(
          label: 'Done',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }

    final presentedError = lastError == null
        ? null
        : DomainErrorPresenter.present(lastError!);

    return Column(
      children: [
        if (presentedError != null)
          AppNoticeBanner(
            title: presentedError.title,
            body: presentedError.body,
          ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg + MediaQuery.viewPaddingOf(context).bottom,
            ),
            itemCount: clusters.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final cluster = clusters[index];
              return _ClusterCard(
                cluster: cluster,
                isApplying: cluster.normalizedName == applyingNormalizedName,
                onAccept: () => context.read<LinkSuggestionBloc>().add(
                  LinkSuggestionClusterAccepted(
                    normalizedName: cluster.normalizedName,
                  ),
                ),
                onSkip: () => context.read<LinkSuggestionBloc>().add(
                  LinkSuggestionClusterSkipped(
                    normalizedName: cluster.normalizedName,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ClusterCard extends StatelessWidget {
  const _ClusterCard({
    required this.cluster,
    required this.isApplying,
    required this.onAccept,
    required this.onSkip,
  });

  final LinkSuggestionCluster cluster;
  final bool isApplying;
  final VoidCallback onAccept;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  cluster.suggestedName,
                  style: typography.titleSmall.copyWith(
                    color: colors.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              MeasurementTypeChip(measurementType: cluster.measurementType),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '${cluster.occurrenceCount} occurrence'
            '${cluster.occurrenceCount == 1 ? '' : 's'} across your programs',
            style: typography.caption.copyWith(color: colors.onSurfaceMuted),
          ),
          const SizedBox(height: AppSpacing.md),
          for (final occ in cluster.occurrences)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.xs),
              child: Row(
                children: [
                  AppIcon(
                    Icons.fitness_center_outlined,
                    size: AppIconSize.sm,
                    color: colors.onSurfaceMuted,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      '${occ.programName} · ${occ.workoutDayName}',
                      style: typography.bodySmall.copyWith(
                        color: colors.onSurfaceMuted,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: isApplying ? null : onSkip,
                  child: const Text('Skip'),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  onPressed: isApplying ? null : onAccept,
                  icon: isApplying
                      ? SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: colors.onPrimary,
                          ),
                        )
                      : const Icon(Icons.link),
                  label: const Text('Create & link all'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
