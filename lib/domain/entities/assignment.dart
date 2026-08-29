/// An effective-dated record of which project/supervisor an employee is
/// nominally assigned to. This is planning/organisational data — it is
/// NOT what payroll or project costing is calculated from. Actual work is
/// always taken from [TimesheetEntry] (architecture §6, §18). Multiple
/// assignments can exist for an employee across a payroll period as they
/// move between projects.
class Assignment {
  final String id;
  final String employeeId;
  final String projectId;
  final String supervisorId;
  final DateTime effectiveFrom;
  final DateTime? effectiveTo; // null = currently active

  const Assignment({
    required this.id,
    required this.employeeId,
    required this.projectId,
    required this.supervisorId,
    required this.effectiveFrom,
    this.effectiveTo,
  });
}
