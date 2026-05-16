import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/domain/domain.dart';

/// Defaults extracted from the original planned exercise to seed the
/// replace-dialog's planned-values fields.
class ReplaceExerciseDefaults {
  const ReplaceExerciseDefaults({
    required this.plannedValues,
    required this.setCount,
  });

  final PlannedSetValues plannedValues;
  final int setCount;
}

/// Resolves the dialog's pre-fill defaults from the session snapshot. Looks
/// up the original planned exercise for [sessionExerciseId] and returns its
/// first planned set's values together with the planned set count. Returns
/// null when the exercise has no planned sets (defensive: the dialog has no
/// reasonable defaults to show).
ReplaceExerciseDefaults? resolveReplaceExerciseDefaults({
  required String sessionExerciseId,
  required Session session,
}) {
  final sessionExercise = session.sessionExercises.firstWhere(
    (e) => e.id == sessionExerciseId,
    orElse: () => throw NotFoundError(
      entityType: 'SessionExercise',
      id: sessionExerciseId,
    ),
  );
  for (final group in session.snapshot.workoutDay.exerciseGroups) {
    for (final ex in group.exercises) {
      if (ex.id != sessionExercise.plannedExerciseIdInSnapshot) continue;
      if (ex.sets.isEmpty) return null;
      final sorted = List<WorkoutSet>.of(ex.sets)
        ..sort((a, b) => a.position.compareTo(b.position));
      return ReplaceExerciseDefaults(
        plannedValues: sorted.first.plannedValues,
        setCount: sorted.length,
      );
    }
  }
  throw NotFoundError(
    entityType: 'Exercise',
    id: sessionExercise.plannedExerciseIdInSnapshot,
  );
}

class ReplaceExerciseResult {
  const ReplaceExerciseResult({
    required this.name,
    required this.measurementType,
    required this.plannedValues,
    required this.setCount,
    this.metadata,
  });

  final String name;
  final MeasurementType measurementType;
  final PlannedSetValues plannedValues;
  final int setCount;
  final ExerciseMetadata? metadata;
}

/// In-session substitution dialog. Asks for a substitute name, measurement
/// type, planned values, set count, and optional notes; the template stays
/// untouched.
class ReplaceExerciseDialog extends StatefulWidget {
  const ReplaceExerciseDialog({
    super.key,
    required this.plannedExerciseName,
    required this.defaultMeasurementType,
    required this.defaultPlannedValues,
    required this.defaultSetCount,
  });

  final String plannedExerciseName;
  final MeasurementType defaultMeasurementType;
  final PlannedSetValues defaultPlannedValues;
  final int defaultSetCount;

  static Future<ReplaceExerciseResult?> show({
    required BuildContext context,
    required String plannedExerciseName,
    required MeasurementType defaultMeasurementType,
    required PlannedSetValues defaultPlannedValues,
    required int defaultSetCount,
  }) {
    return showDialog<ReplaceExerciseResult>(
      context: context,
      builder: (_) => ReplaceExerciseDialog(
        plannedExerciseName: plannedExerciseName,
        defaultMeasurementType: defaultMeasurementType,
        defaultPlannedValues: defaultPlannedValues,
        defaultSetCount: defaultSetCount,
      ),
    );
  }

  @override
  State<ReplaceExerciseDialog> createState() => _ReplaceExerciseDialogState();
}

