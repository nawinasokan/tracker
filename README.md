# Water Tracker

A production-style Flutter app that tracks daily water intake.

## Features
- Quick-add 100 ml / 250 ml / 500 ml + custom amount
- Daily goal with progress ring
- Today's history (swipe to delete)
- Local persistence with Hive
- 7-day analytics with bar chart
- Light / Dark / System theme
- Hydration reminders (Android local notifications)
- Material 3 UI, Android-first, iOS-compatible

## Tech Stack
| Layer | Choice |
|---|---|
| Language | Dart 3 |
| Framework | Flutter (stable) |
| State | Riverpod v2 (`StateNotifier`, `StreamProvider`) |
| Storage | Hive (manual `TypeAdapter`, no codegen) |
| Routing | go_router (shell route + bottom nav) |
| Charts | fl_chart |
| Notifications | flutter_local_notifications + timezone |

## Project Structure
```
lib/
├── main.dart                       # Entry: init Hive, notifications, app
├── app/
│   ├── app.dart                    # MaterialApp.router root
│   ├── router.dart                 # go_router + shell with bottom nav
│   └── theme.dart                  # Material 3 light/dark themes
├── core/
│   ├── constants.dart              # Box names, defaults
│   └── utils/date_utils.dart       # Date helpers
└── features/
    ├── tracker/
    │   ├── data/                   # WaterEntry model + repository
    │   ├── domain/                 # DailySummary value object
    │   ├── providers/              # Riverpod providers
    │   └── presentation/           # HomeScreen + widgets
    ├── settings/
    │   ├── data/                   # Settings repository (Hive-backed)
    │   ├── providers/              # Theme, goal, reminders controllers
    │   └── presentation/           # SettingsScreen
    ├── analytics/
    │   └── presentation/           # AnalyticsScreen with weekly chart
    └── notifications/
        └── notification_service.dart
```

## First-time Setup

These source files were created standalone. You still need Flutter to scaffold the native Android/iOS wrappers.

```bash
# 1. Install Flutter (see Phase 1 instructions)
flutter doctor

# 2. From inside this project folder, generate native + config scaffolding
#    (this will NOT overwrite lib/, pubspec.yaml, analysis_options.yaml)
flutter create --org com.mnxw --project-name water_tracker .

# 3. Install dependencies
flutter pub get

# 4. Run
flutter run
```

### Android — required manifest tweaks

After `flutter create`, edit `android/app/src/main/AndroidManifest.xml` and add inside the `<manifest>` tag (before `<application>`):

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS" />
<uses-permission android:name="android.permission.SCHEDULE_EXACT_ALARM" />
<uses-permission android:name="android.permission.USE_EXACT_ALARM" />
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED" />
<uses-permission android:name="android.permission.VIBRATE" />
```

Inside `<application>` add (for scheduled notifications):
```xml
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationReceiver" />
<receiver android:exported="false" android:name="com.dexterous.flutterlocalnotifications.ScheduledNotificationBootReceiver">
  <intent-filter>
    <action android:name="android.intent.action.BOOT_COMPLETED" />
  </intent-filter>
</receiver>
```

Set minimum SDK to 21 in `android/app/build.gradle`:
```gradle
defaultConfig {
    minSdkVersion 21
    ...
}
```

### iOS — optional

In `ios/Runner/Info.plist` add:
```xml
<key>UIBackgroundModes</key>
<array>
  <string>fetch</string>
</array>
```

## Building Release APK
```bash
flutter build apk --release
# Output: build/app/outputs/flutter-apk/app-release.apk
```

## Architecture Notes
- **Repository pattern**: `WaterRepository` / `SettingsRepository` hide Hive — UI never imports Hive directly.
- **Reactive UI**: `StreamProvider` watches the Hive box and rebuilds widgets automatically when entries change.
- **No codegen**: `WaterEntryAdapter` is hand-written so you don't need `build_runner`.
- **Theme persistence**: theme mode is stored in Hive and exposed via `themeModeProvider`.
- **Notification scheduling**: simple daily fixed-time slots between 08:00 and 22:00 spaced by the chosen interval.
