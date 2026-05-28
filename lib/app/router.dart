import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../features/analytics/presentation/analytics_screen.dart';
import '../features/settings/presentation/settings_screen.dart';
import '../features/tracker/presentation/home_screen.dart';
import 'motion.dart';
import 'widgets/app_page_transition.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      pageBuilder: (context, state, child) => appFadePage(
        key: state.pageKey,
        child: _ScaffoldShell(child: child),
      ),
      routes: [
        GoRoute(
          path: '/',
          pageBuilder: (context, state) => appFadePage(
            key: state.pageKey,
            child: const HomeScreen(),
          ),
        ),
        GoRoute(
          path: '/analytics',
          pageBuilder: (context, state) => appFadePage(
            key: state.pageKey,
            child: const AnalyticsScreen(),
          ),
        ),
        GoRoute(
          path: '/settings',
          pageBuilder: (context, state) => appFadePage(
            key: state.pageKey,
            child: const SettingsScreen(),
          ),
        ),
      ],
    ),
  ],
);

class _ScaffoldShell extends StatelessWidget {
  const _ScaffoldShell({required this.child});

  final Widget child;

  static const _tabs = ['/', '/analytics', '/settings'];

  int _indexFromLocation(String location) {
    if (location.startsWith('/analytics')) return 1;
    if (location.startsWith('/settings')) return 2;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    final index = _indexFromLocation(location);

    return Scaffold(
      extendBody: true,
      body: AnimatedSwitcher(
        duration: AppDurations.md,
        switchInCurve: AppCurves.emphasizedDecelerate,
        switchOutCurve: AppCurves.emphasizedAccelerate,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
        child: KeyedSubtree(
          key: ValueKey(index),
          child: child,
        ),
      ),
      bottomNavigationBar: _FloatingPillNav(
        selectedIndex: index,
        onSelect: (i) {
          if (i == index) return;
          HapticFeedback.selectionClick();
          context.go(_tabs[i]);
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
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
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
