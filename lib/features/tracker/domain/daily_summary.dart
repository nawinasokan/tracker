import '../data/water_entry.dart';

class DailySummary {
  const DailySummary({
    required this.date,
    required this.totalMl,
    required this.goalMl,
    required this.entries,
  });

  final DateTime date;
  final int totalMl;
  final int goalMl;
  final List<WaterEntry> entries;

  double get progress => goalMl == 0 ? 0 : (totalMl / goalMl).clamp(0, 1);
  int get remainingMl => (goalMl - totalMl).clamp(0, goalMl);
  bool get goalReached => totalMl >= goalMl;
}
