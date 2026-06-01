import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'reminder_sound.dart';

/// Outcome of trying to enable reminders.
enum ReminderResult {
  /// Reminders were scheduled successfully.
  scheduled,

  /// Notifications are not allowed for the app.
  permissionDenied,

  /// Scheduling failed for another (usually transient) reason.
  failed,
}

class NotificationService {
  NotificationService._();
  static final instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const _channelName = 'Hydration reminders';
  static const _channelDescription =
      'Reminders to drink water throughout the day';

  // Active reminder window (24h clock).
  static const _startHour = 8;
  static const _endHour = 22;

  bool _initialized = false;

  /// Detail of the most recent scheduling failure, surfaced to the user when
  /// reminders can't be set. Null after a successful attempt.
  String? lastError;

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

  Future<void> init() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    // tz.local defaults to UTC — set it to the device timezone so reminders
    // fire at the correct local clock time.
    try {
      final name = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(name));
    } catch (e) {
      if (kDebugMode) debugPrint('Could not resolve local timezone: $e');
    }

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      const InitializationSettings(android: androidInit, iOS: iosInit),
    );

    // Channels are created per selected sound just before scheduling
    // (see [_ensureChannel]) — a channel's sound is immutable once created, so
    // we can't pre-create a single shared channel here.

    _initialized = true;
  }

  /// Requests notification + exact-alarm permissions. Returns whether
  /// notifications are allowed.
  ///
  /// On Android we trust the notification plugin's *own* check
  /// ([AndroidFlutterLocalNotificationsPlugin.areNotificationsEnabled]) rather
  /// than `permission_handler`, because the latter reports notifications as
  /// denied on some OEM skins (MIUI / HyperOS) even when they are enabled —
  /// which would wrongly block reminders.
  Future<bool> requestPermissions() async {
    final android = _android;
    if (android != null) {
      var granted = await android.areNotificationsEnabled() ?? false;
      if (!granted) {
        try {
          granted = await android.requestNotificationsPermission() ?? false;
        } on PlatformException catch (e) {
          // e.g. a request already in flight — fall back to the current OS
          // state rather than reporting a hard failure.
          if (kDebugMode) debugPrint('Notification permission request: $e');
          granted = await android.areNotificationsEnabled() ?? false;
        }
      }
      if (!granted) {
        // Last-resort fallback (older OS versions where the native request is
        // a no-op).
        try {
          granted = (await Permission.notification.request()).isGranted;
        } catch (_) {/* unsupported platform — ignore */}
      }
      if (!granted) return false;

      // Exact alarms (Android 12+). Best-effort: if unavailable we fall back to
      // inexact scheduling rather than blocking reminders entirely.
      try {
        final canExact = await android.canScheduleExactNotifications() ?? true;
        if (!canExact) {
          await android.requestExactAlarmsPermission();
        }
      } catch (e) {
        if (kDebugMode) debugPrint('Exact alarm permission request failed: $e');
      }
      return true;
    }

    // iOS / macOS.
    final ios = _plugin.resolvePlatformSpecificImplementation<
        IOSFlutterLocalNotificationsPlugin>();
    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    // Other platforms (desktop / web) — best-effort.
    try {
      return (await Permission.notification.request()).isGranted;
    } catch (_) {
      return true;
    }
  }

  /// Schedules daily-repeating reminders every [intervalHours] within the
  /// active window, playing [sound] on each reminder.
  Future<ReminderResult> scheduleRepeatingReminder({
    required int intervalHours,
    required ReminderSound sound,
  }) async {
    lastError = null;

    final bool granted;
    try {
      granted = await requestPermissions();
    } catch (e) {
      lastError = _describeError(e);
      if (kDebugMode) debugPrint('Permission request failed: $e');
      return ReminderResult.failed;
    }
    if (!granted) {
      if (kDebugMode) debugPrint('Notification permission denied');
      return ReminderResult.permissionDenied;
    }

    // Clear previously scheduled reminders only once we know we can
    // reschedule — so a denied/failed attempt never wipes working alarms.
    try {
      await cancelAll();
    } catch (_) {/* best-effort */}

    // Make sure the channel carrying the chosen sound exists (and tidy away
    // the channels for the other sounds).
    await _ensureChannel(sound, cleanup: true);

    final canExact = await _canScheduleExact();

    // Try the best available mode first; on ANY failure of an exact-mode
    // attempt, fall back to inexact alarms (covers exact-alarm rejection and
    // other exact-mode quirks seen on restrictive OEMs like MIUI/HyperOS).
    try {
      await _scheduleWindow(
        intervalHours: intervalHours,
        exact: canExact,
        sound: sound,
      );
      return ReminderResult.scheduled;
    } catch (e, st) {
      if (kDebugMode) debugPrint('Schedule (exact=$canExact) failed: $e\n$st');
      if (canExact) {
        try {
          await cancelAll();
          await _scheduleWindow(
            intervalHours: intervalHours,
            exact: false,
            sound: sound,
          );
          return ReminderResult.scheduled;
        } catch (e2, st2) {
          lastError = _describeError(e2);
          if (kDebugMode) debugPrint('Inexact reschedule failed: $e2\n$st2');
          return ReminderResult.failed;
        }
      }
      lastError = _describeError(e);
      return ReminderResult.failed;
    }
  }

  String _describeError(Object e) => e is PlatformException
      ? 'code=${e.code}${e.message != null ? ' — ${e.message}' : ''}'
      : e.toString();

  Future<bool> _canScheduleExact() async {
    try {
      return await _android?.canScheduleExactNotifications() ?? true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _scheduleWindow({
    required int intervalHours,
    required bool exact,
    required ReminderSound sound,
  }) async {
    final mode = exact
        ? AndroidScheduleMode.exactAllowWhileIdle
        : AndroidScheduleMode.inexactAllowWhileIdle;

    var id = 0;
    for (int hour = _startHour; hour <= _endHour; hour += intervalHours) {
      await _plugin.zonedSchedule(
        id++,
        'Time to hydrate 💧',
        'Take a sip — your body will thank you.',
        _nextInstanceOfHour(hour),
        _notificationDetails(sound),
        androidScheduleMode: mode,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.time,
      );
    }
  }

  /// Shows an immediate notification (used to confirm reminders are working).
  Future<void> showConfirmation(int intervalHours, ReminderSound sound) async {
    try {
      await _plugin.show(
        9999,
        'Reminders on 💧',
        'We\'ll nudge you every $intervalHours hour'
            '${intervalHours == 1 ? '' : 's'} from $_startHour:00–$_endHour:00.',
        _notificationDetails(sound),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Could not show confirmation: $e');
    }
  }

  /// Plays a one-off notification so the user can audition [sound] from the
  /// picker. Best-effort — never throws to the caller.
  Future<void> previewSound(ReminderSound sound) async {
    try {
      await _ensureChannel(sound, cleanup: false);
      await _plugin.show(
        9998,
        'Notification sound',
        '${sound.label} — this is how reminders will sound.',
        _notificationDetails(sound),
      );
    } catch (e) {
      if (kDebugMode) debugPrint('Could not preview sound: $e');
    }
  }

  tz.TZDateTime _nextInstanceOfHour(int hour) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour);
    if (!scheduled.isAfter(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }
    return scheduled;
  }

  Future<void> cancelAll() => _plugin.cancelAll();

  /// Opens the OS app-settings screen so the user can re-enable notifications
  /// they previously denied (Android will not re-prompt after a denial).
  Future<void> openSettings() => openAppSettings();

  /// Creates the notification channel that carries [sound]'s audio. When
  /// [cleanup] is set, also deletes the channels belonging to the *other*
  /// sounds so they don't clutter the system notification-settings list.
  Future<void> _ensureChannel(
    ReminderSound sound, {
    required bool cleanup,
  }) async {
    final android = _android;
    if (android == null) return;

    if (cleanup) {
      for (final other in ReminderSound.values) {
        if (other == sound) continue;
        try {
          await android.deleteNotificationChannel(other.channelId);
        } catch (_) {/* best-effort */}
      }
    }

    await android.createNotificationChannel(
      AndroidNotificationChannel(
        sound.channelId,
        _channelName,
        description: _channelDescription,
        importance: Importance.high,
        playSound: !sound.isSilent,
        sound: sound.androidResource != null
            ? RawResourceAndroidNotificationSound(sound.androidResource!)
            : null,
      ),
    );
  }

  NotificationDetails _notificationDetails(ReminderSound sound) =>
      NotificationDetails(
        android: AndroidNotificationDetails(
          sound.channelId,
          _channelName,
          channelDescription: _channelDescription,
          importance: Importance.high,
          priority: Priority.high,
          playSound: !sound.isSilent,
          sound: sound.androidResource != null
              ? RawResourceAndroidNotificationSound(sound.androidResource!)
              : null,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: !sound.isSilent,
          sound: sound.iosFile,
        ),
      );
}
