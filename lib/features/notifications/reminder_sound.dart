/// A selectable sound for hydration reminders.
///
/// On Android 8+ a notification's sound is bound to its **channel**, and a
/// channel's sound is immutable once the channel is created. So each option
/// maps to its own stable [channelId]: switching sound means scheduling on a
/// different channel rather than mutating one. Each [channelId] always carries
/// the same sound, which keeps deletion/recreation safe (Android restores a
/// recreated channel's previous settings — identical to what we'd set anyway).
enum ReminderSound {
  /// The device's default notification sound.
  defaultSound(
    id: 'default',
    label: 'Default',
    channelId: 'water_reminders',
    androidResource: null,
    iosFile: null,
  ),
  droplet(
    id: 'droplet',
    label: 'Droplet',
    channelId: 'water_reminders_droplet',
    androidResource: 'droplet',
    iosFile: 'droplet.wav',
  ),
  chime(
    id: 'chime',
    label: 'Chime',
    channelId: 'water_reminders_chime',
    androidResource: 'chime',
    iosFile: 'chime.wav',
  ),
  bell(
    id: 'bell',
    label: 'Bell',
    channelId: 'water_reminders_bell',
    androidResource: 'bell',
    iosFile: 'bell.wav',
  ),

  /// No sound — the notification still appears, just silently.
  silent(
    id: 'silent',
    label: 'Silent',
    channelId: 'water_reminders_silent',
    androidResource: null,
    iosFile: null,
  );

  const ReminderSound({
    required this.id,
    required this.label,
    required this.channelId,
    required this.androidResource,
    required this.iosFile,
  });

  /// Stable identifier persisted in settings (decoupled from enum order).
  final String id;

  /// Human-readable label shown in the picker.
  final String label;

  /// Android notification channel id that carries this sound.
  final String channelId;

  /// `res/raw` resource name (no extension), or null to use the OS default.
  final String? androidResource;

  /// iOS bundle sound filename (with extension), or null for the OS default.
  final String? iosFile;

  bool get isSilent => this == ReminderSound.silent;

  /// Resolves a persisted [id] back to an enum value, defaulting to
  /// [ReminderSound.defaultSound] for unknown/legacy values.
  static ReminderSound fromId(String? id) => ReminderSound.values.firstWhere(
        (s) => s.id == id,
        orElse: () => ReminderSound.defaultSound,
      );
}
