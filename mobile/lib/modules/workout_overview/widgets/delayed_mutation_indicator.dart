import 'dart:async';

import 'package:flutter/material.dart';

/// Top-of-screen mutation indicator that only appears once a mutation has
/// been in flight for [_showAfter]. Fast operations (a single set log
/// against the local SQLite write) typically resolve well under that
/// threshold; showing the bar immediately produced a brief orange flash
/// on every LOG SET. Slow operations still surface the indicator so the
/// user knows something is happening.
class DelayedMutationIndicator extends StatefulWidget {
  const DelayedMutationIndicator({super.key, required this.inFlight});

  final bool inFlight;

  static const Duration _showAfter = Duration(milliseconds: 500);

  @override
  State<DelayedMutationIndicator> createState() =>
      _DelayedMutationIndicatorState();
}

class _DelayedMutationIndicatorState extends State<DelayedMutationIndicator> {
  Timer? _timer;
  bool _visible = false;

  @override
  void initState() {
    super.initState();
    if (widget.inFlight) _scheduleShow();
  }

  @override
  void didUpdateWidget(covariant DelayedMutationIndicator old) {
    super.didUpdateWidget(old);
    if (widget.inFlight == old.inFlight) return;
    if (widget.inFlight) {
      _scheduleShow();
    } else {
      _timer?.cancel();
      _timer = null;
      if (_visible) setState(() => _visible = false);
    }
  }

  void _scheduleShow() {
    _timer?.cancel();
    _timer = Timer(DelayedMutationIndicator._showAfter, () {
      if (!mounted) return;
      setState(() => _visible = true);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_visible) return const SizedBox.shrink();
    return const LinearProgressIndicator(minHeight: 2);
  }
}
