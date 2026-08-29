import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/dashboard/dashboard_screen.dart';
import '../../features/employees/employees_screen.dart';
import '../../shared/widgets/placeholder_screen.dart';
import '../shell/app_shell.dart';

/// One entry per module in architecture §25 "Navigation". Both the
/// desktop NavigationRail and the mobile drawer/bottom bar are built from
/// this single list, so adding a module means adding one line here and
/// one GoRoute below — never touching shell layout code twice.
class NavItem {
  final String path;
  final String label;
  final IconData icon;
  const NavItem({required this.path, required this.label, required this.icon});
}

const navItems = <NavItem>[
  NavItem(path: '/dashboard', label: 'Dashboard', icon: Icons.dashboard_outlined),
  NavItem(path: '/employees', label: 'Employees', icon: Icons.people_outline),
  NavItem(path: '/projects', label: 'Projects', icon: Icons.apartment_outlined),
  NavItem(
      path: '/supervisors',
      label: 'Supervisors',
      icon: Icons.supervisor_account_outlined),
  NavItem(
      path: '/assignments',
      label: 'Assignments',
      icon: Icons.assignment_ind_outlined),
  NavItem(
      path: '/attendance',
      label: 'Attendance',
      icon: Icons.event_available_outlined),
  NavItem(path: '/timesheets', label: 'Timesheets', icon: Icons.schedule_outlined),
  NavItem(path: '/approvals', label: 'Approvals', icon: Icons.fact_check_outlined),
  NavItem(path: '/payroll', label: 'Payroll', icon: Icons.payments_outlined),
  NavItem(path: '/leave', label: 'Leave', icon: Icons.beach_access_outlined),
  NavItem(path: '/documents', label: 'Documents', icon: Icons.folder_outlined),
  NavItem(path: '/reports', label: 'Reports', icon: Icons.bar_chart_outlined),
  NavItem(
      path: '/notifications',
      label: 'Notifications',
      icon: Icons.notifications_outlined),
  NavItem(path: '/audit', label: 'Audit', icon: Icons.history_outlined),
  NavItem(path: '/settings', label: 'Settings', icon: Icons.settings_outlined),
];

/// Indices into [navItems] that appear in the MOBILE bottom bar. This is
/// deliberately a small, task-focused subset for a field supervisor
/// (architecture §16's mobile workflow: attendance/timesheets/approvals),
/// not all 15 desktop modules shrunk into a bottom bar. Everything else
/// is one tap away in the mobile drawer.
const mobilePrimaryIndices = <int>[0, 5, 6, 7]; // Dashboard, Attendance, Timesheets, Approvals

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/dashboard',
    routes: [
      ShellRoute(
        builder: (context, state, child) =>
            AppShell(location: state.uri.toString(), child: child),
        routes: [
          GoRoute(path: '/dashboard', builder: (context, state) => const DashboardScreen()),
          GoRoute(path: '/employees', builder: (context, state) => const EmployeesScreen()),
          GoRoute(
              path: '/projects',
              builder: (context, state) => const PlaceholderScreen(title: 'Projects')),
          GoRoute(
              path: '/supervisors',
              builder: (context, state) => const PlaceholderScreen(title: 'Supervisors')),
          GoRoute(
              path: '/assignments',
              builder: (context, state) => const PlaceholderScreen(title: 'Assignments')),
          GoRoute(
              path: '/attendance',
              builder: (context, state) => const PlaceholderScreen(title: 'Attendance')),
          GoRoute(
              path: '/timesheets',
              builder: (context, state) => const PlaceholderScreen(title: 'Timesheets')),
          GoRoute(
              path: '/approvals',
              builder: (context, state) => const PlaceholderScreen(title: 'Approvals')),
          GoRoute(
              path: '/payroll',
              builder: (context, state) => const PlaceholderScreen(title: 'Payroll')),
          GoRoute(
              path: '/leave',
              builder: (context, state) => const PlaceholderScreen(title: 'Leave')),
          GoRoute(
              path: '/documents',
              builder: (context, state) => const PlaceholderScreen(title: 'Documents')),
          GoRoute(
              path: '/reports',
              builder: (context, state) => const PlaceholderScreen(title: 'Reports')),
          GoRoute(
              path: '/notifications',
              builder: (context, state) => const PlaceholderScreen(title: 'Notifications')),
          GoRoute(
              path: '/audit',
              builder: (context, state) => const PlaceholderScreen(title: 'Audit')),
          GoRoute(
              path: '/settings',
              builder: (context, state) => const PlaceholderScreen(title: 'Settings')),
        ],
      ),
    ],
  );
});
