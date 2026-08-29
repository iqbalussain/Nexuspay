import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import '../../domain/entities/employee.dart';

/// This is the proof that the dependency-injection pattern works
/// end-to-end: this screen depends only on [employeeRepositoryProvider],
/// which currently resolves to [MockEmployeeRepository]. When that single
/// provider is later repointed at a Supabase implementation, this file
/// does not change.
final employeesListProvider = FutureProvider<List<Employee>>((ref) {
  final repo = ref.watch(employeeRepositoryProvider);
  return repo.getEmployees(const EmployeeFilter());
});

class EmployeesScreen extends ConsumerWidget {
  const EmployeesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeesListProvider);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Employees', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 4),
          Text(
            'Loaded from EmployeeRepository via the mock data source.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: employeesAsync.when(
              data: (employees) => employees.isEmpty
                  ? const Center(child: Text('No employees yet.'))
                  : ListView.separated(
                      itemCount: employees.length,
                      separatorBuilder: (_, index) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final e = employees[index];
                        return ListTile(
                          leading: CircleAvatar(
                              child: Text(e.fullName.isNotEmpty ? e.fullName[0] : '?')),
                          title: Text(e.fullName),
                          subtitle:
                              Text('${e.employeeCode} · ${e.position ?? 'No position set'}'),
                          trailing: Chip(label: Text(e.status.name)),
                        );
                      },
                    ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, stack) => Center(child: Text('Failed to load employees: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
