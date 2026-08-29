import '../enums/enums.dart';

/// Coarse daily attendance status (present/absent/leave/holiday), separate
/// from the detailed hour-by-project [TimesheetEntry]. Attendance drives
/// unpaid-leave/absence salary impact; timesheets drive hours & project
/// costing. The two are reconciled during payroll validation, not merged
/// into a single record, since a supervisor may mark attendance for a
/// broad team quickly while detailed timesheet entry happens separately.
class AttendanceRecord {
  final String id;
  final String employeeId;
  final DateTime date;
  final AttendanceStatus status;
  final String? note;

  const AttendanceRecord({
    required this.id,
    required this.employeeId,
    required this.date,
    required this.status,
    this.note,
  });
}
