import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../motion.dart';

class PressableScale extends StatefulWidget {
  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scale = 0.96,
    this.haptic = true,
    this.enabled = true,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final bool haptic;
  final bool enabled;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    final enabled = widget.enabled && widget.onTap != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _setPressed(true) : null,
      onTapCancel: enabled ? () => _setPressed(false) : null,
      onTapUp: enabled ? (_) => _setPressed(false) : null,
      onTap: enabled
          ? () {
              if (widget.haptic) HapticFeedback.lightImpact();
              widget.onTap?.call();
            }
          : null,
      onLongPress: enabled && widget.onLongPress != null
          ? () {
              if (widget.haptic) HapticFeedback.mediumImpact();
              widget.onLongPress?.call();
            }
          : null,
      child: AnimatedScale(
        scale: _pressed && !disableMotion ? widget.scale : 1.0,
        duration: AppDurations.sm,
        curve: AppCurves.emphasized,
        child: widget.child,
      ),
    );
  }
}
