import 'package:hive/hive.dart';

class WaterEntry {
  WaterEntry({
    required this.id,
    required this.amountMl,
    required this.timestamp,
  });

  final String id;
  final int amountMl;
  final DateTime timestamp;

  WaterEntry copyWith({String? id, int? amountMl, DateTime? timestamp}) =>
      WaterEntry(
        id: id ?? this.id,
        amountMl: amountMl ?? this.amountMl,
        timestamp: timestamp ?? this.timestamp,
      );
}

class WaterEntryAdapter extends TypeAdapter<WaterEntry> {
  @override
  final int typeId = 0;

  @override
  WaterEntry read(BinaryReader reader) {
    final id = reader.readString();
    final amountMl = reader.readInt();
    final ts = reader.readInt();
    return WaterEntry(
      id: id,
      amountMl: amountMl,
      timestamp: DateTime.fromMillisecondsSinceEpoch(ts),
    );
  }

  @override
  void write(BinaryWriter writer, WaterEntry obj) {
    writer.writeString(obj.id);
    writer.writeInt(obj.amountMl);
    writer.writeInt(obj.timestamp.millisecondsSinceEpoch);
  }
}
