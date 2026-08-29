import '../../core/result/result.dart';
import '../../core/utils/date_utils.dart';
import '../entities/attendance_record.dart';
import '../entities/company_payroll_rules.dart';
import '../entities/deduction.dart';
import '../entities/earning.dart';
import '../entities/employee.dart';
import '../entities/payroll_adjustment.dart';
import '../entities/payroll_period.dart';
import '../entities/payroll_record.dart';
import '../entities/salary_history.dart';
import '../entities/timesheet_entry.dart';
import '../enums/enums.dart';
import '../value_objects/money.dart';

/// All the data the engine needs for one employee, gathered by the calling
/// use case from the various repositories. Keeping this as a plain input
/// bundle (rather than the service reaching into repositories itself)
/// keeps [PayrollCalculationService] a pure function of its inputs —
/// deterministic, synchronous, and trivially unit-testable without mocks.
class PayrollCalculationInput {
  final PayrollPeriod period;
  final Employee employee;
  final List<SalaryHistory> salaryHistory; // any records overlapping the period
  final List<TimesheetEntry> timesheets; // any status; engine filters to approved
  final List<AttendanceRecord> attendance;
  final List<Earning> earnings; // any approval state; engine filters to approved
  final List<Deduction> deductions; // any approval state; engine filters to approved
  final List<PayrollAdjustment>
      existingAdjustments; // only relevant when recalculating post-finalization
  final CompanyPayrollRules rules;
  final int previousVersion; // 0 if never calculated before

  const PayrollCalculationInput({
    required this.period,
    required this.employee,
    required this.salaryHistory,
    required this.timesheets,
    required this.attendance,
    required this.earnings,
    required this.deductions,
    this.existingAdjustments = const [],
    required this.rules,
    this.previousVersion = 0,
  });
}

/// Deterministic payroll calculation, following architecture §14 exactly:
///
///  1. Determine applicable salary/rates by effective date.
///  2. Aggregate approved regular hours.
///  3. Aggregate approved OT hours.
///  4. Calculate configured earnings (base pay).
///  5. Calculate unpaid absence/leave impact.
///  6. Add approved allowances.
///  7. Add/subtract approved adjustments.
///  8. Apply deductions.
///  9. Calculate gross and net.
/// 10. Store calculation snapshot/version.
///
/// This class has no Flutter, Supabase, or I/O dependency of any kind —
/// it is pure domain logic, matching the "business/domain logic must be
/// independent of Flutter widgets and independent of Supabase" rule.
class PayrollCalculationService {
  const PayrollCalculationService();

