import 'package:flutter/material.dart';
import 'package:hive/hive.dart';

import '../../../core/constants.dart';
import '../../notifications/reminder_sound.dart';

class SettingsRepository {
  SettingsRepository(this._box);

  final Box<dynamic> _box;

  int getDailyGoalMl() =>
      _box.get(SettingsKeys.dailyGoalMl, defaultValue: AppDefaults.dailyGoalMl)
          as int;

  Future<void> setDailyGoalMl(int value) =>
      _box.put(SettingsKeys.dailyGoalMl, value);

  ThemeMode getThemeMode() {
    final raw = _box.get(SettingsKeys.themeMode, defaultValue: 'system') as String;
    return switch (raw) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };
  }

  Future<void> setThemeMode(ThemeMode mode) =>
      _box.put(SettingsKeys.themeMode, mode.name);

  bool getRemindersEnabled() =>
      _box.get(SettingsKeys.remindersEnabled, defaultValue: false) as bool;

  Future<void> setRemindersEnabled(bool value) =>
      _box.put(SettingsKeys.remindersEnabled, value);

  int getReminderIntervalHours() => _box.get(
        SettingsKeys.reminderIntervalHours,
        defaultValue: AppDefaults.reminderIntervalHours,
      ) as int;

  Future<void> setReminderIntervalHours(int value) =>
      _box.put(SettingsKeys.reminderIntervalHours, value);

  ReminderSound getNotificationSound() => ReminderSound.fromId(
        _box.get(SettingsKeys.notificationSound) as String?,
      );

  Future<void> setNotificationSound(ReminderSound sound) =>
      _box.put(SettingsKeys.notificationSound, sound.id);
}

SettingsRepository createSettingsRepository() {
  final box = Hive.box<dynamic>(AppBoxes.settings);
  return SettingsRepository(box);
}
