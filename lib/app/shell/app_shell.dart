import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../responsive/responsive.dart';
import '../router/app_router.dart';
import '../theme/nexus_theme.dart';

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
    return ResponsiveLayout.isDesktop(context)
        ? _DesktopShell(selectedIndex: _selectedIndex, child: child)
        : _MobileShell(selectedIndex: _selectedIndex, location: location, child: child);
  }
}

// ---- Desktop shell: custom left rail + content ----------------------

class _DesktopShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  const _DesktopShell({required this.child, required this.selectedIndex});

  @override
  Widget build(BuildContext context) {
    final extended = ResponsiveLayout.isWideDesktop(context);

    return Scaffold(
      backgroundColor: NexusColors.base,
      body: Row(
        children: [
          _NexusNavRail(selectedIndex: selectedIndex, extended: extended),
          Expanded(
            child: SafeArea(left: false, child: child),
          ),
        ],
      ),
    );
  }
}

class _NexusNavRail extends StatelessWidget {
  final int selectedIndex;
  final bool extended;
  const _NexusNavRail({required this.selectedIndex, required this.extended});

  static final _groups = [
    _NavGroup(label: 'Overview', indices: [0]),
    _NavGroup(label: 'Master Data', indices: [1, 2, 3, 4]),
    _NavGroup(label: 'Operations', indices: [5, 6, 7]),
    _NavGroup(label: 'Financials', indices: [8, 9, 10, 11]),
    _NavGroup(label: 'System', indices: [12, 13, 14]),
  ];

  @override
  Widget build(BuildContext context) {
    final width = extended ? 200.0 : 64.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: width,
      decoration: const BoxDecoration(
        color: NexusColors.surface,
        border: Border(right: BorderSide(color: NexusColors.border)),
      ),
      child: Column(
        children: [
          // Logo / wordmark area
          Container(
            height: 56,
            padding: EdgeInsets.symmetric(
                horizontal: extended ? NexusSpacing.md : 0),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: NexusColors.border)),
            ),
            child: Center(
              child: extended
                  ? Row(
                      children: [
                        _LogoMark(),
                        const SizedBox(width: 8),
                        const Text(
                          'NexusPay',
                          style: TextStyle(
                            fontFamily: 'SpaceGrotesk',
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: NexusColors.textPrimary,
                          ),
                        ),
                      ],
                    )
                  : _LogoMark(),
            ),
          ),
          // Nav items grouped
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: NexusSpacing.sm),
              children: [
                for (final group in _groups) ...[
                  if (extended)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Text(group.label.toUpperCase(),
                          style: NexusTypography.label),
                    ),
                  for (final idx in group.indices)
                    _NavItem(
                      item: navItems[idx],
                      selected: idx == selectedIndex,
                      extended: extended,
                    ),
                  if (group != _groups.last)
                    const Divider(height: 16),
                ],
              ],
            ),
          ),
          // Bottom user row (placeholder)
          Container(
            height: 52,
            padding: EdgeInsets.symmetric(
                horizontal: extended ? NexusSpacing.sm : 0),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: NexusColors.border)),
            ),
            child: Center(
              child: extended
                  ? Row(children: [
                      const CircleAvatar(
                        radius: 14,
                        backgroundColor: NexusColors.primaryDim,
                        child: Text('A',
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: NexusColors.primaryText)),
                      ),
                      const SizedBox(width: 8),
                      Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Admin',
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: NexusColors.textPrimary)),
                            Text('Payroll Admin',
                                style: NexusTypography.label),
                          ]),
                    ])
                  : const CircleAvatar(
                      radius: 14,
                      backgroundColor: NexusColors.primaryDim,
                      child: Text('A',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: NexusColors.primaryText)),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final NavItem item;
  final bool selected;
  final bool extended;
  const _NavItem(
      {required this.item, required this.selected, required this.extended});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.go(item.path),
      hoverColor: NexusColors.overlay,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
        padding: EdgeInsets.symmetric(
            horizontal: extended ? 10 : 0, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? NexusColors.primaryDim : Colors.transparent,
          borderRadius: NexusRadius.sm,
          border: selected
              ? Border(
                  left: BorderSide(color: NexusColors.primary, width: 2))
              : null,
        ),
        child: extended
            ? Row(children: [
                const SizedBox(width: 6),
                Icon(item.icon,
                    size: 18,
                    color: selected
                        ? NexusColors.primary
                        : NexusColors.textMuted),
                const SizedBox(width: 10),
                Text(item.label,
                    style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: selected
                            ? NexusColors.primaryText
                            : NexusColors.textSecondary)),
              ])
            : Center(
                child: Icon(item.icon,
                    size: 20,
                    color: selected
                        ? NexusColors.primary
                        : NexusColors.textMuted),
              ),
      ),
    );
  }
}

