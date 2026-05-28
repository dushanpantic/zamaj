import 'package:flutter/material.dart';
import 'package:zamaj/core/app_spacing.dart';

/// Single-line text that scrolls horizontally like a news ticker when it
/// can't fit the available width, and renders statically when it can. Two
/// copies separated by a gap give a seamless continuous loop.
class FocusMarqueeText extends StatefulWidget {
  const FocusMarqueeText({super.key, required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  State<FocusMarqueeText> createState() => _FocusMarqueeTextState();
}

class _FocusMarqueeTextState extends State<FocusMarqueeText>
    with SingleTickerProviderStateMixin {
  static const double _gap = AppSpacing.xxxl;

  /// Scroll speed in logical pixels per second.
  static const double _velocity = 40;

  late final AnimationController _controller;
  final ScrollController _scrollController = ScrollController();

  /// Distance to travel for one seamless loop: a full copy plus the gap.
  double _loopExtent = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this)..addListener(_tick);
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _tick() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(_controller.value * _loopExtent);
    }
  }

  Widget _line() =>
      Text(widget.text, style: widget.style, maxLines: 1, softWrap: false);

  double _measureWidth(TextStyle style, TextScaler textScaler) {
    final painter = TextPainter(
      text: TextSpan(text: widget.text, style: style),
      maxLines: 1,
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout();
    return painter.size.width;
  }

  void _runScroll() {
    final duration = Duration(
      milliseconds: (_loopExtent / _velocity * 1000).round(),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (_controller.duration != duration) {
        _controller.duration = duration;
        _controller.repeat();
      } else if (!_controller.isAnimating) {
        _controller.repeat();
      }
    });
  }

  void _stopScroll() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.isAnimating) return;
      _controller
        ..stop()
        ..value = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Resolve exactly as Text does, so the overflow test matches what's
    // actually painted (DefaultTextStyle can supply letterSpacing etc.,
    // and text scaling widens glyphs).
    final effectiveStyle = DefaultTextStyle.of(
      context,
    ).style.merge(widget.style);
    final textScaler = MediaQuery.textScalerOf(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final textWidth = _measureWidth(effectiveStyle, textScaler);

        if (!maxWidth.isFinite || textWidth <= maxWidth) {
          _stopScroll();
          return Text(
            widget.text,
            style: widget.style,
            maxLines: 1,
            softWrap: false,
            overflow: TextOverflow.clip,
          );
        }

        _loopExtent = textWidth + _gap;
        _runScroll();

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _line(),
              const SizedBox(width: _gap),
              _line(),
            ],
          ),
        );
      },
    );
  }
}
