import '../../core/utils/date_utils.dart';
import '../../core/utils/id_generator.dart';
import '../../domain/entities/assignment.dart';
import '../../domain/entities/attendance_record.dart';
import '../../domain/entities/audit_log_entry.dart';
import '../../domain/entities/deduction.dart';
import '../../domain/entities/earning.dart';
import '../../domain/entities/employee.dart';
import '../../domain/entities/payroll_adjustment.dart';
import '../../domain/entities/payroll_period.dart';
import '../../domain/entities/payroll_record.dart';
import '../../domain/entities/project.dart';
import '../../domain/entities/salary_history.dart';
import '../../domain/entities/supervisor.dart';
import '../../domain/entities/timesheet_entry.dart';
import '../../domain/enums/enums.dart';
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

/// Thrown by mock repositories for state errors that a real backend would
/// also reject (e.g. writing to a locked payroll period). Use cases
/// should catch domain-meaningful cases like this and translate to a
/// [Result] failure; kept as an exception here (rather than a Result) so
/// the repository *interface* signatures match the architecture doc's
/// example exactly (`Future<Employee> create(...)`, no Result wrapper) —
/// Result-wrapping can be added at the interface level later without
/// touching this mock's internals.
class RepositoryStateError extends StateError {
  RepositoryStateError(super.message);
}

// ---------------------------------------------------------------------
// Employee
// ---------------------------------------------------------------------
class MockEmployeeRepository implements EmployeeRepository {
  final List<Employee> _employees;
  MockEmployeeRepository(List<Employee> seed) : _employees = List.of(seed);

  @override
  Future<Employee> create(Employee employee) async {
    _employees.add(employee);
    return employee;
  }

  @override
  Future<void> deactivate(String id) async {
    final idx = _employees.indexWhere((e) => e.id == id);
    if (idx == -1) throw RepositoryStateError('Employee $id not found');
    // Deactivation flips status only; all historical salary/timesheet/
    // payroll records referencing this id remain untouched and queryable
    // (architecture §17: "deactivation must preserve historical records").
    _employees[idx] = _employees[idx].copyWith(status: EmployeeStatus.inactive);
  }

