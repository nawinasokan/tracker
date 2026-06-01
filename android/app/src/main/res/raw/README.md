# Notification sounds

These files back the in-app "Notification sound" picker (Settings → Reminders).

- `droplet.wav`, `chime.wav`, `bell.wav` — referenced from Dart by their
  **resource name** (filename without extension), e.g. `RawResourceAndroidNotificationSound('droplet')`.

To replace a sound, drop in a new file with the **same name** (e.g. `droplet.wav`).
Constraints for Android `res/raw` resources:

- Filename must be lowercase, using only letters, digits and `_`.
- Keep clips short (≈ ≤ 3 s) — Android truncates long notification sounds.
- `.wav`, `.ogg` and `.mp3` all work.

To add a *new* option, also add an entry to `ReminderSound`
(`lib/features/notifications/reminder_sound.dart`).