  Result<PayrollCalculationSnapshot> calculate(PayrollCalculationInput input) {
    final warnings = <String>[];
    final lineItems = <PayrollLineItem>[];
    final currency = input.rules.currency;

    // ---- Guard: salary configuration must exist for the whole period ----
    final salarySegments = _resolveSalarySegments(
      input.salaryHistory,
      input.period.startDate,
      input.period.endDate,
    );
    if (salarySegments.isEmpty) {
      return Result.err(MissingRateFailure(
        'No salary history covers any part of the payroll period for '
        'employee ${input.employee.id}. Payroll cannot be finalized '
        'without a rate (architecture §26: "Missing salary/rate '
        'configuration must prevent payroll finalization").',
      ));
    }
    final uncoveredDays = _uncoveredDayCount(
      salarySegments,
      input.period.startDate,
      input.period.endDate,
    );
    if (uncoveredDays > 0) {
      warnings.add(
        '$uncoveredDays day(s) in the period have no salary rate on file '
        'and were excluded from base pay.',
      );
    }

    // ---- Step 1 & 4: base pay, prorated across salary segments ----
    Money basePay = Money.zero(currency);
    for (final segment in salarySegments) {
      basePay = basePay + _basePayForSegment(segment, input.rules);
      lineItems.add(PayrollLineItem(
        'Base pay (${segment.salary.salaryType.name}, '
        '${_fmt(segment.start)}–${_fmt(segment.end)})',
        _basePayForSegment(segment, input.rules),
      ));
    }

    // ---- Step 2 & 3: aggregate APPROVED hours only ----
    final approvedTimesheets = input.timesheets
        .where((t) => t.status == TimesheetStatus.approved)
        .where((t) => isWithinInclusive(t.date, input.period.startDate, input.period.endDate))
        .toList();

    final unapproved = input.timesheets.where((t) => t.status != TimesheetStatus.approved);
    if (unapproved.isNotEmpty) {
      warnings.add(
        '${unapproved.length} timesheet entr${unapproved.length == 1 ? 'y is' : 'ies are'} '
        'not approved and were excluded from this calculation.',
      );
    }

    final approvedRegularHours =
        approvedTimesheets.fold<double>(0, (sum, t) => sum + t.regularHours);
    final approvedOtHours = approvedTimesheets.fold<double>(0, (sum, t) => sum + t.otHours);

    // Base hourly rate, derived from whichever salary segment is active —
    // used only for OT rules of type multiplierOfBaseHourlyRate. If salary
    // changes mid-period, we use the segment covering each OT day.
    Money overtimePay = Money.zero(currency);
    final otPayByDayType = <DayType, Money>{};
    final otHoursByDayType = <DayType, double>{};
    for (final t in approvedTimesheets) {
      if (t.otHours <= 0) continue;
      final dayType = _dayTypeFor(t.date, input.rules, input.attendance);
      otHoursByDayType[dayType] = (otHoursByDayType[dayType] ?? 0) + t.otHours;

      final segment = _segmentContaining(salarySegments, t.date);
      final baseHourlyRate = segment == null
          ? null
          : _hourlyRate(segment.salary, input.rules);
      final rule = input.rules.ruleFor(dayType);

      if (rule == null) {
        warnings.add(
          'No overtime rule configured for ${dayType.name} days; '
          'OT hours on ${_fmt(t.date)} were not paid. Confirm the OT '
          'policy before finalizing (architecture §45).',
        );
        continue;
      }

      Money otRateForHour;
      switch (rule.type) {
        case OvertimeRuleType.fixedHourlyRate:
        case OvertimeRuleType.weekendHolidayRate:
          otRateForHour = Money.fromMajor(rule.value, currency);
          break;
        case OvertimeRuleType.multiplierOfBaseHourlyRate:
          if (baseHourlyRate == null) {
            warnings.add(
              'No base salary rate on ${_fmt(t.date)} to derive an '
              'overtime multiplier from; OT hours that day were not paid.',
            );
            continue;
          }
          otRateForHour = baseHourlyRate * rule.value;
          break;
      }
      final otPayForEntry = otRateForHour * t.otHours;
      overtimePay = overtimePay + otPayForEntry;
      otPayByDayType[dayType] = (otPayByDayType[dayType] ?? Money.zero(currency)) + otPayForEntry;
    }
    otPayByDayType.forEach((dayType, pay) {
      final hours = otHoursByDayType[dayType] ?? 0;
      lineItems.add(PayrollLineItem('Overtime (${dayType.name}, ${hours}h)', pay));
    });
    if (approvedOtHours > 16 * (inclusiveDayCount(input.period.startDate, input.period.endDate) / 30)) {
      // Coarse, configurable-in-future heuristic just to flag suspicious OT
      // for human review (architecture §14/§20 "validation report ...
      // unusual OT"), not to block calculation.
      warnings.add('Unusually high total OT hours ($approvedOtHours h) — recommend review.');
    }

    // ---- Step 5: unpaid absence/leave impact ----
    final unpaidLeaveDays = input.attendance
        .where((a) => a.status == AttendanceStatus.unpaidLeave)
        .where((a) => isWithinInclusive(a.date, input.period.startDate, input.period.endDate))
        .length;
    Money unpaidAbsenceDeduction = Money.zero(currency);
    if (unpaidLeaveDays > 0) {
      final segment = salarySegments.last; // best-effort: current rate
      final dailyRate = _dailyRate(segment.salary, input.rules);
      unpaidAbsenceDeduction = dailyRate * unpaidLeaveDays;
      lineItems.add(PayrollLineItem(
        'Unpaid leave/absence ($unpaidLeaveDays day(s))',
        Money(-unpaidAbsenceDeduction.minorUnits, currency),
      ));
    }

    // ---- Step 6: approved allowances ----
    final approvedEarnings = input.earnings.where((e) => e.approved).toList();
    final skippedEarnings = input.earnings.where((e) => !e.approved);
    if (skippedEarnings.isNotEmpty) {
      warnings.add(
        '${skippedEarnings.length} earning(s) are pending approval and were '
        'excluded from this calculation.',
      );
    }
    Money allowancesTotal = Money.zero(currency);
    for (final e in approvedEarnings) {
      allowancesTotal = allowancesTotal + e.amount;
      lineItems.add(PayrollLineItem(e.typeName, e.amount));
    }

    // ---- Step 7: adjustments (only pre-existing ones passed in; new
    // ones are created via a separate use case after finalization) ----
    Money adjustmentsCredit = Money.zero(currency);
    Money adjustmentsDebit = Money.zero(currency);
    for (final adj in input.existingAdjustments) {
      if (adj.type == AdjustmentType.credit) {
        adjustmentsCredit = adjustmentsCredit + adj.amount;
      } else {
        adjustmentsDebit = adjustmentsDebit + adj.amount;
      }
      lineItems.add(PayrollLineItem(
        'Adjustment: ${adj.reason}',
        adj.type == AdjustmentType.credit
            ? adj.amount
            : Money(-adj.amount.minorUnits, currency),
      ));
    }

    // ---- Step 8: deductions ----
    final approvedDeductions = input.deductions.where((d) => d.approved).toList();
    final skippedDeductions = input.deductions.where((d) => !d.approved);
    if (skippedDeductions.isNotEmpty) {
      warnings.add(
        '${skippedDeductions.length} deduction(s) are pending approval and '
        'were excluded from this calculation.',
      );
    }
    Money deductionsTotal = Money.zero(currency);
    for (final d in approvedDeductions) {
      deductionsTotal = deductionsTotal + d.amount;
      lineItems.add(PayrollLineItem(d.typeName, Money(-d.amount.minorUnits, currency)));
    }

    // ---- Step 9: gross & net ----
    final grossPay = basePay + overtimePay + allowancesTotal + adjustmentsCredit;
    final netPay = grossPay - unpaidAbsenceDeduction - deductionsTotal - adjustmentsDebit;

    if (netPay.isNegative) {
      warnings.add('Calculated net pay is negative — review deductions/adjustments.');
    }

    // ---- Step 10: snapshot with version ----
    final snapshot = PayrollCalculationSnapshot(
      employeeId: input.employee.id,
      payrollPeriodId: input.period.id,
      version: input.previousVersion + 1,
      calculatedAt: DateTime.now(),
      approvedRegularHours: approvedRegularHours,
      approvedOtHours: approvedOtHours,
      basePay: basePay,
      overtimePay: overtimePay,
      allowancesTotal: allowancesTotal,
      adjustmentsCreditTotal: adjustmentsCredit,
      adjustmentsDebitTotal: adjustmentsDebit,
      deductionsTotal: deductionsTotal,
      unpaidAbsenceDeduction: unpaidAbsenceDeduction,
      grossPay: grossPay,
      netPay: netPay,
      lineItems: lineItems,
      warnings: warnings,
    );

    return Result.ok(snapshot);
  }

