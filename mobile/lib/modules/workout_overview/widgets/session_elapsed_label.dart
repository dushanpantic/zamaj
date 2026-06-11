import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:zamaj/core/app_theme.dart';
import 'package:zamaj/core/app_typography.dart';

/// Ticking elapsed-time readout. Counts up from [startedAt] every second
/// while the session is live; freezes at `endedAt - startedAt` once the
/// session ends.
class SessionElapsedLabel extends StatefulWidget {
  const SessionElapsedLabel({
    super.key,
    required this.startedAt,
    required this.endedAt,
  });

  final DateTime startedAt;
  final DateTime? endedAt;

  @override
  State<SessionElapsedLabel> createState() => _SessionElapsedLabelState();
}

class _SessionElapsedLabelState extends State<SessionElapsedLabel> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _maybeStartTicker();
  }

  @override
  void didUpdateWidget(covariant SessionElapsedLabel old) {
    super.didUpdateWidget(old);
    if (old.endedAt != widget.endedAt) {
      _ticker?.cancel();
      _ticker = null;
      _maybeStartTicker();
    }
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  void _maybeStartTicker() {
    if (widget.endedAt != null) return;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).appColors;
    const typography = AppTypography.standard;
    final end = widget.endedAt ?? context.read<Clock>().now().toUtc();
    final seconds = end.difference(widget.startedAt).inSeconds;
    return Text(
      _formatElapsed(seconds < 0 ? 0 : seconds),
      style: typography.numericSm.copyWith(color: colors.onSurfaceMuted),
    );
  }

  static String _formatElapsed(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    final mm = m.toString().padLeft(2, '0');
    final ss = s.toString().padLeft(2, '0');
    if (h > 0) return '$h:$mm:$ss';
    return '$mm:$ss';
  }
}
