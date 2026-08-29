import '../entities/employee.dart';

abstract class EmployeeRepository {
  Future<List<Employee>> getEmployees(EmployeeFilter filter);
  Future<Employee?> getEmployee(String id);
  Future<Employee> create(Employee employee);
  Future<Employee> update(Employee employee);
  Future<void> deactivate(String id);
}
