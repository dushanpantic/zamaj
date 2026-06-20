import 'package:flutter/material.dart';
import 'package:zamaj/building_blocks/building_blocks.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/domain/domain.dart';
import 'package:zamaj/modules/exercise_library/exercise_library.dart';
import 'package:zamaj/modules/workout_overview/services/add_exercise_plan_builder.dart';

/// Two-step add-exercise flow opened from the live overview:
///
/// 1. The shared [LibraryPickerSheet], pre-filtered so movements already in the
///    session (any state) show as disabled "already here" rows. The user picks
///    a library movement or chooses "create one-off".
/// 2. A focused plan-config sheet (set count + planned-value steppers, plus a
///    name and measurement-type selector for one-offs) with seeded defaults.
///
/// Resolves to the built [AddedExercisePlan] on confirm, or `null` if the user
/// backed out of either step (no exercise is added on dismiss). Backing out of
/// the config sheet returns to the picker; backing out of the picker closes the
/// flow.
abstract final class AddExerciseSheet {
  static Future<AddedExercisePlan?> show(
    BuildContext context, {
    required Session session,
    String? excludeSessionExerciseId,
    String? replacingName,
  }) async {
    final excludedIds = AddExercisePlanBuilder.excludedLibraryIds(
      session,
      excludeSessionExerciseId: excludeSessionExerciseId,
    );

    // Loop so backing out of the config sheet returns to the picker.
    while (true) {
      if (!context.mounted) return null;
      final picked = await LibraryPickerSheet.show(
        context,
        title: replacingName == null
            ? 'Add exercise'
            : 'Replacing: $replacingName',
        allowCreateOneOff: true,
        disabledEntryIds: excludedIds,
        disabledNote:
            'Already in this session — resume or add a set from '
            'its card',
      );

      if (picked == null) return null; // dismissed the picker → close flow.
      if (!context.mounted) return null;

      switch (picked) {
        case LibraryPickerSelected(:final entry):
          final config = await _PlanConfigSheet.show(
            context,
            lockedName: entry.name,
            measurementType: entry.measurementType,
          );
          if (config != null) {
            return AddExercisePlanBuilder.fromLibrary(
              entry: entry,
              plannedValues: config.plannedValues,
              setCount: config.setCount,
            );
          }
        case LibraryPickerCreateOneOff():
          final config = await _PlanConfigSheet.show(context);
          if (config != null && config.name != null) {
            return AddExercisePlanBuilder.oneOff(
              name: config.name!,
              measurementType: config.measurementType,
              plannedValues: config.plannedValues,
              setCount: config.setCount,
            );
          }
        case LibraryPickerAddToLibrary():
          return null; // not offered by this flow.
      }
      // Config was dismissed → loop back to the picker.
    }
  }
}

/// Result of the plan-config step.
class _PlanConfig {
  _PlanConfig({
    required this.measurementType,
    required this.plannedValues,
    required this.setCount,
    this.name,
  });

  final MeasurementType measurementType;
  final PlannedSetValues plannedValues;
  final int setCount;

  /// The entered name for a one-off; null when a library movement was chosen
  /// (its name is fixed).
  final String? name;
}

class _PlanConfigSheet extends StatefulWidget {
  const _PlanConfigSheet({this.lockedName, required this.measurementType});

  /// Non-null when configuring a library movement: the name is fixed and the
  /// measurement type is locked, so only the steppers show.
  final String? lockedName;
  final MeasurementType measurementType;

  static Future<_PlanConfig?> show(
    BuildContext context, {
    String? lockedName,
    MeasurementType measurementType = const MeasurementType.repBased(),
  }) {
    return showModalBottomSheet<_PlanConfig>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).appColors.surfaceElevated,
      builder: (_) => _PlanConfigSheet(
        lockedName: lockedName,
        measurementType: measurementType,
      ),
    );
  }

  @override
  State<_PlanConfigSheet> createState() => _PlanConfigSheetState();
}

class _PlanConfigSheetState extends State<_PlanConfigSheet> {
  late final TextEditingController _name;
  late MeasurementType _measurementType;

  // Seeded defaults — sensible non-zero starting points the user tunes.
  int _setCount = 3;
  double _weight = 20;
  int _reps = 8;
  int _duration = 30;

  bool get _isOneOff => widget.lockedName == null;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _measurementType = widget.measurementType;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  PlannedSetValues _buildPlannedValues() {
    return switch (_measurementType) {
      RepBasedMeasurement() => PlannedSetValues.repBased(
        weightKg: _weight,
        repTarget: RepTarget.fixed(reps: _reps),
      ),
      TimeBasedMeasurement() => PlannedSetValues.timeBased(
        durationSeconds: _duration,
        weightKg: _weight > 0 ? _weight : null,
      ),
      BodyweightMeasurement() => PlannedSetValues.bodyweight(
        repTarget: RepTarget.fixed(reps: _reps),
      ),
    };
  }

  bool get _canConfirm => !_isOneOff || _name.text.trim().isNotEmpty;

