import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_icon.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/core/increment_rules.dart';
import 'package:zamaj/core/weight_formatter.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';
import 'package:zamaj/modules/focus_mode/widgets/mmss_formatter.dart';

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

class _FocusTimeBasedPanelState extends State<FocusTimeBasedPanel>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _seconds;
  late final TextEditingController _weight;
  final FocusNode _secondsFocus = FocusNode();
  final FocusNode _weightFocus = FocusNode();

  /// Drives the blinking 00:00 while the countdown rests in its finished
  /// hold. One half-period per direction, reversed on repeat, so the hero
  /// pulses between full and dimmed.
  static const Duration _flashHalfPeriod = Duration(milliseconds: 450);
  late final AnimationController _flash;
  late final Animation<double> _flashOpacity;

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
    _flash = AnimationController(vsync: this, duration: _flashHalfPeriod);
    _flashOpacity = _flash.drive(Tween(begin: 1.0, end: 0.2));
    if (widget.stopwatch.isFinished) _flash.repeat(reverse: true);
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
    final wasFinished = oldWidget.stopwatch.isFinished;
    final nowFinished = widget.stopwatch.isFinished;
    if (nowFinished && !wasFinished) {
      _flash
        ..reset()
        ..repeat(reverse: true);
    } else if (!nowFinished && wasFinished) {
      _flash
        ..stop()
        ..value = 0;
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
    _flash.dispose();
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
    final isFinished = widget.stopwatch.isFinished;
    // "Engaged" covers the live countdown and the brief 00:00 finish flash;
    // both show the countdown reading rather than the idle target.
    final isCountingDown = isRunning || isFinished;
    // The hero counts down from the set duration; the input below stays put.
    final remainingSeconds =
        widget.durationSeconds - widget.stopwatch.elapsedSeconds;
    // Step policy comes from the shared [IncrementRules] so the time-based
    // panel can never drift from the rep panel or the set-row stepper:
    // duration ±5 s, weight ±1 kg up to 10 kg and ±2.5 kg above it.
    const durationSteps = IncrementRules.durationSteps;
    final weightSteps = IncrementRules.weightSteps(widget.weightKg ?? 0);

    final hero = Text(
      MmssFormatter.format(
        isCountingDown ? remainingSeconds : widget.durationSeconds,
      ),
      style: typography.numericHero.copyWith(
        color: isCountingDown ? colors.primary : colors.onSurface,
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(
          child: isFinished
              ? FadeTransition(opacity: _flashOpacity, child: hero)
              : hero,
        ),
        const SizedBox(height: AppSpacing.xs),
        Center(
          child: Text(
            isFinished
                ? 'done'
                : isRunning
                ? 'remaining'
                : 'seconds',
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
                  onPressed: widget.enabled && widget.durationSeconds > 0
                      ? widget.onStopwatchStart
                      : null,
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
                  onPressed: widget.enabled && !isCountingDown
                      ? () => widget.onDurationBump(durationSteps[0])
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurfaceMuted,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    textStyle: AppTypography.standard.actionLabel,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_stepLabel(durationSteps[0]), maxLines: 1),
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
                enabled: widget.enabled && !isCountingDown,
                textAlign: TextAlign.center,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                // "done" blurs the field; _commitOnBlur is the single commit
                // path, so it commits exactly once.
                onSubmitted: (_) => _secondsFocus.unfocus(),
                style: typography.numeric.copyWith(color: colors.onSurface),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: SizedBox(
                height: AppInSessionSize.stepButton,
                child: OutlinedButton(
                  onPressed: widget.enabled && !isCountingDown
                      ? () => widget.onDurationBump(durationSteps[1])
                      : null,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                    ),
                    textStyle: AppTypography.standard.actionLabel,
                  ),
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(_stepLabel(durationSteps[1]), maxLines: 1),
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
                        ? () => widget.onWeightBump(weightSteps[0])
                        : null,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colors.onSurfaceMuted,
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      textStyle: AppTypography.standard.actionLabel,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_stepLabel(weightSteps[0]), maxLines: 1),
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
                  // "done" blurs the field; _commitWeightOnBlur is the single
                  // commit path (handling empty→clear and parse), so a done
                  // press commits exactly once.
                  onSubmitted: (_) => _weightFocus.unfocus(),
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
                        ? () => widget.onWeightBump(weightSteps[1])
                        : null,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      textStyle: AppTypography.standard.actionLabel,
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(_stepLabel(weightSteps[1]), maxLines: 1),
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

  /// Signed step label for a bump button, e.g. `-5`, `+1`, `+2.5`. Half-kg
  /// steps render one decimal place; whole steps render as integers.
  String _stepLabel(num value) {
    final magnitude = value.abs();
    final whole = magnitude.toInt();
    final text = magnitude == whole ? '$whole' : magnitude.toStringAsFixed(1);
    return value < 0 ? '-$text' : '+$text';
  }
}
