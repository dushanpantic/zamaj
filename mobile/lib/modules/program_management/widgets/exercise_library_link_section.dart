import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/widgets/library_picker_sheet.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/exercise_editor/exercise_editor_event.dart';
import 'package:zamaj/modules/program_management/models/program_editor_draft.dart';
import 'package:zamaj/modules/program_management/widgets/library_link_chip.dart';

class ExerciseLibraryLinkSection extends StatelessWidget {
  const ExerciseLibraryLinkSection({
    super.key,
    required this.draft,
    required this.bloc,
  });

  final ExerciseDraft draft;
  final ExerciseEditorBloc bloc;

  Future<void> _openActions(BuildContext context) async {
    if (draft.libraryExerciseId == null) {
      await _showUnlinkedActions(context);
    } else {
      await _showLinkedActions(context);
    }
  }

  Future<void> _showUnlinkedActions(BuildContext context) async {
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
              leading: const Icon(Icons.library_add_outlined),
              title: const Text('Add to library'),
              subtitle: const Text('Create a library entry from this exercise'),
              onTap: () =>
                  Navigator.of(context).pop(_LibraryAction.addToLibrary),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text('Link to existing…'),
              subtitle: const Text('Pick from your library'),
              onTap: () =>
                  Navigator.of(context).pop(_LibraryAction.linkExisting),
            ),
          ],
        ),
      ),
    );
    if (!context.mounted || action == null) return;
    switch (action) {
      case _LibraryAction.addToLibrary:
        await _addToLibrary(context);
      case _LibraryAction.linkExisting:
        await _linkExisting(context);
      case _LibraryAction.unlink:
        break;
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
        bloc.add(const ExerciseLibraryUnlinked());
      case _LibraryAction.addToLibrary:
        break;
    }
  }

  Future<void> _addToLibrary(BuildContext context) async {
    final repo = context.read<ExerciseLibraryRepository>();
    final name = draft.name.trim();
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
            measurementType: draft.measurementType,
            videoUrl: draft.metadata.videoUrl,
          );
        }
      } else {
        entry = await repo.create(
          name: name,
          measurementType: draft.measurementType,
          videoUrl: draft.metadata.videoUrl,
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
    bloc.add(
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
      measurementType: draft.measurementType,
      allowCreateOneOff: false,
      title: 'Link to library entry',
    );
    if (!context.mounted || result is! LibraryPickerSelected) return;
    final overwrite = await _askOverwriteRow(context);
    if (!context.mounted || overwrite == null) return;
    bloc.add(
      ExerciseLibraryLinked(
        libraryExerciseId: result.entry.id,
        libraryName: result.entry.name,
        libraryVideoUrl: result.entry.videoUrl,
        overwriteNameAndVideo: overwrite,
      ),
    );
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
        linkedName: draft.libraryExerciseId == null ? null : draft.name,
        onTap: () => _openActions(context),
      ),
    );
  }
}

enum _LibraryAction { addToLibrary, linkExisting, unlink }