class _LogoMark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [NexusColors.primary, Color(0xFF7B9BFF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(6),
      ),
      child: const Icon(Icons.bolt, color: Colors.white, size: 16),
    );
  }
}

class _NavGroup {
  final String label;
  final List<int> indices;
  const _NavGroup({required this.label, required this.indices});
}

// ---- Mobile shell ---------------------------------------------------

class _MobileShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;
  final String location;
  const _MobileShell(
      {required this.child,
      required this.selectedIndex,
      required this.location});

  @override
  Widget build(BuildContext context) {
    final primaryItems = mobilePrimaryIndices.map((i) => navItems[i]).toList();
    final bottomBarIndex =
        mobilePrimaryIndices.indexOf(selectedIndex).clamp(0, primaryItems.length - 1);
    final currentItem = navItems[selectedIndex];

    return Scaffold(
      backgroundColor: NexusColors.base,
      appBar: AppBar(
        backgroundColor: NexusColors.surface,
        title: Row(children: [
          _LogoMark(),
          const SizedBox(width: 10),
          Text(currentItem.label),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 20),
              onPressed: () => context.go('/notifications')),
        ],
      ),
      drawer: Drawer(
        backgroundColor: NexusColors.surface,
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(NexusSpacing.md),
                child: Row(children: [
                  _LogoMark(),
                  const SizedBox(width: 10),
                  const Text('NexusPay',
                      style: TextStyle(
                          fontFamily: 'SpaceGrotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: NexusColors.textPrimary)),
                ]),
              ),
              const Divider(),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(
                      vertical: NexusSpacing.xs, horizontal: NexusSpacing.sm),
                  children: [
                    for (var i = 0; i < navItems.length; i++)
                      InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          context.go(navItems[i].path);
                        },
                        borderRadius: NexusRadius.sm,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 9),
                          decoration: BoxDecoration(
                            color: i == selectedIndex
                                ? NexusColors.primaryDim
                                : Colors.transparent,
                            borderRadius: NexusRadius.sm,
                          ),
                          child: Row(children: [
                            Icon(navItems[i].icon,
                                size: 18,
                                color: i == selectedIndex
                                    ? NexusColors.primary
                                    : NexusColors.textMuted),
                            const SizedBox(width: 12),
                            Text(navItems[i].label,
                                style: TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 13,
                                    fontWeight: i == selectedIndex
                                        ? FontWeight.w600
                                        : FontWeight.w400,
                                    color: i == selectedIndex
                                        ? NexusColors.primaryText
                                        : NexusColors.textSecondary)),
                          ]),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(child: child),
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          color: NexusColors.surface,
          border: Border(top: BorderSide(color: NexusColors.border)),
        ),
        child: NavigationBar(
          backgroundColor: Colors.transparent,
          selectedIndex: bottomBarIndex,
          onDestinationSelected: (i) => context.go(primaryItems[i].path),
          destinations: [
            for (final item in primaryItems)
              NavigationDestination(
                  icon: Icon(item.icon), label: item.label),
          ],
        ),
      ),
    );
  }
}