class _ReplaceExerciseDialogState extends State<ReplaceExerciseDialog> {
  late final TextEditingController _name;
  late final TextEditingController _notes;
  late final TextEditingController _weight;
  late final TextEditingController _reps;
  late final TextEditingController _duration;
  late final TextEditingController _sets;
  late MeasurementType _measurementType;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _notes = TextEditingController();
    _weight = TextEditingController();
    _reps = TextEditingController();
    _duration = TextEditingController();
    _sets = TextEditingController(text: widget.defaultSetCount.toString());
    _measurementType = widget.defaultMeasurementType;
    _seedFieldsFor(widget.defaultPlannedValues);
  }

  @override
  void dispose() {
    _name.dispose();
    _notes.dispose();
    _weight.dispose();
    _reps.dispose();
    _duration.dispose();
    _sets.dispose();
    super.dispose();
  }

  void _seedFieldsFor(PlannedSetValues values) {
    switch (values) {
      case PlannedRepBased(:final weightKg, :final reps):
        _weight.text = WeightFormatter.formatKg(weightKg);
        _reps.text = reps.toString();
      case PlannedTimeBased(:final durationSeconds, :final weightKg):
        _duration.text = durationSeconds.toString();
        _weight.text = weightKg == null
            ? ''
            : WeightFormatter.formatKg(weightKg);
    }
  }

  PlannedSetValues? _parsePlannedValues() {
    switch (_measurementType) {
      case RepBasedMeasurement():
        final weight = double.tryParse(_weight.text.trim());
        final reps = int.tryParse(_reps.text.trim());
        if (weight == null || reps == null) return null;
        if (weight < 0 || reps < 0) return null;
        if ((weight * 2).roundToDouble() != weight * 2) return null;
        return PlannedSetValues.repBased(weightKg: weight, reps: reps);
      case TimeBasedMeasurement():
        final seconds = int.tryParse(_duration.text.trim());
        if (seconds == null || seconds < 0) return null;
        final weightRaw = _weight.text.trim();
        double? weightKg;
        if (weightRaw.isNotEmpty) {
          final parsed = double.tryParse(weightRaw);
          if (parsed == null) return null;
          if (parsed < 0) return null;
          if ((parsed * 2).roundToDouble() != parsed * 2) return null;
          weightKg = parsed;
        }
        return PlannedSetValues.timeBased(
          durationSeconds: seconds,
          weightKg: weightKg,
        );
    }
  }

  int? _parseSetCount() {
    final n = int.tryParse(_sets.text.trim());
    if (n == null || n < 1) return null;
    return n;
  }

  bool get _canSubmit {
    if (_name.text.trim().isEmpty) return false;
    if (_parsePlannedValues() == null) return false;
    if (_parseSetCount() == null) return false;
    return true;
  }

  void _submit() {
    if (!_canSubmit) return;
    final notes = _notes.text.trim();
    Navigator.of(context).pop(
      ReplaceExerciseResult(
        name: _name.text.trim(),
        measurementType: _measurementType,
        plannedValues: _parsePlannedValues()!,
        setCount: _parseSetCount()!,
        metadata: notes.isEmpty ? null : ExerciseMetadata(notes: notes),
      ),
    );
  }

  void _onMeasurementTypeChanged(MeasurementType next) {
    setState(() {
      _measurementType = next;
      switch (next) {
        case RepBasedMeasurement():
          _weight.text = '0';
          _reps.text = '0';
        case TimeBasedMeasurement():
          _duration.text = '0';
          // weight is optional on time-based; leave blank so the user can
          // opt-in (e.g. weighted deadhang) without being forced to type 0.
          _weight.text = '';
      }
    });
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
                _onMeasurementTypeChanged(
                  selection.first == 0
                      ? const MeasurementType.repBased()
                      : const MeasurementType.timeBased(),
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            _PlannedFields(
              measurementType: _measurementType,
              weightController: _weight,
              repsController: _reps,
              durationController: _duration,
              setsController: _sets,
              onChanged: () => setState(() {}),
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

class _PlannedFields extends StatelessWidget {
  const _PlannedFields({
    required this.measurementType,
    required this.weightController,
    required this.repsController,
    required this.durationController,
    required this.setsController,
    required this.onChanged,
  });

  final MeasurementType measurementType;
  final TextEditingController weightController;
  final TextEditingController repsController;
  final TextEditingController durationController;
  final TextEditingController setsController;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final numeric = AppTypography.standard.numeric;
    switch (measurementType) {
      case RepBasedMeasurement():
        return Row(
          children: [
            Expanded(
              child: TextField(
                controller: weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                ],
                style: numeric,
                decoration: const InputDecoration(labelText: 'Weight (kg)'),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: repsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: numeric,
                decoration: const InputDecoration(labelText: 'Reps'),
                onChanged: (_) => onChanged(),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: TextField(
                controller: setsController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: numeric,
                decoration: const InputDecoration(labelText: 'Sets'),
                onChanged: (_) => onChanged(),
              ),
            ),
          ],
        );
      case TimeBasedMeasurement():
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: durationController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: numeric,
                    decoration: const InputDecoration(
                      labelText: 'Duration (s)',
                    ),
                    onChanged: (_) => onChanged(),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: TextField(
                    controller: setsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    style: numeric,
                    decoration: const InputDecoration(labelText: 'Sets'),
                    onChanged: (_) => onChanged(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: weightController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              style: numeric,
              decoration: const InputDecoration(
                labelText: 'Added weight (kg)',
                hintText: 'optional · e.g. 10 for weighted deadhang',
              ),
              onChanged: (_) => onChanged(),
            ),
          ],
        );
    }
  }
}
