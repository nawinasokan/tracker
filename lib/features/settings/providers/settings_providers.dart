import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../notifications/notification_service.dart';
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
          ),
        );

  final SettingsRepository _repo;

  Future<void> setEnabled(bool enabled) async {
    state = state.copyWith(enabled: enabled);
    await _repo.setRemindersEnabled(enabled);
    await _syncSchedule();
  }

  Future<void> setIntervalHours(int hours) async {
    state = state.copyWith(intervalHours: hours);
    await _repo.setReminderIntervalHours(hours);
    if (state.enabled) await _syncSchedule();
  }

  Future<void> _syncSchedule() async {
    final svc = NotificationService.instance;
    if (state.enabled) {
      await svc.scheduleRepeatingReminder(intervalHours: state.intervalHours);
    } else {
      await svc.cancelAll();
    }
  }
}

class RemindersState {
  const RemindersState({required this.enabled, required this.intervalHours});

  final bool enabled;
  final int intervalHours;

  RemindersState copyWith({bool? enabled, int? intervalHours}) =>
      RemindersState(
        enabled: enabled ?? this.enabled,
        intervalHours: intervalHours ?? this.intervalHours,
      );
}

final remindersProvider =
    StateNotifierProvider<RemindersController, RemindersState>((ref) {
  return RemindersController(ref.watch(settingsRepositoryProvider));
});
