import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../settings/providers/settings_providers.dart';
import '../data/water_entry.dart';
import '../data/water_repository.dart';
import '../domain/daily_summary.dart';

final waterRepositoryProvider = Provider<WaterRepository>((ref) {
  return createWaterRepository();
});

final allEntriesProvider = StreamProvider<List<WaterEntry>>((ref) {
  return ref.watch(waterRepositoryProvider).watchAll();
});

final todaySummaryProvider = Provider<DailySummary>((ref) {
  final entries = ref.watch(allEntriesProvider).valueOrNull ?? const [];
  final goal = ref.watch(dailyGoalProvider);
  final today = DateTime.now();
  final todayEntries = entries
      .where((e) =>
          e.timestamp.year == today.year &&
          e.timestamp.month == today.month &&
          e.timestamp.day == today.day)
      .toList();
  final total = todayEntries.fold<int>(0, (sum, e) => sum + e.amountMl);

  return DailySummary(
    date: DateTime(today.year, today.month, today.day),
    totalMl: total,
    goalMl: goal,
    entries: todayEntries,
  );
});
