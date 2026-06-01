class AppBoxes {
  AppBoxes._();
  static const String entries = 'water_entries';
  static const String settings = 'app_settings';
}

class SettingsKeys {
  SettingsKeys._();
  static const String dailyGoalMl = 'daily_goal_ml';
  static const String themeMode = 'theme_mode';
  static const String remindersEnabled = 'reminders_enabled';
  static const String reminderIntervalHours = 'reminder_interval_hours';
  static const String notificationSound = 'notification_sound';
}

class AppDefaults {
  AppDefaults._();
  static const int dailyGoalMl = 2000;
  static const int reminderIntervalHours = 2;
  static const List<int> quickAddAmounts = [100, 250, 500];
}
