import '../entities/timesheet_entry.dart';
import '../enums/enums.dart';

abstract class TimesheetRepository {
  Future<List<TimesheetEntry>> getForEmployeeInRange(
    String employeeId,
    DateTime start,
    DateTime end,
  );

  Future<List<TimesheetEntry>> getForPeriod(
    DateTime start,
    DateTime end, {
    String? projectId,
    String? supervisorId,
    TimesheetStatus? status,
  });

  /// Creates or updates a single day's entry for
  /// (employeeId, date, projectId, supervisorId). Implementations must
  /// enforce the no-duplicate-row rule (architecture §13) and must reject
  /// writes to a date inside a finalized/locked payroll period.
  Future<TimesheetEntry> upsert(TimesheetEntry entry);

  Future<TimesheetEntry> submit(String id);
  Future<TimesheetEntry> approve(String id, String approvedBy);
  Future<TimesheetEntry> returnForCorrection(String id, String reason);
}
