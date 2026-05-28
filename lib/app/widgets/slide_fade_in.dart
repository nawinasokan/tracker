import 'package:flutter/material.dart';

import '../motion.dart';

class SlideFadeIn extends StatefulWidget {
  const SlideFadeIn({
    super.key,
    required this.child,
    this.index = 0,
    this.delayStep = const Duration(milliseconds: 60),
    this.duration = AppDurations.lg,
    this.offset = 16.0,
  });

  final Widget child;
  final int index;
  final Duration delayStep;
  final Duration duration;
  final double offset;

  @override
  State<SlideFadeIn> createState() => _SlideFadeInState();
}

class _SlideFadeInState extends State<SlideFadeIn>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    _schedule();
  }

  void _schedule() {
    final delay = widget.delayStep * widget.index;
    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(covariant SlideFadeIn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      _controller.reset();
      _schedule();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disable) return widget.child;

    final curve = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.emphasizedDecelerate,
    );

    return AnimatedBuilder(
      animation: curve,
      builder: (context, _) {
        final t = curve.value;
        return Opacity(
          opacity: t,
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - t)),
            child: widget.child,
          ),
        );
      },
    );
  }
}
