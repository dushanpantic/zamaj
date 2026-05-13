import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/modules/domain/domain.dart';

class ReplaceExerciseResult {
  const ReplaceExerciseResult({
    required this.name,
    required this.measurementType,
    this.metadata,
  });

  final String name;
  final MeasurementType measurementType;
  final ExerciseMetadata? metadata;
}

/// In-session substitution dialog. Asks for a substitute name, measurement
/// type, and optional notes; the template stays untouched.
class ReplaceExerciseDialog extends StatefulWidget {
  const ReplaceExerciseDialog({
    super.key,
    required this.plannedExerciseName,
    required this.defaultMeasurementType,
  });

  final String plannedExerciseName;
  final MeasurementType defaultMeasurementType;

  static Future<ReplaceExerciseResult?> show({
    required BuildContext context,
    required String plannedExerciseName,
    required MeasurementType defaultMeasurementType,
  }) {
    return showDialog<ReplaceExerciseResult>(
      context: context,
      builder: (_) => ReplaceExerciseDialog(
        plannedExerciseName: plannedExerciseName,
        defaultMeasurementType: defaultMeasurementType,
      ),
    );
  }

  @override
  State<ReplaceExerciseDialog> createState() => _ReplaceExerciseDialogState();
}

class _ReplaceExerciseDialogState extends State<ReplaceExerciseDialog> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late MeasurementType _measurementType;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _notes = TextEditingController();
    _measurementType = widget.defaultMeasurementType;
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    super.dispose();
  }

  bool get _canSubmit => _name.text.trim().isNotEmpty;

  void _submit() {
    if (!_canSubmit) return;
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      ReplaceExerciseResult(
        name: _name.text.trim(),
        measurementType: _measurementType,
        metadata: notes.isEmpty ? null : ExerciseMetadata(notes: notes),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    return AlertDialog(
      backgroundColor: colors.surface,
      title: Text(
        'Replace ${widget.plannedExerciseName}',
        style: TextStyle(color: colors.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Substitute exercise name',
                hintText: 'e.g. Cable Fly',
              ),
              style: TextStyle(color: colors.onSurface),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Measurement',
              style: TextStyle(
                color: colors.onSurfaceMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 0, label: Text('Reps')),
                ButtonSegment(value: 1, label: Text('Time')),
              ],
              selected: {
                switch (_measurementType) {
                  RepBasedMeasurement() => 0,
                  TimeBasedMeasurement() => 1,
                },
              },
              onSelectionChanged: (selection) {
                setState(() {
                  _measurementType = selection.first == 0
                      ? const MeasurementType.repBased()
                      : const MeasurementType.timeBased();
                });
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'e.g. left shoulder pain',
              ),
              style: TextStyle(color: colors.onSurface),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _canSubmit ? _submit : null,
          child: const Text('Replace'),
        ),
      ],
    );
  }
}
