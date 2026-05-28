import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../../../app/motion.dart';
import '../../data/water_entry.dart';

class HistoryList extends StatefulWidget {
  const HistoryList({
    super.key,
    required this.entries,
    required this.onDelete,
  });

  final List<WaterEntry> entries;
  final ValueChanged<WaterEntry> onDelete;

  @override
  State<HistoryList> createState() => _HistoryListState();
}

class _HistoryListState extends State<HistoryList> {
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();
  late List<WaterEntry> _items;

  @override
  void initState() {
    super.initState();
    _items = List.of(widget.entries);
  }

  @override
  void didUpdateWidget(covariant HistoryList oldWidget) {
    super.didUpdateWidget(oldWidget);
    _sync(widget.entries);
  }

  void _sync(List<WaterEntry> next) {
    final oldIds = _items.map((e) => e.id).toSet();
    final nextIds = next.map((e) => e.id).toSet();

    // Remove items that disappeared.
    for (int i = _items.length - 1; i >= 0; i--) {
      final id = _items[i].id;
      if (!nextIds.contains(id)) {
        final removed = _items.removeAt(i);
        _listKey.currentState?.removeItem(
          i,
          (context, animation) => _buildAnimated(removed, animation),
          duration: AppDurations.md,
        );
      }
    }

    // Insert new items at correct positions.
    for (int i = 0; i < next.length; i++) {
      final entry = next[i];
      if (!oldIds.contains(entry.id)) {
        _items.insert(i, entry);
        _listKey.currentState?.insertItem(i, duration: AppDurations.md);
      }
    }
  }

  Widget _buildAnimated(WaterEntry entry, Animation<double> animation) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: AppCurves.emphasizedDecelerate,
    );
    return SizeTransition(
      sizeFactor: curve,
      child: FadeTransition(
        opacity: curve,
        child: _EntryTile(
          entry: entry,
          onDelete: () => widget.onDelete(entry),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_items.isEmpty) {
      return const _EmptyState();
    }

    return AnimatedList(
      key: _listKey,
      initialItemCount: _items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index, animation) {
        if (index >= _items.length) return const SizedBox.shrink();
        return _buildAnimated(_items[index], animation);
      },
    );
  }
}

class _EntryTile extends StatelessWidget {
  const _EntryTile({required this.entry, required this.onDelete});

  final WaterEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final timeFmt = DateFormat.jm();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: ValueKey(entry.id),
        direction: DismissDirection.endToStart,
        dismissThresholds: const {DismissDirection.endToStart: 0.35},
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                scheme.errorContainer.withOpacity(0.3),
                scheme.error,
              ],
            ),
          ),
          child: const Icon(Icons.delete_outline, color: Colors.white),
        ),
        onUpdate: (details) {
          if (details.reached && !details.previousReached) {
            HapticFeedback.lightImpact();
          }
        },
        onDismissed: (_) {
          HapticFeedback.mediumImpact();
          onDelete();
        },
        child: Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withOpacity(0.6),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.35),
              width: 1,
            ),
          ),
          child: ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    scheme.primary.withOpacity(0.85),
                    scheme.tertiary.withOpacity(0.85),
                  ],
                ),
              ),
              child: const Icon(
                Icons.water_drop,
                color: Colors.white,
                size: 22,
              ),
            ),
            title: Text(
              '${entry.amountMl} ml',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            subtitle: Text(timeFmt.format(entry.timestamp)),
            trailing: Icon(
              Icons.chevron_left,
              color: scheme.onSurfaceVariant.withOpacity(0.5),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Column(
          children: [
            CustomPaint(
              size: const Size(72, 88),
              painter: _DropPainter(
                color: scheme.primary.withOpacity(0.18),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'No entries yet',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              'Tap a preset above to log your first sip.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropPainter extends CustomPainter {
  _DropPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..moveTo(size.width / 2, 0)
      ..quadraticBezierTo(size.width, size.height * 0.55,
          size.width / 2, size.height)
      ..quadraticBezierTo(0, size.height * 0.55, size.width / 2, 0)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _DropPainter old) => old.color != color;
}
