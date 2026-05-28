import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'water_reminders';
  static const _channelName = 'Hydration reminders';
  static const _channelDescription = 'Reminders to drink water throughout the day';

  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    tz.initializeTimeZones();

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );
    _initialized = true;
  }

  Future<bool> requestPermissions() async {
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  Future<void> scheduleRepeatingReminder({required int intervalHours}) async {
    await cancelAll();
    final granted = await requestPermissions();
    if (!granted) {
      if (kDebugMode) debugPrint('Notification permission denied');
      return;
    }

    final now = tz.TZDateTime.now(tz.local);
    var first = tz.TZDateTime(tz.local, now.year, now.month, now.day, 8);
    if (first.isBefore(now)) {
      first = first.add(Duration(hours: intervalHours));
    }

    const lastHourOfDay = 22;
    var scheduledId = 0;
    var current = first;
    while (current.hour <= lastHourOfDay && scheduledId < 24) {
      await _plugin.zonedSchedule(
        scheduledId,
        'Time to hydrate',
        'Take a sip — your body will thank you.',
        current,
        _notificationDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
      scheduledId++;
      current = current.add(Duration(hours: intervalHours));
    }
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  NotificationDetails _notificationDetails() => const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: DarwinNotificationDetails(),
      );
}
