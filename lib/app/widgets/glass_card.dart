import 'dart:ui';

import 'package:flutter/material.dart';

import '../app_gradients.dart';

class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.radius = 20,
    this.blurSigma = 14,
    this.tint,
    this.showBorder = true,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final double radius;
  final double blurSigma;
  final Color? tint;
  final bool showBorder;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseTint = tint ??
        (isDark
            ? scheme.surfaceContainerHigh.withOpacity(0.55)
            : Colors.white.withOpacity(0.55));

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          decoration: BoxDecoration(
            color: baseTint,
            borderRadius: BorderRadius.circular(radius),
            border: showBorder
                ? Border.all(
                    width: 1,
                    color: isDark
                        ? scheme.outlineVariant.withOpacity(0.3)
                        : Colors.white.withOpacity(0.5),
                  )
                : null,
            gradient: showBorder
                ? null
                : null,
          ),
          foregroundDecoration: showBorder
              ? BoxDecoration(
                  borderRadius: BorderRadius.circular(radius),
                  gradient: AppGradients.glassBorder(context),
                  backgroundBlendMode: BlendMode.overlay,
                )
              : null,
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}
