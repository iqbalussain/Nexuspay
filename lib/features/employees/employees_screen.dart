import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme/nexus_theme.dart';
import '../../app/theme/nexus_widgets.dart';
import '../../domain/enums/enums.dart';
import '../../shared/widgets/confirm_dialog.dart';
import '../employees/viewmodel/employees_notifier.dart';
import '../employees/widgets/employee_form.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(employeesProvider).when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (state) => _Body(state: state),
        );
  }
}

class _Body extends ConsumerStatefulWidget {
  final EmployeesState state;
  const _Body({required this.state});

  @override
  ConsumerState<_Body> createState() => _BodyState();
}

class _BodyState extends ConsumerState<_Body> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(EmployeeStatus s) => switch (s) {
        EmployeeStatus.active => NexusColors.positive,
        EmployeeStatus.inactive => NexusColors.textMuted,
        EmployeeStatus.onLeave => NexusColors.amber,
        EmployeeStatus.terminated => NexusColors.negative,
      };

  String _statusLabel(EmployeeStatus s) => switch (s) {
        EmployeeStatus.active => 'Active',
        EmployeeStatus.inactive => 'Inactive',
        EmployeeStatus.onLeave => 'On Leave',
        EmployeeStatus.terminated => 'Terminated',
      };

  @override
  Widget build(BuildContext context) {
    final notifier = ref.read(employeesProvider.notifier);
    final filtered = widget.state.filtered;

    return NexusScreen(
      eyebrow: 'Master Data',
      title: 'Employees',
      accentColor: NexusColors.moduleEmployee,
      headerTrailing: Text(
        '${filtered.length} / ${widget.state.employees.length}',
        style: NexusTypography.bodySmall,
      ),
      filterRow: Column(
        children: [
          NexusSearchBar(
            controller: _searchCtrl,
            hint: 'Search by name, code or position…',
            onChanged: notifier.setSearch,
          ),
          const SizedBox(height: NexusSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: widget.state.statusFilter == null,
                  onSelected: (_) => notifier.setStatusFilter(null),
                ),
                const SizedBox(width: 6),
                for (final s in EmployeeStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: FilterChip(
                      label: Text(_statusLabel(s)),
                      selected: widget.state.statusFilter == s,
                      onSelected: (_) => notifier.setStatusFilter(
                          widget.state.statusFilter == s ? null : s),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      body: filtered.isEmpty
          ? Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.people_outline,
                  size: 48, color: NexusColors.textMuted),
              const SizedBox(height: 12),
              Text(
                widget.state.employees.isEmpty
                    ? 'No employees on record.\nTap + to add the first one.'
                    : 'No employees match the current filter.',
                style: NexusTypography.bodyMedium
                    .copyWith(color: NexusColors.textSecondary),
                textAlign: TextAlign.center,
              ),
            ]))
          : ListView.builder(
              padding: const EdgeInsets.only(bottom: 80),
              itemCount: filtered.length,
              itemBuilder: (context, i) {
                final e = filtered[i];
                final color = _statusColor(e.status);
                return NexusDataRow(
                  leading: NexusAvatar(
                      name: e.fullName, color: NexusColors.moduleEmployee),
                  title: e.fullName,
                  subtitle:
                      '${e.employeeCode}${e.position != null ? ' · ${e.position}' : ''}',
                  badges: [
                    NexusBadge(
                        label: _statusLabel(e.status),
                        color: color,
                        dot: e.status == EmployeeStatus.active),
                  ],
                  onTap: () => showEmployeeForm(context, existing: e),
                  trailing: PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert,
                        size: 18, color: NexusColors.textMuted),
                    itemBuilder: (_) => [
                      const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                              leading: Icon(Icons.edit_outlined, size: 16),
                              title: Text('Edit'),
                              dense: true,
                              contentPadding: EdgeInsets.zero)),
                      if (e.status == EmployeeStatus.active)
                        const PopupMenuItem(
                            value: 'deactivate',
                            child: ListTile(
                                leading: Icon(Icons.block_outlined,
                                    size: 16, color: NexusColors.negative),
                                title: Text('Deactivate'),
                                dense: true,
                                contentPadding: EdgeInsets.zero)),
                    ],
                    onSelected: (action) async {
                      if (action == 'edit') {
                        await showEmployeeForm(context, existing: e);
                      } else if (action == 'deactivate') {
                        final ok = await showConfirmDialog(
                          context,
                          title: 'Deactivate ${e.fullName}?',
                          message:
                              'Marked inactive. All payroll history, '
                              'timesheets and salary records are preserved.',
                          confirmLabel: 'Deactivate',
                          destructive: true,
                        );
                        if (ok) {
                          await ref
                              .read(employeesProvider.notifier)
                              .deactivateEmployee(e.id);
                        }
                      }
                    },
                  ),
                );
              },
            ),
      fab: FloatingActionButton(
        tooltip: 'Add Employee',
        onPressed: () => showEmployeeForm(context),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }
}
