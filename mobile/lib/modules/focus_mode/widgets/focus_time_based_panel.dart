import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zamaj/core/app_spacing.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';
import 'package:zamaj/modules/focus_mode/models/stopwatch_view_model.dart';

/// Big editable panel for the current time-based set: stopwatch with
/// START/STOP, with a fallback numeric field + ±5 bumps so users can also
/// log durations they timed themselves.
class FocusTimeBasedPanel extends StatefulWidget {
  const FocusTimeBasedPanel({
    super.key,
    required this.durationSeconds,
    required this.stopwatch,
    required this.onDurationBump,
    required this.onDurationCommitted,
    required this.onStopwatchStart,
    required this.onStopwatchStop,
    required this.enabled,
  });

  final int durationSeconds;
  final StopwatchViewModel stopwatch;
  final void Function(int delta) onDurationBump;
  final void Function(int seconds) onDurationCommitted;
  final VoidCallback onStopwatchStart;
  final VoidCallback onStopwatchStop;
  final bool enabled;

  @override
  State<FocusTimeBasedPanel> createState() => _FocusTimeBasedPanelState();
}

class _FocusTimeBasedPanelState extends State<FocusTimeBasedPanel> {
  late final TextEditingController _seconds;
  final FocusNode _secondsFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _seconds = TextEditingController(text: widget.durationSeconds.toString());
    _secondsFocus.addListener(_commitOnBlur);
  }

  @override
  void didUpdateWidget(covariant FocusTimeBasedPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_secondsFocus.hasFocus &&
        widget.durationSeconds != oldWidget.durationSeconds) {
      _seconds.text = widget.durationSeconds.toString();
    }
  }

  @override
  void dispose() {
    _secondsFocus.removeListener(_commitOnBlur);
    _seconds.dispose();
    _secondsFocus.dispose();
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

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final isRunning = widget.stopwatch.isRunning;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.lg,
      ),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: colors.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Text(
              _formatMmss(
                isRunning
                    ? widget.stopwatch.elapsedSeconds
                    : widget.durationSeconds,
              ),
              style: typography.numericLarge.copyWith(
                color: isRunning ? colors.primary : colors.onSurface,
                fontSize: 56,
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
                    icon: const Icon(Icons.stop, size: 18),
                    label: const Text('STOP'),
                    style: FilledButton.styleFrom(
                      backgroundColor: colors.error,
                      foregroundColor: colors.onError,
                    ),
                  )
                : FilledButton.icon(
                    onPressed: widget.enabled ? widget.onStopwatchStart : null,
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('START TIMER'),
                  ),
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: AppSpacing.touchMin,
                  child: OutlinedButton(
                    onPressed: widget.enabled && !isRunning
                        ? () => widget.onDurationBump(-5)
                        : null,
                    child: const Text('-5'),
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
                  decoration: InputDecoration(
                    isDense: true,
                    filled: true,
                    fillColor: colors.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.md,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      borderSide: BorderSide(color: colors.outline),
                    ),
                  ),
                  style: typography.numeric.copyWith(color: colors.onSurface),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: SizedBox(
                  height: AppSpacing.touchMin,
                  child: OutlinedButton(
                    onPressed: widget.enabled && !isRunning
                        ? () => widget.onDurationBump(5)
                        : null,
                    child: const Text('+5'),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _formatMmss(int totalSeconds) {
    final s = totalSeconds < 0 ? 0 : totalSeconds;
    final m = s ~/ 60;
    final r = s % 60;
    return '${m.toString().padLeft(2, '0')}:${r.toString().padLeft(2, '0')}';
  }
}
