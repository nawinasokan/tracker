import 'package:flutter/material.dart';

import '../motion.dart';

class FloatingToast {
  FloatingToast._();

  static OverlayEntry? _current;

  static void show(
    BuildContext context, {
    required String message,
    IconData icon = Icons.water_drop,
    Duration duration = const Duration(milliseconds: 1500),
  }) {
    final overlay = Overlay.maybeOf(context, rootOverlay: true);
    if (overlay == null) return;

    _current?.remove();
    _current = null;

    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => _ToastWidget(
        message: message,
        icon: icon,
        duration: duration,
        onDismissed: () {
          if (_current == entry) _current = null;
          entry.remove();
        },
      ),
    );

    _current = entry;
    overlay.insert(entry);
  }
}

class _ToastWidget extends StatefulWidget {
  const _ToastWidget({
    required this.message,
    required this.icon,
    required this.duration,
    required this.onDismissed,
  });

  final String message;
  final IconData icon;
  final Duration duration;
  final VoidCallback onDismissed;

  @override
  State<_ToastWidget> createState() => _ToastWidgetState();
}

class _ToastWidgetState extends State<_ToastWidget>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: AppDurations.md,
    );
    _run();
  }

  Future<void> _run() async {
    await _controller.forward();
    await Future.delayed(widget.duration);
    if (!mounted) return;
    await _controller.reverse();
    if (!mounted) return;
    widget.onDismissed();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final mq = MediaQuery.of(context);

    final curve = CurvedAnimation(
      parent: _controller,
      curve: AppCurves.emphasizedDecelerate,
      reverseCurve: AppCurves.emphasizedAccelerate,
    );

    return Positioned(
      left: 0,
      right: 0,
      bottom: mq.padding.bottom + 110,
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: curve,
          builder: (context, _) {
            final t = curve.value;
            return Opacity(
              opacity: t,
              child: Transform.translate(
                offset: Offset(0, 20 * (1 - t)),
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: scheme.inverseSurface,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.18),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            widget.icon,
                            color: scheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.message,
                            style: TextStyle(
                              color: scheme.onInverseSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
