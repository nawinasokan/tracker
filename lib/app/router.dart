import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tracker/presentation/home_screen.dart';
import 'motion.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          _ScaffoldShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(path: '/', builder: (context, state) => const HomeScreen()),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/analytics',
              builder: (context, state) => const AnalyticsScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),
  ],
);

class _ScaffoldShell extends StatefulWidget {
  const _ScaffoldShell({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  State<_ScaffoldShell> createState() => _ScaffoldShellState();
}

class _ScaffoldShellState extends State<_ScaffoldShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: AppDurations.sm,
    value: 1,
  );
  late int _index = widget.navigationShell.currentIndex;

  @override
  void didUpdateWidget(covariant _ScaffoldShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final next = widget.navigationShell.currentIndex;
    if (next != _index) {
      _index = next;
      // Fade only the newly shown tab in — the IndexedStack has already
      // swapped, so no two screens are ever painted at once.
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final index = widget.navigationShell.currentIndex;

    return Scaffold(
      extendBody: true,
      body: FadeTransition(
        opacity: CurvedAnimation(parent: _fade, curve: AppCurves.standard),
        child: widget.navigationShell,
      ),
      bottomNavigationBar: _FloatingPillNav(
        selectedIndex: index,
        onSelect: (i) {
          if (i == index) return;
          HapticFeedback.selectionClick();
          widget.navigationShell.goBranch(i);
        },
      ),
    );
  }
}

class _NavItem {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
  });
  final IconData icon;
  final IconData selectedIcon;
  final String label;
}

class _FloatingPillNav extends StatelessWidget {
  const _FloatingPillNav({
    required this.selectedIndex,
    required this.onSelect,
  });

  final int selectedIndex;
  final ValueChanged<int> onSelect;

  static const _items = <_NavItem>[
    _NavItem(
      icon: Icons.water_drop_outlined,
      selectedIcon: Icons.water_drop,
      label: 'Today',
    ),
    _NavItem(
      icon: Icons.bar_chart_outlined,
      selectedIcon: Icons.bar_chart,
      label: 'Analytics',
    ),
    _NavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings,
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottom = MediaQuery.viewPaddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: bottom > 0 ? bottom : 16,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            height: 68,
            decoration: BoxDecoration(
              color: isDark
                  ? scheme.surfaceContainerHigh.withOpacity(0.72)
                  : scheme.surface.withOpacity(0.78),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: scheme.outlineVariant.withOpacity(0.4),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final itemWidth = constraints.maxWidth / _items.length;
                return Stack(
                  children: [
                    AnimatedPositioned(
                      duration: AppDurations.md,
                      curve: AppCurves.emphasized,
                      left: itemWidth * selectedIndex + 8,
                      top: 8,
                      bottom: 8,
                      width: itemWidth - 16,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer
                              .withOpacity(0.85),
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        for (int i = 0; i < _items.length; i++)
                          Expanded(
                            child: _NavButton(
                              item: _items[i],
                              selected: i == selectedIndex,
                              onTap: () => onSelect(i),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color =
        selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Semantics(
        button: true,
        selected: selected,
        label: item.label,
        child: Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: AppDurations.sm,
                transitionBuilder: (child, anim) => ScaleTransition(
                  scale: anim,
                  child: FadeTransition(opacity: anim, child: child),
                ),
                child: Icon(
                  selected ? item.selectedIcon : item.icon,
                  key: ValueKey(selected),
                  color: color,
                  size: 22,
                ),
              ),
              AnimatedSize(
                duration: AppDurations.sm,
                curve: AppCurves.emphasized,
                child: selected
                    ? Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Text(
                          item.label,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
