import '../../core/utils/id_generator.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/deduction.dart';
import '../../domain/entities/earning.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/salary_history.dart';
import '../../domain/entities/supervisor.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/enums/enums.dart';
import '../../domain/value_objects/money.dart';

/// Sample data for local/mock development, deliberately modelling the
/// exact scenario architecture §18 and §28 describe: an employee who
/// works under two different supervisors, on two different projects,
/// within a single payroll period — plus a mid-period salary change, an
/// unpaid-leave day, and both regular and OT hours. This is the scenario
/// the payroll engine must get right.
class SeedData {
  static const currency = 'AED';

  // ---- Master data -------------------------------------------------
  static final supervisorTariq = Supervisor(id: IdGenerator.newId(), fullName: 'Tariq Hassan');
  static final supervisorMohammed =
      Supervisor(id: IdGenerator.newId(), fullName: 'Mohammed Ali');

  static final projectAlpha = Project(
    id: IdGenerator.newId(),
    code: 'PRJ-A',
    name: 'Marina Tower - Site A',
    status: ProjectStatus.active,
    costCentre: 'CC-100',
  );
  static final projectBeta = Project(
    id: IdGenerator.newId(),
    code: 'PRJ-B',
    name: 'Marina Tower - Site B',
    status: ProjectStatus.active,
    costCentre: 'CC-200',
  );

  static final employeeAhmed = Employee(
    id: IdGenerator.newId(),
    employeeCode: 'EMP-1001',
    fullName: 'Ahmed Khan',
    position: 'Mason',
    status: EmployeeStatus.active,
    hireDate: DateTime(2023, 1, 10),
  );

  static final payrollPeriodAugust = PayrollPeriod(
    id: IdGenerator.newId(),
    startDate: DateTime(2026, 8, 1),
    endDate: DateTime(2026, 8, 31),
    status: PayrollPeriodStatus.open,
  );

  // ---- Effective-dated assignments (organisational, not payroll truth) --
  static List<Assignment> assignmentsForAhmed() => [
        Assignment(
          id: IdGenerator.newId(),
          employeeId: employeeAhmed.id,
          projectId: projectAlpha.id,
          supervisorId: supervisorTariq.id,
          effectiveFrom: DateTime(2026, 8, 1),
          effectiveTo: DateTime(2026, 8, 10),
        ),
        Assignment(
          id: IdGenerator.newId(),
          employeeId: employeeAhmed.id,
          projectId: projectBeta.id,
          supervisorId: supervisorMohammed.id,
          effectiveFrom: DateTime(2026, 8, 11),
          effectiveTo: null,
        ),
      ];

  // ---- Salary history: changes mid-period ---------------------------
  static List<SalaryHistory> salaryHistoryForAhmed() => [
        SalaryHistory(
          id: IdGenerator.newId(),
          employeeId: employeeAhmed.id,
          salaryType: SalaryType.monthly,
          amount: Money.fromMajor(3000, currency),
          effectiveFrom: DateTime(2025, 1, 1),
          effectiveTo: DateTime(2026, 8, 15),
          createdAt: DateTime(2025, 1, 1),
          createdBy: 'seed',
        ),
        SalaryHistory(
          id: IdGenerator.newId(),
          employeeId: employeeAhmed.id,
          salaryType: SalaryType.monthly,
          amount: Money.fromMajor(3300, currency),
          effectiveFrom: DateTime(2026, 8, 16),
          effectiveTo: null,
          reason: 'Annual increment',
          createdAt: DateTime(2026, 8, 16),
          createdBy: 'seed',
        ),
      ];

  // ---- Daily timesheets: 10 days on Project A / Tariq, 20 on Project B /
  // Mohammed, matching the exact scenario in architecture §28 test cases --
  static List<TimesheetEntry> timesheetsForAhmed() {
    final entries = <TimesheetEntry>[];
    DateTime d(int day) => DateTime(2026, 8, day);

    // 1–10 Aug: Project Alpha / Tariq, 8h/day, with OT on day 5 (weekday)
    for (var day = 1; day <= 10; day++) {
      if (day == 8) continue; // unpaid leave day, no timesheet entry
      entries.add(TimesheetEntry(
        id: IdGenerator.newId(),
        employeeId: employeeAhmed.id,
        date: d(day),
        projectId: projectAlpha.id,
        supervisorId: supervisorTariq.id,
        regularHours: 8,
        otHours: day == 5 ? 2 : 0,
        status: TimesheetStatus.approved,
        createdAt: d(day),
        updatedAt: d(day),
      ));
    }

    // 11–31 Aug: Project Beta / Mohammed, 8h/day, with OT on 21 Aug (a Friday
    // = the configured weekend day, so it exercises the weekend OT rate)
    for (var day = 11; day <= 31; day++) {
      entries.add(TimesheetEntry(
        id: IdGenerator.newId(),
        employeeId: employeeAhmed.id,
        date: d(day),
        projectId: projectBeta.id,
        supervisorId: supervisorMohammed.id,
        regularHours: d(day).weekday == DateTime.friday ? 0 : 8,
        otHours: day == 21 ? 3 : 0,
        status: TimesheetStatus.approved,
        createdAt: d(day),
        updatedAt: d(day),
      ));
    }
    return entries;
  }

  static List<AttendanceRecord> attendanceForAhmed() => [
        AttendanceRecord(
          id: IdGenerator.newId(),
          employeeId: employeeAhmed.id,
          date: DateTime(2026, 8, 8),
          status: AttendanceStatus.unpaidLeave,
          note: 'Personal leave, unpaid (no salary accrual per company policy).',
        ),
      ];

  static List<Earning> earningsForAhmed(String payrollPeriodId) => [
        Earning(
          id: IdGenerator.newId(),
          employeeId: employeeAhmed.id,
          payrollPeriodId: payrollPeriodId,
          typeName: 'Transport Allowance',
          recurrence: EarningRecurrence.fixed,
          amount: Money.fromMajor(150, currency),
          approved: true,
        ),
      ];

  static List<Deduction> deductionsForAhmed(String payrollPeriodId) => [
        Deduction(
          id: IdGenerator.newId(),
          employeeId: employeeAhmed.id,
          payrollPeriodId: payrollPeriodId,
          typeName: 'Uniform Advance Recovery',
          recurrence: DeductionRecurrence.oneOff,
          amount: Money.fromMajor(50, currency),
          approved: true,
        ),
      ];
}
