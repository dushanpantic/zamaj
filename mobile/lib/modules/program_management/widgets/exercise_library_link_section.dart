import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/exercise_library.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/widgets/library_link_chip.dart';

class ExerciseLibraryLinkSection extends StatefulWidget {
  const ExerciseLibraryLinkSection({
    super.key,
    required this.draft,
    required this.bloc,
  });

  final ExerciseDraft draft;
  final ExerciseEditorBloc bloc;

  @override
  State<ExerciseLibraryLinkSection> createState() =>
      _ExerciseLibraryLinkSectionState();
}

class _ExerciseLibraryLinkSectionState
    extends State<ExerciseLibraryLinkSection> {
  /// The linked library entry's name, or null when unlinked or while the lookup
  /// is in flight. Resolved from the repository rather than read off the draft:
  /// the draft's own name is the row's (local) name, which the user can keep
  /// distinct from the library entry's name when linking.
  String? _libraryName;

  /// The id [_libraryName] was resolved for. Guards against re-resolving on
  /// every rebuild and against a stale async result landing after the link
  /// changed again.
  String? _resolvedForId;

  @override
  void initState() {
    super.initState();
    _resolveLibraryName();
  }

  @override
  void didUpdateWidget(covariant ExerciseLibraryLinkSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.draft.libraryExerciseId != widget.draft.libraryExerciseId) {
      _resolveLibraryName();
    }
  }

  Future<void> _resolveLibraryName() async {
    final id = widget.draft.libraryExerciseId;
    _resolvedForId = id;
    if (id == null) {
      if (_libraryName != null) setState(() => _libraryName = null);
      return;
    }
    final repo = context.read<ExerciseLibraryRepository>();
    final entry = await repo.get(id);
    if (!mounted || _resolvedForId != id) return;
    setState(() => _libraryName = entry?.name);
  }

  Future<void> _openActions(BuildContext context) async {
    if (widget.draft.libraryExerciseId == null) {
      // First-time link: go straight to the picker. "Add to library" lives
      // inside it as a footer action, so the common "link to existing" path
      // costs one tap rather than two.
      await _linkExisting(context);
    } else {
      await _showLinkedActions(context);
    }
  }

  Future<void> _showLinkedActions(BuildContext context) async {
    final colors = Theme.of(context).appColors;
    final action = await showModalBottomSheet<_LibraryAction>(
      context: context,
      backgroundColor: colors.surfaceElevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.swap_horiz),
              title: const Text('Change link…'),
              onTap: () =>
                  Navigator.of(context).pop(_LibraryAction.linkExisting),
            ),
            ListTile(
              leading: const Icon(Icons.link_off),
              title: const Text('Unlink'),
              onTap: () => Navigator.of(context).pop(_LibraryAction.unlink),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _LibraryAction.linkExisting:
        await _linkExisting(context);
      case _LibraryAction.unlink:
        widget.bloc.add(const ExerciseLibraryUnlinked());
    }
  }

  Future<void> _addToLibrary(BuildContext context) async {
    final repo = context.read<ExerciseLibraryRepository>();
    final name = widget.draft.name.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Add a name before linking to the library.'),
        ),
      );
      return;
    }
    LibraryExercise? entry;
    try {
      final existing = await repo.findByNormalizedName(name);
      if (!context.mounted) return;
      if (existing != null) {
        final shouldLink = await _confirmExistingMatch(context, existing);
        if (!context.mounted) return;
        if (shouldLink == null) return;
        if (shouldLink) {
          entry = existing;
        } else {
          entry = await repo.create(
            name: name,
            measurementType: widget.draft.measurementType,
            videoUrl: widget.draft.metadata.videoUrl,
          );
        }
      } else {
        // Guard the one path that silently creates a brand-new global entry,
        // so a stray tap on "Add to library" can't pollute the catalog. The
        // existing-name branch above is already gated by _confirmExistingMatch.
        final confirmed = await AppConfirmDialog.show(
          context: context,
          title: 'Add to library?',
          body:
              'Creates a new library entry "$name", available to all your '
              'programs, and links this exercise to it.',
          confirmLabel: 'Add',
        );
        if (!context.mounted || confirmed != true) return;
        entry = await repo.create(
          name: name,
          measurementType: widget.draft.measurementType,
          videoUrl: widget.draft.metadata.videoUrl,
        );
      }
    } on DomainError catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Could not link: ${e.message}')));
      return;
    }
    if (!context.mounted) return;
    widget.bloc.add(
      ExerciseLibraryLinked(
        libraryExerciseId: entry.id,
        libraryName: entry.name,
        libraryVideoUrl: entry.videoUrl,
        overwriteNameAndVideo: false,
      ),
    );
  }

  Future<bool?> _confirmExistingMatch(
    BuildContext context,
    LibraryExercise existing,
  ) {
    final colors = Theme.of(context).appColors;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        title: const Text('Library entry already exists'),
        content: Text(
          'A library entry "${existing.name}" already exists. Link to that '
          'instead?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Create new anyway'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Link'),
          ),
        ],
      ),
    );
  }

  Future<void> _linkExisting(BuildContext context) async {
    final result = await LibraryPickerSheet.show(
      context,
      measurementType: widget.draft.measurementType,
      allowCreateOneOff: false,
      allowAddToLibrary: true,
      title: 'Link to library entry',
    );
    if (!context.mounted) return;
    switch (result) {
      case LibraryPickerSelected(:final entry):
        final overwrite = await _askOverwriteRow(context);
        if (!context.mounted || overwrite == null) return;
        widget.bloc.add(
          ExerciseLibraryLinked(
            libraryExerciseId: entry.id,
            libraryName: entry.name,
            libraryVideoUrl: entry.videoUrl,
            overwriteNameAndVideo: overwrite,
          ),
        );
      case LibraryPickerAddToLibrary():
        await _addToLibrary(context);
      case LibraryPickerCreateOneOff():
      case null:
        return;
    }
  }

  Future<bool?> _askOverwriteRow(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: colors.surfaceElevated,
        title: const Text('Update this row to match library?'),
        content: const Text(
          'Replace this row\'s name and video URL with the library entry\'s '
          'values. Notes are kept (they\'re day-specific).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Keep local'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Update row'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: LibraryLinkChip(
        isLinked: widget.draft.libraryExerciseId != null,
        linkedName: _libraryName,
        onTap: () => _openActions(context),
      ),
    );
  }
}

enum _LibraryAction { linkExisting, unlink }
