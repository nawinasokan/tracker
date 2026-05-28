import 'package:flutter/material.dart';

class AppDurations {
  AppDurations._();

  static const Duration xs = Duration(milliseconds: 120);
  static const Duration sm = Duration(milliseconds: 200);
  static const Duration md = Duration(milliseconds: 320);
  static const Duration lg = Duration(milliseconds: 520);
  static const Duration xl = Duration(milliseconds: 800);
}

class AppCurves {
  AppCurves._();

  static const Curve emphasized = Cubic(0.2, 0.0, 0.0, 1.0);
  static const Curve emphasizedDecelerate = Cubic(0.05, 0.7, 0.1, 1.0);
  static const Curve emphasizedAccelerate = Cubic(0.3, 0.0, 0.8, 0.15);
  static const Curve standard = Cubic(0.2, 0.0, 0, 1.0);
  static const Curve gentleSpring = Cubic(0.34, 1.56, 0.64, 1.0);
}
