import 'package:flutter/material.dart';

import '../../../../app/motion.dart';
import '../../../../app/widgets/pressable_scale.dart';
import '../../../../core/constants.dart';

class QuickAddButtons extends StatelessWidget {
  const QuickAddButtons({super.key, required this.onAdd});

  final ValueChanged<int> onAdd;

  static const _glyphs = <int, IconData>{
    100: Icons.local_cafe_outlined,
    250: Icons.local_drink_outlined,
    500: Icons.sports_bar_outlined,
  };

  static const _labels = <int, String>{
    100: 'Sip',
    250: 'Glass',
    500: 'Bottle',
  };

  @override
  Widget build(BuildContext context) {
    const amounts = AppDefaults.quickAddAmounts;
    return LayoutBuilder(
      builder: (context, constraints) {
        const spacing = 12.0;
        final tileWidth =
            (constraints.maxWidth - spacing * (amounts.length - 1)) /
                amounts.length;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: [
            for (final amount in amounts)
              SizedBox(
                width: tileWidth,
                child: _QuickAddTile(
                  amount: amount,
                  icon: _glyphs[amount] ?? Icons.water_drop_outlined,
                  label: _labels[amount] ?? '',
                  onTap: () => onAdd(amount),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _QuickAddTile extends StatefulWidget {
  const _QuickAddTile({
    required this.amount,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final int amount;
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  State<_QuickAddTile> createState() => _QuickAddTileState();
}

class _QuickAddTileState extends State<_QuickAddTile> {
  bool _flash = false;

  Future<void> _handle() async {
    if (mounted) setState(() => _flash = true);
    widget.onTap();
    await Future.delayed(const Duration(milliseconds: 220));
    if (mounted) setState(() => _flash = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PressableScale(
      onTap: _handle,
      child: AnimatedContainer(
        duration: AppDurations.sm,
        curve: AppCurves.emphasized,
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: _flash
                ? [
                    scheme.primary,
                    scheme.tertiary,
                  ]
                : isDark
                    ? [
                        scheme.surfaceContainerHigh,
                        scheme.surfaceContainerHighest,
                      ]
                    : [
                        scheme.primaryContainer.withOpacity(0.55),
                        scheme.tertiaryContainer.withOpacity(0.4),
                      ],
          ),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.35),
            width: 1,
          ),
          boxShadow: _flash
              ? [
                  BoxShadow(
                    color: scheme.primary.withOpacity(0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              widget.icon,
              color: _flash ? Colors.white : scheme.primary,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.amount} ml',
              style: TextStyle(
                color: _flash ? Colors.white : scheme.onSurface,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              widget.label,
              style: TextStyle(
                color: _flash
                    ? Colors.white.withOpacity(0.85)
                    : scheme.onSurfaceVariant,
                fontSize: 11,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