  void _confirm() {
    if (!_canConfirm) return;
    Navigator.of(context).pop(
      _PlanConfig(
        measurementType: _measurementType,
        plannedValues: _buildPlannedValues(),
        setCount: _setCount,
        name: _isOneOff ? _name.text.trim() : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.sm,
        AppSpacing.lg,
        AppSpacing.lg + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.lockedName ?? 'New exercise',
              style: typography.titleSmall.copyWith(color: colors.onSurface),
            ),
            const SizedBox(height: AppSpacing.lg),
            if (_isOneOff) ...[
              TextField(
                controller: _name,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                style: typography.body.copyWith(color: colors.onSurface),
                decoration: const InputDecoration(
                  labelText: 'Exercise name',
                  hintText: 'e.g. Sled Push',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: AppSpacing.md),
              _MeasurementTypeSelector(
                selected: _measurementType,
                onChanged: (mt) => setState(() => _measurementType = mt),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            _CounterRow(
              label: 'Sets',
              value: '$_setCount',
              onDecrement: _setCount > 1
                  ? () => setState(() => _setCount--)
                  : null,
              onIncrement: () => setState(() => _setCount++),
            ),
            const SizedBox(height: AppSpacing.md),
            ..._valueSteppers(),
            const SizedBox(height: AppSpacing.lg),
            PrimaryActionButton(
              label: 'ADD EXERCISE',
              onPressed: _confirm,
              enabled: _canConfirm,
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _valueSteppers() {
    return switch (_measurementType) {
      RepBasedMeasurement() => [
        _weightStepper(),
        const SizedBox(height: AppSpacing.md),
        _repsStepper(),
      ],
      TimeBasedMeasurement() => [
        _durationStepper(),
        const SizedBox(height: AppSpacing.md),
        _weightStepper(optional: true),
      ],
      BodyweightMeasurement() => [_repsStepper()],
    };
  }

  Widget _weightStepper({bool optional = false}) => _CounterRow(
    label: optional ? 'kg (optional)' : 'kg',
    value: _weight % 1 == 0
        ? _weight.toStringAsFixed(0)
        : _weight.toStringAsFixed(1),
    onDecrement: _weight > 0
        ? () => setState(() => _weight = (_weight - 2.5).clamp(0, 9999))
        : null,
    onIncrement: () => setState(() => _weight += 2.5),
  );

  Widget _repsStepper() => _CounterRow(
    label: 'reps',
    value: '$_reps',
    onDecrement: _reps > 1 ? () => setState(() => _reps--) : null,
    onIncrement: () => setState(() => _reps++),
  );

  Widget _durationStepper() => _CounterRow(
    label: 'seconds',
    value: '$_duration',
    onDecrement: _duration > 5 ? () => setState(() => _duration -= 5) : null,
    onIncrement: () => setState(() => _duration += 5),
  );
}

/// A `[−] value label [+]` row sized for in-session sweaty hands: 64 dp step
/// buttons flanking a large numeric readout.
class _CounterRow extends StatelessWidget {
  const _CounterRow({
    required this.label,
    required this.value,
    required this.onDecrement,
    required this.onIncrement,
  });

  final String label;
  final String value;
  final VoidCallback? onDecrement;
  final VoidCallback? onIncrement;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    return Row(
      children: [
        _StepButton(symbol: '−', onPressed: onDecrement),
        Expanded(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: typography.numericLarge.copyWith(
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                label,
                style: typography.labelSmall.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
            ],
          ),
        ),
        _StepButton(symbol: '+', onPressed: onIncrement),
      ],
    );
  }
}

/// Compact three-way measurement-type chooser for one-off exercises. Inlined
/// (rather than reusing the program-editor selector) to keep the live-session
/// module free of a dependency on the program-management module.
class _MeasurementTypeSelector extends StatelessWidget {
  const _MeasurementTypeSelector({
    required this.selected,
    required this.onChanged,
  });

  final MeasurementType selected;
  final void Function(MeasurementType) onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    Widget chip(String label, MeasurementType type, bool isSelected) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.only(right: AppSpacing.sm),
          child: ChoiceChip(
            label: Text(label),
            selected: isSelected,
            onSelected: (_) => onChanged(type),
            showCheckmark: false,
            selectedColor: colors.primary.withValues(alpha: 0.2),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          'Reps',
          const MeasurementType.repBased(),
          selected is RepBasedMeasurement,
        ),
        chip(
          'Time',
          const MeasurementType.timeBased(),
          selected is TimeBasedMeasurement,
        ),
        chip(
          'Bodyweight',
          const MeasurementType.bodyweight(),
          selected is BodyweightMeasurement,
        ),
      ],
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.symbol, required this.onPressed});

  static const double _size = AppInSessionSize.stepButton;

  final String symbol;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: _size,
      height: _size,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          padding: EdgeInsets.zero,
          minimumSize: const Size(_size, _size),
          textStyle: AppTypography.standard.actionLabel,
        ),
        child: Text(symbol),
      ),
    );
  }
}
