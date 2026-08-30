import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:nexuspay/domain/entities/project.dart';

import '../../app/di/providers.dart';
import '../../app/theme/nexus_theme.dart';
import '../../app/theme/nexus_widgets.dart';
import '../../domain/entities/employee.dart';
import '../../domain/enums/enums.dart';

final _dashboardDataProvider = FutureProvider((ref) async {
  final empRepo = ref.watch(employeeRepositoryProvider);
  final projRepo = ref.watch(projectRepositoryProvider);
  final supRepo = ref.watch(supervisorRepositoryProvider);
  final periodRepo = ref.watch(payrollPeriodRepositoryProvider);

  final employees = await empRepo.getEmployees(const EmployeeFilter());
  final projects = await projRepo.getProjects();
  final supervisors = await supRepo.getSupervisors(activeOnly: false);
  final periods = await periodRepo.getAll();

  return (
    employees: employees,
    activeEmployees:
        employees.where((e) => e.status == EmployeeStatus.active).length,
    activeProjects:
        projects.where((p) => p.status == ProjectStatus.active).length,
    activeSupervisors: supervisors.where((s) => s.active).length,
    currentPeriod: periods.isNotEmpty ? periods.last : null,
  );
});

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(_dashboardDataProvider);

    return NexusScreen(
      eyebrow: 'Overview',
      title: 'Dashboard',
      accentColor: NexusColors.primary,
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (data) => _DashboardBody(data: data),
      ),
    );
  }
}

class _DashboardBody extends StatelessWidget {
  final dynamic data;
  const _DashboardBody({required this.data});

  @override
  Widget build(BuildContext context) {
    final period = data.currentPeriod;
    final periodLabel = period != null
        ? '${period.startDate.year}-${period.startDate.month.toString().padLeft(2, '0')}'
        : '—';
    final periodStatus = period?.status.name ?? '—';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(NexusSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current payroll period banner
          Container(
            padding: const EdgeInsets.all(NexusSpacing.md),
            decoration: BoxDecoration(
              color: NexusColors.surface,
              borderRadius: NexusRadius.sm,
              border: Border.all(color: NexusColors.border),
              gradient: LinearGradient(
                colors: [
                  NexusColors.amber.withValues(alpha: 0.08),
                  NexusColors.surface,
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 3,
                  height: 36,
                  decoration: BoxDecoration(
                      color: NexusColors.amber,
                      borderRadius: BorderRadius.circular(2)),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CURRENT PAYROLL PERIOD',
                        style: NexusTypography.label),
                    const SizedBox(height: 2),
                    Row(children: [
                      Text(periodLabel,
                          style: NexusTypography.money(
                              fontSize: 18,
                              color: NexusColors.amberText,
                              weight: FontWeight.w700)),
                      const SizedBox(width: 10),
                      NexusBadge(
                        label: periodStatus.toUpperCase(),
                        color: NexusColors.amber,
                        dot: true,
                      ),
                    ]),
                  ],
                ),
                const Spacer(),
                OutlinedButton(
                  onPressed: () => context.go('/payroll'),
                  child: const Text('View Payroll'),
                ),
              ],
            ),
          ),

          const SizedBox(height: NexusSpacing.md),

          // Stat cards row
          LayoutBuilder(builder: (context, constraints) {
            final crossCount = constraints.maxWidth > 700 ? 4 : 2;
            return GridView.count(
              crossAxisCount: crossCount,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: NexusSpacing.sm,
              crossAxisSpacing: NexusSpacing.sm,
              childAspectRatio: constraints.maxWidth > 700 ? 1.8 : 1.6,
              children: [
                NexusStatCard(
                  label: 'Active Employees',
                  value: '${data.activeEmployees}',
                  subValue: '${data.employees.length} total on record',
                  icon: Icons.people_outline,
                  accentColor: NexusColors.moduleEmployee,
                ),
                NexusStatCard(
                  label: 'Active Projects',
                  value: '${data.activeProjects}',
                  subValue: 'Sites currently running',
                  icon: Icons.apartment_outlined,
                  accentColor: NexusColors.moduleProject,
                ),
                NexusStatCard(
                  label: 'Supervisors',
                  value: '${data.activeSupervisors}',
                  subValue: 'Active in the field',
                  icon: Icons.supervisor_account_outlined,
                  accentColor: NexusColors.moduleSupervisor,
                ),
                NexusStatCard(
                  label: 'Period Status',
                  value: periodStatus[0].toUpperCase() + periodStatus.substring(1),
                  subValue: periodLabel,
                  icon: Icons.payments_outlined,
                  accentColor: NexusColors.modulePayroll,
                ),
              ],
            );
          }),

          const SizedBox(height: NexusSpacing.lg),

          // Quick links section
          Text('QUICK ACTIONS', style: NexusTypography.label),
          const SizedBox(height: NexusSpacing.sm),
          Wrap(
            spacing: NexusSpacing.sm,
            runSpacing: NexusSpacing.sm,
            children: [
              _QuickAction(
                  icon: Icons.person_add_outlined,
                  label: 'Add Employee',
                  color: NexusColors.moduleEmployee,
                  onTap: () => context.go('/employees')),
              _QuickAction(
                  icon: Icons.event_available_outlined,
                  label: 'Mark Attendance',
                  color: NexusColors.moduleAttendance,
                  onTap: () => context.go('/attendance')),
              _QuickAction(
                  icon: Icons.schedule_outlined,
                  label: 'Enter Timesheets',
                  color: NexusColors.cyan,
                  onTap: () => context.go('/timesheets')),
              _QuickAction(
                  icon: Icons.fact_check_outlined,
                  label: 'Approvals',
                  color: NexusColors.amber,
                  onTap: () => context.go('/approvals')),
            ],
          ),

          const SizedBox(height: NexusSpacing.lg),

          // Footer note about Phase 1 data
          Container(
            padding: const EdgeInsets.all(NexusSpacing.sm),
            decoration: BoxDecoration(
              color: NexusColors.borderSubtle,
              borderRadius: NexusRadius.sm,
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 14, color: NexusColors.textMuted),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Running on mock data layer. '
                    'Connect Supabase to see live payroll figures.',
                    style: NexusTypography.label,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: NexusRadius.sm,
      child: Container(
        padding: const EdgeInsets.symmetric(
            horizontal: NexusSpacing.md, vertical: NexusSpacing.sm),
        decoration: BoxDecoration(
          color: NexusColors.surface,
          borderRadius: NexusRadius.sm,
          border: Border.all(color: NexusColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(label,
                style: NexusTypography.bodyMedium
                    .copyWith(fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}
