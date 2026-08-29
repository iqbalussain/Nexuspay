import '../enums/enums.dart';
import '../value_objects/money.dart';

/// A salary record effective for a date range. Never mutate/overwrite an
/// existing record to "change" salary — close it (`effectiveTo`) and add a
/// new one, so historical payroll can always be recomputed exactly as it
/// was calculated at the time. See architecture §13 & §17.
class SalaryHistory {
  final String id;
  final String employeeId;
  final SalaryType salaryType;

  /// Amount per the unit implied by [salaryType]: per month, per day, or
  /// per hour.
  final Money amount;

  final DateTime effectiveFrom;
  final DateTime? effectiveTo; // null = currently effective
  final String? reason;
  final DateTime createdAt;
  final String createdBy;

  const SalaryHistory({
    required this.id,
    required this.employeeId,
    required this.salaryType,
    required this.amount,
    required this.effectiveFrom,
    this.effectiveTo,
    this.reason,
    required this.createdAt,
    required this.createdBy,
  });
}
