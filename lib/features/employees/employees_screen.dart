import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/enums/enums.dart';
import '../../shared/widgets/confirm_dialog.dart';
import 'viewmodel/employees_notifier.dart';
import 'widgets/employee_form.dart';

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncState = ref.watch(employeesProvider);

    return asyncState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (state) => _EmployeeListBody(state: state),
    );
  }
}

class _EmployeeListBody extends ConsumerWidget {
  final EmployeesState state;
  const _EmployeeListBody({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(employeesProvider.notifier);
    final filtered = state.filtered;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                Text(
                  'Employees',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const Spacer(),
                Text(
                  '${filtered.length} of ${state.employees.length}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          // Search bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, code or position…',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
                isDense: true,
              ),
              onChanged: notifier.setSearch,
            ),
          ),
          // Status filter chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                FilterChip(
                  label: const Text('All'),
                  selected: state.statusFilter == null,
                  onSelected: (_) => notifier.setStatusFilter(null),
                ),
                const SizedBox(width: 8),
                for (final status in EmployeeStatus.values)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(_statusLabel(status)),
                      selected: state.statusFilter == status,
                      onSelected: (_) => notifier.setStatusFilter(
                        state.statusFilter == status ? null : status,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // List
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 48,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          state.employees.isEmpty
                              ? 'No employees yet. Tap + to add one.'
                              : 'No employees match the current filter.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.only(bottom: 80),
                    itemCount: filtered.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, i) {
                      final e = filtered[i];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(
                            e.fullName.isNotEmpty
                                ? e.fullName[0].toUpperCase()
                                : '?',
                          ),
                        ),
                        title: Text(e.fullName),
                        subtitle: Text(
                          '${e.employeeCode}'
                          '${e.position != null ? ' · ${e.position}' : ''}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _StatusBadge(status: e.status),
                            PopupMenuButton<String>(
                              itemBuilder: (_) => [
                                const PopupMenuItem(
                                  value: 'edit',
                                  child: ListTile(
                                    leading: Icon(Icons.edit_outlined),
                                    title: Text('Edit'),
                                    dense: true,
                                  ),
                                ),
                                if (e.status == EmployeeStatus.active)
                                  const PopupMenuItem(
                                    value: 'deactivate',
                                    child: ListTile(
                                      leading: Icon(Icons.block_outlined),
                                      title: Text('Deactivate'),
                                      dense: true,
                                    ),
                                  ),
                              ],
                              onSelected: (action) async {
                                if (action == 'edit') {
                                  await showEmployeeForm(context, existing: e);
                                } else if (action == 'deactivate') {
                                  final confirmed = await showConfirmDialog(
                                    context,
                                    title: 'Deactivate ${e.fullName}?',
                                    message:
                                        'The employee will be marked inactive. '
                                        'All historical payroll records, '
                                        'timesheets, and salary history are '
                                        'preserved and remain queryable.',
                                    confirmLabel: 'Deactivate',
                                    destructive: true,
                                  );
                                  if (confirmed) {
                                    await ref
                                        .read(employeesProvider.notifier)
                                        .deactivateEmployee(e.id);
                                  }
                                }
                              },
                            ),
                          ],
                        ),
                        onTap: () => showEmployeeForm(context, existing: e),
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: 'Add Employee',
        onPressed: () => showEmployeeForm(context),
        child: const Icon(Icons.person_add_outlined),
      ),
    );
  }

  String _statusLabel(EmployeeStatus s) => switch (s) {
    EmployeeStatus.active => 'Active',
    EmployeeStatus.inactive => 'Inactive',
    EmployeeStatus.onLeave => 'On Leave',
    EmployeeStatus.terminated => 'Terminated',
  };
}

class _StatusBadge extends StatelessWidget {
  final EmployeeStatus status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      EmployeeStatus.active => ('Active', Colors.green),
      EmployeeStatus.inactive => ('Inactive', Colors.grey),
      EmployeeStatus.onLeave => ('On Leave', Colors.orange),
      EmployeeStatus.terminated => ('Terminated', Colors.red),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.32), width: 0.5),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
