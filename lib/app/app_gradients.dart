import 'package:flutter/material.dart';

class AppGradients {
  AppGradients._();

  static LinearGradient brand(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary,
        Color.lerp(scheme.primary, scheme.tertiary, 0.6) ?? scheme.primary,
        scheme.tertiary,
      ],
    );
  }

  static LinearGradient header(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: isDark
          ? [
              scheme.surfaceContainerHigh,
              Color.lerp(scheme.primary, scheme.surface, 0.78) ??
                  scheme.surface,
              scheme.surfaceContainer,
            ]
          : [
              Color.lerp(scheme.primary, Colors.white, 0.82) ??
                  scheme.primaryContainer,
              Color.lerp(scheme.tertiary, Colors.white, 0.85) ??
                  scheme.tertiaryContainer,
              scheme.surface,
            ],
    );
  }

  static SweepGradient ring(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SweepGradient(
      startAngle: -1.5708, // -π/2
      endAngle: 4.7124, // 3π/2
      colors: [
        scheme.primary,
        Color.lerp(scheme.primary, scheme.tertiary, 0.5) ?? scheme.primary,
        scheme.tertiary,
        scheme.primary,
      ],
      stops: const [0.0, 0.5, 0.85, 1.0],
    );
  }

  static LinearGradient glassBorder(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        scheme.primary.withOpacity(0.35),
        scheme.tertiary.withOpacity(0.15),
      ],
    );
  }
}
