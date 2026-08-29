import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/mock/mock_repositories.dart';
import '../../data/mock/seed_data.dart';
import '../../domain/repositories/assignment_repository.dart';
import '../../domain/repositories/attendance_repository.dart';
import '../../domain/repositories/audit_log_repository.dart';
import '../../domain/repositories/deduction_repository.dart';
import '../../domain/repositories/earning_repository.dart';
import '../../domain/repositories/employee_repository.dart';
import '../../domain/repositories/payroll_adjustment_repository.dart';
import '../../domain/repositories/payroll_period_repository.dart';
import '../../domain/repositories/payroll_record_repository.dart';
import '../../domain/repositories/project_repository.dart';
import '../../domain/repositories/salary_history_repository.dart';
import '../../domain/repositories/supervisor_repository.dart';
import '../../domain/repositories/timesheet_repository.dart';

/// THE dependency-injection point (architecture §9: "The application
/// should initially inject Mock/Local repositories. Later, switching to
/// Supabase should be a dependency configuration change, not a screen
/// rewrite.").
///
/// Every provider below returns the abstract repository *interface* type
/// (e.g. `EmployeeRepository`, not `MockEmployeeRepository`). Every
/// screen and use case in features/ depends only on that interface via
/// `ref.watch(employeeRepositoryProvider)`. When Supabase is ready:
///
///   1. Implement `SupabaseEmployeeRepository implements EmployeeRepository`
///      in lib/data/remote/.
///   2. Change ONE line here: `MockEmployeeRepository(...)` ->
///      `SupabaseEmployeeRepository(...)`.
///
/// No feature file changes. That is the entire point of this file
/// existing separately from the screens.

final payrollPeriodRepositoryProvider = Provider<PayrollPeriodRepository>((ref) {
  return MockPayrollPeriodRepository([SeedData.payrollPeriodAugust]);
});

final employeeRepositoryProvider = Provider<EmployeeRepository>((ref) {
  return MockEmployeeRepository([SeedData.employeeAhmed]);
});

final supervisorRepositoryProvider = Provider<SupervisorRepository>((ref) {
  return MockSupervisorRepository(
      [SeedData.supervisorTariq, SeedData.supervisorMohammed]);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  return MockProjectRepository([SeedData.projectAlpha, SeedData.projectBeta]);
});

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return MockAssignmentRepository(SeedData.assignmentsForAhmed());
});

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  return MockAttendanceRepository(SeedData.attendanceForAhmed());
});

final timesheetRepositoryProvider = Provider<TimesheetRepository>((ref) {
  return MockTimesheetRepository(
    SeedData.timesheetsForAhmed(),
    ref.watch(payrollPeriodRepositoryProvider),
  );
});

final salaryHistoryRepositoryProvider = Provider<SalaryHistoryRepository>((ref) {
  return MockSalaryHistoryRepository(SeedData.salaryHistoryForAhmed());
});

final earningRepositoryProvider = Provider<EarningRepository>((ref) {
  return MockEarningRepository(
      SeedData.earningsForAhmed(SeedData.payrollPeriodAugust.id));
});

final deductionRepositoryProvider = Provider<DeductionRepository>((ref) {
  return MockDeductionRepository(
      SeedData.deductionsForAhmed(SeedData.payrollPeriodAugust.id));
});

final payrollAdjustmentRepositoryProvider =
    Provider<PayrollAdjustmentRepository>((ref) {
  return MockPayrollAdjustmentRepository();
});

final payrollRecordRepositoryProvider = Provider<PayrollRecordRepository>((ref) {
  return MockPayrollRecordRepository(ref.watch(payrollPeriodRepositoryProvider));
});

final auditLogRepositoryProvider = Provider<AuditLogRepository>((ref) {
  return MockAuditLogRepository();
});