  @override
  Future<Employee?> getEmployee(String id) async {
    try {
      return _employees.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Employee>> getEmployees(EmployeeFilter filter) async {
    return _employees.where((e) {
      if (filter.status != null && e.status != filter.status) return false;
      if (filter.searchText != null && filter.searchText!.isNotEmpty) {
        final q = filter.searchText!.toLowerCase();
        if (!e.fullName.toLowerCase().contains(q) &&
            !e.employeeCode.toLowerCase().contains(q)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  @override
  Future<Employee> update(Employee employee) async {
    final idx = _employees.indexWhere((e) => e.id == employee.id);
    if (idx == -1) throw RepositoryStateError('Employee ${employee.id} not found');
    _employees[idx] = employee;
    return employee;
  }
}

// ---------------------------------------------------------------------
// Salary history
// ---------------------------------------------------------------------
class MockSalaryHistoryRepository implements SalaryHistoryRepository {
  final List<SalaryHistory> _records;
  MockSalaryHistoryRepository(List<SalaryHistory> seed) : _records = List.of(seed);

  @override
  Future<SalaryHistory> addSalaryChange(SalaryHistory newRecord) async {
    // Close any currently-open record for this employee rather than
    // overwriting it — historical amounts are immutable.
    for (var i = 0; i < _records.length; i++) {
      final r = _records[i];
      if (r.employeeId == newRecord.employeeId && r.effectiveTo == null) {
        _records[i] = SalaryHistory(
          id: r.id,
          employeeId: r.employeeId,
          salaryType: r.salaryType,
          amount: r.amount,
          effectiveFrom: r.effectiveFrom,
          effectiveTo: newRecord.effectiveFrom.subtract(const Duration(days: 1)),
          reason: r.reason,
          createdAt: r.createdAt,
          createdBy: r.createdBy,
        );
      }
    }
    _records.add(newRecord);
    return newRecord;
  }

  @override
  Future<List<SalaryHistory>> getEffectiveInRange(
      String employeeId, DateTime start, DateTime end) async {
    return _records
        .where((r) => r.employeeId == employeeId)
        .where((r) => rangesOverlap(r.effectiveFrom, r.effectiveTo, start, end))
        .toList();
  }

  @override
  Future<List<SalaryHistory>> getForEmployee(String employeeId) async {
    return _records.where((r) => r.employeeId == employeeId).toList();
  }
}

// ---------------------------------------------------------------------
// Supervisor / Project (simple master data)
// ---------------------------------------------------------------------
class MockSupervisorRepository implements SupervisorRepository {
  final List<Supervisor> _items;
  MockSupervisorRepository(List<Supervisor> seed) : _items = List.of(seed);

  @override
  Future<Supervisor> create(Supervisor supervisor) async {
    _items.add(supervisor);
    return supervisor;
  }

  @override
  Future<Supervisor?> getSupervisor(String id) async {
    try {
      return _items.firstWhere((s) => s.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Supervisor>> getSupervisors({bool activeOnly = true}) async =>
      _items.where((s) => !activeOnly || s.active).toList();

  @override
  Future<Supervisor> update(Supervisor supervisor) async {
    final idx = _items.indexWhere((s) => s.id == supervisor.id);
    if (idx == -1) throw RepositoryStateError('Supervisor ${supervisor.id} not found');
    _items[idx] = supervisor;
    return supervisor;
  }
}

class MockProjectRepository implements ProjectRepository {
  final List<Project> _items;
  MockProjectRepository(List<Project> seed) : _items = List.of(seed);

  @override
  Future<Project> create(Project project) async {
    _items.add(project);
    return project;
  }

  @override
  Future<Project?> getProject(String id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<Project>> getProjects({ProjectStatus? status}) async =>
      _items.where((p) => status == null || p.status == status).toList();

  @override
  Future<Project> update(Project project) async {
    final idx = _items.indexWhere((p) => p.id == project.id);
    if (idx == -1) throw RepositoryStateError('Project ${project.id} not found');
    // Closing a project (status -> closed) never removes it, so historical
    // timesheets referencing it remain fully resolvable (architecture §18).
    _items[idx] = project;
    return project;
  }
}

// ---------------------------------------------------------------------
// Assignment
// ---------------------------------------------------------------------
class MockAssignmentRepository implements AssignmentRepository {
  final List<Assignment> _items;
  MockAssignmentRepository(List<Assignment> seed) : _items = List.of(seed);

  @override
  Future<Assignment> create(Assignment assignment) async {
    _items.add(assignment);
    return assignment;
  }

  @override
  Future<List<Assignment>> getForEmployee(String employeeId) async =>
      _items.where((a) => a.employeeId == employeeId).toList();

  @override
  Future<List<Assignment>> getOverlapping(
      String employeeId, DateTime start, DateTime end) async {
    return _items
        .where((a) => a.employeeId == employeeId)
        .where((a) => rangesOverlap(a.effectiveFrom, a.effectiveTo, start, end))
        .toList();
  }

  @override
  Future<Assignment> reassign(Assignment newAssignment) async {
    for (var i = 0; i < _items.length; i++) {
      final a = _items[i];
      if (a.employeeId == newAssignment.employeeId && a.effectiveTo == null) {
        _items[i] = Assignment(
          id: a.id,
          employeeId: a.employeeId,
          projectId: a.projectId,
          supervisorId: a.supervisorId,
          effectiveFrom: a.effectiveFrom,
          effectiveTo: newAssignment.effectiveFrom.subtract(const Duration(days: 1)),
        );
      }
    }
    _items.add(newAssignment);
    return newAssignment;
  }
}

// ---------------------------------------------------------------------
// Attendance
// ---------------------------------------------------------------------
class MockAttendanceRepository implements AttendanceRepository {
  final List<AttendanceRecord> _items;
  MockAttendanceRepository(List<AttendanceRecord> seed) : _items = List.of(seed);

  @override
  Future<List<AttendanceRecord>> getForEmployeeInRange(
      String employeeId, DateTime start, DateTime end) async {
    return _items
        .where((a) => a.employeeId == employeeId)
        .where((a) => isWithinInclusive(a.date, start, end))
        .toList();
  }

  @override
  Future<List<AttendanceRecord>> getForPeriod(DateTime start, DateTime end) async {
    return _items.where((a) => isWithinInclusive(a.date, start, end)).toList();
  }

  @override
  Future<AttendanceRecord> upsert(AttendanceRecord record) async {
    final idx = _items.indexWhere(
        (a) => a.employeeId == record.employeeId && isSameDay(a.date, record.date));
    if (idx == -1) {
      _items.add(record);
    } else {
      _items[idx] = record;
    }
    return record;
  }
}

// ---------------------------------------------------------------------
// Timesheet — enforces the no-duplicate-row and locked-period rules
// ---------------------------------------------------------------------
class MockTimesheetRepository implements TimesheetRepository {
  final List<TimesheetEntry> _items;
  final PayrollPeriodRepository _periodRepository;
  MockTimesheetRepository(List<TimesheetEntry> seed, this._periodRepository)
      : _items = List.of(seed);

  Future<void> _assertPeriodOpenFor(DateTime date) async {
    final period = await _periodRepository.getContaining(date);
    if (period != null && period.isLocked) {
      throw RepositoryStateError(
        'Payroll period ${period.id} covering $date is finalized/locked. '
        'Use a payroll adjustment instead of editing the timesheet '
        '(architecture §2, §15, §26).',
      );
    }
  }

  @override
  Future<List<TimesheetEntry>> getForEmployeeInRange(
      String employeeId, DateTime start, DateTime end) async {
    return _items
        .where((t) => t.employeeId == employeeId)
        .where((t) => isWithinInclusive(t.date, start, end))
        .toList();
  }

  @override
  Future<List<TimesheetEntry>> getForPeriod(
    DateTime start,
    DateTime end, {
    String? projectId,
    String? supervisorId,
    TimesheetStatus? status,
  }) async {
    return _items
        .where((t) => isWithinInclusive(t.date, start, end))
        .where((t) => projectId == null || t.projectId == projectId)
        .where((t) => supervisorId == null || t.supervisorId == supervisorId)
        .where((t) => status == null || t.status == status)
        .toList();
  }

  @override
  Future<TimesheetEntry> upsert(TimesheetEntry entry) async {
    await _assertPeriodOpenFor(entry.date);
    final idx = _items.indexWhere((t) =>
        t.employeeId == entry.employeeId &&
        isSameDay(t.date, entry.date) &&
        t.projectId == entry.projectId &&
        t.supervisorId == entry.supervisorId);
    if (idx == -1) {
      _items.add(entry);
    } else {
      _items[idx] = entry;
    }
    return entry;
  }

  @override
  Future<TimesheetEntry> approve(String id, String approvedBy) async {
    final idx = _items.indexWhere((t) => t.id == id);
    if (idx == -1) throw RepositoryStateError('Timesheet $id not found');
    await _assertPeriodOpenFor(_items[idx].date);
    _items[idx] = _items[idx].copyWith(
      status: TimesheetStatus.approved,
      approvedBy: approvedBy,
      approvedAt: DateTime.now(),
    );
    return _items[idx];
  }

  @override
  Future<TimesheetEntry> returnForCorrection(String id, String reason) async {
    final idx = _items.indexWhere((t) => t.id == id);
    if (idx == -1) throw RepositoryStateError('Timesheet $id not found');
    _items[idx] =
        _items[idx].copyWith(status: TimesheetStatus.returned, note: reason);
    return _items[idx];
  }

  @override
  Future<TimesheetEntry> submit(String id) async {
    final idx = _items.indexWhere((t) => t.id == id);
    if (idx == -1) throw RepositoryStateError('Timesheet $id not found');
    _items[idx] = _items[idx].copyWith(status: TimesheetStatus.submitted);
    return _items[idx];
  }
}

// ---------------------------------------------------------------------
// Payroll period — owns the lock
// ---------------------------------------------------------------------
class MockPayrollPeriodRepository implements PayrollPeriodRepository {
  final List<PayrollPeriod> _items;
  MockPayrollPeriodRepository(List<PayrollPeriod> seed) : _items = List.of(seed);

  @override
  Future<PayrollPeriod> create(PayrollPeriod period) async {
    _items.add(period);
    return period;
  }

  @override
  Future<PayrollPeriod> finalizePeriod(String id, String finalizedBy) async {
    final idx = _items.indexWhere((p) => p.id == id);
    if (idx == -1) throw RepositoryStateError('Payroll period $id not found');
    if (_items[idx].isLocked) {
      throw RepositoryStateError('Payroll period $id is already finalized.');
    }
    _items[idx] = _items[idx].copyWith(
      status: PayrollPeriodStatus.finalized,
      finalizedAt: DateTime.now(),
      finalizedBy: finalizedBy,
    );
    return _items[idx];
  }

  @override
  Future<List<PayrollPeriod>> getAll() async => List.of(_items);

  @override
  Future<PayrollPeriod?> getById(String id) async {
    try {
      return _items.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PayrollPeriod?> getContaining(DateTime date) async {
    try {
      return _items.firstWhere((p) => isWithinInclusive(date, p.startDate, p.endDate));
    } catch (_) {
      return null;
    }
  }

  @override
  Future<PayrollPeriod> updateStatus(String id, PayrollPeriodStatus status) async {
    final idx = _items.indexWhere((p) => p.id == id);
    if (idx == -1) throw RepositoryStateError('Payroll period $id not found');
    if (_items[idx].isLocked) {
      throw RepositoryStateError('Payroll period $id is finalized and cannot change status.');
    }
    _items[idx] = _items[idx].copyWith(status: status);
    return _items[idx];
  }
}

// ---------------------------------------------------------------------
// Earnings / Deductions
// ---------------------------------------------------------------------
class MockEarningRepository implements EarningRepository {
  final List<Earning> _items;
  MockEarningRepository(List<Earning> seed) : _items = List.of(seed);

  @override
  Future<Earning> approve(String id) async {
    final idx = _items.indexWhere((e) => e.id == id);
    if (idx == -1) throw RepositoryStateError('Earning $id not found');
    final e = _items[idx];
    _items[idx] = Earning(
      id: e.id,
      employeeId: e.employeeId,
      payrollPeriodId: e.payrollPeriodId,
      typeName: e.typeName,
      recurrence: e.recurrence,
      amount: e.amount,
      approved: true,
      note: e.note,
    );
    return _items[idx];
  }

  @override
  Future<List<Earning>> getForEmployeeInPeriod(
      String employeeId, String payrollPeriodId) async {
    return _items
        .where((e) => e.employeeId == employeeId && e.payrollPeriodId == payrollPeriodId)
        .toList();
  }

  @override
  Future<Earning> upsert(Earning earning) async {
    final idx = _items.indexWhere((e) => e.id == earning.id);
    if (idx == -1) {
      _items.add(earning);
    } else {
      _items[idx] = earning;
    }
    return earning;
  }
}

class MockDeductionRepository implements DeductionRepository {
  final List<Deduction> _items;
  MockDeductionRepository(List<Deduction> seed) : _items = List.of(seed);

  @override
  Future<Deduction> approve(String id) async {
    final idx = _items.indexWhere((d) => d.id == id);
    if (idx == -1) throw RepositoryStateError('Deduction $id not found');
    final d = _items[idx];
    _items[idx] = Deduction(
      id: d.id,
      employeeId: d.employeeId,
      payrollPeriodId: d.payrollPeriodId,
      typeName: d.typeName,
      recurrence: d.recurrence,
      amount: d.amount,
      approved: true,
      note: d.note,
    );
    return _items[idx];
  }

  @override
  Future<List<Deduction>> getForEmployeeInPeriod(
      String employeeId, String payrollPeriodId) async {
    return _items
        .where((d) => d.employeeId == employeeId && d.payrollPeriodId == payrollPeriodId)
        .toList();
  }

  @override
  Future<Deduction> upsert(Deduction deduction) async {
    final idx = _items.indexWhere((d) => d.id == deduction.id);
    if (idx == -1) {
      _items.add(deduction);
    } else {
      _items[idx] = deduction;
    }
    return deduction;
  }
}

// ---------------------------------------------------------------------
// Payroll adjustments — append-only
// ---------------------------------------------------------------------
class MockPayrollAdjustmentRepository implements PayrollAdjustmentRepository {
  final List<PayrollAdjustment> _items = [];

  @override
  Future<PayrollAdjustment> add(PayrollAdjustment adjustment) async {
    _items.add(adjustment);
    return adjustment;
  }

  @override
  Future<List<PayrollAdjustment>> getForPayrollRecord(String payrollRecordId) async {
    return _items.where((a) => a.payrollRecordId == payrollRecordId).toList();
  }
}

// ---------------------------------------------------------------------
// Payroll record — rejects new calculation snapshots for locked periods
// ---------------------------------------------------------------------
class MockPayrollRecordRepository implements PayrollRecordRepository {
  final List<PayrollRecord> _items = [];
  final PayrollPeriodRepository _periodRepository;
  MockPayrollRecordRepository(this._periodRepository);

  @override
  Future<PayrollRecord> approve(String id) async {
    final idx = _items.indexWhere((r) => r.id == id);
    if (idx == -1) throw RepositoryStateError('Payroll record $id not found');
    _items[idx] = _items[idx].copyWith(status: PayrollRecordStatus.approved);
    return _items[idx];
  }

  @override
  Future<PayrollRecord?> getForEmployeeInPeriod(
      String employeeId, String payrollPeriodId) async {
    try {
      return _items.firstWhere(
          (r) => r.employeeId == employeeId && r.payrollPeriodId == payrollPeriodId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<PayrollRecord>> getForPeriod(String payrollPeriodId) async =>
      _items.where((r) => r.payrollPeriodId == payrollPeriodId).toList();

  @override
  Future<PayrollRecord> saveCalculation(PayrollRecord record) async {
    final period = await _periodRepository.getById(record.payrollPeriodId);
    if (period != null && period.isLocked) {
      throw RepositoryStateError(
        'Payroll period ${period.id} is finalized/locked. A new '
        'calculation snapshot cannot be saved — create a '
        'PayrollAdjustment instead (architecture §15).',
      );
    }
    final idx = _items.indexWhere(
        (r) => r.employeeId == record.employeeId && r.payrollPeriodId == record.payrollPeriodId);
    if (idx == -1) {
      _items.add(record);
    } else {
      _items[idx] = record;
    }
    return record;
  }
}

// ---------------------------------------------------------------------
// Audit log
// ---------------------------------------------------------------------
class MockAuditLogRepository implements AuditLogRepository {
  final List<AuditLogEntry> _items = [];

  @override
  Future<List<AuditLogEntry>> getForEntity(String entityType, String entityId) async {
    return _items
        .where((e) => e.entityType == entityType && e.entityId == entityId)
        .toList();
  }

  @override
  Future<List<AuditLogEntry>> getRecent({int limit = 100}) async {
    final sorted = List.of(_items)..sort((a, b) => b.performedAt.compareTo(a.performedAt));
    return sorted.take(limit).toList();
  }

  @override
  Future<void> record(AuditLogEntry entry) async {
    _items.add(entry);
  }
}

/// Convenience id helper re-exported so callers building new entities in
/// use cases don't need to import IdGenerator directly from core in every
/// feature module.
String newId() => IdGenerator.newId();
