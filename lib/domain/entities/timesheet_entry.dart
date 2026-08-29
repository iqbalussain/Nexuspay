import '../enums/enums.dart';

/// The single most important entity in the system (architecture §6).
/// A daily record of actual hours worked by an employee, on a specific
/// project, under a specific supervisor. Payroll and project costing are
/// ALWAYS aggregated from approved rows of this table — never from a
/// monthly total and never from [Employee]/[Assignment] fields.
///
/// Business rule: no two entries for the same
/// (employeeId, date, projectId, supervisorId) — see
/// architecture §13 "prevent duplicate timesheet rows".
class TimesheetEntry {
  final String id;
  final String employeeId;
  final DateTime date;
  final String projectId;
  final String supervisorId;
  final double regularHours;
  final double otHours;
  final TimesheetStatus status;
  final String? note;
  final String? approvedBy;
  final DateTime? approvedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  const TimesheetEntry({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.projectId,
    required this.supervisorId,
    required this.regularHours,
    required this.otHours,
    required this.status,
    this.note,
    this.approvedBy,
    this.approvedAt,
    required this.createdAt,
    required this.updatedAt,
  });

  TimesheetEntry copyWith({
    double? regularHours,
    double? otHours,
    TimesheetStatus? status,
    String? note,
    String? approvedBy,
    DateTime? approvedAt,
    DateTime? updatedAt,
  }) {
    return TimesheetEntry(
      id: id,
      employeeId: employeeId,
      date: date,
      projectId: projectId,
      supervisorId: supervisorId,
      regularHours: regularHours ?? this.regularHours,
      otHours: otHours ?? this.otHours,
      status: status ?? this.status,
      note: note ?? this.note,
      approvedBy: approvedBy ?? this.approvedBy,
      approvedAt: approvedAt ?? this.approvedAt,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}
