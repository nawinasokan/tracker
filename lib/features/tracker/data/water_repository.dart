import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

import '../../../core/constants.dart';
import '../../../core/utils/date_utils.dart';
import 'water_entry.dart';

class WaterRepository {
  WaterRepository(this._box);

  final Box<WaterEntry> _box;
  static const _uuid = Uuid();

  Stream<List<WaterEntry>> watchAll() async* {
    yield _all();
    yield* _box.watch().map((_) => _all());
  }

  List<WaterEntry> _all() {
    final list = _box.values.toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return list;
  }

  List<WaterEntry> entriesForDay(DateTime day) {
    return _box.values
        .where((e) => e.timestamp.isSameDay(day))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  int totalForDay(DateTime day) =>
      entriesForDay(day).fold(0, (sum, e) => sum + e.amountMl);

  Future<WaterEntry> addEntry(int amountMl, {DateTime? at}) async {
    final entry = WaterEntry(
      id: _uuid.v4(),
      amountMl: amountMl,
      timestamp: at ?? DateTime.now(),
    );
    await _box.put(entry.id, entry);
    return entry;
  }

  Future<void> deleteEntry(String id) => _box.delete(id);

  Future<void> clearAll() => _box.clear();
}

WaterRepository createWaterRepository() {
  final box = Hive.box<WaterEntry>(AppBoxes.entries);
  return WaterRepository(box);
}
