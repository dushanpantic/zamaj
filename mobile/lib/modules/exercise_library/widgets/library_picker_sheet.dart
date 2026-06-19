import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_colors.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_opacity.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/widgets/measurement_type_chip.dart';

/// Result of [LibraryPickerSheet.show]. `null` means the user dismissed the
/// sheet without making a choice.
sealed class LibraryPickerResult {
  const LibraryPickerResult();
}

final class LibraryPickerSelected extends LibraryPickerResult {
  const LibraryPickerSelected(this.entry);

  final LibraryExercise entry;
}

/// Sentinel returned when the user explicitly opts out of using the library
/// for this slot — caller should fall back to the free-text editor.
final class LibraryPickerCreateOneOff extends LibraryPickerResult {
  const LibraryPickerCreateOneOff();
}

/// Sentinel returned when the user wants to create a brand-new library entry
/// from the calling exercise (shown only when `allowAddToLibrary` is true).
/// The picker has no exercise context of its own; the caller owns the
/// create-and-link logic.
final class LibraryPickerAddToLibrary extends LibraryPickerResult {
  const LibraryPickerAddToLibrary();
}

class LibraryPickerSheet extends StatefulWidget {
  const LibraryPickerSheet({
    super.key,
    required this.repository,
    this.measurementType,
    this.allowCreateOneOff = true,
    this.allowAddToLibrary = false,
    this.title = 'Pick from library',
    this.disabledEntryIds = const <String>{},
    this.disabledNote,
  });

  final ExerciseLibraryRepository repository;

  /// Library entry ids shown as disabled (non-tappable) rows rather than hidden
  /// — used by the add-exercise flow so a movement already in the session reads
  /// as "already here" instead of silently missing. [disabledNote] explains why.
  final Set<String> disabledEntryIds;
  final String? disabledNote;

  /// Lock the picker to this type. When non-null, the type chip is shown in
  /// the header and only matching entries are loaded.
  final MeasurementType? measurementType;

  /// When true, show a footer button that returns [LibraryPickerCreateOneOff].
  final bool allowCreateOneOff;

  /// When true, show a footer button that returns [LibraryPickerAddToLibrary] —
  /// used by the link flow so "no match? create a new entry" lives inside the
  /// picker rather than behind a separate menu.
  final bool allowAddToLibrary;

  final String title;

  static Future<LibraryPickerResult?> show(
    BuildContext context, {
    MeasurementType? measurementType,
    bool allowCreateOneOff = true,
    bool allowAddToLibrary = false,
    String title = 'Pick from library',
    Set<String> disabledEntryIds = const <String>{},
    String? disabledNote,
  }) {
    final repository = context.read<ExerciseLibraryRepository>();
    return showModalBottomSheet<LibraryPickerResult>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).appColors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => LibraryPickerSheet(
        repository: repository,
        measurementType: measurementType,
        allowCreateOneOff: allowCreateOneOff,
        allowAddToLibrary: allowAddToLibrary,
        title: title,
        disabledEntryIds: disabledEntryIds,
        disabledNote: disabledNote,
      ),
    );
  }

  @override
  State<LibraryPickerSheet> createState() => _LibraryPickerSheetState();
}

class _LibraryPickerSheetState extends State<LibraryPickerSheet> {
  final _searchController = TextEditingController();
  Timer? _debounce;
  String _query = '';
  bool _loading = true;
  List<LibraryExercise> _entries = const [];
  String? _loadError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    setState(() => _query = value);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 200), _load);
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final entries = await widget.repository.list(
        measurementType: widget.measurementType,
        nameQuery: _query.trim().isEmpty ? null : _query,
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _entries = entries;
        _loadError = null;
      });
    } on DomainError catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _loadError = e.message;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final mediaQuery = MediaQuery.of(context);
    final maxHeight = mediaQuery.size.height * 0.85;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: mediaQuery.viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.lg,
                  AppSpacing.sm,
                  AppSpacing.lg,
                  AppSpacing.sm,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.title,
                        style: typography.titleSmall.copyWith(
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                    if (widget.measurementType != null)
                      MeasurementTypeChip(
                        measurementType: widget.measurementType!,
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                child: TextField(
                  controller: _searchController,
                  autofocus: true,
                  textInputAction: TextInputAction.search,
                  style: typography.body.copyWith(color: colors.onSurface),
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.search),
                    hintText: 'Search library',
                  ),
                  onChanged: _onSearchChanged,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Flexible(child: _buildList(colors)),
              if (widget.allowAddToLibrary || widget.allowCreateOneOff)
                _buildFooter(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (widget.allowAddToLibrary)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const LibraryPickerAddToLibrary()),
                icon: const Icon(Icons.library_add_outlined),
                label: const Text('Add to library'),
              ),
            ),
          if (widget.allowAddToLibrary && widget.allowCreateOneOff)
            const SizedBox(height: AppSpacing.sm),
          if (widget.allowCreateOneOff)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.of(
                  context,
                ).pop(const LibraryPickerCreateOneOff()),
                icon: const Icon(Icons.add),
                label: const Text('Create one-off (no library)'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildList(AppColors colors) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(AppSpacing.xl),
        child: AppLoadingView(),
      );
    }
    if (_loadError != null) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          _loadError!,
          style: AppTypography.standard.body.copyWith(color: colors.error),
        ),
      );
    }
    if (_entries.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppIcon(
              Icons.search_off,
              color: colors.onSurfaceMuted,
              size: AppIconSize.emptyState,
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              _query.trim().isEmpty
                  ? 'Your library is empty.'
                  : 'No entries match "$_query".',
              style: AppTypography.standard.body.copyWith(
                color: colors.onSurfaceMuted,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
      itemCount: _entries.length,
      separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
      itemBuilder: (context, index) {
        final entry = _entries[index];
        final disabled = widget.disabledEntryIds.contains(entry.id);
        return _PickerRow(
          entry: entry,
          disabled: disabled,
          disabledNote: disabled ? widget.disabledNote : null,
          onTap: disabled
              ? null
              : () =>
                    Navigator.of(context).pop(LibraryPickerSelected(entry)),
        );
      },
    );
  }
}

class _PickerRow extends StatelessWidget {
  const _PickerRow({
    required this.entry,
    required this.onTap,
    this.disabled = false,
    this.disabledNote,
  });

  final LibraryExercise entry;
  final VoidCallback? onTap;
  final bool disabled;
  final String? disabledNote;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    // A disabled row reads "already in this session" — dimmed and inert, with
    // the explanatory note replacing the cue line.
    final subtitle = disabled ? disabledNote : entry.cues;
    final nameColor = disabled ? colors.onSurfaceMuted : colors.onSurface;

    return Opacity(
      opacity: disabled ? AppOpacity.muted : 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: colors.surfaceVariant,
            borderRadius: BorderRadius.circular(AppRadius.md),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      style: typography.label.copyWith(color: nameColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        subtitle,
                        style: typography.caption.copyWith(
                          color: colors.onSurfaceMuted,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              MeasurementTypeChip(measurementType: entry.measurementType),
            ],
          ),
        ),
      ),
    );
  }
}
