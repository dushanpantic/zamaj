import 'package:flutter/material.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/exercise_library/widgets/library_picker_sheet.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_bloc.dart';
import 'package:zamaj/modules/program_management/bloc/workout_day_editor/workout_day_editor_event.dart';

Future<void> startAddExercise(
  BuildContext context,
  WorkoutDayEditorBloc bloc,
) async {
  final result = await LibraryPickerSheet.show(context);
  if (!context.mounted) return;
  switch (result) {
    case LibraryPickerSelected(:final entry):
      bloc.add(LibraryExerciseAddedAsNew(entry: entry));
    case LibraryPickerCreateOneOff():
      await showDialog<void>(
        context: context,
        builder: (_) => _AddExerciseDialog(bloc: bloc),
      );
    case null:
      return;
  }
}

class _AddExerciseDialog extends StatefulWidget {
  const _AddExerciseDialog({required this.bloc});

  final WorkoutDayEditorBloc bloc;

  @override
  State<_AddExerciseDialog> createState() => _AddExerciseDialogState();
}

class _AddExerciseDialogState extends State<_AddExerciseDialog> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final trimmed = _nameController.text.trim();
    if (trimmed.isEmpty) return;
    widget.bloc.add(QuickExerciseAdded(exerciseName: trimmed));
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text('Add exercise', style: TextStyle(color: colors.onSurface)),
      content: TextField(
        controller: _nameController,
        autofocus: true,
        style: TextStyle(color: colors.onSurface),
        onChanged: (_) => setState(() {}),
        onSubmitted: (_) => _submit(),
        decoration: InputDecoration(
          labelText: 'Exercise name',
          labelStyle: TextStyle(color: colors.onSurfaceMuted),
          enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.outline),
          ),
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: colors.primary),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text('Cancel', style: TextStyle(color: colors.onSurfaceMuted)),
        ),
        FilledButton(
          onPressed: _nameController.text.trim().isEmpty ? null : _submit,
          style: FilledButton.styleFrom(
            backgroundColor: colors.primary,
            foregroundColor: colors.onPrimary,
          ),
          child: const Text('Add'),
        ),
      ],
    );
  }
}
