import 'package:flutter/material.dart';

import '../motion.dart';

class AnimatedCounter extends StatefulWidget {
  const AnimatedCounter({
    super.key,
    required this.value,
    this.duration = AppDurations.md,
    this.curve = AppCurves.emphasizedDecelerate,
    this.style,
    this.suffix,
    this.prefix,
    this.fractionDigits = 0,
    this.textAlign,
  });

  final num value;
  final Duration duration;
  final Curve curve;
  final TextStyle? style;
  final String? suffix;
  final String? prefix;
  final int fractionDigits;
  final TextAlign? textAlign;

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter> {
  late double _previous;

  @override
  void initState() {
    super.initState();
    _previous = widget.value.toDouble();
  }

  @override
  void didUpdateWidget(covariant AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value) {
      _previous = oldWidget.value.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: _previous, end: widget.value.toDouble()),
      duration: disable ? Duration.zero : widget.duration,
      curve: widget.curve,
      builder: (context, v, _) {
        final shown = v.toStringAsFixed(widget.fractionDigits);
        final text = '${widget.prefix ?? ''}$shown${widget.suffix ?? ''}';
        return Text(text, style: widget.style, textAlign: widget.textAlign);
      },
    );
  }
}
