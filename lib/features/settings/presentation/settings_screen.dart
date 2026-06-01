import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/motion.dart';
import '../../../app/widgets/animated_counter.dart';
import '../../../app/widgets/pressable_scale.dart';
import '../../../app/widgets/slide_fade_in.dart';
import '../../notifications/notification_service.dart';
import '../../tracker/providers/tracker_providers.dart';
import '../providers/settings_providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final goal = ref.watch(dailyGoalProvider);
    final reminders = ref.watch(remindersProvider);

    return SafeArea(
      bottom: false,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          const SliverAppBar(pinned: true, title: Text('Settings')),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                SlideFadeIn(
                  index: 0,
                  child: _SectionCard(
                    title: 'Goal',
                    children: [
                      _GoalTile(
                        goal: goal,
                        onTap: () async {
                          final value = await _showGoalSheet(context, goal);
                          if (value != null) {
                            await ref
                                .read(dailyGoalProvider.notifier)
                                .set(value);
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SlideFadeIn(
                  index: 1,
                  child: _SectionCard(
                    title: 'Appearance',
                    children: [
                      _ThemeSelector(
                        current: themeMode,
                        onChange: (m) =>
                            ref.read(themeModeProvider.notifier).set(m),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SlideFadeIn(
                  index: 2,
                  child: _SectionCard(
                    title: 'Reminders',
                    children: [
                      _ReminderToggle(
                        enabled: reminders.enabled,
                        onChanged: (v) async {
                          final result = await ref
                              .read(remindersProvider.notifier)
                              .setEnabled(v);
                          if (v && context.mounted) {
                            _showReminderError(context, ref, result);
                          }
                        },
                      ),
                      _Divider(),
                      _IntervalTile(
                        hours: reminders.intervalHours,
                        enabled: reminders.enabled,
                        onTap: () async {
                          final hours = await _showIntervalSheet(
                            context,
                            reminders.intervalHours,
                          );
                          if (hours != null) {
                            final result = await ref
                                .read(remindersProvider.notifier)
                                .setIntervalHours(hours);
                            if (context.mounted) {
                              _showReminderError(context, ref, result);
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SlideFadeIn(
                  index: 3,
                  child: _SectionCard(
                    title: 'Data',
                    children: [
                      _DangerTile(
                        onTap: () async {
                          final confirmed = await _confirmClear(context);
                          if (confirmed == true) {
                            await ref
                                .read(waterRepositoryProvider)
                                .clearAll();
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(6, 0, 0, 8),
          child: Text(
            title.toUpperCase(),
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: scheme.primary,
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: scheme.surfaceContainerHighest.withOpacity(0.55),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: scheme.outlineVariant.withOpacity(0.35),
            ),
          ),
          child: Column(children: children),
        ),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Divider(
        height: 1,
        color:
            Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
      ),
    );
  }
}

class _GoalTile extends StatelessWidget {
  const _GoalTile({required this.goal, required this.onTap});

  final int goal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    scheme.primary.withOpacity(0.2),
                    scheme.tertiary.withOpacity(0.12),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.flag_outlined, color: scheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Daily goal',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  AnimatedCounter(
                    value: goal,
                    suffix: ' ml',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class _ThemeSelector extends StatelessWidget {
  const _ThemeSelector({required this.current, required this.onChange});

  final ThemeMode current;
  final ValueChanged<ThemeMode> onChange;

  static const _options = [
    (ThemeMode.system, 'System', Icons.brightness_auto_outlined),
    (ThemeMode.light, 'Light', Icons.light_mode_outlined),
    (ThemeMode.dark, 'Dark', Icons.dark_mode_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          for (int i = 0; i < _options.length; i++) ...[
            Expanded(
              child: PressableScale(
                onTap: () => onChange(_options[i].$1),
                child: AnimatedContainer(
                  duration: AppDurations.sm,
                  curve: AppCurves.emphasized,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: current == _options[i].$1
                        ? scheme.primaryContainer
                        : scheme.surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: current == _options[i].$1
                          ? scheme.primary.withOpacity(0.6)
                          : scheme.outlineVariant.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        _options[i].$3,
                        color: current == _options[i].$1
                            ? scheme.onPrimaryContainer
                            : scheme.onSurfaceVariant,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _options[i].$2,
                        style: TextStyle(
                          color: current == _options[i].$1
                              ? scheme.onPrimaryContainer
                              : scheme.onSurface,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (i < _options.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _ReminderToggle extends StatelessWidget {
  const _ReminderToggle({required this.enabled, required this.onChanged});

  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: AppDurations.sm,
      color: enabled
          ? scheme.primaryContainer.withOpacity(0.12)
          : Colors.transparent,
      child: SwitchListTile.adaptive(
        secondary: Icon(
          enabled
              ? Icons.notifications_active_outlined
              : Icons.notifications_outlined,
          color: enabled ? scheme.primary : scheme.onSurfaceVariant,
        ),
        title: const Text(
          'Hydration reminders',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: const Text('Gentle reminders throughout the day'),
        value: enabled,
        onChanged: (v) {
          HapticFeedback.lightImpact();
          onChanged(v);
        },
      ),
    );
  }
}

class _IntervalTile extends StatelessWidget {
  const _IntervalTile({
    required this.hours,
    required this.enabled,
    required this.onTap,
  });

  final int hours;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: ListTile(
        leading: Icon(Icons.schedule, color: scheme.onSurfaceVariant),
        title: const Text(
          'Interval',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text('Every $hours hour${hours == 1 ? '' : 's'}'),
        trailing: Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
        enabled: enabled,
        onTap: enabled ? onTap : null,
      ),
    );
  }
}

class _DangerTile extends StatelessWidget {
  const _DangerTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(Icons.delete_forever_outlined, color: scheme.error),
      title: Text(
        'Clear all entries',
        style: TextStyle(
          color: scheme.error,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: const Text('Permanently delete all logged water'),
      onTap: onTap,
    );
  }
}

/// Surfaces a SnackBar when enabling/rescheduling reminders didn't succeed.
/// No-op on success.
void _showReminderError(
  BuildContext context,
  WidgetRef ref,
  ReminderResult result,
) {
  if (result == ReminderResult.scheduled) return;
  final denied = result == ReminderResult.permissionDenied;
  final detail = NotificationService.instance.lastError;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      duration:
          denied ? const Duration(seconds: 4) : const Duration(seconds: 12),
      content: Text(
        denied
            ? 'Allow notifications to receive reminders.'
            : detail != null
                ? 'Couldn\'t set reminders:\n$detail'
                : 'Couldn\'t set reminders. Please try again.',
      ),
      action: denied
          ? SnackBarAction(
              label: 'Settings',
              onPressed: () =>
                  ref.read(remindersProvider.notifier).openSystemSettings(),
            )
          : null,
    ),
  );
}

Future<int?> _showGoalSheet(BuildContext context, int current) {
  final controller = TextEditingController(text: current.toString());
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 8,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daily goal',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                suffixText: 'ml',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final n = int.tryParse(controller.text);
                      if (n != null && n > 0) Navigator.pop(context, n);
                    },
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

Future<int?> _showIntervalSheet(BuildContext context, int current) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          20,
          12,
          20,
          MediaQuery.viewPaddingOf(context).bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Reminder interval',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
            for (final h in const [1, 2, 3, 4, 6])
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _IntervalOption(
                  hours: h,
                  selected: h == current,
                  onTap: () => Navigator.pop(context, h),
                ),
              ),
          ],
        ),
      );
    },
  );
}

class _IntervalOption extends StatelessWidget {
  const _IntervalOption({
    required this.hours,
    required this.selected,
    required this.onTap,
  });

  final int hours;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return PressableScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: AppDurations.sm,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? scheme.primaryContainer
              : scheme.surfaceContainerHighest.withOpacity(0.6),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected
                ? scheme.primary.withOpacity(0.6)
                : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.schedule,
              color: selected
                  ? scheme.onPrimaryContainer
                  : scheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Every $hours hour${hours == 1 ? '' : 's'}',
                style: TextStyle(
                  color: selected
                      ? scheme.onPrimaryContainer
                      : scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              Icon(Icons.check_circle, color: scheme.primary),
          ],
        ),
      ),
    );
  }
}

Future<bool?> _confirmClear(BuildContext context) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Clear all entries?'),
      content: const Text('This cannot be undone.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Clear'),
        ),
      ],
    ),
  );
}
