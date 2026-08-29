import '../enums/enums.dart';

/// A payroll period (e.g. a calendar month). Its [status] drives the
/// workflow in architecture §15. Once [PayrollPeriodStatus.finalized],
/// the period is LOCKED: no normal edits to attendance, timesheets, or
/// payroll records are permitted — only [PayrollAdjustment]s against the
/// already-finalized numbers, which are always additive/auditable.
class PayrollPeriod {
  final String id;
  final DateTime startDate;
  final DateTime endDate;
  final PayrollPeriodStatus status;
  final DateTime? finalizedAt;
  final String? finalizedBy;

  const PayrollPeriod({
    required this.id,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.finalizedAt,
    this.finalizedBy,
  });

  bool get isLocked => status == PayrollPeriodStatus.finalized;

  PayrollPeriod copyWith({
    PayrollPeriodStatus? status,
    DateTime? finalizedAt,
    String? finalizedBy,
  }) {
    return PayrollPeriod(
      id: id,
      startDate: startDate,
      endDate: endDate,
      status: status ?? this.status,
      finalizedAt: finalizedAt ?? this.finalizedAt,
      finalizedBy: finalizedBy ?? this.finalizedBy,
    );
  }
}
