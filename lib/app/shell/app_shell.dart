import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../responsive/responsive.dart';
import '../router/app_router.dart';

/// The persistent chrome around every route. Architecture §2 & §24:
/// "Desktop and mobile layouts must be intentionally designed for their
/// use cases; do not simply shrink the desktop UI." Accordingly this
/// picks between two genuinely different widget trees — [_DesktopShell]
/// (permanent NavigationRail, all 15 modules, accountant-oriented) and
/// [_MobileShell] (bottom bar with 4 supervisor-relevant tasks, drawer
/// for the rest) — rather than one layout with responsive tweaks.
class AppShell extends StatelessWidget {
  final Widget child;
  final String location;
  const AppShell({super.key, required this.child, required this.location});

  int get _selectedIndex {
    final idx = navItems.indexWhere((n) => location.startsWith(n.path));
    return idx == -1 ? 0 : idx;
  }

  @override
  Widget build(BuildContext context) {
    final selectedIndex = _selectedIndex;
    return ResponsiveLayout.isDesktop(context)
        ? _DesktopShell(selectedIndex: selectedIndex, child: child)
        : _MobileShell(selectedIndex: selectedIndex, child: child);
  }
}

class _DesktopShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  const _DesktopShell({required this.child, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final extended = ResponsiveLayout.isWideDesktop(context);
    return Scaffold(
      body: Row(
        children: [
          NavigationRail(
            extended: extended,
            minExtendedWidth: 220,
            selectedIndex: selectedIndex,
            onDestinationSelected: (i) => context.go(navItems[i].path),
            labelType:
                extended ? NavigationRailLabelType.none : NavigationRailLabelType.all,
            leading: const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Icon(Icons.apartment, size: 32),
            ),
            destinations: [
              for (final item in navItems)
                NavigationRailDestination(
                  icon: Icon(item.icon),
                  label: Text(item.label),
                ),
            ],
          ),
          const VerticalDivider(width: 1),
          Expanded(child: SafeArea(child: child)),
        ],
      ),
    );
  }
}

class _MobileShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  const _MobileShell({required this.child, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final primaryItems = mobilePrimaryIndices.map((i) => navItems[i]).toList();
    final bottomBarIndex = mobilePrimaryIndices.indexOf(selectedIndex);

    return Scaffold(
      appBar: AppBar(title: Text(navItems[selectedIndex].label)),
      drawer: Drawer(
        child: SafeArea(
          child: ListView(
            padding: EdgeInsets.zero,
            children: [
              const DrawerHeader(child: Text('NexusPay')),
              for (var i = 0; i < navItems.length; i++)
                ListTile(
                  leading: Icon(navItems[i].icon),
                  title: Text(navItems[i].label),
                  selected: i == selectedIndex,
                  onTap: () {
                    Navigator.of(context).pop();
                    context.go(navItems[i].path);
                  },
                ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: bottomBarIndex == -1 ? 0 : bottomBarIndex,
        onDestinationSelected: (i) => context.go(primaryItems[i].path),
        destinations: [
          for (final item in primaryItems)
            NavigationDestination(icon: Icon(item.icon), label: item.label),
        ],
      ),
    );
  }
}
