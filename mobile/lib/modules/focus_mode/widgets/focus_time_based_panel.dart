import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';

/// Big editable panel for the current time-based set: stopwatch with
/// START/STOP, with a fallback numeric field + ±5 bumps so users can also
/// log durations they timed themselves.
///
/// When [weightKg] is non-null the exercise carries weight (e.g. weighted
/// deadhang); a secondary kg row appears below the duration controls. When
/// it is null the panel shows an "+ Add weight" affordance instead, keeping
/// the unweighted case visually minimal.
class FocusTimeBasedPanel extends StatefulWidget {
  const FocusTimeBasedPanel({
    super.key,
    required this.durationSeconds,
    required this.weightKg,
    required this.stopwatch,
    required this.onDurationBump,
    required this.onDurationCommitted,
    required this.onWeightBump,
    required this.onWeightCommitted,
    required this.onWeightCleared,
    required this.onStopwatchStart,
    required this.onStopwatchStop,
    required this.enabled,
  });

  final int durationSeconds;
  final double? weightKg;
  final StopwatchViewModel stopwatch;
  final void Function(int delta) onDurationBump;
  final void Function(int seconds) onDurationCommitted;
  final void Function(double delta) onWeightBump;
  final void Function(double weightKg) onWeightCommitted;
  final VoidCallback onWeightCleared;
  final VoidCallback onStopwatchStart;
  final VoidCallback onStopwatchStop;
  final bool enabled;

  @override
  State<FocusTimeBasedPanel> createState() => _FocusTimeBasedPanelState();
}

class _FocusTimeBasedPanelState extends State<FocusTimeBasedPanel> {
  late final TextEditingController _seconds;
  late final TextEditingController _weight;
  final FocusNode _secondsFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _seconds = TextEditingController(text: widget.durationSeconds.toString());
    _weight = TextEditingController(
      text: widget.weightKg == null
          ? ''
          : WeightFormatter.formatKg(widget.weightKg!),
    );
    _secondsFocus.addListener(_commitOnBlur);
    _weightFocus.addListener(_commitWeightOnBlur);
  }

  @override
  void didUpdateWidget(covariant FocusTimeBasedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_secondsFocus.hasFocus &&
        widget.durationSeconds != oldWidget.durationSeconds) {
      _seconds.text = widget.durationSeconds.toString();
    }
    if (!_weightFocus.hasFocus && widget.weightKg != oldWidget.weightKg) {
      _weight.text = widget.weightKg == null
          ? ''
          : WeightFormatter.formatKg(widget.weightKg!);
    }
  }

  @override
  void dispose() {
    _secondsFocus.removeListener(_commitOnBlur);
    _weightFocus.removeListener(_commitWeightOnBlur);
    _seconds.dispose();
    _weight.dispose();
    _secondsFocus.dispose();
    _weightFocus.dispose();
    super.dispose();
  }

  void _commitOnBlur() {
    if (_secondsFocus.hasFocus) return;
    final parsed = int.tryParse(_seconds.text.trim());
    if (parsed == null) {
      _seconds.text = widget.durationSeconds.toString();
      return;
    }
    widget.onDurationCommitted(parsed);
  }

  void _commitWeightOnBlur() {
    if (_weightFocus.hasFocus) return;
    final raw = _weight.text.trim();
    if (raw.isEmpty) {
      widget.onWeightCleared();
      return;
    }
    final parsed = double.tryParse(raw);
    if (parsed == null) {
      _weight.text = widget.weightKg == null
          ? ''
          : WeightFormatter.formatKg(widget.weightKg!);
      return;
    }
    widget.onWeightCommitted(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isRunning = widget.stopwatch.isRunning;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: Text(
            _formatMmss(
              isRunning
                  ? widget.stopwatch.elapsedSeconds
                  : widget.durationSeconds,
            ),
            style: typography.numericHero.copyWith(
              color: isRunning ? colors.primary : colors.onSurface,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            'seconds',
            style: typography.caption.copyWith(color: colors.onSurfaceMuted),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SizedBox(
          height: AppSpacing.touchMin,
          child: isRunning
              ? FilledButton.icon(
                  onPressed: widget.enabled ? widget.onStopwatchStop : null,
                  icon: const AppIcon(Icons.stop, size: AppIconSize.md),
                  label: const Text('STOP'),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.error,
                    foregroundColor: colors.onError,
                  ),
                )
              : FilledButton.icon(
                  onPressed: widget.enabled ? widget.onStopwatchStart : null,
                  icon: const AppIcon(Icons.play_arrow, size: AppIconSize.md),
                  label: const Text('START TIMER'),
                ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: AppInSessionSize.stepButton,
                child: OutlinedButton(
                  onPressed: widget.enabled && !isRunning
                      ? () => widget.onDurationBump(-5)
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurfaceMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    textStyle: AppTypography.standard.actionLabel,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('-5', maxLines: 1),
                  ),
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              flex: 2,
              child: TextField(
                controller: _seconds,
                focusNode: _secondsFocus,
                enabled: widget.enabled && !isRunning,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onSubmitted: (text) {
                  final parsed = int.tryParse(text.trim());
                  if (parsed != null) widget.onDurationCommitted(parsed);
                },
                style: typography.numeric.copyWith(color: colors.onSurface),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: AppInSessionSize.stepButton,
                child: OutlinedButton(
                  onPressed: widget.enabled && !isRunning
                      ? () => widget.onDurationBump(5)
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    textStyle: AppTypography.standard.actionLabel,
                  ),
                  child: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text('+5', maxLines: 1),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (widget.weightKg != null) ...[
          const SizedBox(height: AppSpacing.md),
          const Divider(),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Text(
                'Added weight',
                style: typography.caption.copyWith(
                  color: colors.onSurfaceMuted,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: widget.enabled ? widget.onWeightCleared : null,
                icon: const AppIcon(Icons.close, size: AppIconSize.sm),
                label: const Text('Remove'),
                style: TextButton.styleFrom(
                  foregroundColor: colors.onSurfaceMuted,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                  ),
                  minimumSize: const Size(0, AppSpacing.compactAction),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppInSessionSize.stepButton,
                  child: OutlinedButton(
                    onPressed: widget.enabled
                        ? () => widget.onWeightBump(-2.5)
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurfaceMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      textStyle: AppTypography.standard.actionLabel,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('-2.5', maxLines: 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _weight,
                  focusNode: _weightFocus,
                  enabled: widget.enabled,
                  textAlign: TextAlign.center,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                  ],
                  onSubmitted: (text) {
                    final raw = text.trim();
                    if (raw.isEmpty) {
                      widget.onWeightCleared();
                      return;
                    }
                    final parsed = double.tryParse(raw);
                    if (parsed != null) widget.onWeightCommitted(parsed);
                  },
                  decoration: const InputDecoration(suffixText: 'kg'),
                  style: typography.numeric.copyWith(color: colors.onSurface),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: AppInSessionSize.stepButton,
                  child: OutlinedButton(
                    onPressed: widget.enabled
                        ? () => widget.onWeightBump(2.5)
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      textStyle: AppTypography.standard.actionLabel,
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text('+2.5', maxLines: 1),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ] else ...[
          const SizedBox(height: AppSpacing.sm),
          Align(
            alignment: Alignment.center,
            child: TextButton.icon(
              onPressed: widget.enabled
                  ? () => widget.onWeightCommitted(0)
                  : null,
              icon: const AppIcon(Icons.add, size: AppIconSize.sm),
              label: const Text('Add weight'),
            ),
          ),
        ],
      ],
    );
  }

  String _formatMmss(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}
