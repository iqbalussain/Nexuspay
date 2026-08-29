import '../enums/enums.dart';

/// Employee master data.
///
/// IMPORTANT (architecture §2 non-negotiable rule): this entity does NOT
/// store `currentProjectId` / `currentSupervisorId`. Those would become a
/// false "source of truth" for historical work. Actual work allocation
/// lives in [Assignment] (effective-dated) and [TimesheetEntry] (daily,
/// actual). Never add project/supervisor fields here.
class Employee {
  final String id;
  final String employeeCode;
  final String fullName;
  final String? position;
  final EmployeeStatus status;
  final DateTime hireDate;
  final DateTime? terminationDate;
  final String? nationalId;
  final String? phone;
  final String? email;

  const Employee({
    required this.id,
    required this.employeeCode,
    required this.fullName,
    this.position,
    required this.status,
    required this.hireDate,
    this.terminationDate,
    this.nationalId,
    this.phone,
    this.email,
  });

  Employee copyWith({
    String? fullName,
    String? position,
    EmployeeStatus? status,
    DateTime? terminationDate,
    String? phone,
    String? email,
  }) {
    return Employee(
      id: id,
      employeeCode: employeeCode,
      fullName: fullName ?? this.fullName,
      position: position ?? this.position,
      status: status ?? this.status,
      hireDate: hireDate,
      terminationDate: terminationDate ?? this.terminationDate,
      nationalId: nationalId,
      phone: phone ?? this.phone,
      email: email ?? this.email,
    );
  }
}

class EmployeeFilter {
  final String? searchText;
  final EmployeeStatus? status;
  final String? projectId; // resolved via current Assignment, not a stored field
  final String? supervisorId;

  const EmployeeFilter({this.searchText, this.status, this.projectId, this.supervisorId});
}
