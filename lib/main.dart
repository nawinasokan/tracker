import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'core/constants.dart';
import 'features/notifications/notification_service.dart';
import 'features/tracker/data/water_entry.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();
  Hive.registerAdapter(WaterEntryAdapter());
  await Hive.openBox<WaterEntry>(AppBoxes.entries);
  await Hive.openBox<dynamic>(AppBoxes.settings);

  await NotificationService.instance.init();

  runApp(const ProviderScope(child: WaterTrackerApp()));
}
