import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/bloc/exercise_library_list/bloc.dart';
import 'package:zamaj/modules/exercise_library/models/exercise_library_args.dart';
import 'package:zamaj/modules/exercise_library/navigation/exercise_library_routes.dart';
import 'package:zamaj/modules/exercise_library/widgets/library_entry_tile.dart';
import 'package:zamaj/modules/program_management/widgets/confirmation_dialog.dart';
import 'package:zamaj/modules/program_management/widgets/domain_error_banner.dart';

class ExerciseLibraryListScreen extends StatefulWidget {
  const ExerciseLibraryListScreen({super.key});

  @override
  State<ExerciseLibraryListScreen> createState() =>
      _ExerciseLibraryListScreenState();
}

class _ExerciseLibraryListScreenState extends State<ExerciseLibraryListScreen> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    context.read<ExerciseLibraryListBloc>().add(
      const ExerciseLibraryListRequested(),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), () {
      if (!mounted) return;
      context.read<ExerciseLibraryListBloc>().add(
        ExerciseLibraryListSearchChanged(query: value),
      );
    });
  }

  Future<void> _navigateToEditor({String? libraryExerciseId}) async {
    await Navigator.of(context).pushNamed(
      ExerciseLibraryRoutes.editor,
      arguments: ExerciseLibraryEditorArgs(
        libraryExerciseId: libraryExerciseId,
      ),
    );
    if (mounted) {
      context.read<ExerciseLibraryListBloc>().add(
        const ExerciseLibraryListRefreshed(),
      );
    }
  }

  Future<void> _navigateToSuggestions() async {
    await Navigator.of(
      context,
    ).pushNamed(ExerciseLibraryRoutes.linkSuggestions);
    if (mounted) {
      context.read<ExerciseLibraryListBloc>().add(
        const ExerciseLibraryListRefreshed(),
      );
    }
  }

  Future<void> _onArchiveRequested(LibraryExercise entry) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Archive entry',
      body:
          'Archive "${entry.name}"? It will stay linked to past data but stop '
          'appearing in the picker. You can restore it later.',
      confirmLabel: 'Archive',
    );
    if (confirmed != true || !mounted) return;
    context.read<ExerciseLibraryListBloc>().add(
      ExerciseLibraryListArchiveRequested(libraryExerciseId: entry.id),
    );
  }

  void _onUnarchiveRequested(LibraryExercise entry) {
    context.read<ExerciseLibraryListBloc>().add(
      ExerciseLibraryListUnarchiveRequested(libraryExerciseId: entry.id),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;

    return Scaffold(
      backgroundColor: colors.background,
      appBar: AppBar(
        title: const Text('Exercise library'),
        actions: [
          IconButton(
            onPressed: _navigateToSuggestions,
            icon: const Icon(Icons.auto_fix_high_outlined),
            tooltip: 'Suggest from your programs',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _navigateToEditor(),
        backgroundColor: colors.primary,
        foregroundColor: colors.onPrimary,
        icon: const Icon(Icons.add),
        label: const Text('New entry'),
      ),
      body: BlocBuilder<ExerciseLibraryListBloc, ExerciseLibraryListState>(
        builder: (context, state) {
          return switch (state) {
            ExerciseLibraryListInitial() ||
            ExerciseLibraryListLoading() => const _LoadingView(),
            ExerciseLibraryListFailure(:final error) => _FailureView(
              error: error,
              onRetry: () => context.read<ExerciseLibraryListBloc>().add(
                const ExerciseLibraryListRetryRequested(),
              ),
            ),
            ExerciseLibraryListLoaded(
              :final entries,
              :final searchQuery,
              :final includeArchived,
              :final lastError,
              :final mutatingId,
            ) =>
              _LoadedView(
                entries: entries,
                searchQuery: searchQuery,
                includeArchived: includeArchived,
                lastError: lastError,
                mutatingId: mutatingId,
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onToggleArchived: (next) =>
                    context.read<ExerciseLibraryListBloc>().add(
                      ExerciseLibraryListIncludeArchivedToggled(
                        includeArchived: next,
                      ),
                    ),
                onRefresh: () async {
                  context.read<ExerciseLibraryListBloc>().add(
                    const ExerciseLibraryListRefreshed(),
                  );
                },
                onEditEntry: (entry) =>
                    _navigateToEditor(libraryExerciseId: entry.id),
                onArchiveEntry: _onArchiveRequested,
                onUnarchiveEntry: _onUnarchiveRequested,
                onCreateEntry: () => _navigateToEditor(),
                onOpenSuggestions: _navigateToSuggestions,
              ),
          };
        },
      ),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return Center(child: CircularProgressIndicator(color: colors.primary));
  }
}

class _FailureView extends StatelessWidget {
  const _FailureView({required this.error, required this.onRetry});

  final DomainError error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline, color: colors.error, size: 48),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Could not load library',
              style: typography.titleSmall.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              error.message,
              style: typography.body.copyWith(color: colors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadedView extends StatelessWidget {
  const _LoadedView({
    required this.entries,
    required this.searchQuery,
    required this.includeArchived,
    required this.lastError,
    required this.mutatingId,
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleArchived,
    required this.onRefresh,
    required this.onEditEntry,
    required this.onArchiveEntry,
    required this.onUnarchiveEntry,
    required this.onCreateEntry,
    required this.onOpenSuggestions,
  });

  final List<LibraryExercise> entries;
  final String searchQuery;
  final bool includeArchived;
  final DomainError? lastError;
  final String? mutatingId;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<bool> onToggleArchived;
  final Future<void> Function() onRefresh;
  final void Function(LibraryExercise entry) onEditEntry;
  final void Function(LibraryExercise entry) onArchiveEntry;
  final void Function(LibraryExercise entry) onUnarchiveEntry;
  final VoidCallback onCreateEntry;
  final VoidCallback onOpenSuggestions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isFilterActive = searchQuery.trim().isNotEmpty || includeArchived;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.md,
            AppSpacing.lg,
            AppSpacing.sm,
          ),
          child: TextField(
            controller: searchController,
            textInputAction: TextInputAction.search,
            style: typography.body.copyWith(color: colors.onSurface),
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Search by name',
              suffixIcon: searchController.text.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Clear search',
                      onPressed: () {
                        searchController.clear();
                        onSearchChanged('');
                      },
                    ),
            ),
            onChanged: onSearchChanged,
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('Active'),
                selected: !includeArchived,
                onSelected: (_) => onToggleArchived(false),
              ),
              const SizedBox(width: AppSpacing.sm),
              ChoiceChip(
                label: const Text('Include archived'),
                selected: includeArchived,
                onSelected: (_) => onToggleArchived(true),
              ),
            ],
          ),
        ),
        if (lastError != null) DomainErrorBanner(error: lastError!),
        Expanded(
          child: entries.isEmpty
              ? _EmptyView(
                  isFiltered: isFilterActive,
                  onCreate: onCreateEntry,
                  onOpenSuggestions: onOpenSuggestions,
                )
              : RefreshIndicator(
                  onRefresh: onRefresh,
                  child: ListView.separated(
                    padding: const EdgeInsets.only(
                      left: AppSpacing.lg,
                      right: AppSpacing.lg,
                      top: AppSpacing.md,
                      bottom: AppSpacing.xxxl,
                    ),
                    itemCount: entries.length,
                    separatorBuilder: (_, _) =>
                        const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final entry = entries[index];
                      return LibraryEntryTile(
                        entry: entry,
                        onTap: () => onEditEntry(entry),
                        onArchive: () => onArchiveEntry(entry),
                        onUnarchive: () => onUnarchiveEntry(entry),
                        isMutating: entry.id == mutatingId,
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.isFiltered,
    required this.onCreate,
    required this.onOpenSuggestions,
  });

  final bool isFiltered;
  final VoidCallback onCreate;
  final VoidCallback onOpenSuggestions;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFiltered ? Icons.search_off : Icons.library_books_outlined,
              color: colors.onSurfaceMuted,
              size: 64,
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              isFiltered ? 'No entries match' : 'Your library is empty',
              style: typography.title.copyWith(color: colors.onSurface),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              isFiltered
                  ? 'Try a different search or toggle archived entries.'
                  : 'Each entry is a single movement (e.g. BB Bench Press) '
                        'that can be reused across programs.',
              style: typography.body.copyWith(color: colors.onSurfaceMuted),
              textAlign: TextAlign.center,
            ),
            if (!isFiltered) ...[
              const SizedBox(height: AppSpacing.xxl),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: onCreate,
                  icon: const Icon(Icons.add),
                  label: const Text('Create entry'),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onOpenSuggestions,
                  icon: const Icon(Icons.auto_fix_high_outlined),
                  label: const Text('Suggest from your programs'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
