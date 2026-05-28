import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/motion.dart';
import '../../../../app/widgets/animated_counter.dart';
import '../../../../app/widgets/pressable_scale.dart';

Future<int?> showCustomAmountDialog(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Theme.of(context).colorScheme.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) => const _CustomAmountSheet(),
  );
}

class _CustomAmountSheet extends StatefulWidget {
  const _CustomAmountSheet();

  @override
  State<_CustomAmountSheet> createState() => _CustomAmountSheetState();
}

class _CustomAmountSheetState extends State<_CustomAmountSheet> {
  static const _presets = [150, 200, 300, 400, 600, 750, 1000];
  static const _minMl = 50;
  static const _maxMl = 1500;

  double _value = 300;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    final ratio = ((_value - _minMl) / (_maxMl - _minMl)).clamp(0.0, 1.0);

    final accent = Color.lerp(scheme.primary, scheme.tertiary, ratio) ??
        scheme.primary;

    return Padding(
      padding: EdgeInsets.only(bottom: bottom),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Add custom amount',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pick a preset or fine-tune below',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),
            Container(
              padding:
                  const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    accent.withOpacity(0.18),
                    accent.withOpacity(0.06),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: accent.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  AnimatedCounter(
                    value: _value.round(),
                    style: Theme.of(context)
                        .textTheme
                        .displaySmall
                        ?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: accent,
                          letterSpacing: -1,
                        ),
                  ),
                  const SizedBox(width: 6),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(
                      'ml',
                      style: TextStyle(
                        fontSize: 16,
                        color: scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 40,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  for (final p in _presets) ...[
                    _PresetChip(
                      value: p,
                      selected: _value.round() == p,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        setState(() => _value = p.toDouble());
                      },
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 6,
                activeTrackColor: accent,
                thumbColor: accent,
                overlayColor: accent.withOpacity(0.15),
                inactiveTrackColor:
                    scheme.surfaceContainerHighest.withOpacity(0.8),
              ),
              child: Slider(
                value: _value.clamp(_minMl.toDouble(), _maxMl.toDouble()),
                min: _minMl.toDouble(),
                max: _maxMl.toDouble(),
                divisions: (_maxMl - _minMl) ~/ 10,
                onChanged: (v) {
                  setState(() => _value = v);
                },
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PressableScale(
                    onTap: () => Navigator.pop(context, _value.round()),
                    child: AnimatedContainer(
                      duration: AppDurations.sm,
                      curve: AppCurves.emphasized,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [scheme.primary, accent],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: accent.withOpacity(0.35),
                            blurRadius: 14,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'Add',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  const _PresetChip({
    required this.value,
    required this.selected,
    required this.onTap,
  });

  final int value;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppDurations.sm,
      curve: AppCurves.emphasized,
      decoration: BoxDecoration(
        color: selected
            ? scheme.primary
            : scheme.surfaceContainerHighest.withOpacity(0.7),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Text(
              '$value ml',
              style: TextStyle(
                color: selected ? Colors.white : scheme.onSurface,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
