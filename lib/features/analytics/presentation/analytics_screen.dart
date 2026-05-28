import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../app/motion.dart';
import '../../../app/widgets/animated_counter.dart';
import '../../../app/widgets/slide_fade_in.dart';
import '../../../core/utils/date_utils.dart';
import '../../settings/providers/settings_providers.dart';
import '../../tracker/data/water_entry.dart';
import '../../tracker/providers/tracker_providers.dart';

enum _Range { week, month }

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  _Range _range = _Range.week;

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(allEntriesProvider).valueOrNull ?? const [];
    final goal = ref.watch(dailyGoalProvider);
    final dayCount = _range == _Range.week ? 7 : 30;
    final days = lastNDays(dayCount);
    final perDay = _aggregate(entries, days);

    final avg =
        perDay.isEmpty ? 0 : perDay.reduce((a, b) => a + b) ~/ perDay.length;
    final best = perDay.isEmpty ? 0 : perDay.reduce((a, b) => a > b ? a : b);
    final streak = _streak(perDay, goal);
    final maxValue = perDay.isEmpty ? goal : perDay.reduce((a, b) => a > b ? a : b);
    final chartMax =
        ((maxValue < goal ? goal : maxValue) * 1.2).toDouble().clamp(100.0, double.infinity);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar(
            pinned: true,
            title: Text('Analytics'),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlideFadeIn(
                  index: 0,
                  child: _RangeToggle(
                    range: _range,
                    onChanged: (r) {
                      HapticFeedback.selectionClick();
                      setState(() => _range = r);
                    },
                  ),
                ),
                const SizedBox(height: 20),
                SlideFadeIn(
                  index: 1,
                  child: Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          label: 'Average',
                          value: avg,
                          suffix: ' ml',
                          icon: Icons.show_chart_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'Best day',
                          value: best,
                          suffix: ' ml',
                          icon: Icons.emoji_events_outlined,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _KpiCard(
                          label: 'Streak',
                          value: streak,
                          suffix: streak == 1 ? ' day' : ' days',
                          icon: Icons.local_fire_department_outlined,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SlideFadeIn(
                  index: 2,
                  child: Text(
                    _range == _Range.week ? 'Last 7 days' : 'Last 30 days',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                SlideFadeIn(
                  index: 3,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(12, 24, 16, 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .surfaceContainerHighest
                          .withOpacity(0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Theme.of(context)
                            .colorScheme
                            .outlineVariant
                            .withOpacity(0.35),
                      ),
                    ),
                    child: SizedBox(
                      height: 220,
                      child: RepaintBoundary(
                        child: _RangeChart(
                          days: days,
                          values: perDay,
                          goal: goal,
                          maxY: chartMax,
                          compact: _range == _Range.month,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SlideFadeIn(
                  index: 4,
                  child: Text(
                    'Daily breakdown',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ),
                const SizedBox(height: 8),
                for (int i = days.length - 1; i >= 0; i--)
                  SlideFadeIn(
                    index: 5 + (days.length - 1 - i),
                    delayStep: const Duration(milliseconds: 30),
                    child: _DayRow(
                      date: days[i],
                      totalMl: perDay[i],
                      goalMl: goal,
                    ),
                  ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  List<int> _aggregate(List<WaterEntry> entries, List<DateTime> days) {
    return days.map((day) {
      return entries
          .where((e) => e.timestamp.isSameDay(day))
          .fold<int>(0, (s, e) => s + e.amountMl);
    }).toList();
  }

  int _streak(List<int> perDay, int goal) {
    int s = 0;
    for (int i = perDay.length - 1; i >= 0; i--) {
      if (perDay[i] >= goal) {
        s++;
      } else {
        break;
      }
    }
    return s;
  }
}

class _RangeToggle extends StatelessWidget {
  const _RangeToggle({required this.range, required this.onChanged});

  final _Range range;
  final ValueChanged<_Range> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(14),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final w = constraints.maxWidth / 2;
          return Stack(
            children: [
              AnimatedAlign(
                alignment: range == _Range.week
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                duration: AppDurations.md,
                curve: AppCurves.emphasized,
                child: Container(
                  width: w - 4,
                  height: 40,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scheme.primary, scheme.tertiary],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: scheme.primary.withOpacity(0.25),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: _ToggleButton(
                      label: 'Week',
                      selected: range == _Range.week,
                      onTap: () => onChanged(_Range.week),
                    ),
                  ),
                  Expanded(
                    child: _ToggleButton(
                      label: 'Month',
                      selected: range == _Range.month,
                      onTap: () => onChanged(_Range.month),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Center(
          child: AnimatedDefaultTextStyle(
            duration: AppDurations.sm,
            style: TextStyle(
              color: selected ? Colors.white : scheme.onSurfaceVariant,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
            child: Text(label),
          ),
        ),
      ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.suffix,
    required this.icon,
  });

  final String label;
  final int value;
  final String suffix;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withOpacity(0.6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: scheme.outlineVariant.withOpacity(0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  scheme.primary.withOpacity(0.18),
                  scheme.tertiary.withOpacity(0.12),
                ],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: scheme.primary, size: 18),
          ),
          const SizedBox(height: 10),
          AnimatedCounter(
            value: value,
            suffix: suffix,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }
}

class _RangeChart extends StatelessWidget {
  const _RangeChart({
    required this.days,
    required this.values,
    required this.goal,
    required this.maxY,
    required this.compact,
  });

  final List<DateTime> days;
  final List<int> values;
  final int goal;
  final double maxY;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return BarChart(
      BarChartData(
        maxY: maxY,
        gridData: const FlGridData(show: false),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          enabled: true,
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            tooltipRoundedRadius: 10,
            getTooltipItem: (group, _, rod, __) {
              return BarTooltipItem(
                '${rod.toY.toInt()} ml',
                TextStyle(
                  color: scheme.onInverseSurface,
                  fontWeight: FontWeight.w600,
                ),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              interval: compact ? 5 : 1,
              getTitlesWidget: (value, _) {
                final i = value.toInt();
                if (i < 0 || i >= days.length) return const SizedBox.shrink();
                if (compact && i % 5 != 0 && i != days.length - 1) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    compact
                        ? DateFormat.d().format(days[i])
                        : DateFormat.E().format(days[i]),
                    style: TextStyle(
                      color: scheme.onSurfaceVariant,
                      fontSize: 11,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        extraLinesData: ExtraLinesData(
          horizontalLines: [
            HorizontalLine(
              y: goal.toDouble(),
              color: scheme.tertiary.withOpacity(0.6),
              strokeWidth: 2,
              dashArray: [6, 4],
            ),
          ],
        ),
        barGroups: [
          for (int i = 0; i < values.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: values[i].toDouble(),
                  width: compact ? 6 : 16,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(8),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: values[i] >= goal
                        ? [
                            scheme.tertiary,
                            scheme.primary,
                          ]
                        : [
                            scheme.primary.withOpacity(0.4),
                            scheme.primary,
                          ],
                  ),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: maxY,
                    color: scheme.surfaceContainerHigh
                        .withOpacity(0.4),
                  ),
                ),
              ],
            ),
        ],
      ),
      duration: const Duration(milliseconds: 600),
      curve: AppCurves.emphasizedDecelerate,
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({
    required this.date,
    required this.totalMl,
    required this.goalMl,
  });

  final DateTime date;
  final int totalMl;
  final int goalMl;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final pct = goalMl == 0 ? 0.0 : (totalMl / goalMl).clamp(0.0, 1.0);
    final reached = totalMl >= goalMl;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerHighest.withOpacity(0.55),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: scheme.outlineVariant.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat.MMMEd().format(date),
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Row(
                  children: [
                    if (reached)
                      Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: Icon(
                          Icons.check_circle,
                          size: 16,
                          color: scheme.tertiary,
                        ),
                      ),
                    Text(
                      '$totalMl / $goalMl ml',
                      style: TextStyle(
                        color: reached
                            ? scheme.tertiary
                            : scheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Stack(
                children: [
                  Container(
                    height: 8,
                    color: scheme.surfaceContainerHigh,
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: pct),
                    duration: AppDurations.lg,
                    curve: AppCurves.emphasizedDecelerate,
                    builder: (context, value, _) {
                      return FractionallySizedBox(
                        widthFactor: value,
                        child: Container(
                          height: 8,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: reached
                                  ? [scheme.tertiary, scheme.primary]
                                  : [
                                      scheme.primary.withOpacity(0.7),
                                      scheme.primary,
                                    ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
