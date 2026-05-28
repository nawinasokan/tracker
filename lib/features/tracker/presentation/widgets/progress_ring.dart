import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../app/app_gradients.dart';
import '../../../../app/motion.dart';
import '../../../../app/widgets/animated_counter.dart';

class ProgressRing extends StatefulWidget {
  const ProgressRing({
    super.key,
    required this.progress,
    required this.totalMl,
    required this.goalMl,
  });

  final double progress;
  final int totalMl;
  final int goalMl;

  @override
  State<ProgressRing> createState() => _ProgressRingState();
}

class _ProgressRingState extends State<ProgressRing>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final AnimationController _celebrateController;

  double _previousProgress = 0;
  bool _wasGoalReached = false;

  @override
  void initState() {
    super.initState();
    _previousProgress = widget.progress;
    _wasGoalReached = widget.progress >= 1.0;
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _celebrateController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void didUpdateWidget(covariant ProgressRing oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.progress != widget.progress) {
      _previousProgress = oldWidget.progress;
    }
    final reached = widget.progress >= 1.0;
    if (reached && !_wasGoalReached) {
      _pulseController.forward(from: 0);
      _celebrateController.forward(from: 0);
    }
    _wasGoalReached = reached;
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _celebrateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final disableMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final pct = (widget.progress * 100).clamp(0, 100).toStringAsFixed(0);

    final pulse = CurvedAnimation(
      parent: _pulseController,
      curve: AppCurves.gentleSpring,
    );

    return RepaintBoundary(
      child: AnimatedBuilder(
        animation: Listenable.merge([pulse, _celebrateController]),
        builder: (context, _) {
          final pulseScale = 1.0 +
              (disableMotion
                  ? 0.0
                  : math.sin(pulse.value * math.pi) * 0.06);
          return Transform.scale(
            scale: pulseScale,
            child: SizedBox(
              width: 260,
              height: 260,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  if (_celebrateController.isAnimating ||
                      _celebrateController.value > 0)
                    CustomPaint(
                      size: const Size(260, 260),
                      painter: _ParticlesPainter(
                        progress: _celebrateController.value,
                        color: scheme.tertiary,
                        secondary: scheme.primary,
                      ),
                    ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(
                      begin: _previousProgress,
                      end: widget.progress,
                    ),
                    duration: disableMotion
                        ? Duration.zero
                        : AppDurations.lg,
                    curve: AppCurves.emphasizedDecelerate,
                    builder: (context, value, _) {
                      return CustomPaint(
                        size: const Size(260, 260),
                        painter: _RingPainter(
                          progress: value,
                          trackColor: scheme.surfaceContainerHighest
                              .withOpacity(0.55),
                          gradient: AppGradients.ring(context),
                          glowColor: scheme.primary.withOpacity(0.25),
                        ),
                      );
                    },
                  ),
                  _RingCenter(
                    totalMl: widget.totalMl,
                    goalMl: widget.goalMl,
                    pct: pct,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RingCenter extends StatelessWidget {
  const _RingCenter({
    required this.totalMl,
    required this.goalMl,
    required this.pct,
  });

  final int totalMl;
  final int goalMl;
  final String pct;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          label: '$totalMl millilitres of $goalMl, $pct percent',
          child: AnimatedCounter(
            value: totalMl,
            suffix: ' ml',
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: scheme.onSurface,
                  letterSpacing: -0.5,
                ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'of $goalMl ml',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: AppDurations.md,
          curve: AppCurves.emphasized,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                scheme.primary,
                scheme.tertiary,
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: scheme.primary.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Text(
            '$pct%',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.3,
            ),
          ),
        ),
      ],
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.progress,
    required this.trackColor,
    required this.gradient,
    required this.glowColor,
  });

  final double progress;
  final Color trackColor;
  final SweepGradient gradient;
  final Color glowColor;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 20.0;
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke;

    canvas.drawCircle(center, radius, trackPaint);

    final clamped = progress.clamp(0.0, 1.0);
    if (clamped <= 0) return;

    final sweep = 2 * math.pi * clamped;

    final glowPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke + 6
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

    canvas.drawArc(rect, -math.pi / 2, sweep, false, glowPaint);

    final progressPaint = Paint()
      ..shader = gradient.createShader(rect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, -math.pi / 2, sweep, false, progressPaint);

    final headAngle = -math.pi / 2 + sweep;
    final headOffset = Offset(
      center.dx + radius * math.cos(headAngle),
      center.dy + radius * math.sin(headAngle),
    );
    final headPaint = Paint()
      ..color = Colors.white.withOpacity(0.85)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
    canvas.drawCircle(headOffset, stroke / 4, headPaint);
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress ||
      old.trackColor != trackColor ||
      old.glowColor != glowColor;
}

class _ParticlesPainter extends CustomPainter {
  _ParticlesPainter({
    required this.progress,
    required this.color,
    required this.secondary,
  });

  final double progress;
  final Color color;
  final Color secondary;

  static final List<double> _angles = List.generate(
    14,
    (i) => (i / 14) * 2 * math.pi + math.Random(i).nextDouble() * 0.4,
  );

  static final List<double> _radii = List.generate(
    14,
    (i) => 0.85 + math.Random(i + 100).nextDouble() * 0.25,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    final center = size.center(Offset.zero);
    final baseR = size.shortestSide / 2;

    for (int i = 0; i < _angles.length; i++) {
      final t = progress;
      final dist = baseR * _radii[i] * t;
      final angle = _angles[i];
      final position = Offset(
        center.dx + dist * math.cos(angle),
        center.dy + dist * math.sin(angle),
      );
      final opacity = (1 - t).clamp(0.0, 1.0);
      final paint = Paint()
        ..color = (i.isEven ? color : secondary).withOpacity(opacity);
      canvas.drawCircle(position, 3.5 * (1 - t * 0.5), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _ParticlesPainter old) =>
      old.progress != progress;
}
