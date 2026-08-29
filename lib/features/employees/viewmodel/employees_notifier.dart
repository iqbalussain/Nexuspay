import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/providers.dart';
import '../../../core/utils/id_generator.dart';
import '../../../domain/entities/employee.dart';
import '../../../domain/enums/enums.dart';

/// State for the employee list screen.
class EmployeesState {
  final List<Employee> employees;
  final String searchQuery;
  final EmployeeStatus? statusFilter;
  final bool loading;
  final String? error;

  const EmployeesState({
    this.employees = const [],
    this.searchQuery = '',
    this.statusFilter,
    this.loading = false,
    this.error,
  });

  List<Employee> get filtered {
    return employees.where((e) {
      final q = searchQuery.toLowerCase();
      if (q.isNotEmpty &&
          !e.fullName.toLowerCase().contains(q) &&
          !e.employeeCode.toLowerCase().contains(q) &&
          !(e.position?.toLowerCase().contains(q) ?? false)) {
        return false;
      }
      if (statusFilter != null && e.status != statusFilter) return false;
      return true;
    }).toList();
  }

  EmployeesState copyWith({
    List<Employee>? employees,
    String? searchQuery,
    EmployeeStatus? statusFilter,
    bool clearStatusFilter = false,
    bool? loading,
    String? error,
    bool clearError = false,
  }) {
    return EmployeesState(
      employees: employees ?? this.employees,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: clearStatusFilter
          ? null
          : (statusFilter ?? this.statusFilter),
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class EmployeesNotifier extends AsyncNotifier<EmployeesState> {
  @override
  Future<EmployeesState> build() async {
    final repo = ref.watch(employeeRepositoryProvider);
    final employees = await repo.getEmployees(const EmployeeFilter());
    return EmployeesState(employees: employees);
  }

  Future<void> reload() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final repo = ref.read(employeeRepositoryProvider);
      final employees = await repo.getEmployees(const EmployeeFilter());
      return (state.value ?? const EmployeesState()).copyWith(
        employees: employees,
      );
    });
  }

  void setSearch(String q) {
    state = state.whenData((s) => s.copyWith(searchQuery: q));
  }

  void setStatusFilter(EmployeeStatus? status) {
    state = state.whenData(
      (s) =>
          s.copyWith(statusFilter: status, clearStatusFilter: status == null),
    );
  }

  Future<void> addEmployee(Employee employee) async {
    final repo = ref.read(employeeRepositoryProvider);
    await repo.create(employee);
    await reload();
  }

  Future<void> updateEmployee(Employee employee) async {
    final repo = ref.read(employeeRepositoryProvider);
    await repo.update(employee);
    await reload();
  }

  Future<void> deactivateEmployee(String id) async {
    final repo = ref.read(employeeRepositoryProvider);
    await repo.deactivate(id);
    await reload();
  }
}

final employeesProvider =
    AsyncNotifierProvider<EmployeesNotifier, EmployeesState>(
      EmployeesNotifier.new,
    );

/// Builds a new Employee entity ready for [EmployeesNotifier.addEmployee].
Employee buildNewEmployee({
  required String fullName,
  required String employeeCode,
  String? position,
  String? nationalId,
  String? phone,
  String? email,
  required DateTime hireDate,
}) {
  return Employee(
    id: IdGenerator.newId(),
    employeeCode: employeeCode,
    fullName: fullName,
    position: position,
    status: EmployeeStatus.active,
    hireDate: hireDate,
    nationalId: nationalId,
    phone: phone,
    email: email,
  );
}
