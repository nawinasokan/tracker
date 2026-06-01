import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/notification_service.dart';
import '../../notifications/reminder_sound.dart';
import '../data/settings_repository.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return createSettingsRepository();
});

class ThemeModeController extends StateNotifier<ThemeMode> {
  ThemeModeController(this._repo) : super(_repo.getThemeMode());

  final SettingsRepository _repo;

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _repo.setThemeMode(mode);
  }
}

final themeModeProvider =
    StateNotifierProvider<ThemeModeController, ThemeMode>((ref) {
  return ThemeModeController(ref.watch(settingsRepositoryProvider));
});

class DailyGoalController extends StateNotifier<int> {
  DailyGoalController(this._repo) : super(_repo.getDailyGoalMl());

  final SettingsRepository _repo;

  Future<void> set(int ml) async {
    state = ml;
    await _repo.setDailyGoalMl(ml);
  }
}

final dailyGoalProvider =
    StateNotifierProvider<DailyGoalController, int>((ref) {
  return DailyGoalController(ref.watch(settingsRepositoryProvider));
});

class RemindersController extends StateNotifier<RemindersState> {
  RemindersController(this._repo)
      : super(
          RemindersState(
            enabled: _repo.getRemindersEnabled(),
            intervalHours: _repo.getReminderIntervalHours(),
            sound: _repo.getNotificationSound(),
          ),
        );

  final SettingsRepository _repo;

  /// Enables/disables reminders. Returns the outcome so the UI can react —
  /// anything other than [ReminderResult.scheduled] means the toggle was kept
  /// off (e.g. notification permission denied).
  Future<ReminderResult> setEnabled(bool enabled) async {
    final svc = NotificationService.instance;
    if (enabled) {
      final result = await svc.scheduleRepeatingReminder(
        intervalHours: state.intervalHours,
        sound: state.sound,
      );
      if (result != ReminderResult.scheduled) {
        // Couldn't schedule (permission denied / error) — keep the toggle off
        // so the UI stays honest.
        state = state.copyWith(enabled: false);
        await _repo.setRemindersEnabled(false);
        return result;
      }
      // Flip + persist first; the confirmation ping is best-effort and must
      // not be able to revert the switch if it throws.
      state = state.copyWith(enabled: true);
      await _repo.setRemindersEnabled(true);
      await svc.showConfirmation(state.intervalHours, state.sound);
      return ReminderResult.scheduled;
    }

    try {
      await svc.cancelAll();
    } catch (e) {
      if (kDebugMode) debugPrint('Failed to cancel reminders: $e');
    }
    state = state.copyWith(enabled: false);
    await _repo.setRemindersEnabled(false);
    return ReminderResult.scheduled;
  }

  /// Opens system settings so the user can grant notification permission
  /// after a denial.
  Future<void> openSystemSettings() =>
      NotificationService.instance.openSettings();

  /// Updates the interval. If reminders are on, reschedules them and returns
  /// the outcome — on failure the toggle is flipped off so the UI stays honest.
  Future<ReminderResult> setIntervalHours(int hours) async {
    state = state.copyWith(intervalHours: hours);
    await _repo.setReminderIntervalHours(hours);
    if (!state.enabled) return ReminderResult.scheduled;

    final result = await NotificationService.instance.scheduleRepeatingReminder(
      intervalHours: hours,
      sound: state.sound,
    );
    if (result != ReminderResult.scheduled) {
      state = state.copyWith(enabled: false);
      await _repo.setRemindersEnabled(false);
    }
    return result;
  }

  /// Updates the reminder sound and previews it. If reminders are on, the
  /// active reminders are rescheduled onto the new sound's channel; on failure
  /// the toggle is flipped off so the UI stays honest.
  Future<ReminderResult> setSound(ReminderSound sound) async {
    state = state.copyWith(sound: sound);
    await _repo.setNotificationSound(sound);

    final svc = NotificationService.instance;
    if (!state.enabled) {
      // Nothing scheduled — just let the user hear their pick.
      await svc.previewSound(sound);
      return ReminderResult.scheduled;
    }

    final result = await svc.scheduleRepeatingReminder(
      intervalHours: state.intervalHours,
      sound: sound,
    );
    if (result != ReminderResult.scheduled) {
      state = state.copyWith(enabled: false);
      await _repo.setRemindersEnabled(false);
    } else {
      await svc.previewSound(sound);
    }
    return result;
  }
}

class RemindersState {
  const RemindersState({
    required this.enabled,
    required this.intervalHours,
    required this.sound,
  });

  final bool enabled;
  final int intervalHours;
  final ReminderSound sound;

  RemindersState copyWith({
    bool? enabled,
    int? intervalHours,
    ReminderSound? sound,
  }) =>
      RemindersState(
        enabled: enabled ?? this.enabled,
        intervalHours: intervalHours ?? this.intervalHours,
        sound: sound ?? this.sound,
      );
}

final remindersProvider =
    StateNotifierProvider<RemindersController, RemindersState>((ref) {
  return RemindersController(ref.watch(settingsRepositoryProvider));
});