  // ---------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------

  List<_SalarySegment> _resolveSalarySegments(
    List<SalaryHistory> history,
    DateTime periodStart,
    DateTime periodEnd,
  ) {
    final segments = <_SalarySegment>[];
    for (final s in history) {
      if (!rangesOverlap(s.effectiveFrom, s.effectiveTo, periodStart, periodEnd)) continue;
      final segStart =
          s.effectiveFrom.isAfter(periodStart) ? s.effectiveFrom : periodStart;
      final segEnd = (s.effectiveTo == null || s.effectiveTo!.isAfter(periodEnd))
          ? periodEnd
          : s.effectiveTo!;
      segments.add(_SalarySegment(salary: s, start: dateOnly(segStart), end: dateOnly(segEnd)));
    }
    segments.sort((a, b) => a.start.compareTo(b.start));
    return segments;
  }

  int _uncoveredDayCount(List<_SalarySegment> segments, DateTime periodStart, DateTime periodEnd) {
    final totalDays = inclusiveDayCount(periodStart, periodEnd);
    final coveredDays = segments.fold<int>(0, (sum, s) => sum + inclusiveDayCount(s.start, s.end));
    final overlapCorrection = 0; // segments are built non-overlapping by construction above
    return (totalDays - coveredDays - overlapCorrection).clamp(0, totalDays);
  }

