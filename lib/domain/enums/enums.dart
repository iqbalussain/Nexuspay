enum EmployeeStatus { active, inactive, onLeave, terminated }

enum SalaryType { monthly, daily, hourly }

enum TimesheetStatus { draft, submitted, approved, returned }

enum AttendanceStatus { present, absent, paidLeave, unpaidLeave, publicHoliday }

/// Payroll period lifecycle. See architecture §15 "Payroll Workflow".
enum PayrollPeriodStatus {
  open, // attendance/timesheet entry in progress
  submitted, // supervisors have submitted for review
  underReview, // admin/payroll reviewing, corrections possible
  approved, // approved, ready to calculate
  calculated, // payroll engine has produced a snapshot, still editable
  finalized, // LOCKED — no normal edits; adjustments only
}

/// How a day should be rated when computing overtime.
enum DayType { regular, weekend, publicHoliday }

/// Overtime rules are configurable per company, not hard-coded.
/// See architecture §14: "Do not assume one universal overtime formula."
enum OvertimeRuleType {
  fixedHourlyRate, // flat AED/hr (etc.) regardless of base salary
  multiplierOfBaseHourlyRate, // e.g. 1.5x, 2x of derived base hourly rate
  weekendHolidayRate, // separate flat or multiplier rate for weekend/holiday
}

enum AdjustmentType { credit, debit }

enum DeductionRecurrence { recurring, oneOff }

enum EarningRecurrence { fixed, attendanceBased, projectBased }

enum PayrollRecordStatus { draft, calculated, approved, finalized }
