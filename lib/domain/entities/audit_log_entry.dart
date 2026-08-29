/// A single audit trail event. Generated for every important change to
/// payroll, hours, salary, assignments and approvals (architecture §2, §23).
class AuditLogEntry {
  final String id;
  final String entityType; // e.g. "Employee", "TimesheetEntry", "PayrollRecord"
  final String entityId;
  final String action; // e.g. "salary_changed", "timesheet_approved", "payroll_finalized"
  final String performedBy;
  final DateTime performedAt;
  final Map<String, Object?> metadata; // before/after values, reason, etc.

  const AuditLogEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    required this.performedBy,
    required this.performedAt,
    this.metadata = const {},
  });
}
