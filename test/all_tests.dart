import '../lib/core/utils/id_generator.dart';
import '../lib/data/mock/mock_repositories.dart';
import '../lib/data/mock/seed_data.dart';
import '../lib/domain/entities/attendance_record.dart';
import '../lib/domain/entities/company_payroll_rules.dart';
import '../lib/domain/entities/deduction.dart';
import '../lib/domain/entities/earning.dart';
import '../lib/domain/entities/employee.dart';
import '../lib/domain/entities/payroll_adjustment.dart';
import '../lib/domain/entities/payroll_period.dart';
import '../lib/domain/entities/payroll_record.dart';
import '../lib/domain/entities/project.dart';
import '../lib/domain/entities/salary_history.dart';
import '../lib/domain/entities/timesheet_entry.dart';
import '../lib/domain/enums/enums.dart';
import '../lib/domain/services/payroll_calculation_service.dart';
import '../lib/domain/value_objects/money.dart';
import 'test_harness.dart';

const _engine = PayrollCalculationService();

void main() async {
  // -----------------------------------------------------------------
  // §28 scenario: multi-project/multi-supervisor + mid-period salary
  // change + regular & OT hours + one unpaid-leave day, all in one
  // payroll period. This is the single most important test in the
  // suite — it is exactly the scenario architecture §6/§18/§28 call out.
  // -----------------------------------------------------------------
  test(
      'payroll engine: multi-supervisor movement, mid-period salary change, '
      'regular+OT hours, and one unpaid-leave day calculate correctly', () async {
    final period = SeedData.payrollPeriodAugust;
    final rules = CompanyPayrollRules.placeholderDefaults();

    final input = PayrollCalculationInput(
      period: period,
      employee: SeedData.employeeAhmed,
      salaryHistory: SeedData.salaryHistoryForAhmed(),
      timesheets: SeedData.timesheetsForAhmed(),
      attendance: SeedData.attendanceForAhmed(),
      earnings: SeedData.earningsForAhmed(period.id),
      deductions: SeedData.deductionsForAhmed(period.id),
      rules: rules,
    );

    final result = _engine.calculate(input);
    expectTrue(result.isSuccess, 'Calculation should succeed: ${result.isFailure ? result.failure : ''}');
    final snapshot = result.value;

    // Hours aggregated across BOTH supervisors/projects.
    expect(snapshot.approvedRegularHours, 216.0, '9 days*8h (Alpha/Tariq) + 18 days*8h (Beta/Mohammed)');
    expect(snapshot.approvedOtHours, 5.0, '2h regular-day OT (5 Aug) + 3h weekend OT (21 Aug)');

    // Base pay: prorated across the two salary segments (15 days @3000/mo, 16 days @3300/mo).
    expect(snapshot.basePay, Money.fromMajor(3260.00, 'AED'));

    // Overtime: 5 Aug (regular, 1.25x of 12.50/hr) + 21 Aug (weekend, 1.5x of 13.75/hr).
    expect(snapshot.overtimePay, Money.fromMajor(93.15, 'AED'));

    // One unpaid-leave day (8 Aug), priced at the latest known daily rate.
    expect(snapshot.unpaidAbsenceDeduction, Money.fromMajor(110.00, 'AED'));

    expect(snapshot.allowancesTotal, Money.fromMajor(150.00, 'AED'));
    expect(snapshot.deductionsTotal, Money.fromMajor(50.00, 'AED'));

    expect(snapshot.grossPay, Money.fromMajor(3503.15, 'AED'));
    expect(snapshot.netPay, Money.fromMajor(3343.15, 'AED'));

    expectTrue(snapshot.warnings.isEmpty, 'Fully-approved, fully-rated period should produce no warnings: ${snapshot.warnings}');
    expect(snapshot.version, 1);
  });

  // -----------------------------------------------------------------
  // §28: "Attempt to edit finalized payroll" / period lock
  // -----------------------------------------------------------------
  test('finalized payroll period rejects new timesheet writes and new calculation snapshots',
      () async {
    final periodRepo = MockPayrollPeriodRepository([
      PayrollPeriod(
        id: 'period-1',
        startDate: DateTime(2026, 6, 1),
        endDate: DateTime(2026, 6, 30),
        status: PayrollPeriodStatus.open,
      ),
    ]);
    final timesheetRepo = MockTimesheetRepository([], periodRepo);
    final payrollRecordRepo = MockPayrollRecordRepository(periodRepo);

    // While open, a write succeeds.
    final entry = TimesheetEntry(
      id: IdGenerator.newId(),
      employeeId: 'emp-1',
      date: DateTime(2026, 6, 5),
      projectId: 'proj-1',
      supervisorId: 'sup-1',
      regularHours: 8,
      otHours: 0,
      status: TimesheetStatus.approved,
      createdAt: DateTime(2026, 6, 5),
      updatedAt: DateTime(2026, 6, 5),
    );
    await timesheetRepo.upsert(entry);

    await periodRepo.finalizePeriod('period-1', 'admin-user');

    // After lock, normal timesheet edits are rejected.
    await expectThrowsAsync(
      () => timesheetRepo.upsert(entry.copyWith(regularHours: 10)),
      'Editing a timesheet inside a locked period should throw',
    );

    // After lock, saving a fresh calculation snapshot is also rejected —
    // corrections must go through PayrollAdjustment instead.
    final dummySnapshot = PayrollCalculationSnapshot(
      employeeId: 'emp-1',
      payrollPeriodId: 'period-1',
      version: 1,
      calculatedAt: DateTime.now(),
      approvedRegularHours: 8,
      approvedOtHours: 0,
      basePay: Money.zero('AED'),
      overtimePay: Money.zero('AED'),
      allowancesTotal: Money.zero('AED'),
      adjustmentsCreditTotal: Money.zero('AED'),
      adjustmentsDebitTotal: Money.zero('AED'),
      deductionsTotal: Money.zero('AED'),
      unpaidAbsenceDeduction: Money.zero('AED'),
      grossPay: Money.zero('AED'),
      netPay: Money.zero('AED'),
      lineItems: const [],
    );
    await expectThrowsAsync(
      () => payrollRecordRepo.saveCalculation(PayrollRecord(
        id: 'rec-1',
        payrollPeriodId: 'period-1',
        employeeId: 'emp-1',
        status: PayrollRecordStatus.calculated,
        snapshot: dummySnapshot,
      )),
      'Saving a new calculation snapshot for a locked period should throw',
    );
  });

  // -----------------------------------------------------------------
  // §28: "A payroll adjustment is created after finalization"
  // -----------------------------------------------------------------
  test('payroll adjustments are append-only corrections against a finalized record', () async {
    final adjustmentRepo = MockPayrollAdjustmentRepository();

    final adjustment = PayrollAdjustment(
      id: IdGenerator.newId(),
      payrollRecordId: 'rec-1',
      type: AdjustmentType.credit,
      amount: Money.fromMajor(200, 'AED'),
      reason: 'Missed allowance discovered after finalization',
      createdBy: 'payroll-admin',
      createdAt: DateTime.now(),
    );
    await adjustmentRepo.add(adjustment);

    final forRecord = await adjustmentRepo.getForPayrollRecord('rec-1');
    expect(forRecord.length, 1);
    expect(forRecord.first.amount, Money.fromMajor(200, 'AED'));
    expect(forRecord.first.type, AdjustmentType.credit);

    // Recalculating with this adjustment as an input folds it into gross/net.
    final rules = CompanyPayrollRules.placeholderDefaults();
    final period = PayrollPeriod(
      id: 'period-1',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      status: PayrollPeriodStatus.finalized,
    );
    final employee = Employee(
      id: 'emp-1',
      employeeCode: 'E1',
      fullName: 'Test Employee',
      status: EmployeeStatus.active,
      hireDate: DateTime(2020, 1, 1),
    );
    final salary = SalaryHistory(
      id: 's1',
      employeeId: 'emp-1',
      salaryType: SalaryType.monthly,
      amount: Money.fromMajor(3000, 'AED'),
      effectiveFrom: DateTime(2020, 1, 1),
      createdAt: DateTime(2020, 1, 1),
      createdBy: 'seed',
    );

    final result = _engine.calculate(PayrollCalculationInput(
      period: period,
      employee: employee,
      salaryHistory: [salary],
      timesheets: const [],
      attendance: const [],
      earnings: const [],
      deductions: const [],
      existingAdjustments: [adjustment],
      rules: rules,
      previousVersion: 1,
    ));

    expectTrue(result.isSuccess);
    expect(result.value.adjustmentsCreditTotal, Money.fromMajor(200, 'AED'));
    expect(result.value.version, 2, 'Recalculation must bump the version, not overwrite it');
  });

  // -----------------------------------------------------------------
  // §28: "Employee is deactivated but historical payroll must remain visible"
  // -----------------------------------------------------------------
  test('deactivating an employee preserves historical records and queryability', () async {
    final employee = Employee(
      id: 'emp-1',
      employeeCode: 'E1',
      fullName: 'Historical Employee',
      status: EmployeeStatus.active,
      hireDate: DateTime(2020, 1, 1),
    );
    final repo = MockEmployeeRepository([employee]);

    await repo.deactivate('emp-1');
    final after = await repo.getEmployee('emp-1');

    expectTrue(after != null);
    expect(after!.status, EmployeeStatus.inactive);
    expect(after.id, 'emp-1', 'Same id — historical records keyed on this id remain resolvable');
    expect(after.fullName, 'Historical Employee', 'Deactivation must not scrub employee data');
  });

  // -----------------------------------------------------------------
  // §28: "A project closes while historical timesheets remain accessible"
  // -----------------------------------------------------------------
  test('closing a project keeps its historical timesheets fully queryable', () async {
    final project = Project(
      id: 'proj-1',
      code: 'P1',
      name: 'Old Site',
      status: ProjectStatus.active,
    );
    final projectRepo = MockProjectRepository([project]);
    final periodRepo = MockPayrollPeriodRepository([
      PayrollPeriod(
        id: 'period-1',
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 1, 31),
        status: PayrollPeriodStatus.open,
      ),
    ]);
    final timesheetRepo = MockTimesheetRepository([
      TimesheetEntry(
        id: 't1',
        employeeId: 'emp-1',
        date: DateTime(2026, 1, 10),
        projectId: 'proj-1',
        supervisorId: 'sup-1',
        regularHours: 8,
        otHours: 0,
        status: TimesheetStatus.approved,
        createdAt: DateTime(2026, 1, 10),
        updatedAt: DateTime(2026, 1, 10),
      ),
    ], periodRepo);

    await projectRepo.update(Project(
      id: 'proj-1',
      code: 'P1',
      name: 'Old Site',
      status: ProjectStatus.closed,
    ));

    final closedProject = await projectRepo.getProject('proj-1');
    expect(closedProject!.status, ProjectStatus.closed);

    final history = await timesheetRepo.getForPeriod(
      DateTime(2026, 1, 1),
      DateTime(2026, 1, 31),
      projectId: 'proj-1',
    );
    expect(history.length, 1, 'Historical timesheet for the now-closed project must still resolve');
  });

  // -----------------------------------------------------------------
  // Validation: missing salary/rate configuration must block finalization
  // -----------------------------------------------------------------
  test('calculation fails with MissingRateFailure when no salary covers the period', () async {
    final rules = CompanyPayrollRules.placeholderDefaults();
    final period = PayrollPeriod(
      id: 'period-1',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      status: PayrollPeriodStatus.open,
    );
    final employee = Employee(
      id: 'emp-1',
      employeeCode: 'E1',
      fullName: 'No Salary On File',
      status: EmployeeStatus.active,
      hireDate: DateTime(2026, 6, 1),
    );

    final result = _engine.calculate(PayrollCalculationInput(
      period: period,
      employee: employee,
      salaryHistory: const [], // nothing on file
      timesheets: const [],
      attendance: const [],
      earnings: const [],
      deductions: const [],
      rules: rules,
    ));

    expectTrue(result.isFailure, 'Calculation must fail, not silently produce zero pay');
    expect(result.failure.code, 'missing_rate');
  });

  // -----------------------------------------------------------------
  // Validation: unapproved timesheets/earnings/deductions must be excluded
  // -----------------------------------------------------------------
  test('unapproved timesheet, earning and deduction entries are excluded, with warnings', () async {
    final rules = CompanyPayrollRules.placeholderDefaults();
    final period = PayrollPeriod(
      id: 'period-1',
      startDate: DateTime(2026, 6, 1),
      endDate: DateTime(2026, 6, 30),
      status: PayrollPeriodStatus.open,
    );
    final employee = Employee(
      id: 'emp-1',
      employeeCode: 'E1',
      fullName: 'Pending Approvals',
      status: EmployeeStatus.active,
      hireDate: DateTime(2020, 1, 1),
    );
    final salary = SalaryHistory(
      id: 's1',
      employeeId: 'emp-1',
      salaryType: SalaryType.monthly,
      amount: Money.fromMajor(3000, 'AED'),
      effectiveFrom: DateTime(2020, 1, 1),
      createdAt: DateTime(2020, 1, 1),
      createdBy: 'seed',
    );
    final approvedEntry = TimesheetEntry(
      id: 't1',
      employeeId: 'emp-1',
      date: DateTime(2026, 6, 2),
      projectId: 'proj-1',
      supervisorId: 'sup-1',
      regularHours: 8,
      otHours: 0,
      status: TimesheetStatus.approved,
      createdAt: DateTime(2026, 6, 2),
      updatedAt: DateTime(2026, 6, 2),
    );
    final submittedEntry = TimesheetEntry(
      id: 't2',
      employeeId: 'emp-1',
      date: DateTime(2026, 6, 3),
      projectId: 'proj-1',
      supervisorId: 'sup-1',
      regularHours: 8,
      otHours: 0,
      status: TimesheetStatus.submitted, // not yet approved
      createdAt: DateTime(2026, 6, 3),
      updatedAt: DateTime(2026, 6, 3),
    );
    final pendingEarning = Earning(
      id: 'e1',
      employeeId: 'emp-1',
      payrollPeriodId: 'period-1',
      typeName: 'Bonus',
      recurrence: EarningRecurrence.fixed,
      amount: Money.fromMajor(500, 'AED'),
      approved: false,
    );
    final pendingDeduction = Deduction(
      id: 'd1',
      employeeId: 'emp-1',
      payrollPeriodId: 'period-1',
      typeName: 'Loan',
      recurrence: DeductionRecurrence.recurring,
      amount: Money.fromMajor(300, 'AED'),
      approved: false,
    );

    final result = _engine.calculate(PayrollCalculationInput(
      period: period,
      employee: employee,
      salaryHistory: [salary],
      timesheets: [approvedEntry, submittedEntry],
      attendance: const [],
      earnings: [pendingEarning],
      deductions: [pendingDeduction],
      rules: rules,
    ));

    expectTrue(result.isSuccess);
    final snapshot = result.value;
    expect(snapshot.approvedRegularHours, 8.0, 'Only the approved entry should count');
    expect(snapshot.allowancesTotal, Money.zero('AED'), 'Unapproved earning excluded');
    expect(snapshot.deductionsTotal, Money.zero('AED'), 'Unapproved deduction excluded');
    expectTrue(snapshot.warnings.length >= 3,
        'Expected warnings about the unapproved timesheet, earning and deduction; got ${snapshot.warnings}');
  });

  await runTests();
}