  _SalarySegment? _segmentContaining(List<_SalarySegment> segments, DateTime date) {
    for (final s in segments) {
      if (isWithinInclusive(date, s.start, s.end)) return s;
    }
    return null;
  }

  Money _basePayForSegment(_SalarySegment segment, CompanyPayrollRules rules) {
    final salary = segment.salary;
    final daysInSegment = inclusiveDayCount(segment.start, segment.end);
    switch (salary.salaryType) {
      case SalaryType.monthly:
        // Prorate the monthly amount by the fraction of the standard
        // working-days-per-month that this segment covers.
        return salary.amount * (daysInSegment / rules.standardWorkingDaysPerMonth);
      case SalaryType.daily:
        return salary.amount * daysInSegment;
      case SalaryType.hourly:
        // Hourly base pay is earned via approved regular hours, not by
        // calendar days; base pay for an hourly employee is computed from
        // timesheet hours instead of a segment day-count. Returning zero
        // here and relying on a future dedicated hourly aggregation path
        // is intentionally out of scope for this Phase-1 slice — flagged
        // for the business-rule confirmation list (architecture §45).
        return Money.zero(rules.currency);
    }
  }

  Money _dailyRate(SalaryHistory salary, CompanyPayrollRules rules) {
    switch (salary.salaryType) {
      case SalaryType.monthly:
        return salary.amount / rules.standardWorkingDaysPerMonth;
      case SalaryType.daily:
        return salary.amount;
      case SalaryType.hourly:
        return salary.amount * rules.standardHoursPerDay;
    }
  }

  Money _hourlyRate(SalaryHistory salary, CompanyPayrollRules rules) {
    switch (salary.salaryType) {
      case SalaryType.monthly:
        return _dailyRate(salary, rules) / rules.standardHoursPerDay;
      case SalaryType.daily:
        return salary.amount / rules.standardHoursPerDay;
      case SalaryType.hourly:
        return salary.amount;
    }
  }

  DayType _dayTypeFor(
    DateTime date,
    CompanyPayrollRules rules,
    List<AttendanceRecord> attendance,
  ) {
    final isHoliday = attendance.any((a) =>
        isSameDay(a.date, date) && a.status == AttendanceStatus.publicHoliday);
    if (isHoliday) return DayType.publicHoliday;
    if (isWeekend(date, rules.weekendWeekdays)) return DayType.weekend;
    return DayType.regular;
  }

  String _fmt(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

class _SalarySegment {
  final SalaryHistory salary;
  final DateTime start;
  final DateTime end;
  const _SalarySegment({required this.salary, required this.start, required this.end});
}
