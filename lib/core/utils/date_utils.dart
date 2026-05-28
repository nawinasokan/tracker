extension DateOnly on DateTime {
  DateTime get dayStart => DateTime(year, month, day);
  DateTime get dayEnd => DateTime(year, month, day, 23, 59, 59, 999);

  bool isSameDay(DateTime other) =>
      year == other.year && month == other.month && day == other.day;
}

List<DateTime> lastNDays(int n) {
  final today = DateTime.now().dayStart;
  return List.generate(n, (i) => today.subtract(Duration(days: n - 1 - i)));
}
