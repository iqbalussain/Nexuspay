import '../enums/enums.dart';
import '../value_objects/money.dart';

/// A configured earning (allowance) applied to an employee for a payroll
/// period. Only entries with `approved == true` are included in payroll
/// calculation (architecture §14 inputs).
class Earning {
  final String id;
  final String employeeId;
  final String payrollPeriodId;
  final String typeName; // e.g. "Housing Allowance" - see settings §39
  final EarningRecurrence recurrence;
  final Money amount;
  final bool approved;
  final String? note;

  const Earning({
    required this.id,
    required this.employeeId,
    required this.payrollPeriodId,
    required this.typeName,
    required this.recurrence,
    required this.amount,
    required this.approved,
    this.note,
  });
}
