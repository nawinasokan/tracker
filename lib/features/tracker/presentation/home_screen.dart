import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/app_gradients.dart';
import '../../../app/motion.dart';
import '../../../app/widgets/floating_toast.dart';
import '../../../app/widgets/slide_fade_in.dart';
import '../providers/tracker_providers.dart';
import 'widgets/custom_amount_dialog.dart';
import 'widgets/history_list.dart';
import 'widgets/progress_ring.dart';
import 'widgets/quick_add_buttons.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Stay hydrated';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(todaySummaryProvider);
    final repo = ref.watch(waterRepositoryProvider);
    final dateStr = DateFormat.yMMMMEEEEd().format(summary.date);
    final scheme = Theme.of(context).colorScheme;

    Future<void> add(int ml) async {
      await repo.addEntry(ml);
      if (!context.mounted) return;
      FloatingToast.show(
        context,
        message: '+$ml ml added',
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(allEntriesProvider);
        await Future.delayed(const Duration(milliseconds: 400));
      },
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        slivers: [
          SliverPersistentHeader(
            pinned: true,
            delegate: _HeaderDelegate(
              greeting: _greeting(),
              date: dateStr,
              minExtent: MediaQuery.paddingOf(context).top + 60,
              maxExtent: MediaQuery.paddingOf(context).top + 180,
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlideFadeIn(
                  index: 0,
                  child: Center(
                    child: ProgressRing(
                      progress: summary.progress,
                      totalMl: summary.totalMl,
                      goalMl: summary.goalMl,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SlideFadeIn(
                  index: 1,
                  child: AnimatedSwitcher(
                    duration: AppDurations.md,
                    transitionBuilder: (child, anim) => FadeTransition(
                      opacity: anim,
                      child: SizeTransition(sizeFactor: anim, child: child),
                    ),
                    child: summary.goalReached
                        ? _GoalReachedBanner(key: const ValueKey('reached'))
                        : Center(
                            key: const ValueKey('remaining'),
                            child: Text(
                              '${summary.remainingMl} ml to go',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyLarge
                                  ?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 28),
                SlideFadeIn(
                  index: 2,
                  child: QuickAddButtons(onAdd: add),
                ),
                const SizedBox(height: 12),
                SlideFadeIn(
                  index: 3,
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final ml = await showCustomAmountDialog(context);
                      if (ml != null) await add(ml);
                    },
                    icon: const Icon(Icons.tune_rounded),
                    label: const Text('Custom amount'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(52),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SlideFadeIn(
                  index: 4,
                  child: Row(
                    children: [
                      Text(
                        "Today's history",
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const Spacer(),
                      Text(
                        '${summary.entries.length} entries',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SlideFadeIn(
                  index: 5,
                  child: HistoryList(
                    entries: summary.entries,
                    onDelete: (e) => repo.deleteEntry(e.id),
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _GoalReachedBanner extends StatelessWidget {
  const _GoalReachedBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.tertiary,
            Color.lerp(scheme.tertiary, scheme.primary, 0.4) ?? scheme.primary,
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scheme.tertiary.withOpacity(0.35),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.celebration, color: Colors.white, size: 26),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              "Goal reached! Great job staying hydrated.",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderDelegate extends SliverPersistentHeaderDelegate {
  _HeaderDelegate({
    required this.greeting,
    required this.date,
    required this.minExtent,
    required this.maxExtent,
  });

  final String greeting;
  final String date;

  @override
  final double minExtent;

  @override
  final double maxExtent;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final ratio =
        (1 - (shrinkOffset / (maxExtent - minExtent))).clamp(0.0, 1.0);
    final scheme = Theme.of(context).colorScheme;
    final topPad = MediaQuery.paddingOf(context).top;

    return ClipRect(
      child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(gradient: AppGradients.header(context)),
          ),
          Positioned.fill(
            child: RepaintBoundary(
              child: _AnimatedWave(
                color: scheme.primary.withOpacity(0.18),
                opacity: ratio,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(20, topPad + 8, 20, 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Opacity(
                  opacity: ratio,
                  child: Text(
                    greeting,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                ),
                Text(
                  'Today',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: scheme.onSurface,
                        letterSpacing: -0.4,
                      ),
                ),
                if (ratio > 0.2)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Opacity(
                      opacity: ratio,
                      child: Text(
                        date,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _HeaderDelegate old) =>
      old.greeting != greeting || old.date != date;
}

class _AnimatedWave extends StatefulWidget {
  const _AnimatedWave({required this.color, required this.opacity});

  final Color color;
  final double opacity;

  @override
  State<_AnimatedWave> createState() => _AnimatedWaveState();
}

class _AnimatedWaveState extends State<_AnimatedWave>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableMotion =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (disableMotion) return const SizedBox.shrink();
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => CustomPaint(
        painter: _WavePainter(
          phase: _controller.value * 2 * math.pi,
          color: widget.color.withOpacity(widget.opacity * 0.7),
        ),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  _WavePainter({required this.phase, required this.color});

  final double phase;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color;
    final amplitude = 8.0;
    final baseY = size.height - 24;
    final path = Path()..moveTo(0, baseY);
    for (double x = 0; x <= size.width; x += 6) {
      final y = baseY +
          math.sin((x / size.width) * 2 * math.pi * 1.5 + phase) * amplitude;
      path.lineTo(x, y);
    }
    path
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path, paint);

    final paint2 = Paint()..color = color.withOpacity(color.opacity * 0.5);
    final path2 = Path()..moveTo(0, baseY + 4);
    for (double x = 0; x <= size.width; x += 6) {
      final y = baseY +
          4 +
          math.sin((x / size.width) * 2 * math.pi * 1.2 + phase + math.pi / 2) *
              amplitude *
              0.7;
      path2.lineTo(x, y);
    }
    path2
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(path2, paint2);
  }

  @override
  bool shouldRepaint(covariant _WavePainter old) =>
      old.phase != phase || old.color != color;
}
