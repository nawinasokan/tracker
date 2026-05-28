import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../motion.dart';

class AppFadeThroughTransitionBuilder extends PageTransitionsBuilder {
  const AppFadeThroughTransitionBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disable) return child;

    final fadeIn = CurvedAnimation(
      parent: animation,
      curve: const Interval(0.3, 1.0, curve: AppCurves.emphasizedDecelerate),
    );

    final scaleIn = Tween<double>(begin: 0.98, end: 1.0).animate(
      CurvedAnimation(
        parent: animation,
        curve: AppCurves.emphasizedDecelerate,
      ),
    );

    final fadeOut = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: secondaryAnimation,
        curve: const Interval(0.0, 0.3),
      ),
    );

    return FadeTransition(
      opacity: fadeOut,
      child: FadeTransition(
        opacity: fadeIn,
        child: ScaleTransition(
          scale: scaleIn,
          child: child,
        ),
      ),
    );
  }
}

Page<T> appFadePage<T>({required Widget child, LocalKey? key}) {
  return CustomTransitionPage<T>(
    key: key,
    child: child,
    transitionDuration: AppDurations.md,
    reverseTransitionDuration: AppDurations.sm,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final disable = MediaQuery.maybeDisableAnimationsOf(context) ?? false;
      if (disable) return child;

      return FadeTransition(
        opacity: CurvedAnimation(
          parent: animation,
          curve: AppCurves.emphasizedDecelerate,
        ),
        child: child,
      );
    },
  );
}
