import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Persistent navigation shell — bottom bar on phone, rail on tablet/web.
class AppShell extends StatelessWidget {
  final StatefulNavigationShell shell;

  const AppShell({super.key, required this.shell});

  static const _destinations = [
    _NavDest(label: 'Home', icon: Icons.home_outlined, activeIcon: Icons.home),
    _NavDest(
      label: 'Cockpit',
      icon: Icons.dashboard_outlined,
      activeIcon: Icons.dashboard,
    ),
    _NavDest(
      label: 'Journal',
      icon: Icons.book_outlined,
      activeIcon: Icons.book,
    ),
    _NavDest(
      label: 'Analyze',
      icon: Icons.analytics_outlined,
      activeIcon: Icons.analytics,
    ),
    _NavDest(
      label: 'Tools',
      icon: Icons.build_outlined,
      activeIcon: Icons.build,
    ),
  ];

  void _onTap(int index) {
    if (shell.currentIndex == index) {
      // Pop to root of the current branch on double-tap
      shell.goBranch(index, initialLocation: true);
    } else {
      shell.goBranch(index);
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final useRail = width >= 600;

    if (useRail) {
      return Scaffold(
        body: Row(
          children: [
            NavigationRail(
              selectedIndex: shell.currentIndex,
              onDestinationSelected: _onTap,
              labelType: NavigationRailLabelType.all,
              destinations: _destinations
                  .map(
                    (d) => NavigationRailDestination(
                      icon: Icon(d.icon),
                      selectedIcon: Icon(d.activeIcon),
                      label: Text(d.label),
                    ),
                  )
                  .toList(),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(child: shell),
          ],
        ),
      );
    }

    return Scaffold(
      body: shell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: shell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: _destinations
            .map(
              (d) => NavigationDestination(
                icon: Icon(d.icon),
                selectedIcon: Icon(d.activeIcon),
                label: d.label,
              ),
            )
            .toList(),
      ),
    );
  }
}

class _NavDest {
  final String label;
  final IconData icon;
  final IconData activeIcon;
  const _NavDest({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}
