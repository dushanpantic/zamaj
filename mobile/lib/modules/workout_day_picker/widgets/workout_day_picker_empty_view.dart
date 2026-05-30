import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';

class WorkoutDayPickerEmptyView extends StatelessWidget {
  const WorkoutDayPickerEmptyView({
    super.key,
    required this.programName,
    required this.onEditProgram,
  });

  final String programName;
  final VoidCallback onEditProgram;

  @override
  Widget build(BuildContext context) {
    return AppStateView(
      icon: Icons.event_note_outlined,
      title: programName,
      message: 'This program has no workout days yet.',
      primaryAction: AppStateAction(
        label: 'Edit program',
        icon: Icons.edit_outlined,
        onPressed: onEditProgram,
      ),
    );
  }
}
