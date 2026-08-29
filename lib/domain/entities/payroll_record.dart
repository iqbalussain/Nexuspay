import '../enums/enums.dart';
import '../value_objects/money.dart';

/// A per-day breakdown line inside a [PayrollCalculationSnapshot], kept so
/// the calculation is fully explainable/auditable rather than a black-box
/// total (architecture §14 step 10: "Store calculation snapshot/version").
class PayrollLineItem {
  final String label; // e.g. "Regular hours", "Overtime (weekend)", "Housing Allowance"
  final Money amount;

  const PayrollLineItem(this.label, this.amount);
}

/// The immutable output of one run of [PayrollCalculationService] for one
/// employee in one period. A new calculation always produces a new
/// snapshot with an incremented [version] rather than mutating the
/// previous one (architecture §15: "Recalculation must create a
/// traceable calculation version").
class PayrollCalculationSnapshot {
  final String employeeId;
  final String payrollPeriodId;
  final int version;
  final DateTime calculatedAt;

  final double approvedRegularHours;
  final double approvedOtHours;

  final Money basePay;
  final Money overtimePay;
  final Money allowancesTotal;
  final Money adjustmentsCreditTotal;
  final Money adjustmentsDebitTotal;
  final Money deductionsTotal;
  final Money unpaidAbsenceDeduction;

  final Money grossPay;
  final Money netPay;

  final List<PayrollLineItem> lineItems;
  final List<String> warnings; // e.g. "Unusual OT hours", non-blocking

  const PayrollCalculationSnapshot({
    required this.employeeId,
    required this.payrollPeriodId,
    required this.version,
    required this.calculatedAt,
    required this.approvedRegularHours,
    required this.approvedOtHours,
    required this.basePay,
    required this.overtimePay,
    required this.allowancesTotal,
    required this.adjustmentsCreditTotal,
    required this.adjustmentsDebitTotal,
    required this.deductionsTotal,
    required this.unpaidAbsenceDeduction,
    required this.grossPay,
    required this.netPay,
    required this.lineItems,
    this.warnings = const [],
  });
}

/// The persisted payroll record for one employee within one period —
/// wraps the latest snapshot plus workflow status. Once the parent
/// [PayrollPeriod] is finalized, this record is locked; corrections go
/// through [PayrollAdjustment], never a rewritten snapshot.
class PayrollRecord {
  final String id;
  final String payrollPeriodId;
  final String employeeId;
  final PayrollRecordStatus status;
  final PayrollCalculationSnapshot snapshot;

  const PayrollRecord({
    required this.id,
    required this.payrollPeriodId,
    required this.employeeId,
    required this.status,
    required this.snapshot,
  });

  PayrollRecord copyWith({PayrollRecordStatus? status, PayrollCalculationSnapshot? snapshot}) {
    return PayrollRecord(
      id: id,
      payrollPeriodId: payrollPeriodId,
      employeeId: employeeId,
      status: status ?? this.status,
      snapshot: snapshot ?? this.snapshot,
    );
  }
}
